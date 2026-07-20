# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project

`radarr` is a Crystal shard: a typed client library for the **Radarr API v3**. It provides model classes (JSON (de)serialization), enums, typed endpoint modules, and an HTTP client for talking to a Radarr server.

- Source of truth for the API: **`ext/schema.json`** — the Radarr OpenAPI 3.0.0 document (164 paths, 137 component schemas). When code and schema disagree, the schema wins.
- Language/toolchain: Crystal `>= 1.20.3`. HTTP via the `crest` shard (`github: mamantoha/crest`, public — no auth token needed for CI).

## Architecture

- `src/radarr.cr` — entrypoint: `Radarr` module, `VERSION`, and the `require`s that pull in support, enums, client, models, and the generated API modules.
- `src/radarr/support.cr` / `support_enums.cr` — enum helper macros (`def_string_enum`) and the generated enums.
- `src/radarr/model.cr` — `require`s `./model/**`; each model is `class Radarr::Model::XxxResource` including `JSON::Serializable` (+ `JSON::Serializable::Unmapped`).
- `src/radarr/model/*.cr` — one model per file (96 model files).
- `src/radarr/api/*.cr` — one class per API group, `class Radarr::Api::<Group>` (68 groups), each constructed with a `Radarr::Client` and exposing typed methods that issue the request and return deserialized models.
- `src/radarr/client.cr` — `Radarr::Client` (singleton) wrapping `crest`; a typed core (`#request`) plus `#request_one` / `#request_many` deserialization helpers that the generated endpoints build on.

### Models are GENERATED, not hand-edited
Model classes, enums, and endpoint modules are produced by a **schema-driven code generator** (a Crystal app under `tools/`, run with `crystal run tools/generate.cr`). A new Radarr schema is applied by dropping in the new `ext/schema.json` and regenerating — never by hand-editing dozens of model files.

- Fix the **generator**, then regenerate. Do not hand-patch generated files (they carry an auto-generated header).
- Regeneration is idempotent: same schema in → zero diff out.
- Genuine per-model customization goes in a separate file that reopens the class, never inside a generated file.

### Model conventions (what the generator emits)
- `@[JSON::Field(key: "<exact schema property name>")]` on every property; snake_case Crystal names, camelCase JSON keys; `emit_null: true` on nilable/optional properties.
- Type map: int32→`Int32`, int64→`Int64`, number→`Float64`, string→`String`, bool→`Bool`, string+date-time→`Time`, array→`Array(T)`, `$ref`→referenced type.
- Nullability: schema-optional or `nullable: true` → nilable/`T?` or default; required+non-nullable → non-nilable.
- Enums (41 of them) live under the `Radarr` namespace, referenced as `Radarr::EnumName` (not `Radarr::Model::`). They serialize to/parse from the exact `camelCase` string values the API uses on the wire via `#to_radarr_value`; mind string- vs integer-valued enums and value mapping.

## Commands

- Install deps: `shards install`
- Build check: `crystal build --no-codegen src/radarr.cr`
- Format: `crystal tool format` (check: `crystal tool format --check`)
- Lint: `bin/ameba` (ameba is a development dependency; `shards install` builds `bin/ameba`)
- Unit specs: `crystal spec` (must stay green offline)
- Regenerate models/enums/endpoints: `crystal run tools/generate.cr`
- Integration specs (opt-in, needs Docker): `RADARR_INTEGRATION=1 crystal spec` with the Radarr test container up (see below).

## Testing

- **Unit specs** (`spec/model/*.cr`): offline JSON round-trip against the schema shape. Cover required-only and fully-populated cases. `spec_helper.cr` = `require "spec"` + `require "../src/radarr"`, plus shared fixtures.
- **Integration specs** (`spec/integration/`): run against a **live Radarr container** via `docker compose` (v2 is installed). Must be opt-in (guard by `RADARR_INTEGRATION=1`) and skip gracefully when the container/env is absent, so `crystal spec` stays green by default. A helper (`scripts/radarr-testenv.sh` and/or `docker-compose.yml`) brings up `linuxserver/radarr`, waits for health, and provides a known API key.

## CI / GitHub Actions

- **`.github/workflows/ci.yml`** — runs on every `pull_request` and every push to `master`: install Crystal (pinned `1.20.3`), `shards install`, `crystal tool format --check`, `bin/ameba`, `crystal spec`. No secrets required (the only runtime dep, `crest`, is public).
- **`.github/workflows/release.yml`** — see Releases below.

## Multi-agent workflow

Development is coordinated by a lead (the coordinator) that dispatches specialized subagents and owns all git/GitHub operations. **Subagents do not run git; the coordinator creates branches, commits, and opens/merges PRs.**

Subagents (`.claude/agents/`):
- **code-editor** — the generator and all `src/` library source (models/enums/endpoints are generated).
- **test-agent** — everything under `spec/` and the Docker integration harness.
- **doc-writer** — `README.md`, usage/API docs, `CHANGELOG.md`.
- **pr-reviewer** — read-only review of diffs/PRs for schema compliance, correctness, and coverage.
- **release-engineer** — keeps `shard.yml` `version:` and `Radarr::VERSION` in sync and drives the release workflow.

### GitHub / PR conventions
- Repo: `mjblack/radarr` (remote `origin`, `master` is the default branch).
- Work is tracked by an **epic issue** plus focused per-subsystem issues; each lands as its own reviewed PR.
- Branch per issue (e.g. `feat/model-generator`, `fix/movie-compliance`). Reference the issue in the PR; the pr-reviewer agent reviews before merge.

## Releases
- The version lives in **two** places that must always agree: `shard.yml` `version:` and `Radarr::VERSION` in `src/radarr.cr`. The **release-engineer** agent keeps them in sync.
- **`.github/workflows/release.yml`** is manually triggered (`gh workflow run release.yml`). It reads the version from `shard.yml`, requires `src/radarr.cr` to match, runs `crystal spec`, and **only on success** creates the `v<version>` tag and a GitHub release (`--generate-notes`). It authenticates with the built-in `secrets.GITHUB_TOKEN`.
- Cut a release by bumping both version locations (+ CHANGELOG) via a PR, merging to `master`, then triggering the workflow. Never tag/release by hand — the workflow does it after specs pass.

## Gotchas
- `shard.lock` is gitignored (this is a library).
- Models, enums (`src/radarr/support_enums.cr`), and endpoint modules (`src/radarr/api/*`) are all **generated** by `tools/generate.cr` — fix the generator, not the output.
- Integration specs (`spec/integration/`) are opt-in (`RADARR_INTEGRATION=1`); `crystal spec` stays green offline.
- A couple of non-JSON paths are intentionally not generated as typed endpoints (the calendar iCal feed `/feed/v3/calendar/radarr.ics` and media cover images `/api/v3/mediacover/{movieId}/{filename}`) — use the client's generic `#request` for those.
