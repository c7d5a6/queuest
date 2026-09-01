const std = @import("std");
const sqlite = @import("sqlite");

const default_path: [:0]const u8 = "queuest.db";
const max_path_len: usize = 4095;

var path_buf: [max_path_len:0]u8 = [_:0]u8{0} ** max_path_len;

pub fn pathFromEnv(environ: *const std.process.Environ.Map) [:0]const u8 {
    const env = environ.get("SQLITE_PATH") orelse return default_path;
    if (env.len == 0) return default_path;
    std.debug.assert(env.len <= max_path_len);
    if (env.len > max_path_len) {
        std.log.err("SQLITE_PATH is longer than {d} bytes", .{max_path_len});
        std.process.exit(1);
    }
    @memcpy(path_buf[0..env.len], env);
    path_buf[env.len] = 0;
    return path_buf[0..env.len :0];
}

pub fn openFile(path: [:0]const u8) !sqlite.Db {
    std.debug.assert(path.len > 0);
    var db = try sqlite.Db.init(.{
        .mode = .{ .File = path },
        .open_flags = .{
            .write = true,
            .create = true,
        },
        .threading_mode = .Serialized,
        .shared_cache = false,
    });
    errdefer db.deinit();
    try applyPragmas(&db);
    return db;
}

pub fn applyPragmas(db: *sqlite.Db) !void {
    std.debug.assert(@intFromPtr(db.db) != 0);

    _ = try db.pragma(i64, .{}, "foreign_keys", "ON");
    _ = try db.pragma([32:0]u8, .{}, "journal_mode", "WAL");
    _ = try db.pragma(i64, .{}, "synchronous", "NORMAL");
    _ = try db.pragma(i64, .{}, "busy_timeout", "5000");
    _ = try db.pragma(i64, .{}, "temp_store", "MEMORY");

    const fk = try db.one(i64, "PRAGMA foreign_keys", .{}, .{});
    std.debug.assert(fk != null);
    std.debug.assert(fk.? == 1);
}

pub fn checkpoint(db: *sqlite.Db) !void {
    const Row = struct { busy: i64, log: i64, checkpointed: i64 };
    _ = try db.one(Row, "PRAGMA wal_checkpoint(TRUNCATE)", .{}, .{});
}
