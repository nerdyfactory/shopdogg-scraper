cluster     = require 'cluster'
util        = require 'util'
Promise     = require 'bluebird'
kue         = require 'kue'
request     = require 'request'
_           = require 'underscore'
cheerio     = require 'cheerio'
requireDir  = require 'require-dir'
config      = require('konfig')()
debug       = require('debug') 'main'

queue       = kue.createQueue()
request     = Promise.promisify request
log         = util.log

worker      = requireDir('src/workers')
publisher   = requireDir('src/publishers')

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

  # url publishers
  publisher.banggood()


childMain = ->
  debug 'childMain started'
  # workers
  queue.process('shopdogg', config.common.scraper.concurrency, worker.banggood)


main()
