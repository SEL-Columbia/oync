CREATE TABLE IF NOT EXISTS changesets (
    id bigint,
    file_location text,
    closed_at timestamp, 
    status text
);
