const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Baz panics on ReleaseFast/ReleaseSmall to keep its invariants checked, so it
    // always builds at most ReleaseSafe; the rest of the app follows `-Doptimize`.
    const baz_optimize: std.lang.Optimize = switch (optimize) {
        .debug => .debug,
        .safe, .fast, .small => .safe,
    };
    const baz = b.dependency("baz", .{ .target = target, .optimize = baz_optimize });
    const sqlite = b.dependency("sqlite", .{ .target = target, .optimize = optimize });

    // Library half: data layer without HTTP, shared with the sqlite tests.
    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .imports = &.{
            .{ .name = "sqlite", .module = sqlite.module("sqlite") },
        },
    });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .imports = &.{
            .{ .name = "baz", .module = baz.module("baz") },
            .{ .name = "sqlite", .module = sqlite.module("sqlite") },
        },
    });
    const exe = b.addExecutable(.{
        .name = "queuest-zig",
        .root_module = exe_mod,
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.addPassthruArgs();
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const test_step = b.step("test", "Run unit and sqlite tests");

    const unit_tests = b.addTest(.{ .root_module = exe_mod });
    test_step.dependOn(&b.addRunArtifact(unit_tests).step);

    const sqlite_tests_mod = b.createModule(.{
        .root_source_file = b.path("tests/sqlite/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .imports = &.{
            .{ .name = "queuest", .module = lib_mod },
            .{ .name = "sqlite", .module = sqlite.module("sqlite") },
        },
    });
    const sqlite_tests = b.addTest(.{ .root_module = sqlite_tests_mod });
    const run_sqlite_tests = b.addRunArtifact(sqlite_tests);
    const sqlite_test_step = b.step("test-sqlite", "Run SQLite integration tests");
    sqlite_test_step.dependOn(&run_sqlite_tests.step);
    test_step.dependOn(&run_sqlite_tests.step);

    const fmt_step = b.step("fmt", "Check formatting with zig fmt");
    fmt_step.dependOn(&b.addFmt(.{
        .paths = &.{ b.path("src"), b.path("tests"), b.path("build.zig") },
        .check = true,
    }).step);
}
