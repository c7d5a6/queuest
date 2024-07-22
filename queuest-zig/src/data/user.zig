const std = @import("std");
const pg = @import("pg");
const Conn = pg.Conn;

pub const User = struct {
    id: u64,
    uid: [128]u8,
    email: [256]u8,

    pub fn findByUID(conn: *Conn, uid: []const u8) !?User {
        var result = try conn.queryOpts("select * from user_tbl where uid = $1", .{uid}, .{});
        defer result.deinit();

        if (result.number_of_columns > 1) return error.Error;

        if (try result.next()) |row| {
            try row.to(User, .{ .map = .name });
        }
        return null;
    }
};
