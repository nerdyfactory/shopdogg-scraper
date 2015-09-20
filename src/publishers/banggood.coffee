util        = require 'util'
qs          = require 'querystring'
Promise     = require 'bluebird'
kue         = require 'kue'
cheerio     = require 'cheerio'
_           = require 'underscore'
requireDir  = require 'require-dir'
config      = require('konfig')()
debug       = require('debug') 'publisher:banggood'

log         = util.log
queue       = kue.createQueue()
request     = Promise.promisifyAll require 'request'
lib         = requireDir '../lib/banggood'

main = ->
  urlList = _.values config.banggood.urls
  log "start banggood publisher!"
  setTimeout main, config.common.scraper.interval # this needs to be tested

  request.postAsync(lib.reqOptions.login())
  .get(0)
  .then (res) ->
    @sid = _.find res.headers['set-cookie'], (s) -> s.indexOf('banggood_SID') != -1
    @sid = sid.split(';')[0].split('=')[1]
    debug "sid: #{@sid}"

    Promise.map urlList, (url) ->
      publishProductPages(url, @sid)


publishProductPages = (url, sid) ->
  options = lib.reqOptions.dropshipCenter(url.address)
  options.headers['Cookie'] = 'banggood_SID='+sid

  request.getAsync(options)
  .get(1)
  .then (body) ->
    $ = cheerio.load body
    pids = []
    $('.goodlist_1 :checkbox').each ->
      pids.push $(this).val()
    debug "productIds: #{pids}"
    queue.create('shopdogg', { pids: pids, sid: sid }).save()
    pageNumber = $("a[title='Next page']").attr('page')
    return unless pageNumber
    nextUrl = qs.parse(url.address)
    nextUrl.page = pageNumber
    url.address = qs.unescape(qs.stringify(nextUrl))
    log "go to next page url: #{url.address}"
    publishProductPages url, sid
  .catch (err) ->
    log err.stack

module.exports = main

