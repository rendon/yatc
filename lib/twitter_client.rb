require 'rest_client'
require 'open-uri'
require 'base64'

BASE_URL = 'https://api.twitter.com/1.1'

# This is the Twitter client class that will allow you to query the Twitter API.
class TwitterClient
  attr_accessor :consumer_key
  attr_accessor :consumer_secret

  def self.bearer_token(ck, cs)
    ck = URI.encode(ck)
    cs = URI.encode(cs)
    Base64.strict_encode64(ck + ':' + cs)
  end

  def self.access_token(ck, cs)
    bearer_token = TwitterClient.bearer_token(ck, cs)
    begin
      resp = RestClient::Request.execute(
        method: :post,
        url: 'https://api.twitter.com/oauth2/token',
        headers: {
          'User-Agent' => 'My twitter App',
          'Authorization' => "Basic #{bearer_token}",
          'Content-Type' => 'application/x-www-form-urlencoded;charset=UTF-8',
          'Content-Length' => 29,
          'Accept-Encoding' => 'gzip'
        },
        payload: 'grant_type=client_credentials'
      )
      JSON.parse(resp)['access_token']
    rescue => e
      raise e.http_code == 403 ? AuthenticationError : e
    end
  end

  def self.test_access(ck, cs)
    !access_token(ck, cs).empty?
  end

  def follower_ids(user_id, count = 5000)
    access_token = TwitterClient.access_token(consumer_key, consumer_secret)
    url = "#{BASE_URL}/followers/ids.json?count=#{count}&user_id=#{user_id}"
    resp = RestClient::Request.execute(
      method: :get,
      url: url,
      headers: {
        'User-Agent'      => 'My Twitter App',
        'Authorization'   => "Bearer #{access_token}",
        'Accept-Encoding' =>  'gzip'
      }
    )
    JSON.parse(resp)['ids']
  end

  def initialize(ck, cs)
    @consumer_key = ck
    @consumer_secret = cs
  end
end
