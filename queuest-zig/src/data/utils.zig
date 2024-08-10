const std = @import("std");
const pg = @import("pg");
const Result = pg.Result;

const DBError = error{
    NonSigleResult,
};

pub fn getSoloEntity(T: type, result: *Result) !?T {
    var e: ?T = null;

    if (try result.next()) |row| {
        e = try row.to(T, .{ .map = .name });
    }
    if (try result.next()) |_| {
        return error.NonSigleResult;
    }
    return e;
}

pub fn getList(T: type, allocator: std.mem.Allocator, result: *Result) !std.ArrayList(T) {
    var array = std.ArrayList(T).init(allocator);

    while (try result.next()) |row| {
        const e = try row.to(T, .{ .map = .name });
        try array.append(e);
    }

    return array;
}
