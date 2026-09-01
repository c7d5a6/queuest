
# Testing

```
zig build test --summary all -freference-trace
zig build test-sqlite
zig build test-parity
```

`zig build test` includes unit tests and SQLite file-copy integration tests.
`zig build` and `zig build test` compile as ReleaseSafe when you ask for Debug,
because zig-sqlite 0.15 Debug codegen currently SIGSEGVs. Use
`--release=safe` or `--release=fast` explicitly if you want a release binary.

`zig build test-parity` needs a running Postgres (same env vars as before) and
compares repository results on the same seed. Delete that step when Postgres
is removed. It also needs OpenSSL headers (`libssl-dev`).

# SQLite

The server opens `SQLITE_PATH` (default `queuest.db`), applies pragmas, then
runs embedded migrations before listen.

Backup: `PRAGMA wal_checkpoint(TRUNCATE)` then copy the `.db` file. Also copy
`-wal` / `-shm` if a checkpoint was not done.

# PostgreSQL to SQLite cutover

1. Stop writes (pause or stop the app).
2. `zig build run-pg-to-sqlite -- /path/to/queuest-migrated.db`
3. Point `SQLITE_PATH` at that file and start the new binary.
4. Keep the Postgres volume as a read-only backup until the Postgres code
   is deleted.

Env for the converter (and parity tests): `DATABASE_HOST`, `DATABASE_PORT`,
`DB_USERNAME`, `DB_DATABASE`, `DATABASE_PASSWORD`, `DATABASE_TLS` (`off` or
`require`).
