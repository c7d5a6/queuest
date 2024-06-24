const std = @import("std");
const zap = @import("zap");
const routes = @import("routes/routes.zig");
const expect = std.testing.expect;

pub fn main() !void {
    const gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};
    _ = gpa;
    var buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    {
        // use this allocator for all your memory allocation
        try routes.setup_routes(fba.allocator());
        defer routes.deinit();
        var listener = zap.HttpListener.init(.{
            .port = 3000,
            .on_request = routes.dispatch_routes,
            .log = false,
        });
        try listener.listen();
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
    // const leaked = gpa.detectLeaks();
    // std.debug.print("Leaks detected: {}\n", .{leaked});
}

test "always fail" {
    try expect(true);
}

test "always true" {
    std.debug.print("Test started\n", .{});
    try expect(true);
}
