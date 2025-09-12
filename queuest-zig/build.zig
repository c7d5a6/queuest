const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{
        .default_target = .{
            // .cpu_arch = .x86_64,
            // .os_tag = .linux,
            // .abi = .gnu,
            // .glibc_version = .{ .major = 2, .minor = 28, .patch = 0 },
        },
    });
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "queuest-zig",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const libC = b.addStaticLibrary(.{
        .name = "regez",
        .optimize = optimize,
        .target = target,
    });
    libC.addIncludePath(b.path("c-src"));
    libC.addCSourceFiles(.{
        .files = &.{"c-src/regez.c"},
    });
    libC.linkLibC();
    const zap = b.dependency("zap", .{
        .target = target,
        .optimize = optimize,
    });
    const pg_module = b.dependency("pg", .{
        .target = target,
        .optimize = optimize,
        .openssl_lib_name = @as([]const u8, "ssl"), // usually enough
        // .openssl_lib_path = std.Build.LazyPath{.cwd_relative = "/usr/lib"},   // only if non-standard
        // .openssl_include_path = std.Build.LazyPath{.cwd_relative = "/usr/include"}, // only if non-standard
    }).module("pg");
    // const sqlite = b.dependency("sqlite", .{
    //     .target = target,
    //     .optimize = optimize,
    // });
    const zap_mod = zap.module("zap");
    const zap_art = zap.artifact("facil.io");
    // const sqlite_mod = sqlite.module("sqlite");
    configureArtifact(b, exe, libC, zap_mod, zap_art, pg_module);
    exe.linkSystemLibrary("glib-2.0");
    exe.linkSystemLibrary("ssl");
    exe.linkSystemLibrary("crypto");
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
    configureArtifact(b, exe_unit_tests, libC, zap_mod, zap_art, pg_module);
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);

    // Run e2e tests
    const e2e_tests = b.addTest(.{
        .root_source_file = b.path("tests/e2e/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    configureArtifact(b, e2e_tests, libC, zap_mod, zap_art, pg_module);
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
    configureArtifact(b, exe_debug_step, libC, zap_mod, zap_art, pg_module);

    const run_exe_debug_step = b.addRunArtifact(exe_debug_step);
    const debug_step = b.step("debug", "Run debug info");
    debug_step.dependOn(&run_exe_debug_step.step);
}

fn configureArtifact(
    b: *std.Build,
    artifact: *std.Build.Step.Compile,
    libC: *std.Build.Step.Compile,
    zap_module: *std.Build.Module,
    zap_facil: *std.Build.Step.Compile,
    pg_module: *std.Build.Module,
) void {
    artifact.linkLibrary(libC);
    artifact.addIncludePath(b.path("c-src"));
    artifact.linkLibC();
    artifact.root_module.addImport("zap", zap_module);
    artifact.linkLibrary(zap_facil);
    artifact.root_module.addImport("pg", pg_module);
    // artifact.root_module.addImport("sqlite", sqlite_module);
}
