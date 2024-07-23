const std = @import("std");
const parseUnsigned = std.fmt.parseUnsigned;
const mem = std.mem;
const Allocator = mem.Allocator;
const zap = @import("zap");
const firebase = @import("../auth/firebase.zig");
const User = @import("../data/user.zig").User;
const contextLib = @import("context.zig");
const Context = contextLib.Context;
const Session = contextLib.Session;
const Auth = contextLib.Auth;

const Handler = zap.Middleware.Handler(Context);

pub const UserMiddleware = struct {
    handler: Handler,
    allocator: Allocator,
    const Self = @This();

    pub fn init(other: ?*Handler, allocator: Allocator) Self {
        return .{
            .handler = Handler.init(onRequest, other),
            .allocator = allocator,
        };
    }

    pub fn getHandler(self: *Self) *Handler {
        return &self.handler;
    }

    pub fn onRequest(handler: *Handler, r: zap.Request, context: *Context) bool {
        // const self: *Self = @fieldParentPtr("handler", handler);
        if (context.auth.?.uuid) |uuid| {
            const user = User.findByUID(context.connection.?, &uuid) catch unreachable;
            if (user) |u| {
                context.user = u;
            }
        }
        return handler.handleOther(r, context);
    }
};
