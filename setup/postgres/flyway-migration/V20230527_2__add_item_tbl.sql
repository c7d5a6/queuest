CREATE TABLE item_tbl
(
    id          BIGINT                   NOT NULL DEFAULT nextval('pk_sequence'),
    createdwhen TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updatedwhen TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP(6),

    name        VARCHAR(512)             NOT NULL,

    CONSTRAINT pk_item PRIMARY KEY (id),
    CONSTRAINT unq_item_name UNIQUE (name)
);
