const std = @import("std");
const testing = std.testing;
const runner = @import("runner.zig");

test "e2e tests" {
    try runner.runTests(std.testing.allocator);
}
