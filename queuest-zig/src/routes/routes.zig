const std = @import("std");
const zap = @import("zap");
const regez = @cImport({
    @cInclude("regex.h");
    @cInclude("regez.h");
});

var arena: std.heap.ArenaAllocator = undefined;
var routes: [2]Path = undefined;

pub fn setup_routes(a: std.mem.Allocator) !void {
    arena = std.heap.ArenaAllocator.init(a);
    routes = [_]Path{
        createPath("/api/hello", on_request_verbose),
        createPath("/api/hello2", on_request_verbose),
    };
}

pub fn deinit() void {
    for (routes) |route| {
        route.regex.deinit();
    }
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

    fn matches(self: Regex, allocator: std.mem.Allocator, input: []const u8) !bool {
        const a_input: []u8 = try allocator.alloc(u8, input.len + 1);
        @memcpy(a_input[0..input.len], input);
        a_input[input.len] = 0;
        const c_input: [:0]const u8 = a_input[0..input.len :0];
        const match_size = 1;
        var pmatch: [match_size]regez.regmatch_t = undefined;
        const res = regez.regexec(self.inner, c_input, match_size, &pmatch, 0);
        return 0 == res;
    }
};

pub fn createPath(path: [:0]const u8, method: zap.HttpRequestFn) Path {
    const regex: Regex = Regex.init(path) catch unreachable;
    return Path{
        .path = path,
        .method = method,
        .regex = regex,
    };
}

fn on_request_verbose(r: zap.Request) void {
    // if (r.path) |the_path| { std.debug.print("PATH: {s}\n", .{the_path}); }
    // if (r.query) |the_query| { std.debug.print("QUERY: {s}\n", .{the_query}); }
    //
    r.sendBody("<html><body><h1>Hello from ZAP!!!</h1></body></html>") catch return;
}

pub fn dispatch_routes(r: zap.Request) void {
    defer _ = arena.reset(.retain_capacity);
    // dispatch
    if (r.path) |path| {
        for (routes) |route| {
            if (route.regex.matches(arena.allocator(), path) catch false) {
                route.method(r);
                return;
            }
        }
    }
    r.sendError(error.Error, null, 404);
}

const expect = std.testing.expect;

test "create and match path" {
    const pathStr = "/api/hello";
    const path = createPath(pathStr, testApiFn);
    defer path.regex.deinit();
    const pathIn: [10]u8 = .{ '/', 'a', 'p', 'i', '/', 'h', 'e', 'l', 'l', 'o' };
    const result = try path.regex.matches(std.heap.page_allocator, pathIn[0..]);
    try expect(result);
}

fn testApiFn(method: zap.Request) void {
    _ = method;
}
