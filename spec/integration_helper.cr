# ameba:disable Lint/SpecFilename — this is a shared helper, not a spec file.
require "./spec_helper"
require "http/client"

# Shared helper for the opt-in integration specs.
#
# The integration specs under spec/integration/ run against a LIVE Radarr
# container brought up by scripts/radarr-testenv.sh / docker-compose.yml. They
# exercise the GENERATED, typed endpoint methods (Radarr::Api::<Group>) through
# a configured Radarr::Client — typed request in, typed model out.
#
# They are opt-in and must never break a plain, offline `crystal spec`:
#
#   * Set RADARR_INTEGRATION=1 to actually exercise them.
#   * When the env var is unset, OR the container is not reachable, the specs
#     are reported as `pending` with a clear message instead of failing.
#
# Base URL and API key are read from the environment, defaulting to the values
# seeded by the harness (docker-compose.yml + scripts/radarr-testenv.sh):
#
#   RADARR_URL      (default http://localhost:7878)
#   RADARR_API_KEY  (default 0123456789abcdef0123456789abcdef)
#
# The `present` unwrap helper comes from spec_helper.cr (required above).

module IntegrationHelper
  DEFAULT_URL     = "http://localhost:7878"
  DEFAULT_API_KEY = "0123456789abcdef0123456789abcdef"

  class_getter base_url : String = (ENV["RADARR_URL"]?.presence || DEFAULT_URL).rchop('/')
  class_getter api_key : String = ENV["RADARR_API_KEY"]?.presence || DEFAULT_API_KEY

  # Opt-in switch. Integration specs only truly run when this is "1".
  def self.enabled? : Bool
    ENV["RADARR_INTEGRATION"]? == "1"
  end

  # Cheap liveness probe against /ping. Cached so we probe at most once.
  @@reachable : Bool? = nil

  def self.reachable? : Bool
    cached = @@reachable
    return cached unless cached.nil?
    @@reachable = probe
  end

  private def self.probe : Bool
    uri = URI.parse(base_url)
    client = HTTP::Client.new(uri)
    client.connect_timeout = 2.seconds
    client.read_timeout = 3.seconds
    begin
      resp = client.get("/ping")
      resp.status.success?
    ensure
      client.close
    end
  rescue
    false
  end

  # True only when the specs should actually hit the server.
  def self.run? : Bool
    enabled? && reachable?
  end

  # Human-readable reason the specs are being skipped (nil when they run).
  def self.skip_reason : String?
    return nil if run?
    if enabled?
      "Radarr not reachable at #{base_url} — start it with scripts/radarr-testenv.sh up && scripts/radarr-testenv.sh wait"
    else
      "set RADARR_INTEGRATION=1 (and start the container: scripts/radarr-testenv.sh up && scripts/radarr-testenv.sh wait)"
    end
  end

  # ---- Typed client --------------------------------------------------------
  #
  # A single configured Radarr::Client pointed at the live container. The
  # generated endpoint groups (Radarr::Api::System, Api::Tag, ...) are built on
  # top of it: `Radarr::Api::Tag.new(IntegrationHelper.client)`.

  @@client : Radarr::Client?

  def self.client : Radarr::Client
    @@client ||= Radarr::Client.new(base_url, api_key)
  end
end

# Wrapper around Spec's `it` that runs the example only when the integration
# environment is available, and otherwise records a `pending` example carrying
# the skip reason. Keeps `crystal spec` green and Docker-free by default.
def integration_it(description : String, &block)
  if IntegrationHelper.run?
    it(description, &block)
  else
    pending("#{description} [skipped: #{IntegrationHelper.skip_reason}]", &block)
  end
end
