CREATE TYPE collection_item_type AS ENUM ('ITEM', 'COLLECTION');

CREATE TABLE collection_item_tbl
(
    id                    BIGINT                   NOT NULL DEFAULT nextval('pk_sequence'),
    createdwhen           TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updatedwhen           TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP(6),

    collection_id         BIGINT                   NOT NULL,
    type                  collection_item_type     NOT NULL,
    item_id               BIGINT,
    collection_subitem_id BIGINT,

    CONSTRAINT pk_collection_item PRIMARY KEY (id),
    CONSTRAINT fk_collection_item_item FOREIGN KEY (item_id) REFERENCES item_tbl (id) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT fk_collection_item_collection_subitem FOREIGN KEY (collection_subitem_id) REFERENCES collection_tbl (id) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT fk_collection_item_collection FOREIGN KEY (collection_id) REFERENCES collection_tbl (id) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT chk_collection_item_collection_not_subitem CHECK (collection_id <> collection_subitem_id),
    CONSTRAINT chk_collection_item_item_not_null CHECK ((item_id IS NOT NULL) OR (type <> 'ITEM')),
    CONSTRAINT chk_collection_item_collection_subitem_not_null CHECK ((collection_subitem_id IS NOT NULL) OR (type <> 'COLLECTION'))
);

CREATE UNIQUE INDEX unq_item_id ON collection_item_tbl (item_id) WHERE collection_subitem_id IS NULL;
CREATE UNIQUE INDEX unq_collection_subitem_id ON collection_item_tbl (collection_subitem_id) WHERE item_id IS NULL;
