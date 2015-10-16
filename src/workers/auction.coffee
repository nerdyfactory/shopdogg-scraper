util        = require 'util'
log         = util.log
Promise     = require 'bluebird'
kue         = require 'kue'
queue       = kue.createQueue()
config      = require('konfig')()
debug       = require('debug') 'worker:auction'
requireDir  = require 'require-dir'
lib         = requireDir '../lib/auction'
redis       = require 'lib/redis'

auctionWorker = (job, done) ->
  rate = 1200
  item = job.data
  redis.hgetAsync('auction', item.sku).bind({})
  .then (code) ->
    this.code = code
    lib.addItem(item, this.code, rate)
  .then (res) ->
    log "addItem" + JSON.stringify res
    this.itemID = res.AddItemResult?.attributes?.ItemID || res.ReviseItemResult?.attributes?.ItemID
    throw new Error "failed to addItem:#{res}" unless this.itemID
    unless this.code
      lib.setOfficialNoticeInfo(this.itemID)
    else
      return
  .then ->
    redis.hsetAsync("auction", item.sku, this.itemID)
  .then ->
    lib.reviseItemStock(item, this.itemID, rate)
  .then (res) ->
    log "ReviseItemStock" + JSON.stringify res
    lib.reviseItemSelling(this.itemID)
  .then(done)
  .catch (e) ->
    log "failed to import product!!"
    log JSON.stringfiy job.data
    log e
    log e.stack

module.exports = auctionWorker
