-- One row per entity that may contribute an exhibit or portion thereof.
-- The wording is careful to allow organisations, people who have died,
-- and people for whom we have no contact information. Only a name is
-- required here.
--
-- This table has nothing to do with users, but a user may have an entry
-- in this table (with the same email address as in users.email) if they
-- are also a contributor (as opposed to an administrator).

create table contributors (
    contributor_id serial primary key,
    name text not null,
    email text,
    url text,
    photo text,
    profile text
);

alter table users add email_confirmed boolean not null default true;
