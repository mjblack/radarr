require "../spec_helper"

describe Radarr::Model::HistoryResource do
  it "parses an empty object (arrays default to empty)" do
    history = Radarr::Model::HistoryResource.from_json("{}")
    history.id.should be_nil
    history.quality.should be_nil
    history.event_type.should be_nil
    history.data.should be_nil
    history.movie.should be_nil
    history.languages.should be_empty
    history.custom_formats.should be_empty
  end

  it "parses a fully-populated object" do
    json = %({
      "id": 1,
      "movieId": 2,
      "sourceTitle": "Test.Movie.2020.1080p.BluRay.x264",
      "languages": [#{SpecFixtures.language_json}],
      "quality": #{SpecFixtures.quality_model_json},
      "customFormatScore": 0,
      "qualityCutoffNotMet": false,
      "date": "2023-01-01T12:00:00Z",
      "downloadId": "download123",
      "eventType": "grabbed",
      "data": {"indexer": "TestIndexer", "protocol": "usenet"}
    })
    history = Radarr::Model::HistoryResource.from_json(json)
    history.id.should eq(1)
    history.movie_id.should eq(2)
    history.source_title.should eq("Test.Movie.2020.1080p.BluRay.x264")
    history.languages.size.should eq(1)

    history_quality = present(present(history.quality).quality)
    history_quality.id.should eq(1)
    history_quality.source.should eq(Radarr::QualitySource::Bluray)

    history.quality_cutoff_not_met.should eq(false)
    history.date.should eq(Time.utc(2023, 1, 1, 12, 0, 0))
    history.download_id.should eq("download123")
    history.event_type.should eq(Radarr::MovieHistoryEventType::Grabbed)

    data = present(history.data)
    data["indexer"].should eq("TestIndexer")
    data["protocol"].should eq("usenet")
  end

  it "round-trips the eventType enum as camelCase" do
    history = Radarr::Model::HistoryResource.from_json(%({"eventType": "downloadFolderImported"}))
    history.event_type.should eq(Radarr::MovieHistoryEventType::DownloadFolderImported)
    history.to_json.should contain(%("eventType":"downloadFolderImported"))
  end
end
