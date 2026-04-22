pub const packages = struct {
    pub const @"N-V-__8AAAOLAACqscul40pNN-WUdWQuGSCOYnyXgKXRxOqz" = struct {
        pub const build_root = "/home/nkukovenko/.cache/zig/p/N-V-__8AAAOLAACqscul40pNN-WUdWQuGSCOYnyXgKXRxOqz";
        pub const build_zig = @import("N-V-__8AAAOLAACqscul40pNN-WUdWQuGSCOYnyXgKXRxOqz");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"N-V-__8AACpFpwCXJZXXDaM9adUZOSdCSCy5dik1zsuZkk4x" = struct {
        pub const build_root = "/home/nkukovenko/.cache/zig/p/N-V-__8AACpFpwCXJZXXDaM9adUZOSdCSCy5dik1zsuZkk4x";
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"N-V-__8AAHOzAQBh8wB371GN1DXTl1mKs8Rdqj0sJea0U4P7" = struct {
        pub const build_root = "/home/nkukovenko/.cache/zig/p/N-V-__8AAHOzAQBh8wB371GN1DXTl1mKs8Rdqj0sJea0U4P7";
        pub const build_zig = @import("N-V-__8AAHOzAQBh8wB371GN1DXTl1mKs8Rdqj0sJea0U4P7");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"pg-0.0.0-Wp_7gRD-BQCbDvJEahLsdoxUdlR7BsmvPnQyYdGyQzEE" = struct {
        pub const build_root = "/home/nkukovenko/.cache/zig/p/pg-0.0.0-Wp_7gRD-BQCbDvJEahLsdoxUdlR7BsmvPnQyYdGyQzEE";
        pub const build_zig = @import("pg-0.0.0-Wp_7gRD-BQCbDvJEahLsdoxUdlR7BsmvPnQyYdGyQzEE");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "buffer", "N-V-__8AAAOLAACqscul40pNN-WUdWQuGSCOYnyXgKXRxOqz" },
            .{ "metrics", "N-V-__8AAHOzAQBh8wB371GN1DXTl1mKs8Rdqj0sJea0U4P7" },
        };
    };
    pub const @"sqlite-3.48.0-F2R_a_uGDgCfOH5UEJYjuOCe-HixnLjToxOdEGAEM3xk" = struct {
        pub const build_root = "/home/nkukovenko/.cache/zig/p/sqlite-3.48.0-F2R_a_uGDgCfOH5UEJYjuOCe-HixnLjToxOdEGAEM3xk";
        pub const build_zig = @import("sqlite-3.48.0-F2R_a_uGDgCfOH5UEJYjuOCe-HixnLjToxOdEGAEM3xk");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "sqlite", "N-V-__8AACpFpwCXJZXXDaM9adUZOSdCSCy5dik1zsuZkk4x" },
        };
    };
    pub const @"zap-0.9.1-GoeB84M8JACjZKDNq2LA5hB24Z-ZrZ_HUKRXd8qxL2JW" = struct {
        pub const build_root = "/home/nkukovenko/.cache/zig/p/zap-0.9.1-GoeB84M8JACjZKDNq2LA5hB24Z-ZrZ_HUKRXd8qxL2JW";
        pub const build_zig = @import("zap-0.9.1-GoeB84M8JACjZKDNq2LA5hB24Z-ZrZ_HUKRXd8qxL2JW");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
        };
    };
};

pub const root_deps: []const struct { []const u8, []const u8 } = &.{
    .{ "zap", "zap-0.9.1-GoeB84M8JACjZKDNq2LA5hB24Z-ZrZ_HUKRXd8qxL2JW" },
    .{ "pg", "pg-0.0.0-Wp_7gRD-BQCbDvJEahLsdoxUdlR7BsmvPnQyYdGyQzEE" },
    .{ "sqlite", "sqlite-3.48.0-F2R_a_uGDgCfOH5UEJYjuOCe-HixnLjToxOdEGAEM3xk" },
};
