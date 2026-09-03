const std = @import("std");
const builtin = @import("builtin");

/// Local Angular CORS and other local-only behavior.
///
/// `DEV=1` / `true` / `on` enables it. `DEV=0` / `false` / `off` disables it.
/// Unset follows the build: on in Debug, off in Release*.
pub fn enabled(environ: *const std.process.Environ.Map) bool {
    const v = environ.get("DEV") orelse return builtin.mode == .Debug;
    if (v.len == 0) return builtin.mode == .Debug;
    if (isOn(v)) return true;
    if (isOff(v)) return false;
    std.log.err("DEV must be 1/true/on or 0/false/off, got {s}", .{v});
    std.process.exit(1);
}

fn isOn(v: []const u8) bool {
    return std.mem.eql(u8, v, "1") or std.mem.eql(u8, v, "true") or std.mem.eql(u8, v, "on");
}

fn isOff(v: []const u8) bool {
    return std.mem.eql(u8, v, "0") or std.mem.eql(u8, v, "false") or std.mem.eql(u8, v, "off");
}

test "DEV unset follows build mode" {
    var map = std.process.Environ.Map.init(std.testing.allocator);
    defer map.deinit();
    try std.testing.expectEqual(builtin.mode == .Debug, enabled(&map));
}

test "DEV 1 and 0 override build mode" {
    var map = std.process.Environ.Map.init(std.testing.allocator);
    defer map.deinit();
    try map.put("DEV", "1");
    try std.testing.expect(enabled(&map));
    try map.put("DEV", "0");
    try std.testing.expect(!enabled(&map));
}
