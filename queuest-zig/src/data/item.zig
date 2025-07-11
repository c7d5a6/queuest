const std = @import("std");
const pg = @import("pg");
const User = @import("user.zig").User;
const Conn = pg.Conn;
const utils = @import("utils.zig");
const Id = utils.Id;
const getSoloEntity = utils.getSoloEntity;
const getList = utils.getList;

const table_name = "collection_item_tbl";

const ItemType = enum {
    item,
    collection,
};

const Item = struct {
    id: i64,
    name: []const u8,
};

const Collection = struct {
    id: i64,
    name: []const u8,
};

const InnerItem = union(ItemType) {
    item: Item,
    collection: Collection,
};

// id                    | bigint                   |           | not null | nextval('pk_sequence'::regclass) | plain   |             |              |
// createdwhen           | timestamp with time zone |           | not null | CURRENT_TIMESTAMP(6)             | plain   |             |              |
// updatedwhen           | timestamp with time zone |           | not null | CURRENT_TIMESTAMP(6)             | plain   |             |              |
// collection_id         | bigint                   |           | not null |                                  | plain   |             |              |
// type                  | collection_item_type     |           | not null |                                  | plain   |             |              |
// item_id               | bigint                   |           |          |                                  | plain   |             |              |
// collection_subitem_id | bigint                   |           |          |                                  | plain   |             |              |
pub const CollectionItem = struct {
    id: i64,
    collection_id: i64,
    inner: InnerItem,

    fn toCollectionItem(row: pg.Row) !CollectionItem {
        var value: CollectionItem = undefined;
        // return try row.to(CollectionItem, .{ .map = .name });
        @field(value, "id") = row.getCol(i64, "id");
        @field(value, "collection_id") = row.getCol(i64, "collection_id");
        const typeStr = row.getCol([]const u8, "type");
        const TypeStr = enum { ITEM, COLLECTION };
        const tp = std.meta.stringToEnum(TypeStr, typeStr) orelse unreachable;
        const inner = switch (tp) {
            .ITEM => InnerItem{ .item = Item{
                .id = row.getCol(i64, "item_id"),
                .name = row.getCol([]const u8, "item_name"),
            } },
            .COLLECTION => InnerItem{ .collection = Collection{
                .id = row.getCol(i64, "collection_subitem_id"),
                .name = row.getCol([]const u8, "col_name"),
            } },
        };
        @field(value, "inner") = inner;

        return value;
    }

    pub fn findAllForCollectionId(conn: *Conn, allocator: std.mem.Allocator, collection_id: i64) !std.ArrayList(CollectionItem) {
        var result = try conn.queryOpts(
            \\select ci.*,it.name as item_name,cl.name as col_name  
            \\ from collection_item_tbl as ci
            \\ left join item_tbl as it on ci.item_id = it.id 
            \\ left join collection_tbl as cl on ci.collection_subitem_id = cl.id
            \\   where collection_id = $1
        , .{collection_id}, .{ .column_names = true });
        defer result.deinit();

        var array = std.ArrayList(CollectionItem).init(allocator);

        while (try result.next()) |row| {
            const e = try toCollectionItem(row);
            try array.append(e);
        }

        return array;
    }

    pub fn insertItem(conn: *Conn, name: []const u8, collection_id: i64) !?Id {
        var result = try conn.queryOpts(
            \\with ins1 as (
            \\  insert into item_tbl(name) values ($1) returning id
            \\)
            \\insert into collection_item_tbl(collection_id, type, item_id)
            \\values ($2, $3, (select id from ins1)) returning id
        , .{ name, collection_id, .ITEM }, .{ .column_names = true });
        defer result.deinit();

        return getSoloEntity(Id, result);
    }
};
