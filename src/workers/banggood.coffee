util    = require 'util'
Promise = require 'bluebird'
kue     = require 'kue'
request = require 'request'
cheerio = require 'cheerio'
_       = require 'underscore'
config  = require('konfig')()
debug   = require('debug') 'worker:banggood'

queue   = kue.createQueue()
request = Promise.promisify request
log     = util.log

main = (job, done) ->
  selector = config.banggood.selectors.product_page
  request({url: job.data.url, method: 'get'})
  .spread (res, body) ->
    $ = cheerio.load body
    product =
      sku: $(selector.sku).text()
      name: $(selector.name).text()
      #price:
      #shipping_methods:
      #images: []
      #description:
      #options: []
    debug product
    product
    log "Publishing #{product.sku}"
  .then ->
    done()

module.exports = main
