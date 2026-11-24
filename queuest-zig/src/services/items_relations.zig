const std = @import("std");
const Allocator = std.mem.Allocator;
const params = @import("../routes/params.zig");
const Context = @import("../middle/context.zig").Context;
const Locals = @import("../middle/context.zig").Locals;
const Item = @import("../data/item.zig").CollectionItem;
const Collection = @import("../data/collection.zig").Collection;
const ItemRelation = @import("../data/item_relations.zig").ItemRelation;
const ControllerError = @import("../routes/router-errors.zig").ControllerError;
const request = @import("../middle/context.zig");

pub fn onPostRelation(ctx: *Context) !void {
    const a = request.arena(ctx);
    const c = ctx.locals;
    const fromId = try params.paramAs(i64, ctx, "fromId");
    const toId = try params.paramAs(i64, ctx, "toId");

    try assertItemsAccess(a, c, fromId, toId);

    const id = ItemRelation.insertItemRelation(c.db.?, fromId, toId) catch
        return error.InternalError;

    try request.sendJson(ctx, id);
}

pub fn onDeleteRelation(ctx: *Context) !void {
    const a = request.arena(ctx);
    const c = ctx.locals;
    const itemAId = try params.paramAs(i64, ctx, "itemAId");
    const itemBId = try params.paramAs(i64, ctx, "itemBId");

    try assertItemsAccess(a, c, itemAId, itemBId);

    ItemRelation.deleteItemRelation(c.db.?, itemAId, itemBId) catch return error.InternalError;

    try ctx.response.text(200, "");
}

fn assertItemsAccess(a: Allocator, c: *Locals, fromId: i64, toId: i64) ControllerError!void {
    std.debug.assert(fromId != 0);
    std.debug.assert(toId != 0);
    const fromItem = (Item.findCollectionIdById(c.db.?, fromId) catch
        return error.InternalError) orelse return error.NotFound;
    const toItem = (Item.findCollectionIdById(c.db.?, toId) catch
        return error.InternalError) orelse return error.NotFound;
    if (fromItem != toItem) {
        return ControllerError.BadRequest;
    }
    const user = c.user orelse return error.InternalError;
    const collection = Collection.findByIdAndUserId(c.db.?, a, fromItem, user.id) catch
        return error.InternalError;
    if (collection == null) {
        return ControllerError.BadRequest;
    }
}
