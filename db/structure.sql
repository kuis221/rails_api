--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track execution statistics of all SQL statements executed';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';


--
-- Name: postgres_fdw; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgres_fdw WITH SCHEMA public;


--
-- Name: EXTENSION postgres_fdw; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgres_fdw IS 'foreign-data wrapper for remote PostgreSQL servers';


--
-- Name: tablefunc; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS tablefunc WITH SCHEMA public;


--
-- Name: EXTENSION tablefunc; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION tablefunc IS 'functions that manipulate whole tables, including crosstab';


SET search_path = public, pg_catalog;

--
-- Name: td_linx_result; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE td_linx_result AS (
	code character varying,
	name character varying,
	street character varying,
	city character varying,
	state character varying,
	zipcode character varying,
	confidence integer
);


--
-- Name: find_place(character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION find_place(pname character varying, pstreet character varying, pcity character varying, pstate character varying, pzipcode character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: find_tdlinx_place(character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION find_tdlinx_place(pname character varying, pstreet character varying, pcity character varying, pstate character varying, pzipcode character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    place RECORD;
    normalized_address VARCHAR;
    normalized_address2 VARCHAR;
BEGIN
    normalized_address := lower(normalize_addresss(pstreet));

    FOR place IN SELECT * FROM places WHERE similarity(pname, name) > 0.5 AND lower(city)=lower(pcity) AND lower(state)=lower(pstate) AND lower(zipcode)=lower(pzipcode) AND lower(normalize_addresss(coalesce(places.street_number, '') || ' ' || coalesce(places.route, ''))) = normalized_address  LOOP
        return place.id;
    END LOOP;

    RETURN NULL;
END;
$$;


--
-- Name: incremental_place_match(integer, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION incremental_place_match(place_id integer, state_code character varying) RETURNS td_linx_result
    LANGUAGE plpgsql
    AS $$
DECLARE
    place RECORD;
    td_place RECORD;
    place_name VARCHAR;
    place_address VARCHAR;
    place_address2 VARCHAR;
    place_zip2 VARCHAR;
BEGIN
    SELECT * INTO place FROM places where places.id=incremental_place_match.place_id;
    place_name := normalize_place_name(place.name);
    place_address := normalize_addresss(COALESCE(place.street_number, '') || ' ' || COALESCE(place.route, ''));
    place_address2 := normalize_addresss(COALESCE(place.formatted_address, ''));
    place_zip2 := substr(place.zipcode, 1, 2);
    FOR td_place IN SELECT tdlinx_codes.*, 10 FROM tdlinx_codes WHERE state=state_code AND substr(lower(normalize_place_name(name)), 1, 5) = substr(lower(place_name), 1, 5) AND (substr(lower(street), 1, 5) = substr(lower(place_address), 1, 5) OR substr(lower(street), 1, 5) = substr(lower(place_address2), 1, 5)) AND zipcode = place.zipcode ORDER BY similarity(name, place_name) LOOP
        return td_place;
    END LOOP;

    FOR td_place IN SELECT tdlinx_codes.*, 5 FROM tdlinx_codes WHERE state=state_code AND normalize_place_name(name) % place_name AND (similarity(street, place_address) >= 0.5 AND (substr(lower(street), 1, 5) = substr(lower(place_address), 1, 5) OR substr(lower(street), 1, 5) = substr(lower(place_address2), 1, 5)) ) AND zipcode = place.zipcode ORDER BY similarity(name, place_name) LOOP
        return td_place;
    END LOOP;

    FOR td_place IN SELECT tdlinx_codes.*, 1 FROM tdlinx_codes WHERE similarity(normalize_place_name(name), place_name) >= 0.5 AND similarity(street, place_address) >= 0.4 AND (place_zip2 IS NULL OR substr(zipcode, 1, 2) = place_zip2) ORDER BY similarity(name, place_name) DESC LOOP
        return td_place;
    END LOOP;

    return null;
END;
$$;


--
-- Name: normalize_addresss(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION normalize_addresss(address character varying) RETURNS character varying
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
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
$_$;


--
-- Name: normalize_place_name(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION normalize_place_name(name character varying) RETURNS character varying
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
    name := regexp_replace(name, '^the\s+', '', 'ig');
    name := regexp_replace(name, '''', '', 'ig');
    RETURN trim(both ' ' from name);
END;
$$;


--
-- Name: legacy_prod; Type: SERVER; Schema: -; Owner: -
--

CREATE SERVER legacy_prod FOREIGN DATA WRAPPER postgres_fdw OPTIONS (
    dbname 'd9ncqhfqis29bj',
    host 'ec2-54-235-194-252.compute-1.amazonaws.com',
    port '5432'
);


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: active_admin_comments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE active_admin_comments (
    id integer NOT NULL,
    resource_id character varying(255) NOT NULL,
    resource_type character varying(255) NOT NULL,
    author_id integer,
    author_type character varying(255),
    body text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    namespace character varying(255)
);


--
-- Name: active_admin_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE active_admin_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_admin_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE active_admin_comments_id_seq OWNED BY active_admin_comments.id;


--
-- Name: activities; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE activities (
    id integer NOT NULL,
    activity_type_id integer,
    activitable_id integer,
    activitable_type character varying(255),
    campaign_id integer,
    active boolean DEFAULT true,
    company_user_id integer,
    activity_date timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: activities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE activities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE activities_id_seq OWNED BY activities.id;


--
-- Name: activity_type_campaigns; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE activity_type_campaigns (
    id integer NOT NULL,
    activity_type_id integer,
    campaign_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: activity_type_campaigns_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE activity_type_campaigns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_type_campaigns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE activity_type_campaigns_id_seq OWNED BY activity_type_campaigns.id;


--
-- Name: activity_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE activity_types (
    id integer NOT NULL,
    name character varying(255),
    description text,
    active boolean DEFAULT true,
    company_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: activity_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE activity_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE activity_types_id_seq OWNED BY activity_types.id;


--
-- Name: admin_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE admin_users (
    id integer NOT NULL,
    email character varying(255) DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying(255) DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying(255),
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying(255),
    last_sign_in_ip character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: admin_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE admin_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE admin_users_id_seq OWNED BY admin_users.id;


--
-- Name: alerts_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE alerts_users (
    id integer NOT NULL,
    company_user_id integer,
    name character varying(255),
    version integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: alerts_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE alerts_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: alerts_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE alerts_users_id_seq OWNED BY alerts_users.id;


--
-- Name: areas; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE areas (
    id integer NOT NULL,
    name character varying(255),
    description text,
    active boolean DEFAULT true,
    company_id integer,
    created_by_id integer,
    updated_by_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    common_denominators text,
    common_denominators_locations integer[] DEFAULT '{}'::integer[]
);


--
-- Name: areas_campaigns; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE areas_campaigns (
    id integer NOT NULL,
    area_id integer,
    campaign_id integer,
    exclusions integer[] DEFAULT '{}'::integer[],
    inclusions integer[] DEFAULT '{}'::integer[]
);


--
-- Name: areas_campaigns_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE areas_campaigns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: areas_campaigns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE areas_campaigns_id_seq OWNED BY areas_campaigns.id;


--
-- Name: areas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE areas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: areas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE areas_id_seq OWNED BY areas.id;


--
-- Name: asset_downloads; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE asset_downloads (
    id integer NOT NULL,
    uid character varying(255),
    assets_ids text,
    aasm_state character varying(255),
    file_file_name character varying(255),
    file_content_type character varying(255),
    file_file_size integer,
    file_updated_at timestamp without time zone,
    user_id integer,
    last_downloaded timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: asset_downloads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE asset_downloads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: asset_downloads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE asset_downloads_id_seq OWNED BY asset_downloads.id;


--
-- Name: attached_assets; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE attached_assets (
    id integer NOT NULL,
    file_file_name character varying(255),
    file_content_type character varying(255),
    file_file_size integer,
    file_updated_at timestamp without time zone,
    asset_type character varying(255),
    attachable_id integer,
    attachable_type character varying(255),
    created_by_id integer,
    updated_by_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    active boolean DEFAULT true,
    direct_upload_url character varying(255),
    processed boolean DEFAULT false NOT NULL,
    rating integer DEFAULT 0,
    folder_id integer
);


--
-- Name: attached_assets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE attached_assets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attached_assets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE attached_assets_id_seq OWNED BY attached_assets.id;


--
-- Name: attached_assets_tags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE attached_assets_tags (
    id integer NOT NULL,
    attached_asset_id integer,
    tag_id integer
);


--
-- Name: attached_assets_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE attached_assets_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attached_assets_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE attached_assets_tags_id_seq OWNED BY attached_assets_tags.id;


--
-- Name: brand_ambassadors_visits; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE brand_ambassadors_visits (
    id integer NOT NULL,
    company_id integer,
    company_user_id integer,
    start_date date,
    end_date date,
    active boolean DEFAULT true,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    description text,
    visit_type character varying(255),
    area_id integer,
    city character varying(255),
    campaign_id integer
);


--
-- Name: brand_ambassadors_visits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE brand_ambassadors_visits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: brand_ambassadors_visits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE brand_ambassadors_visits_id_seq OWNED BY brand_ambassadors_visits.id;


--
-- Name: brand_portfolios; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE brand_portfolios (
    id integer NOT NULL,
    name character varying(255),
    active boolean DEFAULT true,
    company_id integer,
    created_by_id integer,
    updated_by_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    description text
);


--
-- Name: brand_portfolios_brands; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE brand_portfolios_brands (
    id integer NOT NULL,
    brand_id integer,
    brand_portfolio_id integer
);


--
-- Name: brand_portfolios_brands_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE brand_portfolios_brands_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: brand_portfolios_brands_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE brand_portfolios_brands_id_seq OWNED BY brand_portfolios_brands.id;


--
-- Name: brand_portfolios_campaigns; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE brand_portfolios_campaigns (
    id integer NOT NULL,
    brand_portfolio_id integer,
    campaign_id integer
);


--
-- Name: brand_portfolios_campaigns_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE brand_portfolios_campaigns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: brand_portfolios_campaigns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE brand_portfolios_campaigns_id_seq OWNED BY brand_portfolios_campaigns.id;


--
-- Name: brand_portfolios_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE brand_portfolios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: brand_portfolios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE brand_portfolios_id_seq OWNED BY brand_portfolios.id;


--
-- Name: brands; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE brands (
    id integer NOT NULL,
    name character varying(255),
    created_by_id integer,
    updated_by_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    company_id integer,
    active boolean DEFAULT true
);


--
-- Name: brands_campaigns; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE brands_campaigns (
    id integer NOT NULL,
    brand_id integer,
    campaign_id integer
);


--
-- Name: brands_campaigns_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE brands_campaigns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: brands_campaigns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE brands_campaigns_id_seq OWNED BY brands_campaigns.id;


--
-- Name: brands_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE brands_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: brands_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE brands_id_seq OWNED BY brands.id;


--
-- Name: campaigns; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE campaigns (
    id integer NOT NULL,
    name character varying(255),
    description text,
    aasm_state character varying(255),
    created_by_id integer,
    updated_by_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    company_id integer,
    first_event_id integer,
    last_event_id integer,
    first_event_at timestamp without time zone,
    last_event_at timestamp without time zone,
    start_date date,
    end_date date,
    survey_brand_ids integer[] DEFAULT '{}'::integer[],
    modules text,
    color character varying(30)
);


--
-- Name: memberships; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE memberships (
    id integer NOT NULL,
    company_user_id integer,
    memberable_id integer,
    memberable_type character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    parent_id integer,
    parent_type character varying(255)
);


--
-- Name: campaign_users; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW campaign_users AS
 SELECT memberships.memberable_id AS campaign_id,
    memberships.company_user_id,
        CASE
            WHEN ((campaigns.aasm_state)::text = 'active'::text) THEN true
            ELSE false
        END AS active,
    'campaign'::text AS via
   FROM (memberships
     JOIN campaigns ON (((campaigns.id = memberships.memberable_id) AND ((memberships.memberable_type)::text = 'Campaign'::text))))
UNION
 SELECT brands_campaigns.campaign_id,
    memberships.company_user_id,
    (brands.active AND ((campaigns.aasm_state)::text = 'active'::text)) AS active,
    'brand'::text AS via
   FROM (((brands_campaigns
     JOIN memberships ON (((memberships.memberable_id = brands_campaigns.brand_id) AND ((memberships.memberable_type)::text = 'Brand'::text))))
     JOIN campaigns ON ((campaigns.id = brands_campaigns.campaign_id)))
     JOIN brands ON (((brands.id = brands_campaigns.brand_id) AND (brands.active = true))))
UNION
 SELECT brand_portfolios_campaigns.campaign_id,
    memberships.company_user_id,
    (brand_portfolios.active AND ((campaigns.aasm_state)::text = 'active'::text)) AS active,
    'brand'::text AS via
   FROM (((brand_portfolios_campaigns
     JOIN memberships ON (((memberships.memberable_id = brand_portfolios_campaigns.brand_portfolio_id) AND ((memberships.memberable_type)::text = 'Brand'::text))))
     JOIN campaigns ON ((campaigns.id = brand_portfolios_campaigns.campaign_id)))
     JOIN brand_portfolios ON (((brand_portfolios.id = brand_portfolios_campaigns.brand_portfolio_id) AND (brand_portfolios.active = true))));


--
-- Name: campaigns_date_ranges; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE campaigns_date_ranges (
    id integer NOT NULL,
    campaign_id integer,
    date_range_id integer
);


--
-- Name: campaigns_date_ranges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE campaigns_date_ranges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: campaigns_date_ranges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE campaigns_date_ranges_id_seq OWNED BY campaigns_date_ranges.id;


--
-- Name: campaigns_day_parts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE campaigns_day_parts (
    id integer NOT NULL,
    campaign_id integer,
    day_part_id integer
);


--
-- Name: campaigns_day_parts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE campaigns_day_parts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: campaigns_day_parts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE campaigns_day_parts_id_seq OWNED BY campaigns_day_parts.id;


--
-- Name: campaigns_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE campaigns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: campaigns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE campaigns_id_seq OWNED BY campaigns.id;


--
-- Name: campaigns_teams; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE campaigns_teams (
    id integer NOT NULL,
    campaign_id integer,
    team_id integer
);


--
-- Name: campaigns_teams_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE campaigns_teams_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: campaigns_teams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE campaigns_teams_id_seq OWNED BY campaigns_teams.id;


--
-- Name: comments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE comments (
    id integer NOT NULL,
    commentable_id integer,
    commentable_type character varying(255),
    content text,
    created_by_id integer,
    updated_by_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE comments_id_seq OWNED BY comments.id;


--
-- Name: companies; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE companies (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    timezone_support boolean,
    settings hstore
);


--
-- Name: companies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE companies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: companies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE companies_id_seq OWNED BY companies.id;


--
-- Name: company_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE company_users (
    id integer NOT NULL,
    company_id integer,
    user_id integer,
    role_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    active boolean DEFAULT true,
    last_activity_at timestamp without time zone,
    notifications_settings character varying(255)[] DEFAULT '{}'::character varying[],
    last_activity_mobile_at timestamp without time zone,
    tableau_username character varying(255)
);


--
-- Name: company_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE company_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: company_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE company_users_id_seq OWNED BY company_users.id;


--
-- Name: contact_events; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE contact_events (
    id integer NOT NULL,
    event_id integer,
    contactable_id integer,
    contactable_type character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: contact_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contact_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contact_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contact_events_id_seq OWNED BY contact_events.id;


--
-- Name: contacts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE contacts (
    id integer NOT NULL,
    company_id integer,
    first_name character varying(255),
    last_name character varying(255),
    title character varying(255),
    email character varying(255),
    phone_number character varying(255),
    street1 character varying(255),
    street2 character varying(255),
    country character varying(255),
    state character varying(255),
    city character varying(255),
    zip_code character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contacts_id_seq OWNED BY contacts.id;


--
-- Name: custom_filters; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE custom_filters (
    id integer NOT NULL,
    name character varying(255),
    apply_to character varying(255),
    filters text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    owner_id integer,
    owner_type character varying(255),
    default_view boolean DEFAULT false,
    category_id integer
);


--
-- Name: custom_filters_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE custom_filters_categories (
    id integer NOT NULL,
    name character varying(255),
    company_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: custom_filters_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE custom_filters_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_filters_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE custom_filters_categories_id_seq OWNED BY custom_filters_categories.id;


--
-- Name: custom_filters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE custom_filters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_filters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE custom_filters_id_seq OWNED BY custom_filters.id;


--
-- Name: data_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE data_migrations (
    id integer NOT NULL,
    remote_id integer,
    remote_type character varying(255),
    local_id integer,
    local_type character varying(255),
    company_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: data_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE data_migrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE data_migrations_id_seq OWNED BY data_migrations.id;


--
-- Name: date_items; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE date_items (
    id integer NOT NULL,
    date_range_id integer,
    start_date date,
    end_date date,
    recurrence boolean DEFAULT false,
    recurrence_type character varying(255),
    recurrence_period integer,
    recurrence_days character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: date_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE date_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: date_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE date_items_id_seq OWNED BY date_items.id;


--
-- Name: date_ranges; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE date_ranges (
    id integer NOT NULL,
    name character varying(255),
    description text,
    active boolean DEFAULT true,
    company_id integer,
    created_by_id integer,
    updated_by_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: date_ranges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE date_ranges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: date_ranges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE date_ranges_id_seq OWNED BY date_ranges.id;


--
-- Name: day_items; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE day_items (
    id integer NOT NULL,
    day_part_id integer,
    start_time time without time zone,
    end_time time without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: day_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE day_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: day_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE day_items_id_seq OWNED BY day_items.id;


--
-- Name: day_parts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE day_parts (
    id integer NOT NULL,
    name character varying(255),
    description text,
    active boolean DEFAULT true,
    company_id integer,
    created_by_id integer,
    updated_by_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: day_parts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE day_parts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: day_parts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE day_parts_id_seq OWNED BY day_parts.id;


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE delayed_jobs (
    id integer NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    handler text NOT NULL,
    last_error text,
    run_at timestamp without time zone,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying(255),
    queue character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE delayed_jobs_id_seq OWNED BY delayed_jobs.id;


--
-- Name: document_folders; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE document_folders (
    id integer NOT NULL,
    name character varying(255),
    parent_id integer,
    active boolean DEFAULT true,
    documents_count integer,
    company_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    folderable_id integer,
    folderable_type character varying(255)
);


--
-- Name: document_folders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE document_folders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: document_folders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE document_folders_id_seq OWNED BY document_folders.id;


--
-- Name: event_data; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE event_data (
    id integer NOT NULL,
    event_id integer,
    impressions integer DEFAULT 0,
    interactions integer DEFAULT 0,
    samples integer DEFAULT 0,
    gender_female numeric(5,2) DEFAULT 0,
    gender_male numeric(5,2) DEFAULT 0,
    ethnicity_asian numeric(5,2) DEFAULT 0,
    ethnicity_black numeric(5,2) DEFAULT 0,
    ethnicity_hispanic numeric(5,2) DEFAULT 0,
    ethnicity_native_american numeric(5,2) DEFAULT 0,
    ethnicity_white numeric(5,2) DEFAULT 0,
    spent numeric(10,2) DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: event_data_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE event_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: event_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE event_data_id_seq OWNED BY event_data.id;


--
-- Name: event_expenses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE event_expenses (
    id integer NOT NULL,
    event_id integer,
    name character varying(255),
    amount numeric(9,2) DEFAULT 0,
    created_by_id integer,
    updated_by_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    brand_id integer
);


--
-- Name: event_expenses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE event_expenses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: event_expenses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE event_expenses_id_seq OWNED BY event_expenses.id;


--
-- Name: events; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE events (
    id integer NOT NULL,
    campaign_id integer,
    company_id integer,
    start_at timestamp without time zone,
    end_at timestamp without time zone,
    aasm_state character varying(255),
    created_by_id integer,
    updated_by_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    active boolean DEFAULT true,
    place_id integer,
    promo_hours numeric(6,2) DEFAULT 0,
    reject_reason text,
    timezone character varying(255),
    local_start_at timestamp without time zone,
    local_end_at timestamp without time zone,
    description text
);


--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE events_id_seq OWNED BY events.id;


--
-- Name: filter_settings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE filter_settings (
    id integer NOT NULL,
    company_user_id integer,
    apply_to character varying(255),
    settings text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: filter_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE filter_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: filter_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE filter_settings_id_seq OWNED BY filter_settings.id;


--
-- Name: form_field_options; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE form_field_options (
    id integer NOT NULL,
    form_field_id integer,
    name character varying(255),
    ordering integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    option_type character varying(255)
);


--
-- Name: form_field_options_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE form_field_options_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: form_field_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE form_field_options_id_seq OWNED BY form_field_options.id;


--
-- Name: form_field_results; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE form_field_results (
    id integer NOT NULL,
    form_field_id integer,
    value text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    hash_value hstore,
    scalar_value numeric(10,2) DEFAULT 0,
    resultable_id integer,
    resultable_type character varying(255)
);


--
-- Name: form_field_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE form_field_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: form_field_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE form_field_results_id_seq OWNED BY form_field_results.id;


--
-- Name: form_fields; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE form_fields (
    id integer NOT NULL,
    fieldable_id integer,
    fieldable_type character varying(255),
    name character varying(255),
    type character varying(255),
    settings text,
    ordering integer,
    required boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    kpi_id integer
);


--
-- Name: form_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE form_fields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: form_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE form_fields_id_seq OWNED BY form_fields.id;


--
-- Name: goals; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE goals (
    id integer NOT NULL,
    kpi_id integer,
    kpis_segment_id integer,
    value numeric,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    goalable_id integer,
    goalable_type character varying(255),
    parent_id integer,
    parent_type character varying(255),
    title character varying(255),
    start_date date,
    due_date date,
    activity_type_id integer
);


--
-- Name: goals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE goals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: goals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE goals_id_seq OWNED BY goals.id;


--
-- Name: invite_rsvps; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE invite_rsvps (
    id integer NOT NULL,
    invite_id integer,
    registrant_id integer,
    date_added date,
    email character varying(255),
    mobile_phone character varying(255),
    mobile_signup boolean,
    first_name character varying(255),
    last_name character varying(255),
    attended_previous_bartender_ball character varying(255),
    opt_in_to_future_communication boolean,
    primary_registrant_id integer,
    bartender_how_long character varying(255),
    bartender_role character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: invite_rsvps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE invite_rsvps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invite_rsvps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE invite_rsvps_id_seq OWNED BY invite_rsvps.id;


--
-- Name: invites; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE invites (
    id integer NOT NULL,
    event_id integer,
    venue_id integer,
    market character varying(255),
    invitees integer DEFAULT 0,
    rsvps_count integer DEFAULT 0,
    attendees integer DEFAULT 0,
    final_date date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    active boolean DEFAULT true,
    area_id integer
);


--
-- Name: invites_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE invites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE invites_id_seq OWNED BY invites.id;


--
-- Name: kpi_reports; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE kpi_reports (
    id integer NOT NULL,
    company_user_id integer,
    params text,
    aasm_state character varying(255),
    progress integer,
    file_file_name character varying(255),
    file_content_type character varying(255),
    file_file_size integer,
    file_updated_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: kpi_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE kpi_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: kpi_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE kpi_reports_id_seq OWNED BY kpi_reports.id;


--
-- Name: kpis; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE kpis (
    id integer NOT NULL,
    name character varying(255),
    description text,
    kpi_type character varying(255),
    capture_mechanism character varying(255),
    company_id integer,
    created_by_id integer,
    updated_by_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    module character varying(255) DEFAULT 'custom'::character varying NOT NULL,
    ordering integer
);


--
-- Name: kpis_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE kpis_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: kpis_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE kpis_id_seq OWNED BY kpis.id;


--
-- Name: kpis_segments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE kpis_segments (
    id integer NOT NULL,
    kpi_id integer,
    text character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ordering integer
);


--
-- Name: kpis_segments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE kpis_segments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: kpis_segments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE kpis_segments_id_seq OWNED BY kpis_segments.id;


--
-- Name: legacy_accounts; Type: FOREIGN TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE FOREIGN TABLE legacy_accounts (
    id integer NOT NULL,
    name character varying(255),
    td_linx_code character varying(255),
    url character varying(255),
    description text,
    active boolean DEFAULT true,
    creator_id integer,
    updater_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    neighborhood character varying(255)
)
SERVER legacy_prod
OPTIONS (
    table_name 'accounts'
);


--
-- Name: legacy_addresses; Type: FOREIGN TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE FOREIGN TABLE legacy_addresses (
    id integer NOT NULL,
    addressable_id integer,
    addressable_type character varying(255),
    street_address character varying(255),
    supplemental_address character varying(255),
    city character varying(255),
    state character varying(255),
    postal_code integer,
    active boolean DEFAULT true,
    creator_id integer,
    updater_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
)
SERVER legacy_prod
OPTIONS (
    table_name 'addresses'
);


--
-- Name: legacy_events; Type: FOREIGN TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE FOREIGN TABLE legacy_events (
    id integer NOT NULL,
    program_id integer,
    account_id integer,
    start_at timestamp without time zone,
    end_at timestamp without time zone,
    notes text,
    staff character varying(255),
    deactivation_reason character varying(255),
    event_type_id integer,
    confirmed boolean DEFAULT true,
    active boolean DEFAULT true,
    creator_id integer,
    updater_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    drink_special boolean DEFAULT false NOT NULL,
    market_id integer
)
SERVER legacy_prod
OPTIONS (
    table_name 'events'
);


--
-- Name: legacy_programs; Type: FOREIGN TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE FOREIGN TABLE legacy_programs (
    id integer NOT NULL,
    name character varying(255),
    brand_id integer,
    events_based boolean DEFAULT true,
    hours_based boolean DEFAULT false,
    managed_bar_night boolean DEFAULT true,
    brand_ambassador boolean DEFAULT false,
    active boolean DEFAULT true,
    creator_id integer,
    updater_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
)
SERVER legacy_prod
OPTIONS (
    table_name 'programs'
);


--
-- Name: list_exports; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE list_exports (
    id integer NOT NULL,
    params text,
    export_format character varying(255),
    aasm_state character varying(255),
    file_file_name character varying(255),
    file_content_type character varying(255),
    file_file_size integer,
    file_updated_at timestamp without time zone,
    company_user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    controller character varying(255),
    progress integer DEFAULT 0,
    url_options text
);


--
-- Name: list_exports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE list_exports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: list_exports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE list_exports_id_seq OWNED BY list_exports.id;


--
-- Name: locations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE locations (
    id integer NOT NULL,
    path character varying(500)
);


--
-- Name: locations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE locations_id_seq OWNED BY locations.id;


--
-- Name: locations_places; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE locations_places (
    id integer NOT NULL,
    location_id integer,
    place_id integer
);


--
-- Name: locations_places_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE locations_places_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: locations_places_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE locations_places_id_seq OWNED BY locations_places.id;


--
-- Name: marques; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE marques (
    id integer NOT NULL,
    brand_id integer,
    name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: marques_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE marques_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: marques_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE marques_id_seq OWNED BY marques.id;


--
-- Name: memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE memberships_id_seq OWNED BY memberships.id;


--
-- Name: neighborhoods; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE neighborhoods (
    gid integer NOT NULL,
    state character varying(2),
    county character varying(43),
    city character varying(64),
    name character varying(64),
    regionid numeric,
    geog geography(MultiPolygon,4326)
);


--
-- Name: neighborhoods_gid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE neighborhoods_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: neighborhoods_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE neighborhoods_gid_seq OWNED BY neighborhoods.gid;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE notifications (
    id integer NOT NULL,
    company_user_id integer,
    message character varying(255),
    level character varying(255),
    path text,
    icon character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    message_params text,
    extra_params text,
    params hstore
);


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE notifications_id_seq OWNED BY notifications.id;


--
-- Name: permissions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE permissions (
    id integer NOT NULL,
    role_id integer,
    action character varying(255),
    subject_class character varying(255),
    subject_id character varying(255),
    mode character varying(255) DEFAULT 'none'::character varying
);


--
-- Name: permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE permissions_id_seq OWNED BY permissions.id;


--
-- Name: placeables; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE placeables (
    id integer NOT NULL,
    place_id integer,
    placeable_id integer,
    placeable_type character varying(255)
);


--
-- Name: placeables_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE placeables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: placeables_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE placeables_id_seq OWNED BY placeables.id;


--
-- Name: places; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE places (
    id integer NOT NULL,
    name character varying(255),
    reference character varying(400),
    place_id character varying(100),
    types character varying(255),
    formatted_address character varying(255),
    street_number character varying(255),
    route character varying(255),
    zipcode character varying(255),
    city character varying(255),
    state character varying(255),
    country character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    administrative_level_1 character varying(255),
    administrative_level_2 character varying(255),
    td_linx_code character varying(255),
    location_id integer,
    is_location boolean,
    price_level integer,
    phone_number character varying(255),
    neighborhoods character varying(255)[],
    lonlat geography(Point,4326),
    td_linx_confidence integer,
    merged_with_place_id integer
);


--
-- Name: places_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE places_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: places_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE places_id_seq OWNED BY places.id;


--
-- Name: read_marks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE read_marks (
    id integer NOT NULL,
    readable_id integer,
    user_id integer NOT NULL,
    readable_type character varying(20) NOT NULL,
    "timestamp" timestamp without time zone
);


--
-- Name: read_marks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE read_marks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: read_marks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE read_marks_id_seq OWNED BY read_marks.id;


--
-- Name: report_sharings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE report_sharings (
    id integer NOT NULL,
    report_id integer,
    shared_with_id integer,
    shared_with_type character varying(255)
);


--
-- Name: report_sharings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE report_sharings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: report_sharings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE report_sharings_id_seq OWNED BY report_sharings.id;


--
-- Name: reports; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE reports (
    id integer NOT NULL,
    company_id integer,
    name character varying(255),
    description text,
    active boolean DEFAULT true,
    created_by_id integer,
    updated_by_id integer,
    rows text,
    columns text,
    "values" text,
    filters text,
    sharing character varying(255) DEFAULT 'owner'::character varying
);


--
-- Name: reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE reports_id_seq OWNED BY reports.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE roles (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    company_id integer,
    active boolean DEFAULT true,
    description text,
    is_admin boolean DEFAULT false
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE roles_id_seq OWNED BY roles.id;


--
-- Name: satisfaction_surveys; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE satisfaction_surveys (
    id integer NOT NULL,
    company_user_id integer,
    session_id character varying(255),
    rating character varying(255),
    feedback text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: satisfaction_surveys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE satisfaction_surveys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: satisfaction_surveys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE satisfaction_surveys_id_seq OWNED BY satisfaction_surveys.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sessions (
    id integer NOT NULL,
    session_id character varying(255) NOT NULL,
    data text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sessions_id_seq OWNED BY sessions.id;


--
-- Name: surveys; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE surveys (
    id integer NOT NULL,
    event_id integer,
    created_by_id integer,
    updated_by_id integer,
    active boolean DEFAULT true,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: surveys_answers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE surveys_answers (
    id integer NOT NULL,
    survey_id integer,
    kpi_id integer,
    question_id integer,
    brand_id integer,
    answer text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: surveys_answers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE surveys_answers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: surveys_answers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE surveys_answers_id_seq OWNED BY surveys_answers.id;


--
-- Name: surveys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE surveys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: surveys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE surveys_id_seq OWNED BY surveys.id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tags (
    id integer NOT NULL,
    name character varying(255),
    company_id integer,
    created_by_id integer,
    updated_by_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tags_id_seq OWNED BY tags.id;


--
-- Name: tasks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tasks (
    id integer NOT NULL,
    event_id integer,
    title character varying(255),
    due_at timestamp without time zone,
    completed boolean DEFAULT false,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    created_by_id integer,
    updated_by_id integer,
    active boolean DEFAULT true,
    company_user_id integer
);


--
-- Name: tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tasks_id_seq OWNED BY tasks.id;


--
-- Name: tdlinx_codes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tdlinx_codes (
    td_linx_code character varying,
    name character varying,
    street character varying,
    city character varying,
    state character varying,
    zipcode character varying
);


--
-- Name: teamings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE teamings (
    id integer NOT NULL,
    team_id integer,
    teamable_id integer,
    teamable_type character varying(255)
);


--
-- Name: teamings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE teamings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: teamings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE teamings_id_seq OWNED BY teamings.id;


--
-- Name: teams; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE teams (
    id integer NOT NULL,
    name character varying(255),
    description text,
    created_by_id integer,
    updated_by_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    active boolean DEFAULT true,
    company_id integer
);


--
-- Name: teams_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE teams_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: teams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE teams_id_seq OWNED BY teams.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    first_name character varying(255),
    last_name character varying(255),
    email character varying(255) DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying(255) DEFAULT ''::character varying,
    reset_password_token character varying(255),
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying(255),
    last_sign_in_ip character varying(255),
    confirmation_token character varying(255),
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    unconfirmed_email character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    country character varying(4),
    state character varying(255),
    city character varying(255),
    created_by_id integer,
    updated_by_id integer,
    invitation_token character varying(255),
    invitation_sent_at timestamp without time zone,
    invitation_accepted_at timestamp without time zone,
    invitation_limit integer,
    invited_by_id integer,
    invited_by_type character varying(255),
    current_company_id integer,
    time_zone character varying(255),
    detected_time_zone character varying(255),
    phone_number character varying(255),
    street_address character varying(255),
    unit_number character varying(255),
    zip_code character varying(255),
    authentication_token character varying(255),
    invitation_created_at timestamp without time zone,
    avatar_file_name character varying(255),
    avatar_content_type character varying(255),
    avatar_file_size integer,
    avatar_updated_at timestamp without time zone,
    phone_number_verified boolean,
    phone_number_verification character varying(255)
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: venues; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE venues (
    id integer NOT NULL,
    company_id integer,
    place_id integer,
    events_count integer,
    promo_hours numeric(8,2) DEFAULT 0,
    impressions integer,
    interactions integer,
    sampled integer,
    spent numeric(10,2) DEFAULT 0,
    score integer,
    avg_impressions numeric(8,2) DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    avg_impressions_hour numeric(6,2) DEFAULT 0,
    avg_impressions_cost numeric(8,2) DEFAULT 0,
    score_impressions integer,
    score_cost integer,
    score_dirty boolean DEFAULT false,
    jameson_locals boolean DEFAULT false,
    top_venue boolean DEFAULT false
);


--
-- Name: venues_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE venues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: venues_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE venues_id_seq OWNED BY venues.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY active_admin_comments ALTER COLUMN id SET DEFAULT nextval('active_admin_comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY activities ALTER COLUMN id SET DEFAULT nextval('activities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_type_campaigns ALTER COLUMN id SET DEFAULT nextval('activity_type_campaigns_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_types ALTER COLUMN id SET DEFAULT nextval('activity_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY admin_users ALTER COLUMN id SET DEFAULT nextval('admin_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY alerts_users ALTER COLUMN id SET DEFAULT nextval('alerts_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY areas ALTER COLUMN id SET DEFAULT nextval('areas_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY areas_campaigns ALTER COLUMN id SET DEFAULT nextval('areas_campaigns_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY asset_downloads ALTER COLUMN id SET DEFAULT nextval('asset_downloads_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY attached_assets ALTER COLUMN id SET DEFAULT nextval('attached_assets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY attached_assets_tags ALTER COLUMN id SET DEFAULT nextval('attached_assets_tags_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY brand_ambassadors_visits ALTER COLUMN id SET DEFAULT nextval('brand_ambassadors_visits_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY brand_portfolios ALTER COLUMN id SET DEFAULT nextval('brand_portfolios_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY brand_portfolios_brands ALTER COLUMN id SET DEFAULT nextval('brand_portfolios_brands_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY brand_portfolios_campaigns ALTER COLUMN id SET DEFAULT nextval('brand_portfolios_campaigns_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY brands ALTER COLUMN id SET DEFAULT nextval('brands_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY brands_campaigns ALTER COLUMN id SET DEFAULT nextval('brands_campaigns_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY campaigns ALTER COLUMN id SET DEFAULT nextval('campaigns_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY campaigns_date_ranges ALTER COLUMN id SET DEFAULT nextval('campaigns_date_ranges_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY campaigns_day_parts ALTER COLUMN id SET DEFAULT nextval('campaigns_day_parts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY campaigns_teams ALTER COLUMN id SET DEFAULT nextval('campaigns_teams_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY comments ALTER COLUMN id SET DEFAULT nextval('comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY companies ALTER COLUMN id SET DEFAULT nextval('companies_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY company_users ALTER COLUMN id SET DEFAULT nextval('company_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY contact_events ALTER COLUMN id SET DEFAULT nextval('contact_events_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY contacts ALTER COLUMN id SET DEFAULT nextval('contacts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_filters ALTER COLUMN id SET DEFAULT nextval('custom_filters_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_filters_categories ALTER COLUMN id SET DEFAULT nextval('custom_filters_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY data_migrations ALTER COLUMN id SET DEFAULT nextval('data_migrations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY date_items ALTER COLUMN id SET DEFAULT nextval('date_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY date_ranges ALTER COLUMN id SET DEFAULT nextval('date_ranges_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY day_items ALTER COLUMN id SET DEFAULT nextval('day_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY day_parts ALTER COLUMN id SET DEFAULT nextval('day_parts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY delayed_jobs ALTER COLUMN id SET DEFAULT nextval('delayed_jobs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY document_folders ALTER COLUMN id SET DEFAULT nextval('document_folders_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY event_data ALTER COLUMN id SET DEFAULT nextval('event_data_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY event_expenses ALTER COLUMN id SET DEFAULT nextval('event_expenses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY events ALTER COLUMN id SET DEFAULT nextval('events_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY filter_settings ALTER COLUMN id SET DEFAULT nextval('filter_settings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY form_field_options ALTER COLUMN id SET DEFAULT nextval('form_field_options_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY form_field_results ALTER COLUMN id SET DEFAULT nextval('form_field_results_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY form_fields ALTER COLUMN id SET DEFAULT nextval('form_fields_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY goals ALTER COLUMN id SET DEFAULT nextval('goals_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY invite_rsvps ALTER COLUMN id SET DEFAULT nextval('invite_rsvps_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY invites ALTER COLUMN id SET DEFAULT nextval('invites_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY kpi_reports ALTER COLUMN id SET DEFAULT nextval('kpi_reports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY kpis ALTER COLUMN id SET DEFAULT nextval('kpis_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY kpis_segments ALTER COLUMN id SET DEFAULT nextval('kpis_segments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY list_exports ALTER COLUMN id SET DEFAULT nextval('list_exports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY locations ALTER COLUMN id SET DEFAULT nextval('locations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY locations_places ALTER COLUMN id SET DEFAULT nextval('locations_places_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY marques ALTER COLUMN id SET DEFAULT nextval('marques_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY memberships ALTER COLUMN id SET DEFAULT nextval('memberships_id_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY neighborhoods ALTER COLUMN gid SET DEFAULT nextval('neighborhoods_gid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY notifications ALTER COLUMN id SET DEFAULT nextval('notifications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY permissions ALTER COLUMN id SET DEFAULT nextval('permissions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY placeables ALTER COLUMN id SET DEFAULT nextval('placeables_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY places ALTER COLUMN id SET DEFAULT nextval('places_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY read_marks ALTER COLUMN id SET DEFAULT nextval('read_marks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY report_sharings ALTER COLUMN id SET DEFAULT nextval('report_sharings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY reports ALTER COLUMN id SET DEFAULT nextval('reports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY roles ALTER COLUMN id SET DEFAULT nextval('roles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY satisfaction_surveys ALTER COLUMN id SET DEFAULT nextval('satisfaction_surveys_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sessions ALTER COLUMN id SET DEFAULT nextval('sessions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY surveys ALTER COLUMN id SET DEFAULT nextval('surveys_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY surveys_answers ALTER COLUMN id SET DEFAULT nextval('surveys_answers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tags ALTER COLUMN id SET DEFAULT nextval('tags_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tasks ALTER COLUMN id SET DEFAULT nextval('tasks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY teamings ALTER COLUMN id SET DEFAULT nextval('teamings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY teams ALTER COLUMN id SET DEFAULT nextval('teams_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY venues ALTER COLUMN id SET DEFAULT nextval('venues_id_seq'::regclass);


--
-- Name: activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY activities
    ADD CONSTRAINT activities_pkey PRIMARY KEY (id);


--
-- Name: activity_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY form_field_results
    ADD CONSTRAINT activity_results_pkey PRIMARY KEY (id);


--
-- Name: activity_type_campaigns_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY activity_type_campaigns
    ADD CONSTRAINT activity_type_campaigns_pkey PRIMARY KEY (id);


--
-- Name: activity_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY activity_types
    ADD CONSTRAINT activity_types_pkey PRIMARY KEY (id);


--
-- Name: admin_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY active_admin_comments
    ADD CONSTRAINT admin_notes_pkey PRIMARY KEY (id);


--
-- Name: admin_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY admin_users
    ADD CONSTRAINT admin_users_pkey PRIMARY KEY (id);


--
-- Name: alerts_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY alerts_users
    ADD CONSTRAINT alerts_users_pkey PRIMARY KEY (id);


--
-- Name: areas_campaigns_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY areas_campaigns
    ADD CONSTRAINT areas_campaigns_pkey PRIMARY KEY (id);


--
-- Name: areas_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY areas
    ADD CONSTRAINT areas_pkey PRIMARY KEY (id);


--
-- Name: asset_downloads_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY asset_downloads
    ADD CONSTRAINT asset_downloads_pkey PRIMARY KEY (id);


--
-- Name: attached_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY attached_assets
    ADD CONSTRAINT attached_assets_pkey PRIMARY KEY (id);


--
-- Name: attached_assets_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY attached_assets_tags
    ADD CONSTRAINT attached_assets_tags_pkey PRIMARY KEY (id);


--
-- Name: brand_ambassadors_visits_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY brand_ambassadors_visits
    ADD CONSTRAINT brand_ambassadors_visits_pkey PRIMARY KEY (id);


--
-- Name: brand_portfolios_brands_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY brand_portfolios_brands
    ADD CONSTRAINT brand_portfolios_brands_pkey PRIMARY KEY (id);


--
-- Name: brand_portfolios_campaigns_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY brand_portfolios_campaigns
    ADD CONSTRAINT brand_portfolios_campaigns_pkey PRIMARY KEY (id);


--
-- Name: brand_portfolios_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY brand_portfolios
    ADD CONSTRAINT brand_portfolios_pkey PRIMARY KEY (id);


--
-- Name: brands_campaigns_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY brands_campaigns
    ADD CONSTRAINT brands_campaigns_pkey PRIMARY KEY (id);


--
-- Name: brands_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY brands
    ADD CONSTRAINT brands_pkey PRIMARY KEY (id);


--
-- Name: campaigns_date_ranges_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY campaigns_date_ranges
    ADD CONSTRAINT campaigns_date_ranges_pkey PRIMARY KEY (id);


--
-- Name: campaigns_day_parts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY campaigns_day_parts
    ADD CONSTRAINT campaigns_day_parts_pkey PRIMARY KEY (id);


--
-- Name: campaigns_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY campaigns
    ADD CONSTRAINT campaigns_pkey PRIMARY KEY (id);


--
-- Name: campaigns_teams_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY campaigns_teams
    ADD CONSTRAINT campaigns_teams_pkey PRIMARY KEY (id);


--
-- Name: comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: companies_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY companies
    ADD CONSTRAINT companies_pkey PRIMARY KEY (id);


--
-- Name: company_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY company_users
    ADD CONSTRAINT company_users_pkey PRIMARY KEY (id);


--
-- Name: contact_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contact_events
    ADD CONSTRAINT contact_events_pkey PRIMARY KEY (id);


--
-- Name: contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- Name: custom_filters_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY custom_filters_categories
    ADD CONSTRAINT custom_filters_categories_pkey PRIMARY KEY (id);


--
-- Name: custom_filters_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY custom_filters
    ADD CONSTRAINT custom_filters_pkey PRIMARY KEY (id);


--
-- Name: data_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY data_migrations
    ADD CONSTRAINT data_migrations_pkey PRIMARY KEY (id);


--
-- Name: date_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY date_items
    ADD CONSTRAINT date_items_pkey PRIMARY KEY (id);


--
-- Name: date_ranges_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY date_ranges
    ADD CONSTRAINT date_ranges_pkey PRIMARY KEY (id);


--
-- Name: day_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY day_items
    ADD CONSTRAINT day_items_pkey PRIMARY KEY (id);


--
-- Name: day_parts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY day_parts
    ADD CONSTRAINT day_parts_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: document_folders_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY document_folders
    ADD CONSTRAINT document_folders_pkey PRIMARY KEY (id);


--
-- Name: event_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY event_data
    ADD CONSTRAINT event_data_pkey PRIMARY KEY (id);


--
-- Name: event_expenses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY event_expenses
    ADD CONSTRAINT event_expenses_pkey PRIMARY KEY (id);


--
-- Name: events_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: filter_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY filter_settings
    ADD CONSTRAINT filter_settings_pkey PRIMARY KEY (id);


--
-- Name: form_field_options_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY form_field_options
    ADD CONSTRAINT form_field_options_pkey PRIMARY KEY (id);


--
-- Name: form_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY form_fields
    ADD CONSTRAINT form_fields_pkey PRIMARY KEY (id);


--
-- Name: goals_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY goals
    ADD CONSTRAINT goals_pkey PRIMARY KEY (id);


--
-- Name: invite_rsvps_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY invite_rsvps
    ADD CONSTRAINT invite_rsvps_pkey PRIMARY KEY (id);


--
-- Name: invites_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY invites
    ADD CONSTRAINT invites_pkey PRIMARY KEY (id);


--
-- Name: kpis_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY kpis
    ADD CONSTRAINT kpis_pkey PRIMARY KEY (id);


--
-- Name: kpisegments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY kpis_segments
    ADD CONSTRAINT kpisegments_pkey PRIMARY KEY (id);


--
-- Name: list_exports_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY list_exports
    ADD CONSTRAINT list_exports_pkey PRIMARY KEY (id);


--
-- Name: locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (id);


--
-- Name: locations_places_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY locations_places
    ADD CONSTRAINT locations_places_pkey PRIMARY KEY (id);


--
-- Name: marques_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY marques
    ADD CONSTRAINT marques_pkey PRIMARY KEY (id);


--
-- Name: memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY memberships
    ADD CONSTRAINT memberships_pkey PRIMARY KEY (id);


--
-- Name: neighborhoods_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY neighborhoods
    ADD CONSTRAINT neighborhoods_pkey PRIMARY KEY (gid);


--
-- Name: notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: placeables_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY placeables
    ADD CONSTRAINT placeables_pkey PRIMARY KEY (id);


--
-- Name: places_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY places
    ADD CONSTRAINT places_pkey PRIMARY KEY (id);


--
-- Name: read_marks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY read_marks
    ADD CONSTRAINT read_marks_pkey PRIMARY KEY (id);


--
-- Name: report_sharings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY report_sharings
    ADD CONSTRAINT report_sharings_pkey PRIMARY KEY (id);


--
-- Name: reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY kpi_reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- Name: reports_pkey1; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY reports
    ADD CONSTRAINT reports_pkey1 PRIMARY KEY (id);


--
-- Name: satisfaction_surveys_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY satisfaction_surveys
    ADD CONSTRAINT satisfaction_surveys_pkey PRIMARY KEY (id);


--
-- Name: sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: surveys_answers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY surveys_answers
    ADD CONSTRAINT surveys_answers_pkey PRIMARY KEY (id);


--
-- Name: surveys_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY surveys
    ADD CONSTRAINT surveys_pkey PRIMARY KEY (id);


--
-- Name: tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);


--
-- Name: teamings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY teamings
    ADD CONSTRAINT teamings_pkey PRIMARY KEY (id);


--
-- Name: teams_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);


--
-- Name: user_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT user_groups_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: venues_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY venues
    ADD CONSTRAINT venues_pkey PRIMARY KEY (id);


--
-- Name: brand_portfolio_unique_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX brand_portfolio_unique_idx ON brand_portfolios_brands USING btree (brand_id, brand_portfolio_id);


--
-- Name: delayed_jobs_priority; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX delayed_jobs_priority ON delayed_jobs USING btree (priority, run_at);


--
-- Name: index_active_admin_comments_on_author_type_and_author_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_active_admin_comments_on_author_type_and_author_id ON active_admin_comments USING btree (author_type, author_id);


--
-- Name: index_active_admin_comments_on_namespace; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_active_admin_comments_on_namespace ON active_admin_comments USING btree (namespace);


--
-- Name: index_activities_on_activitable_id_and_activitable_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_activities_on_activitable_id_and_activitable_type ON activities USING btree (activitable_id, activitable_type);


--
-- Name: index_activities_on_activity_type_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_activities_on_activity_type_id ON activities USING btree (activity_type_id);


--
-- Name: index_activities_on_company_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_activities_on_company_user_id ON activities USING btree (company_user_id);


--
-- Name: index_activity_results_on_form_field_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_results_on_form_field_id ON form_field_results USING btree (form_field_id);


--
-- Name: index_activity_results_on_hash_value; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_results_on_hash_value ON form_field_results USING gist (hash_value);


--
-- Name: index_activity_type_campaigns_on_activity_type_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_type_campaigns_on_activity_type_id ON activity_type_campaigns USING btree (activity_type_id);


--
-- Name: index_activity_type_campaigns_on_campaign_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_type_campaigns_on_campaign_id ON activity_type_campaigns USING btree (campaign_id);


--
-- Name: index_activity_types_on_company_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_types_on_company_id ON activity_types USING btree (company_id);


--
-- Name: index_admin_notes_on_resource_type_and_resource_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_admin_notes_on_resource_type_and_resource_id ON active_admin_comments USING btree (resource_type, resource_id);


--
-- Name: index_admin_users_on_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_admin_users_on_email ON admin_users USING btree (email);


--
-- Name: index_admin_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_admin_users_on_reset_password_token ON admin_users USING btree (reset_password_token);


--
-- Name: index_alerts_users_on_company_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_alerts_users_on_company_user_id ON alerts_users USING btree (company_user_id);


--
-- Name: index_areas_on_common_denominators_locations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_areas_on_common_denominators_locations ON areas USING gin (common_denominators_locations);


--
-- Name: index_areas_on_company_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_areas_on_company_id ON areas USING btree (company_id);


--
-- Name: index_asset_downloads_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_asset_downloads_on_user_id ON asset_downloads USING btree (user_id);


--
-- Name: index_attached_assets_on_attachable_type_and_attachable_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_attached_assets_on_attachable_type_and_attachable_id ON attached_assets USING btree (attachable_type, attachable_id);


--
-- Name: index_attached_assets_on_direct_upload_url; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_attached_assets_on_direct_upload_url ON attached_assets USING btree (direct_upload_url);


--
-- Name: index_attached_assets_on_folder_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_attached_assets_on_folder_id ON attached_assets USING btree (folder_id);


--
-- Name: index_attached_assets_tags_on_attached_asset_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_attached_assets_tags_on_attached_asset_id ON attached_assets_tags USING btree (attached_asset_id);


--
-- Name: index_attached_assets_tags_on_tag_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_attached_assets_tags_on_tag_id ON attached_assets_tags USING btree (tag_id);


--
-- Name: index_brand_ambassadors_visits_on_area_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_brand_ambassadors_visits_on_area_id ON brand_ambassadors_visits USING btree (area_id);


--
-- Name: index_brand_ambassadors_visits_on_campaign_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_brand_ambassadors_visits_on_campaign_id ON brand_ambassadors_visits USING btree (campaign_id);


--
-- Name: index_brand_ambassadors_visits_on_company_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_brand_ambassadors_visits_on_company_id ON brand_ambassadors_visits USING btree (company_id);


--
-- Name: index_brand_ambassadors_visits_on_company_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_brand_ambassadors_visits_on_company_user_id ON brand_ambassadors_visits USING btree (company_user_id);


--
-- Name: index_brand_portfolios_brands_on_brand_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_brand_portfolios_brands_on_brand_id ON brand_portfolios_brands USING btree (brand_id);


--
-- Name: index_brand_portfolios_brands_on_brand_portfolio_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_brand_portfolios_brands_on_brand_portfolio_id ON brand_portfolios_brands USING btree (brand_portfolio_id);


--
-- Name: index_brand_portfolios_campaigns_on_brand_portfolio_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_brand_portfolios_campaigns_on_brand_portfolio_id ON brand_portfolios_campaigns USING btree (brand_portfolio_id);


--
-- Name: index_brand_portfolios_campaigns_on_campaign_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_brand_portfolios_campaigns_on_campaign_id ON brand_portfolios_campaigns USING btree (campaign_id);


--
-- Name: index_brand_portfolios_on_company_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_brand_portfolios_on_company_id ON brand_portfolios USING btree (company_id);


--
-- Name: index_brands_campaigns_on_brand_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_brands_campaigns_on_brand_id ON brands_campaigns USING btree (brand_id);


--
-- Name: index_brands_campaigns_on_campaign_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_brands_campaigns_on_campaign_id ON brands_campaigns USING btree (campaign_id);


--
-- Name: index_brands_on_company_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_brands_on_company_id ON brands USING btree (company_id);


--
-- Name: index_campaigns_on_company_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_campaigns_on_company_id ON campaigns USING btree (company_id);


--
-- Name: index_campaigns_teams_on_campaign_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_campaigns_teams_on_campaign_id ON campaigns_teams USING btree (campaign_id);


--
-- Name: index_campaigns_teams_on_team_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_campaigns_teams_on_team_id ON campaigns_teams USING btree (team_id);


--
-- Name: index_comments_on_commentable_type_and_commentable_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_comments_on_commentable_type_and_commentable_id ON comments USING btree (commentable_type, commentable_id);


--
-- Name: index_comments_on_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_comments_on_created_at ON comments USING btree (created_at);


--
-- Name: index_company_users_on_company_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_company_users_on_company_id ON company_users USING btree (company_id);


--
-- Name: index_company_users_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_company_users_on_user_id ON company_users USING btree (user_id);


--
-- Name: index_contact_events_on_contactable_id_and_contactable_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_contact_events_on_contactable_id_and_contactable_type ON contact_events USING btree (contactable_id, contactable_type);


--
-- Name: index_contact_events_on_event_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_contact_events_on_event_id ON contact_events USING btree (event_id);


--
-- Name: index_custom_filters_categories_on_company_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_custom_filters_categories_on_company_id ON custom_filters_categories USING btree (company_id);


--
-- Name: index_document_folders_on_company_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_document_folders_on_company_id ON document_folders USING btree (company_id);


--
-- Name: index_document_folders_on_parent_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_document_folders_on_parent_id ON document_folders USING btree (parent_id);


--
-- Name: index_event_data_on_event_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_event_data_on_event_id ON event_data USING btree (event_id);


--
-- Name: index_event_expenses_on_brand_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_event_expenses_on_brand_id ON event_expenses USING btree (brand_id);


--
-- Name: index_event_expenses_on_event_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_event_expenses_on_event_id ON event_expenses USING btree (event_id);


--
-- Name: index_events_on_aasm_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_events_on_aasm_state ON events USING btree (aasm_state);


--
-- Name: index_events_on_campaign_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_events_on_campaign_id ON events USING btree (campaign_id);


--
-- Name: index_events_on_company_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_events_on_company_id ON events USING btree (company_id);


--
-- Name: index_events_on_place_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_events_on_place_id ON events USING btree (place_id);


--
-- Name: index_ff_results_on_resultable_and_form_field_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_ff_results_on_resultable_and_form_field_id ON form_field_results USING btree (resultable_id, resultable_type, form_field_id);


--
-- Name: index_filter_settings_on_company_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_filter_settings_on_company_user_id ON filter_settings USING btree (company_user_id);


--
-- Name: index_form_field_options_on_form_field_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_form_field_options_on_form_field_id ON form_field_options USING btree (form_field_id);


--
-- Name: index_form_field_options_on_form_field_id_and_option_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_form_field_options_on_form_field_id_and_option_type ON form_field_options USING btree (form_field_id, option_type);


--
-- Name: index_form_field_results_on_resultable_id_and_resultable_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_form_field_results_on_resultable_id_and_resultable_type ON form_field_results USING btree (resultable_id, resultable_type);


--
-- Name: index_form_fields_on_fieldable_id_and_fieldable_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_form_fields_on_fieldable_id_and_fieldable_type ON form_fields USING btree (fieldable_id, fieldable_type);


--
-- Name: index_goals_on_goalable_id_and_goalable_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_goals_on_goalable_id_and_goalable_type ON goals USING btree (goalable_id, goalable_type);


--
-- Name: index_goals_on_kpi_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_goals_on_kpi_id ON goals USING btree (kpi_id);


--
-- Name: index_goals_on_kpis_segment_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_goals_on_kpis_segment_id ON goals USING btree (kpis_segment_id);


--
-- Name: index_invite_rsvps_on_invite_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_invite_rsvps_on_invite_id ON invite_rsvps USING btree (invite_id);


--
-- Name: index_invites_on_area_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_invites_on_area_id ON invites USING btree (area_id);


--
-- Name: index_invites_on_event_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_invites_on_event_id ON invites USING btree (event_id);


--
-- Name: index_invites_on_venue_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_invites_on_venue_id ON invites USING btree (venue_id);


--
-- Name: index_kpis_segments_on_kpi_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_kpis_segments_on_kpi_id ON kpis_segments USING btree (kpi_id);


--
-- Name: index_list_exports_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_list_exports_on_user_id ON list_exports USING btree (company_user_id);


--
-- Name: index_locations_on_path; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_locations_on_path ON locations USING btree (path);


--
-- Name: index_marques_on_brand_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_marques_on_brand_id ON marques USING btree (brand_id);


--
-- Name: index_memberships_on_company_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_memberships_on_company_user_id ON memberships USING btree (company_user_id);


--
-- Name: index_memberships_on_memberable_id_and_memberable_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_memberships_on_memberable_id_and_memberable_type ON memberships USING btree (memberable_id, memberable_type);


--
-- Name: index_memberships_on_parent_id_and_parent_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_memberships_on_parent_id_and_parent_type ON memberships USING btree (parent_id, parent_type);


--
-- Name: index_notifications_on_company_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_notifications_on_company_user_id ON notifications USING btree (company_user_id);


--
-- Name: index_notifications_on_message; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_notifications_on_message ON notifications USING btree (message);


--
-- Name: index_notifications_on_params; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_notifications_on_params ON notifications USING gist (params);


--
-- Name: index_placeables_on_place_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_placeables_on_place_id ON placeables USING btree (place_id);


--
-- Name: index_placeables_on_placeable_id_and_placeable_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_placeables_on_placeable_id_and_placeable_type ON placeables USING btree (placeable_id, placeable_type);


--
-- Name: index_places_on_city; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_places_on_city ON places USING btree (city);


--
-- Name: index_places_on_country; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_places_on_country ON places USING btree (country);


--
-- Name: index_places_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_places_on_name ON places USING btree (name);


--
-- Name: index_places_on_reference; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_places_on_reference ON places USING btree (reference);


--
-- Name: index_places_on_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_places_on_state ON places USING btree (state);


--
-- Name: index_read_marks_on_user_id_and_readable_type_and_readable_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_read_marks_on_user_id_and_readable_type_and_readable_id ON read_marks USING btree (user_id, readable_type, readable_id);


--
-- Name: index_report_sharings_on_shared_with_id_and_shared_with_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_report_sharings_on_shared_with_id_and_shared_with_type ON report_sharings USING btree (shared_with_id, shared_with_type);


--
-- Name: index_satisfaction_surveys_on_company_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_satisfaction_surveys_on_company_user_id ON satisfaction_surveys USING btree (company_user_id);


--
-- Name: index_sessions_on_session_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sessions_on_session_id ON sessions USING btree (session_id);


--
-- Name: index_sessions_on_updated_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sessions_on_updated_at ON sessions USING btree (updated_at);


--
-- Name: index_surveys_on_event_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_surveys_on_event_id ON surveys USING btree (event_id);


--
-- Name: index_tasks_on_company_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tasks_on_company_user_id ON tasks USING btree (company_user_id);


--
-- Name: index_tasks_on_event_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tasks_on_event_id ON tasks USING btree (event_id);


--
-- Name: index_teamings_on_team_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_teamings_on_team_id ON teamings USING btree (team_id);


--
-- Name: index_teamings_on_team_id_and_teamable_id_and_teamable_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_teamings_on_team_id_and_teamable_id_and_teamable_type ON teamings USING btree (team_id, teamable_id, teamable_type);


--
-- Name: index_teamings_on_teamable_id_and_teamable_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_teamings_on_teamable_id_and_teamable_type ON teamings USING btree (teamable_id, teamable_type);


--
-- Name: index_teams_on_company_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_teams_on_company_id ON teams USING btree (company_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_invitation_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_invitation_token ON users USING btree (invitation_token);


--
-- Name: index_users_on_invited_by_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_invited_by_id ON users USING btree (invited_by_id);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: index_venues_on_company_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_venues_on_company_id ON venues USING btree (company_id);


--
-- Name: index_venues_on_company_id_and_place_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_venues_on_company_id_and_place_id ON venues USING btree (company_id, place_id);


--
-- Name: index_venues_on_place_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_venues_on_place_id ON venues USING btree (place_id);


--
-- Name: neighborhoods_geog_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX neighborhoods_geog_idx ON neighborhoods USING gist (geog);


--
-- Name: td_linx_code_norm_name_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX td_linx_code_norm_name_idx ON tdlinx_codes USING btree (normalize_place_name(name));


--
-- Name: td_linx_code_state_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX td_linx_code_state_idx ON tdlinx_codes USING btree (state);


--
-- Name: td_linx_code_substr_name_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX td_linx_code_substr_name_idx ON tdlinx_codes USING btree (substr(lower((name)::text), 1, 5));


--
-- Name: td_linx_code_substr_street_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX td_linx_code_substr_street_idx ON tdlinx_codes USING btree (substr(lower((street)::text), 1, 5));


--
-- Name: td_linx_code_substr_zipcode_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX td_linx_code_substr_zipcode_idx ON tdlinx_codes USING btree (substr((zipcode)::text, 1, 2));


--
-- Name: td_linx_full_name_trgm_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX td_linx_full_name_trgm_idx ON tdlinx_codes USING gist (name gist_trgm_ops);


--
-- Name: td_linx_full_street_trgm_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX td_linx_full_street_trgm_idx ON tdlinx_codes USING gist (street gist_trgm_ops);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO schema_migrations (version) VALUES ('20130320144126');

INSERT INTO schema_migrations (version) VALUES ('20130320144440');

INSERT INTO schema_migrations (version) VALUES ('20130421010849');

INSERT INTO schema_migrations (version) VALUES ('20130423205204');

INSERT INTO schema_migrations (version) VALUES ('20130424203628');

INSERT INTO schema_migrations (version) VALUES ('20130425154531');

INSERT INTO schema_migrations (version) VALUES ('20130425164900');

INSERT INTO schema_migrations (version) VALUES ('20130425180320');

INSERT INTO schema_migrations (version) VALUES ('20130425202111');

INSERT INTO schema_migrations (version) VALUES ('20130426172345');

INSERT INTO schema_migrations (version) VALUES ('20130426233632');

INSERT INTO schema_migrations (version) VALUES ('20130427213149');

INSERT INTO schema_migrations (version) VALUES ('20130429173329');

INSERT INTO schema_migrations (version) VALUES ('20130430001129');

INSERT INTO schema_migrations (version) VALUES ('20130430172703');

INSERT INTO schema_migrations (version) VALUES ('20130430172712');

INSERT INTO schema_migrations (version) VALUES ('20130430172713');

INSERT INTO schema_migrations (version) VALUES ('20130430173603');

INSERT INTO schema_migrations (version) VALUES ('20130430173800');

INSERT INTO schema_migrations (version) VALUES ('20130502160602');

INSERT INTO schema_migrations (version) VALUES ('20130502192742');

INSERT INTO schema_migrations (version) VALUES ('20130502215644');

INSERT INTO schema_migrations (version) VALUES ('20130506170645');

INSERT INTO schema_migrations (version) VALUES ('20130508002549');

INSERT INTO schema_migrations (version) VALUES ('20130508141916');

INSERT INTO schema_migrations (version) VALUES ('20130508143802');

INSERT INTO schema_migrations (version) VALUES ('20130508170125');

INSERT INTO schema_migrations (version) VALUES ('20130508170421');

INSERT INTO schema_migrations (version) VALUES ('20130509162752');

INSERT INTO schema_migrations (version) VALUES ('20130509220322');

INSERT INTO schema_migrations (version) VALUES ('20130509224657');

INSERT INTO schema_migrations (version) VALUES ('20130514171552');

INSERT INTO schema_migrations (version) VALUES ('20130514185149');

INSERT INTO schema_migrations (version) VALUES ('20130515163451');

INSERT INTO schema_migrations (version) VALUES ('20130516181312');

INSERT INTO schema_migrations (version) VALUES ('20130516205815');

INSERT INTO schema_migrations (version) VALUES ('20130516224029');

INSERT INTO schema_migrations (version) VALUES ('20130517141646');

INSERT INTO schema_migrations (version) VALUES ('20130518205559');

INSERT INTO schema_migrations (version) VALUES ('20130524205931');

INSERT INTO schema_migrations (version) VALUES ('20130527214554');

INSERT INTO schema_migrations (version) VALUES ('20130530180331');

INSERT INTO schema_migrations (version) VALUES ('20130531195702');

INSERT INTO schema_migrations (version) VALUES ('20130601192556');

INSERT INTO schema_migrations (version) VALUES ('20130604162831');

INSERT INTO schema_migrations (version) VALUES ('20130605002901');

INSERT INTO schema_migrations (version) VALUES ('20130605224014');

INSERT INTO schema_migrations (version) VALUES ('20130606152843');

INSERT INTO schema_migrations (version) VALUES ('20130606172043');

INSERT INTO schema_migrations (version) VALUES ('20130608175527');

INSERT INTO schema_migrations (version) VALUES ('20130610195840');

INSERT INTO schema_migrations (version) VALUES ('20130613160421');

INSERT INTO schema_migrations (version) VALUES ('20130614193603');

INSERT INTO schema_migrations (version) VALUES ('20130614210455');

INSERT INTO schema_migrations (version) VALUES ('20130619202306');

INSERT INTO schema_migrations (version) VALUES ('20130628163426');

INSERT INTO schema_migrations (version) VALUES ('20130701153805');

INSERT INTO schema_migrations (version) VALUES ('20130705163717');

INSERT INTO schema_migrations (version) VALUES ('20130705220239');

INSERT INTO schema_migrations (version) VALUES ('20130708193303');

INSERT INTO schema_migrations (version) VALUES ('20130710203220');

INSERT INTO schema_migrations (version) VALUES ('20130710205243');

INSERT INTO schema_migrations (version) VALUES ('20130712153308');

INSERT INTO schema_migrations (version) VALUES ('20130712194507');

INSERT INTO schema_migrations (version) VALUES ('20130712233955');

INSERT INTO schema_migrations (version) VALUES ('20130714161604');

INSERT INTO schema_migrations (version) VALUES ('20130715151824');

INSERT INTO schema_migrations (version) VALUES ('20130716143153');

INSERT INTO schema_migrations (version) VALUES ('20130716225205');

INSERT INTO schema_migrations (version) VALUES ('20130718220032');

INSERT INTO schema_migrations (version) VALUES ('20130719005345');

INSERT INTO schema_migrations (version) VALUES ('20130720022239');

INSERT INTO schema_migrations (version) VALUES ('20130722175858');

INSERT INTO schema_migrations (version) VALUES ('20130723024222');

INSERT INTO schema_migrations (version) VALUES ('20130723155334');

INSERT INTO schema_migrations (version) VALUES ('20130725160709');

INSERT INTO schema_migrations (version) VALUES ('20130729234759');

INSERT INTO schema_migrations (version) VALUES ('20130802232700');

INSERT INTO schema_migrations (version) VALUES ('20130803230950');

INSERT INTO schema_migrations (version) VALUES ('20130805173213');

INSERT INTO schema_migrations (version) VALUES ('20130808154705');

INSERT INTO schema_migrations (version) VALUES ('20130808222619');

INSERT INTO schema_migrations (version) VALUES ('20130813165731');

INSERT INTO schema_migrations (version) VALUES ('20130814163147');

INSERT INTO schema_migrations (version) VALUES ('20130820172608');

INSERT INTO schema_migrations (version) VALUES ('20130820233224');

INSERT INTO schema_migrations (version) VALUES ('20130822161255');

INSERT INTO schema_migrations (version) VALUES ('20130824182224');

INSERT INTO schema_migrations (version) VALUES ('20130826223112');

INSERT INTO schema_migrations (version) VALUES ('20130829154025');

INSERT INTO schema_migrations (version) VALUES ('20130829181311');

INSERT INTO schema_migrations (version) VALUES ('20130830010449');

INSERT INTO schema_migrations (version) VALUES ('20130830163432');

INSERT INTO schema_migrations (version) VALUES ('20130901020307');

INSERT INTO schema_migrations (version) VALUES ('20130902205104');

INSERT INTO schema_migrations (version) VALUES ('20130903032423');

INSERT INTO schema_migrations (version) VALUES ('20130903040128');

INSERT INTO schema_migrations (version) VALUES ('20130903152234');

INSERT INTO schema_migrations (version) VALUES ('20130903152532');

INSERT INTO schema_migrations (version) VALUES ('20130904202830');

INSERT INTO schema_migrations (version) VALUES ('20130907160431');

INSERT INTO schema_migrations (version) VALUES ('20130909031930');

INSERT INTO schema_migrations (version) VALUES ('20130911081614');

INSERT INTO schema_migrations (version) VALUES ('20130911210826');

INSERT INTO schema_migrations (version) VALUES ('20130912061930');

INSERT INTO schema_migrations (version) VALUES ('20130924222047');

INSERT INTO schema_migrations (version) VALUES ('20130925183612');

INSERT INTO schema_migrations (version) VALUES ('20130927195537');

INSERT INTO schema_migrations (version) VALUES ('20130927203756');

INSERT INTO schema_migrations (version) VALUES ('20130927212907');

INSERT INTO schema_migrations (version) VALUES ('20131004151643');

INSERT INTO schema_migrations (version) VALUES ('20131004220536');

INSERT INTO schema_migrations (version) VALUES ('20131012154546');

INSERT INTO schema_migrations (version) VALUES ('20131015213734');

INSERT INTO schema_migrations (version) VALUES ('20131015213823');

INSERT INTO schema_migrations (version) VALUES ('20131018160343');

INSERT INTO schema_migrations (version) VALUES ('20131018172330');

INSERT INTO schema_migrations (version) VALUES ('20131022151855');

INSERT INTO schema_migrations (version) VALUES ('20131106150122');

INSERT INTO schema_migrations (version) VALUES ('20131114022734');

INSERT INTO schema_migrations (version) VALUES ('20131119162327');

INSERT INTO schema_migrations (version) VALUES ('20131216173755');

INSERT INTO schema_migrations (version) VALUES ('20131219195000');

INSERT INTO schema_migrations (version) VALUES ('20140108200310');

INSERT INTO schema_migrations (version) VALUES ('20140109185805');

INSERT INTO schema_migrations (version) VALUES ('20140115210126');

INSERT INTO schema_migrations (version) VALUES ('20140121200658');

INSERT INTO schema_migrations (version) VALUES ('20140124202736');

INSERT INTO schema_migrations (version) VALUES ('20140129182630');

INSERT INTO schema_migrations (version) VALUES ('20140204211220');

INSERT INTO schema_migrations (version) VALUES ('20140204215421');

INSERT INTO schema_migrations (version) VALUES ('20140204215955');

INSERT INTO schema_migrations (version) VALUES ('20140204220932');

INSERT INTO schema_migrations (version) VALUES ('20140204221214');

INSERT INTO schema_migrations (version) VALUES ('20140205182211');

INSERT INTO schema_migrations (version) VALUES ('20140206222315');

INSERT INTO schema_migrations (version) VALUES ('20140208180019');

INSERT INTO schema_migrations (version) VALUES ('20140210181637');

INSERT INTO schema_migrations (version) VALUES ('20140210202029');

INSERT INTO schema_migrations (version) VALUES ('20140212144618');

INSERT INTO schema_migrations (version) VALUES ('20140212220518');

INSERT INTO schema_migrations (version) VALUES ('20140212231328');

INSERT INTO schema_migrations (version) VALUES ('20140213191256');

INSERT INTO schema_migrations (version) VALUES ('20140214174405');

INSERT INTO schema_migrations (version) VALUES ('20140225153028');

INSERT INTO schema_migrations (version) VALUES ('20140227205714');

INSERT INTO schema_migrations (version) VALUES ('20140318093131');

INSERT INTO schema_migrations (version) VALUES ('20140318105959');

INSERT INTO schema_migrations (version) VALUES ('20140322221112');

INSERT INTO schema_migrations (version) VALUES ('20140402221101');

INSERT INTO schema_migrations (version) VALUES ('20140405221111');

INSERT INTO schema_migrations (version) VALUES ('20140405221112');

INSERT INTO schema_migrations (version) VALUES ('20140405221113');

INSERT INTO schema_migrations (version) VALUES ('20140405221114');

INSERT INTO schema_migrations (version) VALUES ('20140410005523');

INSERT INTO schema_migrations (version) VALUES ('20140429215144');

INSERT INTO schema_migrations (version) VALUES ('20140430145357');

INSERT INTO schema_migrations (version) VALUES ('20140430172242');

INSERT INTO schema_migrations (version) VALUES ('20140508044637');

INSERT INTO schema_migrations (version) VALUES ('20140508162351');

INSERT INTO schema_migrations (version) VALUES ('20140514004126');

INSERT INTO schema_migrations (version) VALUES ('20140520204529');

INSERT INTO schema_migrations (version) VALUES ('20140604183223');

INSERT INTO schema_migrations (version) VALUES ('20140626003208');

INSERT INTO schema_migrations (version) VALUES ('20140626231648');

INSERT INTO schema_migrations (version) VALUES ('20140701022727');

INSERT INTO schema_migrations (version) VALUES ('20140717134846');

INSERT INTO schema_migrations (version) VALUES ('20140717212001');

INSERT INTO schema_migrations (version) VALUES ('20140717214845');

INSERT INTO schema_migrations (version) VALUES ('20140722012255');

INSERT INTO schema_migrations (version) VALUES ('20140807202736');

INSERT INTO schema_migrations (version) VALUES ('20140808185124');

INSERT INTO schema_migrations (version) VALUES ('20140809221042');

INSERT INTO schema_migrations (version) VALUES ('20140818181535');

INSERT INTO schema_migrations (version) VALUES ('20140820045702');

INSERT INTO schema_migrations (version) VALUES ('20140820175246');

INSERT INTO schema_migrations (version) VALUES ('20140820194232');

INSERT INTO schema_migrations (version) VALUES ('20140821114202');

INSERT INTO schema_migrations (version) VALUES ('20140821175739');

INSERT INTO schema_migrations (version) VALUES ('20140822232819');

INSERT INTO schema_migrations (version) VALUES ('20140826223825');

INSERT INTO schema_migrations (version) VALUES ('20140828001108');

INSERT INTO schema_migrations (version) VALUES ('20140828171718');

INSERT INTO schema_migrations (version) VALUES ('20140828232932');

INSERT INTO schema_migrations (version) VALUES ('20140829215808');

INSERT INTO schema_migrations (version) VALUES ('20140829225956');

INSERT INTO schema_migrations (version) VALUES ('20140903155120');

INSERT INTO schema_migrations (version) VALUES ('20140906135527');

INSERT INTO schema_migrations (version) VALUES ('20140917204844');

INSERT INTO schema_migrations (version) VALUES ('20140919040050');

INSERT INTO schema_migrations (version) VALUES ('20140919045120');

INSERT INTO schema_migrations (version) VALUES ('20140919052121');

INSERT INTO schema_migrations (version) VALUES ('20140919052349');

INSERT INTO schema_migrations (version) VALUES ('20140920000541');

INSERT INTO schema_migrations (version) VALUES ('20140923182037');

INSERT INTO schema_migrations (version) VALUES ('20140925224240');

INSERT INTO schema_migrations (version) VALUES ('20141008230422');

INSERT INTO schema_migrations (version) VALUES ('20141018015939');

INSERT INTO schema_migrations (version) VALUES ('20141101004857');

INSERT INTO schema_migrations (version) VALUES ('20141105225703');

INSERT INTO schema_migrations (version) VALUES ('20141106212144');

INSERT INTO schema_migrations (version) VALUES ('20141110235004');

INSERT INTO schema_migrations (version) VALUES ('20141112130554');

INSERT INTO schema_migrations (version) VALUES ('20141112143051');

INSERT INTO schema_migrations (version) VALUES ('20141126004039');

INSERT INTO schema_migrations (version) VALUES ('20141203165819');

INSERT INTO schema_migrations (version) VALUES ('20141219231528');

INSERT INTO schema_migrations (version) VALUES ('20141230213142');

INSERT INTO schema_migrations (version) VALUES ('20150103000304');

INSERT INTO schema_migrations (version) VALUES ('20150105215550');

INSERT INTO schema_migrations (version) VALUES ('20150106231728');

INSERT INTO schema_migrations (version) VALUES ('20150109220816');

INSERT INTO schema_migrations (version) VALUES ('20150115215305');

INSERT INTO schema_migrations (version) VALUES ('20150126044001');

INSERT INTO schema_migrations (version) VALUES ('20150126190408');

INSERT INTO schema_migrations (version) VALUES ('20150127021717');

INSERT INTO schema_migrations (version) VALUES ('20150127133851');

INSERT INTO schema_migrations (version) VALUES ('20150127214124');

INSERT INTO schema_migrations (version) VALUES ('20150127222206');

INSERT INTO schema_migrations (version) VALUES ('20150127223950');

INSERT INTO schema_migrations (version) VALUES ('20150127225850');

INSERT INTO schema_migrations (version) VALUES ('20150210030844');

INSERT INTO schema_migrations (version) VALUES ('20150212235756');

INSERT INTO schema_migrations (version) VALUES ('20150226220017');

INSERT INTO schema_migrations (version) VALUES ('20150317180935');

INSERT INTO schema_migrations (version) VALUES ('20150319192414');

INSERT INTO schema_migrations (version) VALUES ('20150320155037');

INSERT INTO schema_migrations (version) VALUES ('20150407181402');

