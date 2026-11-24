const std = @import("std");
const context = @import("context.zig");
const Application = context.Application;
const Context = context.Context;

/// Gives every request an arena that is freed after the response is built.
pub const middleware: Application.Middleware = .{ .before = before, .cleanup = cleanup };

fn before(ctx: *Context) !Application.Decision {
    ctx.locals.arena = std.heap.ArenaAllocator.init(ctx.shared.allocator);
    return .continue_request;
}

fn cleanup(ctx: *Context) void {
    if (ctx.locals.arena) |*a| a.deinit();
    ctx.locals.arena = null;
}
