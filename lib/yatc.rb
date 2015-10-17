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
  attr_accessor :access_token
  attr_accessor :force_retrieval
  attr_accessor :credentials

  def test_access(ck, cs)
    !request_access_token(ck, cs).empty?
  end

  def followers_ids(user, count = 5000)
    retrieved = 0
    params = {}
    if user.class == Fixnum
      params[:user_id] = user
    else
      params[:screen_name] = user
    end
    ids = []
    cursor = nil
    force_retrieval = true
    while count > 0
      params[:count] = [Yatc::Settings::MAX_FOLLOWER_IDS, count].min
      count -= params[:count]
      unless cursor.nil?
        params[:cursor] = cursor
      end

      encoded_params = encode_params(params)
      url = "#{BASE_URL}/followers/ids.json?#{encoded_params}"
      data = JSON.parse(execute(:get, url))
      ids += data['ids']
      cursor = data['next_cursor']
      retrieved += params[:count]
      break if cursor == 0
    end
    force_retrieval = false
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
    while count > 0
      params[:count] = [Yatc::Settings::MAX_FOLLOWER_IDS, count].min
      count -= params[:count]
      unless cursor.nil?
        params[:cursor] = cursor
      end

      encoded_params = encode_params(params)
      url = "#{BASE_URL}/friends/ids.json?#{encoded_params}"
      data = JSON.parse(execute(:get, url))
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
    JSON.parse(execute(:get, url))
  end

  def statuses_user_timeline(user, count = 200)
    params = {}
    if user.class == Fixnum
      params[:user_id] = user
    else
      params[:screen_name] = user
    end
    tweets = []
    max_id = nil
    while count > 0
      params[:count] = [Yatc::Settings::MAX_TWEETS, count].min
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


  def initialize(credentials, wait = false, force_retrieval = false)
    raise ArgumentError unless credentials.class == Array
    raise 'Must provide at least one credential' if credentials.empty?
    @credentials = credentials
    @credential_index = 0
    activate_next_credential
    @should_wait = wait
    @force_retrieval = force_retrieval
  end

  def bearer_token(ck, cs)
    ck = URI.encode(ck)
    cs = URI.encode(cs)
    Base64.strict_encode64(ck + ':' + cs)
  end

  def request_access_token(ck, cs)
    bearer_token = bearer_token(ck, cs)
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

  private
  def encode_params(params)
    params.map { |k, v| "#{k}=#{v}" }.join('&')
  end

  def activate_next_credential
    return false if @credential_index >= credentials.length
    @consumer_key = credentials[@credential_index][:consumer_key]
    @consumer_secret = credentials[@credential_index][:consumer_secret]
    @credential_index += 1
    begin
      @access_token = request_access_token(consumer_key, consumer_secret)
    rescue => e
      return false
    end
    true
  end

  def execute(method, url)
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
      if activate_next_credential
        retry
      end

      limit_reset = e.response.headers[:x_rate_limit_reset]
      if should_wait && limit_reset && (tries == 0 || force_retrieval)
        tries += 1
        delta = (Time.at(limit_reset.to_i) - Time.now).to_i
        sleep(delta + 1)
        retry
      else
        raise RateLimitExceeded.new(e.message)
      end
    end
  end
end
