const std = @import("std");
const sqlite = @import("sqlite");

const Migration = struct {
    version: []const u8,
    sql: []const u8,
};

const migrations = [_]Migration{
    .{
        .version = "001_init",
        .sql = @embedFile("migrations/001_init.sql"),
    },
};

pub fn run(db: *sqlite.Db) !void {
    std.debug.assert(@intFromPtr(db.db) != 0);
    std.debug.assert(migrations.len > 0);

    try db.exec(
        \\CREATE TABLE IF NOT EXISTS schema_migrations (
        \\    version TEXT PRIMARY KEY,
        \\    applied_at INTEGER NOT NULL
        \\)
    , .{}, .{});

    for (migrations) |m| {
        std.debug.assert(m.version.len > 0);
        std.debug.assert(m.sql.len > 0);
        try applyOne(db, m);
    }
}

fn applyOne(db: *sqlite.Db, m: Migration) !void {
    const already = try db.one(
        i64,
        "SELECT 1 FROM schema_migrations WHERE version = ?",
        .{},
        .{m.version},
    );
    if (already != null) {
        std.debug.assert(already.? == 1);
        return;
    }

    try db.exec("BEGIN IMMEDIATE", .{}, .{});
    errdefer db.exec("ROLLBACK", .{}, .{}) catch {};

    try execScript(db, m.sql);
    try db.exec(
        "INSERT INTO schema_migrations(version, applied_at) VALUES (?, unixepoch())",
        .{},
        .{m.version},
    );
    try db.exec("COMMIT", .{}, .{});
}

pub fn execScript(db: *sqlite.Db, sql: []const u8) !void {
    std.debug.assert(@intFromPtr(db.db) != 0);
    std.debug.assert(sql.len > 0);
    db.execMulti(sql, .{}) catch |err| switch (err) {
        error.EmptyQuery => {},
        else => return err,
    };
}

const open = @import("open.zig");

test "migrate applies 001_init once" {
    const allocator = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    var path_buf: [std.fs.max_path_bytes]u8 = undefined;
    const dir_path = try tmp.dir.realpath(".", &path_buf);
    const path = try std.fs.path.joinZ(allocator, &.{ dir_path, "t.db" });
    defer allocator.free(path);

    var db = try open.openFile(path);
    defer db.deinit();
    try run(&db);
    try run(&db);

    const n = try db.one(i64, "SELECT COUNT(*) FROM schema_migrations", .{}, .{});
    try std.testing.expectEqual(@as(i64, 1), n.?);
    const users = try db.one(i64, "SELECT COUNT(*) FROM user_tbl", .{}, .{});
    try std.testing.expectEqual(@as(i64, 0), users.?);
}
