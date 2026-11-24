
# Testing

Requires exactly Zig 0.17.0 (see `.zig-version`; baz refuses any other compiler).
HTTP is served by [baz](https://github.com/technologylab-ai/baz); the server listens on
`127.0.0.1:$PORT` (default 3002) and expects a reverse proxy in front.

Optimization is per module: `-Doptimize=ReleaseFast` (or `ReleaseSmall`) applies to queuest
and zig-sqlite, while baz and its dependencies are always built ReleaseSafe because baz
refuses the other modes.

```
zig build test --summary all -freference-trace
zig build test-sqlite
```

`zig build test` includes unit tests and SQLite file-copy integration tests.

There is no HTTP-level e2e test yet.

# SQLite

The server opens `SQLITE_PATH` (default `queuest.db`), applies pragmas, then
runs embedded migrations before listen.

# CORS / DEV

The API always allows `https://queuest.c7d5a6.com`. It also allows
`http://localhost:4200` when `DEV` is on.

- Unset: on in Debug, off in `--release=safe`
- `DEV=1` / `true` / `on`: allow localhost (use this for a local ReleaseSafe binary)
- `DEV=0` / `false` / `off`: production origin only

Backup: `PRAGMA wal_checkpoint(TRUNCATE)` then copy the `.db` file. Also copy
`-wal` / `-shm` if a checkpoint was not done.
