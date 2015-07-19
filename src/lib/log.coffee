moment = require "moment"

log = (msg) ->
  console.log "#{timestamp()} #{msg}"

timestamp = ->
  "[#{moment().format('YYYY-MM-DD HH:mm:ss')}]"

module.exports = log
