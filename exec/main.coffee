# requires
Promise = require 'bluebird'
kue =  require 'kue'
queue = Promise.promisifyAll kue.createQueue()
cluster = require('cluster')
config = require('konfig')()
debug = require('debug') 'scraper'
_ = require 'underscore'
cheerio = require('cheerio')
request = Promise.promisify require 'request'

#worker
shopdogg = require('src/workers/shopdogg')


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
  while true
    queue.processAsync('shopdogg', config.common.scraper.concurrency)
    .spread(shopdogg.scrape)

publishUrls = (urlList) ->
  console.log "started publishUrls!"
  setTimeout publishUrls, config.common.scraper.interval
  Promise.map urlList, (url) ->
    publishProductPages(url)
  .then ->
    "job complete"
  .then(queue.onAsync)
  .then ->
    console.log "finished publishUrls!"
  
publishProductPages = (url) ->
  request({url: url.address, method: 'get'})
  .spread (res, body) ->
    $ = cheerio.load body
    urls = []
    $(config.banggood.selectors.product_list).find(config.banggood.selectors.product_page).each (i, elem)->
      urls.push $(this).attr('href')
    urls
  .map (url) ->
    queue.createAsync('shopdogg', {url: url})
    url.address = $(config.banggood.selectors.next_page).attr('href')
    return unless url.address
    console.log "go to naxt page url: " + url.address
    publishProductPages url

module.exports = main

if require.main == module
  main()
