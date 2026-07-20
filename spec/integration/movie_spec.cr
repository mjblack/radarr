require "../integration_helper"

# Api::Movie#list — a fresh Radarr has no movies added, so this returns an empty
# Array(Radarr::Model::MovieResource). Verifies the typed endpoint is reachable
# and deserializes cleanly without any external metadata/indexers.
describe "integration: Api::Movie" do
  integration_it "#list returns an empty typed array on a bare instance" do
    movies = Radarr::Api::Movie.new(IntegrationHelper.client).list
    movies.should be_empty
  end
end
