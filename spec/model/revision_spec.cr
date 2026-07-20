require "../spec_helper"

describe Radarr::Model::Revision do
  it "parses an empty object (all properties optional)" do
    revision = Radarr::Model::Revision.from_json("{}")
    revision.version.should be_nil
    revision.real.should be_nil
    revision.is_repack.should be_nil
  end

  it "parses a fully-populated object" do
    revision = Radarr::Model::Revision.from_json(%({"version": 2, "real": 1, "isRepack": true}))
    revision.version.should eq(2)
    revision.real.should eq(1)
    revision.is_repack.should eq(true)
    revision.to_json.should contain(%("isRepack":true))
  end
end
