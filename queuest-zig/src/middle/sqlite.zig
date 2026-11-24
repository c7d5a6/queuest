const std = @import("std");
const context = @import("context.zig");
const Application = context.Application;
const Exchange = context.Exchange;

/// One IMMEDIATE transaction per request: committed after a successful handler,
/// rolled back on error or early response.
pub const middleware: Application.Middleware = .{
    .before = before,
    .after = after,
    .cleanup = cleanup,
};

fn before(ctx: *Exchange) !Application.Decision {
    const db = ctx.shared.db;
    try db.exec("BEGIN IMMEDIATE", .{}, .{});
    ctx.locals.db = db;
    ctx.locals.in_transaction = true;
    return .continue_request;
}

fn after(ctx: *Exchange) !void {
    std.debug.assert(ctx.locals.in_transaction);
    try ctx.shared.db.exec("COMMIT", .{}, .{});
    ctx.locals.in_transaction = false;
}

fn cleanup(ctx: *Exchange) void {
    if (!ctx.locals.in_transaction) return;
    ctx.shared.db.exec("ROLLBACK", .{}, .{}) catch |err| {
        std.log.err("ROLLBACK failed: {}", .{err});
    };
    ctx.locals.in_transaction = false;
}
