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

fn toIt(item: Item) It {
    const name = switch (item.inner) {
        .collection => |cl| cl.name,
        .item => |it| it.name,
    };
    return It{
        .id = item.id,
        .name = name,
    };
}

pub fn on_get_items(a: Allocator, r: Request, c: *Context, params: anytype) ControllerError!void {
    const collectionId = params.collectionId;
    const user = c.user orelse return error.InternalError;
    _ = Collection.findByIdAndUserId(c.connection.?, a, collectionId, user.id) catch
        return error.InternalError orelse return error.NotFound;
    const items: std.ArrayList(Item) = Item.findAllForCollectionId(c.connection.?, a, collectionId) catch
        return error.InternalError;
    var result = std.ArrayList(It).initCapacity(a, items.items.len) catch return error.InternalError;
    for (items.items) |item| {
        const name = switch (item.inner) {
            .collection => |cl| cl.name,
            .item => |it| it.name,
        };
        const n = a.allocSentinel(u8, name.len, 0) catch return error.InternalError;
        @memcpy(n, name);
        result.append(a, It{ .id = item.id, .name = n }) catch return error.InternalError;
    }
    var graph: Graph = Graph.init(a, @intCast(items.items.len));
    setGraphEdges(a, c, items.items, &graph) catch return error.InternalError;
    const sorted = graph.sort() catch return error.InternalError;
    var resultSorted = std.ArrayList(It).initCapacity(a, items.items.len) catch return error.InternalError;
    for (sorted) |i| {
        resultSorted.append(a, result.items[i]) catch return error.InternalError;
    }

    const Result = struct { id: i64, items: []It, calibrated: f64 };
    const res = Result{ .id = collectionId, .items = resultSorted.items, .calibrated = 0.5 };
    const json = std.json.Stringify.valueAlloc(a, res, .{ .escape_unicode = true, .emit_null_optional_fields = false, .whitespace = .minified }) catch return error.InternalError;
    r.setContentType(.JSON) catch return;
    r.sendJson(json) catch return;
}

pub fn on_get_best_pair(a: Allocator, r: Request, c: *Context, params: anytype) ControllerError!void {
    const collectionId = params.collectionId;
    const id = params.collectionItemId;
    const strict: bool = params.strict;
    const exclude = parseExcludeIds(a, r) catch return error.BadRequest;

    const user = c.user orelse return error.InternalError;
    _ = Collection.findByIdAndUserId(c.connection.?, a, collectionId, user.id) catch
        return error.InternalError orelse return error.NotFound;
    const item = Item.findById(c.connection.?, a, id) catch return error.InternalError orelse return error.NotFound;
    const items: std.ArrayList(Item) = Item.findAllForCollectionId(c.connection.?, a, collectionId) catch
        return error.InternalError;
    var graph: Graph = Graph.init(a, @intCast(items.items.len));
    setGraphEdges(a, c, items.items, &graph) catch return error.InternalError;
    const sorted = graph.sort() catch return error.InternalError;
    const relations = ItemRelation.findAllForItemIds(c.connection.?, a, items.items) catch return error.InternalError;
    var items_sorted = std.ArrayList(Item).initCapacity(a, items.items.len) catch return error.InternalError;
    for (sorted) |i| {
        items_sorted.append(a, items.items[i]) catch return error.InternalError;
    }

    const item_index = indexOfItem(items_sorted.items, id) orelse return error.InternalError;
    if (strict and isItemCalibrated(id, items_sorted.items, item_index, relations)) {
        const json = std.json.Stringify.valueAlloc(a, @as(?ItRel, null), .{
            .escape_unicode = true,
            .emit_null_optional_fields = false,
            .whitespace = .minified,
        }) catch return error.InternalError;
        r.setContentType(.JSON) catch return;
        r.sendJson(json) catch return;
        return;
    }

    const pair = getBestPair(a, id, items_sorted, exclude, relations) catch return error.InternalError;

    var res: ?ItRel = null;
    if (pair) |p| {
        if (!containsId(exclude, p.id)) {
            const candidate = toItRel(item, p, relations);
            if (candidate.relation == null) {
                res = candidate;
            }
        }
    }

    const json = std.json.Stringify.valueAlloc(a, res, .{
        .escape_unicode = true,
        .emit_null_optional_fields = false,
        .whitespace = .minified,
    }) catch return error.InternalError;
    r.setContentType(.JSON) catch return;
    r.sendJson(json) catch return;
}

