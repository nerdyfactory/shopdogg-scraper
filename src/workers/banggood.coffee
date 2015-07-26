# requires
kue = require('kue')
cluster = require('cluster')
queue = kue.createQueue()
config = require('konfig')()
debug = require('debug') 'shopdoggWorker'
Promise = require 'bluebird'
_ = require 'underscore'
cheerio = require('cheerio')
request = Promise.promisify require 'request'

module.exports.scrape = (job, done) ->
  selector = config.banggood.selectors.product_page
  $ = undefined
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
  .then ->
    done()
