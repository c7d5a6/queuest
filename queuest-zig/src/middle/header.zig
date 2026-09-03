const std = @import("std");
const zap = @import("zap");
const contextLib = @import("context.zig");
const Context = contextLib.Context;

const prod_origin: []const u8 = "https://queuest.c7d5a6.com";
const dev_origin: []const u8 = "http://localhost:4200";

const Handler = zap.Middleware.Handler(Context);

pub const HeaderMiddleWare = struct {
    handler: Handler,
    allow_localhost: bool,

    const Self = @This();

    pub fn init(other: ?*Handler, allow_localhost: bool) Self {
        return .{
            .handler = Handler.init(onRequest, other),
            .allow_localhost = allow_localhost,
        };
    }

    pub fn getHandler(self: *Self) *Handler {
        return &self.handler;
    }

    pub fn onRequest(handler: *Handler, r: zap.Request, context: *Context) !bool {
        const self: *Self = @fieldParentPtr("handler", handler);
        const origin = corsOrigin(r.getHeader("origin"), self.allow_localhost);
        std.debug.assert(origin.len > 0);
        r.setHeader("Access-Control-Allow-Origin", origin) catch unreachable;
        r.setHeader("Access-Control-Allow-Methods", "GET, POST, DELETE, PATCH, OPTIONS") catch unreachable;
        r.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization") catch unreachable;
        r.setHeader("Expires", "0") catch unreachable;
        if (r.methodAsEnum() == .OPTIONS) {
            r.sendBody("") catch unreachable;
            return true;
        }
        return handler.handleOther(r, context);
    }
};

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