fn setGraphEdges(a: Allocator, c: *Context, items: []Item, graph: *Graph) !void {
    const relations = ItemRelation.findAllForItemIds(c.connection.?, a, items) catch return error.InternalError;
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
                return error.InternalError;
            }
        } else {
            return error.InternalError;
        }
    }
}

pub fn on_post_item(a: Allocator, r: Request, c: *Context, params: anytype) ControllerError!void {
    r.parseBody() catch return error.InternalError;
    const body = r.body orelse return error.InternalError;

    const collectionId = params.collectionId;
    const user = c.user orelse return error.InternalError;
    _ = Collection.findByIdAndUserId(c.connection.?, a, collectionId, user.id) catch
        return error.InternalError orelse return error.NotFound;

    const CreateItem = struct { name: []const u8 };
    const create = std.json.parseFromSlice(CreateItem, a, body, .{ .ignore_unknown_fields = true }) catch return error.InternalError;
    const id = Item.insertItem(c.connection.?, create.value.name, collectionId) catch return error.InternalError;

    const json = std.json.Stringify.valueAlloc(a, id, .{ .escape_unicode = true, .emit_null_optional_fields = false }) catch return error.InternalError;
    r.setContentType(.JSON) catch return;
    r.sendJson(json) catch return;
}

pub fn on_delete_item(a: Allocator, r: Request, c: *Context, params: anytype) ControllerError!void {
    const collectionId = params.collectionId;
    const collectionItemId = params.collectionItemId;
    std.debug.assert(collectionId != 0);
    std.debug.assert(collectionItemId != 0);
    const user = c.user orelse return error.InternalError;
    _ = Collection.findByIdAndUserId(c.connection.?, a, collectionId, user.id) catch
        return error.InternalError orelse return error.NotFound;
    const item = Item.findById(c.connection.?, a, collectionItemId) catch
        return error.InternalError orelse return error.NotFound;
    if (item.collection_id != collectionId) {
        return error.NotFound;
    }

    Item.deleteItem(c.connection.?, collectionItemId) catch return error.InternalError;

    r.sendBody("") catch return;
}

fn toItRel(item: Item, pair: Item, relations: std.ArrayList(ItemRelation)) ItRel {
    var rel: ?Rel = null;
    if (isThereRelationFromTo(item.id, pair.id, relations)) {
        rel = .{ .from = item.id, .to = pair.id };
    }
    if (isThereRelationFromTo(pair.id, item.id, relations)) {
        rel = .{ .from = pair.id, .to = item.id };
    }
    return ItRel{
        .item1 = toIt(item),
        .item2 = toIt(pair),
        .relation = rel,
    };
}

fn parseExcludeIds(a: Allocator, r: Request) ControllerError![]const i64 {
    const raw = r.getParamSlice("exclude") orelse return &.{};
    var list = std.ArrayList(i64).initCapacity(a, 0) catch return error.InternalError;
    var it = std.mem.tokenizeScalar(u8, raw, ',');
    while (it.next()) |s| {
        if (s.len == 0) continue;
        if (list.items.len >= 1024) return error.BadRequest;
        const parsed = std.fmt.parseInt(i64, s, 10) catch return error.BadRequest;
        list.append(a, parsed) catch return error.InternalError;
    }
    return list.items;
}

fn containsId(ids: []const i64, id: i64) bool {
    for (ids) |x| {
        if (x == id) return true;
    }
    return false;
}

fn indexOfItem(items: []const Item, id: i64) ?usize {
    for (items, 0..) |item, i| {
        if (item.id == id) return i;
    }
    return null;
}

