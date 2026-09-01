INSERT INTO user_tbl(id, uid, email) VALUES
(1, 'seed-user-alice', 'alice@example.test'),
(2, 'seed-user-bob', 'bob@example.test');

INSERT INTO collection_tbl(id, user_id, name, visited_ts, favourite_yn) VALUES
(10, 1, 'Alpha Queue', 1700000010, 1),
(11, 1, 'Beta Queue', 1700000005, 0),
(12, 1, 'Gamma Nested', 1700000001, 0),
(20, 2, 'Bob Only', 1700000020, 1);

INSERT INTO item_tbl(id, name) VALUES
(100, 'Alpha One'),
(101, 'Alpha Two'),
(102, 'Alpha Three'),
(103, 'Alpha Four'),
(104, 'Beta One');

INSERT INTO collection_item_tbl(id, collection_id, type, item_id, collection_subitem_id) VALUES
(1000, 10, 'ITEM', 100, NULL),
(1001, 10, 'ITEM', 101, NULL),
(1002, 10, 'ITEM', 102, NULL),
(1003, 10, 'ITEM', 103, NULL),
(1004, 10, 'COLLECTION', NULL, 12),
(1100, 11, 'ITEM', 104, NULL);

INSERT INTO item_relation_tbl(id, collection_item_from_id, collection_item_to_id) VALUES
(5000, 1000, 1001),
(5001, 1001, 1002);
