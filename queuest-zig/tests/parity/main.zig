const std = @import("std");
const Allocator = std.mem.Allocator;
const pg = @import("pg");
const sqlite = @import("sqlite");
const queuest = @import("queuest");
const pg_data = @import("pg_data");

const us_per_s: i64 = 1_000_000;

test "same seed yields the same repo results on sqlite and pgsql" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const io = std.testing.io;

    const pool = connectPg(io, allocator) catch |err| {
        std.log.err("parity tests need postgres: {}", .{err});
        return err;
    };
    defer pool.deinit();
    var conn = try pool.acquire();
    defer conn.release();

    _ = try conn.exec("begin", .{});
    defer _ = conn.exec("rollback", .{}) catch {};

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    var path_buf: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const path_len = try tmp.dir.realPath(io, &path_buf);
    const sqlite_path = try std.fs.path.joinZ(allocator, &.{ path_buf[0..path_len], "parity.db" });
    var db = try queuest.open.openFile(sqlite_path);
    defer db.deinit();
    try queuest.migrate.run(&db);

    const seed = try insertParitySeed(allocator, io, conn, &db);
    try compareRepos(allocator, conn, &db, seed);
}

const Seed = struct {
    uid: []const u8,
    user_id: i64,
    collection_id: i64,
    nested_collection_id: i64,
    item_a: i64,
    item_b: i64,
    item_c: i64,
    ci_a: i64,
    ci_b: i64,
    ci_c: i64,
    ci_nested: i64,
    rel_id: i64,
};

fn envOr(key: [:0]const u8, default: []const u8) []const u8 {
    const p = std.c.getenv(key) orelse return default;
    return std.mem.span(p);
}

