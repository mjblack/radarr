require "crest"

module Radarr
  # Base class for every error raised by this shard, so callers can rescue
  # `Radarr::Error` to catch anything the client throws.
  class Error < Exception
  end

  # Raised when the Radarr API responds with a non-2xx HTTP status.
  #
  # Carries the HTTP `status_code` and the raw response `body` (often a JSON
  # error payload) so callers can inspect what went wrong. The client wraps
  # `crest`'s own `Crest::RequestFailed` into this type so consumers never need
  # to know the underlying HTTP shard.
  class ApiError < Error
    getter status_code : Int32
    getter body : String

    def initialize(@status_code : Int32, @body : String, message : String? = nil)
      super(message || default_message)
    end

    private def default_message : String
      base = "Radarr API request failed with HTTP #{@status_code}"
      snippet = @body.strip
      snippet.empty? ? base : "#{base}: #{snippet[0, 500]}"
    end

    # Wraps the response of a `crest` failure (raised when `handle_errors` is
    # on) into a typed `ApiError`.
    def self.from_request_failed(ex : Crest::RequestFailed) : ApiError
      from_response(ex.response)
    end

    # Builds an `ApiError` from a `crest` response.
    def self.from_response(response : Crest::Response) : ApiError
      new(response.status_code.to_i, response.body)
    end
  end
end
