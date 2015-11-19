CREATE TABLE IF NOT EXISTS changesets (
    id bigint primary key,
    file_location text,
    closed_at timestamp, 
    status text
);
