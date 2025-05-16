const std = @import("std");
const zap = @import("zap");
const pg = @import("pg");
const sqlite = @import("sqlite");
const builtin = @import("builtin");
const routes = @import("routes/routes.zig");
const DispatchRoutes = routes.DispatchRoutes;
const auth = @import("middle/auth.zig");
const userMiddle = @import("middle/user.zig");
const trans = @import("middle/trans.zig");
const sqliteMiddle = @import("middle/sqlite.zig");
const contextLib = @import("middle/context.zig");
const controller = @import("middle/controller.zig");
const header = @import("middle/header.zig");
const Context = contextLib.Context;
const Session = contextLib.Session;
const SharedAllocator = contextLib.SharedAllocator;

const Handler = zap.Middleware.Handler(Context);

const port = 3000;

pub const std_options: std.Options = .{
    // general log level
    .log_level = .debug,
    .log_scope_levels = &[_]std.log.ScopeLevel{
        // log level specific to zap
        .{ .scope = .zap, .level = .debug },
    },
};
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = if (builtin.mode == .Debug) gpa.allocator() else std.heap.c_allocator;
    SharedAllocator.init(allocator);
    {
        //
        // --- Database
        //
        const pool = pg.Pool.init(allocator, .{ .size = 5, .connect = .{
            .port = 5432,
            .host = "127.0.0.1",
        }, .auth = .{
            .username = "queuest",
            .database = "queuest",
            .password = "queuest",
            .timeout = 10_000,
        } }) catch |err| {
            std.log.debug("Failed to connect: {}", .{err});
            std.posix.exit(1);
        };
        defer pool.deinit();
        // sqlite
        var db = sqlite.Db.init(.{
            .mode = sqlite.Db.Mode{ .File = "queuest.db" },
            .open_flags = .{
                .write = true,
                .create = true,
            },
            .threading_mode = .MultiThread,
        }) catch unreachable;
        defer db.deinit();

        //
        // --- Routes
        //
        try routes.setup_routes(allocator);
        defer routes.deinit();

        //
        // --- Handlers
        //
        var controllerHandler = controller.ControllerMiddleWare.init(null, routes.dispatch_routes, allocator);
        var userHandler = userMiddle.UserMiddleware.init(controllerHandler.getHandler(), allocator);
        var transactionHandler = trans.TransactionMiddleware.init(userHandler.getHandler(), allocator, pool);
        var sqliteHandler = sqliteMiddle.SqliteMiddleware.init(transactionHandler.getHandler(), allocator, &db);
        var jwtHandler = auth.JWTMiddleware.init(sqliteHandler.getHandler(), allocator);
        var headerHandler = header.HeaderMiddleWare.init(jwtHandler.getHandler());

        //
        // --- Listner with first middleware in line
        //
        var listener = try zap.Middleware.Listener(Context).init(
            .{
                .port = port,
                .log = true,
                .max_clients = 100000, // TODO: setup this number
                .on_request = null, // must be null
            },
            headerHandler.getHandler(),
            SharedAllocator.getAllocator,
        );
        listener.listen() catch |err| {
            std.log.debug("\nLISTEN ERROR: {any}\n", .{err});
            return;
        };
        std.log.debug("Listening on 0.0.0.0:{d}\n", .{port});

        //
        // --- Start worker threads
        //
        zap.start(.{
            // if all threads hang, your server will hang
            .threads = 1,
            // workers share memory so do not share states if you have multiple workers
            .workers = 1,
        });
    }

    if (builtin.mode == .Debug) {
        std.log.debug("\n\nSTOPPED!\n\n", .{});
        const leaked = gpa.detectLeaks();
        std.log.debug("Leaks detected: {}\n", .{leaked});
    }
}

const expect = std.testing.expect;
const g = @import("services/graph.zig");

test {
    _ = @import("services/collections.zig");
    // or refAllDeclsRecursive
}

test "graph" {
    _ = g.Graph;
}

test "always true" {
    std.log.debug("Test started\n", .{});
    try expect(true);
}
