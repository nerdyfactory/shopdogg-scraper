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
  debug job.data.url
  done()
