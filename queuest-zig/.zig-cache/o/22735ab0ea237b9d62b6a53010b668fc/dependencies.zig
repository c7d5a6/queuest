pub const packages = struct {
    pub const @"N-V-__8AAEGLAAB4JS8S1rWwdvXUTwnt7gRNthhJanWx4AvP" = struct {
        pub const build_root = "/home/nkukovenko/.cache/zig/p/N-V-__8AAEGLAAB4JS8S1rWwdvXUTwnt7gRNthhJanWx4AvP";
        pub const build_zig = @import("N-V-__8AAEGLAAB4JS8S1rWwdvXUTwnt7gRNthhJanWx4AvP");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"N-V-__8AAH-mpwB7g3MnqYU-ooUBF1t99RP27dZ9addtMVXD" = struct {
        pub const build_root = "/home/nkukovenko/.cache/zig/p/N-V-__8AAH-mpwB7g3MnqYU-ooUBF1t99RP27dZ9addtMVXD";
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"metrics-0.0.0-W7G4eP2_AQBKsaql3dhLJ-pkf-RdP-zV3vflJy4N34jC" = struct {
        pub const build_root = "/home/nkukovenko/.cache/zig/p/metrics-0.0.0-W7G4eP2_AQBKsaql3dhLJ-pkf-RdP-zV3vflJy4N34jC";
        pub const build_zig = @import("metrics-0.0.0-W7G4eP2_AQBKsaql3dhLJ-pkf-RdP-zV3vflJy4N34jC");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
        };
    };
    pub const @"pg-0.0.0-Wp_7gV1pBgAN_atgbzpICLXPcJ0gJJxVfFmuaprjCUew" = struct {
        pub const build_root = "/home/nkukovenko/.cache/zig/p/pg-0.0.0-Wp_7gV1pBgAN_atgbzpICLXPcJ0gJJxVfFmuaprjCUew";
        pub const build_zig = @import("pg-0.0.0-Wp_7gV1pBgAN_atgbzpICLXPcJ0gJJxVfFmuaprjCUew");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "buffer", "N-V-__8AAEGLAAB4JS8S1rWwdvXUTwnt7gRNthhJanWx4AvP" },
            .{ "metrics", "metrics-0.0.0-W7G4eP2_AQBKsaql3dhLJ-pkf-RdP-zV3vflJy4N34jC" },
        };
    };
    pub const @"sqlite-3.48.0-F2R_a8WODgDamFQx1fOrpgY7IdluD4Sr_P7G0UPxUUMr" = struct {
        pub const build_root = "/home/nkukovenko/.cache/zig/p/sqlite-3.48.0-F2R_a8WODgDamFQx1fOrpgY7IdluD4Sr_P7G0UPxUUMr";
        pub const build_zig = @import("sqlite-3.48.0-F2R_a8WODgDamFQx1fOrpgY7IdluD4Sr_P7G0UPxUUMr");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "sqlite", "N-V-__8AAH-mpwB7g3MnqYU-ooUBF1t99RP27dZ9addtMVXD" },
        };
    };
    pub const @"zap-0.10.6-GoeB8w-EJABTkxyoGH_Z8oMBYMxTBvn7YWk-DrJOHuDO" = struct {
        pub const build_root = "/home/nkukovenko/.cache/zig/p/zap-0.10.6-GoeB8w-EJABTkxyoGH_Z8oMBYMxTBvn7YWk-DrJOHuDO";
        pub const build_zig = @import("zap-0.10.6-GoeB8w-EJABTkxyoGH_Z8oMBYMxTBvn7YWk-DrJOHuDO");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
        };
    };
};

pub const root_deps: []const struct { []const u8, []const u8 } = &.{
    .{ "zap", "zap-0.10.6-GoeB8w-EJABTkxyoGH_Z8oMBYMxTBvn7YWk-DrJOHuDO" },
    .{ "pg", "pg-0.0.0-Wp_7gV1pBgAN_atgbzpICLXPcJ0gJJxVfFmuaprjCUew" },
    .{ "sqlite", "sqlite-3.48.0-F2R_a8WODgDamFQx1fOrpgY7IdluD4Sr_P7G0UPxUUMr" },
};
