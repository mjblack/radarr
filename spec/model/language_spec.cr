require "../spec_helper"

describe Radarr::Model::Language do
  it "parses an empty object (all properties optional)" do
    lang = Radarr::Model::Language.from_json("{}")
    lang.id.should be_nil
    lang.name.should be_nil
  end

  it "parses a fully-populated object" do
    lang = Radarr::Model::Language.from_json(SpecFixtures.language_json)
    lang.id.should eq(1)
    lang.name.should eq("English")
  end
end
