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
YAML        = require 'yamljs'
categories  = YAML.load 'config/categories.yml'

banggoodPublishers = (code) ->
  categories = _.chain categories
    .map (category) ->
      category.cids = category.cids.split(",")
      category.cids = [category.cids] unless _.isArray category.cids
      return unless category.cids[0] == code
      #append 0
      auctionCode = category.auction
      auctionCode = "0" + auctionCode for [0...(8-category.auction.length)]
      category.auction = auctionCode
      params =
        com: "account"
        t: "dropshipImportDownload"
        d_warehouse: "CN"
        "d_cid[]": category.cids
        sortKey: "1"
        page: "1"
      category.url = "https://www.banggood.com/index.php?" + qs.stringify(params)
      category
    .compact()
    .value()

  request.postAsync(lib.reqOptions.login())
  .get(0)
  .then (res) ->
    @sid = _.find res.headers['set-cookie'], (s) -> s.indexOf('banggood_SID') != -1
    @sid = sid.split(';')[0].split('=')[1]
    debug "sid: #{@sid}"

    Promise.map categories, (category) ->
      publishProductPages(category, @sid)


publishProductPages = (category, sid) ->
  options = lib.reqOptions.dropshipCenter(category.url)
  options.headers['Cookie'] = 'banggood_SID='+sid

  request.getAsync(options)
  .get(1)
  .then (body) ->
    $ = cheerio.load body
    pids = []
    $('.goodlist_1 :checkbox').each ->
      pids.push $(this).val()
    debug "productIds: #{pids}"
    queue.create('shopdogg', { pids: pids, sid: sid, auction: category.auction, keyword: category.keyword }).save()
    pageNumber = $("a[title='Next page']").attr('page')
    return unless pageNumber
    nextUrl = qs.parse(category.url)
    nextUrl.page = pageNumber
    category.url = qs.unescape(qs.stringify(nextUrl))
    log "go to next page url: #{category.url}"
    publishProductPages category, sid
  .catch (err) ->
    log err.stack

module.exports = banggoodPublishers

