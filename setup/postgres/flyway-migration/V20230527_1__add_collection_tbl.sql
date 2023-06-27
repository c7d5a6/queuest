CREATE TABLE collection_tbl
(
    id          BIGINT                   NOT NULL DEFAULT nextval('pk_sequence'),
    createdwhen TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updatedwhen TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP(6),

    user_id     BIGINT                   NOT NULL,
    name        VARCHAR(512)             NOT NULL,

    CONSTRAINT pk_collection PRIMARY KEY (id),
    CONSTRAINT unq_collection_name UNIQUE (name),
    CONSTRAINT fk_collection_user FOREIGN KEY (user_id) REFERENCES user_tbl (id) ON DELETE NO ACTION ON UPDATE NO ACTION
);
