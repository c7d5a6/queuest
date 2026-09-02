const std = @import("std");
const sqlite = @import("sqlite");
const Db = sqlite.Db;
const utils = @import("utils.zig");
const Id = utils.Id;
const CollectionItem = @import("item.zig").CollectionItem;

pub const ItemRelation = struct {
    id: i64,
    collection_item_from_id: i64,
    collection_item_to_id: i64,

    pub fn findAllForItemIds(
        db: *Db,
        allocator: std.mem.Allocator,
        items: []const CollectionItem,
    ) !std.ArrayList(ItemRelation) {
        if (items.len == 0) {
            return try std.ArrayList(ItemRelation).initCapacity(allocator, 0);
        }
        std.debug.assert(items.len > 0);

        var ids_buf = try std.ArrayList(u8).initCapacity(allocator, 0);
        defer ids_buf.deinit(allocator);
        for (items, 0..) |item, i| {
            std.debug.assert(item.id != 0);
            if (i != 0) try ids_buf.print(allocator, ", ", .{});
            try ids_buf.print(allocator, "{d}", .{item.id});
        }
        const ids_str = ids_buf.items;

        const sql = try std.fmt.allocPrint(allocator,
            \\SELECT id, collection_item_from_id, collection_item_to_id
            \\  FROM item_relation_tbl
            \\ WHERE collection_item_from_id IN ({s})
            \\    OR collection_item_to_id IN ({s})
        , .{ ids_str, ids_str });
        defer allocator.free(sql);

        var stmt = try db.prepareDynamic(sql);
        defer stmt.deinit();
        return utils.collectAll(ItemRelation, &stmt, allocator, .{});
    }

    pub fn insertItemRelation(
        db: *Db,
        collection_item_from_id: i64,
        collection_item_to_id: i64,
    ) !?Id {
        std.debug.assert(collection_item_from_id != 0);
        std.debug.assert(collection_item_to_id != 0);
        std.debug.assert(collection_item_from_id != collection_item_to_id);
        const id = try db.one(
            Id,
            \\INSERT INTO item_relation_tbl(collection_item_from_id, collection_item_to_id)
            \\VALUES (?, ?) RETURNING id
        ,
            .{},
            .{ collection_item_from_id, collection_item_to_id },
        );
        if (id) |row| {
            std.debug.assert(row.id != 0);
        }
        return id;
    }

    pub fn deleteItemRelation(
        db: *Db,
        collection_item_from_id: i64,
        collection_item_to_id: i64,
    ) !void {
        std.debug.assert(collection_item_from_id != 0);
        std.debug.assert(collection_item_to_id != 0);
        try db.exec(
            \\DELETE FROM item_relation_tbl WHERE
            \\(collection_item_from_id = ? AND collection_item_to_id = ?) OR
            \\(collection_item_from_id = ? AND collection_item_to_id = ?)
        ,
            .{},
            .{
                collection_item_from_id,
                collection_item_to_id,
                collection_item_to_id,
                collection_item_from_id,
            },
        );
    }
};
