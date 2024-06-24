const std = @import("std");
const zap = @import("zap");
const routes = @import("routes/routes.zig");
const expect = std.testing.expect;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};
    {
        //        const Regex_t = ?*regex.regex_t;
        //        const rexx: Regex_t = regex.alloc_regex_t();
        //        const reti = regex.regcomp(rexx, "^a[[:alnum:]]", 0);
        //        if (reti != 0) {
        //            std.debug.print("Could not compile regex\n", .{});
        //            return;
        //        }
        try reg();
        // use this allocator for all your memory allocation
        const allocator = gpa.allocator();
        try routes.setup_routes(allocator);
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
    const leaked = gpa.detectLeaks();
    std.debug.print("Leaks detected: {}\n", .{leaked});
}

fn reg() !void {
    {
        //        const regex = try Regex.init("[ab]c");
        //        defer regex.deinit();
        //
        //        try std.testing.expect(regex.matches("bc"));
        //        try std.testing.expect(!regex.matches("cc"));
        //        std.debug.print("Regex : {}\n", .{regex.matches("aab")});
    }

    {
        //        const regex = try Regex.init("John.*o");
        //        defer regex.deinit();

        //        try regex.exec(
        //            \\ 1) John Driverhacker;
        //            \\ 2) John Doe;
        //            \\ 3) John Foo;
        //            \\
        //        );
    }
}

test "always fail" {
    try expect(true);
}

test "always true" {
    std.debug.print("Test started\n", .{});
    try expect(true);
}
