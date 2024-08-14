const std = @import("std");
const Allocator = std.mem.Allocator;
const zap = @import("zap");
const Request = zap.Request;
const Context = @import("../middle/context.zig").Context;
const Item = @import("../data/item.zig").CollectionItem;
const ControllerError = @import("../routes/router-errors.zig").ControllerError;

pub fn on_get_items(a: Allocator, r: Request, c: *Context, params: anytype) ControllerError!void {
    const collectionId = params.collectionId;
    const items: std.ArrayList(Item) = Item.findAllForCollectionId(c.connection.?, a, collectionId) catch unreachable;
    const It = struct { id: i64, name: []const u8 };
    var result = std.ArrayList(It).initCapacity(a, items.items.len) catch unreachable;
    for (items.items) |item| {
        const name = switch (item.inner) {
            .collection => |cl| cl.name,
            .item => |it| it.name,
        };
        result.append(It{ .id = item.id, .name = name }) catch unreachable;
    }
    const Result = struct { id: i64, items: []It, calibrated: f64 };
    const res = Result{ .id = collectionId, .items = result.items, .calibrated = 0.5 };
    const json = std.json.stringifyAlloc(a, res, .{ .escape_unicode = true, .emit_null_optional_fields = false }) catch unreachable;
    r.setContentType(.JSON) catch return;
    r.sendJson(json) catch return;
}
