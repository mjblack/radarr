module Radarr
  abstract class Model
    include JSON::Serializable
    include JSON::Serializable::Unmapped
  end
end

require "./model/**"
