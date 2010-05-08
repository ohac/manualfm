require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'digest/md5'
require 'net/http'
require 'pit'

module ManualFm
  CONFIG = Pit.get('lastfm_api')
  APIKEY = CONFIG['apikey']
  SECRET = CONFIG['secret']

  URL1 = 'http://ws.audioscrobbler.com/2.0/'
  URL2 = 'http://post.audioscrobbler.com/'

  def self.gettoken
    url = '%s?method=auth.getToken&api_key=%s' % [URL1, APIKEY]
    body = open(url){|fd| fd.read}
    xml = Nokogiri::XML.parse(body)
    xml.css('token').text
  end

  def self.getsession(token)
    sig = Digest::MD5.hexdigest('api_key%smethod%stoken%s%s' %
        [APIKEY, 'auth.getSession', token, SECRET])
    url = '%s?api_key=%s&method=auth.getSession&token=%s&api_sig=%s' %
        [URL1, APIKEY, token, sig]
    body = open(url){|fd| fd.read}
    xml = Nokogiri::XML.parse(body)
    subscr = xml.css('subscriber').text
    name = xml.css('name').text
    sk = xml.css('key').text
    [name, sk, subscr]
  end

  def self.handshake(user, sk)
    ts = Time.now.to_i.to_s
    auth = Digest::MD5.hexdigest(SECRET + ts)
    params = {
      :hs => true,
      :p => '1.2.1',
      :c => 'tst', # TODO
      :v => '1.0', # TODO
      :u => user,
      :t => ts,
      :a => auth,
      :api_key => APIKEY,
      :sk => sk,
    }
    url = '%s?%s' % [URL2, params.map{|k, v| "%s=%s" % [k, v]}.join('&')]
    result = open(url){|fd| fd.read}
    result.each_line.map(&:chomp)
  end

  def self.submit(baseurl, sid, artist, track, time, len)
    params = {
      's' => sid,
      'a[0]' => artist,
      't[0]' => track,
      'i[0]' => time,
      'o[0]' => 'P',
      'r[0]' => '',
      'l[0]' => len,
      'b[0]' => '', # album
      'n[0]' => '', # tracknumber
      'm[0]' => '',
    }
    Net::HTTP.post_form(URI.parse(baseurl), params)
  end

end

if ManualFm::APIKEY.nil?
  puts 'Get your API Key and secret on http://www.lastfm.jp/api/account'
  puts
  print 'Your API Key: '
  apikey = gets.chomp
  print 'Your Secret: '
  secret = gets.chomp
  Pit.set('lastfm_api', :data => {
    'apikey' => apikey,
    'secret' => secret,
  })
  exit
end

token = ManualFm::CONFIG['token']
if token.nil?
  token = ManualFm.gettoken
  puts('http://www.last.fm/api/auth/?api_key=%s&token=%s' %
      [ManualFm::APIKEY, token])
  ManualFm::CONFIG['token'] = token
  puts('ready?')
  gets
end

name = ManualFm::CONFIG['name']
sk = ManualFm::CONFIG['sk']

if sk.nil?
  name, sk = ManualFm.getsession(token)
  ManualFm::CONFIG['name'] = name
  ManualFm::CONFIG['sk'] = sk
end

re, sid, post, post2 = ManualFm.handshake(name, sk)
artist = 'Van Halen'
track = 'Jump'
len = 4 * 60 + 6
time = Time.now.to_i - len - 10
ManualFm.submit(post2, sid, artist, track, time, len)
