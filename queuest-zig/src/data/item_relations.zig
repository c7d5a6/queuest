const std = @import("std");
const pg = @import("pg");
const User = @import("user.zig").User;
const Conn = pg.Conn;
const utils = @import("utils.zig");
const Id = utils.Id;
const getSoloEntity = utils.getSoloEntity;
const getList = utils.getList;
const CollectionItem = @import("item.zig").CollectionItem;

const table_name = "item_relation_tbl";

// id                      | bigint                   |           | not null | nextval('pk_sequence'::regclass) | plain   |             |              |
// createdwhen             | timestamp with time zone |           | not null | CURRENT_TIMESTAMP(6)             | plain   |             |              |
// updatedwhen             | timestamp with time zone |           | not null | CURRENT_TIMESTAMP(6)             | plain   |             |              |
// collection_item_from_id | bigint                   |           | not null |                                  | plain   |             |              |
// collection_item_to_id   | bigint                   |           | not null |                                  | plain   |             |              |
pub const ItemRelation = struct {
    id: i64,
    collection_item_from_id: i64,
    collection_item_to_id: i64,

    fn toItemRelation(row: pg.Row) !ItemRelation {
        var value: ItemRelation = undefined;
        // return try row.to(CollectionItem, .{ .map = .name });
        @field(value, "id") = row.getCol(i64, "id");
        @field(value, "collection_item_from_id") = row.getCol(i64, "collection_item_from_id");
        @field(value, "collection_item_to_id") = row.getCol(i64, "collection_item_to_id");

        return value;
    }

    pub fn findAllForItemIds(conn: *Conn, allocator: std.mem.Allocator, items: []const CollectionItem) !std.ArrayList(ItemRelation) {
        if (items.len == 0) {
            return std.ArrayList(ItemRelation).init(allocator);
        }

        var item_ids: []i32 = try allocator.alloc(i32, items.len);
        defer allocator.free(item_ids);
        for (items, 0..) |item, i| {
            item_ids[i] = @intCast(item.id);
        }

        var ids_buf = std.ArrayList(u8).init(allocator);
        defer ids_buf.deinit();
        for (item_ids, 0..) |id, i| {
            if (i != 0) ids_buf.writer().print(", ", .{}) catch unreachable;
            ids_buf.writer().print("{d}", .{id}) catch unreachable;
        }
        const ids_str = ids_buf.items;
        std.log.info("ids_str: {s}\n", .{ids_str});

        const sql = try std.fmt.allocPrint(allocator,
            \\SELECT * FROM item_relation_tbl
            \\WHERE collection_item_from_id IN ({s}) OR collection_item_to_id IN ({s})
        , .{ ids_str, ids_str });
        defer allocator.free(sql);
        std.log.info("sql: {s}\n", .{sql});

        var result = try conn.queryOpts(sql, .{}, .{ .column_names = true });
        defer result.deinit();

        var array = std.ArrayList(ItemRelation).init(allocator);

        while (try result.next()) |row| {
            const e = try toItemRelation(row);
            try array.append(e);
        }

        return array;
    }

    pub fn insertItemRelation(conn: *Conn, collection_item_from_id: i64, collection_item_to_id: i64) !?Id {
        var result = try conn.queryOpts(
            \\insert into item_relation_tbl(collection_item_from_id, collection_item_to_id) values ($1, $2) returning id
        , .{ collection_item_from_id, collection_item_to_id }, .{ .column_names = true });
        defer result.deinit();

        return getSoloEntity(Id, result);
    }

    pub fn deleteItemRelation(conn: *Conn, collection_item_from_id: i64, collection_item_to_id: i64) !void {
        var result = try conn.queryOpts(
            \\delete from item_relation_tbl where 
            \\(collection_item_from_id = $1 and collection_item_to_id = $2) or
            \\(collection_item_from_id = $2 and collection_item_to_id = $1)
        , .{ collection_item_from_id, collection_item_to_id }, .{ .column_names = true });
        defer result.deinit();
    }
};
