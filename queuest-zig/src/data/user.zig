const std = @import("std");
const pg = @import("pg");
const getSoloEntity = @import("utils.zig").getSoloEntity;
const Conn = pg.Conn;

pub const User = struct {
    id: i64,

    pub fn findByUID(conn: *Conn, uid: []const u8) !?User {
        std.debug.assert(uid.len > 0);
        var result = try conn.queryOpts(
            "select * from user_tbl where uid = $1",
            .{uid},
            .{ .column_names = true },
        );
        defer result.deinit();

        const user = try getSoloEntity(User, null, result);
        if (user) |u| {
            std.debug.assert(u.id != 0);
        }
        return user;
    }

    pub fn create(conn: *Conn, uid: []const u8, email: []const u8) !void {
        std.debug.assert(uid.len > 0);
        std.debug.assert(email.len > 0);
        _ = try conn.exec("insert into user_tbl (uid, email) values ($1, $2)", .{ uid, email });
    }
};
