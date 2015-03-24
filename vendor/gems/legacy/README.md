This requires to enable the extension `postgres_fdw` and to create some foreign tables


```
--
-- Name: legacy_prod; Type: SERVER; Schema: -; Owner: -
--

CREATE SERVER legacy_prod FOREIGN DATA WRAPPER postgres_fdw OPTIONS (
    dbname 'd9ncqhfqis29bj',
    host 'ec2-54-235-194-252.compute-1.amazonaws.com',
    port '5432'
);


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

```