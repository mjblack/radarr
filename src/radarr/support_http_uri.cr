# Hand-written support for `Radarr::Model::HttpUri`.
#
# This file is intentionally NOT generated: some Servarr APIs declare `HttpUri`
# as an object (`fullUri`/`scheme`/`host`/`port`/`path`/`query`/`fragment`),
# yet the live API serializes it as a plain URL *string* (e.g.
# `"https://wiki.servarr.com/..."`). The schema can't express that, so
# `tools/generate.cr` skips emitting `model/http_uri.cr` and this string-backed
# implementation stands in for it.
#
# NOTE: the current Radarr schema (`ext/schema.json`) does not declare an
# `HttpUri` component, so this type is presently unreferenced. It is kept for
# parity with the sibling `sonarr` shard and to guard against a future schema
# revision reintroducing the wire-format mismatch.
#
# Deserialization accepts both wire formats:
#   * a JSON string  -> stored as `full_uri`, with the component fields
#     best-effort populated via `URI.parse` (parse errors are swallowed).
#   * a JSON object  -> fields parsed as the schema declares them.
# Serialization emits the string form (`full_uri`) so values round-trip with
# Radarr.

require "uri"

class Radarr::Model::HttpUri
  property full_uri : String?
  property scheme : String?
  property host : String?
  property port : Int32?
  property path : String?
  property query : String?
  property fragment : String?

  def initialize(@full_uri : String? = nil, @scheme : String? = nil,
                 @host : String? = nil, @port : Int32? = nil,
                 @path : String? = nil, @query : String? = nil,
                 @fragment : String? = nil)
  end

  def self.new(pull : JSON::PullParser) : self
    case pull.kind
    when .string?
      from_uri_string(pull.read_string)
    when .begin_object?
      from_json_object(pull)
    when .null?
      pull.read_null
      new
    else
      raise JSON::ParseException.new(
        "Expected String or BeginObject for HttpUri, not #{pull.kind}",
        *pull.location)
    end
  end

  # Builds an `HttpUri` from a plain URL string, best-effort decomposing it
  # into its component fields. A malformed URL never raises: the component
  # fields are simply left nil while `full_uri` still holds the raw value.
  def self.from_uri_string(value : String) : self
    uri = new(full_uri: value)
    begin
      parsed = URI.parse(value)
      uri.scheme = parsed.scheme
      uri.host = parsed.host
      uri.port = parsed.port
      uri.path = parsed.path.presence
      uri.query = parsed.query
      uri.fragment = parsed.fragment
    rescue
      # Best-effort only; keep the components nil on any parse failure.
    end
    uri
  end

  # Builds an `HttpUri` from the object wire format the schema declares.
  def self.from_json_object(pull : JSON::PullParser) : self
    uri = new
    pull.read_object do |key|
      case key
      when "fullUri"  then uri.full_uri = pull.read_string_or_null
      when "scheme"   then uri.scheme = pull.read_string_or_null
      when "host"     then uri.host = pull.read_string_or_null
      when "port"     then uri.port = pull.read_null_or { pull.read_int.to_i32 }
      when "path"     then uri.path = pull.read_string_or_null
      when "query"    then uri.query = pull.read_string_or_null
      when "fragment" then uri.fragment = pull.read_string_or_null
      else                 pull.skip
      end
    end
    uri
  end

  # Emits the string form so values round-trip with Radarr (which expects a
  # bare URL string). A nil `full_uri` serializes as JSON `null`.
  def to_json(json : JSON::Builder) : Nil
    @full_uri.to_json(json)
  end
end
