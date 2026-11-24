# queuest-zig

Zig backend of Queuest: baz (HTTP) + zig-sqlite, Firebase JWT auth.

## Rules

- Build with exactly Zig 0.17.0 (`.zig-version`): `zig build`, `zig build test`, `zig build fmt`.
- Follow `../STYLE.md` for new code and lines you touch (also `.cursor/rules/zig-style.mdc`).
- Baz refuses ReleaseFast/ReleaseSmall, so `build.zig` builds baz at ReleaseSafe and
  everything else follows `-Doptimize`. Asserts in our code only fire in Debug/ReleaseSafe.
- Deploy with `./deploy/deploy.sh` only when the user asks; it ships to the real server.
- Issues live in the Lific project QUEUE. Commit iteratively and stop for review before commits.

## Layout

- `src/main.zig` wires shared state, baz app and routes.
- `src/routes/` route table, param parsing, error to status mapping.
- `src/middle/` baz hooks: `header` (global CORS), then per route `arena`, `auth`, `sqlite`, `user`.
- `src/services/` handlers (`fn(ctx: *Exchange) !void`); `src/data/` SQL; `src/db/` open + migrations.
- `tests/sqlite/` data-layer tests against a copied seeded DB.
