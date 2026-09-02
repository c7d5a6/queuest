const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{
        .default_target = .{},
    });
    const optimize = b.standardOptimizeOption(.{});

    const exe_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const exe = b.addExecutable(.{
        .name = "queuest-zig",
        .root_module = exe_module,
    });

    const regez_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    regez_module.addIncludePath(b.path("c-src"));
    regez_module.addCSourceFiles(.{
        .files = &.{"c-src/regez.c"},
    });
    const libC = b.addLibrary(.{
        .name = "regez",
        .root_module = regez_module,
        .linkage = .static,
    });
    const zap = b.dependency("zap", .{
        .target = target,
        .optimize = optimize,
    });
    const pg_module = b.dependency("pg", .{
        .target = target,
        .optimize = optimize,
        .openssl_lib_name = @as([]const u8, "ssl"),
    }).module("pg");
    const sqlite_dep = b.dependency("sqlite", .{
        .target = target,
        .optimize = optimize,
    });
    const sqlite_mod = sqlite_dep.module("sqlite");
    sqlite_mod.resolved_target = target;
    const zap_mod = zap.module("zap");
    const zap_art = zap.artifact("facil.io");
    configureArtifact(b, exe, libC, zap_mod, zap_art, sqlite_mod);
    b.installArtifact(exe);

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    lib_mod.addImport("sqlite", sqlite_mod);

    const pg_lib_mod = b.createModule(.{
        .root_source_file = b.path("src/pg_lib.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    pg_lib_mod.addImport("pg", pg_module);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const exe_unit_tests = b.addTest(.{
        .root_module = exe_tests_module,
    });
    configureArtifact(b, exe_unit_tests, libC, zap_mod, zap_art, sqlite_mod);
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);

    const sqlite_tests_module = b.createModule(.{
        .root_source_file = b.path("tests/sqlite/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    sqlite_tests_module.addImport("queuest", lib_mod);
    sqlite_tests_module.addImport("sqlite", sqlite_mod);
    const sqlite_tests = b.addTest(.{
        .root_module = sqlite_tests_module,
    });
    const run_sqlite_tests = b.addRunArtifact(sqlite_tests);
    const sqlite_test_step = b.step("test-sqlite", "Run SQLite integration tests");
    sqlite_test_step.dependOn(&run_sqlite_tests.step);
    test_step.dependOn(&run_sqlite_tests.step);

    const e2e_tests_module = b.createModule(.{
        .root_source_file = b.path("tests/e2e/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const e2e_tests = b.addTest(.{
        .root_module = e2e_tests_module,
    });
    configureArtifact(b, e2e_tests, libC, zap_mod, zap_art, sqlite_mod);
    const run_e2e_tests = b.addRunArtifact(e2e_tests);
    const e2e_test_step = b.step("e2e", "Run end-to-end tests");
    e2e_test_step.dependOn(&run_e2e_tests.step);

    const parity_tests_module = b.createModule(.{
        .root_source_file = b.path("tests/parity/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    parity_tests_module.addImport("queuest", lib_mod);
    parity_tests_module.addImport("pg_data", pg_lib_mod);
    parity_tests_module.addImport("pg", pg_module);
    parity_tests_module.addImport("sqlite", sqlite_mod);
    const parity_tests = b.addTest(.{
        .root_module = parity_tests_module,
    });
    linkOpenssl(parity_tests);
    const run_parity_tests = b.addRunArtifact(parity_tests);
    const parity_step = b.step("test-parity", "Compare SQLite and PostgreSQL repo results");
    parity_step.dependOn(&run_parity_tests.step);

    const converter_module = b.createModule(.{
        .root_source_file = b.path("tools/pg_to_sqlite.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    converter_module.addImport("queuest", lib_mod);
    converter_module.addImport("pg", pg_module);
    converter_module.addImport("sqlite", sqlite_mod);
    const converter = b.addExecutable(.{
        .name = "pg-to-sqlite",
        .root_module = converter_module,
    });
    linkOpenssl(converter);
    const install_converter = b.addInstallArtifact(converter, .{});
    const converter_step = b.step("pg-to-sqlite", "Build the PostgreSQL to SQLite converter");
    converter_step.dependOn(&install_converter.step);
    const run_converter = b.addRunArtifact(converter);
    run_converter.step.dependOn(&install_converter.step);
    if (b.args) |args| {
        run_converter.addArgs(args);
    }
    const run_converter_step = b.step("run-pg-to-sqlite", "Run the PostgreSQL to SQLite converter");
    run_converter_step.dependOn(&run_converter.step);

    const debug_module = b.createModule(.{
        .root_source_file = b.path("src/type-check.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const exe_debug_step = b.addExecutable(.{
        .name = "queuest-zig-debug-info",
        .root_module = debug_module,
    });
    configureArtifact(b, exe_debug_step, libC, zap_mod, zap_art, sqlite_mod);

    const run_exe_debug_step = b.addRunArtifact(exe_debug_step);
    const debug_step = b.step("debug", "Run debug info");
    debug_step.dependOn(&run_exe_debug_step.step);
}

fn linkOpenssl(artifact: *std.Build.Step.Compile) void {
    artifact.root_module.addLibraryPath(.{ .cwd_relative = "/usr/lib/x86_64-linux-gnu" });
    artifact.root_module.linkSystemLibrary("ssl", .{});
    artifact.root_module.linkSystemLibrary("crypto", .{});
}

fn configureArtifact(
    b: *std.Build,
    artifact: *std.Build.Step.Compile,
    libC: *std.Build.Step.Compile,
    zap_module: *std.Build.Module,
    zap_facil: *std.Build.Step.Compile,
    sqlite_module: *std.Build.Module,
) void {
    artifact.root_module.linkLibrary(libC);
    artifact.root_module.addIncludePath(b.path("c-src"));
    artifact.root_module.link_libc = true;
    artifact.root_module.addImport("zap", zap_module);
    artifact.root_module.linkLibrary(zap_facil);
    artifact.root_module.addImport("sqlite", sqlite_module);
}
