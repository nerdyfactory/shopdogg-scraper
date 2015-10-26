util        = require 'util'
Promise     = require 'bluebird'
kue         = require 'kue'
cheerio     = require 'cheerio'
_           = require 'underscore'
numeral     = require 'numeral'
requireDir  = require 'require-dir'
prettyBytes = require 'pretty-bytes'
config      = require('konfig')()
debug       = require('debug') 'worker:banggood'
log         = util.log
queue       = kue.createQueue()
request     = Promise.promisifyAll require 'request'
lib         = requireDir '../lib/banggood'

banggoodWorker = (job, done) ->
  options = lib.reqOptions.downloadZip(job.data.pids)
  options.headers['Cookie'] =  lib.reqOptions.getCookie(job.data.sid)
  r = request(options)
  new Promise (resolve, reject) ->
    data = []
    r.on 'data', (chunk) ->
      debug "receiving data"
      data.push chunk
    r.on 'end', ->
      buf = Buffer.concat(data)
      debug "finished"
      debug "data size #{prettyBytes(Buffer.byteLength(buf, 'utf8'))}"
      resolve buf
    r.on 'error', (err) ->
      log err.stack
      reject err
  .then(lib.unzipAndParse)
  .map (product) ->
    lib.additionalData(product.url, job.data.sid)
    .then (data) ->
      unless data.available
        log "Product not available: #{product.sku}"
      else
        if data.old_price? and data.old_price > product.price
          product.old_price = data.old_price
        product.shipping_options = data.shipping_options
        product.auctionCode  = job.data.auction
        product.keyword = job.data.keyword
        debug JSON.stringify product, null, 2
        log "Publishing product: #{product.sku}"
        queue.create('auction', product).save()
    .catch (err) ->
      log err.stack

  , { concurrency: 4 }
  .then ->
    done()
  .catch (err) ->
    log err.stack


module.exports = banggoodWorker
