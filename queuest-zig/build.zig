const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "queuest-zig",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const libC = b.addStaticLibrary(.{
        .name = "regez",
        .optimize = .Debug,
        .target = target,
    });
    libC.addIncludePath(b.path("c-src"));
    libC.addCSourceFiles(.{
        .files = &.{"c-src/regez.c"},
    });
    libC.linkLibC();
    exe.linkLibrary(libC);
    exe.addIncludePath(b.path("c-src"));
    exe.linkLibC();

    const zap = b.dependency("zap", .{
        .target = target,
        .optimize = optimize,
    });
    const pg = b.dependency("pg", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("zap", zap.module("zap"));
    exe.linkLibrary(zap.artifact("facil.io"));
    exe.root_module.addImport("pg", pg.module("pg"));

    b.installArtifact(exe);

    // Run the main executable
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Run unit tests
    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_unit_tests.linkLibrary(libC);
    exe_unit_tests.addIncludePath(b.path("c-src"));
    exe_unit_tests.linkLibC();
    exe_unit_tests.root_module.addImport("zap", zap.module("zap"));
    exe_unit_tests.linkLibrary(zap.artifact("facil.io"));
    exe_unit_tests.root_module.addImport("pg", pg.module("pg"));

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);

    // Run e2e tests
    const e2e_tests = b.addTest(.{
        .root_source_file = b.path("tests/e2e/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    e2e_tests.linkLibrary(libC);
    e2e_tests.addIncludePath(b.path("c-src"));
    e2e_tests.linkLibC();
    e2e_tests.root_module.addImport("zap", zap.module("zap"));
    e2e_tests.linkLibrary(zap.artifact("facil.io"));
    e2e_tests.root_module.addImport("pg", pg.module("pg"));

    const run_e2e_tests = b.addRunArtifact(e2e_tests);
    const e2e_test_step = b.step("e2e", "Run end-to-end tests");
    e2e_test_step.dependOn(&run_e2e_tests.step);

    // ---
    // --- Debug informations step
    const exe_debug_step = b.addExecutable(.{
        .name = "queuest-zig-debug-info",
        .root_source_file = b.path("src/type-check.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_debug_step.linkLibrary(libC);
    exe_debug_step.addIncludePath(b.path("c-src"));
    exe_debug_step.linkLibC();
    exe_debug_step.root_module.addImport("zap", zap.module("zap"));
    // exe_debug_step.linkLibrary(zap.artifact("facil.io"));
    exe_debug_step.root_module.addImport("pg", pg.module("pg"));

    const run_exe_debug_step = b.addRunArtifact(exe_debug_step);
    const debug_step = b.step("debug", "Run debug info");
    debug_step.dependOn(&run_exe_debug_step.step);
}
