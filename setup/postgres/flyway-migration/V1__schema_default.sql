CREATE SEQUENCE IF NOT EXISTS pk_sequence INCREMENT 20 CACHE 20 MINVALUE 1000;

-- set minimal value of IDs to 1000
SELECT nextval('pk_sequence') as pk_init;