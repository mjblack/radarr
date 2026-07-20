require "../spec_helper"

describe Radarr::Model::Command do
  it "parses an empty object (all properties optional)" do
    body = Radarr::Model::Command.from_json("{}")
    body.name.should be_nil
    body.trigger.should be_nil
    body.send_updates_to_client.should be_nil
  end

  it "parses a fully-populated object" do
    json = %({
      "sendUpdatesToClient": true,
      "updateScheduledTask": false,
      "completionMessage": "Completed",
      "requiresDiskAccess": true,
      "isExclusive": false,
      "isTypeExclusive": true,
      "isLongRunning": false,
      "name": "RefreshMovie",
      "lastExecutionTime": "2023-01-01T12:00:00Z",
      "lastStartTime": "2023-01-01T12:01:00Z",
      "trigger": "scheduled",
      "suppressMessages": false,
      "clientUserAgent": "SpecAgent"
    })
    body = Radarr::Model::Command.from_json(json)
    body.send_updates_to_client.should eq(true)
    body.update_scheduled_task.should eq(false)
    body.completion_message.should eq("Completed")
    body.requires_disk_access.should eq(true)
    body.is_exclusive.should eq(false)
    body.is_type_exclusive.should eq(true)
    body.is_long_running.should eq(false)
    body.name.should eq("RefreshMovie")
    body.last_execution_time.should eq(Time.utc(2023, 1, 1, 12, 0, 0))
    body.last_start_time.should eq(Time.utc(2023, 1, 1, 12, 1, 0))
    body.trigger.should eq(Radarr::CommandTrigger::Scheduled)
    body.suppress_messages.should eq(false)
    body.client_user_agent.should eq("SpecAgent")
  end
end
