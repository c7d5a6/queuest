const std = @import("std");
const context = @import("context.zig");
const Application = context.Application;
const Context = context.Context;

const prod_origin: []const u8 = "https://queuest.c7d5a6.com";
const dev_origin: []const u8 = "http://localhost:4200";

/// Global middleware: CORS and cache headers on every response.
/// Baz itself answers `OPTIONS` (with `Allow`) and 404/405 through global hooks.
pub const middleware: Application.Middleware = .{ .before = before };

fn before(ctx: *Context) !Application.Decision {
    try addHeaders(ctx);
    return .continue_request;
}

/// Also called from the error hook: Baz discards the draft response
/// (headers included) when a handler fails.
pub fn addHeaders(ctx: *Context) !void {
    const origin = corsOrigin(ctx.request.header("origin"), ctx.shared.allow_localhost);
    std.debug.assert(origin.len > 0);
    try ctx.response.header("Access-Control-Allow-Origin", origin);
    try ctx.response.header("Access-Control-Allow-Methods", "GET, POST, DELETE, PATCH, OPTIONS");
    try ctx.response.header("Access-Control-Allow-Headers", "Content-Type, Authorization");
    try ctx.response.header("Expires", "0");
}

fn corsOrigin(request_origin: ?[]const u8, allow_localhost: bool) []const u8 {
    if (request_origin) |o| {
        std.debug.assert(o.len > 0);
        if (std.mem.eql(u8, o, prod_origin)) return o;
        if (allow_localhost and std.mem.eql(u8, o, dev_origin)) return o;
    }
    return prod_origin;
}

test "cors echoes localhost when DEV is on" {
    try std.testing.expectEqualStrings(dev_origin, corsOrigin(dev_origin, true));
    try std.testing.expectEqualStrings(prod_origin, corsOrigin(dev_origin, false));
}

test "cors always echoes production origin" {
    try std.testing.expectEqualStrings(prod_origin, corsOrigin(prod_origin, false));
    try std.testing.expectEqualStrings(prod_origin, corsOrigin(prod_origin, true));
    try std.testing.expectEqualStrings(prod_origin, corsOrigin(null, true));
}
