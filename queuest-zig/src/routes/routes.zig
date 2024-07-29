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

pub fn StructTag(comptime T: type) type {
    switch (@typeInfo(T)) {
        .Struct => |st| {
            var enum_fields: [st.fields.len]std.builtin.Type.EnumField = undefined;
            inline for (st.fields, 0..) |field, index| {
                enum_fields[index] = .{
                    .name = field.name,
                    .value = index,
                };
            }
            return @Type(.{
                .Enum = .{
                    .tag_type = u16,
                    .fields = &enum_fields,
                    .decls = &.{},
                    .is_exhaustive = true,
                },
            });
        },
        else => @compileError("Not a struct"),
    }
}

pub fn setField(ptr: anytype, tag: StructTag(@TypeOf(ptr.*)), value: anytype) void {
    const T = @TypeOf(value);
    const st = @typeInfo(@TypeOf(ptr.*)).Struct;
    inline for (st.fields, 0..) |field, index| {
        if (tag == @as(@TypeOf(tag), @enumFromInt(index))) {
            if (field.type == T) {
                @field(ptr.*, field.name) = value;
            } else {
                @panic("Type mismatch: " ++ @typeName(field.type) ++ " != " ++ @typeName(T));
            }
        }
    }
}

fn getRouteParams(T: type, path: Path, url: []const u8) T {
    const params_type_info = @typeInfo(T);
    if (params_type_info != .Struct) {
        @compileError("expected tuple or struct argument, found " ++ @typeName(T));
    }
    const tag: StructTag(T) = i64;
    var result: T = undefined;
    var start: usize = 0;
    var valueStart: usize = 0;
    var i: usize = 0;
    while (std.mem.indexOfScalarPos(u8, path.path[0..], start, '{')) |pos| {
        valueStart = valueStart + pos - start;
        const end = std.mem.indexOfScalarPos(u8, path.path[0..], pos, '}') orelse unreachable;
        const valueEnd = std.mem.indexOfScalarPos(u8, url[0..], valueStart, '/') orelse url.len;
        const paramName = path.path[pos + 1 .. end];
        _ = paramName;
        const paramValue = url[valueStart..valueEnd];
        const value = std.fmt.parseInt(i64, paramValue, 10);
        setField(&result, tag, value);
        i = i + 1;
        start = end;
        valueStart = valueEnd - 1;
    }

    return result;
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

test "getting path params" {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};
    const allocator = gpa.allocator();
    const pathStr = "/api/hello/{id}/fav/{favId}/{i}";
    const path = createPath(allocator, pathStr, testApiFn);
    defer path.regex.deinit();

    const param = getRouteParams(struct { i64, i64, i64 }, path, "/api/hello/12/fav/5/1");

    try expect(param[0] == 12);
}

fn testApiFn(r: zap.Request, c: *Context) void {
    _ = r;
    _ = c;
}

// test "check"
