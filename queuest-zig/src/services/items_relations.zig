const std = @import("std");
const Allocator = std.mem.Allocator;
const zap = @import("zap");
const Request = zap.Request;
const Context = @import("../middle/context.zig").Context;
const Item = @import("../data/item.zig").CollectionItem;
const Collection = @import("../data/collection.zig").Collection;
const ItemRelation = @import("../data/item_relations.zig").ItemRelation;
const ControllerError = @import("../routes/router-errors.zig").ControllerError;

pub fn on_post_relation(a: Allocator, r: Request, c: *Context, params: anytype) ControllerError!void {
    const fromId = params.fromId;
    const toId = params.toId;

    try assertItemsAccess(c, fromId, toId);

    const id = ItemRelation.insertItemRelation(c.connection.?, fromId, toId) catch unreachable;

    const json = std.json.stringifyAlloc(a, id, .{ .escape_unicode = true, .emit_null_optional_fields = false }) catch unreachable;
    r.setContentType(.JSON) catch return;
    r.sendJson(json) catch return;
}

pub fn on_delete_relation(a: Allocator, r: Request, c: *Context, params: anytype) ControllerError!void {
    _ = a;
    const itemAId = params.itemAId;
    const itemBId = params.itemBId;

    try assertItemsAccess(c, itemAId, itemBId);

    ItemRelation.deleteItemRelation(c.connection.?, itemAId, itemBId) catch unreachable;

    r.sendBody("") catch return;
}

fn assertItemsAccess(c: *Context, fromId: i64, toId: i64) ControllerError!void {
    const fromItem = Item.findById(c.connection.?, fromId) catch unreachable orelse unreachable;
    const toItem = Item.findById(c.connection.?, toId) catch unreachable orelse unreachable;
    if (fromItem.collection_id != toItem.collection_id) {
        return ControllerError.BadRequest;
    }
    const collection = Collection.findByIdAndUserId(c.connection.?, fromItem.collection_id, c.user.?.id) catch unreachable;
    if (collection == null) {
        return ControllerError.BadRequest;
    }
}
