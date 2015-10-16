config      = require('konfig')()
Promise     = require 'bluebird'
redis       = require 'redis'
cl          = redis.createClient(config.redis.port, config.redis.host, { auth_pass: process.env['REDIS_PASSWORD']  })
client      = Promise.promisifyAll(cl)

module.exports = client
