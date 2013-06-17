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
    parent integer not null references taxa(taxon_id),
    genus text not null,
    species text not null,
    common_name text not null,
    taxonomic_notes text,
    unique (genus, species)
);
grant select, insert, update on species to :user;
