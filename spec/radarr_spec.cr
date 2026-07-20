require "./spec_helper"

describe Radarr do
  it "exposes its version" do
    Radarr::VERSION.should eq("0.1.0")
  end
end
