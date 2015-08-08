util    = require 'util'
Promise = require 'bluebird'
kue     = require 'kue'
request = require 'request'
cheerio = require 'cheerio'
_       = require 'underscore'
config  = require('konfig')()
debug   = require('debug') 'publisher:banggood'

queue   = kue.createQueue()
request = Promise.promisify request
log     = util.log

main = ->
  urlList = _.values config.banggood.urls
  log "start banggood publisher!"
  setTimeout main, config.common.scraper.interval # this needs to be tested
  Promise.map urlList, (url) ->
    publishProductPages(url)

publishProductPages = (url) ->
  $ = ""
  request({url: url.address, method: 'get'})
  .spread (res, body) ->
    $ = cheerio.load body
    urls = []
    $(".goodlist_1").find("li .img a").each ->
      urls.push $(this).attr('href')
    urls
  .map (url) ->
    queue.create('shopdogg', { url: url }).save()
  .then ->
    url.address = $("a[title='Next page']").attr('href')
    return unless url.address
    log "go to next page url: " + url.address
    publishProductPages url
  .catch (e) ->
    log e

module.exports = main

