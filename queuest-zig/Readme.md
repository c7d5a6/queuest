
# Testing

Requires Zig 0.16.0.

```
zig build test --summary all -freference-trace
zig build test-sqlite
```

`zig build test` includes unit tests and SQLite file-copy integration tests.

`zig build e2e` currently skips; the Zap listener stub is unfinished.

# SQLite

The server opens `SQLITE_PATH` (default `queuest.db`), applies pragmas, then
runs embedded migrations before listen.

# CORS / DEV

The API always allows `https://queuest.c7d5a6.com`. It also allows
`http://localhost:4200` when `DEV` is on.

- Unset: on in Debug, off in `--release=fast` / `--release=safe` / `--release=small`
- `DEV=1` / `true` / `on`: allow localhost (use this for a local ReleaseFast binary)
- `DEV=0` / `false` / `off`: production origin only

Backup: `PRAGMA wal_checkpoint(TRUNCATE)` then copy the `.db` file. Also copy
`-wal` / `-shm` if a checkpoint was not done.
