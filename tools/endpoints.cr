# Endpoint (typed API) generation for the `radarr` shard.
#
# Extends the model/enum generator (`tools/generate.cr`) with a second pass that
# reads the OpenAPI `paths` object and emits typed endpoint modules under
# `src/radarr/api/<group>.cr`. Each module is a thin wrapper around a
# `Radarr::Client`, one class per schema `tag` (group), with one method per
# operation.
#
# Design notes:
#   * The Radarr schema has NO `operationId`s, so method names are derived
#     deterministically from the HTTP verb + path (`list`, `get`, `create`,
#     `update`, `delete`, plus `<action>_<subresource>` for nested paths).
#   * Accessor pattern: `Radarr::Api::Tag.new(client).list`. Each group is a
#     class taking a `Radarr::Client`; methods delegate to the client core
#     (`request` / `request_one` / `request_many`).
#   * Path params interpolate into the URL. Query params build a `Radarr::Query`
#     (never `apikey` — the client core injects it). Request bodies pass through
#     `body:`. Responses deserialize to the schema's 200 model (array → many,
#     `$ref` → one, no content → `Nil`).
#
# This pass is purely additive: model/enum generation is unchanged.

module Generator
  API_DIR = ROOT / "src" / "radarr" / "api"

  # Groups (schema `tags`) that are NOT JSON APIs and are excluded wholesale:
  #   * StaticResource — HTML/static assets and the catch-all `{path}` routes.
  #   * MediaCover      — returns raw image bytes, not JSON.
  #   * CalendarFeed    — an iCal (`text/calendar`) feed.
  # This is an explicit safety net; the content-type / catch-all rules in
  # `exclusion_reason` catch these (and any future non-JSON operations) on their
  # own merits, so no operation is ever dropped silently.
  NON_JSON_GROUPS = %w[StaticResource MediaCover CalendarFeed]

  # A single API operation, resolved from the schema.
  record Operation,
    verb : String,
    path : String,
    name : String,
    node : JSON::Any

  # An operation that was intentionally skipped, with the reason (for logging).
  record Exclusion,
    group : String,
    verb : String,
    path : String,
    reason : String

  # ---- driver ---------------------------------------------------------------

  # Emits one file per emittable group; prunes stale files. Logs every excluded
  # operation. Returns the count of modules written.
  def self.emit_endpoints(schema : Schema) : Int32
    FileUtils.mkdir_p(API_DIR)

    grouped, excluded = operations_by_group(schema)

    unless excluded.empty?
      puts "Excluded #{excluded.size} operation(s) (non-JSON / catch-all):"
      excluded.each do |ex|
        puts "  - #{ex.group} #{ex.verb.upcase} #{ex.path} — #{ex.reason}"
      end
    end

    expected = Set(String).new
    grouped.keys.sort!.each do |group|
      file = "#{snake_case(group)}.cr"
      expected << file
      File.write(API_DIR / file, emit_group(schema, group, grouped[group]))
    end

    Dir.glob(API_DIR / "*.cr").each do |path|
      base = File.basename(path)
      File.delete(path) unless expected.includes?(base)
    end

    expected.size
  end

  # Collects emittable operations keyed by schema tag, with unique method names
  # per group. Non-JSON / catch-all operations are filtered out (and returned in
  # the second tuple element so the caller can report them); a group with zero
  # emittable operations is dropped entirely.
  def self.operations_by_group(schema : Schema) : {Hash(String, Array(Operation)), Array(Exclusion)}
    grouped = Hash(String, Array(Operation)).new { |hash, key| hash[key] = [] of Operation }
    excluded = [] of Exclusion

    # Deterministic order: sort by path, then by a fixed verb order.
    verb_order = %w[get post put delete]
    schema.paths.keys.sort!.each do |path|
      verbs = schema.paths[path].as_h
      verbs.keys.sort_by! { |v| verb_order.index(v) || verb_order.size }.each do |verb|
        next unless verb_order.includes?(verb)
        op = verbs[verb]
        tags = op["tags"]?.try(&.as_a.map(&.as_s)) || [] of String
        group = tags.first? || "Default"

        if reason = exclusion_reason(group, path, op)
          excluded << Exclusion.new(group, verb, path, reason)
          next
        end

        base = method_name(verb, path)
        # De-duplicate within a group (last-resort backstop; the ends-in-param
        # naming rule below yields zero collisions on the current schema).
        existing = grouped[group].map(&.name)
        name = base
        suffix = 2
        while existing.includes?(name)
          name = "#{base}_#{suffix}"
          suffix += 1
        end
        grouped[group] << Operation.new(verb, path, name, op)
      end
    end

    {grouped, excluded}
  end

  # ---- exclusion (non-JSON / catch-all) -------------------------------------

  # Returns why an operation should be skipped, or nil if it is emittable.
  # Principled: a catch-all/regex `{path}` route, or a request/response body
  # whose only content type is non-JSON (image, iCal, HTML, octet-stream,
  # multipart, …), is not a typed JSON endpoint. The named-group list is a
  # belt-and-braces safety net over the same intent.
  def self.exclusion_reason(group : String, path : String, op : JSON::Any) : String?
    return "excluded non-JSON group (#{group})" if NON_JSON_GROUPS.includes?(group)
    return "catch-all/regex `{path}` route" if path.includes?("{path}")
    return "non-JSON request body" if request_non_json?(op)
    return "non-JSON response body" if response_non_json?(op)
    nil
  end

  # True when a media type carries a JSON representation (`application/json`,
  # `text/json`, `application/*+json`, …).
  def self.json_content?(content_type : String) : Bool
    content_type.includes?("json")
  end

  # True when a request body is declared but no JSON representation is offered.
  def self.request_non_json?(op : JSON::Any) : Bool
    content = op.dig?("requestBody", "content").try(&.as_h)
    return false if content.nil? || content.empty?
    content.keys.none? { |content_type| json_content?(content_type) }
  end

  # True when any response declares content but none of it is JSON.
  def self.response_non_json?(op : JSON::Any) : Bool
    responses = op["responses"]?.try(&.as_h) || {} of String => JSON::Any
    responses.each_value do |resp|
      content = resp.dig?("content").try(&.as_h)
      next if content.nil? || content.empty?
      return true if content.keys.none? { |content_type| json_content?(content_type) }
    end
    false
  end

  # ---- naming ---------------------------------------------------------------

  # Derives a Crystal method name from verb + path (no operationId exists).
  #
  # GET disambiguation: a GET whose path ENDS IN A PATH PARAM fetches a single
  # item (`get`); otherwise it returns a collection (`list`). This decides at
  # every nesting level, not just the top one, so sibling collection/item routes
  # (`GET /config/host` → `list_host`, `GET /config/host/{id}` → `get_host`) no
  # longer collide. The static tail segments are always appended, keeping names
  # meaningful and unique.
  def self.method_name(verb : String, path : String) : String
    segments = path.split('/').reject(&.empty?)
    segments = segments.reject { |seg| seg == "api" || /\Av\d+\z/.matches?(seg) }

    resource = segments.first?
    tail = resource ? segments[1..] : segments
    static_tail = tail.reject(&.starts_with?('{'))
    ends_in_param = segments.last?.try(&.starts_with?('{')) || false

    action =
      case verb
      when "get"    then ends_in_param ? "get" : "list"
      when "post"   then "create"
      when "put"    then "update"
      when "delete" then "delete"
      else               verb
      end

    parts = [action] + static_tail.map { |seg| snake_case(seg) }
    name = parts.join('_')
    RESERVED.includes?(name) ? "#{name}_endpoint" : name
  end

  # ---- emitters -------------------------------------------------------------

  def self.emit_group(schema : Schema, group : String, ops : Array(Operation)) : String
    String.build do |io|
      io << HEADER << "\n\n"
      io << "class Radarr::Api::#{group}\n"
      io << "  def initialize(@client : Radarr::Client)\n"
      io << "  end\n"
      ops.each do |op|
        io << "\n"
        emit_operation(schema, io, op)
      end
      io << "end\n"
    end
  end

  # Path/query/body parameters resolved to Crystal.
  private record Param, key : String, arg : String, type : String

  def self.emit_operation(schema : Schema, io : IO, op : Operation) : Nil
    params = op.node["parameters"]?.try(&.as_a) || [] of JSON::Any
    path_params = params.select { |prm| prm["in"]? == JSON::Any.new("path") }
      .map { |prm| param_of(schema, prm) }
    query_params = params.select { |prm| prm["in"]? == JSON::Any.new("query") }
      .map { |prm| param_of(schema, prm) }
    body_type = request_body_type(schema, op.node)
    resp = response_shape(schema, op.node)

    # Signature: required path params, then body, then optional query params.
    args = [] of String
    path_params.each { |prm| args << "#{prm.arg} : #{prm.type}" }
    args << "body : #{body_type}" if body_type
    query_params.each { |prm| args << "#{prm.arg} : #{prm.type}? = nil" }
    signature = args.empty? ? "" : "(#{args.join(", ")})"

    io << "  def #{op.name}#{signature} : #{resp[:return]}\n"

    unless query_params.empty?
      io << "    query = Radarr::Query.new\n"
      query_params.each do |prm|
        io << "    query.add(#{prm.key.inspect}, #{prm.arg})\n"
      end
    end

    io << "    #{request_call(op, resp, path_params, !query_params.empty?, !body_type.nil?)}\n"
    io << "  end\n"
  end

  # Builds the delegating call into the client core.
  def self.request_call(op : Operation, resp, path_params : Array(Param),
                        has_query : Bool, has_body : Bool) : String
    url = url_literal(op.path, path_params)
    query_expr = has_query ? "query" : "nil"
    body_expr = has_body ? "body" : "nil"

    call_args = [":#{op.verb}", url]
    case resp[:kind]
    when :many
      method = "request_many"
      call_args << resp[:type]
    when :one
      method = "request_one"
      call_args << resp[:type]
    else
      method = "request"
    end
    call_args << query_expr << body_expr

    # Drop trailing `nil` arguments (they are the client's own defaults).
    while call_args.last? == "nil"
      call_args.pop
    end

    "@client.#{method}(#{call_args.join(", ")})"
  end

  # Turns `/api/v3/tag/{id}` into a Crystal string literal with interpolation.
  def self.url_literal(path : String, path_params : Array(Param)) : String
    literal = path
    path_params.each do |prm|
      literal = literal.gsub("{#{prm.key}}", "\#{#{prm.arg}}")
    end
    %("#{literal}")
  end

  def self.param_of(schema : Schema, node : JSON::Any) : Param
    key = node["name"].as_s
    type = resolve(schema, node["schema"]).expr

    # Normalize path `id`-style params to Int32 for caller ergonomics. The
    # schema declares some `{id}` path params as `string` (e.g. PUT /tag/{id})
    # and others as int32; unifying them to Int32 is wire-safe because URL
    # interpolation only calls `#to_s`. This applies to PATH params only —
    # query and body types stay strictly schema-faithful.
    if node["in"]? == JSON::Any.new("path") && id_path_param?(key)
      type = "Int32"
    end

    Param.new(key, property_name(key), type)
  end

  # A path param that names a numeric identifier (`id`, `movieId`, `fileId`,
  # …). Filenames and free-text names are unaffected.
  def self.id_path_param?(key : String) : Bool
    key.downcase.ends_with?("id")
  end

  # Request body Crystal type (from the JSON content schema), or nil if none.
  def self.request_body_type(schema : Schema, op : JSON::Any) : String?
    content = op.dig?("requestBody", "content").try(&.as_h)
    return nil unless content
    media = json_media(content)
    node = media["schema"]?
    node ? resolve(schema, node).expr : nil
  end

  # Picks the JSON media object from a content map, preferring `application/json`
  # and falling back to any JSON-ish type, then the first entry.
  def self.json_media(content : Hash(String, JSON::Any)) : JSON::Any
    content["application/json"]? ||
      content.find { |content_type, _| json_content?(content_type) }.try(&.last) ||
      content.first_value
  end

  # The 200/201 response: :many (array), :one (`$ref`), or :none (no content).
  def self.response_shape(schema : Schema, op : JSON::Any)
    responses = op["responses"]?.try(&.as_h) || {} of String => JSON::Any
    success = responses["200"]? || responses["201"]?
    content = success.try(&.dig?("content")).try(&.as_h)

    unless content
      return {kind: :none, type: "Nil", return: "Nil"}
    end

    media = json_media(content)
    node = media["schema"]

    if node["type"]? == JSON::Any.new("array")
      item = resolve(schema, node["items"]).expr
      {kind: :many, type: item, return: "Array(#{item})"}
    else
      type = resolve(schema, node).expr
      {kind: :one, type: type, return: "#{type}?"}
    end
  end
end
