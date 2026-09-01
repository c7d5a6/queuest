const std = @import("std");
const sqlite = @import("sqlite");
const queuest = @import("queuest");
const harness = @import("harness.zig");

const User = queuest.User;
const Collection = queuest.Collection;
const CollectionItem = queuest.CollectionItem;
const ItemRelation = queuest.ItemRelation;
const Graph = queuest.Graph;

test "users collections fav and visit ordering" {
    try harness.withCopiedDb(usersCollectionsFavVisit);
}

test "items insert list delete and nested collection item" {
    try harness.withCopiedDb(itemsInsertListDeleteNested);
}

test "relations insert delete and graph sort" {
    try harness.withCopiedDb(relationsAndGraph);
}

fn usersCollectionsFavVisit(db: *sqlite.Db) !void {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const missing = try User.findByUID(db, "nobody");
    try std.testing.expect(missing == null);

    try User.create(db, "seed-user-carol", "carol@example.test");
    const carol = try User.findByUID(db, "seed-user-carol");
    try std.testing.expect(carol != null);
    try std.testing.expect(carol.?.id != 0);

    const alice = (try User.findByUID(db, "seed-user-alice")).?;
    try std.testing.expectEqual(@as(i64, 1), alice.id);

    const listed = try Collection.findAllForUserId(db, allocator, alice.id);
    try std.testing.expectEqual(@as(usize, 3), listed.items.len);
    try std.testing.expectEqualStrings("Alpha Queue", listed.items[0].name);
    try std.testing.expectEqual(@as(i64, 10), listed.items[0].id);
    try std.testing.expect(listed.items[0].favourite_yn);

    const favs = try Collection.findAllFavForUserId(db, allocator, alice.id);
    try std.testing.expectEqual(@as(usize, 1), favs.items.len);
    try std.testing.expectEqual(@as(i64, 10), favs.items[0].id);

    var beta = (try Collection.findByIdAndUserId(db, allocator, 11, alice.id)).?;
    try std.testing.expectEqualStrings("Beta Queue", beta.name);
    try std.testing.expect(!beta.favourite_yn);

    beta.favourite_yn = true;
    const updated = try Collection.updateCollection(db, beta);
    try std.testing.expectEqual(@as(i64, 11), updated.?.id);

    const favs2 = try Collection.findAllFavForUserId(db, allocator, alice.id);
    try std.testing.expectEqual(@as(usize, 2), favs2.items.len);

    try Collection.visitCollection(db, beta);
    const after_visit = try Collection.findAllForUserId(db, allocator, alice.id);
    try std.testing.expectEqual(@as(i64, 11), after_visit.items[0].id);
    try std.testing.expect(after_visit.items[0].visited_ts > 1700000010);

    const created = try Collection.insertCollection(db, alice.id, "Delta New");
    try std.testing.expect(created != null);
    try std.testing.expect(created.?.id != 0);
    const delta = try Collection.findByIdAndUserId(db, allocator, created.?.id, alice.id);
    try std.testing.expectEqualStrings("Delta New", delta.?.name);

    const bob = (try User.findByUID(db, "seed-user-bob")).?;
    const bob_only = try Collection.findByIdAndUserId(db, allocator, 20, bob.id);
    try std.testing.expect(bob_only != null);
    const stolen = try Collection.findByIdAndUserId(db, allocator, 20, alice.id);
    try std.testing.expect(stolen == null);
}

fn itemsInsertListDeleteNested(db: *sqlite.Db) !void {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const nested = (try CollectionItem.findById(db, allocator, 1004)).?;
    try std.testing.expectEqual(@as(i64, 10), nested.collection_id);
    switch (nested.inner) {
        .collection => |cl| {
            try std.testing.expectEqual(@as(i64, 12), cl.id);
            try std.testing.expectEqualStrings("Gamma Nested", cl.name);
        },
        .item => return error.TestUnexpectedResult,
    }

    const before = try CollectionItem.findAllForCollectionId(db, allocator, 10);
    try std.testing.expectEqual(@as(usize, 5), before.items.len);

    const new_id = try CollectionItem.insertItem(db, "Alpha Five", 10);
    try std.testing.expect(new_id != null);
    try std.testing.expect(new_id.?.id != 0);

    const fetched = (try CollectionItem.findById(db, allocator, new_id.?.id)).?;
    switch (fetched.inner) {
        .item => |it| try std.testing.expectEqualStrings("Alpha Five", it.name),
        .collection => return error.TestUnexpectedResult,
    }

    const after_insert = try CollectionItem.findAllForCollectionId(db, allocator, 10);
    try std.testing.expectEqual(@as(usize, 6), after_insert.items.len);

    const beta_items = try CollectionItem.findAllForCollectionId(db, allocator, 11);
    try std.testing.expectEqual(@as(usize, 1), beta_items.items.len);
    try std.testing.expectEqual(@as(i64, 1100), beta_items.items[0].id);

    try CollectionItem.deleteItem(db, 1100);
    const beta_after = try CollectionItem.findAllForCollectionId(db, allocator, 11);
    try std.testing.expectEqual(@as(usize, 0), beta_after.items.len);
    try std.testing.expect(try CollectionItem.findById(db, allocator, 1100) == null);

    const parent = try CollectionItem.findCollectionIdById(db, 1000);
    try std.testing.expectEqual(@as(i64, 10), parent.?);
    try std.testing.expect(try CollectionItem.findCollectionIdById(db, 999999) == null);
}

fn relationsAndGraph(db: *sqlite.Db) !void {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const items = try CollectionItem.findAllForCollectionId(db, allocator, 10);
    try std.testing.expectEqual(@as(usize, 5), items.items.len);

    const initial = try ItemRelation.findAllForItemIds(db, allocator, items.items);
    try std.testing.expectEqual(@as(usize, 2), initial.items.len);

    const added = try ItemRelation.insertItemRelation(db, 1002, 1003);
    try std.testing.expect(added != null);
    try std.testing.expect(added.?.id != 0);

    const after_insert = try ItemRelation.findAllForItemIds(db, allocator, items.items);
    try std.testing.expectEqual(@as(usize, 3), after_insert.items.len);

    try ItemRelation.deleteItemRelation(db, 1000, 1001);
    const after_delete = try ItemRelation.findAllForItemIds(db, allocator, items.items);
    try std.testing.expectEqual(@as(usize, 2), after_delete.items.len);
    for (after_delete.items) |rel| {
        const from_1000_to_1001 = rel.collection_item_from_id == 1000 and
            rel.collection_item_to_id == 1001;
        try std.testing.expect(!from_1000_to_1001);
    }

    var graph = Graph.init(allocator, @intCast(items.items.len));
    for (after_delete.items) |rel| {
        const from = indexOf(items.items, rel.collection_item_from_id) orelse
            return error.TestUnexpectedResult;
        const to = indexOf(items.items, rel.collection_item_to_id) orelse
            return error.TestUnexpectedResult;
        graph.addEdge(@intCast(from), @intCast(to));
    }
    const sorted = try graph.sort();
    try std.testing.expectEqual(@as(usize, 5), sorted.len);

    const empty = try ItemRelation.findAllForItemIds(db, allocator, &.{});
    try std.testing.expectEqual(@as(usize, 0), empty.items.len);
}

fn indexOf(items: []const CollectionItem, id: i64) ?usize {
    for (items, 0..) |item, i| {
        if (item.id == id) return i;
    }
    return null;
}
