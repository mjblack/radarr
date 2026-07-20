require "../spec_helper"

describe Radarr::Model::IndexerResource do
  it "parses an empty object (arrays default to empty)" do
    indexer = Radarr::Model::IndexerResource.from_json("{}")
    indexer.id.should be_nil
    indexer.fields.should be_empty
    indexer.tags.should be_empty
    indexer.protocol.should be_nil
  end

  it "parses a fully-populated object" do
    json = %({
      "id": 1,
      "name": "Test Indexer",
      "protocol": "torrent",
      "supportsRss": true,
      "supportsSearch": true,
      "enableRss": true,
      "enableAutomaticSearch": true,
      "enableInteractiveSearch": false,
      "fields": [{"name": "baseUrl", "label": "URL", "value": "http://indexer", "type": "textbox", "advanced": false}],
      "implementationName": "Torznab",
      "implementation": "Torznab",
      "configContract": "TorznabSettings",
      "infoLink": "http://example.com",
      "priority": 25,
      "downloadClientId": 3,
      "tags": []
    })
    indexer = Radarr::Model::IndexerResource.from_json(json)
    indexer.id.should eq(1)
    indexer.name.should eq("Test Indexer")
    indexer.protocol.should eq(Radarr::DownloadProtocol::Torrent)
    indexer.supports_rss.should eq(true)
    indexer.supports_search.should eq(true)
    indexer.enable_rss.should eq(true)
    indexer.enable_automatic_search.should eq(true)
    indexer.enable_interactive_search.should eq(false)
    indexer.fields.size.should eq(1)
    indexer.fields.first.name.should eq("baseUrl")
    indexer.implementation_name.should eq("Torznab")
    indexer.implementation.should eq("Torznab")
    indexer.config_contract.should eq("TorznabSettings")
    indexer.info_link.should eq("http://example.com")
    indexer.priority.should eq(25)
    indexer.download_client_id.should eq(3)
    indexer.tags.should be_empty
  end
end
