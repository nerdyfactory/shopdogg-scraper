itemPrice = (USDprice, rate) ->
  # original price * exchange rate * commssion rate * margin * vat for margin
  Math.ceil((USDprice * rate * 1.12 * 1.1 *  1.01)/10) * 10

module.exports = itemPrice
