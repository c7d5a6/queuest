const std = @import("std");
const zap = @import("zap");
const routes = @import("routes/routes.zig");
const auth = @import("auth/auth.zig");
const contextLib = @import("auth/context.zig");
const Context = contextLib.Context;
const Session = contextLib.Session;

const Handler = zap.Middleware.Handler(Context);

const port = 3000;

// just a way to share our allocator via callback
const SharedAllocator = struct {
    // static
    var allocator: std.mem.Allocator = undefined;

    const Self = @This();

    // just a convenience function
    pub fn init(a: std.mem.Allocator) void {
        allocator = a;
    }

    // static function we can pass to the listener later
    pub fn getAllocator() std.mem.Allocator {
        return allocator;
    }
};

// Example session middleware: puts session info into the context
pub const SessionMiddleWare = struct {
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
        // this is how we would get our self pointer
        const self: *Self = @fieldParentPtr("handler", handler);
        _ = self;

        context.session = Session{
            .info = "secret session",
            .token = "rot47-asdlkfjsaklfdj",
        };

        std.debug.print("\n\nSessionMiddleware: set session in context {any}\n\n", .{context.session});

        // continue in the chain
        return handler.handleOther(r, context);
    }
};

// Example html middleware: handles the request and sends a response
pub const HtmlMiddleWare = struct {
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

        // this is how we would get our self pointer
        const self: *Self = @fieldParentPtr("handler", handler);
        _ = self;

        std.debug.print("\n\nHtmlMiddleware: handling request with context: {any}\n\n", .{context});

        var buf: [1024]u8 = undefined;
        var userFound: bool = false;
        var sessionFound: bool = false;
        if (context.user) |user| {
            userFound = true;
            if (context.session) |session| {
                sessionFound = true;

                std.debug.assert(r.isFinished() == false);
                const message = std.fmt.bufPrint(&buf, "User: {any} / {?s}, Session: {s} / {s}", .{
                    user.authenticated,
                    user.uuid,
                    session.info,
                    session.token,
                }) catch unreachable;
                r.setContentType(.TEXT) catch unreachable;
                r.sendBody(message) catch unreachable;
                std.debug.assert(r.isFinished() == true);
                return true;
            }
        }

        const message = std.fmt.bufPrint(&buf, "User info found: {}, session info found: {}", .{ userFound, sessionFound }) catch unreachable;

        r.setContentType(.TEXT) catch unreachable;
        r.sendBody(message) catch unreachable;
        return true;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};
    const allocator = gpa.allocator();
    SharedAllocator.init(allocator);
    {
        var htmlHandler = HtmlMiddleWare.init(null);
        var sessionHandler = SessionMiddleWare.init(htmlHandler.getHandler());
        var jwtHandler = auth.JWTMiddleware.init(sessionHandler.getHandler(), allocator);

        try routes.setup_routes(allocator);
        defer routes.deinit();

        // we wrap that in the user Middleware component
        var listener = try zap.Middleware.Listener(Context).init(
            .{
                .port = port,
                .log = true,
                .max_clients = 100000,
                .on_request = null, // must be null
            },
            jwtHandler.getHandler(),
            SharedAllocator.getAllocator,
        );
        zap.enableDebugLog();

        listener.listen() catch |err| {
            std.debug.print("\nLISTEN ERROR: {any}\n", .{err});
            return;
        };
        std.debug.print("Listening on 0.0.0.0:{d}\n", .{port});
        // start worker threads
        zap.start(.{
            // if all threads hang, your server will hang
            .threads = 1,
            // workers share memory so do not share states if you have multiple workers
            .workers = 1,
        });
    }
    std.debug.print("\n\nSTOPPED!\n\n", .{});
    const leaked = gpa.detectLeaks();
    std.debug.print("Leaks detected: {}\n", .{leaked});
}

const expect = std.testing.expect;

test {
    std.testing.refAllDeclsRecursive(@This());
    // or refAllDeclsRecursive
}

test "always true" {
    std.debug.print("Test started\n", .{});
    try expect(true);
}
