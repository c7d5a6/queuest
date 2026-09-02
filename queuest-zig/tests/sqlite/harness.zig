const std = @import("std");
const sqlite = @import("sqlite");
const queuest = @import("queuest");

const seed_sql = queuest.seed_sql;

pub fn withCopiedDb(func: *const fn (*sqlite.Db) anyerror!void) !void {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    var path_buf: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const path_len = try tmp.dir.realPath(io, &path_buf);
    const dir_path = path_buf[0..path_len];

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

    try tmp.dir.copyFile("golden.db", tmp.dir, "work.db", io, .{});

    var db = try queuest.open.openFile(work_path);
    defer {
        db.deinit();
        deleteCopy(tmp.dir, io, "work.db");
    }

    try func(&db);
}

fn deleteCopy(dir: std.Io.Dir, io: std.Io, name: []const u8) void {
    std.debug.assert(name.len > 0);
    dir.deleteFile(io, name) catch {};

    var wal_buf: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const wal = std.fmt.bufPrint(&wal_buf, "{s}-wal", .{name}) catch return;
    dir.deleteFile(io, wal) catch {};

    var shm_buf: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const shm = std.fmt.bufPrint(&shm_buf, "{s}-shm", .{name}) catch return;
    dir.deleteFile(io, shm) catch {};
}
