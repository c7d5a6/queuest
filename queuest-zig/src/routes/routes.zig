const std = @import("std");
const context = @import("../middle/context.zig");
const Application = context.Application;
const Context = context.Context;
const header = @import("../middle/header.zig");
const arena = @import("../middle/arena.zig");
const auth = @import("../middle/auth.zig");
const sqlite = @import("../middle/sqlite.zig");
const user = @import("../middle/user.zig");
const collections = @import("../services/collections.zig");
const items = @import("../services/items.zig");
const items_relations = @import("../services/items_relations.zig");
const httpStatus = @import("router-errors.zig").httpStatus;

pub const on_error: Application.ErrorHandler = onError;

/// Hooks for every route that needs a signed-in user, in running order.
const authorized: Application.RouteOptions = .{
    .middleware = &.{
        arena.middleware,
        auth.middleware,
        sqlite.middleware,
        user.middleware,
    },
};

/// Register all routes. Baz picks the most specific path (`/collections/fav`
/// beats `/collections/:id`) and answers 404/405, OPTIONS and HEAD itself.
pub fn register(app: *Application) !void {
    try app.route("GET", "/api/hello", hello);
    // -- Collections
    try app.routeWith("GET", "/collections", collections.on_get_collections, authorized);
    try app.routeWith("GET", "/collections/fav", collections.on_get_fav_collections, authorized);
    try app.routeWith("GET", "/collections/:collectionId", collections.on_get_collection, authorized);
    try app.routeWith("POST", "/collections", collections.on_post_collection, authorized);
    try app.routeWith("POST", "/collections/fav/:collectionId", collections.on_post_fav_collection, authorized);
    try app.routeWith("POST", "/collections/visit/:collectionId", collections.on_post_visit_collection, authorized);
    try app.routeWith("DELETE", "/collections/fav/:collectionId", collections.on_delete_fav_collection, authorized);
    // -- Items
    try app.routeWith("GET", "/collections/:collectionId/items", items.on_get_items, authorized);
    try app.routeWith("GET", "/collections/:collectionId/items/least-calibrated", items.on_get_least_calibrated_item, authorized);
    try app.routeWith("GET", "/collections/:collectionId/items/:collectionItemId/bestpair/:strict", items.on_get_best_pair, authorized);
    try app.routeWith("POST", "/collections/:collectionId/items", items.on_post_item, authorized);
    try app.routeWith("DELETE", "/collections/:collectionId/items/:collectionItemId", items.on_delete_item, authorized);
    // -- ItemsRelation
    try app.routeWith("POST", "/relations/:fromId/:toId", items_relations.on_post_relation, authorized);
    try app.routeWith("DELETE", "/relations/:itemAId/:itemBId", items_relations.on_delete_relation, authorized);
}

fn hello(ctx: *Context) !void {
    return ctx.response.bytes(200, "text/html", "<html><body><h1>Hello from Baz!!!</h1></body></html>");
}

fn onError(ctx: *Context, err: anyerror) !void {
    std.log.info("request failed: {s}", .{@errorName(err)});
    try header.addHeaders(ctx);
    return ctx.response.text(httpStatus(err), @errorName(err));
}

test {
    _ = @import("params.zig");
}
