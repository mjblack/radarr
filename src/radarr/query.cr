require "uri"

module Radarr
  # Structured, URI-encoded query-string builder for typed endpoints.
  #
  # Handles Radarr's paging parameters (`page`, `pageSize`, `sortKey`,
  # `sortDirection`) plus arbitrary filters:
  #
  # * `nil` values are dropped.
  # * `Array` values are emitted as repeated keys (`movieIds=1&movieIds=2`),
  #   matching Radarr's ASP.NET Core model binding.
  # * enum values are serialized via `#to_radarr_value` when available (so the
  #   exact schema string, e.g. `ascending`, is sent), `Time` via RFC 3339,
  #   everything else via `#to_s`.
  #
  # Insertion order is preserved, so rendering is deterministic and the class
  # is pure/unit-testable — it performs no I/O and never touches the client.
  #
  #     Radarr::Query.paging(page: 2, page_size: 50, sort_key: "date")
  #       .add("movieIds", [1, 2])
  #       .to_s # => "page=2&pageSize=50&sortKey=date&movieIds=1&movieIds=2"
  class Query
    # Rendered key/value pairs, in insertion order.
    getter pairs : Array({String, String})

    def initialize
      @pairs = [] of {String, String}
    end

    # Yields a fresh query for block-style construction.
    def self.build(&) : self
      query = new
      yield query
      query
    end

    # Builds a query pre-populated with paging parameters.
    def self.paging(page = nil, page_size = nil, sort_key = nil, sort_direction = nil) : self
      new.paging(page, page_size, sort_key, sort_direction)
    end

    # Builds a query from a plain hash of params. Used by the generic verbs for
    # backwards compatibility.
    def self.from(params) : self
      query = new
      params.each { |key, value| query.add(key.to_s, value) }
      query
    end

    # Appends the standard paging parameters (nil ones are skipped). Chainable.
    def paging(page = nil, page_size = nil, sort_key = nil, sort_direction = nil) : self
      add("page", page)
      add("pageSize", page_size)
      add("sortKey", sort_key)
      add("sortDirection", sort_direction)
    end

    # Appends `value` under `key`. Arrays expand to repeated keys; nil is
    # dropped. Chainable.
    def add(key : String, value) : self
      append(key, value)
      self
    end

    def empty? : Bool
      @pairs.empty?
    end

    def to_s(io : IO) : Nil
      first = true
      @pairs.each do |(key, value)|
        io << '&' unless first
        first = false
        io << URI.encode_www_form(key) << '=' << URI.encode_www_form(value)
      end
    end

    private def append(key : String, value) : Nil
      case value
      when Nil
        # dropped
      when Array
        value.each { |element| append(key, element) }
      else
        @pairs << {key, stringify(value)}
      end
    end

    private def stringify(value) : String
      if value.responds_to?(:to_radarr_value)
        value.to_radarr_value
      elsif value.is_a?(Time)
        value.to_rfc3339
      else
        value.to_s
      end
    end
  end
end
