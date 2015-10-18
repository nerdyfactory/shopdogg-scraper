config        = require('konfig')()
Promise       = require 'bluebird'
_             = require 'underscore'
redis         = require 'lib/redis'
sendSoapRequest = require 'lib/sendSoapRequest'

setOfficialNoticeInfo = (code) ->
  options =
    req:
      attributes:
        Version: "1"
      ItemID:
        $value: code
        attributes:
          xmlns:"http://schema.auction.co.kr/Arche.Sell3.Service.xsd"
      MemberTicket:
        Ticket:
          $value: config.auction.token
          attributes:
            xmlns: "http://schema.auction.co.kr/Arche.Service.xsd"

  sendSoapRequest('ShoppingService', 'GetOfficialNoticeInfo', options)
  .catch (e) ->
    console.log "failed to get OfficialNoticeInfo, try with etc category"
    options =
      req:
        attributes:
          Version: "1"
        NotiItemGroupNo:
          $value: "35"
          attributes:
            xmlns:"http://schema.auction.co.kr/Arche.Sell3.Service.xsd"
        MemberTicket:
          Ticket:
            $value: config.auction.token
            attributes:
              xmlns: "http://schema.auction.co.kr/Arche.Service.xsd"
    sendSoapRequest('ShoppingService', 'GetOfficialNoticeInfo', options)
  .then (res) ->
    notiGroupNo = res.GetOfficialNoticeInfoResult?.NotiItemGroup?.attributes?.NotiItemGroupNo
    notiCodes = res.GetOfficialNoticeInfoResult?.NotiItemCode
    notiCodes = _.pluck(notiCodes, 'attributes')
    options =
      req:
        attributes:
          Version: "1"
        ItemOfficialNotice:
          attributes:
            xmlns: "http://schema.auction.co.kr/Arche.Sell3.Service.xsd"
          ItemID:
            $value: code
            attributes:
              xmlns: "http://schema.auction.co.kr/Arche.Service.xsd"
          NotiItemGroupNo:
            $value: notiGroupNo
            attributes:
              xmlns: "http://schema.auction.co.kr/Arche.Service.xsd"
    itemOfficialNotiValues = []
    _.each notiCodes, (notiCode) ->
      tmp =
        attributes:
          xmlns:"http://schema.auction.co.kr/Arche.Service.xsd"
          NotiItemCode: notiCode.NotiItemCode
          NotiItemValue: '상품상세정보 참조'
          ExtraMarkIs: "false"
      itemOfficialNotiValues.push tmp

    options['req']['ItemOfficialNotice']['ItemOfficialNotiValue'] = itemOfficialNotiValues
    sendSoapRequest('ShoppingService', 'AddOfficialNotice', options)

module.exports = setOfficialNoticeInfo
