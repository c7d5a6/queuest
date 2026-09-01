const std = @import("std");
const sqlite = @import("sqlite");
const queuest = @import("queuest");

const seed_sql = queuest.seed_sql;

pub fn withCopiedDb(func: *const fn (*sqlite.Db) anyerror!void) !void {
    const allocator = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    var path_buf: [std.fs.max_path_bytes]u8 = undefined;
    const dir_path = try tmp.dir.realpath(".", &path_buf);

    const golden_path = try std.fs.path.joinZ(allocator, &.{ dir_path, "golden.db" });
    defer allocator.free(golden_path);
    const work_path = try std.fs.path.joinZ(allocator, &.{ dir_path, "work.db" });
    defer allocator.free(work_path);

    {
        var golden = try queuest.open.openFile(golden_path);
        errdefer golden.deinit();
        try queuest.migrate.run(&golden);
        try queuest.migrate.execScript(&golden, seed_sql);
        try queuest.open.checkpoint(&golden);
        golden.deinit();
    }

    try tmp.dir.copyFile("golden.db", tmp.dir, "work.db", .{});

    var db = try queuest.open.openFile(work_path);
    defer {
        db.deinit();
        deleteCopy(tmp.dir, "work.db");
    }

    try func(&db);
}

fn deleteCopy(dir: std.fs.Dir, name: []const u8) void {
    std.debug.assert(name.len > 0);
    dir.deleteFile(name) catch {};

    var wal_buf: [std.fs.max_path_bytes]u8 = undefined;
    const wal = std.fmt.bufPrint(&wal_buf, "{s}-wal", .{name}) catch return;
    dir.deleteFile(wal) catch {};

    var shm_buf: [std.fs.max_path_bytes]u8 = undefined;
    const shm = std.fmt.bufPrint(&shm_buf, "{s}-shm", .{name}) catch return;
    dir.deleteFile(shm) catch {};
}
