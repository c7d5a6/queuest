CREATE TABLE user_tbl
(
    id    BIGINT       NOT NULL DEFAULT nextval('pk_sequence'),

    uid   VARCHAR(128) NOT NULL,
    email VARCHAR(255) NOT NULL,

    CONSTRAINT pk_user PRIMARY KEY (id),
    CONSTRAINT unq_user_uuid UNIQUE (uid),
    CONSTRAINT unq_user_email UNIQUE (email)
);
