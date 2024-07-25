const pg = @import("pg");
const Result = pg.Result;

const DBError = error{
    NonSigleResult,
};

pub fn getSoloEntity(T: type, result: *Result) !?T {
    var e: ?T = null;

    if (try result.next()) |row| {
        e = try row.to(T, .{ .map = .name });
    }
    if (try result.next()) |_| {
        return error.NonSigleResult;
    }
    return e;
}
