const std = @import("std");
const Allocator = std.mem.Allocator;
const pg = @import("pg");
const sqlite = @import("sqlite");
const queuest = @import("queuest");

const us_per_s: i64 = 1_000_000;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const out_path = try outputPath(allocator);
    defer allocator.free(out_path);

    std.fs.cwd().deleteFile(out_path) catch |err| switch (err) {
        error.FileNotFound => {},
        else => return err,
    };

    var db = try queuest.open.openFile(out_path);
    defer db.deinit();
    try queuest.migrate.run(&db);

    const pool = try connectPg(allocator);
    defer pool.deinit();
    var conn = try pool.acquire();
    defer conn.release();

    try copyUsers(allocator, conn, &db);
    try copyCollections(allocator, conn, &db);
    try copyItems(allocator, conn, &db);
    try copyCollectionItems(allocator, conn, &db);
    try copyRelations(allocator, conn, &db);
    try verify(allocator, &db);
    try queuest.open.checkpoint(&db);

    std.log.info("wrote {s}", .{out_path});
}

fn outputPath(allocator: Allocator) ![:0]const u8 {
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next();
    if (args.next()) |p| {
        std.debug.assert(p.len > 0);
        return try allocator.dupeZ(u8, p);
    }
    return try allocator.dupeZ(u8, "queuest-migrated.db");
}

fn connectPg(allocator: Allocator) !*pg.Pool {
    const dbport_s = std.posix.getenv("DATABASE_PORT") orelse "5432";
    const dbport = try std.fmt.parseInt(u16, dbport_s, 10);
    const dbhost = std.posix.getenv("DATABASE_HOST") orelse "127.0.0.1";
    const dbuser = std.posix.getenv("DB_USERNAME") orelse "queuest";
    const dbname = std.posix.getenv("DB_DATABASE") orelse "queuest";
    const dbpass = std.posix.getenv("DATABASE_PASSWORD") orelse "queuest";
    const tls_s = std.posix.getenv("DATABASE_TLS") orelse "off";
    const tls: pg.Conn.Opts.TLS = if (std.mem.eql(u8, tls_s, "require"))
        .require
    else
        .off;

    return pg.Pool.init(allocator, .{
        .size = 1,
        .connect = .{
            .port = dbport,
            .host = dbhost,
            .tls = tls,
        },
        .auth = .{
            .username = dbuser,
            .database = dbname,
            .password = dbpass,
            .timeout = 10_000,
        },
    });
}

fn unixSeconds(pg_us: i64) i64 {
    return @divTrunc(pg_us, us_per_s);
}

fn copyUsers(allocator: Allocator, conn: *pg.Conn, db: *sqlite.Db) !void {
    const Row = struct {
        id: i64,
        createdwhen: i64,
        updatedwhen: i64,
        uid: []const u8,
        email: []const u8,
    };
    var result = try conn.queryOpts(
        "select id, createdwhen, updatedwhen, uid, email from user_tbl",
        .{},
        .{ .column_names = true },
    );
    defer result.deinit();
    var n: usize = 0;
    while (try result.next()) |row| {
        const rec = try row.to(Row, .{ .map = .name, .allocator = allocator });
        std.debug.assert(rec.id != 0);
        try db.exec(
            "INSERT INTO user_tbl(id, createdwhen, updatedwhen, uid, email) VALUES (?, ?, ?, ?, ?)",
            .{},
            .{ rec.id, unixSeconds(rec.createdwhen), unixSeconds(rec.updatedwhen), rec.uid, rec.email },
        );
        n += 1;
    }
    std.log.info("users {d}", .{n});
}

fn copyCollections(allocator: Allocator, conn: *pg.Conn, db: *sqlite.Db) !void {
    const Row = struct {
        id: i64,
        createdwhen: i64,
        updatedwhen: i64,
        user_id: i64,
        name: []const u8,
        visited_ts: i64,
        favourite_yn: bool,
    };
    var result = try conn.queryOpts(
        \\select id, createdwhen, updatedwhen, user_id, name, visited_ts, favourite_yn
        \\  from collection_tbl
    , .{}, .{ .column_names = true });
    defer result.deinit();
    var n: usize = 0;
    while (try result.next()) |row| {
        const rec = try row.to(Row, .{ .map = .name, .allocator = allocator });
        std.debug.assert(rec.id != 0);
        std.debug.assert(rec.user_id != 0);
        try db.exec(
            \\INSERT INTO collection_tbl(id, createdwhen, updatedwhen, user_id, name, visited_ts, favourite_yn)
            \\VALUES (?, ?, ?, ?, ?, ?, ?)
        , .{}, .{
            rec.id,
            unixSeconds(rec.createdwhen),
            unixSeconds(rec.updatedwhen),
            rec.user_id,
            rec.name,
            unixSeconds(rec.visited_ts),
            rec.favourite_yn,
        });
        n += 1;
    }
    std.log.info("collections {d}", .{n});
}

