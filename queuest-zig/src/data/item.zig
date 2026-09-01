const std = @import("std");
const Allocator = std.mem.Allocator;
const sqlite = @import("sqlite");
const Db = sqlite.Db;
const utils = @import("utils.zig");
const Id = utils.Id;

const ItemType = enum {
    item,
    collection,
};

const Item = struct {
    id: i64,
    name: [:0]const u8,
};

const NestedCollection = struct {
    id: i64,
    name: [:0]const u8,
};

const InnerItem = union(ItemType) {
    item: Item,
    collection: NestedCollection,
};

pub const CollectionItem = struct {
    id: i64,
    collection_id: i64,
    inner: InnerItem,

    const Row = struct {
        id: i64,
        collection_id: i64,
        type: []const u8,
        item_id: ?i64,
        collection_subitem_id: ?i64,
        item_name: ?[]const u8,
        col_name: ?[]const u8,
    };

    fn toCollectionItem(a: Allocator, row: Row) !CollectionItem {
        std.debug.assert(row.id != 0);
        std.debug.assert(row.collection_id != 0);
        const TypeStr = enum { ITEM, COLLECTION };
        const tp = std.meta.stringToEnum(TypeStr, row.type) orelse unreachable;
        const aname = switch (tp) {
            .ITEM => row.item_name orelse unreachable,
            .COLLECTION => row.col_name orelse unreachable,
        };
        const name = try a.allocSentinel(u8, aname.len, 0);
        @memcpy(name, aname);
        const inner = switch (tp) {
            .ITEM => InnerItem{ .item = Item{
                .id = row.item_id orelse unreachable,
                .name = name,
            } },
            .COLLECTION => InnerItem{ .collection = NestedCollection{
                .id = row.collection_subitem_id orelse unreachable,
                .name = name,
            } },
        };
        return CollectionItem{
            .id = row.id,
            .collection_id = row.collection_id,
            .inner = inner,
        };
    }

    const select_sql =
        \\SELECT ci.id, ci.collection_id, ci.type, ci.item_id, ci.collection_subitem_id,
        \\       it.name, cl.name
        \\  FROM collection_item_tbl AS ci
        \\  LEFT JOIN item_tbl AS it ON ci.item_id = it.id
        \\  LEFT JOIN collection_tbl AS cl ON ci.collection_subitem_id = cl.id
    ;

    pub fn findCollectionIdById(db: *Db, id: i64) !?i64 {
        std.debug.assert(id != 0);
        const Cid = struct { collection_id: ?i64 };
        const ocid = try db.one(
            Cid,
            "SELECT collection_id FROM collection_item_tbl WHERE id = ?",
            .{},
            .{id},
        );
        if (ocid) |cid| {
            return cid.collection_id;
        }
        return null;
    }

    pub fn findById(db: *Db, allocator: Allocator, id: i64) !?CollectionItem {
        std.debug.assert(id != 0);
        const row = try db.oneAlloc(
            Row,
            allocator,
            select_sql ++ " WHERE ci.id = ?",
            .{},
            .{id},
        );
        if (row) |r| {
            return try toCollectionItem(allocator, r);
        }
        return null;
    }

    pub fn findAllForCollectionId(
        db: *Db,
        allocator: Allocator,
        collection_id: i64,
    ) !std.ArrayList(CollectionItem) {
        std.debug.assert(collection_id != 0);
        var stmt = try db.prepare(select_sql ++ " WHERE collection_id = ?");
        defer stmt.deinit();
        const rows = try stmt.all(Row, allocator, .{}, .{collection_id});

        var array = try std.ArrayList(CollectionItem).initCapacity(allocator, rows.len);
        for (rows) |row| {
            try array.append(allocator, try toCollectionItem(allocator, row));
        }
        return array;
    }

    pub fn insertItem(db: *Db, name: []const u8, collection_id: i64) !?Id {
        std.debug.assert(name.len > 0);
        std.debug.assert(collection_id != 0);
        try db.exec("SAVEPOINT insert_item", .{}, .{});
        errdefer db.exec("ROLLBACK TO insert_item", .{}, .{}) catch {};

        try db.exec("INSERT INTO item_tbl(name) VALUES (?)", .{}, .{name});
        const item_id = db.getLastInsertRowID();
        std.debug.assert(item_id != 0);

        const id = try db.one(
            Id,
            \\INSERT INTO collection_item_tbl(collection_id, type, item_id)
            \\VALUES (?, 'ITEM', ?) RETURNING id
        ,
            .{},
            .{ collection_id, item_id },
        );
        try db.exec("RELEASE insert_item", .{}, .{});
        if (id) |row| {
            std.debug.assert(row.id != 0);
        }
        return id;
    }

    pub fn deleteItem(db: *Db, collection_item_id: i64) !void {
        std.debug.assert(collection_item_id != 0);
        try db.exec(
            "DELETE FROM collection_item_tbl WHERE id = ?",
            .{},
            .{collection_item_id},
        );
    }
};
