require "../spec_helper"

describe Radarr::Model::CollectionResource do
  it "parses an empty object (arrays default to empty)" do
    collection = Radarr::Model::CollectionResource.from_json("{}")
    collection.id.should be_nil
    collection.title.should be_nil
    collection.minimum_availability.should be_nil
    collection.movies.should be_empty
    collection.images.should be_empty
    collection.tags.should be_empty
  end

  it "parses a fully-populated object with nested movies" do
    json = %({
      "id": 1,
      "title": "The Test Collection",
      "sortTitle": "test collection",
      "tmdbId": 555,
      "images": [{"coverType": "poster", "url": "/poster.jpg"}],
      "overview": "A collection of tests",
      "monitored": true,
      "rootFolderPath": "/movies",
      "qualityProfileId": 1,
      "searchOnAdd": false,
      "minimumAvailability": "released",
      "missingMovies": 2,
      "tags": [3],
      "movies": [{
        "tmdbId": 22222,
        "imdbId": "tt1234567",
        "title": "Test Movie",
        "cleanTitle": "testmovie",
        "sortTitle": "test movie",
        "status": "released",
        "overview": "A test movie",
        "runtime": 120,
        "year": 2020,
        "ratings": {"tmdb": {"votes": 100, "value": 8.5, "type": "user"}},
        "genres": ["Action"],
        "folder": "Test Movie (2020)",
        "isExisting": false,
        "isExcluded": false
      }]
    })
    collection = Radarr::Model::CollectionResource.from_json(json)
    collection.id.should eq(1)
    collection.title.should eq("The Test Collection")
    collection.sort_title.should eq("test collection")
    collection.tmdb_id.should eq(555)
    collection.overview.should eq("A collection of tests")
    collection.monitored.should eq(true)
    collection.root_folder_path.should eq("/movies")
    collection.quality_profile_id.should eq(1)
    collection.search_on_add.should eq(false)
    collection.minimum_availability.should eq(Radarr::MovieStatusType::Released)
    collection.missing_movies.should eq(2)
    collection.tags.should eq([3])
    collection.images.size.should eq(1)
    collection.images.first.cover_type.should eq(Radarr::MediaCoverTypes::Poster)

    collection.movies.size.should eq(1)
    movie = collection.movies.first
    movie.tmdb_id.should eq(22222)
    movie.imdb_id.should eq("tt1234567")
    movie.title.should eq("Test Movie")
    movie.status.should eq(Radarr::MovieStatusType::Released)
    movie.year.should eq(2020)
    movie.is_existing.should eq(false)
    movie.is_excluded.should eq(false)
    present(present(movie.ratings).tmdb).value.should eq(8.5)
  end
end
