require "spec"
require "../src/radarr"

# Unwraps a nilable value, failing the example (at the caller) if it is nil.
#
# Every generated model property is nilable (`T?`), so specs constantly need to
# assert a value is present before drilling into it. `present` keeps that
# concise while still producing a clear spec failure on an unexpected nil.
def present(value : T?, file = __FILE__, line = __LINE__) : T forall T
  value.should_not(be_nil, file: file, line: line)
  value.not_nil! # ameba:disable Lint/NotNil
end

# Shared JSON fixtures for the model specs.
#
# The models are generated from `ext/schema.json` with every property nilable,
# so these fixtures build up valid, fully-shaped nested objects that individual
# specs can embed without repeating large literals.
module SpecFixtures
  extend self

  # A `QualityModel` (nested `quality` + `revision`).
  def quality_model_json : String
    <<-JSON
    {"quality": {"id": 1, "name": "Bluray-1080p", "source": "bluray", "resolution": 1080, "modifier": "none"}, "revision": {"version": 1, "real": 0, "isRepack": false}}
    JSON
  end

  # A `MovieResource` with ratings/statistics/collection/addOptions populated.
  def movie_json : String
    <<-JSON
    {"id": 2, "title": "Test Movie", "originalTitle": "Test Movie Original", "originalLanguage": {"id": 1, "name": "English"}, "year": 2020, "status": "released", "qualityProfileId": 1, "monitored": true, "minimumAvailability": "released", "hasFile": true, "movieFileId": 5, "isAvailable": true, "tmdbId": 22222, "imdbId": "tt1234567", "runtime": 120, "sizeOnDisk": 1024, "added": "2020-01-01T12:00:00Z", "inCinemas": "2020-01-01T00:00:00Z", "path": "/movies/Test Movie", "studio": "Test Studio", "genres": ["Action", "Drama"], "tags": [1, 2], "popularity": 12.5, "ratings": {"tmdb": {"votes": 100, "value": 8.5, "type": "user"}, "imdb": {"votes": 200, "value": 7.9, "type": "user"}}, "statistics": {"movieFileCount": 1, "sizeOnDisk": 1024, "releaseGroups": ["GROUP"]}, "addOptions": {"monitor": "movieOnly", "searchForMovie": false, "addMethod": "manual"}, "collection": {"title": "Test Collection", "tmdbId": 999}}
    JSON
  end

  # A `Language`.
  def language_json : String
    <<-JSON
    {"id": 1, "name": "English"}
    JSON
  end
end
