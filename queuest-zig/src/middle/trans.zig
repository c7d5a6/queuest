const std = @import("std");
const Allocator = std.mem.Allocator;
const zap = @import("zap");
const pg = @import("pg");
const Pool = pg.Pool;
const contextLib = @import("context.zig");
const Context = contextLib.Context;

const Handler = zap.Middleware.Handler(Context);

pub const TransactionMiddleware = struct {
    handler: Handler,
    allocator: Allocator,
    pool: *Pool,
    const Self = @This();

    pub fn init(other: ?*Handler, allocator: Allocator, pool: *Pool) Self {
        return .{
            .handler = Handler.init(onRequest, other),
            .allocator = allocator,
            .pool = pool,
        };
    }

    pub fn getHandler(self: *Self) *Handler {
        return &self.handler;
    }

    pub fn onRequest(handler: *Handler, r: zap.Request, context: *Context) bool {
        const self: *Self = @fieldParentPtr("handler", handler);
        const pool = self.pool;
        var conn = pool.acquire() catch |err| {
            std.log.debug("Error in pool creation {}", .{err});
            return false;
        };
        defer conn.release();

        context.connection = conn;

        return handler.handleOther(r, context);
    }
};
