require "../spec_helper"

describe Radarr::Model::NotificationResource do
  it "parses an empty object (arrays default to empty)" do
    notification = Radarr::Model::NotificationResource.from_json("{}")
    notification.id.should be_nil
    notification.fields.should be_empty
    notification.tags.should be_empty
    notification.presets.should be_empty
    notification.on_grab.should be_nil
  end

  it "parses a fully-populated object" do
    json = %({
      "id": 1,
      "name": "Discord",
      "fields": [{"name": "webHookUrl", "label": "Webhook", "value": "http://hook", "type": "textbox"}],
      "implementationName": "Discord",
      "implementation": "Discord",
      "configContract": "DiscordSettings",
      "infoLink": "http://example.com",
      "tags": [2],
      "link": "http://discord",
      "onGrab": true,
      "onDownload": true,
      "onUpgrade": false,
      "onRename": false,
      "onMovieAdded": true,
      "onMovieDelete": false,
      "onMovieFileDelete": false,
      "onMovieFileDeleteForUpgrade": true,
      "onHealthIssue": true,
      "includeHealthWarnings": false,
      "onHealthRestored": true,
      "onApplicationUpdate": false,
      "onManualInteractionRequired": true,
      "supportsOnGrab": true,
      "supportsOnDownload": true,
      "testCommand": "test"
    })
    notification = Radarr::Model::NotificationResource.from_json(json)
    notification.id.should eq(1)
    notification.name.should eq("Discord")
    notification.fields.size.should eq(1)
    notification.fields.first.name.should eq("webHookUrl")
    notification.implementation.should eq("Discord")
    notification.config_contract.should eq("DiscordSettings")
    notification.tags.should eq([2])
    notification.link.should eq("http://discord")
    notification.on_grab.should eq(true)
    notification.on_download.should eq(true)
    notification.on_upgrade.should eq(false)
    notification.on_movie_added.should eq(true)
    notification.on_movie_file_delete_for_upgrade.should eq(true)
    notification.on_health_issue.should eq(true)
    notification.include_health_warnings.should eq(false)
    notification.on_health_restored.should eq(true)
    notification.on_application_update.should eq(false)
    notification.on_manual_interaction_required.should eq(true)
    notification.supports_on_grab.should eq(true)
    notification.supports_on_download.should eq(true)
    notification.test_command.should eq("test")
  end
end
