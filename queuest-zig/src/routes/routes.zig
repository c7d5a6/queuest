const std = @import("std");
const zap = @import("zap");
const regez = @cImport({
    @cInclude("regex.h");
    @cInclude("regez.h");
});

var arena: std.heap.ArenaAllocator = undefined;
var routesOld: std.StringHashMap(zap.HttpRequestFn) = undefined;
var routes: []const Path = undefined;

pub fn setup_routes(a: std.mem.Allocator) !void {
    arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // routesOld = std.StringHashMap(zap.HttpRequestFn).init(a);
    // try routesOld.put("/api/hello", on_request_verbose);
    _ = a;
    routes = &.{
        createPath("/api/hello", on_request_verbose),
    };
}

pub fn deinit() void {
    routesOld.deinit();
    arena.deinit();
}

const Path = struct {
    path: [:0]const u8,
    method: zap.HttpRequestFn,
    regex: Regex,
};

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

    fn matches(self: Regex, input: []const u8) !bool {
        const a_input: []u8 = try arena.allocator().alloc(u8, input.len + 1);
        @memcpy(a_input[0..input.len], input);
        a_input[input.len] = 0;
        const match_size = 1;
        var pmatch: [match_size]regez.regmatch_t = undefined;
        return 0 == regez.regexec(self.inner, &a_input, match_size, &pmatch, 0);
    }
};

pub fn createPath(comptime path: [:0]const u8, comptime method: zap.HttpRequestFn) Path {
    const regex: Regex = Regex.init(path) catch unreachable;
    return Path{
        .path = path,
        .method = method,
        .regex = regex,
    };
}

fn on_request_verbose(r: zap.Request) void {
    if (r.path) |the_path| {
        std.debug.print("PATH: {s}\n", .{the_path});
    }
    if (r.query) |the_query| {
        std.debug.print("QUERY: {s}\n", .{the_query});
    }
    r.sendBody("<html><body><h1>Hello from ZAP!!!</h1></body></html>") catch return;
}

pub fn dispatch_routes(r: zap.Request) void {
    // dispatch
    if (r.path) |path| {
        for (routes) |route| {
            if (route.regex.matches(path) catch false) {
                route.method(r);
                return;
            }
        }
    }

    r.sendError(error.Error, null, 404);
}

const expect = std.testing.expect;

test "create and match path" {
    const path = createPath("/api/hello", testApiFn);
    const r_path: []const u8 = "/api/hello";
    expect(path.regex.matches(r_path[0.. :0]));
}

fn testApiFn(method: zap.Request) void {
    _ = method;
}
