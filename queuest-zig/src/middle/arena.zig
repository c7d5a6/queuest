const std = @import("std");
const context = @import("context.zig");
const Application = context.Application;
const Exchange = context.Exchange;

/// Gives every request an arena that is freed after the response is built.
pub const middleware: Application.Middleware = .{ .before = before, .cleanup = cleanup };

fn before(ctx: *Exchange) !Application.Decision {
    ctx.locals.arena = std.heap.ArenaAllocator.init(ctx.shared.allocator);
    return .continue_request;
}

fn cleanup(ctx: *Exchange) void {
    if (ctx.locals.arena) |*a| a.deinit();
    ctx.locals.arena = null;
}
