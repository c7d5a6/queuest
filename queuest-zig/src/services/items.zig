const std = @import("std");
const Allocator = std.mem.Allocator;
const zap = @import("zap");
const Request = zap.Request;
const Context = @import("../middle/context.zig").Context;
const Item = @import("../data/item.zig").CollectionItem;
const Collection = @import("../data/collection.zig").Collection;
const ControllerError = @import("../routes/router-errors.zig").ControllerError;

pub fn on_get_items(a: Allocator, r: Request, c: *Context, params: anytype) ControllerError!void {
    const collectionId = params.collectionId;
    _ = Collection.findByIdAndUserId(c.connection.?, collectionId, c.user.?.id) catch unreachable orelse unreachable;
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

pub fn on_post_item(a: Allocator, r: Request, c: *Context, params: anytype) ControllerError!void {
    r.parseBody() catch return error.InternalError;
    const body = r.body orelse return error.InternalError;

    const collectionId = params.collectionId;
    _ = Collection.findByIdAndUserId(c.connection.?, collectionId, c.user.?.id) catch unreachable orelse unreachable;

    const CreateItem = struct { name: []const u8 };
    const create = std.json.parseFromSlice(CreateItem, a, body, .{ .ignore_unknown_fields = true }) catch return error.InternalError;
    const id = Item.insertItem(c.connection.?, create.value.name, collectionId) catch unreachable;

    const json = std.json.stringifyAlloc(a, id, .{ .escape_unicode = true, .emit_null_optional_fields = false }) catch unreachable;
    r.setContentType(.JSON) catch return;
    r.sendJson(json) catch return;
}

pub fn on_delete_item(a: Allocator, r: Request, c: *Context, params: anytype) ControllerError!void {
    _ = a;

    const collectionId = params.collectionId;
    const collectionItemId = params.collectionItemId;
    _ = Collection.findByIdAndUserId(c.connection.?, collectionId, c.user.?.id) catch unreachable orelse unreachable;

    Item.deleteItem(c.connection.?, collectionItemId) catch unreachable;

    r.sendBody("") catch return;
}
