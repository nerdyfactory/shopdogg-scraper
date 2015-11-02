Promise = require 'bluebird'
fs      = Promise.promisifyAll require('fs')
parse   = Promise.promisify require('csv-parse')
yaml    = require 'yamljs'

csvFile = 'banggood.csv'   # input
ymlFile = 'config/categories.yml' # output

p = []

fs.readFileAsync(csvFile, 'utf8')
.then (data) ->
  parse data, {columns: true}
.map (data) ->
  return unless data['auction']
  c = {}
  c.cids = [data['cid1'],data['cid2'],data['cid3'],data['cid4']].filter((val) -> val).join(',')
  c.auction = data['auction']
  c.keyword = data['keyword'] || ""
  p.push(c)
.then ->
  fs.writeFileAsync ymlFile, yaml.stringify(p)
