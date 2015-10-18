Promise = require 'bluebird'
request = Promise.promisify require 'request'
cheerio = require 'cheerio'
numeral = require 'numeral'

additionalData = (url) ->
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
    .get(1)
    .then (body) ->
      $$ = cheerio.load(body.html)
      product.shipping_options = []
      $$('.inputChangePrice').each ->
        type = $(this).attr('label').split('Korea, Republic of via')[1].trim()
        time = $(this).attr('time')
        fee = +$(this).attr('oriprice') # USD
        product.shipping_options.push({type: type, time: time, fee: fee})
        # TODO
        # Translate following to Korean
        # Shipping type - "Air Parcel Register", "Expedited Shipping Service"...etc
        # Shipping time - "7-25 business days", "10-15 business days"...etc
  
      #console.log JSON.stringify product, null, 2
      product

module.exports = additionalData
