const std = @import("std");
const Allocator = std.mem.Allocator;
const zap = @import("zap");
const sqlite = @import("sqlite");
const contextLib = @import("context.zig");
const Context = contextLib.Context;

const Handler = zap.Middleware.Handler(Context);

pub const SqliteMiddleware = struct {
    handler: Handler,
    allocator: Allocator,
    db: *sqlite.Db,
    const Self = @This();

    pub fn init(other: ?*Handler, allocator: Allocator, db: *sqlite.Db) Self {
        return .{
            .handler = Handler.init(onRequest, other),
            .allocator = allocator,
            .db = db,
        };
    }

    pub fn getHandler(self: *Self) *Handler {
        return &self.handler;
    }

    pub fn onRequest(handler: *Handler, r: zap.Request, context: *Context) !bool {
        const self: *Self = @fieldParentPtr("handler", handler);
        context.db = self.db;
        return handler.handleOther(r, context);
    }
};
