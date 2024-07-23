const std = @import("std");
const pg = @import("pg");
const Conn = pg.Conn;

pub const User = struct {
    id: i64,
    uid: []const u8,
    email: []const u8,

    pub fn findByUID(conn: *Conn, uid: []const u8) !?User {
        var result = try conn.queryOpts("select * from user_tbl where uid = $1", .{uid}, .{});
        defer result.deinit();

        var user: ?User = null;

        if (try result.next()) |row| {
            // const user = try row.to(User, .{ .map = .name });
            user = User{
                .id = row.get(i64, 0),
                .uid = row.get([]const u8, 3),
                .email = row.get([]const u8, 4),
            };
        }
        if (try result.next()) |_| {
            return error.Error;
        }
        return user;
    }

    pub fn create(conn: *Conn, uid: []const u8, email: []const u8) !void {
        _ = try conn.exec("insert into user_tbl (uid, email) values ($1, $2)", .{ uid, email });
    }
};
