require "./spec_helper"

describe Radarr::Client do
  describe "timeouts" do
    it "defaults to 30s read / 10s connect" do
      Radarr::Client.default_read_timeout.should eq(30.seconds)
      Radarr::Client.default_connect_timeout.should eq(10.seconds)
    end

    it "applies the class defaults when no timeouts are given" do
      client = Radarr::Client.new("http://localhost:7878", "abc123")
      client.read_timeout.should eq(Radarr::Client.default_read_timeout)
      client.connect_timeout.should eq(Radarr::Client.default_connect_timeout)
    end

    it "resolves an explicit nil to the class default" do
      client = Radarr::Client.new(
        "http://localhost:7878",
        "abc123",
        read_timeout: nil,
        connect_timeout: nil,
      )
      client.read_timeout.should eq(Radarr::Client.default_read_timeout)
      client.connect_timeout.should eq(Radarr::Client.default_connect_timeout)
    end

    it "stores explicit timeout overrides (which win over the defaults)" do
      client = Radarr::Client.new(
        "http://localhost:7878",
        "abc123",
        read_timeout: 5.seconds,
        connect_timeout: 2.seconds,
      )
      client.read_timeout.should eq(5.seconds)
      client.connect_timeout.should eq(2.seconds)
    end

    it "lets a changed class default flow into a new client with no param" do
      original_read = Radarr::Client.default_read_timeout
      original_connect = Radarr::Client.default_connect_timeout
      begin
        Radarr::Client.default_read_timeout = 90.seconds
        Radarr::Client.default_connect_timeout = 15.seconds
        client = Radarr::Client.new("http://localhost:7878", "abc123")
        client.read_timeout.should eq(90.seconds)
        client.connect_timeout.should eq(15.seconds)
      ensure
        Radarr::Client.default_read_timeout = original_read
        Radarr::Client.default_connect_timeout = original_connect
      end
    end
  end

  describe Radarr::TimeoutError do
    it "is a rescuable Radarr::ApiError" do
      err = Radarr::TimeoutError.new
      err.should be_a(Radarr::ApiError)
      err.should be_a(Radarr::Error)
      err.status_code.should eq(0)
    end

    it "wraps an IO::TimeoutError with an informative message" do
      err = Radarr::TimeoutError.from_timeout(IO::TimeoutError.new("read timed out"))
      present(err.message).should contain("timed out")
    end
  end
end
