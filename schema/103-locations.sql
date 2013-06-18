-- We maintain a list of countries in the oriental region as defined by
-- the OBC, plus some former Soviet countries because we have photos of
-- birds there.

create table countries (
    country_id serial primary key,
    country_name text not null unique,
    country_code text not null unique
);

-- We store a list of provinces for each country, but we make no attempt
-- to store further administrative subdivisions; nor do we care overmuch
-- about terminology. For example, they would be called states in India,
-- but it's all "in the provinces" to us.

create table provinces (
    province_id serial primary key,
    province_name text not null,
    country_id integer not null references countries
);

-- Using the above data, we maintain a big list of named locations that
-- people can use while defining observations.

create table locations (
    location_id serial primary key,
    location_name text not null,
    location_extra text,
    country_id integer not null references countries,
    province_id integer not null references provinces,
    coordinates point,
    altitude integer,
    pos_accuracy integer,
    alt_accuracy integer
);
