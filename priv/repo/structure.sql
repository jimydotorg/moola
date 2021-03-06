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
-- Name: binance_ticks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE binance_ticks (
    id bigint NOT NULL,
    symbol integer,
    price numeric,
    max_price numeric,
    min_price numeric,
    volume numeric,
    btc_volume numeric,
    usd_volume numeric,
    hour integer,
    minute integer,
    day_of_week integer,
    "timestamp" timestamp without time zone
);


--
-- Name: binance_ticks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE binance_ticks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: binance_ticks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE binance_ticks_id_seq OWNED BY binance_ticks.id;


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
-- Name: coinbase_ticks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE coinbase_ticks (
    id bigint NOT NULL,
    symbol integer,
    buy_price numeric,
    spot_price numeric,
    sell_price numeric,
    latency integer,
    hour integer,
    minute integer,
    day_of_week integer,
    "timestamp" timestamp without time zone
);


--
-- Name: coinbase_ticks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE coinbase_ticks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: coinbase_ticks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE coinbase_ticks_id_seq OWNED BY coinbase_ticks.id;


--
-- Name: gdax_fills; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE gdax_fills (
    id bigint NOT NULL,
    trade_id integer,
    symbol integer,
    order_id character varying(255),
    product_id character varying(255),
    price numeric,
    size numeric,
    liquidity character varying(255),
    fee numeric,
    settled boolean DEFAULT false NOT NULL,
    side character varying(255),
    created_at timestamp without time zone
);


--
-- Name: gdax_fills_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE gdax_fills_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gdax_fills_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE gdax_fills_id_seq OWNED BY gdax_fills.id;


--
-- Name: gdax_order_latency_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE gdax_order_latency_logs (
    id bigint NOT NULL,
    milliseconds integer,
    "timestamp" timestamp without time zone
);


--
-- Name: gdax_order_latency_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE gdax_order_latency_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gdax_order_latency_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE gdax_order_latency_logs_id_seq OWNED BY gdax_order_latency_logs.id;


--
-- Name: gdax_orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE gdax_orders (
    id bigint NOT NULL,
    gdax_id character varying(255),
    price numeric,
    size numeric,
    symbol integer,
    product_id character varying(255),
    side character varying(255),
    stp character varying(255),
    type character varying(255),
    time_in_force character varying(255),
    post_only boolean DEFAULT false NOT NULL,
    fill_fees numeric,
    filled_size numeric,
    executed_value numeric,
    status character varying(255),
    settled boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone
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
    price numeric,
    max_price numeric,
    min_price numeric,
    volume numeric,
    usd_volume numeric,
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
-- Name: binance_ticks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY binance_ticks ALTER COLUMN id SET DEFAULT nextval('binance_ticks_id_seq'::regclass);


--
-- Name: client_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY client_tokens ALTER COLUMN id SET DEFAULT nextval('client_tokens_id_seq'::regclass);


--
-- Name: coinbase_ticks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY coinbase_ticks ALTER COLUMN id SET DEFAULT nextval('coinbase_ticks_id_seq'::regclass);


--
-- Name: gdax_fills id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY gdax_fills ALTER COLUMN id SET DEFAULT nextval('gdax_fills_id_seq'::regclass);


--
-- Name: gdax_order_latency_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY gdax_order_latency_logs ALTER COLUMN id SET DEFAULT nextval('gdax_order_latency_logs_id_seq'::regclass);


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
-- Name: binance_ticks binance_ticks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY binance_ticks
    ADD CONSTRAINT binance_ticks_pkey PRIMARY KEY (id);


--
-- Name: client_tokens client_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY client_tokens
    ADD CONSTRAINT client_tokens_pkey PRIMARY KEY (id);


--
-- Name: coinbase_ticks coinbase_ticks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY coinbase_ticks
    ADD CONSTRAINT coinbase_ticks_pkey PRIMARY KEY (id);


--
-- Name: gdax_fills gdax_fills_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gdax_fills
    ADD CONSTRAINT gdax_fills_pkey PRIMARY KEY (id);


--
-- Name: gdax_order_latency_logs gdax_order_latency_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gdax_order_latency_logs
    ADD CONSTRAINT gdax_order_latency_logs_pkey PRIMARY KEY (id);


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
-- Name: binance_ticks_symbol_timestamp_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX binance_ticks_symbol_timestamp_index ON binance_ticks USING btree (symbol, "timestamp");


--
-- Name: client_tokens_token_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX client_tokens_token_index ON client_tokens USING btree (token);


--
-- Name: gdax_fills_symbol_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX gdax_fills_symbol_index ON gdax_fills USING btree (symbol);


--
-- Name: gdax_fills_trade_id_symbol_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX gdax_fills_trade_id_symbol_index ON gdax_fills USING btree (trade_id, symbol);


--
-- Name: gdax_order_latency_logs_timestamp_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX gdax_order_latency_logs_timestamp_index ON gdax_order_latency_logs USING btree ("timestamp");


--
-- Name: gdax_orders_gdax_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX gdax_orders_gdax_id_index ON gdax_orders USING btree (gdax_id);


--
-- Name: gdax_orders_symbol_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX gdax_orders_symbol_index ON gdax_orders USING btree (symbol);


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

INSERT INTO "schema_migrations" (version) VALUES (20171216034812), (20171218032627), (20171218032634), (20171218032638), (20171218032639), (20171220044208), (20171221043239), (20171224200517), (20171225041220), (20180111014414);

