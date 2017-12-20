--
-- PostgreSQL database dump
--

-- Dumped from database version 10.0
-- Dumped by pg_dump version 10.0

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: client_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE client_tokens (
    id bigint NOT NULL,
    token character varying(255),
    device_id character varying(255),
    last_active_at timestamp without time zone,
    creating_ip character varying(255),
    "collation" character varying(255),
    disabled boolean,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: client_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE client_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: client_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE client_tokens_id_seq OWNED BY client_tokens.id;


--
-- Name: gdax_orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE gdax_orders (
    id bigint NOT NULL,
    gdax_id character varying(255),
    price double precision,
    size double precision,
    symbol integer,
    product_id character varying(255),
    side character varying(255),
    stp character varying(255),
    type character varying(255),
    time_in_force character varying(255),
    post_only boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    fill_fees double precision,
    filled_size double precision,
    executed_value double precision,
    status character varying(255),
    settled boolean DEFAULT false NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: gdax_orders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE gdax_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gdax_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE gdax_orders_id_seq OWNED BY gdax_orders.id;


--
-- Name: log_event_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE log_event_types (
    id bigint NOT NULL,
    name character varying(255),
    full_name text,
    description character varying(255),
    parent_id bigint,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: log_event_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE log_event_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: log_event_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE log_event_types_id_seq OWNED BY log_event_types.id;


--
-- Name: log_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE log_events (
    id bigint NOT NULL,
    client_token_id bigint,
    log_event_type_id bigint,
    info jsonb,
    inserted_at timestamp without time zone NOT NULL
);


--
-- Name: log_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE log_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: log_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE log_events_id_seq OWNED BY log_events.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp without time zone
);


--
-- Name: ticks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE ticks (
    id bigint NOT NULL,
    symbol integer,
    price double precision,
    max_price double precision,
    min_price double precision,
    volume double precision,
    usd_volume double precision,
    hour integer,
    minute integer,
    day_of_week integer,
    "timestamp" timestamp without time zone
);


--
-- Name: ticks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ticks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ticks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ticks_id_seq OWNED BY ticks.id;


--
-- Name: user_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE user_tokens (
    id bigint NOT NULL,
    token character varying(255),
    user_id bigint,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: user_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_tokens_id_seq OWNED BY user_tokens.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE users (
    id bigint NOT NULL,
    nickname character varying(255),
    password_hash character varying(255),
    registration_ip character varying(255),
    status integer,
    level integer,
    deleted_nickname character varying(255),
    deleted_at timestamp without time zone,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
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
-- Name: client_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY client_tokens ALTER COLUMN id SET DEFAULT nextval('client_tokens_id_seq'::regclass);


--
-- Name: gdax_orders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY gdax_orders ALTER COLUMN id SET DEFAULT nextval('gdax_orders_id_seq'::regclass);


--
-- Name: log_event_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY log_event_types ALTER COLUMN id SET DEFAULT nextval('log_event_types_id_seq'::regclass);


--
-- Name: log_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY log_events ALTER COLUMN id SET DEFAULT nextval('log_events_id_seq'::regclass);


--
-- Name: ticks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY ticks ALTER COLUMN id SET DEFAULT nextval('ticks_id_seq'::regclass);


--
-- Name: user_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_tokens ALTER COLUMN id SET DEFAULT nextval('user_tokens_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: client_tokens client_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY client_tokens
    ADD CONSTRAINT client_tokens_pkey PRIMARY KEY (id);


--
-- Name: gdax_orders gdax_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gdax_orders
    ADD CONSTRAINT gdax_orders_pkey PRIMARY KEY (id);


--
-- Name: log_event_types log_event_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY log_event_types
    ADD CONSTRAINT log_event_types_pkey PRIMARY KEY (id);


--
-- Name: log_events log_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY log_events
    ADD CONSTRAINT log_events_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: ticks ticks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ticks
    ADD CONSTRAINT ticks_pkey PRIMARY KEY (id);


--
-- Name: user_tokens user_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_tokens
    ADD CONSTRAINT user_tokens_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: client_tokens_token_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX client_tokens_token_index ON client_tokens USING btree (token);


--
-- Name: log_event_types_full_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX log_event_types_full_name_index ON log_event_types USING btree (full_name);


--
-- Name: log_event_types_name_parent_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX log_event_types_name_parent_id_index ON log_event_types USING btree (name, parent_id);


--
-- Name: log_event_types_parent_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX log_event_types_parent_id_index ON log_event_types USING btree (parent_id);


--
-- Name: log_events_client_token_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX log_events_client_token_id_index ON log_events USING btree (client_token_id);


--
-- Name: log_events_log_event_type_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX log_events_log_event_type_id_index ON log_events USING btree (log_event_type_id);


--
-- Name: ticks_symbol_timestamp_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ticks_symbol_timestamp_index ON ticks USING btree (symbol, "timestamp");


--
-- Name: user_tokens_token_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX user_tokens_token_index ON user_tokens USING btree (token);


--
-- Name: user_tokens_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_tokens_user_id_index ON user_tokens USING btree (user_id);


--
-- Name: users_nickname_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_nickname_index ON users USING btree (nickname);


--
-- Name: log_event_types log_event_types_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY log_event_types
    ADD CONSTRAINT log_event_types_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES log_event_types(id);


--
-- Name: log_events log_events_client_token_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY log_events
    ADD CONSTRAINT log_events_client_token_id_fkey FOREIGN KEY (client_token_id) REFERENCES client_tokens(id);


--
-- Name: log_events log_events_log_event_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY log_events
    ADD CONSTRAINT log_events_log_event_type_id_fkey FOREIGN KEY (log_event_type_id) REFERENCES log_event_types(id);


--
-- Name: user_tokens user_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_tokens
    ADD CONSTRAINT user_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- PostgreSQL database dump complete
--

INSERT INTO "schema_migrations" (version) VALUES (20171216034812), (20171218032627), (20171218032634), (20171218032638), (20171218032639), (20171220044208);

