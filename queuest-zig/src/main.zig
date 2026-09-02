const std = @import("std");
const zap = @import("zap");
const builtin = @import("builtin");
const routes = @import("routes/routes.zig");
const DispatchRoutes = routes.DispatchRoutes;
const auth = @import("middle/auth.zig");
const userMiddle = @import("middle/user.zig");
const sqliteMiddle = @import("middle/sqlite.zig");
const contextLib = @import("middle/context.zig");
const controller = @import("middle/controller.zig");
const header = @import("middle/header.zig");
const db_open = @import("db/open.zig");
const migrate = @import("db/migrate.zig");
const Context = contextLib.Context;
const Session = contextLib.Session;
const SharedAllocator = contextLib.SharedAllocator;

const Handler = zap.Middleware.Handler(Context);

const port = 3002;

pub const std_options: std.Options = .{
    .log_level = if (builtin.mode == .Debug) .info else .err,
    .log_scope_levels = &[_]std.log.ScopeLevel{
        .{ .scope = .zap, .level = if (builtin.mode == .Debug) .info else .warn },
        .{ .scope = .auth, .level = if (builtin.mode == .Debug) .info else .err },
    },
};
pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    SharedAllocator.init(allocator, init.io);
    {
        const sqlite_path = db_open.pathFromEnv(init.environ_map);
        var db = db_open.openFile(sqlite_path) catch |err| {
            std.log.err("Failed to open sqlite at {s}: {}", .{ sqlite_path, err });
            std.process.exit(1);
        };
        defer db.deinit();
        migrate.run(&db) catch |err| {
            std.log.err("Failed to migrate sqlite: {}", .{err});
            std.process.exit(1);
        };

        try routes.setup_routes(allocator);
        defer routes.deinit();

        var controllerHandler = controller.ControllerMiddleWare.init(null, routes.dispatch_routes, allocator);
        var userHandler = userMiddle.UserMiddleware.init(controllerHandler.getHandler(), allocator);
        var sqliteHandler = sqliteMiddle.SqliteMiddleware.init(userHandler.getHandler(), allocator, &db);
        var jwtHandler = auth.JWTMiddleware.init(sqliteHandler.getHandler(), allocator);
        var headerHandler = header.HeaderMiddleWare.init(jwtHandler.getHandler());

        var listener = try zap.Middleware.Listener(Context).init(
            .{
                .port = port,
                .log = true,
                .max_clients = 100000,
                .on_request = null,
            },
            headerHandler.getHandler(),
            SharedAllocator.getAllocator,
        );
        listener.listen() catch |err| {
            std.log.debug("\nLISTEN ERROR: {any}\n", .{err});
            return;
        };
        std.log.debug("Listening on 0.0.0.0:{d}\n", .{port});

        zap.start(.{
            .threads = 1,
            .workers = 1,
        });
    }
}

const expect = std.testing.expect;
const g = @import("services/graph.zig");

test {
    _ = @import("services/collections.zig");
    _ = @import("data/utils.zig");
    _ = @import("db/open.zig");
    _ = @import("db/migrate.zig");
}

test "graph" {
    _ = g.Graph;
}

test "always true" {
    std.log.debug("Test started\n", .{});
    try expect(true);
}
