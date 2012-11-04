alter table users add name text;

create table contributors (
    contributor_id serial primary key,
    name text not null,
    email text,
    url text,
    photo text,
    profile text
);
