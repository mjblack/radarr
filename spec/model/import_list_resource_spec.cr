require "../spec_helper"

describe Radarr::Model::ImportListResource do
  it "parses an empty object (arrays default to empty)" do
    list = Radarr::Model::ImportListResource.from_json("{}")
    list.id.should be_nil
    list.fields.should be_empty
    list.tags.should be_empty
    list.monitor.should be_nil
    list.list_type.should be_nil
  end

  it "parses a fully-populated object" do
    json = %({
      "id": 1,
      "name": "TMDb List",
      "fields": [{"name": "listId", "label": "List", "value": "123", "type": "textbox"}],
      "implementationName": "TMDb List",
      "implementation": "TMDbListImport",
      "configContract": "TMDbListSettings",
      "infoLink": "http://example.com",
      "tags": [1],
      "enabled": true,
      "enableAuto": true,
      "monitor": "movieOnly",
      "rootFolderPath": "/movies",
      "qualityProfileId": 1,
      "searchOnAdd": false,
      "minimumAvailability": "released",
      "listType": "tmdb",
      "listOrder": 2,
      "minRefreshInterval": "24:00:00"
    })
    list = Radarr::Model::ImportListResource.from_json(json)
    list.id.should eq(1)
    list.name.should eq("TMDb List")
    list.fields.size.should eq(1)
    list.fields.first.name.should eq("listId")
    list.implementation.should eq("TMDbListImport")
    list.config_contract.should eq("TMDbListSettings")
    list.tags.should eq([1])
    list.enabled.should eq(true)
    list.enable_auto.should eq(true)
    list.monitor.should eq(Radarr::MonitorTypes::MovieOnly)
    list.root_folder_path.should eq("/movies")
    list.quality_profile_id.should eq(1)
    list.search_on_add.should eq(false)
    list.minimum_availability.should eq(Radarr::MovieStatusType::Released)
    list.list_type.should eq(Radarr::ImportListType::Tmdb)
    list.list_order.should eq(2)
    list.min_refresh_interval.should eq("24:00:00")
  end
end
