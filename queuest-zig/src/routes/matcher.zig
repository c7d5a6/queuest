const std = @import("std");
const regez = @cImport({
    @cInclude("regex.h");
    @cInclude("regez.h");
});

pub const Regex = struct {
    inner: *regez.regex_t,

    pub fn init(pattern: [:0]const u8) !Regex {
        const inner = regez.alloc_regex_t().?;
        if (0 != regez.regcomp(inner, pattern, regez.REG_NEWLINE | regez.REG_EXTENDED)) {
            return error.compile;
        }

        return .{
            .inner = inner,
        };
    }

    pub fn deinit(self: Regex) void {
        regez.free_regex_t(self.inner);
    }

    pub fn matches(self: Regex, allocator: std.mem.Allocator, input: []const u8) !bool {
        const a_input: []u8 = try allocator.alloc(u8, input.len + 1);
        @memcpy(a_input[0..input.len], input);
        a_input[input.len] = 0;
        const c_input: [:0]const u8 = a_input[0..input.len :0];
        const match_size = 1;
        var pmatch: [match_size]regez.regmatch_t = undefined;
        const res = regez.regexec(self.inner, c_input, match_size, &pmatch, 0);
        return 0 == res;
    }
};
const expect = std.testing.expect;

test "create and match path" {
    const pathStr = "/api/hello";
    const regex: Regex = Regex.init(pathStr) catch unreachable;
    defer regex.deinit();
    const pathIn: [10]u8 = .{ '/', 'a', 'p', 'i', '/', 'h', 'e', 'l', 'l', 'o' };
    const result = try regex.matches(std.heap.page_allocator, pathIn[0..]);
    try expect(result);
}
