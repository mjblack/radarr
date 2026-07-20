require "../spec_helper"

describe Radarr::Model::AlternativeTitleResource do
  it "parses an empty object (all properties optional)" do
    title = Radarr::Model::AlternativeTitleResource.from_json("{}")
    title.id.should be_nil
    title.source_type.should be_nil
    title.title.should be_nil
  end

  it "parses a fully-populated object" do
    json = %({
      "id": 1,
      "sourceType": "tmdb",
      "movieMetadataId": 5,
      "title": "Alternative Title",
      "cleanTitle": "alternativetitle"
    })
    title = Radarr::Model::AlternativeTitleResource.from_json(json)
    title.id.should eq(1)
    title.source_type.should eq(Radarr::SourceType::Tmdb)
    title.movie_metadata_id.should eq(5)
    title.title.should eq("Alternative Title")
    title.clean_title.should eq("alternativetitle")
    title.to_json.should contain(%("sourceType":"tmdb"))
  end
end
