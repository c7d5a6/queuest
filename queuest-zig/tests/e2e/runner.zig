const std = @import("std");
const Allocator = std.mem.Allocator;

/// The previous Zap listener stub never compiled (undefined handlers, 0.15 HTTP).
/// Skip until a real e2e server is wired up on 0.16.
pub fn runTests(allocator: Allocator) !void {
    _ = allocator;
    return error.SkipZigTest;
}
