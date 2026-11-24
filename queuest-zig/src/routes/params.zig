const std = @import("std");

pub const ParamError = error{ MissingParam, BadRequest };

/// Parse a raw path capture (`ctx.param("id")`) into `T`.
/// Supports integers, `bool` ("true"/"false"), enums and `[]const u8`.
/// Bad input is an error (-> 400), never a crash.
pub fn parseAs(comptime T: type, raw: ?[]const u8) ParamError!T {
    const text = raw orelse return error.MissingParam;
    return switch (@typeInfo(T)) {
        .int => std.fmt.parseInt(T, text, 10) catch error.BadRequest,
        .bool => if (std.mem.eql(u8, text, "true"))
            true
        else if (std.mem.eql(u8, text, "false"))
            false
        else
            error.BadRequest,
        .@"enum" => std.meta.stringToEnum(T, text) orelse error.BadRequest,
        .pointer => if (T == []const u8) text else @compileError("unsupported param type " ++ @typeName(T)),
        else => @compileError("unsupported param type " ++ @typeName(T)),
    };
}

/// `paramAs(i64, ctx, "id")` for any Baz context.
pub fn paramAs(comptime T: type, ctx: anytype, name: []const u8) ParamError!T {
    return parseAs(T, ctx.param(name));
}

test "parse ints, bools, enums, strings" {
    try std.testing.expectEqual(@as(i64, 12), try parseAs(i64, "12"));
    try std.testing.expectEqual(@as(i64, -5), try parseAs(i64, "-5"));
    try std.testing.expectEqual(true, try parseAs(bool, "true"));
    try std.testing.expectEqual(false, try parseAs(bool, "false"));
    const Kind = enum { a, b };
    try std.testing.expectEqual(Kind.b, try parseAs(Kind, "b"));
    try std.testing.expectEqualStrings("x", try parseAs([]const u8, "x"));
}

test "bad or missing input is an error" {
    try std.testing.expectError(error.BadRequest, parseAs(i64, "fav"));
    try std.testing.expectError(error.BadRequest, parseAs(bool, "yes"));
    try std.testing.expectError(error.BadRequest, parseAs(u8, "300"));
    try std.testing.expectError(error.MissingParam, parseAs(i64, null));
}
