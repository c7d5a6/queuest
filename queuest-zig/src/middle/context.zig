const std = @import("std");
const sqlite = @import("sqlite");
const User = @import("../data/user.zig").User;

pub const Context = struct {
    auth: ?Auth = null,
    user: ?User = null,
    db: ?*sqlite.Db = null,
    session: ?Session = null,
};
pub const Auth = struct {
    authenticated: bool = false,
    uuid: ?[]const u8 = null,
};
pub const Session = struct {
    info: []const u8 = undefined,
    token: []const u8 = undefined,
};

pub const SharedAllocator = struct {
    var allocator: std.mem.Allocator = undefined;

    const Self = @This();

    pub fn init(a: std.mem.Allocator) void {
        allocator = a;
    }

    pub fn getAllocator() std.mem.Allocator {
        return allocator;
    }
};
