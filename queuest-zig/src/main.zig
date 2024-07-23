const std = @import("std");
const zap = @import("zap");
const pg = @import("pg");
const routes = @import("routes/routes.zig");
const auth = @import("middle/auth.zig");
const userMiddle = @import("middle/user.zig");
const trans = @import("middle/trans.zig");
const contextLib = @import("middle/context.zig");
const Context = contextLib.Context;
const Session = contextLib.Session;
const SharedAllocator = contextLib.SharedAllocator;

const Handler = zap.Middleware.Handler(Context);

const port = 3000;

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

        var buf: [8024]u8 = undefined;
        var userFound: bool = false;
        if (context.user) |user| {
            userFound = true;
            var result = context.connection.?.query("select * from user_tbl order by id", .{}) catch unreachable;
            defer result.deinit();
            std.debug.print("\nsql result: {any}\n", .{result});

            std.debug.assert(r.isFinished() == false);
            const message = std.fmt.bufPrint(&buf, "User: {s} / {s}\n\n<div>{any}</div>", .{
                user.email,
                user.uid,
                result,
            }) catch unreachable;
            r.setContentType(.TEXT) catch unreachable;
            r.sendBody(message) catch unreachable;
            std.debug.assert(r.isFinished() == true);
            return true;
        }

        const message = std.fmt.bufPrint(&buf, "User info found: {}", .{userFound}) catch unreachable;

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
        // Database
        const pool = pg.Pool.init(allocator, .{ .size = 5, .connect = .{
            .port = 5432,
            .host = "127.0.0.1",
        }, .auth = .{
            .username = "queuest",
            .database = "queuest",
            .password = "queuest",
            .timeout = 10_000,
        } }) catch |err| {
            std.debug.print("Failed to connect: {}", .{err});
            std.posix.exit(1);
        };
        defer pool.deinit();

        //Handlers
        var htmlHandler = HtmlMiddleWare.init(null);
        var userHandler = userMiddle.UserMiddleware.init(htmlHandler.getHandler(), allocator);
        var transactionHandler = trans.TransactionMiddleware.init(userHandler.getHandler(), allocator, pool);
        var jwtHandler = auth.JWTMiddleware.init(transactionHandler.getHandler(), allocator);

        // Routes
        try routes.setup_routes(allocator);
        defer routes.deinit();

        // Listner with first middleware in line
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
