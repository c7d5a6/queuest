-- https://www.postgresql.org/docs/16/pgtrgm.html
-- https://www.geeksforgeeks.org/how-to-select-top-n-rows-for-each-group-in-sql-server/

CREATE TABLE IF NOT EXISTS text_tbl
(
    txt VARCHAR(255)
);

 
INSERT INTO text_tbl(txt) VALUES 
('aabb'),
('aacc'),
('aacbb'),
('aa');
