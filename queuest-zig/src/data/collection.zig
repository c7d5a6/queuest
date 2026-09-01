const std = @import("std");
const sqlite = @import("sqlite");
const Db = sqlite.Db;
const utils = @import("utils.zig");
const Id = utils.Id;
const getSolo = utils.getSolo;
const getList = utils.getList;

const table_name = "collection_tbl";

pub const Collection = struct {
    id: i64 = 0,
    user_id: i64 = 0,
    name: []const u8 = "0",
    favourite_yn: bool = true,
    visited_ts: i64 = 0,

    pub fn findAllForUserId(db: *Db, allocator: std.mem.Allocator, user_id: i64) !std.ArrayList(Collection) {
        std.debug.assert(user_id != 0);
        return getList(
            Collection,
            db,
            allocator,
            "SELECT id, user_id, name, favourite_yn, visited_ts FROM " ++ table_name ++
                " WHERE user_id = ? ORDER BY visited_ts DESC",
            .{user_id},
        );
    }

    pub fn findAllFavForUserId(db: *Db, allocator: std.mem.Allocator, user_id: i64) !std.ArrayList(Collection) {
        std.debug.assert(user_id != 0);
        return getList(
            Collection,
            db,
            allocator,
            "SELECT id, user_id, name, favourite_yn, visited_ts FROM " ++ table_name ++
                " WHERE user_id = ? AND favourite_yn = 1 ORDER BY visited_ts DESC",
            .{user_id},
        );
    }

    pub fn findByIdAndUserId(
        db: *Db,
        allocator: std.mem.Allocator,
        id: i64,
        user_id: i64,
    ) !?Collection {
        std.debug.assert(id != 0);
        std.debug.assert(user_id != 0);
        const collection = try getSolo(
            Collection,
            db,
            allocator,
            "SELECT id, user_id, name, favourite_yn, visited_ts FROM " ++ table_name ++
                " WHERE id = ? AND user_id = ?",
            .{ id, user_id },
        );
        if (collection) |c| {
            std.debug.assert(c.id == id);
            std.debug.assert(c.user_id == user_id);
        }
        return collection;
    }

    pub fn insertCollection(db: *Db, user_id: i64, name: []const u8) !?Id {
        std.debug.assert(user_id != 0);
        std.debug.assert(name.len > 0);
        const id = try db.one(
            Id,
            "INSERT INTO collection_tbl(user_id, name, visited_ts) VALUES (?, ?, unixepoch()) RETURNING id",
            .{},
            .{ user_id, name },
        );
        if (id) |row| {
            std.debug.assert(row.id != 0);
        }
        return id;
    }

    pub fn updateCollection(db: *Db, collection: Collection) !?Id {
        std.debug.assert(collection.id != 0);
        std.debug.assert(collection.user_id != 0);
        try db.exec(
            "UPDATE collection_tbl SET favourite_yn = ?, name = ? WHERE id = ? AND user_id = ?",
            .{},
            .{ collection.favourite_yn, collection.name, collection.id, collection.user_id },
        );
        return Id{ .id = collection.id };
    }

    pub fn deleteCollection(db: *Db, id: i64, user_id: i64) !void {
        std.debug.assert(id != 0);
        std.debug.assert(user_id != 0);
        try db.exec(
            "DELETE FROM collection_tbl WHERE id = ? AND user_id = ?",
            .{},
            .{ id, user_id },
        );
    }

    pub fn visitCollection(db: *Db, collection: Collection) !void {
        std.debug.assert(collection.id != 0);
        std.debug.assert(collection.user_id != 0);
        try db.exec(
            "UPDATE collection_tbl SET visited_ts = unixepoch() WHERE id = ? AND user_id = ?",
            .{},
            .{ collection.id, collection.user_id },
        );
    }

    pub fn setFav(
        db: *Db,
        allocator: std.mem.Allocator,
        id: i64,
        user_id: i64,
        fav: bool,
    ) !?Collection {
        std.debug.assert(id != 0);
        std.debug.assert(user_id != 0);
        return getSolo(
            Collection,
            db,
            allocator,
            "UPDATE " ++ table_name ++
                " SET favourite_yn = ? WHERE id = ? AND user_id = ?" ++
                " RETURNING id, user_id, name, favourite_yn, visited_ts",
            .{ fav, id, user_id },
        );
    }
};
