const std = @import("std");
const User = @import("../data/user.zig").User;
const context = @import("context.zig");
const Application = context.Application;
const Context = context.Context;

/// Loads the user for the authenticated uid, creating it on first sight.
pub const middleware: Application.Middleware = .{ .before = before };

fn before(ctx: *Context) !Application.Decision {
    const db = ctx.locals.db orelse return error.InternalError;
    const uuid = ctx.locals.auth.uuid orelse return error.InternalError;
    if (try User.findByUID(db, uuid)) |user| {
        ctx.locals.user = user;
        return .continue_request;
    }
    try User.create(db, uuid, "email");
    ctx.locals.user = try User.findByUID(db, uuid) orelse return error.InternalError;
    return .continue_request;
}
