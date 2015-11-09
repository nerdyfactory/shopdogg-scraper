require('app-module-path').addPath(__dirname + "/src/")
data    = require "./fixture.json"
auction = require "./src/workers/auction"
auction({data: data})
.then ->
  console.log "finished"
  process.exit(0)
