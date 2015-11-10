require('app-module-path').addPath(__dirname)
cluster     = require 'cluster'
util        = require 'util'
kue         = require 'kue'
requireDir  = require 'require-dir'
config      = require('konfig')()
debug       = require('debug') 'main'

queue       = kue.createQueue()
log         = util.log

worker      = requireDir('workers')
publisher   = requireDir('publishers')

main = ->
  #parent process
  if cluster.isMaster
    parentMain()
  #child process
  else
    childMain()


parentMain = ->
  if process.argv.length < 3
    console.log "you should specify top level category code!"
    process.exit()

  kue.app.listen 3000
  i = 0
  while i < config.common.scraper.worker_count
    cluster.fork()
    i++

  process.on 'SIGTERM', ->
    for id of cluster.workers
      cluster.workers[id].kill()
    process.exit(0)

  cluster.on 'exit', (deadWorker, code, signal) ->
    # Restart the worker
    worker = cluster.fork()
    # Note the process IDs
    newPID = worker.process.pid
    oldPID = deadWorker.process.pid
    # Log the event
    console.log 'worker ' + oldPID + ' died.'
    console.log 'worker ' + newPID + ' born.'
  
  # url publishers
  publisher.banggood(process.argv[2])


childMain = ->
  debug 'childMain started'
  # workers
  queue.process('shopdogg', config.common.scraper.concurrency, worker.banggood)
  queue.process('auction', config.common.scraper.concurrency, worker.auction)

  process.on 'SIGTERM', (sig) ->
    queue.shutdown 5000, (err) ->
      console.log 'Kue shutdown: ', err or ''
      process.exit 0


main()