fn isItemCalibrated(
    id: i64,
    sorted: []const Item,
    item_index: usize,
    relations: std.ArrayList(ItemRelation),
) bool {
    if (sorted.len <= 1) return true;
    std.debug.assert(item_index < sorted.len);
    var out_n: usize = 0;
    var in_n: usize = 0;
    for (relations.items) |rel| {
        if (rel.collection_item_from_id == id) out_n += 1;
        if (rel.collection_item_to_id == id) in_n += 1;
    }
    if (out_n + in_n >= sorted.len - 1) return true;
    if (item_index == 0) {
        return isThereRelationFromTo(id, sorted[1].id, relations);
    }
    if (item_index == sorted.len - 1) {
        return isThereRelationFromTo(sorted[sorted.len - 2].id, id, relations);
    }
    return isThereRelationFromTo(id, sorted[item_index + 1].id, relations) and
        isThereRelationFromTo(sorted[item_index - 1].id, id, relations);
}

fn getBestPair(
    a: Allocator,
    id: i64,
    item_list: std.ArrayList(Item),
    exclude: []const i64,
    relations: std.ArrayList(ItemRelation),
) !?Item {
    std.debug.assert(id != 0);
    if (item_list.items.len == 0) return null;
    const pos = indexOfItem(item_list.items, id) orelse return error.InternalError;

    var positions = std.AutoHashMap(i64, usize).init(a);
    for (item_list.items, 0..) |item, i| {
        try positions.put(item.id, i);
    }

    var last_idx: usize = item_list.items.len - 1;
    var has_out = false;
    var first_idx: usize = 0;
    var has_in = false;
    for (relations.items) |rel| {
        if (rel.collection_item_from_id == id) {
            if (positions.get(rel.collection_item_to_id)) |p| {
                if (!has_out or p < last_idx) last_idx = p;
                has_out = true;
            }
        }
        if (rel.collection_item_to_id == id) {
            if (positions.get(rel.collection_item_from_id)) |p| {
                if (!has_in or p > first_idx) first_idx = p;
                has_in = true;
            }
        }
    }
    if (!has_out) last_idx = item_list.items.len - 1;
    if (!has_in) first_idx = 0;

    const r_pos = if (@abs(@as(isize, @intCast(pos)) - @as(isize, @intCast(first_idx))) >
        @abs(@as(isize, @intCast(pos)) - @as(isize, @intCast(last_idx))))
        @divFloor(pos + first_idx + 1, 2)
    else
        @divFloor(pos + last_idx, 2);

    var backup: ?Item = null;
    var resort: ?Item = null;
    const n: isize = @intCast(item_list.items.len);
    for (0..item_list.items.len * 2) |ui| {
        const i: isize = @intCast(ui);
        const step = @divFloor(i + 1, 2);
        const sign: isize = 2 * @mod(i, 2) - 1;
        const p = @as(isize, @intCast(r_pos)) + sign * step;
        if (p < 0 or p >= n) continue;
        const r_item = item_list.items[@intCast(p)];
        if (backup == null and r_item.id != id and !containsId(exclude, r_item.id)) {
            backup = r_item;
        }
        if (resort == null and r_item.id != id) {
            resort = r_item;
        }
        if (r_item.id == id or containsId(exclude, r_item.id)) {
            continue;
        }
        if (!isThereRelation(id, r_item.id, relations)) {
            return r_item;
        }
    }
    if (backup) |b| return b;
    if (resort) |item| return item;
    return null;
}

pub fn on_get_least_calibrated_item(a: Allocator, r: Request, c: *Context, params: anytype) ControllerError!void {
    const collectionId = params.collectionId;
    const user = c.user orelse return error.InternalError;
    _ = Collection.findByIdAndUserId(c.connection.?, a, collectionId, user.id) catch
        return error.InternalError orelse return error.NotFound;
    const items: std.ArrayList(Item) = Item.findAllForCollectionId(c.connection.?, a, collectionId) catch
        return error.InternalError;
    var positions = std.AutoHashMap(i64, usize).init(a);
    for (items.items, 0..) |item, i| {
        try positions.put(item.id, @intCast(i));
    }
    const relations = ItemRelation.findAllForItemIds(c.connection.?, a, items.items) catch return error.InternalError;
    const in = a.alloc(usize, items.items.len) catch return error.InternalError;
    const out = a.alloc(usize, items.items.len) catch return error.InternalError;
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
        const it = toIt(res);
        const json = std.json.Stringify.valueAlloc(a, it, .{ .escape_unicode = true, .emit_null_optional_fields = false }) catch return error.InternalError;
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
