require 'rest_client'
require 'open-uri'
require 'base64'

require_relative 'settings'
require_relative 'exceptions'

BASE_URL = 'https://api.twitter.com/1.1'.freeze

# This is the Twitter client class that will allow you to query the Twitter API.
class TwitterClient
  attr_accessor :consumer_key
  attr_accessor :consumer_secret
  attr_accessor :access_token
  attr_accessor :credentials

  # Creates a new twitter client with the given consumer key and consumer
  # secret. It DOES NOT authenticate with Twitter automatically, you should do
  # so calling request_access_token before starting querying Twitter.
  def initialize(ck, cs)
    @consumer_key = ck
    @consumer_secret = cs
  end

  # Retrieves followers IDs. User can be an ID or the screen name. Pass -1 as
  # count to retrieve everything. See
  # https://dev.twitter.com/rest/reference/get/followers/ids.
  def followers_ids(user, count = Yatc::Settings::MAX_FOLLOWER_COUNT)
    params = params_from_user(user)
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

  # Retrieves friends IDs. User can be an ID or the screen name. Pass -1 as
  # count to retrieve everything. See
  # https://dev.twitter.com/rest/reference/get/friends/ids.
  def friends_ids(user, count = Yatc::Settings::MAX_FRIENDS_COUNT)
    params = params_from_user(user)
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

  # Retrieves user profile. User can be an ID or the screen name. See
  # https://dev.twitter.com/rest/reference/get/users/show.
  def users_show(user)
    params = params_from_user(user)
    params = encode_params(params)
    url = "#{BASE_URL}/users/show.json?#{params}"
    JSON.parse(execute(:get, url))
  end

  # Retrieves the most recent tweets of user. User can be an ID or the screen
  # name. See https://dev.twitter.com/rest/reference/get/statuses/user_timeline.
  def statuses_user_timeline(user, count = Yatc::Settings::MAX_TWEETS_COUNT)
    params = params_from_user(user)
    tweets = []
    max_id = nil
    while count > 0
      params[:count] = [Yatc::Settings::MAX_TWEETS_COUNT, count].min
      count -= params[:count]

      params[:max_id] = max_id unless max_id.nil?

      encoded_params = encode_params(params)
      url = "#{BASE_URL}/statuses/user_timeline.json?#{encoded_params}"
      t = JSON.parse(execute(:get, url))

      max_id = t.map { |tweet| tweet['id'] }.min - 1 unless t.empty?

      tweets += t
    end
    tweets
  end

  # Authenticates against the twitter API using the provided keys at creation.
  # You should call this method before issuing a query to the API. See
  # https://dev.twitter.com/oauth/application-only for details.
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
          'Accept-Encoding' => 'gzip'
        }
      )
    rescue RestClient::TooManyRequests => e
      limit_reset = e.response.headers[:x_rate_limit_reset]
      raise RateLimitExceeded.new(e.message, limit_reset)
    end
  end

  def params_from_user(user)
    params = {}
    if user.class == Fixnum
      params[:user_id] = user
    else
      params[:screen_name] = user.to_s
    end
    params
  end
end
