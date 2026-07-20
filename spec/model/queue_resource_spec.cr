require "../spec_helper"

describe Radarr::Model::QueueResource do
  it "parses an empty object (arrays default to empty)" do
    queue = Radarr::Model::QueueResource.from_json("{}")
    queue.id.should be_nil
    queue.movie.should be_nil
    queue.quality.should be_nil
    queue.status.should be_nil
    queue.languages.should be_empty
    queue.custom_formats.should be_empty
    queue.status_messages.should be_empty
  end

  it "parses a fully-populated object" do
    json = %({
      "id": 1,
      "movieId": 2,
      "movie": #{SpecFixtures.movie_json},
      "languages": [#{SpecFixtures.language_json}],
      "quality": #{SpecFixtures.quality_model_json},
      "customFormatScore": 15,
      "size": 123456,
      "title": "Test.Movie.2020.1080p",
      "status": "queued",
      "trackedDownloadStatus": "ok",
      "trackedDownloadState": "downloading",
      "protocol": "usenet",
      "downloadClient": "SABnzbd",
      "indexer": "TestIndexer",
      "sizeleft": 6543,
      "timeleft": "00:10:00"
    })
    queue = Radarr::Model::QueueResource.from_json(json)
    queue.id.should eq(1)
    queue.movie_id.should eq(2)
    present(queue.movie).id.should eq(2)
    queue.languages.size.should eq(1)
    queue.languages.first.name.should eq("English")

    quality = present(queue.quality)
    present(quality.quality).id.should eq(1)
    present(quality.quality).source.should eq(Radarr::QualitySource::Bluray)
    present(quality.revision).version.should eq(1)

    queue.custom_format_score.should eq(15)
    queue.size.should eq(123456.0)
    queue.title.should eq("Test.Movie.2020.1080p")
    queue.status.should eq(Radarr::QueueStatus::Queued)
    queue.tracked_download_status.should eq(Radarr::TrackedDownloadStatus::Ok)
    queue.tracked_download_state.should eq(Radarr::TrackedDownloadState::Downloading)
    queue.protocol.should eq(Radarr::DownloadProtocol::Usenet)
    queue.download_client.should eq("SABnzbd")
    queue.indexer.should eq("TestIndexer")
    queue.sizeleft.should eq(6543.0)
    queue.timeleft.should eq("00:10:00")
  end
end
