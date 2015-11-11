itemPrice = (USDprice, rate) ->
  # original price * exchange rate * commssion rate * margin * vat for margin
  Math.ceil((USDprice * rate * 1.25)/10) * 10

module.exports = itemPrice
