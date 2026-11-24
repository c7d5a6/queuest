const std = @import("std");
const Allocator = std.mem.Allocator;
const params = @import("../routes/params.zig");
const Exchange = @import("../middle/context.zig").Exchange;
const Collection = @import("../data/collection.zig").Collection;
const ControllerError = @import("../routes/router-errors.zig").ControllerError;
const request = @import("../middle/context.zig");

pub fn onGetCollections(ctx: *Exchange) !void {
    const a = request.arena(ctx);
    const c = ctx.locals;
    std.debug.assert(c.db != null);
    std.debug.assert(c.user != null);
    const user = c.user orelse return error.InternalError;
    const collections = Collection.findAllForUserId(c.db.?, a, user.id) catch
        return error.InternalError;
    try request.sendJson(ctx, collections.items);
}

pub fn onGetFavCollections(ctx: *Exchange) !void {
    const a = request.arena(ctx);
    const c = ctx.locals;
    std.debug.assert(c.db != null);
    std.debug.assert(c.user != null);
    const user = c.user orelse return error.InternalError;
    const collections = Collection.findAllFavForUserId(c.db.?, a, user.id) catch
        return error.InternalError;
    try request.sendJson(ctx, collections.items);
}

pub fn onGetCollection(ctx: *Exchange) !void {
    const a = request.arena(ctx);
    const c = ctx.locals;
    std.debug.assert(c.db != null);
    std.debug.assert(c.user != null);
    const collectionId = try params.paramAs(i64, ctx, "collectionId");
    const user = c.user orelse return error.InternalError;
    const collection = (Collection.findByIdAndUserId(c.db.?, a, collectionId, user.id) catch
        return error.InternalError) orelse return error.NotFound;
    try request.sendJson(ctx, collection);
}

pub fn onPostCollection(ctx: *Exchange) !void {
    const a = request.arena(ctx);
    const c = ctx.locals;
    std.debug.assert(c.db != null);
    std.debug.assert(c.user != null);
    const body = ctx.request.body().contiguous() orelse return error.BadRequest;

    const CollectionCreate = struct { name: []const u8, favourite_yn: bool };
    const create = std.json.parseFromSlice(CollectionCreate, a, body, .{}) catch
        return error.BadRequest;

    const user = c.user orelse return error.InternalError;
    const id = (Collection.insertCollection(c.db.?, user.id, create.value.name) catch
        return error.InternalError) orelse return error.InternalError;
    try request.sendJson(ctx, id);
}

pub fn onPostFavCollection(ctx: *Exchange) !void {
    const a = request.arena(ctx);
    const c = ctx.locals;
    std.debug.assert(c.db != null);
    std.debug.assert(c.user != null);
    const collectionId = try params.paramAs(i64, ctx, "collectionId");
    const user = c.user orelse return error.InternalError;
    std.debug.assert(collectionId != 0);
    std.debug.assert(user.id != 0);
    var collection = (Collection.findByIdAndUserId(c.db.?, a, collectionId, user.id) catch
        return error.InternalError) orelse return error.NotFound;
    collection.favourite_yn = true;

    _ = Collection.updateCollection(c.db.?, collection) catch return error.InternalError;

    try ctx.response.text(200, "");
}

pub fn onPostVisitCollection(ctx: *Exchange) !void {
    const a = request.arena(ctx);
    const c = ctx.locals;
    std.debug.assert(c.db != null);
    std.debug.assert(c.user != null);
    const collectionId = try params.paramAs(i64, ctx, "collectionId");
    const user = c.user orelse return error.InternalError;
    const collection = (Collection.findByIdAndUserId(c.db.?, a, collectionId, user.id) catch
        return error.InternalError) orelse return error.NotFound;

    Collection.visitCollection(c.db.?, collection) catch return error.InternalError;

    try ctx.response.text(200, "");
}

pub fn onDeleteFavCollection(ctx: *Exchange) !void {
    const a = request.arena(ctx);
    const c = ctx.locals;
    std.debug.assert(c.db != null);
    std.debug.assert(c.user != null);
    const collectionId = try params.paramAs(i64, ctx, "collectionId");
    const user = c.user orelse return error.InternalError;
    std.debug.assert(collectionId != 0);
    std.debug.assert(user.id != 0);
    var collection = (Collection.findByIdAndUserId(c.db.?, a, collectionId, user.id) catch
        return error.InternalError) orelse return error.NotFound;
    collection.favourite_yn = false;

    _ = Collection.updateCollection(c.db.?, collection) catch return error.InternalError;

    try ctx.response.text(200, "");
}
