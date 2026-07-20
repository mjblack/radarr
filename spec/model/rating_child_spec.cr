require "../spec_helper"

describe Radarr::Model::RatingChild do
  it "parses an empty object (all properties optional)" do
    child = Radarr::Model::RatingChild.from_json("{}")
    child.votes.should be_nil
    child.value.should be_nil
    child.type_field.should be_nil
  end

  it "parses a fully-populated object" do
    child = Radarr::Model::RatingChild.from_json(%({"votes": 42, "value": 7.8, "type": "critic"}))
    child.votes.should eq(42)
    child.value.should eq(7.8)
    child.type_field.should eq(Radarr::RatingType::Critic)
    child.to_json.should contain(%("type":"critic"))
  end
end
