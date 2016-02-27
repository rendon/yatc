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
  attr_accessor :access_token
  attr_accessor :credentials

  def initialize(ck, cs)
    @consumer_key = ck
    @consumer_secret = cs
  end

  def followers_ids(user, count = Yatc::Settings::MAX_FOLLOWER_COUNT)
    params = {}
    if user.class == Fixnum
      params[:user_id] = user
    else
      params[:screen_name] = user
    end
    ids = []
    cursor = nil
    loop do
      if count == -1
        params[:count] = Yatc::Settings::MAX_FOLLOWER_COUNT
      else
        params[:count] = [Yatc::Settings::MAX_FOLLOWER_COUNT, count].min
        count -= params[:count]
      end

      params[:cursor] = cursor unless cursor.nil?

      encoded_params = encode_params(params)
      url = "#{BASE_URL}/followers/ids.json?#{encoded_params}"
      data = JSON.parse(execute(:get, url))
      ids += data['ids']
      cursor = data['next_cursor']
      break if cursor == 0
      break if count == 0
    end
    ids
  end

  def friends_ids(user, count = Yatc::Settings::MAX_FRIENDS_COUNT)
    params = {}
    if user.class == Fixnum
      params[:user_id] = user
    else
      params[:screen_name] = user
    end
    ids = []
    cursor = nil
    loop do
      if count == -1
        params[:count] = Yatc::Settings::MAX_FRIENDS_COUNT
      else
        params[:count] = [Yatc::Settings::MAX_FRIENDS_COUNT, count].min
        count -= params[:count]
      end

      params[:cursor] = cursor unless cursor.nil?

      encoded_params = encode_params(params)
      url = "#{BASE_URL}/friends/ids.json?#{encoded_params}"
      data = JSON.parse(execute(:get, url))
      ids += data['ids']
      cursor = data['next_cursor']
      break if cursor == 0
      break if count == 0
    end
    ids
  end

  def users_show(user)
    params = {}
    if user.class == Fixnum
      params[:user_id] = user
    else
      params[:screen_name] = user.to_s
    end
    params = encode_params(params)
    url = "#{BASE_URL}/users/show.json?#{params}"
    JSON.parse(execute(:get, url))
  end

  def statuses_user_timeline(user, count = Yatc::Settings::MAX_TWEETS_COUNT)
    params = {}
    if user.class == Fixnum
      params[:user_id] = user
    else
      params[:screen_name] = user.to_s
    end
    tweets = []
    max_id = nil
    while count > 0
      params[:count] = [Yatc::Settings::MAX_TWEETS_COUNT, count].min
      count -= params[:count]
      unless max_id.nil?
        params[:max_id] = max_id
      end
      encoded_params = encode_params(params)
      url = "#{BASE_URL}/statuses/user_timeline.json?#{encoded_params}"
      t = JSON.parse(execute(:get, url))
      unless t.empty?
        max_id = t.map{ |tweet| tweet['id'] }.min - 1
      end
      tweets += t
    end
    tweets
  end

  def request_access_token
    bearer_token = encode_keys(consumer_key, consumer_secret)
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
      @access_token = JSON.parse(resp)['access_token']
    rescue => e
      raise e.http_code == 403 ? AuthenticationError : e
    end
  end

  private
  def encode_keys(ck, cs)
    ck = URI.encode(ck)
    cs = URI.encode(cs)
    Base64.strict_encode64(ck + ':' + cs)
  end

  def encode_params(params)
    params.map { |k, v| "#{k}=#{v}" }.join('&')
  end

  def execute(method, url)
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
      limit_reset = e.response.headers[:x_rate_limit_reset]
      raise RateLimitExceeded.new(e.message, limit_reset)
    end
  end
end
