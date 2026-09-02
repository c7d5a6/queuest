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
    return collectAll(T, &stmt, allocator, values);
}

/// zig-sqlite's `Statement.all` still initializes ArrayList with `.{}`, which
/// is invalid in Zig 0.16. Iterate ourselves until upstream uses `.empty`.
pub fn collectAll(
    comptime T: type,
    stmt: anytype,
    allocator: Allocator,
    values: anytype,
) !std.ArrayList(T) {
    var iter = try stmt.iteratorAlloc(T, allocator, values);
    var array: std.ArrayList(T) = .empty;
    errdefer array.deinit(allocator);
    while (try iter.nextAlloc(allocator, .{})) |row| {
        try array.append(allocator, row);
    }
    return array;
}