fn copyItems(allocator: Allocator, conn: *pg.Conn, db: *sqlite.Db) !void {
    const Row = struct {
        id: i64,
        createdwhen: i64,
        updatedwhen: i64,
        name: []const u8,
    };
    var result = try conn.queryOpts(
        "select id, createdwhen, updatedwhen, name from item_tbl",
        .{},
        .{ .column_names = true },
    );
    defer result.deinit();
    var n: usize = 0;
    while (try result.next()) |row| {
        const rec = try row.to(Row, .{ .map = .name, .allocator = allocator });
        std.debug.assert(rec.id != 0);
        try db.exec(
            "INSERT INTO item_tbl(id, createdwhen, updatedwhen, name) VALUES (?, ?, ?, ?)",
            .{},
            .{ rec.id, unixSeconds(rec.createdwhen), unixSeconds(rec.updatedwhen), rec.name },
        );
        n += 1;
    }
    std.log.info("items {d}", .{n});
}

fn copyCollectionItems(allocator: Allocator, conn: *pg.Conn, db: *sqlite.Db) !void {
    const Row = struct {
        id: i64,
        createdwhen: i64,
        updatedwhen: i64,
        collection_id: i64,
        item_type: []const u8,
        item_id: ?i64,
        collection_subitem_id: ?i64,
    };
    var result = try conn.queryOpts(
        \\select id, createdwhen, updatedwhen, collection_id, type as item_type,
        \\       item_id, collection_subitem_id
        \\  from collection_item_tbl
    , .{}, .{ .column_names = true });
    defer result.deinit();
    var n: usize = 0;
    while (try result.next()) |row| {
        const rec = try row.to(Row, .{ .map = .name, .allocator = allocator });
        std.debug.assert(rec.id != 0);
        std.debug.assert(rec.collection_id != 0);
        try db.exec(
            \\INSERT INTO collection_item_tbl(
            \\  id, createdwhen, updatedwhen, collection_id, type, item_id, collection_subitem_id
            \\) VALUES (?, ?, ?, ?, ?, ?, ?)
        , .{}, .{
            rec.id,
            unixSeconds(rec.createdwhen),
            unixSeconds(rec.updatedwhen),
            rec.collection_id,
            rec.item_type,
            rec.item_id,
            rec.collection_subitem_id,
        });
        n += 1;
    }
    std.log.info("collection_items {d}", .{n});
}

fn copyRelations(allocator: Allocator, conn: *pg.Conn, db: *sqlite.Db) !void {
    const Row = struct {
        id: i64,
        createdwhen: i64,
        updatedwhen: i64,
        collection_item_from_id: i64,
        collection_item_to_id: i64,
    };
    var result = try conn.queryOpts(
        \\select id, createdwhen, updatedwhen, collection_item_from_id, collection_item_to_id
        \\  from item_relation_tbl
    , .{}, .{ .column_names = true });
    defer result.deinit();
    var n: usize = 0;
    while (try result.next()) |row| {
        const rec = try row.to(Row, .{ .map = .name, .allocator = allocator });
        std.debug.assert(rec.id != 0);
        try db.exec(
            \\INSERT INTO item_relation_tbl(
            \\  id, createdwhen, updatedwhen, collection_item_from_id, collection_item_to_id
            \\) VALUES (?, ?, ?, ?, ?)
        , .{}, .{
            rec.id,
            unixSeconds(rec.createdwhen),
            unixSeconds(rec.updatedwhen),
            rec.collection_item_from_id,
            rec.collection_item_to_id,
        });
        n += 1;
    }
    std.log.info("relations {d}", .{n});
}

fn verify(allocator: Allocator, db: *sqlite.Db) !void {
    const integrity = try db.oneAlloc([]const u8, allocator, "PRAGMA integrity_check", .{}, .{});
    defer if (integrity) |s| allocator.free(s);
    if (integrity == null or !std.mem.eql(u8, integrity.?, "ok")) {
        std.log.err("integrity_check failed: {?s}", .{integrity});
        return error.IntegrityCheckFailed;
    }

    const FkFail = struct {
        table: []const u8,
        rowid: i64,
        parent: []const u8,
        fkid: i64,
    };
    var stmt = try db.prepare("PRAGMA foreign_key_check");
    defer stmt.deinit();
    const fails = try stmt.all(FkFail, allocator, .{}, .{});
    defer {
        for (fails) |f| {
            allocator.free(f.table);
            allocator.free(f.parent);
        }
        allocator.free(fails);
    }
    if (fails.len != 0) {
        std.log.err("foreign_key_check failed: {d} row(s)", .{fails.len});
        return error.ForeignKeyCheckFailed;
    }
}
