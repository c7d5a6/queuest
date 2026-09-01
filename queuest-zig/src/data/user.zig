const std = @import("std");
const sqlite = @import("sqlite");
const Db = sqlite.Db;

pub const User = struct {
    id: i64,

    pub fn findByUID(db: *Db, uid: []const u8) !?User {
        std.debug.assert(uid.len > 0);
        const user = try db.one(
            User,
            "SELECT id FROM user_tbl WHERE uid = ?",
            .{},
            .{uid},
        );
        if (user) |u| {
            std.debug.assert(u.id != 0);
        }
        return user;
    }

    pub fn create(db: *Db, uid: []const u8, email: []const u8) !void {
        std.debug.assert(uid.len > 0);
        std.debug.assert(email.len > 0);
        try db.exec(
            "INSERT INTO user_tbl (uid, email) VALUES (?, ?)",
            .{},
            .{ uid, email },
        );
        std.debug.assert(db.getLastInsertRowID() != 0);
    }
};
