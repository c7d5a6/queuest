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
        std.debug.assert(@intFromPtr(db.db) != 0);
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

        try self.db.exec("BEGIN IMMEDIATE", .{}, .{});
        const ok = handler.handleOther(r, context) catch |err| {
            self.db.exec("ROLLBACK", .{}, .{}) catch {};
            return err;
        };
        if (ok) {
            try self.db.exec("COMMIT", .{}, .{});
        } else {
            self.db.exec("ROLLBACK", .{}, .{}) catch {};
        }
        return ok;
    }
};
