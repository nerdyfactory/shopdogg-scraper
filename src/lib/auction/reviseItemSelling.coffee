config        = require('konfig')()
Promise       = require 'bluebird'
sendSoapRequest = require 'lib/sendSoapRequest'
moment        = require 'moment'

reviseItemSelling = (code = null) ->
  options =
    req:
      attributes:
        Version: "1"
        ItemID: code
  sendSoapRequest('ShoppingService','ViewItemSelling', options)
  .then (res) ->
    flag = true
    if res.ViewItemSellingResult?.ItemSelling?.Period[0]?.attributes?.Status is "OnSale"
      endDate = res.ViewItemSellingResult?.ItemSelling?.Period[0]?.Period?.attributes?.ApplyEndDate
      flag = moment(endDate).isBefore(moment().add(2, 'days'))
    if flag
      options =
        req:
          attributes:
            Version: "1"
          ItemSelling:
            attributes:
              xmlns: "http://schema.auction.co.kr/Arche.Sell3.Service.xsd"
              ItemID: code
            Period:
              attributes:
                xmlns: "http://schema.auction.co.kr/Arche.Service.xsd"
                Status: "OnSale"
              Period:
                attributes:
                  ApplyPeriod: '7'

      sendSoapRequest('ShoppingService', 'ReviseItemSelling', options)
    else
      return "not extended sales period"

module.exports = reviseItemSelling
