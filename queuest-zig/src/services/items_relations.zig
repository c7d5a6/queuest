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

    try assertItemsAccess(a, c, fromId, toId);

    const id = ItemRelation.insertItemRelation(c.connection.?, fromId, toId) catch return error.InternalError;

    const json = std.json.Stringify.valueAlloc(a, id, .{
        .escape_unicode = true,
        .emit_null_optional_fields = false,
    }) catch return error.InternalError;
    r.setContentType(.JSON) catch return;
    r.sendJson(json) catch return;
}

pub fn on_delete_relation(a: Allocator, r: Request, c: *Context, params: anytype) ControllerError!void {
    const itemAId = params.itemAId;
    const itemBId = params.itemBId;

    try assertItemsAccess(a, c, itemAId, itemBId);

    ItemRelation.deleteItemRelation(c.connection.?, itemAId, itemBId) catch return error.InternalError;

    r.sendBody("") catch return;
}

fn assertItemsAccess(a: Allocator, c: *Context, fromId: i64, toId: i64) ControllerError!void {
    std.debug.assert(fromId != 0);
    std.debug.assert(toId != 0);
    const fromItem = Item.findCollectionIdById(c.connection.?, fromId) catch
        return error.InternalError orelse return error.NotFound;
    const toItem = Item.findCollectionIdById(c.connection.?, toId) catch
        return error.InternalError orelse return error.NotFound;
    if (fromItem != toItem) {
        return ControllerError.BadRequest;
    }
    const user = c.user orelse return error.InternalError;
    const collection = Collection.findByIdAndUserId(c.connection.?, a, fromItem, user.id) catch
        return error.InternalError;
    if (collection == null) {
        return ControllerError.BadRequest;
    }
}
