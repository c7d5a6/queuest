const std = @import("std");
const pg = @import("pg");
const getSoloEntity = @import("utils.zig").getSoloEntity;
const Conn = pg.Conn;

pub const User = struct {
    id: i64,
    uid: []const u8,
    email: []const u8,

    pub fn findByUID(conn: *Conn, uid: []const u8) !?User {
        var result = try conn.queryOpts("select * from user_tbl where uid = $1", .{uid}, .{});
        defer result.deinit();

        return getSoloEntity(User, result);
    }

    pub fn create(conn: *Conn, uid: []const u8, email: []const u8) !void {
        _ = try conn.exec("insert into user_tbl (uid, email) values ($1, $2)", .{ uid, email });
    }
};
