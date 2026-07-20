require "../spec_helper"

describe Radarr::Model::Field do
  it "parses an empty object (all properties optional)" do
    field = Radarr::Model::Field.from_json("{}")
    field.name.should be_nil
    field.value.should be_nil
    field.select_options.should be_empty
  end

  it "parses a fully-populated object" do
    json = %({
      "order": 1,
      "name": "testField",
      "label": "Test Field",
      "unit": "bytes",
      "helpText": "Help text",
      "helpLink": "http://example.com/help",
      "value": "test value",
      "type": "textbox",
      "advanced": false,
      "selectOptions": [{"value": 1, "name": "Option 1"}],
      "selectOptionsProviderAction": "testAction",
      "section": "testSection",
      "hidden": "false",
      "privacy": "normal",
      "placeholder": "Enter value",
      "isFloat": false
    })
    field = Radarr::Model::Field.from_json(json)
    field.order.should eq(1)
    field.name.should eq("testField")
    field.label.should eq("Test Field")
    field.unit.should eq("bytes")
    field.help_text.should eq("Help text")
    field.help_link.should eq("http://example.com/help")
    present(field.value).as_s.should eq("test value")
    field.type_field.should eq("textbox")
    field.advanced.should eq(false)
    field.select_options.size.should eq(1)
    field.select_options.first.name.should eq("Option 1")
    field.select_options_provider_action.should eq("testAction")
    field.section.should eq("testSection")
    field.hidden.should eq("false")
    field.privacy.should eq(Radarr::PrivacyLevel::Normal)
    field.placeholder.should eq("Enter value")
    field.is_float.should eq(false)
  end
end
