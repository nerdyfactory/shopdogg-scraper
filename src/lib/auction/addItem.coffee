config          = require('konfig')()
Promise         = require 'bluebird'
_               = require 'underscore'
numeral         = require 'numeral'
redis           = require 'lib/redis'
sendSoapRequest = require 'lib/sendSoapRequest'
itemPrice       = require 'lib/itemPrice'


addItem = (product, code = null, rate) ->
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

  (if code then getUpdateItemInfo(product, code, rate) else getNewItemInfo(product, rate))
  .then (item) ->
    options['req']['Item'] = item
    apiName = if code then  'ReviseItem' else 'AddItem'
    sendSoapRequest('ShoppingService', apiName, options)

getNewItemInfo = (prod, rate) ->
  brand = _.findWhere(prod.product_properties_attributes, { "property_name" : "brand" })?.value
  getBrandCode(brand)
  .then (brandCode) ->
    options =
      attributes:
        xmlns: "http://schema.auction.co.kr/Arche.Sell3.Service.xsd"
        BrandName: brand
        CategoryCode: prod.auctionCode
        Name: "#{prod.keyword} #{prod.name}".substring(0, 50)
        Price: itemPrice(prod.price, rate)
        ItemStatusType: "New"
        DescriptionVerType: "New"
        ItemCode: prod.sku
      ItemPicture: getImageList(prod.images)
      ItemContentsHtml: getHtmlDescription(prod.description)
      ItemReturn: getItemReturn()
      ShippingFee: getShippingFee()
      ChildProductSafeCert:
        attributes:
          CertificationType: "NotCert"
    options['BrandCode'] = brandCode if brandCode
    options

getItemReturn = ->
  options =
    attributes:
      xmlns: "http://schema.auction.co.kr/Arche.Service.xsd"
      DeliveryAgency: "etc"
    Address:
      attributes:
        ZipCode: "150800"
        Address: "서울특별시 영등포구 당산동"
        Street: "121-200 휴브리지 802호"
    ExtraInfo:
      attributes:
        ReturnFee: "40000"
        ReturnNotice: "반품시 왕복 국제배송비 부담"
        ReturnTel: "010-3123-1069"


getUpdateItemInfo = (prod, code, rate) ->
  options =
    attributes:
      xmlns: "http://schema.auction.co.kr/Arche.Sell3.Service.xsd"
      ItemID: code
      Price: itemPrice(prod.price, rate)
      DescriptionVerType: "New"
    ItemContentsHtml: getHtmlDescription(prod)
  Promise.resolve options

getBrandCode = (brand) ->
  redis.hgetAsync('auctionBrandCode', brand)
  .then (code) ->
    return code if code

    # if we don't have brand code stored in redis, query it from auction
    req =
      req:
        attributes:
          Equal: 'true'
          Type: 'BrnadName'
          Value: brand

    sendSoapRequest('AuctionService', 'GetBrandID', req)
    .then (res) ->
      brandId  = res.GetBrandIDResult?.Brand?[0].attributes?.BrandID
      return null unless brandId
      redis.hsetAsync('auctionBrandCode', brand, brandId)
      .then ->
        brandId

getImageList = (images) ->
  imgs = []
  _.each images, (image) ->
    imgs.push { attributes: { Uri: image, Description: "snapshop" } }
  opt =
    attributes:
      xmlns: "http://schema.auction.co.kr/Arche.Service.xsd"
    FixImage: imgs[0]
    FixImageB: imgs[0]
    ListingPicture: imgs[0]
    ListingPictureB: imgs[0]
  _.each imgs, (img, i) ->
    opt["Picture#{i+1}"] = img
    opt["Picture#{i+1}B"] = img if i < 3
  opt

getHtmlDescription = (desc) ->
  desc = desc.replace(/\<[ ]*a[^>]+\>/, "")
  desc = desc.replace(/\<\/a\>/, "")
  desc = "<img alt='' src='http://i.imgur.com/uaF17Qk.jpg' style='width: 800px;' /><br>" + desc + "<img alt='' src='http://i.imgur.com/QiIQSyu.jpg' style='width: 800px;' />"
  description =
    attributes:
      ItemHtml: desc
      ItemAddHtml: ""
      ItemPromotionHtml: ""
      xmlns: "http://schema.auction.co.kr/Arche.Service.xsd"
  description

getShippingFee = ->
  opt =
    attributes:
      xmlns: "http://schema.auction.co.kr/Arche.Service.xsd"
      ShippingType: 'Door2Door'
      IsPrepayable: 'false'
      FeeFreeConditionType: 'Discount'
      ShippingFeeChargeType: 'Free'
    ShipingFeeType: 'SellerShipping'

module.exports = addItem
