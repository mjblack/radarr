require "../spec_helper"

describe Radarr::Model::RootFolderResource do
  it "parses an empty object (arrays default to empty)" do
    folder = Radarr::Model::RootFolderResource.from_json("{}")
    folder.id.should be_nil
    folder.path.should be_nil
    folder.unmapped_folders.should be_empty
  end

  it "parses a fully-populated object" do
    json = %({
      "id": 1,
      "path": "/movies",
      "accessible": true,
      "freeSpace": 1099511627776,
      "unmappedFolders": [{"name": "Old Movie", "path": "/movies/Old Movie", "relativePath": "Old Movie"}]
    })
    folder = Radarr::Model::RootFolderResource.from_json(json)
    folder.id.should eq(1)
    folder.path.should eq("/movies")
    folder.accessible.should eq(true)
    folder.free_space.should eq(1099511627776_i64)
    folder.unmapped_folders.size.should eq(1)
    folder.unmapped_folders.first.name.should eq("Old Movie")
    folder.unmapped_folders.first.relative_path.should eq("Old Movie")
  end
end
