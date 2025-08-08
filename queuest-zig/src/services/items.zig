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

const It = struct { id: i64, name: [:0]const u8 };
const Rel = struct { from: i64, to: i64 };
const ItRel = struct { item1: It, item2: It, relation: ?Rel };

fn toIt(a: Allocator, item: Item) It {
    const name = switch (item.inner) {
        .collection => |cl| cl.name,
        .item => |it| it.name,
    };
    const n = a.allocSentinel(u8, name.len, 0) catch unreachable;
    @memcpy(n, name);
    return It{
        .id = item.id,
        .name = n,
    };
}

pub fn on_get_items(a: Allocator, r: Request, c: *Context, params: anytype) ControllerError!void {
    const collectionId = params.collectionId;
    _ = Collection.findByIdAndUserId(c.connection.?, collectionId, c.user.?.id) catch unreachable orelse unreachable;
    const items: std.ArrayList(Item) = Item.findAllForCollectionId(c.connection.?, a, collectionId) catch unreachable;
    var result = std.ArrayList(It).initCapacity(a, items.items.len) catch unreachable;
    for (items.items) |item| {
        const name = switch (item.inner) {
            .collection => |cl| cl.name,
            .item => |it| it.name,
        };
        const n = a.allocSentinel(u8, name.len, 0) catch unreachable;
        @memcpy(n, name);
        result.append(It{ .id = item.id, .name = n }) catch unreachable;
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
    const json = std.json.stringifyAlloc(a, res, .{ .escape_unicode = true, .emit_null_optional_fields = false, .whitespace = .minified }) catch unreachable;
    r.setContentType(.JSON) catch return;
    r.sendJson(json) catch return;
}

pub fn on_get_best_pair(a: Allocator, r: Request, c: *Context, params: anytype) ControllerError!void {
    const collectionId = params.collectionId;
    const id = params.collectionItemId;
    _ = params.strict;

    _ = Collection.findByIdAndUserId(c.connection.?, collectionId, c.user.?.id) catch unreachable orelse unreachable;
    const item = Item.findById(c.connection.?, id) catch unreachable orelse unreachable;
    const items: std.ArrayList(Item) = Item.findAllForCollectionId(c.connection.?, a, collectionId) catch unreachable;
    var graph: Graph = Graph.init(a, @intCast(items.items.len));
    setGraphEdges(a, c, items.items, &graph) catch unreachable;
    const sorted = graph.sort() catch unreachable;
    const relations = ItemRelation.findAllForItemIds(c.connection.?, a, items.items) catch unreachable;
    var items_sorted = std.ArrayList(Item).initCapacity(a, items.items.len) catch unreachable;
    for (sorted) |i| {
        items_sorted.append(items.items[i]) catch unreachable;
    }

    const pair = getBestPair(a, id, items_sorted, &.{}, relations) catch unreachable;

    var res: ?ItRel = null;
    if (pair) |p| {
        res = toItRel(a, item, p, relations);
    }

    const json = std.json.stringifyAlloc(a, res, .{ .escape_unicode = true, .emit_null_optional_fields = false, .whitespace = .minified }) catch unreachable;
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

fn toItRel(a: Allocator, item: Item, pair: Item, relations: std.ArrayList(ItemRelation)) ItRel {
    var rel: ?Rel = null;
    if (isThereRelationFromTo(item.id, pair.id, relations)) {
        rel = .{ .from = item.id, .to = pair.id };
    }
    if (isThereRelationFromTo(pair.id, item.id, relations)) {
        rel = .{ .from = pair.id, .to = item.id };
    }
    return ItRel{
        .item1 = toIt(a, item),
        .item2 = toIt(a, pair),
        .relation = rel,
    };
}

fn getBestPair(a: Allocator, id: i64, item_list: std.ArrayList(Item), exclude: []const i64, relations: std.ArrayList(ItemRelation)) !?Item {
    _ = exclude;
    const pos = ip: {
        for (item_list.items, 0..) |item, i| {
            if (item.id == id) {
                break :ip i;
            }
        }
        return error.InternalError;
    };

    var positions = std.AutoHashMap(i64, i64).init(a);
    for (item_list.items, 0..) |item, i| {
        positions.put(item.id, @intCast(i)) catch unreachable;
    }

    const last_pos = last: {
        var l = item_list.items.len - 1;
        for (relations.items) |r| {
            if (r.collection_item_to_id == id) {
                if (positions.get(r.collection_item_from_id)) |p| {
                    if (p < l) {
                        l = @intCast(p);
                    }
                }
            }
            if (r.collection_item_from_id == id) {
                if (positions.get(r.collection_item_to_id)) |p| {
                    if (p < l) {
                        l = @intCast(p);
                    }
                }
            }
        }
        break :last l;
    };
    const first_pos = first: {
        var f: usize = 0;
        for (relations.items) |r| {
            if (r.collection_item_to_id == id) {
                if (positions.get(r.collection_item_from_id)) |p| {
                    if (p > f) {
                        f = @intCast(p);
                    }
                }
            }
            if (r.collection_item_from_id == id) {
                if (positions.get(r.collection_item_to_id)) |p| {
                    if (p > f) {
                        f = @intCast(p);
                    }
                }
            }
        }
        break :first f;
    };

    std.debug.print("first_pos: {d}, last_pos: {d}, pos: {d}\n", .{ first_pos, last_pos, pos });
    const isize_pos: isize = @intCast(pos);
    const isize_first_pos: isize = @intCast(first_pos);
    const isize_last_pos: isize = @intCast(last_pos);
    const r_pos = if (@abs(isize_pos - isize_first_pos) > @abs(isize_pos - isize_last_pos)) @divFloor(pos + first_pos, 3) + @mod(pos + first_pos, 2) else @divFloor(pos + last_pos, 2);

    var backup: ?Item = null;
    var resort: ?Item = null;

    for (0..item_list.items.len * 2) |ui| {
        const i: isize = @intCast(ui);
        var p: isize = (2 * @mod(i, 2) - 1) * (@divFloor(i, 2) + @mod(i, 2));
        p += @intCast(r_pos);
        if (p < 0 or p >= item_list.items.len) {
            continue;
        }
        const r_item = item_list.items[@intCast(p)];
        // if (backup == null and r_item.id != id  and !exclude.contains(r_item)) {
        if (backup == null and r_item.id != id) {
            backup = r_item;
        }
        if (resort == null and r_item.id != id) {
            resort = r_item;
        }
        // if (r_item.id == id or exclude.contains(r_item)) {
        if (r_item.id == id) {
            continue;
        }
        if (!isThereRelation(id, r_item.id, relations)) {
            return r_item;
        }
    }
    if (backup) |b| {
        return b;
    }
    if (resort) |r| {
        return r;
    }
    return null;
}

pub fn on_get_least_calibrated_item(a: Allocator, r: Request, c: *Context, params: anytype) ControllerError!void {
    const collectionId = params.collectionId;
    _ = Collection.findByIdAndUserId(c.connection.?, collectionId, c.user.?.id) catch unreachable orelse unreachable;
    const items: std.ArrayList(Item) = Item.findAllForCollectionId(c.connection.?, a, collectionId) catch unreachable;
    var positions = std.AutoHashMap(i64, usize).init(a);
    for (items.items, 0..) |item, i| {
        positions.put(item.id, @intCast(i)) catch unreachable;
    }
    const relations = ItemRelation.findAllForItemIds(c.connection.?, a, items.items) catch unreachable;
    const in = a.alloc(usize, items.items.len) catch unreachable;
    const out = a.alloc(usize, items.items.len) catch unreachable;
    @memset(in, 0);
    @memset(out, 0);
    for (relations.items) |rel| {
        if (positions.get(rel.collection_item_from_id)) |p| {
            in[p] += 1;
        }
        if (positions.get(rel.collection_item_to_id)) |p| {
            out[p] += 1;
        }
    }
    var result: ?Item = null;
    var calibration: ?f64 = null;
    for (items.items, 0..) |item, i| {
        const insrt: f64 = @floatFromInt(in[i]);
        const outst: f64 = @floatFromInt(out[i]);
        const calvalue: f64 = std.math.sqrt(insrt) + std.math.sqrt(outst);
        if (calibration) |cal| {
            if (calvalue < cal) {
                calibration = calvalue;
                result = item;
            }
        } else {
            calibration = calvalue;
            result = item;
        }
    }
    if (result) |res| {
        const it = toIt(a, res);
        const json = std.json.stringifyAlloc(a, it, .{ .escape_unicode = true, .emit_null_optional_fields = false }) catch unreachable;
        r.setContentType(.JSON) catch return;
        r.sendJson(json) catch return;
    } else {
        r.sendBody("") catch return;
    }
}

fn isThereRelation(item: i64, relation: i64, relations: std.ArrayList(ItemRelation)) bool {
    return isThereRelationFromTo(item, relation, relations) or isThereRelationFromTo(relation, item, relations);
}

fn isThereRelationFromTo(from: i64, to: i64, relations: std.ArrayList(ItemRelation)) bool {
    for (relations.items) |r| {
        if (r.collection_item_from_id == from and r.collection_item_to_id == to)
            return true;
    }
    return false;
}
