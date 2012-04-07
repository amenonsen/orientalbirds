-- Taxonomic ranks (for reference)

create type rank as
    enum ('Kingdom', 'Phylum', 'Class', 'Order', 'Family', 'Subfamily',
          'Tribe', 'Genus', 'Species');

-- One row per taxon (but taxa of rank genus or species are handled
-- specially by the next table, though they could in principle be
-- stored here).

create table taxa (
    taxon_id serial primary key,
    rank rank not null,
    parent integer references taxa(taxon_id),
    taxon_name text not null unique,
    taxon_description text
);
grant select on taxa to :user;

-- One row per species, with the generic and specific names stored
-- separately, and the family identified using the above table.

create table species (
    species_id serial primary key,
    family integer not null references taxa(taxon_id),
    genus text not null,
    species text not null,
    common_name text not null,
    unique (genus, species)
);
grant select, insert, update on species to :user;

-- One row per alternative common or scientific name for a species
-- (language_id is 1 for "Latin", or 2 for English).

create table alternative_names (
    species_id integer not null references species,
    language_id integer not null
        constraint valid_language check (language_id in (1,2)),
    alt_name text not null
);
grant select, insert, update, delete on alternative_names to :user;

-- One row per checklist (e.g. Howard and Moore). Just a list of names.

create table checklists (
    checklist_id serial primary key,
    name text not null unique,
    description text
);
grant select on checklists to :user;

-- One row per species per checklist, identifying the serial number of
-- the species in the given checklist. (We don't support "1024A", just
-- an integer for now.)

create table checklist_species (
    checklist_id integer not null references checklists,
    species_id integer not null references species,
    serial integer not null
);
grant select on checklist_species to :user;
