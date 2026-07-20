require "../spec_helper"

describe Radarr::Model::Quality do
  it "parses an empty object (all properties optional)" do
    quality = Radarr::Model::Quality.from_json("{}")
    quality.id.should be_nil
    quality.name.should be_nil
    quality.source.should be_nil
    quality.resolution.should be_nil
    quality.modifier.should be_nil
  end

  it "parses a fully-populated object" do
    json = %({"id": 30, "name": "Remux-2160p", "source": "bluray", "resolution": 2160, "modifier": "remux"})
    quality = Radarr::Model::Quality.from_json(json)
    quality.id.should eq(30)
    quality.name.should eq("Remux-2160p")
    quality.source.should eq(Radarr::QualitySource::Bluray)
    quality.resolution.should eq(2160)
    quality.modifier.should eq(Radarr::Modifier::Remux)
  end

  it "round-trips the source enum as camelCase" do
    quality = Radarr::Model::Quality.from_json(%({"source": "webdl"}))
    quality.source.should eq(Radarr::QualitySource::Webdl)
    quality.to_json.should contain(%("source":"webdl"))
  end
end
