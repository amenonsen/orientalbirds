-- An observation is a (species, location, date) that results in one or
-- more artefacts (photographs, recordings, video) that are stored as
-- individual files below.

create table observations (
    observation_id serial primary key,

    -- If we don't know the species, we set the taxon_id to the nearest
    -- known ancestor.
    species_id integer references species,
    taxon_id integer references taxa,

    -- If this is set, it means all the files that refer to this
    -- observation have the same contributor (which is the common case).
    -- Otherwise, this information must be looked up separately.
    contributor_id integer references contributors,

    -- Where and when were the files associated with this observation
    -- recorded? We have to accommodate historical data with limited
    -- available precision.
    location_id integer references locations,
    approximate_location text,
    observed_at timestamptz,
    approximate_date text,

    -- Approximate or not, we invariably need to know what, where, and
    -- when this observation refers to.
    constraint observation_identity
        check (coalesce(species_id, taxon_id) is not null),
    constraint observation_location
        check (coalesce(location_id, approximate_location) is not null),
    constraint observation_time
        check (coalesce(observed_at, approximate_date) is not null),

    comments text,
    url text
);

-- An exhibit is a collection of files from one or more observations. We
-- use this structure with optional references in order to accommodate a
-- variety of situations: a photo of an individual, a series of photos
-- from one observation, many observations over time, a comparison
-- between different species, and so on.

create table exhibits (
    exhibit_id serial primary key,

    -- If this is set, it means all the constituent observations are of
    -- the same species. Otherwise, species information must be looked
    -- up for each observation separately (i.e. it's a comparison).
    species_id integer references species,

    -- If this is set, it's an allowance for the commonest case: an
    -- exhibit that consists of artefacts from a single observation.
    -- Otherwise, the observation corresponding to each file must be
    -- looked up separately.
    observation_id integer references observations,

    archived boolean not null default false,
    removed boolean not null default false,
    comments text,
    url text
);

-- A file is just a blob of data of a particular type, associated with a
-- particular observation and contributor. We don't care about the name
-- given to it by the contributor—we use a checksum of the contents for
-- storage and to enforce uniqueness.

create table mime_types (
    mime_type_id serial primary key,
    mime_type text not null unique
);

create table files (
    file_id serial primary key,
    checksum text not null unique,
    observation_id integer not null
        references observations,
    contributor_id integer not null
        references contributors,
    mime_type_id integer not null
        references mime_types
);

-- Optional per-file metadata derived from EXIF or similar. May not be
-- available for historical files, but should become more common and
-- more extensive as time goes by.

create table file_metadata (
    file_id integer not null references files,
    recorded_at timestamptz,
    position point,
    altitude integer,
    pos_accuracy integer,
    alt_accuracy integer
);

-- 1–N files per exhibit, in order.

create table exhibit_files (
    exhibit_id integer not null references exhibits,
    file_id integer not null references files,
    unique (exhibit_id, file_id),
    slno integer not null
);
