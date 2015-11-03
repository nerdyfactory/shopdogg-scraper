Promise = require 'bluebird'
_       = require 'underscore'
soap    = Promise.promisifyAll require 'soap'
request = Promise.promisifyAll require 'request'
debug   = require('debug') "auction:sendSoapRequest"
log     = require 'lib/log'
config  = require('konfig')()


getSoapClient = (service) ->
  if service is 'AuctionService'
    Promise.resolve @auctionServiceClient if @auctionServiceClient
    #soap.createClientAsync("http://apitest.auction.co.kr/APIv1/AuctionService.asmx?WSDL")
    soap.createClientAsync("http://api.auction.co.kr/APIv1/AuctionService.asmx?WSDL")
    .then (@auctionServiceClient) ->
      @auctionServiceClient
  else if 'ShoppingService'
    Promise.resolve @shoppingServiceClient if @shoppingServiceClient
    #soap.createClientAsync("http://apitest.auction.co.kr/APIv1/ShoppingService.asmx?WSDL")
    soap.createClientAsync("http://api.auction.co.kr/APIv1/ShoppingService.asmx?WSDL")
    .then (@shoppingServiceClient) ->
      @shoppingServiceClient
  else
    throw new Error 'please check service'

sendSoapRequest = (service, name, data) ->
  getSoapClient(service).bind({})
  .then (soapClient) ->
    this.soapClient = soapClient
    soapClient.addSoapHeader { EncryptedTicket: { Value: config.auction.token, attributes: { xmlns: "http://www.auction.co.kr/Security" } } }
    soapAsync = Promise.promisify soapClient[name]
    soapAsync(data)
  .spread (result, raw, soapHeader, err) ->
    debug JSON.stringify result
    debug raw
    debug JSON.stringify soapHeader
    debug err
    result
  .catch (e) ->
    #log this.soapClient.lastRequest
    #log e.body
    throw new Error e.body

module.exports = sendSoapRequest
