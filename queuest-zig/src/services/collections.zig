const std = @import("std");
const Allocator = std.mem.Allocator;
const zap = @import("zap");
const Request = zap.Request;
const Context = @import("../middle/context.zig").Context;
const Collection = @import("../data/collection.zig").Collection;

pub fn on_get_collections(a: Allocator, r: Request, c: *Context, params: anytype) void {
    _ = params;
    const collections: std.ArrayList(Collection) = Collection.findAllForUserId(c.connection.?, a, c.user.?.id) catch unreachable;
    const json = std.json.stringifyAlloc(a, collections.items, .{ .escape_unicode = true, .emit_null_optional_fields = false }) catch unreachable;
    r.setContentType(.JSON) catch return;
    r.sendJson(json) catch return;
}

pub fn on_get_collection(a: Allocator, r: Request, c: *Context, params: anytype) void {
    const collectionId = params.collectionId;
    const collection: Collection = Collection.findByIdAndUserId(c.connection.?, collectionId, c.user.?.id) catch unreachable orelse unreachable;
    const json = std.json.stringifyAlloc(a, collection, .{ .escape_unicode = true, .emit_null_optional_fields = false }) catch unreachable;
    r.setContentType(.JSON) catch return;
    r.sendJson(json) catch return;
}
