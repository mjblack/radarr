require "../spec_helper"

describe Radarr::Model::MovieFileResource do
  it "parses an empty object (arrays default to empty)" do
    file = Radarr::Model::MovieFileResource.from_json("{}")
    file.id.should be_nil
    file.quality.should be_nil
    file.media_info.should be_nil
    file.languages.should be_empty
    file.custom_formats.should be_empty
  end

  it "parses a fully-populated object" do
    json = %({
      "id": 10,
      "movieId": 2,
      "relativePath": "Test Movie (2020).mkv",
      "path": "/movies/Test Movie/Test Movie (2020).mkv",
      "size": 987654321,
      "dateAdded": "2023-01-01T12:00:00Z",
      "sceneName": "Test.Movie.2020.1080p.BluRay.x264-GROUP",
      "releaseGroup": "GROUP",
      "edition": "Director's Cut",
      "languages": [#{SpecFixtures.language_json}],
      "quality": #{SpecFixtures.quality_model_json},
      "customFormatScore": 25,
      "indexerFlags": 1,
      "mediaInfo": {"id": 3, "audioCodec": "DTS", "audioChannels": 5.1, "videoCodec": "x264", "resolution": "1920x1080", "runTime": "2:00:00"},
      "qualityCutoffNotMet": false
    })
    file = Radarr::Model::MovieFileResource.from_json(json)
    file.id.should eq(10)
    file.movie_id.should eq(2)
    file.relative_path.should eq("Test Movie (2020).mkv")
    file.path.should eq("/movies/Test Movie/Test Movie (2020).mkv")
    file.size.should eq(987654321_i64)
    file.date_added.should eq(Time.utc(2023, 1, 1, 12, 0, 0))
    file.scene_name.should eq("Test.Movie.2020.1080p.BluRay.x264-GROUP")
    file.release_group.should eq("GROUP")
    file.edition.should eq("Director's Cut")
    file.languages.size.should eq(1)
    file.languages.first.name.should eq("English")
    file.custom_format_score.should eq(25)
    file.indexer_flags.should eq(1)
    file.quality_cutoff_not_met.should eq(false)

    quality = present(present(file.quality).quality)
    quality.id.should eq(1)
    quality.source.should eq(Radarr::QualitySource::Bluray)

    media = present(file.media_info)
    media.id.should eq(3)
    media.audio_codec.should eq("DTS")
    media.audio_channels.should eq(5.1)
    media.video_codec.should eq("x264")
    media.resolution.should eq("1920x1080")
  end
end
