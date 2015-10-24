require 'mechanize'
class Banggood
  def initialize
    header = {
      'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Encoding' => 'gzip, deflate, sdch',
      'Accept-Language' => 'en-US,en;q=0.8,ko;q=0.6',
      'Connection' => 'keep-alive',
      'Host' => 'www.banggood.com',
      'Referer' => 'https://www.banggood.com/index.php?com=account&t=dropshipImportDownload',
      'Upgrade-Insecure-Requests' => 1,
      'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.155 Safari/537.36'
    }
    @agent = Mechanize.new
    @agent.request_headers = header
    @agent.get 'https://www.banggood.com'
  end

  def login email, pwd
    params = {
      'com' => 'account',
      't' => 'submitLogin',
      'email' => email,
      'pwd' => pwd,
      'at' => '55f4416c8c61f'
    }
    page = @agent.post "https://www.banggood.com/index.php", params, {}
  end

  def get_sub_category cid
    params = {
      'com' => 'ajax',
      't' => 'getSubCate',
      'cid' => cid
    }
    page = @agent.post "https://www.banggood.com/index.php", params, {}
    res = []
    Nokogiri::HTML(page.body).css(".select_box ul li").each do |tmp|
      link = tmp.css('a')
      next if link.text == "Please select"
      res << {:name => link.text, :cid => link.attr('cid').value }
    end
    res
  end
end

#@categories = [{:name=>"Electronics", :cid=>"1091"},
# {:name=>"Cell Phones & Accessories ", :cid=>"140"},
# {:name=>"Lights & Lighting", :cid=>"1697"},
# {:name=>"Sports & Outdoor", :cid=>"896"},
# {:name=>"Toys and Hobbies", :cid=>"133"},
# {:name=>"Computer & Networking", :cid=>"155"},
# {:name=>"Clothing and Apparel", :cid=>"274"},
# {:name=>"Health & Beauty", :cid=>"892"},
# {:name=>"Automobiles & Motorcycles", :cid=>"1134"},
# {:name=>"Home and Garden", :cid=>"1031"},
# {:name=>"Jewelry and Watch", :cid=>"170"},
# {:name=>"Intimate Apparel", :cid=>"1098"},
# {:name=>"Apple Accessories", :cid=>"1696"},
# {:name=>"Bags & Shoes", :cid=>"3798"}]
#
#@client = Banggood.new
#@client.login 'login', 'pwd'
#@categories.each do |cate|
#  cate[:kids] = @client.get_sub_category cate[:cid]
#  next if cate[:kids].empty?
#  cate[:kids].each do |c|
#    c[:kids] = @client.get_sub_category c[:cid]
#    next if cate[:kids].empty?
#    c[:kids].each do |c2|
#      c2[:kids] = @client.get_sub_category c2[:cid]
#      if c2[:kids].empty?
#
#      end
#      c2[:kids].each do |c3|
#        c3[:kids] = @client.get_sub_category c3[:cid]
#      end
#    end
#  end
#end
@categories.each do |c1|
  if c1[:kids].empty?
    @aa << c1[:name] + "," + c1[:cid] + "\n"
    next
  end
  c1[:kids].each do |c2|
    if c2[:kids].empty?
      @aa << c1[:name] + "," + c1[:cid] + "," + c2[:name] + "," + c2[:cid] + "\n"
      next
    end
    c2[:kids].each do |c3|
      if c3[:kids].empty?
        @aa << c1[:name] + "," + c1[:cid] + "," + c2[:name] + "," + c2[:cid] + "," + c3[:name] + "," + c3[:cid] + "\n"
        next
      end
      c3[:kids].each do |c4|
        @aa << c1[:name] + "," + c1[:cid] + "," + c2[:name] + "," + c2[:cid] + "," + c3[:name] + "," + c3[:cid] + "," + c4[:name] + "," + c4[:cid] + "\n"
      end
    end
  end
end
