# This class represents an authentication error.
class AuthenticationError < StandardError
end

# This class represents a rate limit error, limit_reset contains the time at
# which the the access will be renewed.
class RateLimitExceeded < StandardError
  attr_accessor :limit_reset
  def initialize(message, limit_reset)
    @message = message
    @limit_reset = limit_reset
  end
end
