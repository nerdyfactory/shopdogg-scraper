qs = require 'querystring'

getHeaders = ->
  headers =
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
    'Accept-Encoding': 'gzip, deflate, sdch'
    'Accept-Language': 'en-US,en;q=0.8,ko;q=0.6'
    'Connection': 'keep-alive'
    'Host': 'www.banggood.com'
    'Referer': 'https://www.banggood.com/index.php?com=account&t=dropshipImportDownload'
    'Upgrade-Insecure-Requests': 1
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.155 Safari/537.36'
  headers

login = ->
  params =
    'com': 'account'
    't': 'submitLogin'
    'email': 'test@gmail.com'
    'pwd': 'pwd'
    'at': '55f4416c8c61f'
  url = 'https://www.banggood.com/index.php?'+qs.stringify(params)
  options =
    url: url
    method: 'POST'
    headers: getHeaders()
  options

dropshipCenter = (url) ->
  options =
    url: url
    method: 'GET'
    headers: getHeaders()
    gzip: true
  options

downloadZip = (pids) ->
  params =
    'com': 'account'
    't': 'dropshipDownloadSub'
    'pids[]': pids
    'download_type': '2'
    'warehouse': 'CN'
  url = 'https://www.banggood.com/index.php?'+qs.stringify(params)
  options =
    url: url
    method: 'GET'
    headers: getHeaders()
    gzip: true
    encoding: null
  options


module.exports.login = login
module.exports.dropshipCenter = dropshipCenter
module.exports.downloadZip = downloadZip
