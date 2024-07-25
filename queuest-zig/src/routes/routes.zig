const std = @import("std");
const zap = @import("zap");
const Context = @import("../middle/context.zig").Context;
const Collection = @import("../data/collection.zig").Collection;
const regez = @cImport({
    @cInclude("regex.h");
    @cInclude("regez.h");
});

pub const ControllerRequest = *const fn (zap.Request, *Context) void;
pub const DispatchRoutes = *const fn (zap.Request, *Context) void;

var arena: std.heap.ArenaAllocator = undefined;
var routes: [2]Path = undefined;

pub fn setup_routes(a: std.mem.Allocator) !void {
    arena = std.heap.ArenaAllocator.init(a);
    routes = [_]Path{
        createPath("/api/hello", on_request_verbose),
        createPath("/collections", on_get_collections),
    };
}

fn on_get_collections(r: zap.Request, c: *Context) void {
    const collections: std.ArrayList(Collection) = Collection.findAll(c.connection.?, arena.allocator()) catch unreachable;
    // const jsonArray = std.json.Array.init(arena.allocator());
    const json = std.json.stringifyAlloc(arena.allocator(), collections.items, .{ .escape_unicode = true, .emit_null_optional_fields = false }) catch unreachable;
    r.setContentType(.JSON) catch return;
    r.sendJson(json) catch return;
}

pub fn deinit() void {
    for (routes) |route| {
        route.regex.deinit();
    }
    arena.deinit();
}

const Path = struct {
    path: [:0]const u8,
    method: ControllerRequest,
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

pub fn createPath(path: [:0]const u8, method: ControllerRequest) Path {
    const regex: Regex = Regex.init(path) catch unreachable;
    return Path{
        .path = path,
        .method = method,
        .regex = regex,
    };
}

fn on_request_verbose(r: zap.Request, c: *Context) void {
    _ = c;
    r.sendBody("<html><body><h1>Hello from ZAP!!!</h1></body></html>") catch return;
}

pub fn dispatch_routes(r: zap.Request, c: *Context) void {
    defer _ = arena.reset(.retain_capacity);
    // dispatch
    if (r.path) |path| {
        for (routes) |route| {
            if (route.regex.matches(arena.allocator(), path) catch false) {
                route.method(r, c);
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
