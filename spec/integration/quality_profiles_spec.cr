require "../integration_helper"

# Api::QualityProfile#list — a bare Radarr ships default quality profiles.
# Exercises the typed round-trip into Array(Radarr::Model::QualityProfileResource).
describe "integration: Api::QualityProfile" do
  integration_it "#list returns the default quality profiles as typed models" do
    profiles = Radarr::Api::QualityProfile.new(IntegrationHelper.client).list
    profiles.should_not be_empty

    # Each profile exposes at least an id and a name.
    first = profiles.first
    present(first.id).should be > 0
    present(first.name).should_not be_empty
  end
end
