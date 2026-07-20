# radarr

A Crystal shard for talking to the [Radarr](https://radarr.video/) API v3.

It provides:

- **Generated model classes** (`Radarr::Model::*`) for every object schema in the
  Radarr v3 OpenAPI document — JSON (de)serialization via `JSON::Serializable`,
  with correct nilability, `camelCase` JSON keys, and `Time` conversion for
  `date-time` properties.
- **Generated enums** (`Radarr::*`) for every enum schema, serializing to the
  exact `camelCase` string values the Radarr API expects.
- A small **HTTP client** (`Radarr::Client`) wrapping [`crest`](https://github.com/mamantoha/crest)
  that handles the base URL and `X-Api-Key` header for you.
- **Generated typed endpoints** (`Radarr::Api::*`) — one class per API group
  (e.g. `Radarr::Api::Movie`, `Radarr::Api::Tag`), each with methods that
  issue the request and return already-deserialized models, so you don't have
  to build paths and parse JSON by hand.

Models, enums, and endpoints are all generated from `ext/schema.json`
(Radarr's own OpenAPI document) rather than hand-written — see
[Generation](#generation) below.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     radarr:
       github: mjblack/radarr
   ```

2. Run `shards install`

## Usage

### Quick start

```crystal
require "radarr"

# Radarr::Client is a singleton: `.new` configures the shared instance and
# also returns it.
client = Radarr::Client.new("http://localhost:7878", "APIKEY")
```

### Typed endpoints

For every API group in the schema there's a `Radarr::Api::<Group>` class:
construct it with the `Radarr::Client` instance, then call a method — no
manual path-building or JSON parsing required. Methods return already
deserialized models (or `nil`/`[]` for empty/204 bodies).

System status:

```crystal
status = Radarr::Api::System.new(client).list_status # => Radarr::Model::SystemResource?
```

Since every model is nilable-by-default (mirroring the schema, which marks
almost nothing as strictly required), always guard against `nil` before using
a field:

```crystal
if version = status.try(&.version)
  puts "Radarr #{version}"
end
```

Movie CRUD (`list` / `get(id)` / `create(body)` / `update(id, body)` / `delete(id)`):

```crystal
movies = Radarr::Api::Movie.new(client)
all    = movies.list # => Array(Radarr::Model::MovieResource)

# Models have no keyword constructor (they're built for JSON round-tripping),
# so build one via #from_json and adjust properties as needed.
new_movie = Radarr::Model::MovieResource.from_json(%({"title": "Arrival", "tmdbId": 329865, "qualityProfileId": 1}))
created   = movies.create(new_movie) # => Radarr::Model::MovieResource?

if id = created.try(&.id)
  fetched = movies.get(id) # => Radarr::Model::MovieResource?
  movies.delete(id)        # => Nil
end
```

A paged endpoint, e.g. the download queue — note this returns a
`*PagingResource` wrapper, not a bare array (see [Caveats](#caveats)):

```crystal
page = Radarr::Api::Queue.new(client).list(page: 1, page_size: 25)
page.try(&.records) # => Array(Radarr::Model::QueueResource)
```

#### Naming convention

`Radarr::Api::<Group>` names come straight from the schema's path tags (e.g.
`/api/v3/movie` → `Radarr::Api::Movie`, `/api/v3/tag` → `Radarr::Api::Tag`);
there are 68 groups covering the schema's 164 documented paths. Within a
group, method names follow the HTTP verb and path shape:

- `list` — `GET` on the collection path (e.g. `GET /api/v3/movie`).
- `get(id)` — `GET` on the collection path with an `/{id}` tail.
- `create(body)` — `POST` on the collection path.
- `update(id, body)` — `PUT` on the `/{id}` path.
- `delete(id)` — `DELETE` on the `/{id}` path.
- A sub-path tail becomes a suffix: `GET /api/v3/history/since` →
  `list_since`, `GET /api/v3/system/status` → `list_status`.
- Endpoints that don't fit the CRUD shape (no request body, or a verb-like
  path segment) are named after the verb: `POST /api/v3/system/restart` →
  `create_restart`, `POST /api/v3/system/shutdown` → `create_shutdown`.

Optional query parameters (filters, paging, `includeXxx` flags) are exposed
as keyword arguments in schema order, e.g. `Radarr::Api::Movie#list(tmdb_id:
nil, exclude_local_covers: nil, language_id: nil)`.

#### Caveats

- **Paged endpoints return a wrapper, not a bare array.** Endpoints whose
  schema response is a `*PagingResource` (queue, history, blocklist, log,
  missing, cutoff, import list exclusions) return that wrapper type — access
  the actual items via its `records` property, plus `page`, `pageSize`, and
  `totalRecords`. Unpaged list endpoints (e.g. `Radarr::Api::Tag#list`,
  `Radarr::Api::Movie#list`) return a plain `Array(T)`.
- **A few endpoints are RPC-style, not CRUD.** Their method names are
  verb-derived rather than `list`/`get`/`create`/`update`/`delete` — e.g.
  `Radarr::Api::System#create_restart`, `#create_shutdown`.
- **Some endpoints return no body** (`Nil`) — `delete` methods, and RPC-style
  actions like the ones above.
- **A handful of non-JSON paths are intentionally not generated**, since
  there's no JSON schema to type against: the calendar iCal feed
  (`/feed/v3/calendar/radarr.ics`) and media cover images
  (`/api/v3/mediacover/{movieId}/{filename}`). Use the
  [generic client](#generic-client) for those.

### Generic client

The typed endpoints are built on the client's lower-level core, which is
available directly on the `Radarr::Client` instance for anything not (yet)
covered by a typed endpoint:

- `#request(method, path, query = nil, body = nil)` — issues the request and
  returns the raw `Crest::Response`.
- `#request_one(method, path, Type, ...)` — issues the request and
  deserializes the body into a single model (`nil` for empty bodies).
- `#request_many(method, path, Type, ...)` — deserializes into an
  `Array(Type)`.

The `apikey` query parameter and `X-Api-Key` header are attached
automatically; non-2xx responses raise `Radarr::ApiError`.

```crystal
resp = client.request(:get, "api/v3/system/status")

# Deserialize the response body into a generated model yourself.
status = Radarr::Model::SystemResource.from_json(resp.body)
status.app_name # => "Radarr"
status.version  # => "5.x.x.xxxx"

# Or let the client deserialize for you:
movies = client.request_many(:get, "api/v3/movie", Radarr::Model::MovieResource)
```

### Enums

Enum schemas (e.g. `Radarr::DatabaseType`, `Radarr::DownloadProtocol`) live
under the `Radarr` namespace, not `Radarr::Model`. They serialize to and parse
from the exact `camelCase` string Radarr uses on the wire (not Crystal's
default snake_case `Enum#to_json`), so round-tripping a model that contains one
just works:

```crystal
status.database_type # => Radarr::DatabaseType::SqLite
status.database_type.try(&.to_radarr_value) # => "sqLite"
```

## Development

- Install dependencies: `shards install`
- Run the unit specs: `crystal spec`
- Format code: `crystal tool format` (check only: `crystal tool format --check`)
- Lint: `bin/ameba` (built by `shards install` as a development dependency)

CI (`.github/workflows/ci.yml`) runs the format check, ameba, and the spec
suite on every pull request and push to `master`.

## Generation

Model classes (`src/radarr/model/*.cr`), enums (`src/radarr/support_enums.cr`),
and typed endpoints (`src/radarr/api/*.cr`) are all **generated, not
hand-written**, from `ext/schema.json` — Radarr's own OpenAPI 3.0.0 document.
The generator lives at `tools/generate.cr`; endpoints are built from the
document's `paths`, one `Radarr::Api::<Group>` class per path tag/group.

```sh
crystal run tools/generate.cr
```

This single command (re)writes every `src/radarr/model/<snake_name>.cr` file,
the whole of `src/radarr/support_enums.cr`, and every
`src/radarr/api/<snake_name>.cr` file. Generation is deterministic and
idempotent: running it twice against the same schema produces no git diff.

To pick up a new Radarr API version, drop the updated OpenAPI document in
place as `ext/schema.json` and regenerate:

```sh
cp /path/to/new/schema.json ext/schema.json
crystal run tools/generate.cr
```

Do not hand-edit files under `src/radarr/model/`, `src/radarr/support_enums.cr`,
or `src/radarr/api/` — they carry an `AUTO-GENERATED ... DO NOT EDIT` header.
If a generated file needs fixing, fix the generator and regenerate. Genuine
per-model or per-endpoint customization belongs in a separate file that
reopens the class, never inside a generated file.

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
