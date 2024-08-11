const std = @import("std");
const pg = @import("pg");
const User = @import("user.zig").User;
const Conn = pg.Conn;
const utils = @import("utils.zig");
const getSoloEntity = utils.getSoloEntity;
const getList = utils.getList;

const table_name = "collection_item_tbl";
const ItemType = enum {
    ITEM,
    COLLECTION,
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
    // type: ItemType,
    item_id: ?i64 = null,
    collection_subitem_id: ?i64 = null,
    name: []const u8 = "0",

    fn toCollectionItem(row: pg.Row) !CollectionItem {
        return try row.to(CollectionItem, .{ .map = .name });
    }
    pub fn findAllForCollectionId(conn: *Conn, allocator: std.mem.Allocator, collection_id: i64) !?(CollectionItem) {
        _ = collection_id;
        var result = try conn.queryOpts("select ci.*,i.name from " ++ table_name ++ " as ci left join item_tbl as i on ci.item_id = i.id ", .{}, .{ .column_names = true });
        defer result.deinit();

        _ = allocator;

        var e: ?CollectionItem = null;

        if (try result.next()) |row| {
            for (row._result.column_names) |c_name| {
                std.debug.print("\n\t{s}", .{c_name});
            }
            std.debug.print("\nCollectionItem {any}\n", .{row});
            e = try toCollectionItem(row);
            std.debug.print("\nCollectionItem {any}\n", .{e});
            // e = try row.to(T, .{ .map = .name });
        }
        return e;
    }
};
