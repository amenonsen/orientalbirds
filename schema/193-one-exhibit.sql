insert into contributors
    (name, email) values
    ('Jonathan Martinez', 'jonathanmartinez@example.com');

insert into species
    (parent, genus, species, common_name, taxonomic_notes) values
    (152, 'Phylloscopus', 'ogilviegranti', 'Kloss''s Leaf Warbler',
        'Split from Phylloscopus davisoni following Olsson et al. (2005).');

insert into provinces
    (province_name, country_id) values
    ('Guangxi',
        (select country_id from countries where country_code='CN'));

insert into locations
    (location_name, country_id, province_id) values
    ('Shizi Shan',
        (select country_id from countries where country_code='CN'),
        (select province_id from provinces where province_name='Guangxi'));

insert into observations
    (species_id, contributor_id, location_id, observed_date) values
    ((select species_id from species where genus='Phylloscopus' and
        species='ogilviegranti'),
     (select contributor_id from contributors where
        email='jonathanmartinez@example.com'),
     (select location_id from locations where location_name='Shizi Shan'),
     '2012-07-21');

insert into files
    (checksum, observation_id, contributor_id, mime_type_id) values
    ('e9ffa68632291de77b0ce8a7b3276318',
     (select max(observation_id) from observations),
     (select contributor_id from contributors where
         email='jonathanmartinez@example.com'),
     (select mime_type_id from mime_types where mime_type='image/jpeg')),
    ('a9b74dec5cd9d75e9a027a724b3d5d6b',
     (select max(observation_id) from observations),
     (select contributor_id from contributors where
         email='jonathanmartinez@example.com'),
     (select mime_type_id from mime_types where mime_type='image/jpeg')),
    ('1f3d04271616222cc525d9bb3ad0540f',
     (select max(observation_id) from observations),
     (select contributor_id from contributors where
         email='jonathanmartinez@example.com'),
     (select mime_type_id from mime_types where mime_type='image/jpeg')),
    ('c7e3985bc223afdfef2be122db701445',
     (select max(observation_id) from observations),
     (select contributor_id from contributors where
         email='jonathanmartinez@example.com'),
     (select mime_type_id from mime_types where mime_type='image/jpeg')),
    ('97ca10fe536920e1e7dd3ea3492333da',
     (select max(observation_id) from observations),
     (select contributor_id from contributors where
         email='jonathanmartinez@example.com'),
     (select mime_type_id from mime_types where mime_type='image/jpeg'));

insert into exhibits
    (species_id, observation_id, comments) values
    ((select species_id from species where genus='Phylloscopus' and
        species='ogilviegranti'),
     (select max(observation_id) from observations),
     'The first set of photographs of P. ogilviegranti in the wild… or on OB, at least');

insert into exhibit_files
    (exhibit_id, file_id, slno)
    select (select max(exhibit_id) from exhibits), file_id,
        row_number() over (order by file_id asc) from files;
