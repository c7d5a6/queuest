CREATE SEQUENCE IF NOT EXISTS pk_sequence INCREMENT 10 CACHE 10 MINVALUE 1000;

-- set minimal value of IDs to 1000
SELECT nextval('pk_sequence') as pk_init;
