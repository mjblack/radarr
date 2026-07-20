require "../integration_helper"

# Api::Command#list — Radarr's command/task queue. A bare instance runs
# scheduled housekeeping commands, so this returns a typed array (possibly
# empty). Verifies the typed round-trip without triggering anything that needs
# indexers or download clients.
describe "integration: Api::Command" do
  integration_it "#list returns a typed array of commands" do
    commands = Radarr::Api::Command.new(IntegrationHelper.client).list

    # If any command is present it carries a name; tolerate an empty queue.
    if first = commands.first?
      present(first.name).should_not be_empty
    end
  end
end
