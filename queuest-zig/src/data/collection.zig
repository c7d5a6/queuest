const std = @import("std");
const pg = @import("pg");
const User = @import("user.zig").User;
const Conn = pg.Conn;
const utils = @import("utils.zig");
const Id = utils.Id;
const getSoloEntity = utils.getSoloEntity;
const getList = utils.getList;

const table_name = "collection_tbl";

// id           | bigint                   |           | not null | nextval('pk_sequence'::regclass) | plain    |             |              |
// createdwhen  | timestamp with time zone |           | not null | CURRENT_TIMESTAMP(6)             | plain    |             |              |
// updatedwhen  | timestamp with time zone |           | not null | CURRENT_TIMESTAMP(6)             | plain    |             |              |
// user_id      | bigint                   |           | not null |                                  | plain    |             |              |
// name         | character varying(512)   |           | not null |                                  | extended |             |              |
// visited_ts   | timestamp with time zone |           | not null | CURRENT_TIMESTAMP(6)             | plain    |             |              |
// favourite_yn | boolean                  |           | not null | false                            | plain    |             |              |
pub const Collection = struct {
    id: i64 = 0,
    user_id: i64 = 0,
    name: []const u8 = "0",
    favourite_yn: bool = true,
    visited_ts: i64 = 0,

    pub fn findAllForUserId(conn: *Conn, allocator: std.mem.Allocator, user_id: i64) !std.ArrayList(Collection) {
        var result = try conn.queryOpts(
            "select * from " ++ table_name ++ " where user_id = $1 order by visited_ts desc",
            .{user_id},
            .{ .column_names = true },
        );
        defer result.deinit();

        return getList(Collection, allocator, result);
    }

    pub fn findAllFavForUserId(conn: *Conn, allocator: std.mem.Allocator, user_id: i64) !std.ArrayList(Collection) {
        var result = try conn.queryOpts(
            "select * from " ++ table_name ++ " where user_id = $1 and favourite_yn order by visited_ts desc",
            .{user_id},
            .{ .column_names = true },
        );
        defer result.deinit();

        return getList(Collection, allocator, result);
    }

    pub fn findByIdAndUserId(conn: *Conn, id: i64, user_id: i64) !?Collection {
        var result = try conn.queryOpts(
            "select * from " ++ table_name ++ " where id = $1 and user_id = $2",
            .{ id, user_id },
            .{ .column_names = true },
        );
        defer result.deinit();

        return getSoloEntity(Collection, result);
    }

    pub fn insertCollection(conn: *Conn, user_id: i64, name: []const u8) !?Id {
        var result = try conn.qugeryOpts(
            \\insert into collection_tbl(user_id, name, visited_ts) values ($1, $2, now()) returning id
        , .{ user_id, name }, .{ .column_names = true });
        defer result.deinit();

        return getSoloEntity(Id, result);
    }

    pub fn updateCollection(conn: *Conn, collection: Collection) !?Id {
        var result = try conn.queryOpts(
            \\update collection_tbl set favourite_yn = $1, name = $2 where id = $3 and user_id = $4
        , .{ collection.favourite_yn, collection.name, collection.id, collection.user_id }, .{ .column_names = true });
        defer result.deinit();

        return getSoloEntity(Id, result);
    }

    pub fn deleteCollection(conn: *Conn, id: i64, user_id: i64) !void {
        _ = try conn.queryOpts(
            \\delete from collection_tbl where id = $1 and user_id = $2
        , .{ id, user_id }, .{});
    }

    pub fn visitCollection(conn: *Conn, collection: Collection) !void {
        _ = try conn.queryOpts(
            \\update collection_tbl set visited_ts = now() where id = $1 and user_id = $2
        , .{ collection.id, collection.user_id }, .{});
    }
};
