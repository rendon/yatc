require 'rest_client'
require 'open-uri'
require 'base64'

require_relative 'settings'
require_relative 'exceptions'

BASE_URL = 'https://api.twitter.com/1.1'

# This is the Twitter client class that will allow you to query the Twitter API.
class TwitterClient
  attr_accessor :consumer_key
  attr_accessor :consumer_secret
  attr_accessor :should_wait

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

  def follower_ids(user, count = 5000)
    params = {}
    if user.class == Fixnum
      params[:user_id] = user
    else
      params[:screen_name] = user
    end
    ids = []
    cursor = nil
    access_token = TwitterClient.access_token(consumer_key, consumer_secret)
    while count > 0
      params[:count] = [Settings::MAX_FOLLOWER_IDS, count].min
      count -= params[:count]
      unless cursor.nil?
        params[:cursor] = cursor
      end

      encoded_params = encode_params(params)
      url = "#{BASE_URL}/followers/ids.json?#{encoded_params}"
      data = JSON.parse(execute(:get, url, access_token))
      ids += data['ids']
      cursor = data['next_cursor']
    end
    ids
  end

  def friends_ids(user, count = 5000)
    params = {}
    if user.class == Fixnum
      params[:user_id] = user
    else
      params[:screen_name] = user
    end
    ids = []
    cursor = nil
    access_token = TwitterClient.access_token(consumer_key, consumer_secret)
    while count > 0
      params[:count] = [Settings::MAX_FOLLOWER_IDS, count].min
      count -= params[:count]
      unless cursor.nil?
        params[:cursor] = cursor
      end

      encoded_params = encode_params(params)
      url = "#{BASE_URL}/friends/ids.json?#{encoded_params}"
      data = JSON.parse(execute(:get, url, access_token))
      ids += data['ids']
      cursor = data['next_cursor']
    end
    ids
  end

  def users_show(user)
    params = {}
    if user.class == Fixnum
      params[:user_id] = user
    else
      params[:screen_name] = user
    end
    params = encode_params(params)
    url = "#{BASE_URL}/users/show.json?#{params}"
    access_token = TwitterClient.access_token(consumer_key, consumer_secret)
    JSON.parse(execute(:get, url, access_token))
  end

  def initialize(ck, cs)
    @consumer_key = ck
    @consumer_secret = cs
  end

  private

  def encode_params(params)
    params.map { |k, v| "#{k}=#{v}" }.join('&')
  end

  def execute(method, url, access_token)
    tries = 0
    begin
      RestClient::Request.execute(
        method: method,
        url: url,
        headers: {
          'User-Agent'      => 'My Twitter App',
          'Authorization'   => "Bearer #{access_token}",
          'Accept-Encoding' =>  'gzip'
        }
      )
    rescue RestClient::TooManyRequests => e
      headers = e.response.headers
      if should_wait && headers[:x_rate_limit_reset] && tries == 0
        tries += 1
        delta = (Time.at(headers[:x_rate_limit_reset].to_i) - Time.now).to_i
        sleep(delta + 1)
        retry
      else
        raise RateLimitExceeded.new(e.message)
      end
    end
  end
end
