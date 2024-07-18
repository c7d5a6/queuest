const std = @import("std");
const zap = @import("zap");
const routes = @import("routes/routes.zig");
const auth = @import("auth/auth.zig");
const expect = std.testing.expect;

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

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};
    const allocator = gpa.allocator();
    SharedAllocator.init(allocator);
    {
        var htmlHandler = auth.HtmlMiddleWare.init(null);
        var sessionHandler = auth.SessionMiddleWare.init(htmlHandler.getHandler());
        var userHandler = auth.UserMiddleWare.init(sessionHandler.getHandler());

        try routes.setup_routes(allocator);
        defer routes.deinit();

        // we wrap that in the user Middleware component
        var listener = try zap.Middleware.Listener(auth.Context).init(
            .{
                .port = port,
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

test {
    std.testing.refAllDeclsRecursive(@This());
    // or refAllDeclsRecursive
}

test "always true" {
    std.debug.print("Test started\n", .{});
    try expect(true);
}
