require "../spec_helper"

describe Radarr::Model::CommandResource do
  it "parses an empty object (all properties optional)" do
    cmd = Radarr::Model::CommandResource.from_json("{}")
    cmd.id.should be_nil
    cmd.body.should be_nil
    cmd.priority.should be_nil
    cmd.queued.should be_nil
  end

  it "parses a fully-populated object" do
    json = %({
      "id": 1,
      "name": "RefreshMovie",
      "commandName": "RefreshMovie",
      "message": "Test message",
      "body": {"sendUpdatesToClient": true, "trigger": "manual", "name": "RefreshMovie"},
      "priority": "normal",
      "status": "started",
      "result": "successful",
      "queued": "2023-01-01T12:00:00Z",
      "started": "2023-01-01T12:01:00Z",
      "ended": "2023-01-01T12:02:00Z",
      "duration": "60",
      "exception": null,
      "trigger": "manual",
      "clientUserAgent": "SpecAgent",
      "stateChangeTime": "2023-01-01T12:01:00Z",
      "sendUpdatesToClient": true,
      "updateScheduledTask": false,
      "lastExecutionTime": "2023-01-01T12:00:00Z"
    })
    cmd = Radarr::Model::CommandResource.from_json(json)
    cmd.id.should eq(1)
    cmd.name.should eq("RefreshMovie")
    cmd.command_name.should eq("RefreshMovie")
    cmd.message.should eq("Test message")
    cmd.body.should be_a(Radarr::Model::Command)
    present(cmd.body).trigger.should eq(Radarr::CommandTrigger::Manual)
    cmd.priority.should eq(Radarr::CommandPriority::Normal)
    cmd.status.should eq(Radarr::CommandStatus::Started)
    cmd.result.should eq(Radarr::CommandResult::Successful)
    cmd.queued.should eq(Time.utc(2023, 1, 1, 12, 0, 0))
    cmd.started.should eq(Time.utc(2023, 1, 1, 12, 1, 0))
    cmd.ended.should eq(Time.utc(2023, 1, 1, 12, 2, 0))
    cmd.duration.should eq("60")
    cmd.exception.should be_nil
    cmd.trigger.should eq(Radarr::CommandTrigger::Manual)
    cmd.client_user_agent.should eq("SpecAgent")
    cmd.state_change_time.should eq(Time.utc(2023, 1, 1, 12, 1, 0))
    cmd.send_updates_to_client.should eq(true)
    cmd.update_scheduled_task.should eq(false)
    cmd.last_execution_time.should eq(Time.utc(2023, 1, 1, 12, 0, 0))
  end
end
