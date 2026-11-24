const std = @import("std");
const Allocator = std.mem.Allocator;
const params = @import("../routes/params.zig");
const Context = @import("../middle/context.zig").Context;
const Collection = @import("../data/collection.zig").Collection;
const ControllerError = @import("../routes/router-errors.zig").ControllerError;
const request = @import("../middle/context.zig");

pub fn on_get_collections(ctx: *Context) !void {
    const a = request.arena(ctx);
    const c = ctx.locals;
    const user = c.user orelse return error.InternalError;
    const collections: std.ArrayList(Collection) = Collection.findAllForUserId(c.db.?, a, user.id) catch
        return error.InternalError;
    const json = std.json.Stringify.valueAlloc(a, collections.items, .{
        .escape_unicode = true,
        .emit_null_optional_fields = false,
    }) catch return error.InternalError;
    try ctx.response.jsonBytes(200, json);
}

pub fn on_get_fav_collections(ctx: *Context) !void {
    const a = request.arena(ctx);
    const c = ctx.locals;
    const user = c.user orelse return error.InternalError;
    const collections: std.ArrayList(Collection) = Collection.findAllFavForUserId(c.db.?, a, user.id) catch
        return error.InternalError;
    const json = std.json.Stringify.valueAlloc(a, collections.items, .{
        .escape_unicode = true,
        .emit_null_optional_fields = false,
    }) catch return error.InternalError;
    try ctx.response.jsonBytes(200, json);
}

pub fn on_get_collection(ctx: *Context) !void {
    const a = request.arena(ctx);
    const c = ctx.locals;
    const collectionId = try params.paramAs(i64, ctx, "collectionId");
    const user = c.user orelse return error.InternalError;
    const collection = (Collection.findByIdAndUserId(c.db.?, a, collectionId, user.id) catch
        return error.InternalError) orelse return error.NotFound;
    const json = std.json.Stringify.valueAlloc(a, collection, .{
        .escape_unicode = true,
        .emit_null_optional_fields = false,
    }) catch return error.InternalError;
    std.debug.print("collection: {s}\n", .{json});
    try ctx.response.jsonBytes(200, json);
}

pub fn on_post_collection(ctx: *Context) !void {
    const a = request.arena(ctx);
    const c = ctx.locals;
    const body = ctx.request.body().contiguous() orelse return error.BadRequest;

    const CollectionCreate = struct { name: []const u8, favourite_yn: bool };
    const create = std.json.parseFromSlice(CollectionCreate, a, body, .{}) catch return error.BadRequest;

    const user = c.user orelse return error.InternalError;
    const id = (Collection.insertCollection(c.db.?, user.id, create.value.name) catch
        return error.InternalError) orelse return error.InternalError;
    const json = std.json.Stringify.valueAlloc(a, id, .{
        .escape_unicode = true,
        .emit_null_optional_fields = false,
    }) catch return error.InternalError;
    try ctx.response.jsonBytes(200, json);
}

pub fn on_post_fav_collection(ctx: *Context) !void {
    const a = request.arena(ctx);
    const c = ctx.locals;
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

pub fn on_post_visit_collection(ctx: *Context) !void {
    const a = request.arena(ctx);
    const c = ctx.locals;
    const collectionId = try params.paramAs(i64, ctx, "collectionId");
    const user = c.user orelse return error.InternalError;
    const collection = (Collection.findByIdAndUserId(c.db.?, a, collectionId, user.id) catch
        return error.InternalError) orelse return error.NotFound;

    Collection.visitCollection(c.db.?, collection) catch return error.InternalError;

    try ctx.response.text(200, "");
}

pub fn on_delete_fav_collection(ctx: *Context) !void {
    const a = request.arena(ctx);
    const c = ctx.locals;
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
