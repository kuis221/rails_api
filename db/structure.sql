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
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track execution statistics of all SQL statements executed';


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


--
-- Name: legacy_prod; Type: SERVER; Schema: -; Owner: -
--

CREATE SERVER legacy_prod FOREIGN DATA WRAPPER postgres_fdw OPTIONS (
    dbname 'legacy_dev',
    host '127.0.0.1',
    port '5432'
);


SET search_path = public, pg_catalog;

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
-- Name: activity_results; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE activity_results (
    id integer NOT NULL,
    activity_id integer,
    form_field_id integer,
    value text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: activity_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE activity_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE activity_results_id_seq OWNED BY activity_results.id;


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
    common_denominators text
);


--
-- Name: areas_campaigns; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE areas_campaigns (
    id integer NOT NULL,
    area_id integer,
    campaign_id integer
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
    processed boolean DEFAULT false NOT NULL
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
    updated_at timestamp without time zone NOT NULL
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
-- Name: campaign_form_fields; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE campaign_form_fields (
    id integer NOT NULL,
    campaign_id integer,
    kpi_id integer,
    ordering integer,
    name character varying(255),
    field_type character varying(255),
    options text,
    section_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: campaign_form_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE campaign_form_fields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: campaign_form_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE campaign_form_fields_id_seq OWNED BY campaign_form_fields.id;


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
    end_date date
);


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
    timezone_support boolean
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
    last_activity_at timestamp without time zone
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
    updated_at timestamp without time zone NOT NULL
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
-- Name: event_results; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE event_results (
    id integer NOT NULL,
    form_field_id integer,
    event_id integer,
    kpis_segment_id integer,
    value text,
    scalar_value numeric(10,2) DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    kpi_id integer
);


--
-- Name: event_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE event_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: event_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE event_results_id_seq OWNED BY event_results.id;


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
    summary text,
    timezone character varying(255),
    local_start_at timestamp without time zone,
    local_end_at timestamp without time zone
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
-- Name: form_field_options; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE form_field_options (
    id integer NOT NULL,
    form_field_id integer,
    name character varying(255),
    ordering integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
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
    updated_at timestamp without time zone NOT NULL
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
    due_date date
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
    progress integer DEFAULT 0
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
    extra_params text
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
    subject_id character varying(255)
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
    latitude double precision,
    longitude double precision,
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
    neighborhood character varying(255),
    location_id integer,
    is_location boolean
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
    filters text
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
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


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
-- Name: td_linxes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE td_linxes (
    id integer NOT NULL,
    store_code character varying(255),
    retailer_dba_name character varying(255),
    retailer_address character varying(255),
    retailer_city character varying(255),
    retailer_state character varying(255),
    retailer_trade_channel character varying(255),
    license_type character varying(255),
    fixed_address character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: td_linxes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE td_linxes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: td_linxes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE td_linxes_id_seq OWNED BY td_linxes.id;


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
    invitation_created_at timestamp without time zone
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
    score_cost integer
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

ALTER TABLE ONLY activity_results ALTER COLUMN id SET DEFAULT nextval('activity_results_id_seq'::regclass);


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

ALTER TABLE ONLY campaign_form_fields ALTER COLUMN id SET DEFAULT nextval('campaign_form_fields_id_seq'::regclass);


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

ALTER TABLE ONLY event_data ALTER COLUMN id SET DEFAULT nextval('event_data_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY event_expenses ALTER COLUMN id SET DEFAULT nextval('event_expenses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY event_results ALTER COLUMN id SET DEFAULT nextval('event_results_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY events ALTER COLUMN id SET DEFAULT nextval('events_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY form_field_options ALTER COLUMN id SET DEFAULT nextval('form_field_options_id_seq'::regclass);


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

ALTER TABLE ONLY reports ALTER COLUMN id SET DEFAULT nextval('reports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY roles ALTER COLUMN id SET DEFAULT nextval('roles_id_seq'::regclass);


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

ALTER TABLE ONLY tasks ALTER COLUMN id SET DEFAULT nextval('tasks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY td_linxes ALTER COLUMN id SET DEFAULT nextval('td_linxes_id_seq'::regclass);


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

ALTER TABLE ONLY activity_results
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
-- Name: campaign_form_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY campaign_form_fields
    ADD CONSTRAINT campaign_form_fields_pkey PRIMARY KEY (id);


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
-- Name: event_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY event_results
    ADD CONSTRAINT event_results_pkey PRIMARY KEY (id);


--
-- Name: events_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


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
-- Name: tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);


--
-- Name: td_linxes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY td_linxes
    ADD CONSTRAINT td_linxes_pkey PRIMARY KEY (id);


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
-- Name: index_activity_results_on_activity_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_results_on_activity_id ON activity_results USING btree (activity_id);


--
-- Name: index_activity_results_on_activity_id_and_form_field_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_results_on_activity_id_and_form_field_id ON activity_results USING btree (activity_id, form_field_id);


--
-- Name: index_activity_results_on_form_field_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_results_on_form_field_id ON activity_results USING btree (form_field_id);


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
-- Name: index_campaign_form_fields_on_campaign_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_campaign_form_fields_on_campaign_id ON campaign_form_fields USING btree (campaign_id);


--
-- Name: index_campaign_form_fields_on_kpi_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_campaign_form_fields_on_kpi_id ON campaign_form_fields USING btree (kpi_id);


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
-- Name: index_event_data_on_event_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_event_data_on_event_id ON event_data USING btree (event_id);


--
-- Name: index_event_expenses_on_event_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_event_expenses_on_event_id ON event_expenses USING btree (event_id);


--
-- Name: index_event_results_on_event_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_event_results_on_event_id ON event_results USING btree (event_id);


--
-- Name: index_event_results_on_event_id_and_form_field_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_event_results_on_event_id_and_form_field_id ON event_results USING btree (event_id, form_field_id);


--
-- Name: index_event_results_on_form_field_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_event_results_on_form_field_id ON event_results USING btree (form_field_id);


--
-- Name: index_event_results_on_kpi_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_event_results_on_kpi_id ON event_results USING btree (kpi_id);


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
-- Name: index_form_field_options_on_form_field_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_form_field_options_on_form_field_id ON form_field_options USING btree (form_field_id);


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
-- Name: index_placeables_on_place_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_placeables_on_place_id ON placeables USING btree (place_id);


--
-- Name: index_placeables_on_placeable_id_and_placeable_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_placeables_on_placeable_id_and_placeable_type ON placeables USING btree (placeable_id, placeable_type);


--
-- Name: index_places_on_reference; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_places_on_reference ON places USING btree (reference);


--
-- Name: index_read_marks_on_user_id_and_readable_type_and_readable_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_read_marks_on_user_id_and_readable_type_and_readable_id ON read_marks USING btree (user_id, readable_type, readable_id);


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
-- Name: index_td_linxes_on_store_code; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_td_linxes_on_store_code ON td_linxes USING btree (store_code);


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

INSERT INTO schema_migrations (version) VALUES ('20140212191723');

INSERT INTO schema_migrations (version) VALUES ('20140212220518');

INSERT INTO schema_migrations (version) VALUES ('20140212231328');

INSERT INTO schema_migrations (version) VALUES ('20140213191256');

INSERT INTO schema_migrations (version) VALUES ('20140214174405');