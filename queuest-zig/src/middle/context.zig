const std = @import("std");
const web = @import("baz");
const sqlite = @import("sqlite");
const User = @import("../data/user.zig").User;

/// App-wide state, borrowed by every request as `ctx.shared`.
pub const Shared = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    db: *sqlite.Db,
    allow_localhost: bool,
};

/// Per-request state, available as `ctx.locals`. All fields need defaults.
pub const Locals = struct {
    auth: Auth = .{},
    user: ?User = null,
    db: ?*sqlite.Db = null,
    arena: ?std.heap.ArenaAllocator = null,
    in_transaction: bool = false,
};

pub const Auth = struct {
    authenticated: bool = false,
    uuid: ?[]const u8 = null,
};

pub const Application = web.AppWithLocals(Shared, Locals);
pub const Exchange = Application.Context;

/// Request-scoped allocator. Freed by `cleanup` of the `arena` middleware.
pub fn arena(ctx: *Exchange) std.mem.Allocator {
    std.debug.assert(ctx.locals.arena != null);
    return ctx.locals.arena.?.allocator();
}

/// Serializes `value` as the JSON response body with status 200.
pub fn sendJson(ctx: *Exchange, value: anytype) !void {
    const json = std.json.Stringify.valueAlloc(arena(ctx), value, .{
        .escape_unicode = true,
        .emit_null_optional_fields = false,
    }) catch return error.InternalError;
    try ctx.response.jsonBytes(200, json);
}
