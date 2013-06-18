alter table observations add observed_date date;
alter table observations drop constraint observation_identity;
alter table observations drop constraint observation_location;
alter table observations drop constraint observation_time;
alter table observations add constraint observation_what
    check (coalesce(species_id, taxon_id) is not null);
alter table observations add constraint observation_where
    check (coalesce(location_id::text, approximate_location) is not null);
alter table observations add constraint observation_when
    check (coalesce(observed_at::text, observed_date::text, approximate_date)
        is not null);
