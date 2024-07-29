const std = @import("std");
const zap = @import("zap");
const Context = @import("../middle/context.zig").Context;
const Collection = @import("../data/collection.zig").Collection;
const Regex = @import("matcher.zig").Regex;

pub const ControllerRequest = *const fn (zap.Request, *Context) void;
pub const DispatchRoutes = *const fn (zap.Request, *Context) void;

var arena: std.heap.ArenaAllocator = undefined;

const Path = struct {
    path: [:0]const u8,
    method: ControllerRequest,
    regex: Regex,
};
//
// --- Paths of REST methods
//
const rt = [_]struct { [:0]const u8, ControllerRequest }{
    .{ "/api/hello", on_request_verbose },
    .{ "/api/hello/{helloId}/fav/{favId}", on_request_verbose },
    .{ "/collections", on_get_collections },
};
var routes: [rt.len]Path = undefined;

//
// --- Setup
//
pub fn setup_routes(a: std.mem.Allocator) !void {
    {
        var arena_tmp = std.heap.ArenaAllocator.init(a);
        defer arena_tmp.deinit();
        for (&routes, 0..) |*pt, i| {
            pt.* = createPath(arena_tmp.allocator(), rt[i][0], rt[i][1]);
        }
    }

    arena = std.heap.ArenaAllocator.init(a);
}

pub fn deinit() void {
    for (routes) |route| {
        route.regex.deinit();
    }
    arena.deinit();
}

fn createPath(a: std.mem.Allocator, path: [:0]const u8, method: ControllerRequest) Path {
    const pathPattern = getPathPattern(a, path);
    const regex: Regex = Regex.init(pathPattern) catch unreachable;
    return Path{
        .path = path,
        .method = method,
        .regex = regex,
    };
}

const regStart = "^";
const paramRx = "([^/?]+)";
const urlEnd = "(\\?[^&?=]+=[^&?=]+(&[^&?=]+=[^&?=]+)*)?$";

fn getPathPattern(a: std.mem.Allocator, path: [:0]const u8) [:0]u8 {
    var urlReg = a.alloc(u8, 1024 + path.len) catch unreachable;
    var start: usize = 0;

    var end: usize = regStart.len;
    @memcpy(urlReg[start..end], regStart);
    start = end;

    var startPath: usize = 0;
    while (std.mem.indexOfScalarPos(u8, path[0..], startPath, '{')) |pos| {
        const endPath = std.mem.indexOfScalarPos(u8, path[0..], pos, '}') orelse unreachable;
        end = end + pos - startPath;
        @memcpy(urlReg[start..end], path[startPath..pos]);
        startPath = endPath + 1;
        start = end;

        end = end + paramRx.len;
        @memcpy(urlReg[start..end], paramRx);
        start = end;
    }

    end = end + path.len - startPath;
    @memcpy(urlReg[start..end], path[startPath..]);
    start = end;

    end = end + urlEnd.len;
    @memcpy(urlReg[start..end], urlEnd);

    urlReg[end] = 0;
    return urlReg[0..end :0];
}

fn on_get_collections(r: zap.Request, c: *Context) void {
    const collections: std.ArrayList(Collection) = Collection.findAll(c.connection.?, arena.allocator()) catch unreachable;
    const json = std.json.stringifyAlloc(arena.allocator(), collections.items, .{ .escape_unicode = true, .emit_null_optional_fields = false }) catch unreachable;
    r.setContentType(.JSON) catch return;
    r.sendJson(json) catch return;
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
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};
    const allocator = gpa.allocator();

    const pathStr = "/api/hello/{id}/fav/{favid}";
    const path = createPath(allocator, pathStr, testApiFn);
    defer path.regex.deinit();
    const pathIn = [_]u8{ '/', 'a', 'p', 'i', '/', 'h', 'e', 'l', 'l', 'o', '/', '1', '/', 'f', 'a', 'v', '/', '5', '0', '/' };
    const t = try path.regex.matches(std.heap.page_allocator, pathIn[0..19]);
    const f = try path.regex.matches(std.heap.page_allocator, pathIn[0..]);
    try expect(t);
    try expect(!f);
}

fn testApiFn(r: zap.Request, c: *Context) void {
    _ = r;
    _ = c;
}

// test "check"
