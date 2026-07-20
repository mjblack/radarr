require "../spec_helper"

describe Radarr::Model::Ratings do
  it "parses an empty object (all properties optional)" do
    ratings = Radarr::Model::Ratings.from_json("{}")
    ratings.imdb.should be_nil
    ratings.tmdb.should be_nil
    ratings.metacritic.should be_nil
    ratings.rotten_tomatoes.should be_nil
    ratings.trakt.should be_nil
  end

  it "parses a fully-populated object with nested rating children" do
    json = %({
      "imdb": {"votes": 200, "value": 7.9, "type": "user"},
      "tmdb": {"votes": 100, "value": 8.5, "type": "user"},
      "metacritic": {"votes": 0, "value": 74.0, "type": "critic"},
      "rottenTomatoes": {"votes": 0, "value": 88.0, "type": "critic"},
      "trakt": {"votes": 50, "value": 8.1, "type": "user"}
    })
    ratings = Radarr::Model::Ratings.from_json(json)
    imdb = present(ratings.imdb)
    imdb.votes.should eq(200)
    imdb.value.should eq(7.9)
    imdb.type_field.should eq(Radarr::RatingType::User)

    present(ratings.tmdb).value.should eq(8.5)
    present(ratings.metacritic).type_field.should eq(Radarr::RatingType::Critic)
    present(ratings.rotten_tomatoes).value.should eq(88.0)
    present(ratings.trakt).votes.should eq(50)
  end

  it "round-trips the rottenTomatoes key as camelCase" do
    ratings = Radarr::Model::Ratings.from_json(%({"rottenTomatoes": {"votes": 1, "value": 90.0, "type": "critic"}}))
    ratings.to_json.should contain(%("rottenTomatoes":))
  end
end
