const std = @import("std");
const zap = @import("zap");
const routes = @import("routes/routes.zig");
const auth = @import("auth/auth.zig");
const expect = std.testing.expect;

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

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};
    const allocator = gpa.allocator();
    SharedAllocator.init(allocator);
    // _ = gpa;
    // var buffer: [1000]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buffer);
    {
        // we create our HTML middleware component that handles the request
        var htmlHandler = auth.HtmlMiddleWare.init(null);

        // we wrap it in the session Middleware component
        var sessionHandler = auth.SessionMiddleWare.init(htmlHandler.getHandler());

        // we wrap that in the user Middleware component
        var userHandler = auth.UserMiddleWare.init(sessionHandler.getHandler());
        // use this allocator for all your memory allocation
        try routes.setup_routes(allocator);
        defer routes.deinit();
        var listener = try zap.Middleware.Listener(auth.Context).init(
            .{
                .port = 3000,
                .log = true,
                .max_clients = 100000,
                .on_request = null, // must be null
            },
            userHandler.getHandler(),
            SharedAllocator.getAllocator,
        );
        zap.enableDebugLog();

        listener.listen() catch |err| {
            std.debug.print("\nLISTEN ERROR: {any}\n", .{err});
            return;
        };
        std.debug.print("Listening on 0.0.0.0:3000\n", .{});
        // start worker threads
        zap.start(.{
            // if all threads hang, your server will hang
            .threads = 5,
            // workers share memory so do not share states if you have multiple workers
            .workers = 2,
        });
    }
    // all defers should have run by now
    std.debug.print("\n\nSTOPPED!\n\n", .{});
    // we'll arrive here after zap.stop()
    const leaked = gpa.detectLeaks();
    std.debug.print("Leaks detected: {}\n", .{leaked});
}

test "always fail" {
    try expect(true);
}

test "always true" {
    std.debug.print("Test started\n", .{});
    try expect(true);
}
