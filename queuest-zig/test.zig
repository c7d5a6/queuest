const std = @import("std");

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
        const value = std.fmt.parseInt(i64, paramValue, 10) catch unreachable;
        @field(result, paramName) = value;
        start = end;
        valueStart = valueEnd - 1;
    }

    return result;
}

const expect = std.testing.expect;

test "test" {
    const path = "/api/hello/{id}/fav/{favId}/{i}";
    const paramType = struct { id: i64, favId: i64, i: i64 };

    const param = getRouteParams(paramType, path, "/api/hello/12/fav/5/1");

    try expect(param.id == 12);
    try expect(param.favId == 5);
    try expect(param.i == 1);
}
