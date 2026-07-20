require "../spec_helper"

describe Radarr::Model::SelectOption do
  it "parses an empty object (all properties optional)" do
    opt = Radarr::Model::SelectOption.from_json("{}")
    opt.value.should be_nil
    opt.name.should be_nil
    opt.divider_after.should be_nil
  end

  it "parses a fully-populated object" do
    json = %({"value": 1, "name": "Option 1", "order": 2, "hint": "a hint", "dividerAfter": true})
    opt = Radarr::Model::SelectOption.from_json(json)
    opt.value.should eq(1)
    opt.name.should eq("Option 1")
    opt.order.should eq(2)
    opt.hint.should eq("a hint")
    opt.divider_after.should eq(true)
  end
end
