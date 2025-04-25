const std = @import("std");
const zap = @import("zap");
const Allocator = std.mem.Allocator;
const testing = std.testing;
const Context = zap.Context;

pub const TestServer = struct {
    allocator: Allocator,
    endpoint: Endpoint,
    server: *zap.SimpleEndpoint,

    pub const Endpoint = struct {
        host: []const u8,
        port: u16,
    };

    pub fn init(allocator: Allocator, endpoint: Endpoint) !*TestServer {
        var self = try allocator.create(TestServer);
        self.allocator = allocator;
        self.endpoint = endpoint;
        self.server = try zap.Middleware.Listener(Context).init(
            .{
                .host = endpoint.host,
                .port = endpoint.port,
                .log = true,
                .max_clients = 100000, // TODO: setup this number
                .on_request = null, // must be null
            },
            headerHandler.getHandler(),
            allocator,
        );
        listener.listen() catch |err| {
            std.log.debug("\nLISTEN ERROR: {any}\n", .{err});
            return;
        };
        return self;
    }

    pub fn deinit(self: *TestServer) void {
        self.server.deinit();
        self.allocator.destroy(self);
    }

    pub fn start(self: *TestServer) !void {
        try self.server.listen();
    }

    pub fn stop(self: *TestServer) void {
        self.server.stop();
    }
};

fn onRequest(r: zap.SimpleRequest) void {
    _ = r;
    // This will be replaced with actual request handling
}

pub fn runTests(allocator: Allocator) !void {
    const endpoint = TestServer.Endpoint{
        .host = "127.0.0.1",
        .port = 3000,
    };

    var server = try TestServer.init(allocator, endpoint);
    defer server.deinit();

    // Start server in a separate thread
    var server_thread = try std.Thread.spawn(.{}, TestServer.start, .{server});
    defer server_thread.join();

    // Give server time to start
    std.time.sleep(1 * std.time.ns_per_s);

    // Run tests
    try runCollectionTests(allocator, endpoint);

    // Stop server
    server.stop();
}

fn runCollectionTests(allocator: Allocator, endpoint: TestServer.Endpoint) !void {
    const base_url = try std.fmt.allocPrint(allocator, "http://{s}:{d}", .{ endpoint.host, endpoint.port });
    defer allocator.free(base_url);

    // Test creating a collection
    var headers = std.http.Headers.init(allocator);
    defer headers.deinit();
    try headers.append("Content-Type", "application/json");

    const create_collection_body = try std.json.stringifyAlloc(allocator, .{
        .name = "Test Collection",
        .favourite = false,
    }, .{});
    defer allocator.free(create_collection_body);

    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    var req = try client.request(.POST, try std.Uri.parse(base_url ++ "/collections"), headers, .{});
    defer req.deinit();
    try req.start();
    try req.writeAll(create_collection_body);
    try req.finish();
    try req.wait();

    try testing.expectEqual(req.response.status, .ok);
    const body = try req.reader().readAllAlloc(allocator, 1024 * 1024);
    defer allocator.free(body);
    try testing.expect(body.len > 0);
}
