const std = @import("std");
const zap = @import("zap");
const Method = zap.Method;
const Context = @import("../middle/context.zig").Context;
const collections = @import("../services/collections.zig");
const items = @import("../services/items.zig");
const Regex = @import("matcher.zig").Regex;
const ControllerError = @import("router-errors.zig").ControllerError;

pub const ControllerRequest = *const fn (std.mem.Allocator, zap.Request, *Context, anytype) ControllerError!void;
pub const DispatchRoutes = *const fn (std.mem.Allocator, zap.Request, *Context) void;

var arena: std.heap.ArenaAllocator = undefined;

const Access = enum {
    Unauthorized,
    Authorized,
};

pub const Path = struct {
    path: [:0]const u8,
    method: ControllerRequest,
    httpMethod: Method,
    access: Access,
    methodType: type,
};
//
// --- Paths of REST methods
//
const rt = [_]struct { Method, Access, [:0]const u8, type, ControllerRequest }{
    .{ .GET, .Unauthorized, "/api/hello", struct {}, on_request_verbose },
    // -- Collections
    .{ .GET, .Authorized, "/collections", struct {}, collections.on_get_collections },
    .{ .GET, .Authorized, "/collections/fav", struct {}, collections.on_get_fav_collections },
    .{ .GET, .Authorized, "/collections/{collectionId}", struct { collectionId: i64 }, collections.on_get_collection },
    // POST /collections
    // POST /collections/fav/{collectionId}
    // POST /collections/visit/{collectionId}
    // DELETE /collections/fav/{collectionId}
    // -- Items
    .{ .GET, .Authorized, "/collections/{collectionId}/items", struct { collectionId: i64 }, items.on_get_items },
    // GET /collections/{collectionId}/items/least-calibrated
    // GET /collections/{collectionId}/items/{id}/bestpair/{strict}
    // POST /collections/{collectionId}/items
    // DELETE /collections/{collectionId}/items/{collectionItemId}
    // -- ItemsRelation
    // POST /relations/{fromId}/{toId}
    // DELETE /relations/{itemAId}/{itemBId}
};
const routes: [rt.len]Path = init_rts: {
    var initial: [rt.len]Path = undefined;
    for (&initial, 0..) |*pt, i| {
        pt.* = Path{
            .httpMethod = rt[i][0],
            .access = rt[i][1],
            .path = rt[i][2],
            .methodType = rt[i][3],
            .method = rt[i][4],
        };
    }
    break :init_rts initial;
};
var routesMatcher: []Regex = undefined;

//
// --- Setup
//
pub fn setup_routes(a: std.mem.Allocator) !void {
    arena = std.heap.ArenaAllocator.init(a);
    routesMatcher = arena.allocator().alloc(Regex, rt.len) catch unreachable;
    {
        var arena_tmp = std.heap.ArenaAllocator.init(a);
        defer arena_tmp.deinit();
        inline for (0..rt.len) |i| {
            const pathPattern = getPathPattern(arena_tmp.allocator(), rt[i][2]);
            const regex: Regex = Regex.init(pathPattern) catch unreachable;
            routesMatcher[i] = regex;
        }
    }
}

pub fn deinit() void {
    for (routesMatcher) |route| {
        route.deinit();
    }
    arena.deinit();
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

fn getRouteParams(comptime T: type, comptime path: []const u8, url: []const u8) T {
    const params_type_info = @typeInfo(T);
    if (params_type_info != .Struct) {
        @compileError("expected tuple or struct argument, found " ++ @typeName(T));
    }
    var result: T = undefined;
    comptime var start = 0;
    comptime var i = 0;
    var valueStart: usize = 0;
    inline while (comptime std.mem.indexOfScalarPos(u8, path[0..], start, '{')) |pos| : (i += 1) {
        valueStart = valueStart + pos - start;
        const end = comptime std.mem.indexOfScalarPos(u8, path[0..], pos, '}') orelse unreachable;
        const valueEnd = std.mem.indexOfScalarPos(u8, url[0..], valueStart, '/') orelse url.len;
        const paramName = path[pos + 1 .. end];
        const paramValue = url[valueStart..valueEnd];
        std.log.debug("parse int param value: {s}", .{paramValue});
        const value = std.fmt.parseInt(i64, paramValue, 10) catch unreachable;
        @field(result, paramName) = value;
        start = end;
        valueStart = valueEnd - 1;
    }

    return result;
}

fn on_request_verbose(a: std.mem.Allocator, r: zap.Request, c: *Context, params: anytype) ControllerError!void {
    _ = c;
    _ = params;
    _ = a;
    r.sendBody("<html><body><h1>Hello from ZAP!!!</h1></body></html>") catch return;
}

pub fn dispatch_routes(a: std.mem.Allocator, r: zap.Request, c: *Context) void {
    // dispatch
    const httpMethod = r.methodAsEnum();
    if (r.path) |path| {
        inline for (routes, 0..) |route, i| {
            if (httpMethod == route.httpMethod and routesMatcher[i].matches(arena.allocator(), path) catch false) {
                if (route.access == .Authorized and (c.auth == null or !c.auth.?.authenticated)) {
                    r.sendError(error.Error, null, 401);
                    return;
                }
                const params = getRouteParams(route.methodType, route.path, path);
                route.method(a, r, c, params) catch |err| {
                    r.sendError(err, null, 500);
                };
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
    const pathPattern = getPathPattern(allocator, pathStr);
    const regex: Regex = Regex.init(pathPattern) catch unreachable;
    defer regex.deinit();
    const pathIn = [_]u8{ '/', 'a', 'p', 'i', '/', 'h', 'e', 'l', 'l', 'o', '/', '1', '/', 'f', 'a', 'v', '/', '5', '0', '/' };
    const t = try regex.matches(std.heap.page_allocator, pathIn[0..19]);
    const f = try regex.matches(std.heap.page_allocator, pathIn[0..]);
    try expect(t);
    try expect(!f);
}

test "test" {
    const path = "/api/hello/{id}/fav/{favId}/{i}";
    const paramType = struct { id: i64, favId: i64, i: i64 };

    const param = getRouteParams(paramType, path, "/api/hello/12/fav/5/1");

    try expect(param.id == 12);
    try expect(param.favId == 5);
    try expect(param.i == 1);
}

fn testApiFn(r: zap.Request, c: *Context) void {
    _ = r;
    _ = c;
}

// test "check"
