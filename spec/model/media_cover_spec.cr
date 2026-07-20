require "../spec_helper"

describe Radarr::Model::MediaCover do
  it "parses an empty object (all properties optional)" do
    cover = Radarr::Model::MediaCover.from_json("{}")
    cover.cover_type.should be_nil
    cover.url.should be_nil
    cover.remote_url.should be_nil
  end

  it "parses a fully-populated object" do
    json = %({
      "coverType": "poster",
      "url": "http://example.com/poster.jpg",
      "remoteUrl": "http://example.com/remote.jpg"
    })
    cover = Radarr::Model::MediaCover.from_json(json)
    cover.cover_type.should eq(Radarr::MediaCoverTypes::Poster)
    cover.url.should eq("http://example.com/poster.jpg")
    cover.remote_url.should eq("http://example.com/remote.jpg")
  end

  it "round-trips the coverType enum as camelCase" do
    cover = Radarr::Model::MediaCover.from_json(%({"coverType": "clearlogo"}))
    cover.to_json.should contain(%("coverType":"clearlogo"))
    Radarr::Model::MediaCover.from_json(cover.to_json).cover_type
      .should eq(Radarr::MediaCoverTypes::Clearlogo)
  end
end
