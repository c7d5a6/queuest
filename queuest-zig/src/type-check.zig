const std = @import("std");
const routes = @import("./routes/routes.zig");
const coll = @import("./data/collection.zig").Collection;
const usr = @import("./data/user.zig").User;

const str = struct {
    // name: [2]u8,
    a1: u8,
    a2: u8,
    yn: bool,
    two: u2,
};

const strP = struct {
    // name: [2:0]u8,
    i: i64,
    u: un,
};

const un = union {
    i: i64,
    u: u64,
};

fn getTypesInfo(T: type, pdn: comptime_int) !void {
    if (pdn == 0)
        std.debug.print("\n", .{});
    std.debug.print(("\t" ** pdn) ++ "Type: {s}\n", .{@typeName(T)});
    std.debug.print(("\t" ** pdn) ++ "  bitSize: {d}\n", .{@bitSizeOf(T)});
    std.debug.print(("\t" ** pdn) ++ "  align: {d}\n", .{@alignOf(T) * 8});
    // try std.debug.print(("\t" ** pdn) ++ "  align: {d}\n", .{@bitOffsetOf(T)});
    const info = @typeInfo(T);
    if (info == .Struct) {
        const fileds = std.meta.fields(T);
        std.debug.print(("\t" ** pdn) ++ "  fields:\n", .{});
        inline for (fileds) |field| {
            std.debug.print(("\t" ** pdn) ++ "    {s}: {s}\n", .{ field.name, @typeName(field.type) });
            std.debug.print(("\t" ** pdn) ++ "      off {d} align {d}\n", .{ @bitOffsetOf(T, field.name), field.alignment * 8 });
        }
        std.debug.print("\n", .{});
        inline for (fileds) |field| {
            try getTypesInfo(field.type, pdn + 1);
        }
    }
}

fn printTypes() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // const allocator = gpa.allocator();
    // var list = try std.ArrayList(u8).initCapacity(allocator, 1024 * 20);
    // defer list.deinit();

    // try getTypesInfo([2]str, 0);
    // try getTypesInfo([2]strP, 0);
    try getTypesInfo(routes.Path, 0);
    try getTypesInfo(coll, 0);
    try getTypesInfo(usr, 0);
    try getTypesInfo(strP, 0);

    // std.debug.print("\nTypes:\n{s}\n", .{list.items});
}

pub fn main() !void {
    try printTypes();
}
