const std = @import("std");
const pg = @import("pg");
const Result = pg.Result;
const Allocator = std.mem.Allocator;

const DBError = error{
    NonSigleResult,
};

pub const Id = struct {
    id: i64,
};

fn typeHasTextSlice(comptime T: type) bool {
    inline for (std.meta.fields(T)) |field| {
        switch (field.type) {
            []const u8, []u8, [:0]const u8, [:0]u8 => return true,
            else => {},
        }
    }
    return false;
}

pub fn getSoloEntity(T: type, allocator: ?Allocator, result: *Result) !?T {
    comptime std.debug.assert(@typeInfo(T) == .@"struct");
    if (comptime typeHasTextSlice(T)) {
        std.debug.assert(allocator != null);
    }

    var e: ?T = null;
    if (try result.next()) |row| {
        e = try row.to(T, .{ .map = .name, .allocator = allocator });
    }
    if (try result.next()) |_| {
        return error.NonSigleResult;
    }
    return e;
}

pub fn getList(T: type, allocator: Allocator, result: *Result) !std.ArrayList(T) {
    comptime std.debug.assert(@typeInfo(T) == .@"struct");
    // Text columns are copied into `allocator` so they outlive Result.deinit.

    var array = try std.ArrayList(T).initCapacity(allocator, 0);

    while (try result.next()) |row| {
        const e = try row.to(T, .{ .map = .name, .allocator = allocator });
        try array.append(allocator, e);
    }

    return array;
}

test "typeHasTextSlice distinguishes text structs" {
    try std.testing.expect(typeHasTextSlice(struct { name: []const u8 }));
    try std.testing.expect(!typeHasTextSlice(Id));
}
