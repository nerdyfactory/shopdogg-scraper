# requires
Promise = require 'bluebird'
kue =  require 'kue'
#queue = Promise.promisifyAll kue.createQueue()
queue = kue.createQueue()
request = Promise.promisify require 'request'
cluster = require('cluster')
config = require('konfig')()
debug = require('debug') 'scraper'
_ = require 'underscore'
cheerio = require('cheerio')

#worker
banggood = require('src/workers/banggood')


# main
main = ->
  #parent process
  if cluster.isMaster
    parentMain()
  #child process
  else
    childMain()

parentMain = ->
  kue.app.listen 3000
  i = 0
  while i < config.common.scraper.worker_count
    cluster.fork()
    i++
  urlList = _.values config.banggood.urls
  publishUrls(urlList)

childMain = ->
  debug 'childMain started'
  queue.process('shopdogg', config.common.scraper.concurrency, banggood.scrape)

publishUrls = (urlList) ->
  console.log "started publishUrls!"
  setTimeout publishUrls, config.common.scraper.interval
  Promise.map urlList, (url) ->
    publishProductPages(url)
  
publishProductPages = (url) ->
  $ = undefined
  selectors = config.banggood.selectors.list_page
  request({url: url.address, method: 'get'})
  .spread (res, body) ->
    $ = cheerio.load body
    urls = []
    $(selectors.product_list).find(selectors.product_page).each (i, elem)->
      urls.push $(this).attr('href')
    urls
  .map (url) ->
    queue.create('shopdogg', { url: url }).save()
  .then ->
    url.address = $(selectors.next_page).attr('href')
    return unless url.address
    console.log "go to naxt page url: " + url.address
    publishProductPages url
  .catch (e) ->
    console.log e

module.exports = main

if require.main == module
  main()
