const std = @import("std");
const web = @import("baz");
const builtin = @import("builtin");
const routes = @import("routes/routes.zig");
const context = @import("middle/context.zig");
const header = @import("middle/header.zig");
const dev = @import("dev.zig");
const db_open = @import("db/open.zig");
const migrate = @import("db/migrate.zig");
const Application = context.Application;

const default_port: u16 = 3002;

pub const std_options: std.Options = .{
    .log_level = if (builtin.mode == .debug) .info else .err,
    .log_scope_levels = &[_]std.log.ScopeLevel{
        .{ .scope = .auth, .level = if (builtin.mode == .debug) .info else .err },
    },
};

pub fn main(init: std.process.Init) !void {
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

    var shared: context.Shared = .{
        .allocator = init.gpa,
        .io = init.io,
        .db = &db,
        .allow_localhost = dev.enabled(init.environ_map),
    };

    // A reverse proxy is the public side: listen on loopback, port from env.
    const port: u16 = if (init.environ_map.get("PORT")) |p|
        std.fmt.parseInt(u16, p, 10) catch return error.InvalidPort
    else
        default_port;

    const app = try Application.init(.{
        .allocator = init.gpa,
        .io = init.io,
        .shared = &shared,
        .server = .{
            .port = port,
            .bind_address = .{ 127, 0, 0, 1 },
            .connections = 128,
            .shards = 1,
            .output_bytes = 160 * 1024,
        },
        .response = .{ .body_bytes = 64 * 1024 },
        .middleware = &.{header.middleware},
        .on_error = routes.on_error,
    });
    defer app.deinit();

    try routes.register(app);
    try app.start();
    std.log.info("Listening on 127.0.0.1:{d}", .{app.port()});
    try app.run();
}

const expect = std.testing.expect;
const g = @import("services/graph.zig");

test {
    _ = @import("services/collections.zig");
    _ = @import("data/utils.zig");
    _ = @import("db/open.zig");
    _ = @import("db/migrate.zig");
    _ = @import("dev.zig");
    _ = @import("middle/header.zig");
    _ = @import("routes/routes.zig");
}

test "graph" {
    _ = g.Graph;
}

test "always true" {
    std.log.debug("Test started\n", .{});
    try expect(true);
}
