require "../spec_helper"

describe Radarr::Model::CustomFormatResource do
  it "parses an empty object (arrays default to empty)" do
    format = Radarr::Model::CustomFormatResource.from_json("{}")
    format.id.should be_nil
    format.name.should be_nil
    format.specifications.should be_empty
  end

  it "parses a fully-populated object with specifications" do
    json = %({
      "id": 1,
      "name": "x264",
      "includeCustomFormatWhenRenaming": true,
      "specifications": [{
        "name": "codec",
        "implementation": "ReleaseTitleSpecification",
        "implementationName": "Release Title",
        "negate": false,
        "required": true,
        "fields": [{"name": "value", "value": "x264", "type": "textbox"}]
      }]
    })
    format = Radarr::Model::CustomFormatResource.from_json(json)
    format.id.should eq(1)
    format.name.should eq("x264")
    format.include_custom_format_when_renaming.should eq(true)
    format.specifications.size.should eq(1)
    spec = format.specifications.first
    spec.name.should eq("codec")
    spec.implementation.should eq("ReleaseTitleSpecification")
    spec.negate.should eq(false)
    spec.required.should eq(true)
    spec.fields.size.should eq(1)
    spec.fields.first.name.should eq("value")
  end
end
