const std = @import("std");
const sqlite = @import("sqlite");
const Allocator = std.mem.Allocator;

pub const Id = struct {
    id: i64,
};

pub fn getSolo(
    comptime T: type,
    db: *sqlite.Db,
    allocator: Allocator,
    comptime query: []const u8,
    values: anytype,
) !?T {
    comptime std.debug.assert(@typeInfo(T) == .@"struct");
    std.debug.assert(@intFromPtr(db.db) != 0);
    return db.oneAlloc(T, allocator, query, .{}, values);
}

pub fn getSoloNoAlloc(
    comptime T: type,
    db: *sqlite.Db,
    comptime query: []const u8,
    values: anytype,
) !?T {
    comptime std.debug.assert(@typeInfo(T) == .@"struct");
    std.debug.assert(@intFromPtr(db.db) != 0);
    return db.one(T, query, .{}, values);
}

pub fn getList(
    comptime T: type,
    db: *sqlite.Db,
    allocator: Allocator,
    comptime query: []const u8,
    values: anytype,
) !std.ArrayList(T) {
    comptime std.debug.assert(@typeInfo(T) == .@"struct");
    std.debug.assert(@intFromPtr(db.db) != 0);

    var stmt = try db.prepare(query);
    defer stmt.deinit();
    const rows = try stmt.all(T, allocator, .{}, values);

    var array = try std.ArrayList(T).initCapacity(allocator, rows.len);
    try array.appendSlice(allocator, rows);
    allocator.free(rows);
    return array;
}
