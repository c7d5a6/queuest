const std = @import("std");
const pg = @import("pg");
const User = @import("user.zig").User;
const Conn = pg.Conn;
const utils = @import("utils.zig");
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

    pub fn findAllForUserId(conn: *Conn, allocator: std.mem.Allocator, user_id: i64) !std.ArrayList(Collection) {
        var result = try conn.queryOpts("select * from " ++ table_name ++ " where user_id = $1", .{user_id}, .{ .column_names = true });
        defer result.deinit();

        return getList(Collection, allocator, result);
    }

    pub fn findAllFavForUserId(conn: *Conn, allocator: std.mem.Allocator, user_id: i64) !std.ArrayList(Collection) {
        var result = try conn.queryOpts("select * from " ++ table_name ++ " where user_id = $1 and favourite_yn", .{user_id}, .{ .column_names = true });
        defer result.deinit();

        return getList(Collection, allocator, result);
    }

    pub fn findByIdAndUserId(conn: *Conn, id: i64, user_id: i64) !?Collection {
        var result = try conn.queryOpts("select * from " ++ table_name ++ " where id = $1 and user_id = $2", .{ id, user_id }, .{ .column_names = true });
        defer result.deinit();

        return getSoloEntity(Collection, result);
    }
};
