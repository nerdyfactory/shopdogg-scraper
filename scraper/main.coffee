# requires
rootRequire = (name) ->
  require __dirname + '/' + name

config = require('konfig')()
yamlConfig = require 'yaml-config'
debug = require('debug') 'shopdoggScraper'
Promise = require 'bluebird'
_ = require 'underscore'
cheerio = require('cheerio')
request = Promise.promisify require 'request'


# main
main = ->
  debug __dirname
  urlList = _.values config.banggood.urls
  Promise.map(urlList, (url) ->
    publishProductPages(url)
  )

publishProductPages = (url) ->
  debug url
  request({url: url.address, method: 'get'})
  .spread (res, body) ->
    $ = cheerio.load body
    debug $(config.banggood.selectors.product_page).find().length

module.exports = main

if require.main == module
      main()
