require "../spec_helper"

describe Radarr::Model::QueueResourcePagingResource do
  it "parses an empty object (records default to empty)" do
    paging = Radarr::Model::QueueResourcePagingResource.from_json("{}")
    paging.page.should be_nil
    paging.records.should be_empty
  end

  it "parses a fully-populated object" do
    json = %({
      "page": 1,
      "pageSize": 10,
      "sortKey": "timeleft",
      "sortDirection": "ascending",
      "totalRecords": 100,
      "records": [{"id": 1, "movie": #{SpecFixtures.movie_json}, "quality": #{SpecFixtures.quality_model_json}, "size": 123456, "status": "queued"}]
    })
    paging = Radarr::Model::QueueResourcePagingResource.from_json(json)
    paging.page.should eq(1)
    paging.page_size.should eq(10)
    paging.sort_key.should eq("timeleft")
    paging.sort_direction.should eq(Radarr::SortDirection::Ascending)
    paging.total_records.should eq(100)
    paging.records.size.should eq(1)
    paging.records.first.status.should eq(Radarr::QueueStatus::Queued)
  end
end
