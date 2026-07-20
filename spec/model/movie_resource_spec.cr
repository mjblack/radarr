require "../spec_helper"

describe Radarr::Model::MovieResource do
  it "parses an empty object (all properties optional, arrays default empty)" do
    movie = Radarr::Model::MovieResource.from_json("{}")
    movie.id.should be_nil
    movie.title.should be_nil
    movie.status.should be_nil
    movie.statistics.should be_nil
    movie.ratings.should be_nil
    movie.collection.should be_nil
    movie.alternate_titles.should be_empty
    movie.images.should be_empty
    movie.genres.should be_empty
    movie.keywords.should be_empty
    movie.tags.should be_empty
  end

  it "parses a fully-populated object" do
    movie = Radarr::Model::MovieResource.from_json(SpecFixtures.movie_json)
    movie.id.should eq(2)
    movie.title.should eq("Test Movie")
    movie.original_title.should eq("Test Movie Original")
    movie.status.should eq(Radarr::MovieStatusType::Released)
    movie.year.should eq(2020)
    movie.quality_profile_id.should eq(1)
    movie.monitored.should eq(true)
    movie.minimum_availability.should eq(Radarr::MovieStatusType::Released)
    movie.has_file.should eq(true)
    movie.movie_file_id.should eq(5)
    movie.is_available.should eq(true)
    movie.tmdb_id.should eq(22222)
    movie.imdb_id.should eq("tt1234567")
    movie.runtime.should eq(120)
    movie.size_on_disk.should eq(1024_i64)
    movie.added.should eq(Time.utc(2020, 1, 1, 12, 0, 0))
    movie.in_cinemas.should eq(Time.utc(2020, 1, 1, 0, 0, 0))
    movie.path.should eq("/movies/Test Movie")
    movie.studio.should eq("Test Studio")
    movie.genres.should eq(["Action", "Drama"])
    movie.tags.should eq([1, 2])
    movie.popularity.should eq(12.5)

    present(movie.original_language).id.should eq(1)
    present(movie.original_language).name.should eq("English")

    ratings = present(movie.ratings)
    present(ratings.tmdb).votes.should eq(100)
    present(ratings.tmdb).value.should eq(8.5)
    present(ratings.imdb).value.should eq(7.9)

    stats = present(movie.statistics)
    stats.movie_file_count.should eq(1)
    stats.size_on_disk.should eq(1024_i64)
    stats.release_groups.should eq(["GROUP"])

    add_options = present(movie.add_options)
    add_options.monitor.should eq(Radarr::MonitorTypes::MovieOnly)
    add_options.search_for_movie.should eq(false)
    add_options.add_method.should eq(Radarr::AddMovieMethod::Manual)

    collection = present(movie.collection)
    collection.title.should eq("Test Collection")
    collection.tmdb_id.should eq(999)
  end

  it "round-trips enums as camelCase and back" do
    movie = Radarr::Model::MovieResource.from_json(SpecFixtures.movie_json)
    json = movie.to_json
    json.should contain(%("status":"released"))
    json.should contain(%("minimumAvailability":"released"))
    json.should contain(%("monitor":"movieOnly"))

    reparsed = Radarr::Model::MovieResource.from_json(json)
    reparsed.status.should eq(Radarr::MovieStatusType::Released)
    reparsed.minimum_availability.should eq(Radarr::MovieStatusType::Released)
    present(reparsed.add_options).monitor.should eq(Radarr::MonitorTypes::MovieOnly)
  end
end