fn connectPg(io: std.Io, allocator: Allocator) !*pg.Pool {
    const dbport_s = envOr("DATABASE_PORT", "5432");
    const dbport = try std.fmt.parseInt(u16, dbport_s, 10);
    const dbhost = envOr("DATABASE_HOST", "127.0.0.1");
    const dbuser = envOr("DB_USERNAME", "queuest");
    const dbname = envOr("DB_DATABASE", "queuest");
    const dbpass = envOr("DATABASE_PASSWORD", "queuest");
    const tls_s = envOr("DATABASE_TLS", "off");
    const tls: pg.Conn.Opts.TLS = if (std.mem.eql(u8, tls_s, "require"))
        .require
    else
        .off;

    return pg.Pool.init(io, allocator, .{
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

fn insertParitySeed(allocator: Allocator, io: std.Io, conn: *pg.Conn, db: *sqlite.Db) !Seed {
    const stamp = std.Io.Clock.real.now(io).toMilliseconds();
    const base: i64 = 2_000_000_000 + @mod(stamp, 1_000_000);
    const uid = try std.fmt.allocPrint(allocator, "parity-uid-{d}", .{stamp});
    const email = try std.fmt.allocPrint(allocator, "parity-{d}@example.test", .{stamp});
    const col_name = try std.fmt.allocPrint(allocator, "Parity Col {d}", .{stamp});
    const nested_name = try std.fmt.allocPrint(allocator, "Parity Nested {d}", .{stamp});

    const seed = Seed{
        .uid = uid,
        .user_id = base,
        .collection_id = base + 10,
        .nested_collection_id = base + 11,
        .item_a = base + 100,
        .item_b = base + 101,
        .item_c = base + 102,
        .ci_a = base + 200,
        .ci_b = base + 201,
        .ci_c = base + 202,
        .ci_nested = base + 203,
        .rel_id = base + 300,
    };
    const visited: i64 = 1_700_000_100;

    try insertUser(conn, db, seed, email);
    try insertCollection(conn, db, seed.collection_id, seed.user_id, col_name, visited, true);
    try insertCollection(conn, db, seed.nested_collection_id, seed.user_id, nested_name, visited - 50, false);
    try insertItem(conn, db, seed.item_a, "Parity A");
    try insertItem(conn, db, seed.item_b, "Parity B");
    try insertItem(conn, db, seed.item_c, "Parity C");
    try insertCollectionItem(conn, db, seed.ci_a, seed.collection_id, "ITEM", seed.item_a, null);
    try insertCollectionItem(conn, db, seed.ci_b, seed.collection_id, "ITEM", seed.item_b, null);
    try insertCollectionItem(conn, db, seed.ci_c, seed.collection_id, "ITEM", seed.item_c, null);
    try insertCollectionItem(conn, db, seed.ci_nested, seed.collection_id, "COLLECTION", null, seed.nested_collection_id);
    try insertRelation(conn, db, seed.rel_id, seed.ci_a, seed.ci_b);
    return seed;
}

fn insertUser(conn: *pg.Conn, db: *sqlite.Db, seed: Seed, email: []const u8) !void {
    _ = try conn.exec(
        "insert into user_tbl(id, uid, email) values ($1, $2, $3)",
        .{ seed.user_id, seed.uid, email },
    );
    try db.exec(
        "INSERT INTO user_tbl(id, uid, email) VALUES (?, ?, ?)",
        .{},
        .{ seed.user_id, seed.uid, email },
    );
}

fn insertCollection(
    conn: *pg.Conn,
    db: *sqlite.Db,
    id: i64,
    user_id: i64,
    name: []const u8,
    visited: i64,
    fav: bool,
) !void {
    _ = try conn.exec(
        \\insert into collection_tbl(id, user_id, name, visited_ts, favourite_yn)
        \\values ($1, $2, $3, $4, $5)
    , .{ id, user_id, name, visited * us_per_s, fav });
    try db.exec(
        \\INSERT INTO collection_tbl(id, user_id, name, visited_ts, favourite_yn)
        \\VALUES (?, ?, ?, ?, ?)
    , .{}, .{ id, user_id, name, visited, fav });
}

fn insertItem(conn: *pg.Conn, db: *sqlite.Db, id: i64, name: []const u8) !void {
    _ = try conn.exec("insert into item_tbl(id, name) values ($1, $2)", .{ id, name });
    try db.exec("INSERT INTO item_tbl(id, name) VALUES (?, ?)", .{}, .{ id, name });
}

fn insertCollectionItem(
    conn: *pg.Conn,
    db: *sqlite.Db,
    id: i64,
    collection_id: i64,
    item_type: []const u8,
    item_id: ?i64,
    collection_subitem_id: ?i64,
) !void {
    if (std.mem.eql(u8, item_type, "ITEM")) {
        _ = try conn.exec(
            \\insert into collection_item_tbl(id, collection_id, type, item_id, collection_subitem_id)
            \\values ($1, $2, 'ITEM', $3, $4)
        , .{ id, collection_id, item_id, collection_subitem_id });
    } else {
        std.debug.assert(std.mem.eql(u8, item_type, "COLLECTION"));
        _ = try conn.exec(
            \\insert into collection_item_tbl(id, collection_id, type, item_id, collection_subitem_id)
            \\values ($1, $2, 'COLLECTION', $3, $4)
        , .{ id, collection_id, item_id, collection_subitem_id });
    }
    try db.exec(
        \\INSERT INTO collection_item_tbl(id, collection_id, type, item_id, collection_subitem_id)
        \\VALUES (?, ?, ?, ?, ?)
    , .{}, .{ id, collection_id, item_type, item_id, collection_subitem_id });
}

fn insertRelation(conn: *pg.Conn, db: *sqlite.Db, id: i64, from_id: i64, to_id: i64) !void {
    _ = try conn.exec(
        "insert into item_relation_tbl(id, collection_item_from_id, collection_item_to_id) values ($1, $2, $3)",
        .{ id, from_id, to_id },
    );
    try db.exec(
        "INSERT INTO item_relation_tbl(id, collection_item_from_id, collection_item_to_id) VALUES (?, ?, ?)",
        .{},
        .{ id, from_id, to_id },
    );
}

fn compareRepos(allocator: Allocator, conn: *pg.Conn, db: *sqlite.Db, seed: Seed) !void {
    const pg_user = try pg_data.User.findByUID(conn, seed.uid);
    const sq_user = try queuest.User.findByUID(db, seed.uid);
    try std.testing.expect(pg_user != null);
    try std.testing.expect(sq_user != null);
    try std.testing.expectEqual(pg_user.?.id, sq_user.?.id);

    const pg_cols = try pg_data.Collection.findAllForUserId(conn, allocator, seed.user_id);
    const sq_cols = try queuest.Collection.findAllForUserId(db, allocator, seed.user_id);
    try std.testing.expectEqual(pg_cols.items.len, sq_cols.items.len);
    try std.testing.expectEqual(@as(usize, 2), sq_cols.items.len);
    try std.testing.expectEqual(pg_cols.items[0].id, sq_cols.items[0].id);
    try std.testing.expectEqual(pg_cols.items[0].user_id, sq_cols.items[0].user_id);
    try std.testing.expectEqualStrings(pg_cols.items[0].name, sq_cols.items[0].name);
    try std.testing.expectEqual(pg_cols.items[0].favourite_yn, sq_cols.items[0].favourite_yn);
    try std.testing.expectEqual(
        @divTrunc(pg_cols.items[0].visited_ts, us_per_s),
        sq_cols.items[0].visited_ts,
    );

    const pg_favs = try pg_data.Collection.findAllFavForUserId(conn, allocator, seed.user_id);
    const sq_favs = try queuest.Collection.findAllFavForUserId(db, allocator, seed.user_id);
    try std.testing.expectEqual(pg_favs.items.len, sq_favs.items.len);
    try std.testing.expectEqual(@as(i64, seed.collection_id), sq_favs.items[0].id);

    const pg_one = try pg_data.Collection.findByIdAndUserId(conn, allocator, seed.collection_id, seed.user_id);
    const sq_one = try queuest.Collection.findByIdAndUserId(db, allocator, seed.collection_id, seed.user_id);
    try std.testing.expectEqual(pg_one.?.id, sq_one.?.id);

    const pg_items = try pg_data.CollectionItem.findAllForCollectionId(conn, allocator, seed.collection_id);
    const sq_items = try queuest.CollectionItem.findAllForCollectionId(db, allocator, seed.collection_id);
    try std.testing.expectEqual(pg_items.items.len, sq_items.items.len);
    try std.testing.expectEqual(@as(usize, 4), sq_items.items.len);
    try expectSameItems(pg_items.items, sq_items.items);

    const pg_nested = try pg_data.CollectionItem.findById(conn, allocator, seed.ci_nested);
    const sq_nested = try queuest.CollectionItem.findById(db, allocator, seed.ci_nested);
    try std.testing.expectEqual(pg_nested.?.id, sq_nested.?.id);
    try std.testing.expectEqual(pg_nested.?.collection_id, sq_nested.?.collection_id);

    const pg_cid = try pg_data.CollectionItem.findCollectionIdById(conn, seed.ci_a);
    const sq_cid = try queuest.CollectionItem.findCollectionIdById(db, seed.ci_a);
    try std.testing.expectEqual(pg_cid, sq_cid);

    const pg_rels = try pg_data.ItemRelation.findAllForItemIds(conn, allocator, pg_items.items);
    const sq_rels = try queuest.ItemRelation.findAllForItemIds(db, allocator, sq_items.items);
    try std.testing.expectEqual(pg_rels.items.len, sq_rels.items.len);
    try std.testing.expectEqual(@as(usize, 1), sq_rels.items.len);
    try std.testing.expectEqual(pg_rels.items[0].id, sq_rels.items[0].id);
    try std.testing.expectEqual(pg_rels.items[0].collection_item_from_id, sq_rels.items[0].collection_item_from_id);
    try std.testing.expectEqual(pg_rels.items[0].collection_item_to_id, sq_rels.items[0].collection_item_to_id);
}

fn expectSameItems(pg_items: []const pg_data.CollectionItem, sq_items: []const queuest.CollectionItem) !void {
    try std.testing.expectEqual(pg_items.len, sq_items.len);
    for (pg_items) |p| {
        const s = findItem(sq_items, p.id) orelse return error.TestUnexpectedResult;
        try std.testing.expectEqual(p.collection_id, s.collection_id);
        try std.testing.expectEqualStrings(itemName(p), itemName(s));
        try std.testing.expectEqual(innerId(p), innerId(s));
    }
}

fn findItem(items: []const queuest.CollectionItem, id: i64) ?queuest.CollectionItem {
    for (items) |item| {
        if (item.id == id) return item;
    }
    return null;
}

fn itemName(item: anytype) []const u8 {
    return switch (item.inner) {
        .item => |it| it.name,
        .collection => |cl| cl.name,
    };
}

fn innerId(item: anytype) i64 {
    return switch (item.inner) {
        .item => |it| it.id,
        .collection => |cl| cl.id,
    };
}
