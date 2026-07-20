# radarr

Crystal Radarr Library

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     radarr:
       github: mjblack/radarr
   ```

2. Run `shards install`

## Usage

```crystal
require "radarr"
```

TODO: Write usage instructions here

## Development

TODO: Write development instructions here

## Docker integration tests

Unit specs (`spec/model/*.cr`) run fully offline against fixture JSON and are
part of the default `crystal spec` run. Integration specs
(`spec/integration/*.cr`) exercise a **live Radarr container** and are opt-in
— they're skipped (reported as `pending`) unless explicitly enabled, so a
plain `crystal spec` stays green and Docker-free.

`docker-compose.yml` and `scripts/radarr-testenv.sh` bring up a single
`linuxserver/radarr` container with a deterministic, pre-seeded API key so
the specs are reproducible. Bring the environment up, wait for it to be
healthy, run the integration specs, then tear it down:

```sh
scripts/radarr-testenv.sh up
scripts/radarr-testenv.sh wait
RADARR_INTEGRATION=1 crystal spec spec/integration/
scripts/radarr-testenv.sh down
```

Other `radarr-testenv.sh` subcommands:

- `apikey` — print the API key currently in use (read back from the live
  `config.xml` if present, otherwise the seeded default)
- `url` — print the base URL the container is published on
- `status` — `docker compose ps` for the environment

Everything is tunable via environment variables (defaults shown, kept in sync
between `docker-compose.yml`, `scripts/radarr-testenv.sh`, and
`spec/integration_helper.cr`):

| Variable              | Default                              | Meaning                                |
|-----------------------|---------------------------------------|-----------------------------------------|
| `RADARR_PORT`         | `7878`                                | Host port the container is published on |
| `RADARR_API_KEY`      | `0123456789abcdef0123456789abcdef`    | API key seeded into `config.xml`        |
| `RADARR_CONFIG_DIR`   | `/tmp/radarr-testenv-config`          | Host dir bind-mounted at `/config`      |
| `RADARR_PUID`/`RADARR_PGID` | current user (script) / `1000` (compose) | Ownership of the config dir  |
| `RADARR_WAIT_TIMEOUT` | `180`                                  | Seconds `wait` polls before failing     |
| `RADARR_URL`          | `http://localhost:${RADARR_PORT}`     | Base URL used by `wait` and the specs   |
| `RADARR_INTEGRATION`  | unset                                  | Set to `1` to actually run the specs    |

`scripts/radarr-testenv.sh down` runs `docker compose down -v` and removes the
ephemeral config directory.

## Contributing

1. Fork it (<https://github.com/mjblack/radarr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Matthew J. Black](https://github.com/mjblack) - creator and maintainer
