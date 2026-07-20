require "../spec_helper"

describe Radarr::Model::HistoryResourcePagingResource do
  it "parses an empty object (records default to empty)" do
    paging = Radarr::Model::HistoryResourcePagingResource.from_json("{}")
    paging.page.should be_nil
    paging.records.should be_empty
  end

  it "parses a fully-populated object" do
    json = %({
      "page": 2,
      "pageSize": 20,
      "sortKey": "date",
      "sortDirection": "descending",
      "totalRecords": 50,
      "records": [{"id": 1, "movieId": 2, "eventType": "grabbed", "quality": #{SpecFixtures.quality_model_json}}]
    })
    paging = Radarr::Model::HistoryResourcePagingResource.from_json(json)
    paging.page.should eq(2)
    paging.page_size.should eq(20)
    paging.sort_key.should eq("date")
    paging.sort_direction.should eq(Radarr::SortDirection::Descending)
    paging.total_records.should eq(50)
    paging.records.size.should eq(1)
    paging.records.first.event_type.should eq(Radarr::MovieHistoryEventType::Grabbed)
  end
end
