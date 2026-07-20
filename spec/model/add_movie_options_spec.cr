require "../spec_helper"

describe Radarr::Model::AddMovieOptions do
  it "parses an empty object (all properties optional)" do
    options = Radarr::Model::AddMovieOptions.from_json("{}")
    options.monitor.should be_nil
    options.add_method.should be_nil
    options.search_for_movie.should be_nil
  end

  it "parses a fully-populated object" do
    json = %({
      "ignoreEpisodesWithFiles": false,
      "ignoreEpisodesWithoutFiles": true,
      "monitor": "movieAndCollection",
      "searchForMovie": true,
      "addMethod": "collection"
    })
    options = Radarr::Model::AddMovieOptions.from_json(json)
    options.ignore_episodes_with_files.should eq(false)
    options.ignore_episodes_without_files.should eq(true)
    options.monitor.should eq(Radarr::MonitorTypes::MovieAndCollection)
    options.search_for_movie.should eq(true)
    options.add_method.should eq(Radarr::AddMovieMethod::Collection)
    options.to_json.should contain(%("monitor":"movieAndCollection"))
  end
end
