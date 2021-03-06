config          = require('konfig')()
Promise         = require 'bluebird'
_               = require 'underscore'
numeral         = require 'numeral'
redis           = require 'lib/redis'
sendSoapRequest = require 'lib/sendSoapRequest'
debug           = require('debug') 'getReviseItemStockData'
itemPrice       = require 'lib/itemPrice'

reviseItemStock = (prod, code = null, rate) ->
  (if code then getExistingStockInfo(code) else Promise.resolve(null))
  .then (res) ->
    existingOrderStock = res.ViewItemStockResult?.ItemStock?.StockStandAlone
    existingOrderStock = _.pluck(existingOrderStock, 'attributes')
    options =
      req:
        attributes:
          Version: "1"
          InputChannel: ''
        MemberTicket:
          Ticket:
            $value: config.auction.token
            attributes:
              xmlns: "http://schema.auction.co.kr/Arche.Service.xsd"
        ItemStock:
          attributes:
            xmlns: "http://schema.auction.co.kr/Arche.Sell3.Service.xsd"
            ItemID: code
            Type: "StandAlone"
            BuyerDescriptiveText: "string"
            OptionStockType: "NotAvailable"
            OptVerType: "New"
            UseOptionBuyQty: "false"
          OptionObjectName:
            attributes:
               xmlns: "http://schema.auction.co.kr/Arche.Service.xsd"
               ClaseName1: "옵션"
               ClaseName2: "배송옵션"
               IsSoldOut: "false"
               UseYN: "true"
               ChangeType: "Add"

    productOptions = []
    reg = /\(\+US\$(\d.+)\)/
    _.each prod.options, (option) ->
      if reg.test(option) # check option contains additional price
        price = itemPrice(parseFloat(reg.exec(option)[1]), rate)
        option = option.replace(reg, "")
      else
        price = 0
      tmp =
        attributes:
          xmlns: "http://schema.auction.co.kr/Arche.Service.xsd"
          Section: "옵션"
          Text: option
          Price: price
          Quantity: "99"
          #ChangeType: "Add"
      existingInfo = _.findWhere(existingOrderStock, { "Text": option })
      unless existingInfo
        tmp['attributes']['ChangeType'] = "Add"
      else
        tmp['attributes']['ChangeType'] = "Update"
        tmp['attributes']['StockNo'] = parseInt(existingInfo.StockNo)
      productOptions.push tmp

    productPrice = itemPrice(prod.price, rate)
    shippingOptions = []
    _.each prod.shipping_options, (shippingOption) ->
      optionText = "#{shippingOption.type}(#{shippingOption.time})"
      shippingPrice = itemPrice(shippingOption.fee, rate)
      return if shippingPrice > (productPrice/2)
      tmp =
        attributes:
          xmlns: "http://schema.auction.co.kr/Arche.Service.xsd"
          Section: "배송옵션"
          Text: optionText
          Price: itemPrice(shippingOption.fee, rate)
          Quantity: "99"
          #ChangeType: "Add"
          
      existingInfo = _.findWhere(existingOrderStock, { "Text": optionText })
      unless existingInfo
        tmp['attributes']['ChangeType'] = "Add"
      else
        tmp['attributes']['ChangeType'] = "Update"
        tmp['attributes']['StockNo'] = parseInt(existingInfo.StockNo)
      productOptions.push tmp
    options['req']['ItemStock']['StockStandAlone'] = productOptions
    sendSoapRequest('ShoppingService', 'ReviseItemStock', options)

getExistingStockInfo = (code) ->
  options =
    req:
      attributes:
        ItemID: code
        Version: "1"
      MemberTicket:
        Ticket:
          $value: config.auction.token
          attributes:
            xmlns: "http://schema.auction.co.kr/Arche.Service.xsd"
  sendSoapRequest('ShoppingService', 'ViewItemStock', options)

module.exports = reviseItemStock
