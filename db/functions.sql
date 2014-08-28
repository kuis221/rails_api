/*
This is the functions.sql file used by Squirm-Rails. Define your Postgres stored
procedures in this file and they will be loaded at the end of any calls to the
db:schema:load Rake task.
*/

CREATE OR REPLACE FUNCTION find_tdlinx_place(pname VARCHAR, pstreet VARCHAR, pcity VARCHAR, pstate VARCHAR, pzipcode VARCHAR) RETURNS integer AS $$
DECLARE
    place RECORD;
    normalized_address VARCHAR;
    normalized_address2 VARCHAR;
BEGIN
    FOR place IN SELECT * FROM places WHERE lower(city)=lower(pcity) AND lower(state)=lower(pstate) AND lower(zipcode)=lower(pzipcode) AND lower(coalesce(places.street_number, '') || ' ' || coalesce(places.route, ''))=lower(pstreet) LOOP
        return place.id;
    END LOOP;

    normalized_address := lower(normalize_addresss(pstreet));

    FOR place IN SELECT * FROM places WHERE lower(city)=lower(pcity) AND lower(state)=lower(pstate) AND lower(zipcode)=lower(pzipcode) AND lower(normalize_addresss(coalesce(places.street_number, '') || ' ' || coalesce(places.route, ''))) = normalized_address  LOOP
        return place.id;
    END LOOP;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION normalize_addresss(address VARCHAR) RETURNS VARCHAR AS $$
BEGIN
    address := regexp_replace(address, '(\s|,|^)(rd\.?)(\s|,|$)', '\1Road\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(st\.?)(\s|,|$)', '\1Street\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(ste\.?)(\s|,|$)', '\1Suite\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(av|ave\.?)(\s|,|$)', '\1Avenue\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(blvd\.?)(\s|,|$)', '\1Boulevard\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(hwy\.?)(\s|,|$)', '\1Highway\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(fifth\.?)(\s|,|$)', '\15th\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(dr\.?)(\s|,|$)', '\1Drive\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(w\.?)(\s|,|$)', '\1West\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(s\.?)(\s|,|$)', '\1South\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(e\.?)(\s|,|$)', '\1East\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(n\.?)(\s|,|$)', '\1North\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(ne\.?)(\s|,|$)', '\1Northeast\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(nw\.?)(\s|,|$)', '\1Northweast\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(se\.?)(\s|,|$)', '\1Northwest\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(sw\.?)(\s|,|$)', '\1Southweast\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(pkwy\.?)(\s|,|$)', '\1Parkway\3', 'ig');
    address := regexp_replace(address, '[\.,]+', '', 'ig');
    address := regexp_replace(address, '\s+', ' ', 'ig');
    RETURN trim(both ' ' from address);
END;
$$ LANGUAGE plpgsql;