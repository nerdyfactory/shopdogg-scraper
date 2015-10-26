_       = require 'underscore'
numeral = require 'numeral'
Promise = require 'bluebird'
AdmZip  = require 'adm-zip'
csv     = Promise.promisify require('csv-parse')
config  = require('konfig')()
 
unzipAndParse = (buf) ->
  zip = new AdmZip(buf)
  zipEntries = zip.getEntries()
  csvInfo  = _.find zipEntries, (z) -> z.name.indexOf('product_info') != -1
  csvImage = _.find zipEntries, (z) -> z.name.indexOf('product_image') != -1

  csvParse = (file) ->
    csv(zip.readAsText(file), {columns: true})

  Promise.join csvParse(csvInfo), csvParse(csvImage), (info, images) ->
    products = []
    Promise.map info, (i) ->
      p = {}
      p.sku = i['Product SKU']
      p.url = i['Products Url']
      p.name = i['Product Name']
      #p.category = i['Category']
      p.price = numeral().unformat(i["Product Price(#{config.banggood.currency})"])
      p.options = i['Options'].split('\n')
      p.images = _.pluck(_.where(images, {'Product SKU': p.sku}), 'Image Url')
      p.description = i['Product Description']
      products.push p
    , { concurrency: 16 }
    products

module.exports = unzipAndParse
