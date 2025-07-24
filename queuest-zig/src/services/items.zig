const std = @import("std");
const Allocator = std.mem.Allocator;
const zap = @import("zap");
const Request = zap.Request;
const Graph = @import("graph.zig").Graph;
const gsize = @import("graph.zig").gsize;
const Context = @import("../middle/context.zig").Context;
const Item = @import("../data/item.zig").CollectionItem;
const Collection = @import("../data/collection.zig").Collection;
const ItemRelation = @import("../data/item_relations.zig").ItemRelation;
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
    var graph: Graph = Graph.init(a, @intCast(items.items.len));
    setGraphEdges(a, c, items.items, &graph) catch unreachable;
    const sorted = graph.sort() catch unreachable;
    var resultSorted = std.ArrayList(It).initCapacity(a, items.items.len) catch unreachable;
    for (sorted) |i| {
        resultSorted.append(result.items[i]) catch unreachable;
    }

    const Result = struct { id: i64, items: []It, calibrated: f64 };
    const res = Result{ .id = collectionId, .items = result.items, .calibrated = 0.5 };
    const json = std.json.stringifyAlloc(a, res, .{ .escape_unicode = true, .emit_null_optional_fields = false }) catch unreachable;
    r.setContentType(.JSON) catch return;
    r.sendJson(json) catch return;
}

fn setGraphEdges(a: Allocator, c: *Context, items: []Item, graph: *Graph) !void {
    const relations = ItemRelation.findAllForItemIds(c.connection.?, a, items) catch unreachable;
    for (relations.items) |rel| {
        const from_id = rel.collection_item_from_id;
        const to_id = rel.collection_item_to_id;
        var from: ?usize = null;
        var to: ?usize = null;
        for (items, 0..) |item, i| {
            if (item.id == from_id) {
                from = i;
            }
            if (item.id == to_id) {
                to = i;
            }
        }
        if (from) |f| {
            if (to) |t| {
                graph.addEdge(@intCast(f), @intCast(t));
            } else {
                unreachable;
            }
        } else {
            unreachable;
        }
    }
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

fn getBestPair(id: i64, itemList: std.ArrayList(i64), exclude: []const i64, edge: Edges) !?CollectionItem {
    const itemPos = ip: {
        for (itemList.items, 0..) |item, i| {
            if (item == id) {
                break :ip i;
            }
        }
        return error.InternalError;
    };

    var positions = std.AutoHashMap(i64, i64).init(a);
    defer positions.deinit();
    for (itemList.items, 0..) |item, i| {
        positions.put(item, @intCast(i)) catch unreachable;
    }

    const lastIdx = if (!edge.relations.has(id)) itemList.items.len - 1 else edge.relations.get(id).?.map((id) => positions.get(id).?).reduce((prevValue, currentValue) => std.math.min(prevValue, currentValue), itemList.items.len - 1);
    const firstIdx = if (!edge.relationsInverted.has(id)) 0 else edge.relationsInverted.get(id).?.map((id) => positions.get(id).?).reduce((prevValue, currentValue) => std.math.max(prevValue, currentValue), 0);

    const relationPosition = if (std.math.absInt(itemPos - firstIdx) > std.math.absInt(itemPos - lastIdx)) std.math.ceil(itemPos + firstIdx) / 2 else std.math.floor(itemPos + lastIdx) / 2;

    var backupItem: ?i64 = null;
    var resortItem: ?i64 = null;

    for (0..itemList.items.len * 2) |i| {
        const position = relationPosition + (2 * (i % 2) - 1) * std.math.ceil(i / 2);
        if (position < 0 or position >= itemList.items.len) {
            continue;
        }
        const itemForRelation = itemList.items[position];
        if (!backupItem and itemForRelation != id and !exclude.contains(itemForRelation)) {
            backupItem = itemForRelation;
        }
        if (!resortItem and itemForRelation != id) {
            resortItem = itemForRelation;
        }
        if (itemForRelation == id or exclude.contains(itemForRelation)) {
            continue;
        }
        if (!isThereRelation(id, itemForRelation, edge)) {
            return itemForRelation;
        }
    }
    if (backupItem) |b| {
        return b;
    }
    if (resortItem) |r| {
        return r;
    }
    return null;
}

fn isThereRelation(id: i64, itemForRelation: i64, edge: Edges) bool {
    return isThereRelationFromTo(id, itemForRelation, edge) or isThereRelationFromTo(itemForRelation, id, edge);
}

fn isThereRelationFromTo(fromId: i64, toId: i64, edge: Edges) bool {
    if (edge.relations.has(fromId)) return 0 <= edge.relations.get(fromId).?.find((idx) => idx == toId);
    return false;
}