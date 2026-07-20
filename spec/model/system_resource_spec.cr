require "../spec_helper"

describe Radarr::Model::SystemResource do
  it "parses an empty object (all properties optional)" do
    system = Radarr::Model::SystemResource.from_json("{}")
    system.app_name.should be_nil
    system.mode.should be_nil
    system.database_type.should be_nil
    system.build_time.should be_nil
  end

  it "parses a fully-populated object" do
    json = %({
      "appName": "Radarr",
      "instanceName": "Test Instance",
      "version": "5.0.0",
      "buildTime": "2023-01-01T12:00:00Z",
      "isDebug": false,
      "isProduction": true,
      "isAdmin": true,
      "isUserInteractive": false,
      "startupPath": "/path/to/radarr",
      "appData": "/path/to/appdata",
      "osName": "Linux",
      "osVersion": "Ubuntu 22.04",
      "isNetCore": true,
      "isLinux": true,
      "isOsx": false,
      "isWindows": false,
      "isDocker": true,
      "mode": "console",
      "branch": "master",
      "databaseType": "sqLite",
      "databaseVersion": "3.36.0",
      "authentication": "forms",
      "migrationVersion": 1,
      "urlBase": "",
      "runtimeVersion": "6.0.0",
      "runtimeName": ".NET",
      "startTime": "2023-01-01T12:00:00Z",
      "packageVersion": "5.0.0",
      "packageAuthor": "Radarr Team",
      "packageUpdateMechanism": "docker",
      "packageUpdateMechanismMessage": "Docker container"
    })
    system = Radarr::Model::SystemResource.from_json(json)
    system.app_name.should eq("Radarr")
    system.instance_name.should eq("Test Instance")
    system.version.should eq("5.0.0")
    system.build_time.should eq(Time.utc(2023, 1, 1, 12, 0, 0))
    system.is_debug.should eq(false)
    system.is_production.should eq(true)
    system.is_admin.should eq(true)
    system.is_user_interactive.should eq(false)
    system.startup_path.should eq("/path/to/radarr")
    system.app_data.should eq("/path/to/appdata")
    system.os_name.should eq("Linux")
    system.os_version.should eq("Ubuntu 22.04")
    system.is_net_core.should eq(true)
    system.is_linux.should eq(true)
    system.is_osx.should eq(false)
    system.is_windows.should eq(false)
    system.is_docker.should eq(true)
    system.mode.should eq(Radarr::RuntimeMode::Console)
    system.branch.should eq("master")
    system.database_type.should eq(Radarr::DatabaseType::SqLite)
    system.database_version.should eq("3.36.0")
    system.authentication.should eq(Radarr::AuthenticationType::Forms)
    system.migration_version.should eq(1)
    system.url_base.should eq("")
    system.runtime_version.should eq("6.0.0")
    system.runtime_name.should eq(".NET")
    system.start_time.should eq(Time.utc(2023, 1, 1, 12, 0, 0))
    system.package_version.should eq("5.0.0")
    system.package_author.should eq("Radarr Team")
    system.package_update_mechanism.should eq(Radarr::UpdateMechanism::Docker)
    system.package_update_mechanism_message.should eq("Docker container")
  end

  it "reads the databaseType enum leniently (postgreSQL)" do
    system = Radarr::Model::SystemResource.from_json(%({"databaseType": "postgreSQL"}))
    system.database_type.should eq(Radarr::DatabaseType::PostgreSQL)
    system.to_json.should contain(%("databaseType":"postgreSQL"))
  end
end
