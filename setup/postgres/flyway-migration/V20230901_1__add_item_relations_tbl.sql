CREATE TABLE item_relation_tbl
(
    id                    BIGINT                   NOT NULL DEFAULT nextval('pk_sequence'),
    createdwhen           TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updatedwhen           TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP(6),

    collection_item_from_id         BIGINT                   NOT NULL,
    collection_item_to_id                  BIGINT                   NOT NULL,

    CONSTRAINT pk_collection_item PRIMARY KEY (id),
    CONSTRAINT fk_collection_item_item FOREIGN KEY (collection_item_from_id) REFERENCES collection_item_tbl (id) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT fk_collection_item_item FOREIGN KEY (collection_item_from_id) REFERENCES collection_item_tbl (id) ON DELETE NO ACTION ON UPDATE NO ACTION
);
