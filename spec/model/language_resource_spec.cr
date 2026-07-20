require "../spec_helper"

describe Radarr::Model::LanguageResource do
  it "parses an empty object (all properties optional)" do
    lang = Radarr::Model::LanguageResource.from_json("{}")
    lang.id.should be_nil
    lang.name.should be_nil
    lang.name_lower.should be_nil
  end

  it "parses a fully-populated object" do
    json = %({"id": 1, "name": "English", "nameLower": "english"})
    lang = Radarr::Model::LanguageResource.from_json(json)
    lang.id.should eq(1)
    lang.name.should eq("English")
    lang.name_lower.should eq("english")
  end
end
