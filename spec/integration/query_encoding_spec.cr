require "../integration_helper"

# Validates the array-query encoding against a LIVE Radarr: Radarr::Query renders
# Array values as REPEATED keys, e.g. `movieIds=1&movieIds=2`, matching ASP.NET
# Core model binding, and enum values as their exact schema string (e.g.
# `ascending`).
#
# These specs drive real paged endpoints whose typed methods take Array(Int32)
# ids plus an enum query param, and confirm the live server ACCEPTS the encoding
# (clean 2xx + a well-formed, typed paging envelope) rather than 400-ing on it.
describe "integration: array/enum query encoding" do
  # Paging + an enum query param (sortDirection) + a repeated-key Array(Int32)
  # (movieIds). Confirms the enum serializes to `ascending` and the array
  # repeats as `movieIds=1&movieIds=2`, all accepted by the live server.
  integration_it "Api::Queue#list accepts paging + enum + Array(Int32) params" do
    page = present(Radarr::Api::Queue.new(IntegrationHelper.client).list(
      page: 1,
      page_size: 20,
      sort_direction: Radarr::SortDirection::Ascending,
      movie_ids: [1, 2],
    ))

    # A bare instance has an empty queue, but the paging envelope is well-formed.
    page.page.should eq(1)
    page.page_size.should eq(20)
    page.total_records.should eq(0)
    page.records.should be_empty
  end

  # History paging endpoint driven with several repeated-key Array(Int32) params
  # at once (movieIds, languages, quality) plus an enum direction.
  integration_it "Api::History#list accepts multiple repeated-key arrays" do
    page = present(Radarr::Api::History.new(IntegrationHelper.client).list(
      page: 1,
      page_size: 10,
      sort_direction: Radarr::SortDirection::Descending,
      movie_ids: [1, 2, 3],
      languages: [1],
      quality: [1, 2],
    ))

    page.page.should eq(1)
    page.page_size.should eq(10)
    page.total_records.should eq(0)
    page.records.should be_empty
  end
end
