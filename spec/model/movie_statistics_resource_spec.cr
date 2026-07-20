require "../spec_helper"

describe Radarr::Model::MovieStatisticsResource do
  it "parses an empty object (arrays default to empty)" do
    stats = Radarr::Model::MovieStatisticsResource.from_json("{}")
    stats.movie_file_count.should be_nil
    stats.size_on_disk.should be_nil
    stats.release_groups.should be_empty
  end

  it "parses a fully-populated object" do
    json = %({"movieFileCount": 2, "sizeOnDisk": 2048, "releaseGroups": ["A", "B"]})
    stats = Radarr::Model::MovieStatisticsResource.from_json(json)
    stats.movie_file_count.should eq(2)
    stats.size_on_disk.should eq(2048_i64)
    stats.release_groups.should eq(["A", "B"])
  end
end
