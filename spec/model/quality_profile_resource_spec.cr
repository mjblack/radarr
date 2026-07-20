require "../spec_helper"

describe Radarr::Model::QualityProfileResource do
  it "parses an empty object (arrays default to empty)" do
    profile = Radarr::Model::QualityProfileResource.from_json("{}")
    profile.id.should be_nil
    profile.name.should be_nil
    profile.language.should be_nil
    profile.items.should be_empty
    profile.format_items.should be_empty
  end

  it "parses a fully-populated object with nested quality items" do
    json = %({
      "id": 1,
      "name": "HD-1080p",
      "upgradeAllowed": true,
      "cutoff": 9,
      "minFormatScore": 0,
      "cutoffFormatScore": 0,
      "minUpgradeFormatScore": 1,
      "language": #{SpecFixtures.language_json},
      "items": [
        {"id": 1, "name": "WEB 1080p", "allowed": true, "items": [
          {"quality": {"id": 3, "name": "WEBDL-1080p", "source": "webdl", "resolution": 1080}, "allowed": true}
        ]}
      ],
      "formatItems": [{"id": 1, "format": 2, "name": "x264", "score": 5}]
    })
    profile = Radarr::Model::QualityProfileResource.from_json(json)
    profile.id.should eq(1)
    profile.name.should eq("HD-1080p")
    profile.upgrade_allowed.should eq(true)
    profile.cutoff.should eq(9)
    profile.min_format_score.should eq(0)
    profile.cutoff_format_score.should eq(0)
    profile.min_upgrade_format_score.should eq(1)
    present(profile.language).name.should eq("English")

    profile.items.size.should eq(1)
    group = profile.items.first
    group.name.should eq("WEB 1080p")
    group.allowed.should eq(true)
    group.items.size.should eq(1)
    nested_quality = present(group.items.first.quality)
    nested_quality.name.should eq("WEBDL-1080p")
    nested_quality.source.should eq(Radarr::QualitySource::Webdl)

    profile.format_items.size.should eq(1)
    profile.format_items.first.format.should eq(2)
    profile.format_items.first.score.should eq(5)
  end
end
