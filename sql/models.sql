create extension hstore;

create table if not exists users (
    id serial not null,
    first_name varchar(20),
    last_name varchar(20),
    credits integer
);

create table if not exists users_credits_changes (
    ts timestamp default now(),
    user_id integer,
    value integer
);

create table if not exists users_first_name_changes (
    ts timestamp default now(),
    user_id integer,
    value varchar(20)
);

create table if not exists users_last_name_changes (
    ts timestamp default now(),
    user_id integer,
    value varchar(20)
);

--
-- Event table
---
create table if not exists events (
    id bigserial not null,
    created_at timestamp default now(),
    type varchar(255),
    user_id integer,
    data json
);


create or replace function insert_user_changes() returns trigger AS $$
DECLARE
    change_found bool := false;
BEGIN
    IF NEW.first_name IS DISTINCT FROM OLD.first_name THEN
        INSERT INTO users_first_name_changes (user_id, value) VALUES (NEW.id, NEW.first_name);
        change_found := true;
    END IF;

    IF NEW.credits IS DISTINCT FROM OLD.credits THEN
        INSERT INTO users_credits_changes (user_id, value) VALUES (NEW.id, NEW.credits);
        change_found := true;
    END IF;

    -- Generate events from changes
    IF change_found THEN
        insert into events (type, user_id, data)
            select 'trait_change',  NEW.id as user_id, json_agg(t) as data from (
                SELECT key as trait, o.value as old_value, n.value as new_value
                    FROM each(hstore(OLD)) o  -- (key, value)
                    JOIN   each(hstore(NEW)) n USING (key)
                    WHERE  o.value IS DISTINCT FROM n.value) as t;
    END IF;


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


create or replace function user_trait_change_notification() returns trigger AS $$
BEGIN
    RAISE NOTICE '%', NEW;
    perform pg_notify('trait_change', NEW.id::text);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


drop trigger if exists user_insert_traits on users;
create trigger user_insert_traits
    after insert on users
    for each row execute function insert_user_changes();

drop trigger if exists user_update_traits on users;
create trigger user_update_traits
    after update on users
    for each row execute function insert_user_changes();


drop trigger if exists user_trait_change_insert on events;
create trigger user_trait_change_insert
    after insert on events
    for each row execute function user_trait_change_notification();





