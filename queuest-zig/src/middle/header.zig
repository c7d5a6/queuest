const std = @import("std");
const builtin = @import("builtin");
const zap = @import("zap");
const contextLib = @import("context.zig");
const Context = contextLib.Context;

const allow_origin: []const u8 = if (builtin.mode == .Debug)
    "http://localhost:4200"
else
    "https://queuest.c7d5a6.com";

const Handler = zap.Middleware.Handler(Context);

pub const HeaderMiddleWare = struct {
    handler: Handler,

    const Self = @This();

    pub fn init(other: ?*Handler) Self {
        return .{
            .handler = Handler.init(onRequest, other),
        };
    }

    // we need the handler as a common interface to chain stuff
    pub fn getHandler(self: *Self) *Handler {
        return &self.handler;
    }

    // note that the first parameter is of type *Handler, not *Self !!!
    pub fn onRequest(handler: *Handler, r: zap.Request, context: *Context) !bool {
        r.setHeader("Access-Control-Allow-Origin", allow_origin) catch unreachable;
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
