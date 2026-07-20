require "./error"
require "./query"

class Radarr::Client
  getter endpoint : URI
  @api_key : String
  @headers : Hash(String, String)
  @client : Crest::Resource

  @@instance : Radarr::Client?

  private def initialize(@endpoint : URI, @api_key : String)
    @headers = {
      "X-Api-Key" => @api_key,
      "Accept"    => "application/json",
    }
    # Kept for backwards compatibility with earlier revisions; the typed core
    # (`#request`) issues requests via `Crest::Request` directly.
    @client = Crest::Resource.new(@endpoint.to_s, params: {"apikey" => @api_key}, headers: @headers)
  end

  # ---- Core primitive ------------------------------------------------------
  #
  # The single method that both the generic verbs and the generated typed
  # endpoints (under `src/radarr/api/*`) build on. It is public so those
  # endpoint modules can call it on the client instance.

  # Issues `method` against `path` (relative to the configured endpoint) and
  # returns the raw `Crest::Response`.
  #
  # * `query` — an optional `Radarr::Query` of paging params / filters.
  # * `body`  — an optional request body: a `String`, or any object that
  #   responds to `#to_json` (a model or `Array` of models). When present the
  #   `Content-Type: application/json` header is added.
  #
  # The `apikey` query param and `X-Api-Key` header are always attached.
  # Non-2xx responses raise `Radarr::ApiError` (wrapping `crest`'s failure).
  #
  #     resp = client.request(:get, "api/v3/movie", Radarr::Query.paging(page: 1))
  #     movies = Array(Radarr::Model::MovieResource).from_json(resp.body)
  def request(method : Symbol, path : String, query : Radarr::Query? = nil, body = nil) : Crest::Response
    headers = @headers.dup
    encoded = Radarr::Client.encode_body(body)
    unless encoded.nil?
      headers["Content-Type"] = "application/json"
    end
    form = encoded.nil? ? ({} of String => String) : encoded

    Crest::Request.execute(
      method,
      url_for(path),
      form,
      headers: headers,
      params: query_string(query),
    )
  rescue ex : Crest::RequestFailed
    raise Radarr::ApiError.from_request_failed(ex)
  end

  # ---- Typed helpers -------------------------------------------------------
  #
  # Convenience wrappers for the generated endpoints: issue a request and
  # deserialize the body into a model (or array of models). Empty / 204 bodies
  # yield `nil` / `[]` respectively.

  # Requests and deserializes a single object of `type` (nil for empty bodies).
  def request_one(method : Symbol, path : String, type : T.class, query : Radarr::Query? = nil, body = nil) : T? forall T
    Radarr::Client.deserialize_one(request(method, path, query, body).body, type)
  end

  # Requests and deserializes a JSON array of `type` (empty for empty bodies).
  def request_many(method : Symbol, path : String, type : T.class, query : Radarr::Query? = nil, body = nil) : Array(T) forall T
    Radarr::Client.deserialize_many(request(method, path, query, body).body, type)
  end

  # ---- Generic verbs (backwards compatible) --------------------------------
  #
  # Unchanged surface: take a path and an optional `params` hash of query
  # parameters, return the raw response body as a `String`. Both instance and
  # class-method (singleton) forms are provided.

  {% for method in [:get, :post, :put, :delete] %}
  def {{method.id}}(path : String, params = {} of String => String) : String
    request(:{{method.id}}, path, Radarr::Query.from(params)).body
  end

  def self.{{method.id}}(path : String, params = {} of String => String) : String
    instance.{{method.id}}(path, params)
  end
  {% end %}

  # ---- Pure deserialization helpers ----------------------------------------
  #
  # Extracted as class methods so they are unit-testable without a live server.

  # Parses `body` into a single `type`; returns nil for empty/204 bodies.
  def self.deserialize_one(body : String?, type : T.class) : T? forall T
    return nil if body.nil? || body.strip.empty?
    type.from_json(body)
  end

  # Parses `body` into an `Array(type)`; returns `[] of T` for empty/204 bodies.
  def self.deserialize_many(body : String?, type : T.class) : Array(T) forall T
    return [] of T if body.nil? || body.strip.empty?
    Array(T).from_json(body)
  end

  # Normalizes a request body into a JSON string (or nil for no body).
  def self.encode_body(body : Nil) : Nil
    nil
  end

  # :ditto:
  def self.encode_body(body : String) : String
    body
  end

  # :ditto:
  def self.encode_body(body) : String
    body.to_json
  end

  # ---- Internals -----------------------------------------------------------

  # Builds the full query string, always carrying `apikey`.
  private def query_string(query : Radarr::Query?) : String
    String.build do |io|
      io << "apikey=" << URI.encode_www_form(@api_key)
      unless query.nil? || query.empty?
        io << '&'
        query.to_s(io)
      end
    end
  end

  private def url_for(path : String) : String
    "#{@endpoint}/#{path.lstrip('/')}"
  end

  # ---- Singleton -----------------------------------------------------------

  def self.new(endpoint : String, api_key : String)
    @@instance = new(URI.parse(endpoint), api_key)
    instance
  end

  def self.instance
    if i = @@instance
      i
    else
      raise "Radarr Client has not been initialized"
    end
  end
end
