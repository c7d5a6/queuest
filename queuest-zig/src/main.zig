const std = @import("std");
const zap = @import("zap");
const regez = @cImport({
    @cInclude("regex.h");
    @cInclude("regez.h");
});

var routes: std.StringHashMap(zap.HttpRequestFn) = undefined;

const Regex = struct {
    inner: *regez.regex_t,

    fn init(pattern: [:0]const u8) !Regex {
        const inner = regez.alloc_regex_t().?;
        if (0 != regez.regcomp(inner, pattern, regez.REG_NEWLINE | regez.REG_EXTENDED)) {
            return error.compile;
        }

        return .{
            .inner = inner,
        };
    }

    fn deinit(self: Regex) void {
        regez.free_regex_t(self.inner);
    }

    fn matches(self: Regex, input: [:0]const u8) bool {
        const match_size = 1;
        var pmatch: [match_size]regez.regmatch_t = undefined;
        return 0 == regez.regexec(self.inner, input, match_size, &pmatch, 0);
    }
};

fn on_request_verbose(r: zap.Request) void {
    if (r.path) |the_path| {
        std.debug.print("PATH: {s}\n", .{the_path});
    }
    if (r.query) |the_query| {
        std.debug.print("QUERY: {s}\n", .{the_query});
    }
    r.sendBody("<html><body><h1>Hello from ZAP!!!</h1></body></html>") catch return;
}

fn dispatch_routes(r: zap.Request) void {
    // dispatch
    if (r.path) |the_path| {
        if (routes.get(the_path)) |foo| {
            foo(r);
            return;
        }
    }

    r.sendError(error.Error, null, 404);
}

fn setup_routes(a: std.mem.Allocator) !void {
    routes = std.StringHashMap(zap.HttpRequestFn).init(a);
    try routes.put("/api/hello", on_request_verbose);
}

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
        try setup_routes(allocator);
        defer routes.deinit();
        var listener = zap.HttpListener.init(.{
            .port = 3000,
            .on_request = dispatch_routes,
            .log = true,
        });
        try listener.listen();
        std.debug.print("Listening on 0.0.0.0:3000\n", .{});
        // start worker threads
        zap.start(.{
            // if all threads hang, your server will hang
            .threads = 2,
            // workers share memory so do not share states if you have multiple workers
            .workers = 1,
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
        const regex = try Regex.init("[ab]c");
        defer regex.deinit();

        try std.testing.expect(regex.matches("bc"));
        try std.testing.expect(!regex.matches("cc"));
        std.debug.print("Regex : {}\n", .{regex.matches("aab")});
    }

    {
        const regex = try Regex.init("John.*o");
        defer regex.deinit();

        try regex.exec(
            \\ 1) John Driverhacker;
            \\ 2) John Doe;
            \\ 3) John Foo;
            \\
        );
    }
}
