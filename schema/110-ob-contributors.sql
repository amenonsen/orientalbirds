alter table users add name text;
alter table users add email_confirmed boolean not null default true;

create table contributors (
    contributor_id serial primary key,
    name text not null,
    email text,
    url text,
    photo text,
    profile text
);
