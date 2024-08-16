const std = @import("std");
const zap = @import("zap");
const contextLib = @import("context.zig");
const Context = contextLib.Context;

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
    pub fn onRequest(handler: *Handler, r: zap.Request, context: *Context) bool {
        r.setHeader("Access-Control-Allow-Origin", "*") catch unreachable;
        r.setHeader("Access-Control-Allow-Methods", "GET, POST, DELETE, PATCH, OPTIONS") catch unreachable;
        r.setHeader("Access-Control-Allow-Headers", "*") catch unreachable;
        r.setHeader("Expires", "0") catch unreachable;
        if (r.methodAsEnum() == .OPTIONS) {
            r.sendBody("") catch unreachable;
            return true;
        }
        return handler.handleOther(r, context);
    }
};
