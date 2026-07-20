require "../integration_helper"

# Api::System#list_status — the most fundamental endpoint a bare Radarr exposes.
# Exercises the typed round-trip: GET /api/v3/system/status deserialized into a
# Radarr::Model::SystemResource.
describe "integration: Api::System" do
  integration_it "#list_status returns a typed SystemResource" do
    system = Radarr::Api::System.new(IntegrationHelper.client)

    status = present(system.list_status)
    status.app_name.should eq("Radarr")
    present(status.version).should_not be_empty
    # A containerised Radarr always reports these.
    status.is_docker.should be_true
    status.is_linux.should be_true
  end
end
