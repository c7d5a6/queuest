const std = @import("std");
const context = @import("../middle/context.zig");
const Application = context.Application;
const Exchange = context.Exchange;
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
    try get(app, "/collections", collections.onGetCollections);
    try get(app, "/collections/fav", collections.onGetFavCollections);
    try get(app, "/collections/:collectionId", collections.onGetCollection);
    try post(app, "/collections", collections.onPostCollection);
    try post(app, "/collections/fav/:collectionId", collections.onPostFavCollection);
    try post(app, "/collections/visit/:collectionId", collections.onPostVisitCollection);
    try delete(app, "/collections/fav/:collectionId", collections.onDeleteFavCollection);
    // -- Items
    const item_path = "/collections/:collectionId/items";
    try get(app, item_path, items.onGetItems);
    try get(app, item_path ++ "/least-calibrated", items.onGetLeastCalibratedItem);
    try get(app, item_path ++ "/:collectionItemId/bestpair/:strict", items.onGetBestPair);
    try post(app, item_path, items.onPostItem);
    try delete(app, item_path ++ "/:collectionItemId", items.onDeleteItem);
    // -- ItemsRelation
    try post(app, "/relations/:fromId/:toId", items_relations.onPostRelation);
    try delete(app, "/relations/:itemAId/:itemBId", items_relations.onDeleteRelation);
}

fn get(app: *Application, comptime path: []const u8, comptime handler: Application.Handler) !void {
    try app.routeWith("GET", path, handler, authorized);
}

fn post(app: *Application, comptime path: []const u8, comptime handler: Application.Handler) !void {
    try app.routeWith("POST", path, handler, authorized);
}

fn delete(
    app: *Application,
    comptime path: []const u8,
    comptime handler: Application.Handler,
) !void {
    try app.routeWith("DELETE", path, handler, authorized);
}

fn hello(ctx: *Exchange) !void {
    return ctx.response.bytes(
        200,
        "text/html",
        "<html><body><h1>Hello from Baz!!!</h1></body></html>",
    );
}

fn onError(ctx: *Exchange, err: anyerror) !void {
    std.log.info("request failed: {s}", .{@errorName(err)});
    try header.addHeaders(ctx);
    return ctx.response.text(httpStatus(err), @errorName(err));
}

test {
    _ = @import("params.zig");
}
