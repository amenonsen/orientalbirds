create table exhibits (
    exhibit_id serial primary key,
    species_id integer not null references species,
    contributor_id integer not null references contributors,
    approximate_location text,
    approximate_date text,
    source_url text,
    comments text
);

create table exhibit_files (
    exhibit_id integer not null references exhibits,
    filename text not null unique
);
