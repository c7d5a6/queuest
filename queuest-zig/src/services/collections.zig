const std = @import("std");
const Allocator = std.mem.Allocator;
const zap = @import("zap");
const Request = zap.Request;
const Context = @import("../middle/context.zig").Context;
const Collection = @import("../data/collection.zig").Collection;
const ControllerError = @import("../routes/router-errors.zig").ControllerError;

pub fn on_get_collections(a: Allocator, r: Request, c: *Context, params: anytype) ControllerError!void {
    _ = params;
    const user_id = c.user.?.id;
    const collections: std.ArrayList(Collection) = Collection.findAllForUserId(c.connection.?, a, user_id) catch unreachable;
    const json = std.json.stringifyAlloc(a, collections.items, .{ .escape_unicode = true, .emit_null_optional_fields = false }) catch unreachable;
    r.setContentType(.JSON) catch return;
    r.sendJson(json) catch return;
}

pub fn on_get_fav_collections(a: Allocator, r: Request, c: *Context, params: anytype) ControllerError!void {
    _ = params;
    const user_id = c.user.?.id;
    const collections: std.ArrayList(Collection) = Collection.findAllFavForUserId(c.connection.?, a, user_id) catch unreachable;
    const json = std.json.stringifyAlloc(a, collections.items, .{ .escape_unicode = true, .emit_null_optional_fields = false }) catch unreachable;
    r.setContentType(.JSON) catch return;
    r.sendJson(json) catch return;
}

pub fn on_get_collection(a: Allocator, r: Request, c: *Context, params: anytype) ControllerError!void {
    const collectionId = params.collectionId;
    const collection: Collection = Collection.findByIdAndUserId(c.connection.?, collectionId, c.user.?.id) catch unreachable orelse unreachable;
    const json = std.json.stringifyAlloc(a, collection, .{ .escape_unicode = true, .emit_null_optional_fields = false }) catch unreachable;
    r.setContentType(.JSON) catch return;
    r.sendJson(json) catch return;
}

pub fn on_post_collection(a: Allocator, r: Request, c: *Context, params: anytype) ControllerError!void {
    _ = params;
    r.parseBody() catch return error.InternalError;
    const body = r.body orelse return error.InternalError;

    const CollectionCreate = struct { name: []const u8, favourite: bool };
    const create = std.json.parseFromSlice(CollectionCreate, a, body, .{}) catch return error.InternalError;

    const id = Collection.insertCollection(c.connection.?, c.user.?.id, create.value.name) catch unreachable orelse unreachable;
    const json = std.json.stringifyAlloc(a, id, .{ .escape_unicode = true, .emit_null_optional_fields = false }) catch unreachable;
    r.setContentType(.JSON) catch return;
    r.sendJson(json) catch return;
}

pub fn on_post_fav_collection(a: Allocator, r: Request, c: *Context, params: anytype) ControllerError!void {
    const collectionId = params.collectionId;
    var collection: Collection = Collection.findByIdAndUserId(c.connection.?, collectionId, c.user.?.id) catch unreachable orelse unreachable;
    collection.favourite_yn = true;

    const id = Collection.updateCollection(c.connection.?, collection) catch unreachable;
    const json = std.json.stringifyAlloc(a, id, .{ .escape_unicode = true, .emit_null_optional_fields = false }) catch unreachable;

    r.setContentType(.JSON) catch return;
    r.sendJson(json) catch return;
}

pub fn on_post_visit_collection(a: Allocator, r: Request, c: *Context, params: anytype) ControllerError!void {
    _ = a;
    const collectionId = params.collectionId;
    const collection: Collection = Collection.findByIdAndUserId(c.connection.?, collectionId, c.user.?.id) catch unreachable orelse unreachable;

    Collection.visitCollection(c.connection.?, collection) catch unreachable;

    r.sendBody("") catch return;
}

pub fn on_delete_fav_collection(a: Allocator, r: Request, c: *Context, params: anytype) ControllerError!void {
    _ = a;
    const collectionId = params.collectionId;
    Collection.deleteCollection(c.connection.?, collectionId, c.user.?.id) catch unreachable;

    r.sendBody("") catch return;
}
