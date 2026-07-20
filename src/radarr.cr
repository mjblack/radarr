require "json"
require "crest"

module Radarr
  VERSION = "0.1.1"
end

require "./radarr/support"
require "./radarr/support_enums"
require "./radarr/error"
require "./radarr/query"
require "./radarr/client"
require "./radarr/model"
require "./radarr/support_http_uri"
require "./radarr/api/**"
