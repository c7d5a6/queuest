CREATE TABLE user_tbl
(
    id          INTEGER PRIMARY KEY,
    createdwhen INTEGER                  NOT NULL DEFAULT (unixepoch()),
    updatedwhen INTEGER                  NOT NULL DEFAULT (unixepoch()),

    uid         VARCHAR(128)             NOT NULL,
    email       VARCHAR(255)             NOT NULL,

    CONSTRAINT unq_user_uuid UNIQUE (uid),
    CONSTRAINT unq_user_email UNIQUE (email)
);

CREATE TABLE collection_tbl
(
    id            INTEGER PRIMARY KEY,
    createdwhen   INTEGER                  NOT NULL DEFAULT (unixepoch()),
    updatedwhen   INTEGER                  NOT NULL DEFAULT (unixepoch()),

    user_id       INTEGER                  NOT NULL,
    name          VARCHAR(512)             NOT NULL,
    visited_ts    INTEGER                  NOT NULL DEFAULT (unixepoch()),
    favourite_yn  INTEGER                  NOT NULL DEFAULT 0,

    CONSTRAINT unq_collection_name UNIQUE (name),
    CONSTRAINT fk_collection_user FOREIGN KEY (user_id)
        REFERENCES user_tbl (id) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT chk_collection_favourite CHECK (favourite_yn IN (0, 1))
);

CREATE TABLE item_tbl
(
    id          INTEGER PRIMARY KEY,
    createdwhen INTEGER                  NOT NULL DEFAULT (unixepoch()),
    updatedwhen INTEGER                  NOT NULL DEFAULT (unixepoch()),

    name        VARCHAR(512)             NOT NULL
);

CREATE TABLE collection_item_tbl
(
    id                    INTEGER PRIMARY KEY,
    createdwhen           INTEGER                  NOT NULL DEFAULT (unixepoch()),
    updatedwhen           INTEGER                  NOT NULL DEFAULT (unixepoch()),

    collection_id         INTEGER                  NOT NULL,
    type                  TEXT                     NOT NULL,
    item_id               INTEGER,
    collection_subitem_id INTEGER,

    CONSTRAINT fk_collection_item_item FOREIGN KEY (item_id)
        REFERENCES item_tbl (id) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT fk_collection_item_collection_subitem FOREIGN KEY (collection_subitem_id)
        REFERENCES collection_tbl (id) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT fk_collection_item_collection FOREIGN KEY (collection_id)
        REFERENCES collection_tbl (id) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT chk_collection_item_type CHECK (type IN ('ITEM', 'COLLECTION')),
    CONSTRAINT chk_collection_item_collection_not_subitem CHECK (collection_id <> collection_subitem_id),
    CONSTRAINT chk_collection_item_item_not_null CHECK ((item_id IS NOT NULL) OR (type <> 'ITEM')),
    CONSTRAINT chk_collection_item_collection_subitem_not_null
        CHECK ((collection_subitem_id IS NOT NULL) OR (type <> 'COLLECTION'))
);

CREATE UNIQUE INDEX unq_item_id ON collection_item_tbl (item_id) WHERE collection_subitem_id IS NULL;
CREATE UNIQUE INDEX unq_collection_subitem_id ON collection_item_tbl (collection_subitem_id) WHERE item_id IS NULL;

CREATE TABLE item_relation_tbl
(
    id                      INTEGER PRIMARY KEY,
    createdwhen             INTEGER                  NOT NULL DEFAULT (unixepoch()),
    updatedwhen             INTEGER                  NOT NULL DEFAULT (unixepoch()),

    collection_item_from_id INTEGER                  NOT NULL,
    collection_item_to_id   INTEGER                  NOT NULL,

    CONSTRAINT fk_item_relation_item_from FOREIGN KEY (collection_item_from_id)
        REFERENCES collection_item_tbl (id) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT fk_item_relation_item_to FOREIGN KEY (collection_item_to_id)
        REFERENCES collection_item_tbl (id) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE INDEX idx_collection_user_id ON collection_tbl (user_id);
CREATE INDEX idx_collection_item_collection_id ON collection_item_tbl (collection_id);
CREATE INDEX idx_item_relation_from ON item_relation_tbl (collection_item_from_id);
CREATE INDEX idx_item_relation_to ON item_relation_tbl (collection_item_to_id);
