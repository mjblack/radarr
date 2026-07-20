require "../spec_helper"

describe Radarr::Model::DownloadClientResource do
  it "parses an empty object (arrays default to empty)" do
    client = Radarr::Model::DownloadClientResource.from_json("{}")
    client.id.should be_nil
    client.protocol.should be_nil
    client.fields.should be_empty
    client.tags.should be_empty
    client.presets.should be_empty
  end

  it "parses a fully-populated object" do
    json = %({
      "id": 1,
      "name": "SABnzbd",
      "fields": [{"name": "host", "label": "Host", "value": "localhost", "type": "textbox"}],
      "implementationName": "SABnzbd",
      "implementation": "Sabnzbd",
      "configContract": "SabnzbdSettings",
      "infoLink": "http://example.com/sab",
      "tags": [1],
      "enable": true,
      "protocol": "usenet",
      "priority": 1,
      "removeCompletedDownloads": true,
      "removeFailedDownloads": false
    })
    client = Radarr::Model::DownloadClientResource.from_json(json)
    client.id.should eq(1)
    client.name.should eq("SABnzbd")
    client.fields.size.should eq(1)
    client.fields.first.name.should eq("host")
    client.implementation_name.should eq("SABnzbd")
    client.implementation.should eq("Sabnzbd")
    client.config_contract.should eq("SabnzbdSettings")
    client.info_link.should eq("http://example.com/sab")
    client.tags.should eq([1])
    client.enable.should eq(true)
    client.protocol.should eq(Radarr::DownloadProtocol::Usenet)
    client.priority.should eq(1)
    client.remove_completed_downloads.should eq(true)
    client.remove_failed_downloads.should eq(false)
  end
end
