class AuthenticationError < StandardError
end

class RateLimitExceeded < StandardError
  attr_accessor :limit_reset
  def initialize(message, limit_reset)
    @message = message
    @limit_reset = limit_reset
  end
end
