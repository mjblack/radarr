require "../spec_helper"

describe Radarr::Model::TagDetailsResource do
  it "parses an empty object (arrays default to empty)" do
    tag = Radarr::Model::TagDetailsResource.from_json("{}")
    tag.id.should be_nil
    tag.label.should be_nil
    tag.movie_ids.should be_empty
    tag.notification_ids.should be_empty
    tag.indexer_ids.should be_empty
  end

  it "parses a fully-populated object" do
    json = %({
      "id": 1,
      "label": "Test Tag",
      "delayProfileIds": [1],
      "importListIds": [2],
      "notificationIds": [3],
      "releaseProfileIds": [4],
      "indexerIds": [5],
      "downloadClientIds": [6],
      "autoTagIds": [7],
      "movieIds": [8, 9]
    })
    tag = Radarr::Model::TagDetailsResource.from_json(json)
    tag.id.should eq(1)
    tag.label.should eq("Test Tag")
    tag.delay_profile_ids.should eq([1])
    tag.import_list_ids.should eq([2])
    tag.notification_ids.should eq([3])
    tag.release_profile_ids.should eq([4])
    tag.indexer_ids.should eq([5])
    tag.download_client_ids.should eq([6])
    tag.auto_tag_ids.should eq([7])
    tag.movie_ids.should eq([8, 9])
  end
end
