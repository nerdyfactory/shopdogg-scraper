util    = require 'util'
Promise = require 'bluebird'
kue     = require 'kue'
request = require 'request'
cheerio = require 'cheerio'
_       = require 'underscore'
numeral = require 'numeral'
config  = require('konfig')()
debug   = require('debug') 'worker:banggood'

queue   = kue.createQueue()
request = Promise.promisify request
log     = util.log

main = (job, done) ->
  selector = config.banggood.selectors.product_page
  request({url: job.data.url, method: 'get'})
  .spread (res, body) ->
    $ = cheerio.load body
    product = {}

    sku = $(".sku span").text()
    name = $(".good_main h1").text()
    price = $('.now').attr('oriprice')
    old_price = $('.old').attr('oriprice')

    unless sku
      throw new Error "No sku information"
    unless name
      throw new Error "No name information"
    unless price
      throw new Error "No price information"

    product.sku = sku
    product.name = name
    product.url = job.data.url
    product.price = numeral().unformat(price) # USD

    if old_price
      old_price = numeral().unformat(old_price)
      product.old_price = old_price if old_price > product.price

    # ----------------- Shipping Options -----------------

    # Validate all options selected
    validateSelOptions = ->
      optionList = $('.good_main .attr')
      length = optionList.length
      i = 0
      optionList.each ->
        len = 0
        $(this).find('a').each ->
          acClass = if $(this).hasClass('attrimg') then 'imgactive' else 'active'
          if $(this).hasClass(acClass)
            len = 1
            return false
        i++ if len == 1
      length == i

    # Get selected options
    getSelectedOptions = ->
      return false unless validateSelOptions()
      optionList = $('.good_main .attr')
      optionIds = new Array
      valueIds = new Array
      optionList.each ->
        option_id = $(this).attr('option_id')
        value_id = 0
        $(this).find('a').each ->
          acClass = if $(this).hasClass('attrimg') then 'imgactive' else 'active'
          if $(this).hasClass(acClass)
            value_id = $(this).attr('value_id')
            return false
        optionIds.push option_id
        valueIds.push value_id
      result = {}
      result.optionIds = optionIds
      result.valueIds = valueIds
      result

    # Ajax get shipping list
    curWarehouse = $('#curWarehouse').val()
    products_id = $('#products_id').val()
    data = 'com=product&t=getShipments'
    data += '&warehouse='+curWarehouse
    data += '&products_id='+products_id

    selOptions = getSelectedOptions()
    if selOptions.valueIds.length > 0
      i = 0
      while i < selOptions.valueIds.length
        data += '&value_ids[]=' + selOptions.valueIds[i]
        i++

    bgUrl = "http://www.banggood.com/index.php?"+data

    request({url: bgUrl, method: 'get', json: true })
    .spread (res, body) ->
      $$ = cheerio.load(body.html)
      product.shipping_options = []
      $$('.inputChangePrice').each ->
        type = $(this).attr('label').split('Korea, Republic of via')[1].trim()
        time = $(this).attr('time')
        fee = +$(this).attr('oriprice') # USD
        product.shipping_options.push({type: type, time: time, fee: fee})

      debug JSON.stringify product, null, 2
      log "Publishing #{product.sku}"
      product
  .then ->
    done()

module.exports = main
