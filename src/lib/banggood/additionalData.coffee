Promise     = require 'bluebird'
request     = Promise.promisify require 'request'
cheerio     = require 'cheerio'
numeral     = require 'numeral'
config      = require('konfig')()
qs          = require 'querystring'
reqOptions  = require './reqOptions'
                          
additionalData = (url, sid) ->
  request({url: url, method: 'get'})
  .get(1)
  .then (body) ->
    $ = cheerio.load body
  
    product = {}
  
    old_price = $('.old').attr('oriprice')
    product.old_price = numeral().unformat(old_price) if old_price
    product.available = if $('.buynow')[0] then true else false
  
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
    products_id = $('#products_id').val()
    data = 'com=product&t=initShipments'
    data += '&warehouse=CN'
    data += '&products_id='+products_id
    bgUrl = "http://www.banggood.com/index.php?"+data
  
    #selOptions = getSelectedOptions()
    #if selOptions.valueIds.length > 0
    #  i = 0
    #  while i < selOptions.valueIds.length
    #    data += '&value_ids[]=' + selOptions.valueIds[i]
    #    i++
    
    headers = { "Cookie": reqOptions.getCookie(sid) }
    request({url: bgUrl, method: 'get', json: true, headers: headers })
    .get(1)
    .then (body) ->
      $$ = cheerio.load(body.shipmentBox)
      unless $$('.inputChangePrice').attr('label')
        throw new Error "shipping to #{config.banggood.shipping_country.name} is not available #{shippingUrl}"
      product.shipping_options = []
      $$('.inputChangePrice').each ->
        type = $(this).attr('label').split(config.banggood.shipping_country.name)[1].trim()
        time = $(this).attr('time')
        fee = +$(this).attr('oriprice') # USD
        product.shipping_options.push
          type: config.banggood.shipping_text[type] || type
          time: time.replace("business days", "영업일")
          fee: fee
        
        # TODO
        # Translate following to Korean
        # Shipping type - "Air Parcel Register", "Expedited Shipping Service"...etc
        # Shipping time - "7-25 business days", "10-15 business days"...etc
      product

module.exports = additionalData
