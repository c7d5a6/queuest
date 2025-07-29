const std = @import("std");
const Allocator = std.mem.Allocator;
const zap = @import("zap");
const pg = @import("pg");
const Pool = pg.Pool;
const contextLib = @import("context.zig");
const DispatchRoutes = @import("../routes/routes.zig").DispatchRoutes;
const Context = contextLib.Context;

const Handler = zap.Middleware.Handler(Context);

pub const ControllerMiddleWare = struct {
    handler: Handler,
    dispatch: DispatchRoutes,
    allocator: Allocator,

    const Self = @This();

    pub fn init(other: ?*Handler, dispatch: DispatchRoutes, allocator: Allocator) Self {
        return .{
            .handler = Handler.init(onRequest, other),
            .dispatch = dispatch,
            .allocator = allocator,
        };
    }

    // we need the handler as a common interface to chain stuff
    pub fn getHandler(self: *Self) *Handler {
        return &self.handler;
    }

    // note that the first parameter is of type *Handler, not *Self !!!
    pub fn onRequest(handler: *Handler, r: zap.Request, context: *Context) !bool {
        // this is how we would get our self pointer
        const self: *Self = @fieldParentPtr("handler", handler);
        var arena = std.heap.ArenaAllocator.init(self.allocator);
        // defer _ = arena.reset(.retain_capacity);
        defer arena.deinit();

        self.dispatch(arena.allocator(), r, context);

        std.log.debug("\n\nHtmlMiddleware: handling request with context: {any}\n\n", .{context});

        return true;
    }
};
