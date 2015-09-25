require 'rest_client'
require 'open-uri'
require 'base64'

class TwitterClient
  def self.bearer_token(consumer_key, consumer_secret)
    consumer_key = URI::encode(consumer_key)
    consumer_secret = URI::encode(consumer_secret)
    Base64.strict_encode64(consumer_key + ':' + consumer_secret)
  end

  def self.test_auth(consumer_key, consumer_secret)
    begin
      bearer_token = TwitterClient.bearer_token(consumer_key, consumer_secret)
      resp = RestClient::Request.execute({
        method: :post,
        url: 'https://api.twitter.com/oauth2/token',
        headers: {
          'User-Agent' => 'My twitter App',
          'Authorization' => "Basic #{bearer_token}",
          'Content-Type' => 'application/x-www-form-urlencoded;charset=UTF-8',
          'Content-Length' => 29,
          'Accept-Encoding' => 'gzip',
        },
        payload: 'grant_type=client_credentials',
      })
    rescue => e
      return false
    end
    true
  end
end

c = JSON.parse(ARGV[0])
tokens = c['tokens'].split(/\s+/)
if TwitterClient.test_auth(tokens[0], tokens[1])
  puts "OK"
else
  puts "FAIL"
end
