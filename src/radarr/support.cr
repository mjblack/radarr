require "json"

module Radarr
  # Converts `format: date-time` schema properties to/from Crystal `Time`.
  #
  # Radarr emits timestamps in a few flavours (RFC 3339 with `Z`, offsets, and
  # timezone-less "unset" values such as `0001-01-01T00:00:00`). Reads are
  # lenient across those shapes; writes are normalised to RFC 3339.
  module TimeConverter
    extend self

    FORMATS = {
      "%Y-%m-%dT%H:%M:%S.%N%z",
      "%Y-%m-%dT%H:%M:%S%z",
      "%Y-%m-%dT%H:%M:%S.%N",
      "%Y-%m-%dT%H:%M:%S",
      "%Y-%m-%d",
    }

    def parse(string : String) : Time
      begin
        return Time.parse_rfc3339(string)
      rescue Time::Format::Error
      end

      FORMATS.each do |format|
        begin
          return Time.parse(string, format, Time::Location::UTC)
        rescue Time::Format::Error
        end
      end

      raise JSON::ParseException.new("Invalid date-time value: #{string.inspect}", 0, 0)
    end

    def from_json(pull : JSON::PullParser) : Time
      parse(pull.read_string)
    end

    def to_json(value : Time, builder : JSON::Builder) : Nil
      builder.string(value.to_rfc3339)
    end
  end

  # Defines a string-valued enum whose JSON representation is the exact
  # camelCase value declared in `ext/schema.json`.
  #
  # Crystal's default `Enum#to_json` emits snake_case member names, which the
  # Radarr API rejects on writes. This macro overrides serialization so writes
  # emit the schema's literal values while reads stay lenient (the built-in
  # case/underscore-insensitive `parse` is used as a fallback).
  macro def_string_enum(name, members)
    enum {{name.id}}
      {% for member, value in members %}
      {{member.id}}
      {% end %}

      # The exact schema value for this member (used on JSON writes).
      def to_radarr_value : String
        case self
        {% for member, value in members %}
        when {{name.id}}::{{member.id}}
          {{value}}
        {% end %}
        else
          to_s
        end
      end

      def to_json(builder : JSON::Builder) : Nil
        builder.string(to_radarr_value)
      end

      # Parses a schema value, falling back to Crystal's lenient enum parsing.
      # Unknown values are surfaced as `JSON::ParseException` for consistency
      # with the rest of JSON deserialization (Crystal's `parse` raises
      # `ArgumentError`).
      def self.from_radarr_value(string : String) : self
        {% for member, value in members %}
        return {{name.id}}::{{member.id}} if string == {{value}}
        {% end %}
        begin
          parse(string)
        rescue ArgumentError
          raise JSON::ParseException.new(
            "Unknown {{name.id}} value: #{string.inspect}", 0, 0)
        end
      end

      def self.new(pull : JSON::PullParser) : self
        case pull.kind
        when .string?
          from_radarr_value(pull.read_string)
        when .int?
          from_value(pull.read_int)
        else
          raise JSON::ParseException.new("Expected string or int for {{name.id}}", *pull.location)
        end
      end
    end
  end
end
