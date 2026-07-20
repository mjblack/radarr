require "../spec_helper"

describe Radarr::Model::QualityModel do
  it "parses an empty object (all properties optional)" do
    model = Radarr::Model::QualityModel.from_json("{}")
    model.quality.should be_nil
    model.revision.should be_nil
  end

  it "parses a fully-populated object" do
    model = Radarr::Model::QualityModel.from_json(SpecFixtures.quality_model_json)
    quality = present(model.quality)
    quality.id.should eq(1)
    quality.name.should eq("Bluray-1080p")
    quality.source.should eq(Radarr::QualitySource::Bluray)
    quality.resolution.should eq(1080)
    quality.modifier.should eq(Radarr::Modifier::None)

    revision = present(model.revision)
    revision.version.should eq(1)
    revision.real.should eq(0)
    revision.is_repack.should eq(false)
  end
end
