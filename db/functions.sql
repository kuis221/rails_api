/*
This is the functions.sql file used by Squirm-Rails. Define your Postgres stored
procedures in this file and they will be loaded at the end of any calls to the
db:schema:load Rake task.
*/



CREATE OR REPLACE FUNCTION find_place(pname VARCHAR, pstreet VARCHAR, pcity VARCHAR, pstate VARCHAR, pzipcode VARCHAR) RETURNS integer AS $$
DECLARE
    place RECORD;
    normalized_address VARCHAR;
    normalized_address2 VARCHAR;
BEGIN
    normalized_address := lower(normalize_addresss(pstreet));

    FOR place IN SELECT * FROM places WHERE similarity(pname, name) > 0.5 AND lower(city)=lower(pcity) AND lower(state)=lower(pstate) AND (pzipcode is NULL OR lower(zipcode)=lower(pzipcode)) AND lower(normalize_addresss(coalesce(places.street_number, '') || ' ' || coalesce(places.route, ''))) = normalized_address  LOOP
        return place.id;
    END LOOP;

    FOR place IN SELECT * FROM places WHERE similarity(pname, name) > 0.5 AND lower(city)=lower(pcity) AND lower(state)=lower(pstate) AND (pzipcode is NULL OR lower(zipcode)=lower(pzipcode)) AND similarity(normalize_addresss(coalesce(places.street_number, '') || ' ' || coalesce(places.route, '')), normalized_address) >= 0.5  LOOP
        return place.id;
    END LOOP;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION normalize_addresss(address VARCHAR) RETURNS VARCHAR IMMUTABLE AS $$
BEGIN
    address := regexp_replace(address, '(\s|,|^)(rd\.?)(\s|,|$)', '\1Road\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(st\.?)(\s|,|$)', '\1Street\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(ste\.?)(\s|,|$)', '\1Suite\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(av|ave\.?)(\s|,|$)', '\1Avenue\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(blvd\.?)(\s|,|$)', '\1Boulevard\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(fwy\.?)(\s|,|$)', '\1Freeway\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(hwy\.?)(\s|,|$)', '\1Highway\3', 'ig');

    address := regexp_replace(address, '(\s|,|^)(Road|Street|Avenue|Boulevard|Freeway|Highway\.?)(\s|,|$)', '\1\3', 'ig');

    address := regexp_replace(address, '(\s|,|^)(fifth\.?)(\s|,|$)', '\15th\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(dr\.?)(\s|,|$)', '\1Drive\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(w\.?)(\s|,|$)', '\1West\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(s\.?)(\s|,|$)', '\1South\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(e\.?)(\s|,|$)', '\1East\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(n\.?)(\s|,|$)', '\1North\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(ne\.?)(\s|,|$)', '\1Northeast\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(nw\.?)(\s|,|$)', '\1Northwest\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(se\.?)(\s|,|$)', '\1Southeast\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(sw\.?)(\s|,|$)', '\1Southwest\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(pkwy\.?)(\s|,|$)', '\1Parkway\3', 'ig');
    address := regexp_replace(address, '[\.,]+', '', 'ig');
    address := regexp_replace(address, '\s+', ' ', 'ig');
    RETURN trim(both ' ' from address);
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION normalize_place_name(name VARCHAR) RETURNS VARCHAR IMMUTABLE AS $$
BEGIN
    name := regexp_replace(name, '^the\s+', '', 'ig');
    RETURN trim(both ' ' from name);
END;
$$ LANGUAGE plpgsql;


CREATE TYPE td_linx_result AS (code varchar, name varchar, street varchar, city varchar, state varchar, zipcode varchar, confidence integer);

CREATE OR REPLACE FUNCTION incremental_place_match(place_id INTEGER, state_code VARCHAR) RETURNS td_linx_result AS $$
DECLARE
    place RECORD;
    td_place RECORD;
    place_name VARCHAR;
    place_address VARCHAR;
    place_zip VARCHAR;
BEGIN
    SELECT * INTO place FROM places where places.id=incremental_place_match.place_id;
    place_name := lower(substr(normalize_place_name(place.name), 1, 5));
    place_address := normalize_addresss(lower(substr(trim(both 'x' from place.street_number || ' ' || place.route), 1, 5)));
    place_zip := substr(place.zipcode, 1, 4);
    RAISE NOTICE 'SEARCHING PLACE WITH name: %, street: %, zip: %', place_name, place_address, place_zip;
    FOR td_place IN SELECT tdlinx_codes.*, 10 FROM tdlinx_codes WHERE state=state_code AND substr(lower(normalize_place_name(name)), 1, 5) = place_name AND substr(street, 1, 5) = place_address AND substr(zipcode, 1, 4) = place_zip ORDER BY similarity(name, place_name) LOOP
        return td_place;
    END LOOP;

    FOR td_place IN SELECT tdlinx_codes.*, 5 FROM tdlinx_codes WHERE state=state_code AND (substr(lower(normalize_place_name(name)), 1, 5) % place_name) AND (substr(street, 1, 5) % place_address) ORDER BY similarity(name, place_name) LOOP
        return td_place;
    END LOOP;

    FOR td_place IN SELECT tdlinx_codes.*, 1 FROM tdlinx_codes WHERE state=state_code AND substr(lower(normalize_place_name(name)), 1, 5) = place_name AND substr(zipcode, 1, 4) = place_zip ORDER BY similarity(name, place_name) DESC LOOP
        return td_place;
    END LOOP;

    return null;
END;
$$ LANGUAGE plpgsql;

