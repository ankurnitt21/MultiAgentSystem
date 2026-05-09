--
-- PostgreSQL database dump
--

\restrict 4vC5Mds55TXQebSVTCUHuGepZtlETenXxbtpILu4j2aBYzlzBtMudixsS7UWHmx

-- Dumped from database version 16.13
-- Dumped by pg_dump version 16.13

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: category; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.category (
    id bigint NOT NULL,
    name character varying(100) NOT NULL,
    parent_category_id bigint,
    description text
);


--
-- Name: category_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.category_id_seq OWNED BY public.category.id;


--
-- Name: checkpoint_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.checkpoint_blobs (
    thread_id text NOT NULL,
    checkpoint_ns text DEFAULT ''::text NOT NULL,
    channel text NOT NULL,
    version text NOT NULL,
    type text NOT NULL,
    blob bytea
);


--
-- Name: checkpoint_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.checkpoint_migrations (
    v integer NOT NULL
);


--
-- Name: checkpoint_writes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.checkpoint_writes (
    thread_id text NOT NULL,
    checkpoint_ns text DEFAULT ''::text NOT NULL,
    checkpoint_id text NOT NULL,
    task_id text NOT NULL,
    idx integer NOT NULL,
    channel text NOT NULL,
    type text,
    blob bytea NOT NULL,
    task_path text DEFAULT ''::text NOT NULL
);


--
-- Name: checkpoints; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.checkpoints (
    thread_id text NOT NULL,
    checkpoint_ns text DEFAULT ''::text NOT NULL,
    checkpoint_id text NOT NULL,
    parent_checkpoint_id text,
    type text,
    checkpoint jsonb NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL
);


--
-- Name: conversation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversation (
    id bigint NOT NULL,
    session_id character varying(100) NOT NULL,
    role character varying(20) NOT NULL,
    content text NOT NULL,
    sql_query text,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: conversation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conversation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conversation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conversation_id_seq OWNED BY public.conversation.id;


--
-- Name: conversation_summary; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversation_summary (
    session_id character varying(100) NOT NULL,
    summary text NOT NULL,
    approximate_tokens integer DEFAULT 0,
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: customer; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer (
    id bigint NOT NULL,
    code character varying(20) NOT NULL,
    name character varying(150) NOT NULL,
    email character varying(100),
    phone character varying(30),
    city character varying(50),
    state character varying(50),
    customer_type character varying(30),
    credit_limit numeric(14,2),
    is_active boolean DEFAULT true
);


--
-- Name: customer_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.customer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.customer_id_seq OWNED BY public.customer.id;


--
-- Name: inventory; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory (
    id bigint NOT NULL,
    product_id bigint NOT NULL,
    location_id bigint NOT NULL,
    quantity_on_hand integer DEFAULT 0 NOT NULL,
    quantity_reserved integer DEFAULT 0 NOT NULL,
    quantity_available integer GENERATED ALWAYS AS ((quantity_on_hand - quantity_reserved)) STORED,
    lot_number character varying(50),
    expiry_date date,
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: inventory_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.inventory_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: inventory_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.inventory_id_seq OWNED BY public.inventory.id;


--
-- Name: inventory_transaction; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_transaction (
    id bigint NOT NULL,
    product_id bigint NOT NULL,
    from_location_id bigint,
    to_location_id bigint,
    transaction_type character varying(30) NOT NULL,
    quantity integer NOT NULL,
    reference_type character varying(30),
    reference_id bigint,
    performed_by character varying(100),
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: inventory_transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.inventory_transaction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: inventory_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.inventory_transaction_id_seq OWNED BY public.inventory_transaction.id;


--
-- Name: location; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.location (
    id bigint NOT NULL,
    zone_id bigint NOT NULL,
    aisle character varying(10),
    rack character varying(10),
    shelf character varying(10),
    bin character varying(10),
    barcode character varying(50),
    location_type character varying(30) NOT NULL,
    max_weight_kg numeric(10,2),
    is_occupied boolean DEFAULT false
);


--
-- Name: location_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.location_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: location_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.location_id_seq OWNED BY public.location.id;


--
-- Name: product; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product (
    id bigint NOT NULL,
    sku character varying(50) NOT NULL,
    name character varying(200) NOT NULL,
    description text,
    category_id bigint,
    supplier_id bigint,
    unit_price numeric(12,2),
    cost_price numeric(12,2),
    weight_kg numeric(10,3),
    uom character varying(20) DEFAULT 'EACH'::character varying,
    is_perishable boolean DEFAULT false,
    min_stock_level integer DEFAULT 0,
    reorder_point integer DEFAULT 0,
    reorder_qty integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: product_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_id_seq OWNED BY public.product.id;


--
-- Name: prompt_template; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prompt_template (
    id bigint NOT NULL,
    name character varying(100) NOT NULL,
    version integer DEFAULT 1,
    template text NOT NULL,
    description text,
    model_hint character varying(50) DEFAULT 'fast'::character varying,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: prompt_template_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.prompt_template_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: prompt_template_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.prompt_template_id_seq OWNED BY public.prompt_template.id;


--
-- Name: purchase_order; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purchase_order (
    id bigint NOT NULL,
    po_number character varying(30) NOT NULL,
    supplier_id bigint NOT NULL,
    warehouse_id bigint NOT NULL,
    status character varying(20) DEFAULT 'DRAFT'::character varying,
    order_date date,
    expected_delivery date,
    total_amount numeric(14,2),
    created_by character varying(100),
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: purchase_order_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.purchase_order_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: purchase_order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.purchase_order_id_seq OWNED BY public.purchase_order.id;


--
-- Name: purchase_order_line; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purchase_order_line (
    id bigint NOT NULL,
    purchase_order_id bigint NOT NULL,
    product_id bigint NOT NULL,
    quantity_ordered integer NOT NULL,
    quantity_received integer DEFAULT 0,
    unit_price numeric(12,2)
);


--
-- Name: purchase_order_line_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.purchase_order_line_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: purchase_order_line_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.purchase_order_line_id_seq OWNED BY public.purchase_order_line.id;


--
-- Name: query_feedback; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.query_feedback (
    id bigint NOT NULL,
    session_id character varying(100) NOT NULL,
    run_id character varying(100),
    query text NOT NULL,
    generated_sql text,
    pipeline character varying(20),
    rating integer NOT NULL,
    comment text,
    correction text,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT query_feedback_rating_check CHECK ((rating = ANY (ARRAY['-1'::integer, 1])))
);


--
-- Name: query_feedback_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.query_feedback_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: query_feedback_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.query_feedback_id_seq OWNED BY public.query_feedback.id;


--
-- Name: query_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.query_logs (
    id bigint NOT NULL,
    query text NOT NULL,
    response text,
    domain character varying(50),
    latency_ms double precision,
    confidence character varying(20),
    ragas_faithfulness double precision,
    prompt_version integer,
    model character varying(100),
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: query_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.query_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: query_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.query_logs_id_seq OWNED BY public.query_logs.id;


--
-- Name: sales_order; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sales_order (
    id bigint NOT NULL,
    order_number character varying(30) NOT NULL,
    customer_id bigint NOT NULL,
    warehouse_id bigint NOT NULL,
    status character varying(20) DEFAULT 'PENDING'::character varying,
    priority character varying(10) DEFAULT 'NORMAL'::character varying,
    order_date date,
    required_date date,
    total_amount numeric(14,2),
    shipping_method character varying(50),
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: sales_order_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sales_order_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sales_order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sales_order_id_seq OWNED BY public.sales_order.id;


--
-- Name: sales_order_line; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sales_order_line (
    id bigint NOT NULL,
    sales_order_id bigint NOT NULL,
    product_id bigint NOT NULL,
    quantity_ordered integer NOT NULL,
    quantity_shipped integer DEFAULT 0,
    unit_price numeric(12,2)
);


--
-- Name: sales_order_line_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sales_order_line_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sales_order_line_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sales_order_line_id_seq OWNED BY public.sales_order_line.id;


--
-- Name: schema_description; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_description (
    id bigint NOT NULL,
    table_name character varying(100) NOT NULL,
    column_name character varying(100),
    domain character varying(50) NOT NULL,
    description text NOT NULL,
    data_type character varying(50),
    embedding_id character varying(100),
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: schema_description_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.schema_description_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: schema_description_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.schema_description_id_seq OWNED BY public.schema_description.id;


--
-- Name: shipment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shipment (
    id bigint NOT NULL,
    shipment_number character varying(30) NOT NULL,
    sales_order_id bigint NOT NULL,
    carrier character varying(100),
    tracking_number character varying(100),
    status character varying(20) DEFAULT 'PENDING'::character varying,
    shipped_date timestamp without time zone,
    delivered_date timestamp without time zone,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: shipment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.shipment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shipment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shipment_id_seq OWNED BY public.shipment.id;


--
-- Name: supplier; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.supplier (
    id bigint NOT NULL,
    code character varying(20) NOT NULL,
    name character varying(150) NOT NULL,
    contact_name character varying(100),
    email character varying(100),
    phone character varying(30),
    city character varying(50),
    country character varying(50),
    lead_time_days integer DEFAULT 7,
    rating numeric(3,2)
);


--
-- Name: supplier_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.supplier_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: supplier_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.supplier_id_seq OWNED BY public.supplier.id;


--
-- Name: warehouse; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.warehouse (
    id bigint NOT NULL,
    code character varying(20) NOT NULL,
    name character varying(100) NOT NULL,
    city character varying(50),
    state character varying(50),
    capacity_sqft numeric(12,2),
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: warehouse_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.warehouse_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: warehouse_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.warehouse_id_seq OWNED BY public.warehouse.id;


--
-- Name: zone; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zone (
    id bigint NOT NULL,
    warehouse_id bigint NOT NULL,
    code character varying(20) NOT NULL,
    name character varying(100) NOT NULL,
    zone_type character varying(30) NOT NULL,
    temperature_controlled boolean DEFAULT false,
    max_capacity_units integer,
    utilization_pct numeric(5,2) DEFAULT 0
);


--
-- Name: zone_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.zone_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: zone_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.zone_id_seq OWNED BY public.zone.id;


--
-- Name: category id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.category ALTER COLUMN id SET DEFAULT nextval('public.category_id_seq'::regclass);


--
-- Name: conversation id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation ALTER COLUMN id SET DEFAULT nextval('public.conversation_id_seq'::regclass);


--
-- Name: customer id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer ALTER COLUMN id SET DEFAULT nextval('public.customer_id_seq'::regclass);


--
-- Name: inventory id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory ALTER COLUMN id SET DEFAULT nextval('public.inventory_id_seq'::regclass);


--
-- Name: inventory_transaction id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_transaction ALTER COLUMN id SET DEFAULT nextval('public.inventory_transaction_id_seq'::regclass);


--
-- Name: location id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location ALTER COLUMN id SET DEFAULT nextval('public.location_id_seq'::regclass);


--
-- Name: product id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product ALTER COLUMN id SET DEFAULT nextval('public.product_id_seq'::regclass);


--
-- Name: prompt_template id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prompt_template ALTER COLUMN id SET DEFAULT nextval('public.prompt_template_id_seq'::regclass);


--
-- Name: purchase_order id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_order ALTER COLUMN id SET DEFAULT nextval('public.purchase_order_id_seq'::regclass);


--
-- Name: purchase_order_line id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_order_line ALTER COLUMN id SET DEFAULT nextval('public.purchase_order_line_id_seq'::regclass);


--
-- Name: query_feedback id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.query_feedback ALTER COLUMN id SET DEFAULT nextval('public.query_feedback_id_seq'::regclass);


--
-- Name: query_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.query_logs ALTER COLUMN id SET DEFAULT nextval('public.query_logs_id_seq'::regclass);


--
-- Name: sales_order id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_order ALTER COLUMN id SET DEFAULT nextval('public.sales_order_id_seq'::regclass);


--
-- Name: sales_order_line id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_order_line ALTER COLUMN id SET DEFAULT nextval('public.sales_order_line_id_seq'::regclass);


--
-- Name: schema_description id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_description ALTER COLUMN id SET DEFAULT nextval('public.schema_description_id_seq'::regclass);


--
-- Name: shipment id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shipment ALTER COLUMN id SET DEFAULT nextval('public.shipment_id_seq'::regclass);


--
-- Name: supplier id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supplier ALTER COLUMN id SET DEFAULT nextval('public.supplier_id_seq'::regclass);


--
-- Name: warehouse id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse ALTER COLUMN id SET DEFAULT nextval('public.warehouse_id_seq'::regclass);


--
-- Name: zone id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zone ALTER COLUMN id SET DEFAULT nextval('public.zone_id_seq'::regclass);


--
-- Data for Name: category; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.category (id, name, parent_category_id, description) FROM stdin;
1	Electronics	\N	Electronic devices and accessories
2	Furniture	\N	Office and warehouse furniture
3	Safety Equipment	\N	PPE and safety gear
4	Packaging	\N	Boxes, wrap, and shipping supplies
5	Food & Beverage	\N	Perishable and non-perishable items
\.


--
-- Data for Name: checkpoint_blobs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.checkpoint_blobs (thread_id, checkpoint_ns, channel, version, type, blob) FROM stdin;
test-rag-1-4de275a7		__start__	00000000000000000000000000000001.0.20624731437029808	msgpack	\\x8ba86d6573736167657390ae6f726967696e616c5f7175657279d920576861742069732074686520616e6e75616c206c6561766520706f6c6963793faa73657373696f6e5f6964aa746573742d7261672d31b0726571756972655f617070726f76616cc2a6737461747573aa70726f63657373696e67a6696e74656e74a0ab72657472795f636f756e7400ab72656163745f737465707390b170656e64696e675f746f6f6c5f63616c6c80ae6465636973696f6e5f747261636590b064657465637465645f646f6d61696e7390
test-rag-1-4de275a7		messages	00000000000000000000000000000002.0.3186759760044504	msgpack	\\x90
test-rag-1-4de275a7		react_steps	00000000000000000000000000000002.0.3186759760044504	msgpack	\\x90
test-rag-1-4de275a7		pending_tool_call	00000000000000000000000000000002.0.3186759760044504	msgpack	\\x80
test-rag-1-4de275a7		decision_trace	00000000000000000000000000000002.0.3186759760044504	msgpack	\\x90
test-rag-1-4de275a7		detected_domains	00000000000000000000000000000002.0.3186759760044504	msgpack	\\x90
test-rag-1-4de275a7		messages	00000000000000000000000000000003.0.17773581668485716	msgpack	\\x90
test-rag-1-4de275a7		decision_trace	00000000000000000000000000000003.0.17773581668485716	msgpack	\\x9183a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40d6f24666666666a76f7574636f6d65a773756363657373
test-rag-1-4de275a7		guard_issues	00000000000000000000000000000003.0.17773581668485716	msgpack	\\x90
test-rag-1-4de275a7		query_embedding	00000000000000000000000000000003.0.17773581668485716	msgpack	\\xdc0180cbbf9bb80000000000cbbfa77c0000000000cb3fa7880000000000cbbfa6400000000000cb3facfc0000000000cb3f9e040000000000cbbfae640000000000cb3f8bdc0000000000cbbf89980000000000cbbf7ca00000000000cb3f96c80000000000cbbf891c0000000000cb3f73540000000000cbbf93800000000000cb3fa0d00000000000cbbf8d8c0000000000cbbfb1fc0000000000cb3f95700000000000cbbfaf900000000000cb3fa0ec0000000000cbbfb6200000000000cb3f7ee00000000000cbbfa8480000000000cbbf96cc0000000000cbbf7e800000000000cbbf75580000000000cbbfbe540000000000cbbfa0940000000000cbbfa1c00000000000cbbf70c80000000000cbbf816c0000000000cbbf9e0c0000000000cbbf89940000000000cb3fa4b40000000000cbbf96f80000000000cbbf91140000000000cb3fb4fc0000000000cb3fa5180000000000cbbfa9680000000000cbbfa60c0000000000cbbfaa800000000000cbbfa4000000000000cbbf9bac0000000000cb3f99300000000000cbbf9cd40000000000cb3f81340000000000cb3fbd9c0000000000cb3f9db00000000000cb3fae000000000000cbbf9f480000000000cbbfa4200000000000cb3f77c00000000000cb3fb4e80000000000cb3f65000000000000cbbf95d80000000000cb3f89a40000000000cb3f86940000000000cb3f68440000000000cbbfa3e40000000000cbbfba580000000000cbbfc1580000000000cbbfa8880000000000cbbfa29c0000000000cbbfb0f40000000000cbbf98f00000000000cb3fa4bc0000000000cb3faf0c0000000000cb3fb4740000000000cb3f8b340000000000cb3fa2d40000000000cb3fb0940000000000cb3f60580000000000cb3fb5880000000000cb3f9a800000000000cbbf96a80000000000cb3f588c0000000000cb3fa7100000000000cb3f97c00000000000cbbf9acc0000000000cb3f75440000000000cbbfb37c0000000000cb3fc29c0000000000cbbfacf80000000000cbbfa5700000000000cbbf926c0000000000cbbfac280000000000cb3faabc0000000000cb3f88780000000000cbbf5c8c0000000000cbbfa1c80000000000cbbf2d140000000000cbbf69b80000000000cbbfa0bc0000000000cbbfb6300000000000cb3f9db40000000000cb3f956c0000000000cbbfa4540000000000cbbfb9cc0000000000cbbf95380000000000cbbfa0ac0000000000cb3f77b00000000000cbbf6f000000000000cb3fa8940000000000cb3fb8c80000000000cb3f9af40000000000cb3fb2580000000000cbbfa1180000000000cbbf94b00000000000cbbfb6dc0000000000cbbf4e5c0000000000cb3fb1e80000000000cbbfb5500000000000cb3f9cc00000000000cbbfa1780000000000cbbfb5240000000000cbbfa84c0000000000cbbf9e3c0000000000cb3f89040000000000cbbfa1840000000000cb3f9cc80000000000cb3fb3500000000000cbbf9dd40000000000cb3fa43c0000000000cbbfa3dc0000000000cb3f8ac40000000000cb3fa0180000000000cb3f83740000000000cb3f91e00000000000cbbf93f00000000000cb3fadf80000000000cb3f6e080000000000cb3f82040000000000cbbf87540000000000cb3fad640000000000cbbfa5000000000000cbbfae480000000000cbbfa8540000000000cbbf9f5c0000000000cb3f81bc0000000000cb3fb7240000000000cb3f80e00000000000cbbf88c00000000000cbbf92780000000000cb3f93ec0000000000cb3f7c440000000000cb3fc32c0000000000cb3f988c0000000000cb3f955c0000000000cbbf9cdc0000000000cbbf62f40000000000cb3fa0f80000000000cb3f94500000000000cbbfb0fc0000000000cbbfa5dc0000000000cbbfaa240000000000cbbfa2040000000000cb3f92d40000000000cb3f968c0000000000cb3f9ef80000000000cb3fb4a00000000000cbbfb4b00000000000cb3fa5480000000000cb3fb2780000000000cbbf996c0000000000cbbf85ec0000000000cb3f9fe00000000000cb3fab980000000000cbbfa6e80000000000cbbfb9e40000000000cbbfb9080000000000cb3fa74c0000000000cbbfa1fc0000000000cb3fa8b00000000000cb3fa8500000000000cbbfb8e40000000000cbbfa3480000000000cb3fb1000000000000cbbf913c0000000000cb3f8e700000000000cb3f68780000000000cb3fa66c0000000000cbbfc1900000000000cbbfa9780000000000cb3f8ae80000000000cbbfaef40000000000cbbf99340000000000cb3fa0f80000000000cb3fc7e40000000000cb3fb7300000000000cb3faa500000000000cb3f95f80000000000cb3fb5c00000000000cbbf9b700000000000cb3fa6280000000000cbbfb2dc0000000000cb3f8e580000000000cbbfb1ac0000000000cbbf8f140000000000cbbf9f7c0000000000cbbfac5c0000000000cbbfa1700000000000cbbfaba00000000000cbbf8ed00000000000cb3fa79c0000000000cbbfb3d00000000000cbbf8bd40000000000cbbfa5dc0000000000cbbfb9a00000000000cb3fa4b00000000000cbbfacf00000000000cb3f88900000000000cb3faa480000000000cbbfa9780000000000cb3f90200000000000cb3f75b00000000000cb3f95b40000000000cbbfa7100000000000cbbfa6a00000000000cbbfa4b00000000000cb3fc7bc0000000000cbbfbd4c0000000000cbbf95440000000000cb3f73f80000000000cb3fa0540000000000cbbf96b00000000000cb3f66d80000000000cbbfb4480000000000cb3f7c900000000000cbbf76540000000000cb3f82c40000000000cb3f81640000000000cb3fc0640000000000cb3f7cd40000000000cbbfac900000000000cbbfa0140000000000cb3f9d700000000000cb3faee00000000000cb3f38000000000000cb3fa5140000000000cbbf83400000000000cbbf7a080000000000cb3fbed00000000000cb3fa8580000000000cb3f8f440000000000cbbf90b40000000000cbbf9c280000000000cbbfb4dc0000000000cb3f7c0c0000000000cb3f88100000000000cb3fa0b40000000000cb3fa60c0000000000cb3fa2840000000000cbbfa1d40000000000cbbf347c0000000000cbbfac680000000000cbbfa7bc0000000000cbbf9c5c0000000000cbbfa0400000000000cbbfb04c0000000000cbbf8c700000000000cb3f901c0000000000cbbf78740000000000cbbfb6a80000000000cbbf98b40000000000cb3f95f80000000000cb3fb4fc0000000000cb3fa1c00000000000cbbf86c40000000000cbbf90dc0000000000cbbf750c0000000000cbbfb3540000000000cbbfb2d00000000000cb3fa4cc0000000000cbbfa4100000000000cbbfa9c00000000000cb3fbbd80000000000cbbfa1600000000000cb3fad480000000000cb3f7d640000000000cb3faf9c0000000000cb3f93bc0000000000cbbf81980000000000cb3f95480000000000cbbf934c0000000000cb3fae480000000000cbbf9a1c0000000000cbbf53100000000000cbbfb3680000000000cb3f95940000000000cbbf8d940000000000cbbf82640000000000cbbfa0bc0000000000cbbf80340000000000cbbfb66c0000000000cbbf74900000000000cb3f46540000000000cb3fb0cc0000000000cb3f93a80000000000cb3fb9fc0000000000cbbfa5780000000000cb3f99800000000000cb3fbb200000000000cb3fa8fc0000000000cb3f529c0000000000cbbf541c0000000000cbbf94cc0000000000cbbfa9b80000000000cbbface80000000000cb3f37940000000000cb3fa9980000000000cbbf937c0000000000cbbf97cc0000000000cbbf93fc0000000000cb3f9d2c0000000000cb3f670c0000000000cbbf90a40000000000cbbf81c80000000000cb3f75480000000000cb3fa4bc0000000000cbbf95240000000000cbbfb5980000000000cb3fa6480000000000cbbf80ec0000000000cb3fb27c0000000000cbbf72640000000000cbbfa8100000000000cb3fad440000000000cbbf92400000000000cb3f75840000000000cbbf789c0000000000cbbfb0c00000000000cb3f981c0000000000cb3fa02c0000000000cbbfb5800000000000cb3f94b40000000000cbbfb3f40000000000cb3f77840000000000cb3fb9c00000000000cbbfad640000000000cbbfb6080000000000cb3fae1c0000000000cbbf92ec0000000000cbbf73600000000000cb3f9ba00000000000cb3f6b440000000000cbbf88fc0000000000cbbf6d480000000000cb3f965c0000000000cbbfa74c0000000000cb3f90640000000000cbbfb3500000000000cbbfa6140000000000cb3f5af40000000000cb3fbcc40000000000cbbfb1140000000000cbbfb7000000000000cb3faec80000000000cb3f98800000000000cbbfa09c0000000000cbbf9aac0000000000cb3f75f80000000000cbbfa3cc0000000000cbbfb1800000000000cbbf67f80000000000cb3fb4600000000000cbbfa8840000000000cb3fa7140000000000cbbf97440000000000cbbfa9980000000000cbbfb7c40000000000cbbf9fe80000000000cbbfbb680000000000cb3fb6a00000000000cb3fad780000000000cb3fad740000000000cb3f71cc0000000000cb3f90f80000000000cbbfb0d00000000000cb3fa7440000000000cbbfa4280000000000cbbf7f0c0000000000cb3fb0b80000000000cbbfb1b40000000000cb3fb2c40000000000
test-rag-1-4de275a7		conversation_history	00000000000000000000000000000003.0.17773581668485716	msgpack	\\x90
test-rag-1-4de275a7		messages	00000000000000000000000000000004.0.9213189263534638	msgpack	\\x90
test-rag-1-4de275a7		decision_trace	00000000000000000000000000000004.0.9213189263534638	msgpack	\\x9283a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40d6f24666666666a76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40d6684000000000a76f7574636f6d65a773756363657373
test-rag-1-4de275a7		detected_domains	00000000000000000000000000000004.0.9213189263534638	msgpack	\\x91a24852
test-rag-1-4de275a7		messages	00000000000000000000000000000005.0.34103043054889604	msgpack	\\x90
test-rag-1-4de275a7		decision_trace	00000000000000000000000000000005.0.34103043054889604	msgpack	\\x9383a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40d6f24666666666a76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40d6684000000000a76f7574636f6d65a77375636365737383a46e6f6465b17261675f646f6d61696e5f726f75746572aa6c6174656e63795f6d73cb40d64dc666666666a76f7574636f6d65a773756363657373
test-rag-1-4de275a7		messages	00000000000000000000000000000006.0.6183653630713223	msgpack	\\x90
test-rag-1-4de275a7		decision_trace	00000000000000000000000000000006.0.6183653630713223	msgpack	\\x9483a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40d6f24666666666a76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40d6684000000000a76f7574636f6d65a77375636365737383a46e6f6465b17261675f646f6d61696e5f726f75746572aa6c6174656e63795f6d73cb40d64dc666666666a76f7574636f6d65a77375636365737383a46e6f6465ad7261675f72657472696576616caa6c6174656e63795f6d73cb4095286666666666a76f7574636f6d65a773756363657373
test-rag-1-4de275a7		conversation_history	00000000000000000000000000000006.0.6183653630713223	msgpack	\\x90
test-rag-1-4de275a7		rag_fused_results	00000000000000000000000000000006.0.6183653630713223	msgpack	\\x9786a26964af48522d383737336231656563323130a7636f6e74656e74da012a416e6e75616c204c656176653a20416c6c2066756c6c2d74696d6520656d706c6f796565732061726520656e7469746c656420746f2032342064617973206f66207061696420616e6e75616c206c65617665207065722063616c656e64617220796561722e204c6561766520616363727565732061742032206461797320706572206d6f6e74682e20556e75736564206c656176652063616e206265206361727269656420666f727761726420757020746f2035206461797320696e746f20746865206e65787420796561722e204c65617665207265717565737473206d757374206265207375626d6974746564206174206c656173742032207765656b7320696e20616476616e636520666f7220706572696f6473206c6f6e676572207468616e203320646179732ea6646f6d61696ea24852a6736f75726365b268725f706f6c6963795f323032342e706466a86d6574616461746185ab6368756e6b5f696e64657800a7636f6e74656e74da012a416e6e75616c204c656176653a20416c6c2066756c6c2d74696d6520656d706c6f796565732061726520656e7469746c656420746f2032342064617973206f66207061696420616e6e75616c206c65617665207065722063616c656e64617220796561722e204c6561766520616363727565732061742032206461797320706572206d6f6e74682e20556e75736564206c656176652063616e206265206361727269656420666f727761726420757020746f2035206461797320696e746f20746865206e65787420796561722e204c65617665207265717565737473206d757374206265207375626d6974746564206174206c656173742032207765656b7320696e20616476616e636520666f7220706572696f6473206c6f6e676572207468616e203320646179732ea6646f6d61696ea24852a6736f75726365b268725f706f6c6963795f323032342e706466a974696d657374616d70cb41da7fca03bccd10aa73696d696c6172697479cb3fdc5c0be06f273b86a26964af48522d343964613534343436643063a7636f6e74656e74da010b5369636b204c656176653a20456d706c6f7965657320726563656976652031322064617973206f662070616964207369636b206c656176652070657220796561722e2041206d65646963616c20636572746966696361746520697320726571756972656420666f7220616273656e63657320657863656564696e67203320636f6e736563757469766520646179732e20556e75736564207369636b206c6561766520646f6573206e6f7420636172727920666f72776172642e20506172742d74696d6520656d706c6f7965657320726563656976652070726f2d7261746564207369636b206c65617665206261736564206f6e20746865697220636f6e7472616374656420686f7572732ea6646f6d61696ea24852a6736f75726365b268725f706f6c6963795f323032342e706466a86d6574616461746185ab6368756e6b5f696e64657801a7636f6e74656e74da010b5369636b204c656176653a20456d706c6f7965657320726563656976652031322064617973206f662070616964207369636b206c656176652070657220796561722e2041206d65646963616c20636572746966696361746520697320726571756972656420666f7220616273656e63657320657863656564696e67203320636f6e736563757469766520646179732e20556e75736564207369636b206c6561766520646f6573206e6f7420636172727920666f72776172642e20506172742d74696d6520656d706c6f7965657320726563656976652070726f2d7261746564207369636b206c65617665206261736564206f6e20746865697220636f6e7472616374656420686f7572732ea6646f6d61696ea24852a6736f75726365b268725f706f6c6963795f323032342e706466a974696d657374616d70cb41da7fca03bccd10aa73696d696c6172697479cb3fd7a9935fa158de86a26964af48522d356465346435373137333639a7636f6e74656e74da010d4d617465726e69747920262050617465726e697479204c656176653a2046656d616c6520656d706c6f796565732061726520656e7469746c656420746f203136207765656b73206f662070616964206d617465726e697479206c656176652e204d616c6520656d706c6f7965657320726563656976652034207765656b73206f6620706169642070617465726e697479206c656176652e20426f7468206d7573742062652074616b656e2077697468696e203132206d6f6e746873206f6620746865206368696c6427732062697274682e204164646974696f6e616c20756e70616964206c65617665206f6620757020746f2036206d6f6e746873206d6179206265207265717565737465642ea6646f6d61696ea24852a6736f75726365b268725f706f6c6963795f323032342e706466a86d6574616461746185ab6368756e6b5f696e64657802a7636f6e74656e74da010d4d617465726e69747920262050617465726e697479204c656176653a2046656d616c6520656d706c6f796565732061726520656e7469746c656420746f203136207765656b73206f662070616964206d617465726e697479206c656176652e204d616c6520656d706c6f7965657320726563656976652034207765656b73206f6620706169642070617465726e697479206c656176652e20426f7468206d7573742062652074616b656e2077697468696e203132206d6f6e746873206f6620746865206368696c6427732062697274682e204164646974696f6e616c20756e70616964206c65617665206f6620757020746f2036206d6f6e746873206d6179206265207265717565737465642ea6646f6d61696ea24852a6736f75726365b268725f706f6c6963795f323032342e706466a974696d657374616d70cb41da7fca03bccd10aa73696d696c6172697479cb3fd3ccd7c05703d986a26964af48522d616434323064626330666439a7636f6e74656e74da01005265746972656d656e742042656e65666974733a20343031286b2920706c616e207769746820636f6d70616e79206d61746368206f662031303025206f6e20666972737420332520616e6420353025206f6e206e657874203225206f662073616c6172792e20456d706c6f796565732061726520656c696769626c652061667465722039302064617973206f6620656d706c6f796d656e742e2056657374696e67207363686564756c653a20323525207065722079656172206f76657220342079656172732e2046696e616e6369616c20706c616e6e696e6720636f6e73756c746174696f6e732061726520617661696c61626c6520717561727465726c792ea6646f6d61696ea24852a6736f75726365b6636f6d70656e736174696f6e5f67756964652e706466a86d6574616461746185ab6368756e6b5f696e64657802a7636f6e74656e74da01005265746972656d656e742042656e65666974733a20343031286b2920706c616e207769746820636f6d70616e79206d61746368206f662031303025206f6e20666972737420332520616e6420353025206f6e206e657874203225206f662073616c6172792e20456d706c6f796565732061726520656c696769626c652061667465722039302064617973206f6620656d706c6f796d656e742e2056657374696e67207363686564756c653a20323525207065722079656172206f76657220342079656172732e2046696e616e6369616c20706c616e6e696e6720636f6e73756c746174696f6e732061726520617661696c61626c6520717561727465726c792ea6646f6d61696ea24852a6736f75726365b6636f6d70656e736174696f6e5f67756964652e706466a974696d657374616d70cb41da7fca03bccd10aa73696d696c6172697479cb3fd34c49602c76bd86a26964af48522d336563653237613133353166a7636f6e74656e74d9ef576f726b2046726f6d20486f6d6520506f6c6963793a20456d706c6f79656573206d617920776f726b2066726f6d20686f6d6520757020746f2033206461797320706572207765656b2077697468206d616e6167657220617070726f76616c2e204120737461626c6520696e7465726e657420636f6e6e656374696f6e20616e642064656469636174656420776f726b7370616365206172652072657175697265642e20436f726520686f757273206f6620313020414d202d203420504d206d757374206265206f6273657276656420666f72206d656574696e677320616e6420636f6c6c61626f726174696f6e2ea6646f6d61696ea24852a6736f75726365b268725f706f6c6963795f323032342e706466a86d6574616461746185ab6368756e6b5f696e64657803a7636f6e74656e74d9ef576f726b2046726f6d20486f6d6520506f6c6963793a20456d706c6f79656573206d617920776f726b2066726f6d20686f6d6520757020746f2033206461797320706572207765656b2077697468206d616e6167657220617070726f76616c2e204120737461626c6520696e7465726e657420636f6e6e656374696f6e20616e642064656469636174656420776f726b7370616365206172652072657175697265642e20436f726520686f757273206f6620313020414d202d203420504d206d757374206265206f6273657276656420666f72206d656574696e677320616e6420636f6c6c61626f726174696f6e2ea6646f6d61696ea24852a6736f75726365b268725f706f6c6963795f323032342e706466a974696d657374616d70cb41da7fca03bccd10aa73696d696c6172697479cb3fd30f8a7fa8e03c86a26964af48522d326436613761386234346164a7636f6e74656e74da010f4865616c746820496e737572616e63653a2054686520636f6d70616e792070726f766964657320636f6d70726568656e73697665206865616c746820696e737572616e636520636f766572696e67206d65646963616c2c2064656e74616c2c20616e6420766973696f6e20636172652e2046616d696c7920636f76657261676520697320617661696c61626c65207769746820656d706c6f79656520636f6e747269627574696f6e206f66203230252e20416e6e75616c2064656475637469626c65206973202435303020696e646976696475616c202f2024313530302066616d696c792e204d656e74616c206865616c7468207365727669636573206172652066756c6c7920636f76657265642ea6646f6d61696ea24852a6736f75726365b6636f6d70656e736174696f6e5f67756964652e706466a86d6574616461746185ab6368756e6b5f696e64657801a7636f6e74656e74da010f4865616c746820496e737572616e63653a2054686520636f6d70616e792070726f766964657320636f6d70726568656e73697665206865616c746820696e737572616e636520636f766572696e67206d65646963616c2c2064656e74616c2c20616e6420766973696f6e20636172652e2046616d696c7920636f76657261676520697320617661696c61626c65207769746820656d706c6f79656520636f6e747269627574696f6e206f66203230252e20416e6e75616c2064656475637469626c65206973202435303020696e646976696475616c202f2024313530302066616d696c792e204d656e74616c206865616c7468207365727669636573206172652066756c6c7920636f76657265642ea6646f6d61696ea24852a6736f75726365b6636f6d70656e736174696f6e5f67756964652e706466a974696d657374616d70cb41da7fca03bccd10aa73696d696c6172697479cb3fd1e120007b7af686a26964af48522d626134663537646566666161a7636f6e74656e74d9fa426173652053616c617279205374727563747572653a2053616c61726965732061726520726576696577656420616e6e75616c6c7920696e204d617263682e205061792062616e647320617265206f7267616e697a6564206279206a6f62206c6576656c3a204a756e696f7220284c312d4c33292c2053656e696f7220284c342d4c36292c204d616e6167656d656e7420284c372d4c39292c2045786563757469766520284c31302b292e2045616368206c6576656c2068617320612073616c6172792072616e6765207769746820323574682c20353074682c20616e6420373574682070657263656e74696c652062656e63686d61726b732ea6646f6d61696ea24852a6736f75726365b6636f6d70656e736174696f6e5f67756964652e706466a86d6574616461746185ab6368756e6b5f696e64657800a7636f6e74656e74d9fa426173652053616c617279205374727563747572653a2053616c61726965732061726520726576696577656420616e6e75616c6c7920696e204d617263682e205061792062616e647320617265206f7267616e697a6564206279206a6f62206c6576656c3a204a756e696f7220284c312d4c33292c2053656e696f7220284c342d4c36292c204d616e6167656d656e7420284c372d4c39292c2045786563757469766520284c31302b292e2045616368206c6576656c2068617320612073616c6172792072616e6765207769746820323574682c20353074682c20616e6420373574682070657263656e74696c652062656e63686d61726b732ea6646f6d61696ea24852a6736f75726365b6636f6d70656e736174696f6e5f67756964652e706466a974696d657374616d70cb41da7fca03bccd10aa73696d696c6172697479cb3fd07ff6ffc002ff
test-rag-1-4de275a7		messages	00000000000000000000000000000007.0.23808075529325656	msgpack	\\x90
test-rag-1-4de275a7		decision_trace	00000000000000000000000000000007.0.23808075529325656	msgpack	\\x9583a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40d6f24666666666a76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40d6684000000000a76f7574636f6d65a77375636365737383a46e6f6465b17261675f646f6d61696e5f726f75746572aa6c6174656e63795f6d73cb40d64dc666666666a76f7574636f6d65a77375636365737383a46e6f6465ad7261675f72657472696576616caa6c6174656e63795f6d73cb4095286666666666a76f7574636f6d65a77375636365737383a46e6f6465ad7261675f67656e657261746f72aa6c6174656e63795f6d73cb40e567c333333333a76f7574636f6d65a773756363657373
test-rag-1-4de275a7		rag_sources	00000000000000000000000000000007.0.23808075529325656	msgpack	\\x91b268725f706f6c6963795f323032342e706466
test-sql-1-52887a2a		__start__	00000000000000000000000000000001.0.6192262901193353	msgpack	\\x8ba86d6573736167657390ae6f726967696e616c5f7175657279bc53686f7720746f7020352070726f6475637473206279207072696365aa73657373696f6e5f6964aa746573742d73716c2d31b0726571756972655f617070726f76616cc2a6737461747573aa70726f63657373696e67a6696e74656e74a0ab72657472795f636f756e7400ab72656163745f737465707390b170656e64696e675f746f6f6c5f63616c6c80ae6465636973696f6e5f747261636590b064657465637465645f646f6d61696e7390
test-sql-1-52887a2a		messages	00000000000000000000000000000002.0.20385790867841658	msgpack	\\x90
test-sql-1-52887a2a		react_steps	00000000000000000000000000000002.0.20385790867841658	msgpack	\\x90
test-sql-1-52887a2a		pending_tool_call	00000000000000000000000000000002.0.20385790867841658	msgpack	\\x80
test-sql-1-52887a2a		decision_trace	00000000000000000000000000000002.0.20385790867841658	msgpack	\\x90
test-sql-1-52887a2a		detected_domains	00000000000000000000000000000002.0.20385790867841658	msgpack	\\x90
test-sql-1-52887a2a		messages	00000000000000000000000000000003.0.13138599163551845	msgpack	\\x90
test-sql-1-52887a2a		decision_trace	00000000000000000000000000000003.0.13138599163551845	msgpack	\\x9183a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40e53d5ccccccccda76f7574636f6d65a773756363657373
test-sql-1-52887a2a		guard_issues	00000000000000000000000000000003.0.13138599163551845	msgpack	\\x90
test-sql-1-52887a2a		query_embedding	00000000000000000000000000000003.0.13138599163551845	msgpack	\\xdc0180cb3f94080000000000cb3f8c180000000000cb3fa8fc0000000000cb3fafe80000000000cbbfa7800000000000cb3fa99c0000000000cb3fa6300000000000cb3fb7d80000000000cb3fb94c0000000000cbbfaa380000000000cbbf79940000000000cbbf61ac0000000000cbbfa9cc0000000000cb3f9e180000000000cb3f54040000000000cbbfb23c0000000000cbbf882c0000000000cbbfb2d00000000000cbbf9f740000000000cb3fa6500000000000cbbf7e000000000000cbbfa4280000000000cb3f9c840000000000cbbf8e600000000000cbbf43f00000000000cbbfb2240000000000cbbface00000000000cb3f247c0000000000cb3fb0940000000000cbbf80b00000000000cbbfa1600000000000cb3fa8a80000000000cb3f87bc0000000000cb3fa8080000000000cbbf94600000000000cbbf55d40000000000cbbf8ecc0000000000cb3fa9580000000000cbbf8b840000000000cb3f7c540000000000cb3fa1bc0000000000cbbf84940000000000cb3f907c0000000000cb3f7e6c0000000000cb3f72e40000000000cb3f5f640000000000cb3fa8e00000000000cb3fa1d80000000000cbbf88740000000000cbbf9e200000000000cb3f96800000000000cbbf75d40000000000cbbfa7b80000000000cbbf95800000000000cbbf8d700000000000cb3fb1800000000000cb3fadb40000000000cb3f91440000000000cb3f6fd00000000000cb3f67300000000000cb3f9e000000000000cbbfa1440000000000cb3fa4dc0000000000cbbf9f100000000000cbbfab7c0000000000cbbfbb6c0000000000cbbf98200000000000cbbf7e940000000000cbbfb2980000000000cb3fa3400000000000cb3fabe00000000000cbbfaec00000000000cbbfa3340000000000cbbfa2c00000000000cb3f77200000000000cb3f8b140000000000cbbf78540000000000cb3f6ca40000000000cb3fbec00000000000cbbfaba80000000000cbbf96e00000000000cb3fab580000000000cb3fa8000000000000cb3fb9480000000000cb3f72340000000000cb3f80d40000000000cbbf83800000000000cbbfa26c0000000000cb3f8c040000000000cbbf94300000000000cbbfa3240000000000cb3f60240000000000cbbfa9ec0000000000cbbfaa2c0000000000cbbfae400000000000cb3fb2cc0000000000cbbf8c180000000000cb3fa2d40000000000cbbf93b00000000000cb3f8fd80000000000cbbf963c0000000000cb3fa9040000000000cbbf22bc0000000000cbbf81980000000000cbbfb1500000000000cbbfab780000000000cb3f94980000000000cb3f88000000000000cbbf84140000000000cb3f45f80000000000cb3fa7dc0000000000cb3fc0580000000000cbbf79780000000000cbbfa5180000000000cbbfac9c0000000000cbbf99900000000000cb3f9eac0000000000cb3fa2080000000000cb3fb1640000000000cbbf92680000000000cbbf94500000000000cbbf89d80000000000cbbfbc400000000000cbbf95d80000000000cb3fa1dc0000000000cb3f87600000000000cbbf994c0000000000cbbf96100000000000cbbf94b80000000000cbbfa06c0000000000cbbfa4bc0000000000cbbfb1380000000000cbbfa2840000000000cbbfa9600000000000cb3f89240000000000cbbfb9300000000000cbbfa10c0000000000cb3fafbc0000000000cbbfa0d00000000000cb3fb3640000000000cbbfb2740000000000cbbfaa500000000000cbbfa4540000000000cbbf93ec0000000000cb3f936c0000000000cbbfb0ec0000000000cbbfa54c0000000000cb3fab940000000000cbbf9d500000000000cbbfb8040000000000cbbf77d00000000000cb3f6a340000000000cbbf967c0000000000cb3fa6d80000000000cbbfc1700000000000cb3f95580000000000cb3fb7040000000000cbbf88000000000000cb3f95ec0000000000cb3faa040000000000cbbfc1480000000000cb3fa9f00000000000cb3fae900000000000cbbfabe00000000000cbbf91240000000000cb3fba140000000000cb3f4e500000000000cbbf82d40000000000cbbfb9700000000000cb3fadf00000000000cbbfa0200000000000cbbf80bc0000000000cb3fb3240000000000cb3f97800000000000cb3fb5880000000000cbbfa1280000000000cbbfb5080000000000cb3fae800000000000cbbfc5bc0000000000cb3fb9300000000000cb3fbeec0000000000cbbf9afc0000000000cbbf8e0c0000000000cb3f9ce00000000000cb3fac800000000000cbbfb65c0000000000cb3f78ec0000000000cb3fb9280000000000cb3f746c0000000000cbbf9b900000000000cbbfa8380000000000cb3f53c00000000000cb3f8e380000000000cb3fa4300000000000cb3f94d40000000000cbbfb23c0000000000cb3f499c0000000000cbbfa5e00000000000cbbfb0680000000000cbbfad8c0000000000cb3f8ba40000000000cb3fa4e40000000000cb3f9e2c0000000000cbbf893c0000000000cbbf56400000000000cb3fa9d00000000000cbbfa9540000000000cbbfa9680000000000cb3f7e900000000000cb3fa0cc0000000000cbbf798c0000000000cb3f9fa80000000000cbbfb6800000000000cbbf929c0000000000cbbfb2cc0000000000cb3fb1840000000000cbbf89740000000000cbbfb9240000000000cb3faefc0000000000cb3f97f40000000000cbbf959c0000000000cb3fc0f40000000000cb3fa0040000000000cbbfa0240000000000cbbfbf2c0000000000cbbf90e00000000000cbbf758c0000000000cbbfa8700000000000cbbfae640000000000cb3f62b40000000000cbbfa0640000000000cbbf95500000000000cbbf90d40000000000cb3f9fe80000000000cbbfba600000000000cb3fa00c0000000000cb3f75180000000000cb3f90080000000000cbbfa8880000000000cbbfb2dc0000000000cb3fb1a40000000000cbbf7c680000000000cbbfc1cc0000000000cbbfb4680000000000cb3fa4640000000000cb3f91640000000000cb3f9a440000000000cb3fabe00000000000cb3f9a680000000000cbbfb3400000000000cb3f83dc0000000000cb3fb35c0000000000cb3fa3e40000000000cbbfb6700000000000cb3f8ab40000000000cb3fac100000000000cb3f33f40000000000cb3f75940000000000cb3faec80000000000cbbfa5a40000000000cbbf9c040000000000cbbfb2940000000000cbbfad940000000000cbbfa4440000000000cbbfb8480000000000cb3fa6f00000000000cb3f7b8c0000000000cbbfb1580000000000cbbfaa580000000000cb3f9ba40000000000cbbfaa440000000000cbbf956c0000000000cb3fb0680000000000cbbfa06c0000000000cbbfb0880000000000cbbf7d000000000000cbbfb4280000000000cb3f9b0c0000000000cbbf984c0000000000cb3f8cf80000000000cb3fa6a40000000000cb3fa4180000000000cbbf7f480000000000cb3f82d40000000000cb3f95340000000000cb3fa4300000000000cbbf7e340000000000cbbfb4680000000000cbbf98200000000000cb3fabdc0000000000cb3f85880000000000cb3fa5680000000000cbbf932c0000000000cbbfa6280000000000cb3fa1940000000000cbbfb1cc0000000000cb3f81d00000000000cb3fafc00000000000cb3f77f00000000000cb3fb4540000000000cb3fadb00000000000cbbfb2500000000000cbbf8c0c0000000000cbbfb2580000000000cb3fa3040000000000cb3f80240000000000cbbf942c0000000000cbbf96880000000000cbbf72980000000000cbbf673c0000000000cb3f90e80000000000cb3fb42c0000000000cb3f81100000000000cb3f68880000000000cb3f7fb40000000000cbbfc4080000000000cbbf87380000000000cbbfada00000000000cb3fa5d00000000000cb3fa0fc0000000000cb3f53600000000000cbbfa94c0000000000cbbfa4cc0000000000cbbfa9e00000000000cbbf8a900000000000cb3f96500000000000cbbfba640000000000cbbfa0180000000000cbbfa3280000000000cbbf86a00000000000cb3f9cf40000000000cbbfb6100000000000cb3f92bc0000000000cbbfa6180000000000cbbfae380000000000cb3f99440000000000cbbfb70c0000000000cb3f99680000000000cbbf87b00000000000cb3fb5100000000000cbbf8e740000000000cbbf89640000000000cbbfb1200000000000cbbfb78c0000000000cbbfa6100000000000cbbf9b440000000000cbbfabec0000000000cbbfbbd00000000000cb3fb6900000000000cb3f86d80000000000cb3fb08c0000000000cb3fbaec0000000000cbbf99640000000000cb3fa0880000000000cbbfa0e80000000000cb3f80880000000000cb3f9f800000000000cbbf73380000000000cb3f67100000000000cbbfa7600000000000cb3f7fb80000000000cb3f65480000000000cb3f9a240000000000cb3fa87c0000000000cbbf9b780000000000cb3fb1b80000000000cb3f7ad80000000000cb3fb3e40000000000cbbfc1ac0000000000cb3faa5c0000000000cbbf8e800000000000cb3fa8100000000000cbbfb0d80000000000cb3fa3100000000000cb3f8c300000000000cb3fb6d00000000000cb3fa5c80000000000cb3fa52c0000000000cbbf95380000000000cbbf94bc0000000000cb3f69f00000000000cb3fbe580000000000cbbf96b00000000000cbbf66880000000000
test-sql-1-52887a2a		conversation_history	00000000000000000000000000000003.0.13138599163551845	msgpack	\\x90
test-sql-1-52887a2a		messages	00000000000000000000000000000004.0.38727839415589693	msgpack	\\x90
test-sql-1-52887a2a		decision_trace	00000000000000000000000000000004.0.38727839415589693	msgpack	\\x9283a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40e53d5ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40e55d0ccccccccda76f7574636f6d65a773756363657373
test-sql-1-52887a2a		detected_domains	00000000000000000000000000000004.0.38727839415589693	msgpack	\\x92a750524f44554354a353514c
test-sql-1-52887a2a		messages	00000000000000000000000000000005.0.2629590109337936	msgpack	\\x90
test-sql-1-52887a2a		decision_trace	00000000000000000000000000000005.0.2629590109337936	msgpack	\\x9383a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40e53d5ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40e55d0ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b773716c5f636f6d706c65786974795f6465746563746f72aa6c6174656e63795f6d73cb40e574a99999999aa76f7574636f6d65a773756363657373
test-sql-1-52887a2a		messages	00000000000000000000000000000006.0.867226227649625	msgpack	\\x90
test-sql-1-52887a2a		decision_trace	00000000000000000000000000000006.0.867226227649625	msgpack	\\x9483a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40e53d5ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40e55d0ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b773716c5f636f6d706c65786974795f6465746563746f72aa6c6174656e63795f6d73cb40e574a99999999aa76f7574636f6d65a77375636365737383a46e6f6465ac73716c5f63616368655f6c32aa6c6174656e63795f6d73cb4016cccccccccccda76f7574636f6d65a773756363657373
test-sql-1-52887a2a		messages	00000000000000000000000000000007.0.09580126371228426	msgpack	\\x90
test-sql-1-52887a2a		decision_trace	00000000000000000000000000000007.0.09580126371228426	msgpack	\\x9583a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40e53d5ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40e55d0ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b773716c5f636f6d706c65786974795f6465746563746f72aa6c6174656e63795f6d73cb40e574a99999999aa76f7574636f6d65a77375636365737383a46e6f6465ac73716c5f63616368655f6c32aa6c6174656e63795f6d73cb4016cccccccccccda76f7574636f6d65a77375636365737383a46e6f6465b473716c5f736368656d615f726574726965766572aa6c6174656e63795f6d73cb40a3bd3333333333a76f7574636f6d65a773756363657373
test-sql-1-52887a2a		tables_used	00000000000000000000000000000007.0.09580126371228426	msgpack	\\x95a9696e76656e746f7279a8737570706c696572a770726f64756374ab73616c65735f6f72646572ae70757263686173655f6f72646572
test-sql-1-52887a2a		messages	00000000000000000000000000000008.0.2197845575525217	msgpack	\\x90
test-sql-1-52887a2a		decision_trace	00000000000000000000000000000008.0.2197845575525217	msgpack	\\x9683a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40e53d5ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40e55d0ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b773716c5f636f6d706c65786974795f6465746563746f72aa6c6174656e63795f6d73cb40e574a99999999aa76f7574636f6d65a77375636365737383a46e6f6465ac73716c5f63616368655f6c32aa6c6174656e63795f6d73cb4016cccccccccccda76f7574636f6d65a77375636365737383a46e6f6465b473716c5f736368656d615f726574726965766572aa6c6174656e63795f6d73cb40a3bd3333333333a76f7574636f6d65a77375636365737383a46e6f6465ad73716c5f67656e657261746f72aa6c6174656e63795f6d73cb40f56c3b33333333a76f7574636f6d65a773756363657373
test-sql-1-52887a2a		tables_used	00000000000000000000000000000008.0.2197845575525217	msgpack	\\x91a770726f64756374
test-sql-1-52887a2a		messages	00000000000000000000000000000009.0.5595618818582142	msgpack	\\x90
test-sql-1-52887a2a		decision_trace	00000000000000000000000000000009.0.5595618818582142	msgpack	\\x9783a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40e53d5ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40e55d0ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b773716c5f636f6d706c65786974795f6465746563746f72aa6c6174656e63795f6d73cb40e574a99999999aa76f7574636f6d65a77375636365737383a46e6f6465ac73716c5f63616368655f6c32aa6c6174656e63795f6d73cb4016cccccccccccda76f7574636f6d65a77375636365737383a46e6f6465b473716c5f736368656d615f726574726965766572aa6c6174656e63795f6d73cb40a3bd3333333333a76f7574636f6d65a77375636365737383a46e6f6465ad73716c5f67656e657261746f72aa6c6174656e63795f6d73cb40f56c3b33333333a76f7574636f6d65a77375636365737383a46e6f6465ad73716c5f76616c696461746f72aa6c6174656e63795f6d73cb0000000000000000a76f7574636f6d65a773756363657373
test-sql-1-52887a2a		validation_errors	00000000000000000000000000000009.0.5595618818582142	msgpack	\\x90
test-sql-1-52887a2a		messages	00000000000000000000000000000010.0.9903888885742909	msgpack	\\x90
test-sql-1-52887a2a		decision_trace	00000000000000000000000000000010.0.9903888885742909	msgpack	\\x9883a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40e53d5ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40e55d0ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b773716c5f636f6d706c65786974795f6465746563746f72aa6c6174656e63795f6d73cb40e574a99999999aa76f7574636f6d65a77375636365737383a46e6f6465ac73716c5f63616368655f6c32aa6c6174656e63795f6d73cb4016cccccccccccda76f7574636f6d65a77375636365737383a46e6f6465b473716c5f736368656d615f726574726965766572aa6c6174656e63795f6d73cb40a3bd3333333333a76f7574636f6d65a77375636365737383a46e6f6465ad73716c5f67656e657261746f72aa6c6174656e63795f6d73cb40f56c3b33333333a76f7574636f6d65a77375636365737383a46e6f6465ad73716c5f76616c696461746f72aa6c6174656e63795f6d73cb0000000000000000a76f7574636f6d65a77375636365737383a46e6f6465ac73716c5f617070726f76616caa6c6174656e63795f6d73cb0000000000000000a76f7574636f6d65a773756363657373
test-sql-1-52887a2a		messages	00000000000000000000000000000011.0.43487827726728223	msgpack	\\x90
test-sql-1-52887a2a		decision_trace	00000000000000000000000000000011.0.43487827726728223	msgpack	\\x9983a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40e53d5ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40e55d0ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b773716c5f636f6d706c65786974795f6465746563746f72aa6c6174656e63795f6d73cb40e574a99999999aa76f7574636f6d65a77375636365737383a46e6f6465ac73716c5f63616368655f6c32aa6c6174656e63795f6d73cb4016cccccccccccda76f7574636f6d65a77375636365737383a46e6f6465b473716c5f736368656d615f726574726965766572aa6c6174656e63795f6d73cb40a3bd3333333333a76f7574636f6d65a77375636365737383a46e6f6465ad73716c5f67656e657261746f72aa6c6174656e63795f6d73cb40f56c3b33333333a76f7574636f6d65a77375636365737383a46e6f6465ad73716c5f76616c696461746f72aa6c6174656e63795f6d73cb0000000000000000a76f7574636f6d65a77375636365737383a46e6f6465ac73716c5f617070726f76616caa6c6174656e63795f6d73cb0000000000000000a76f7574636f6d65a77375636365737383a46e6f6465ac73716c5f6578656375746f72aa6c6174656e63795f6d73cb4023000000000000a76f7574636f6d65a773756363657373
test-sql-1-52887a2a		sql_results	00000000000000000000000000000011.0.43487827726728223	msgpack	\\x9583a2696401a3736b75ae534b552d4c4150544f502d303031aa756e69745f7072696365cb408c1feb851eb85283a2696404a3736b75ac534b552d4445534b2d303031aa756e69745f7072696365cb40812feb851eb85283a2696402a3736b75ae534b552d5441424c45542d303031aa756e69745f7072696365cb407f3fd70a3d70a483a2696405a3736b75ad534b552d43484149522d303031aa756e69745f7072696365cb4075dfd70a3d70a483a2696406a3736b75ac534b552d484841542d303031aa756e69745f7072696365cb4038fd70a3d70a3d
test-sql-1-52887a2a		messages	00000000000000000000000000000012.0.22339826042277777	msgpack	\\x90
test-sql-1-52887a2a		decision_trace	00000000000000000000000000000012.0.22339826042277777	msgpack	\\x9a83a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40e53d5ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40e55d0ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b773716c5f636f6d706c65786974795f6465746563746f72aa6c6174656e63795f6d73cb40e574a99999999aa76f7574636f6d65a77375636365737383a46e6f6465ac73716c5f63616368655f6c32aa6c6174656e63795f6d73cb4016cccccccccccda76f7574636f6d65a77375636365737383a46e6f6465b473716c5f736368656d615f726574726965766572aa6c6174656e63795f6d73cb40a3bd3333333333a76f7574636f6d65a77375636365737383a46e6f6465ad73716c5f67656e657261746f72aa6c6174656e63795f6d73cb40f56c3b33333333a76f7574636f6d65a77375636365737383a46e6f6465ad73716c5f76616c696461746f72aa6c6174656e63795f6d73cb0000000000000000a76f7574636f6d65a77375636365737383a46e6f6465ac73716c5f617070726f76616caa6c6174656e63795f6d73cb0000000000000000a76f7574636f6d65a77375636365737383a46e6f6465ac73716c5f6578656375746f72aa6c6174656e63795f6d73cb4023000000000000a76f7574636f6d65a77375636365737383a46e6f6465ac73716c5f726573706f6e7365aa6c6174656e63795f6d73cb40e5347666666666a76f7574636f6d65a773756363657373
test-compound-1-5774cb33		__start__	00000000000000000000000000000001.0.8103278034384275	msgpack	\\x8ba86d6573736167657390ae6f726967696e616c5f7175657279d9355768617420697320746865206c6561766520706f6c69637920616e642073686f77206d6520746f74616c20656d706c6f796565733faa73657373696f6e5f6964af746573742d636f6d706f756e642d31b0726571756972655f617070726f76616cc2a6737461747573aa70726f63657373696e67a6696e74656e74a0ab72657472795f636f756e7400ab72656163745f737465707390b170656e64696e675f746f6f6c5f63616c6c80ae6465636973696f6e5f747261636590b064657465637465645f646f6d61696e7390
test-compound-1-5774cb33		messages	00000000000000000000000000000002.6.354093502591862e-05	msgpack	\\x90
test-compound-1-5774cb33		react_steps	00000000000000000000000000000002.6.354093502591862e-05	msgpack	\\x90
test-compound-1-5774cb33		pending_tool_call	00000000000000000000000000000002.6.354093502591862e-05	msgpack	\\x80
test-compound-1-5774cb33		decision_trace	00000000000000000000000000000002.6.354093502591862e-05	msgpack	\\x90
test-compound-1-5774cb33		detected_domains	00000000000000000000000000000002.6.354093502591862e-05	msgpack	\\x90
test-compound-1-5774cb33		messages	00000000000000000000000000000003.0.2571108248560736	msgpack	\\x90
test-compound-1-5774cb33		decision_trace	00000000000000000000000000000003.0.2571108248560736	msgpack	\\x9183a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40e5721ccccccccda76f7574636f6d65a773756363657373
test-compound-1-5774cb33		guard_issues	00000000000000000000000000000003.0.2571108248560736	msgpack	\\x90
test-compound-1-5774cb33		query_embedding	00000000000000000000000000000003.0.2571108248560736	msgpack	\\xdc0180cb3f56500000000000cbbf98800000000000cb3fa7880000000000cbbfa6e00000000000cb3facf80000000000cbbf633c0000000000cbbfb01c0000000000cb3fa0cc0000000000cbbf81180000000000cb3f9b7c0000000000cbbfa1c00000000000cbbf93a80000000000cbbfa5740000000000cbbfa42c0000000000cb3fb7540000000000cbbfb7f00000000000cbbfc4240000000000cbbf77140000000000cbbfadfc0000000000cbbf8ef80000000000cbbf9d200000000000cbbf975c0000000000cbbf91000000000000cbbfa4100000000000cbbf9a800000000000cb3fa1f40000000000cbbfaca00000000000cbbfb3440000000000cb3fa2800000000000cbbf81d00000000000cb3f75a40000000000cbbf9c500000000000cbbf82240000000000cb3f9fe00000000000cbbfa76c0000000000cbbf93a00000000000cb3faad00000000000cb3fb5800000000000cbbfb1000000000000cb3f94f80000000000cbbfbd200000000000cb3fa1400000000000cbbf72c00000000000cb3fa5fc0000000000cbbfa0c00000000000cb3fa9f80000000000cb3f9fe40000000000cbbfa3200000000000cb3fa3000000000000cbbfa3980000000000cb3f946c0000000000cbbf88200000000000cbbf9fac0000000000cbbf973c0000000000cbbfa89c0000000000cb3fa0740000000000cbbf70440000000000cbbf99cc0000000000cbbfa3000000000000cbbfb8980000000000cbbf7eb80000000000cbbfc1a80000000000cb3fa3580000000000cbbfa1cc0000000000cbbf81a80000000000cbbfa4f80000000000cb3f9c200000000000cb3f98f80000000000cb3facd40000000000cbbf215c0000000000cb3f91bc0000000000cbbf8f340000000000cb3f83f00000000000cb3f60280000000000cbbfa28c0000000000cb3f7fac0000000000cb3fa4fc0000000000cb3f799c0000000000cb3fa0540000000000cb3f863c0000000000cbbfb0740000000000cb3fbe040000000000cbbf82500000000000cb3f75780000000000cbbf8f740000000000cbbfa3880000000000cbbfa1440000000000cb3fb1440000000000cb3fa6a80000000000cbbfb0180000000000cbbf99e80000000000cbbfb4000000000000cb3f91100000000000cbbfb56c0000000000cb3fa16c0000000000cb3fa1080000000000cbbfadec0000000000cbbf86440000000000cbbf81a40000000000cbbf9c180000000000cbbfa15c0000000000cb3fa0080000000000cbbf95b40000000000cb3fb1480000000000cb3fa5c00000000000cb3fb3140000000000cb3f7cb00000000000cbbf5c100000000000cbbfa83c0000000000cbbfa7180000000000cb3f719c0000000000cbbfa8680000000000cbbf56b00000000000cbbfa2700000000000cbbfb8700000000000cbbfc0900000000000cb3f61cc0000000000cbbf80c40000000000cbbf99880000000000cb3f7ac40000000000cb3fb1e00000000000cbbfa9240000000000cbbfa18c0000000000cbbfa7980000000000cbbf89880000000000cbbf62780000000000cbbfa3ec0000000000cbbf9c980000000000cbbf90900000000000cb3f9cb00000000000cbbf98700000000000cb3f80740000000000cbbfa0380000000000cb3f6c740000000000cbbf99dc0000000000cbbfb1c40000000000cb3f3e040000000000cbbfa36c0000000000cbbfa4340000000000cb3f7fc00000000000cbbf93100000000000cbbf7d0c0000000000cbbf69500000000000cb3fa8b40000000000cb3f7f340000000000cb3fb7140000000000cb3f9c580000000000cbbf85940000000000cbbf50700000000000cbbfb0440000000000cbbf70100000000000cb3faaac0000000000cb3f89d00000000000cbbf91600000000000cbbfb6700000000000cbbfa8c40000000000cb3fa2000000000000cb3fa2a00000000000cb3faed80000000000cb3fa6180000000000cbbf91040000000000cbbf78180000000000cb3fb6c00000000000cb3f5d740000000000cbbfaa480000000000cbbf8f2c0000000000cb3fab500000000000cbbfa4cc0000000000cbbfac140000000000cbbfa83c0000000000cb3f9d000000000000cbbfac240000000000cb3fa89c0000000000cbbfb10c0000000000cbbf63cc0000000000cbbfa22c0000000000cb3f93d40000000000cb3f7f840000000000cb3fa2680000000000cb3f9f940000000000cb3fa8e40000000000cbbfaa380000000000cbbfab7c0000000000cb3f8de80000000000cbbfa9f00000000000cbbfa1f80000000000cb3fa6f00000000000cb3fc4d80000000000cb3fa5940000000000cb3fa7980000000000cb3f85b80000000000cb3fb71c0000000000cb3f9f8c0000000000cb3f8f440000000000cbbf9f1c0000000000cbbf94b40000000000cb3f97a80000000000cbbf853c0000000000cbbfa8780000000000cbbfb8e40000000000cbbfa4680000000000cbbfab340000000000cb3fad680000000000cb3fa64c0000000000cbbfadd00000000000cb3facf80000000000cbbfaa680000000000cbbfc1240000000000cbbfa2a00000000000cbbf97e80000000000cb3f9c300000000000cbbfa2000000000000cbbfaf480000000000cb3f93d80000000000cb3fb2cc0000000000cbbf73240000000000cbbfbd6c0000000000cbbf91200000000000cbbfa3dc0000000000cb3fb0180000000000cbbfc7d40000000000cb3f7e900000000000cbbf992c0000000000cbbf94340000000000cbbf76d00000000000cb3f95280000000000cb3fa2f40000000000cbbf82e00000000000cbbf8d980000000000cbbf87880000000000cb3f46400000000000cb3fc2fc0000000000cb3f96880000000000cbbfb9c40000000000cbbfbdd80000000000cbbf8ca80000000000cb3fb1ec0000000000cbbfa1ac0000000000cb3faaa00000000000cb3f932c0000000000cb3f99800000000000cb3fb2440000000000cb3fa53c0000000000cbbfaafc0000000000cb3f93300000000000cb3f7db40000000000cbbf9aa40000000000cbbf87200000000000cb3f723c0000000000cb3f88f40000000000cb3fad700000000000cb3f97580000000000cbbfb0d40000000000cb3f9a040000000000cbbfaf540000000000cbbfb1540000000000cb3fa9180000000000cbbfac600000000000cbbf98b00000000000cb3fa2500000000000cb3f9fc40000000000cbbfab000000000000cbbfb6940000000000cb3f9fc80000000000cb3fa5e00000000000cb3f95c00000000000cb3fb6b80000000000cbbf93680000000000cbbfa0180000000000cb3f84440000000000cbbfb7700000000000cbbfc4e40000000000cb3f94080000000000cbbf931c0000000000cbbfa0480000000000cb3fb1300000000000cbbf6fbc0000000000cb3fb2ec0000000000cbbf88280000000000cb3fb7a40000000000cbbfb0040000000000cbbfa85c0000000000cbbf82680000000000cb3f8b900000000000cb3fb0dc0000000000cbbf74680000000000cbbf48400000000000cbbfb9c00000000000cb3fb7f00000000000cb3f6f800000000000cbbf91040000000000cb3f8e200000000000cbbfb2100000000000cbbf94e00000000000cbbfb3b40000000000cbbf99440000000000cb3fa7b40000000000cb3fa8680000000000cb3fb4c80000000000cbbf97140000000000cbbf9aec0000000000cb3fb6440000000000cb3f9f4c0000000000cb3f78640000000000cbbfa19c0000000000cbbfa23c0000000000cbbf90040000000000cbbfa2340000000000cb3fbb900000000000cb3f73dc0000000000cbbfa5b40000000000cbbf8d500000000000cbbfa17c0000000000cb3f9d0c0000000000cb3f8a640000000000cbbfa2f80000000000cb3f6f700000000000cbbfa6b00000000000cbbfabe00000000000cbbf9c600000000000cbbfb7f00000000000cb3faa500000000000cbbf53240000000000cb3f9da00000000000cb3fa6740000000000cbbf712c0000000000cb3fac7c0000000000cb3fb3940000000000cbbfa68c0000000000cb3f91c40000000000cb3fa1900000000000cb3f9c1c0000000000cb3f64080000000000cbbfb5bc0000000000cb3faf900000000000cb3f962c0000000000cbbf947c0000000000cb3fbad00000000000cb3f6b000000000000cb3f9f780000000000cb3fa1780000000000cbbfa8080000000000cbbfac300000000000cb3f94800000000000cb3fa15c0000000000cbbfb1a80000000000cbbf66cc0000000000cb3fa0700000000000cbbfa6480000000000cb3fa06c0000000000cbbfb4640000000000cbbf97d80000000000cbbf96300000000000cb3fb53c0000000000cbbfa3100000000000cbbfb4440000000000cb3faa4c0000000000cb3fa7380000000000cb3fac800000000000cbbfa24c0000000000cb3f6f1c0000000000cbbfb8340000000000cbbf99d80000000000cb3f88e80000000000cb3fb0300000000000cbbf7a600000000000cb3fbbf00000000000cbbfa7700000000000cbbf6ab40000000000cbbfbb2c0000000000cbbf8b400000000000cbbfac080000000000cb3fb1f40000000000cb3fb7f00000000000cb3fba340000000000cb3f98880000000000cbbfb2680000000000cbbfb5980000000000cb3fa1a40000000000cbbfa6a80000000000cb3f9ac00000000000cb3fad840000000000cbbfb7b40000000000cb3f9f680000000000
test-compound-1-5774cb33		conversation_history	00000000000000000000000000000003.0.2571108248560736	msgpack	\\x90
test-compound-1-5774cb33		messages	00000000000000000000000000000004.0.7834428818718785	msgpack	\\x90
test-compound-1-5774cb33		decision_trace	00000000000000000000000000000004.0.7834428818718785	msgpack	\\x9283a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40e5721ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40e548a666666666a76f7574636f6d65a773756363657373
test-compound-1-5774cb33		detected_domains	00000000000000000000000000000004.0.7834428818718785	msgpack	\\x92a24852a353514c
test-compound-1-5774cb33		messages	00000000000000000000000000000005.0.8931033896742542	msgpack	\\x90
test-compound-1-5774cb33		decision_trace	00000000000000000000000000000005.0.8931033896742542	msgpack	\\x9383a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40e5721ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40e548a666666666a76f7574636f6d65a77375636365737383a46e6f6465b1636f6d706f756e645f706172616c6c656caa6c6174656e63795f6d73cb410039119999999aa76f7574636f6d65a773756363657373
test-compound-1-5774cb33		messages	00000000000000000000000000000006.0.9842096143120652	msgpack	\\x90
test-compound-1-5774cb33		decision_trace	00000000000000000000000000000006.0.9842096143120652	msgpack	\\x9483a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40e5721ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40e548a666666666a76f7574636f6d65a77375636365737383a46e6f6465b1636f6d706f756e645f706172616c6c656caa6c6174656e63795f6d73cb410039119999999aa76f7574636f6d65a77375636365737383a46e6f6465b073757065727669736f725f6d65726765aa6c6174656e63795f6d73cb0000000000000000a76f7574636f6d65a773756363657373
test-compound-2-b99bb20f		__start__	00000000000000000000000000000001.0.6568530195814937	msgpack	\\x8ba86d6573736167657390ae6f726967696e616c5f7175657279d9405768617420697320746865206c6561766520706f6c69637920616e642073686f77206d6520746f74616c2070726f64756374732062792063617465676f72793faa73657373696f6e5f6964af746573742d636f6d706f756e642d32b0726571756972655f617070726f76616cc2a6737461747573aa70726f63657373696e67a6696e74656e74a0ab72657472795f636f756e7400ab72656163745f737465707390b170656e64696e675f746f6f6c5f63616c6c80ae6465636973696f6e5f747261636590b064657465637465645f646f6d61696e7390
test-compound-2-b99bb20f		messages	00000000000000000000000000000002.0.41336010073608076	msgpack	\\x90
test-compound-2-b99bb20f		react_steps	00000000000000000000000000000002.0.41336010073608076	msgpack	\\x90
test-compound-2-b99bb20f		pending_tool_call	00000000000000000000000000000002.0.41336010073608076	msgpack	\\x80
test-compound-2-b99bb20f		decision_trace	00000000000000000000000000000002.0.41336010073608076	msgpack	\\x90
test-compound-2-b99bb20f		detected_domains	00000000000000000000000000000002.0.41336010073608076	msgpack	\\x90
test-compound-2-b99bb20f		messages	00000000000000000000000000000003.0.40284794310255156	msgpack	\\x90
test-compound-2-b99bb20f		decision_trace	00000000000000000000000000000003.0.40284794310255156	msgpack	\\x9183a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40d670a000000000a76f7574636f6d65a773756363657373
test-compound-2-b99bb20f		guard_issues	00000000000000000000000000000003.0.40284794310255156	msgpack	\\x90
test-compound-2-b99bb20f		query_embedding	00000000000000000000000000000003.0.40284794310255156	msgpack	\\xdc0180cbbf8d8c0000000000cbbf97340000000000cb3f82680000000000cbbf72e00000000000cb3f7c3c0000000000cbbfb6740000000000cbbfb0040000000000cb3fa3f80000000000cb3f9ff00000000000cb3f90540000000000cbbfaa540000000000cbbf902c0000000000cbbf91080000000000cbbf9c480000000000cb3fa5740000000000cbbfc0680000000000cbbfb5980000000000cbbfb28c0000000000cbbf8c2c0000000000cbbf92e00000000000cbbfb30c0000000000cbbf66f00000000000cb3f91940000000000cbbfa5780000000000cb3f92a00000000000cb3f9c2c0000000000cbbfb20c0000000000cbbf8db80000000000cb3fa6c40000000000cbbf93b00000000000cbbf9aa80000000000cb3fa7180000000000cb3fa2640000000000cb3f8c4c0000000000cb3fa8280000000000cbbfb1c40000000000cb3f95380000000000cb3fa9100000000000cbbfb5040000000000cb3f4e580000000000cbbfa8440000000000cbbf815c0000000000cb3f91a00000000000cb3fac040000000000cbbfb2680000000000cb3fb38c0000000000cb3fb0200000000000cbbf9cc00000000000cb3f849c0000000000cbbf93b40000000000cb3f91180000000000cbbfae240000000000cbbf8b880000000000cbbf8bac0000000000cbbfab280000000000cb3fa0540000000000cbbf9b5c0000000000cbbfa7840000000000cb3f9c2c0000000000cbbfb79c0000000000cbbfb0180000000000cbbfc4fc0000000000cb3fbc900000000000cbbf93400000000000cbbf937c0000000000cbbfab780000000000cbbf90140000000000cbbfb1180000000000cb3f751c0000000000cb3f9e380000000000cb3fb41c0000000000cb3fae840000000000cbbfa31c0000000000cbbfa7fc0000000000cbbf85800000000000cb3f6ea40000000000cb3faf9c0000000000cbbfa2500000000000cb3fa91c0000000000cbbf78a40000000000cbbf9e440000000000cb3fbb140000000000cb3f8e380000000000cb3f6e600000000000cb3f87200000000000cb3f77200000000000cbbfa1700000000000cb3fa5500000000000cb3faa140000000000cbbfba940000000000cb3f75180000000000cbbfb1300000000000cbbfb1d40000000000cbbfb0ac0000000000cbbf92980000000000cb3fb2880000000000cb3f72400000000000cbbfaac40000000000cbbfa9000000000000cbbfa1a40000000000cbbf8b5c0000000000cb3facf00000000000cbbfa0680000000000cb3f6cf00000000000cb3f92100000000000cbbfa4880000000000cb3f8a2c0000000000cb3f6df00000000000cb3f75480000000000cbbfa8b00000000000cbbfa3ec0000000000cbbf97200000000000cb3fa89c0000000000cb3f65680000000000cbbfb5ac0000000000cbbfbcf80000000000cb3fa1480000000000cbbf8b600000000000cbbf90bc0000000000cbbf70040000000000cb3fb9fc0000000000cbbfbb540000000000cbbface40000000000cb3f89b00000000000cb3f65540000000000cb3fa2900000000000cb3f72bc0000000000cbbf70800000000000cb3fa7000000000000cbbf87d40000000000cbbfa8bc0000000000cb3f73780000000000cbbfa4f80000000000cb3f764c0000000000cbbf93180000000000cbbfbb040000000000cbbfa7840000000000cb3fb1c80000000000cbbfb3080000000000cb3fb4b80000000000cbbfb14c0000000000cbbfa3900000000000cb3f9b140000000000cbbf93980000000000cb3f78f00000000000cb3fb4400000000000cbbf90100000000000cb3f89440000000000cbbf9b640000000000cbbfafa00000000000cbbfa98c0000000000cb3fb4c80000000000cbbf99e80000000000cb3fa1000000000000cbbfbeb80000000000cb3fa0d40000000000cb3fa6140000000000cbbf5bec0000000000cb3f9de40000000000cbbf7f300000000000cbbf9d780000000000cb3fa6d00000000000cb3fb1a80000000000cb3f79d80000000000cbbf5a780000000000cbbf9bd40000000000cb3fb21c0000000000cbbf95440000000000cbbfa2440000000000cb3fa4c80000000000cb3f96ec0000000000cbbf97b00000000000cb3fb02c0000000000cbbfa5500000000000cb3fb60c0000000000cbbfb6340000000000cbbfa3900000000000cb3fa26c0000000000cbbf9bec0000000000cb3f82ac0000000000cb3fc0e80000000000cbbfb4900000000000cbbfb4940000000000cb3f92040000000000cbbfa5480000000000cbbfaa740000000000cb3f93d40000000000cb3fbb540000000000cb3fa3c80000000000cb3f9a200000000000cbbfa5a40000000000cb3f95ec0000000000cb3fb5d40000000000cb3fa5c40000000000cbbfb4c40000000000cbbfbbe40000000000cbbfb3cc0000000000cbbfbb8c0000000000cb3f95d00000000000cbbfb2100000000000cbbf8e940000000000cbbf9c180000000000cb3f9e000000000000cbbf9a900000000000cbbf9b480000000000cb3fa8d80000000000cbbfa9a40000000000cbbfbadc0000000000cbbf9a100000000000cbbfa0a40000000000cbbfa9680000000000cbbed5400000000000cbbfb54c0000000000cb3f865c0000000000cb3f99dc0000000000cb3fb2d00000000000cbbfbd000000000000cbbfa87c0000000000cb3fa2ac0000000000cb3fa6fc0000000000cbbfbabc0000000000cb3fa4bc0000000000cb3f7b4c0000000000cbbfb1dc0000000000cb3f76900000000000cbbf89b00000000000cbbfa0e80000000000cbbfb3380000000000cb3f93580000000000cbbf72880000000000cbbf87780000000000cb3fb5480000000000cb3fb5140000000000cb3fa42c0000000000cbbfc2740000000000cb3f9f1c0000000000cb3fbbbc0000000000cb3fa1d40000000000cb3fa07c0000000000cbbfa3840000000000cb3fb3180000000000cb3f803c0000000000cb3f6ad00000000000cbbfa18c0000000000cb3f9a340000000000cb3fa2e80000000000cbbf91600000000000cb3f8d8c0000000000cbbf9a540000000000cbbf98580000000000cbbf74940000000000cb3fa9bc0000000000cb3fb0780000000000cbbfa5240000000000cbbfad880000000000cb3f97600000000000cbbf41240000000000cbbfa9440000000000cbbf66cc0000000000cbbf9dfc0000000000cb3fa5e40000000000cbbfa7fc0000000000cbbfbd400000000000cbbf93480000000000cb3f931c0000000000cb3fae140000000000cb3faee40000000000cbbfb23c0000000000cbbfb4800000000000cb3fa4d80000000000cbbfbc2c0000000000cbbfbbf40000000000cb3fac4c0000000000cbbf9cc40000000000cbbfb0240000000000cb3fb5940000000000cb3f86c80000000000cb3fb5380000000000cb3f89cc0000000000cb3fa4400000000000cbbf9c540000000000cb3f7fa80000000000cb3f9d0c0000000000cb3f9cc40000000000cb3fb16c0000000000cb3f81080000000000cbbfa30c0000000000cbbfb6000000000000cb3fa79c0000000000cb3f73b00000000000cb3f849c0000000000cb3fab0c0000000000cbbf97c40000000000cb3f88980000000000cbbf8a900000000000cbbf5e040000000000cbbf95c40000000000cb3fa0800000000000cb3fb1a40000000000cb3fa8600000000000cb3f57c40000000000cb3f95e00000000000cb3f937c0000000000cbbfa6280000000000cb3f5d680000000000cbbf51580000000000cb3f8d900000000000cbbfa40c0000000000cb3fb7500000000000cbbf915c0000000000cbbf71400000000000cb3f94f00000000000cbbf96280000000000cb3f8b740000000000cbbfa0d00000000000cbbfadb40000000000cb3f70940000000000cbbf9fa80000000000cb3f92300000000000cb3f93940000000000cbbfa24c0000000000cb3fa4d40000000000cbbfa1ec0000000000cbbfa2d00000000000cb3fb0900000000000cb3f5bc00000000000cbbf7c580000000000cb3faffc0000000000cbbfb8440000000000cb3f86300000000000cb3f8b900000000000cb3fa0280000000000cb3f72c00000000000cbbf9bac0000000000cb3f94740000000000cb3f87e80000000000cb3f18b00000000000cb3fb49c0000000000cb3f9da00000000000cbbf848c0000000000cbbf94f00000000000cb3f63140000000000cbbf941c0000000000cb3f65ec0000000000cb3f59a80000000000cbbfa8240000000000cbbf90100000000000cb3fb13c0000000000cb3f9b200000000000cb3faa780000000000cbbf99fc0000000000cb3f9afc0000000000cbbf96180000000000cb3fbd4c0000000000cbbfa4880000000000cbbfa97c0000000000cb3fa8c80000000000cb3fa0d80000000000cb3f51fc0000000000cbbfa0400000000000cbbfa6ec0000000000cbbf9bdc0000000000cbbfa50c0000000000cb3f9db80000000000cb3f85bc0000000000cb3f7d8c0000000000cb3fbcb80000000000cbbfaa240000000000cbbfb4680000000000cbbfbca00000000000cb3fa9340000000000cbbfa3d00000000000cb3fb07c0000000000cb3fbca00000000000cb3f88940000000000cb3fb3040000000000cbbfa5a80000000000cbbfb3d00000000000cbbf82500000000000cb3f89c80000000000cb3f76140000000000cb3fb2c00000000000cbbfbd880000000000cb3f94d00000000000
test-compound-2-b99bb20f		conversation_history	00000000000000000000000000000003.0.40284794310255156	msgpack	\\x90
test-compound-2-b99bb20f		messages	00000000000000000000000000000004.0.902313906788756	msgpack	\\x90
test-compound-2-b99bb20f		decision_trace	00000000000000000000000000000004.0.902313906788756	msgpack	\\x9283a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40d670a000000000a76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40e5423000000000a76f7574636f6d65a773756363657373
test-compound-2-b99bb20f		detected_domains	00000000000000000000000000000004.0.902313906788756	msgpack	\\x92a24852a353514c
test-compound-2-b99bb20f		messages	00000000000000000000000000000005.0.10227584215759866	msgpack	\\x90
test-compound-2-b99bb20f		decision_trace	00000000000000000000000000000005.0.10227584215759866	msgpack	\\x9383a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40d670a000000000a76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40e5423000000000a76f7574636f6d65a77375636365737383a46e6f6465b1636f6d706f756e645f706172616c6c656caa6c6174656e63795f6d73cb41058a48cccccccda76f7574636f6d65a773756363657373
test-compound-2-b99bb20f		rag_sources	00000000000000000000000000000005.0.10227584215759866	msgpack	\\x90
test-compound-2-b99bb20f		sql_results	00000000000000000000000000000005.0.10227584215759866	msgpack	\\x9582a46e616d65ab456c656374726f6e696373a5636f756e740382a46e616d65a94675726e6974757265a5636f756e740282a46e616d65b05361666574792045717569706d656e74a5636f756e740282a46e616d65a95061636b6167696e67a5636f756e740282a46e616d65af466f6f642026204265766572616765a5636f756e7401
test-compound-2-b99bb20f		messages	00000000000000000000000000000006.0.7441180169250563	msgpack	\\x90
test-compound-2-b99bb20f		decision_trace	00000000000000000000000000000006.0.7441180169250563	msgpack	\\x9483a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40d670a000000000a76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40e5423000000000a76f7574636f6d65a77375636365737383a46e6f6465b1636f6d706f756e645f706172616c6c656caa6c6174656e63795f6d73cb41058a48cccccccda76f7574636f6d65a77375636365737383a46e6f6465b073757065727669736f725f6d65726765aa6c6174656e63795f6d73cb40e559c99999999aa76f7574636f6d65a773756363657373
\.


--
-- Data for Name: checkpoint_migrations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.checkpoint_migrations (v) FROM stdin;
0
1
2
3
4
5
6
7
8
9
\.


--
-- Data for Name: checkpoint_writes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.checkpoint_writes (thread_id, checkpoint_ns, checkpoint_id, task_id, idx, channel, type, blob, task_path) FROM stdin;
test-rag-1-4de275a7		1f14ba2b-cac7-638b-bfff-d17effbe9c6e	0b38e2c8-44ee-eec4-b6b5-3f3c7c642389	0	messages	msgpack	\\x90	~__pregel_pull, __start__
test-rag-1-4de275a7		1f14ba2b-cac7-638b-bfff-d17effbe9c6e	0b38e2c8-44ee-eec4-b6b5-3f3c7c642389	1	original_query	msgpack	\\xd920576861742069732074686520616e6e75616c206c6561766520706f6c6963793f	~__pregel_pull, __start__
test-rag-1-4de275a7		1f14ba2b-cac7-638b-bfff-d17effbe9c6e	0b38e2c8-44ee-eec4-b6b5-3f3c7c642389	2	session_id	msgpack	\\xaa746573742d7261672d31	~__pregel_pull, __start__
test-rag-1-4de275a7		1f14ba2b-cac7-638b-bfff-d17effbe9c6e	0b38e2c8-44ee-eec4-b6b5-3f3c7c642389	3	require_approval	msgpack	\\xc2	~__pregel_pull, __start__
test-rag-1-4de275a7		1f14ba2b-cac7-638b-bfff-d17effbe9c6e	0b38e2c8-44ee-eec4-b6b5-3f3c7c642389	4	status	msgpack	\\xaa70726f63657373696e67	~__pregel_pull, __start__
test-rag-1-4de275a7		1f14ba2b-cac7-638b-bfff-d17effbe9c6e	0b38e2c8-44ee-eec4-b6b5-3f3c7c642389	5	intent	msgpack	\\xa0	~__pregel_pull, __start__
test-rag-1-4de275a7		1f14ba2b-cac7-638b-bfff-d17effbe9c6e	0b38e2c8-44ee-eec4-b6b5-3f3c7c642389	6	retry_count	msgpack	\\x00	~__pregel_pull, __start__
test-rag-1-4de275a7		1f14ba2b-cac7-638b-bfff-d17effbe9c6e	0b38e2c8-44ee-eec4-b6b5-3f3c7c642389	7	react_steps	msgpack	\\x90	~__pregel_pull, __start__
test-rag-1-4de275a7		1f14ba2b-cac7-638b-bfff-d17effbe9c6e	0b38e2c8-44ee-eec4-b6b5-3f3c7c642389	8	pending_tool_call	msgpack	\\x80	~__pregel_pull, __start__
test-rag-1-4de275a7		1f14ba2b-cac7-638b-bfff-d17effbe9c6e	0b38e2c8-44ee-eec4-b6b5-3f3c7c642389	9	decision_trace	msgpack	\\x90	~__pregel_pull, __start__
test-rag-1-4de275a7		1f14ba2b-cac7-638b-bfff-d17effbe9c6e	0b38e2c8-44ee-eec4-b6b5-3f3c7c642389	10	detected_domains	msgpack	\\x90	~__pregel_pull, __start__
test-rag-1-4de275a7		1f14ba2b-cac7-638b-bfff-d17effbe9c6e	0b38e2c8-44ee-eec4-b6b5-3f3c7c642389	11	branch:to:parallel_init	null	\\x	~__pregel_pull, __start__
test-rag-1-4de275a7		1f14ba2b-cad1-6048-8000-f6f1b8dc8fec	be3d01ab-085a-db7a-59c0-0ac319f3a33f	0	messages	msgpack	\\x90	~__pregel_pull, parallel_init
test-rag-1-4de275a7		1f14ba2b-cad1-6048-8000-f6f1b8dc8fec	be3d01ab-085a-db7a-59c0-0ac319f3a33f	1	input_guard_passed	msgpack	\\xc3	~__pregel_pull, parallel_init
test-rag-1-4de275a7		1f14ba2b-cad1-6048-8000-f6f1b8dc8fec	be3d01ab-085a-db7a-59c0-0ac319f3a33f	2	guard_issues	msgpack	\\x90	~__pregel_pull, parallel_init
test-rag-1-4de275a7		1f14ba2b-cad1-6048-8000-f6f1b8dc8fec	be3d01ab-085a-db7a-59c0-0ac319f3a33f	3	query_embedding	msgpack	\\xdc0180cbbf9bb80000000000cbbfa77c0000000000cb3fa7880000000000cbbfa6400000000000cb3facfc0000000000cb3f9e040000000000cbbfae640000000000cb3f8bdc0000000000cbbf89980000000000cbbf7ca00000000000cb3f96c80000000000cbbf891c0000000000cb3f73540000000000cbbf93800000000000cb3fa0d00000000000cbbf8d8c0000000000cbbfb1fc0000000000cb3f95700000000000cbbfaf900000000000cb3fa0ec0000000000cbbfb6200000000000cb3f7ee00000000000cbbfa8480000000000cbbf96cc0000000000cbbf7e800000000000cbbf75580000000000cbbfbe540000000000cbbfa0940000000000cbbfa1c00000000000cbbf70c80000000000cbbf816c0000000000cbbf9e0c0000000000cbbf89940000000000cb3fa4b40000000000cbbf96f80000000000cbbf91140000000000cb3fb4fc0000000000cb3fa5180000000000cbbfa9680000000000cbbfa60c0000000000cbbfaa800000000000cbbfa4000000000000cbbf9bac0000000000cb3f99300000000000cbbf9cd40000000000cb3f81340000000000cb3fbd9c0000000000cb3f9db00000000000cb3fae000000000000cbbf9f480000000000cbbfa4200000000000cb3f77c00000000000cb3fb4e80000000000cb3f65000000000000cbbf95d80000000000cb3f89a40000000000cb3f86940000000000cb3f68440000000000cbbfa3e40000000000cbbfba580000000000cbbfc1580000000000cbbfa8880000000000cbbfa29c0000000000cbbfb0f40000000000cbbf98f00000000000cb3fa4bc0000000000cb3faf0c0000000000cb3fb4740000000000cb3f8b340000000000cb3fa2d40000000000cb3fb0940000000000cb3f60580000000000cb3fb5880000000000cb3f9a800000000000cbbf96a80000000000cb3f588c0000000000cb3fa7100000000000cb3f97c00000000000cbbf9acc0000000000cb3f75440000000000cbbfb37c0000000000cb3fc29c0000000000cbbfacf80000000000cbbfa5700000000000cbbf926c0000000000cbbfac280000000000cb3faabc0000000000cb3f88780000000000cbbf5c8c0000000000cbbfa1c80000000000cbbf2d140000000000cbbf69b80000000000cbbfa0bc0000000000cbbfb6300000000000cb3f9db40000000000cb3f956c0000000000cbbfa4540000000000cbbfb9cc0000000000cbbf95380000000000cbbfa0ac0000000000cb3f77b00000000000cbbf6f000000000000cb3fa8940000000000cb3fb8c80000000000cb3f9af40000000000cb3fb2580000000000cbbfa1180000000000cbbf94b00000000000cbbfb6dc0000000000cbbf4e5c0000000000cb3fb1e80000000000cbbfb5500000000000cb3f9cc00000000000cbbfa1780000000000cbbfb5240000000000cbbfa84c0000000000cbbf9e3c0000000000cb3f89040000000000cbbfa1840000000000cb3f9cc80000000000cb3fb3500000000000cbbf9dd40000000000cb3fa43c0000000000cbbfa3dc0000000000cb3f8ac40000000000cb3fa0180000000000cb3f83740000000000cb3f91e00000000000cbbf93f00000000000cb3fadf80000000000cb3f6e080000000000cb3f82040000000000cbbf87540000000000cb3fad640000000000cbbfa5000000000000cbbfae480000000000cbbfa8540000000000cbbf9f5c0000000000cb3f81bc0000000000cb3fb7240000000000cb3f80e00000000000cbbf88c00000000000cbbf92780000000000cb3f93ec0000000000cb3f7c440000000000cb3fc32c0000000000cb3f988c0000000000cb3f955c0000000000cbbf9cdc0000000000cbbf62f40000000000cb3fa0f80000000000cb3f94500000000000cbbfb0fc0000000000cbbfa5dc0000000000cbbfaa240000000000cbbfa2040000000000cb3f92d40000000000cb3f968c0000000000cb3f9ef80000000000cb3fb4a00000000000cbbfb4b00000000000cb3fa5480000000000cb3fb2780000000000cbbf996c0000000000cbbf85ec0000000000cb3f9fe00000000000cb3fab980000000000cbbfa6e80000000000cbbfb9e40000000000cbbfb9080000000000cb3fa74c0000000000cbbfa1fc0000000000cb3fa8b00000000000cb3fa8500000000000cbbfb8e40000000000cbbfa3480000000000cb3fb1000000000000cbbf913c0000000000cb3f8e700000000000cb3f68780000000000cb3fa66c0000000000cbbfc1900000000000cbbfa9780000000000cb3f8ae80000000000cbbfaef40000000000cbbf99340000000000cb3fa0f80000000000cb3fc7e40000000000cb3fb7300000000000cb3faa500000000000cb3f95f80000000000cb3fb5c00000000000cbbf9b700000000000cb3fa6280000000000cbbfb2dc0000000000cb3f8e580000000000cbbfb1ac0000000000cbbf8f140000000000cbbf9f7c0000000000cbbfac5c0000000000cbbfa1700000000000cbbfaba00000000000cbbf8ed00000000000cb3fa79c0000000000cbbfb3d00000000000cbbf8bd40000000000cbbfa5dc0000000000cbbfb9a00000000000cb3fa4b00000000000cbbfacf00000000000cb3f88900000000000cb3faa480000000000cbbfa9780000000000cb3f90200000000000cb3f75b00000000000cb3f95b40000000000cbbfa7100000000000cbbfa6a00000000000cbbfa4b00000000000cb3fc7bc0000000000cbbfbd4c0000000000cbbf95440000000000cb3f73f80000000000cb3fa0540000000000cbbf96b00000000000cb3f66d80000000000cbbfb4480000000000cb3f7c900000000000cbbf76540000000000cb3f82c40000000000cb3f81640000000000cb3fc0640000000000cb3f7cd40000000000cbbfac900000000000cbbfa0140000000000cb3f9d700000000000cb3faee00000000000cb3f38000000000000cb3fa5140000000000cbbf83400000000000cbbf7a080000000000cb3fbed00000000000cb3fa8580000000000cb3f8f440000000000cbbf90b40000000000cbbf9c280000000000cbbfb4dc0000000000cb3f7c0c0000000000cb3f88100000000000cb3fa0b40000000000cb3fa60c0000000000cb3fa2840000000000cbbfa1d40000000000cbbf347c0000000000cbbfac680000000000cbbfa7bc0000000000cbbf9c5c0000000000cbbfa0400000000000cbbfb04c0000000000cbbf8c700000000000cb3f901c0000000000cbbf78740000000000cbbfb6a80000000000cbbf98b40000000000cb3f95f80000000000cb3fb4fc0000000000cb3fa1c00000000000cbbf86c40000000000cbbf90dc0000000000cbbf750c0000000000cbbfb3540000000000cbbfb2d00000000000cb3fa4cc0000000000cbbfa4100000000000cbbfa9c00000000000cb3fbbd80000000000cbbfa1600000000000cb3fad480000000000cb3f7d640000000000cb3faf9c0000000000cb3f93bc0000000000cbbf81980000000000cb3f95480000000000cbbf934c0000000000cb3fae480000000000cbbf9a1c0000000000cbbf53100000000000cbbfb3680000000000cb3f95940000000000cbbf8d940000000000cbbf82640000000000cbbfa0bc0000000000cbbf80340000000000cbbfb66c0000000000cbbf74900000000000cb3f46540000000000cb3fb0cc0000000000cb3f93a80000000000cb3fb9fc0000000000cbbfa5780000000000cb3f99800000000000cb3fbb200000000000cb3fa8fc0000000000cb3f529c0000000000cbbf541c0000000000cbbf94cc0000000000cbbfa9b80000000000cbbface80000000000cb3f37940000000000cb3fa9980000000000cbbf937c0000000000cbbf97cc0000000000cbbf93fc0000000000cb3f9d2c0000000000cb3f670c0000000000cbbf90a40000000000cbbf81c80000000000cb3f75480000000000cb3fa4bc0000000000cbbf95240000000000cbbfb5980000000000cb3fa6480000000000cbbf80ec0000000000cb3fb27c0000000000cbbf72640000000000cbbfa8100000000000cb3fad440000000000cbbf92400000000000cb3f75840000000000cbbf789c0000000000cbbfb0c00000000000cb3f981c0000000000cb3fa02c0000000000cbbfb5800000000000cb3f94b40000000000cbbfb3f40000000000cb3f77840000000000cb3fb9c00000000000cbbfad640000000000cbbfb6080000000000cb3fae1c0000000000cbbf92ec0000000000cbbf73600000000000cb3f9ba00000000000cb3f6b440000000000cbbf88fc0000000000cbbf6d480000000000cb3f965c0000000000cbbfa74c0000000000cb3f90640000000000cbbfb3500000000000cbbfa6140000000000cb3f5af40000000000cb3fbcc40000000000cbbfb1140000000000cbbfb7000000000000cb3faec80000000000cb3f98800000000000cbbfa09c0000000000cbbf9aac0000000000cb3f75f80000000000cbbfa3cc0000000000cbbfb1800000000000cbbf67f80000000000cb3fb4600000000000cbbfa8840000000000cb3fa7140000000000cbbf97440000000000cbbfa9980000000000cbbfb7c40000000000cbbf9fe80000000000cbbfbb680000000000cb3fb6a00000000000cb3fad780000000000cb3fad740000000000cb3f71cc0000000000cb3f90f80000000000cbbfb0d00000000000cb3fa7440000000000cbbfa4280000000000cbbf7f0c0000000000cb3fb0b80000000000cbbfb1b40000000000cb3fb2c40000000000	~__pregel_pull, parallel_init
test-rag-1-4de275a7		1f14ba2b-cad1-6048-8000-f6f1b8dc8fec	be3d01ab-085a-db7a-59c0-0ac319f3a33f	4	embedding_done	msgpack	\\xc3	~__pregel_pull, parallel_init
test-rag-1-4de275a7		1f14ba2b-cad1-6048-8000-f6f1b8dc8fec	be3d01ab-085a-db7a-59c0-0ac319f3a33f	5	conversation_history	msgpack	\\x90	~__pregel_pull, parallel_init
test-rag-1-4de275a7		1f14ba2b-cad1-6048-8000-f6f1b8dc8fec	be3d01ab-085a-db7a-59c0-0ac319f3a33f	6	conversation_summary	msgpack	\\xa0	~__pregel_pull, parallel_init
test-rag-1-4de275a7		1f14ba2b-cad1-6048-8000-f6f1b8dc8fec	be3d01ab-085a-db7a-59c0-0ac319f3a33f	7	history_token_usage	msgpack	\\x00	~__pregel_pull, parallel_init
test-rag-1-4de275a7		1f14ba2b-cad1-6048-8000-f6f1b8dc8fec	be3d01ab-085a-db7a-59c0-0ac319f3a33f	8	cache_hit	msgpack	\\xc2	~__pregel_pull, parallel_init
test-rag-1-4de275a7		1f14ba2b-cad1-6048-8000-f6f1b8dc8fec	be3d01ab-085a-db7a-59c0-0ac319f3a33f	9	l1_checked	msgpack	\\xc3	~__pregel_pull, parallel_init
test-rag-1-4de275a7		1f14ba2b-cad1-6048-8000-f6f1b8dc8fec	be3d01ab-085a-db7a-59c0-0ac319f3a33f	10	decision_trace	msgpack	\\x9183a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40d6f24666666666a76f7574636f6d65a773756363657373	~__pregel_pull, parallel_init
test-rag-1-4de275a7		1f14ba2b-cad1-6048-8000-f6f1b8dc8fec	be3d01ab-085a-db7a-59c0-0ac319f3a33f	11	branch:to:supervisor_intent	null	\\x	~__pregel_pull, parallel_init
test-rag-1-4de275a7		1f14ba2c-aaee-6a24-8001-4b89744fdc06	95a8f2ba-bb8f-aeec-1198-933fb734cfbc	0	messages	msgpack	\\x90	~__pregel_pull, supervisor_intent
test-rag-1-4de275a7		1f14ba2c-aaee-6a24-8001-4b89744fdc06	95a8f2ba-bb8f-aeec-1198-933fb734cfbc	1	intent	msgpack	\\xa3726167	~__pregel_pull, supervisor_intent
test-rag-1-4de275a7		1f14ba2c-aaee-6a24-8001-4b89744fdc06	95a8f2ba-bb8f-aeec-1198-933fb734cfbc	2	intent_confidence	msgpack	\\xcb3ff0000000000000	~__pregel_pull, supervisor_intent
test-rag-1-4de275a7		1f14ba2c-aaee-6a24-8001-4b89744fdc06	95a8f2ba-bb8f-aeec-1198-933fb734cfbc	3	detected_domains	msgpack	\\x91a24852	~__pregel_pull, supervisor_intent
test-rag-1-4de275a7		1f14ba2c-aaee-6a24-8001-4b89744fdc06	95a8f2ba-bb8f-aeec-1198-933fb734cfbc	4	decision_trace	msgpack	\\x9283a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40d6f24666666666a76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40d6684000000000a76f7574636f6d65a773756363657373	~__pregel_pull, supervisor_intent
test-rag-1-4de275a7		1f14ba2c-aaee-6a24-8001-4b89744fdc06	95a8f2ba-bb8f-aeec-1198-933fb734cfbc	5	branch:to:rag_domain_router	null	\\x	~__pregel_pull, supervisor_intent
test-rag-1-4de275a7		1f14ba2d-85c4-68f8-8002-89b6eaf0235a	fcd5aab1-7402-6a99-25ae-cfc5a413c1e5	0	messages	msgpack	\\x90	~__pregel_pull, rag_domain_router
test-rag-1-4de275a7		1f14ba2d-85c4-68f8-8002-89b6eaf0235a	fcd5aab1-7402-6a99-25ae-cfc5a413c1e5	1	rag_domain	msgpack	\\xa24852	~__pregel_pull, rag_domain_router
test-rag-1-4de275a7		1f14ba2d-85c4-68f8-8002-89b6eaf0235a	fcd5aab1-7402-6a99-25ae-cfc5a413c1e5	2	rag_sub_question	msgpack	\\xbb416e6e75616c206c6561766520706f6c6963792064657461696c73	~__pregel_pull, rag_domain_router
test-rag-1-4de275a7		1f14ba2d-85c4-68f8-8002-89b6eaf0235a	fcd5aab1-7402-6a99-25ae-cfc5a413c1e5	3	decision_trace	msgpack	\\x9383a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40d6f24666666666a76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40d6684000000000a76f7574636f6d65a77375636365737383a46e6f6465b17261675f646f6d61696e5f726f75746572aa6c6174656e63795f6d73cb40d64dc666666666a76f7574636f6d65a773756363657373	~__pregel_pull, rag_domain_router
test-rag-1-4de275a7		1f14ba2d-85c4-68f8-8002-89b6eaf0235a	fcd5aab1-7402-6a99-25ae-cfc5a413c1e5	4	branch:to:rag_retrieval	null	\\x	~__pregel_pull, rag_domain_router
test-rag-1-4de275a7		1f14ba2e-5f94-6337-8003-83a1b4ece8d7	313d464a-005c-c580-e99a-9f2ff63bcdf5	0	messages	msgpack	\\x90	~__pregel_pull, rag_retrieval
test-rag-1-4de275a7		1f14ba2e-5f94-6337-8003-83a1b4ece8d7	313d464a-005c-c580-e99a-9f2ff63bcdf5	1	rag_fused_results	msgpack	\\x9786a26964af48522d383737336231656563323130a7636f6e74656e74da012a416e6e75616c204c656176653a20416c6c2066756c6c2d74696d6520656d706c6f796565732061726520656e7469746c656420746f2032342064617973206f66207061696420616e6e75616c206c65617665207065722063616c656e64617220796561722e204c6561766520616363727565732061742032206461797320706572206d6f6e74682e20556e75736564206c656176652063616e206265206361727269656420666f727761726420757020746f2035206461797320696e746f20746865206e65787420796561722e204c65617665207265717565737473206d757374206265207375626d6974746564206174206c656173742032207765656b7320696e20616476616e636520666f7220706572696f6473206c6f6e676572207468616e203320646179732ea6646f6d61696ea24852a6736f75726365b268725f706f6c6963795f323032342e706466a86d6574616461746185ab6368756e6b5f696e64657800a7636f6e74656e74da012a416e6e75616c204c656176653a20416c6c2066756c6c2d74696d6520656d706c6f796565732061726520656e7469746c656420746f2032342064617973206f66207061696420616e6e75616c206c65617665207065722063616c656e64617220796561722e204c6561766520616363727565732061742032206461797320706572206d6f6e74682e20556e75736564206c656176652063616e206265206361727269656420666f727761726420757020746f2035206461797320696e746f20746865206e65787420796561722e204c65617665207265717565737473206d757374206265207375626d6974746564206174206c656173742032207765656b7320696e20616476616e636520666f7220706572696f6473206c6f6e676572207468616e203320646179732ea6646f6d61696ea24852a6736f75726365b268725f706f6c6963795f323032342e706466a974696d657374616d70cb41da7fca03bccd10aa73696d696c6172697479cb3fdc5c0be06f273b86a26964af48522d343964613534343436643063a7636f6e74656e74da010b5369636b204c656176653a20456d706c6f7965657320726563656976652031322064617973206f662070616964207369636b206c656176652070657220796561722e2041206d65646963616c20636572746966696361746520697320726571756972656420666f7220616273656e63657320657863656564696e67203320636f6e736563757469766520646179732e20556e75736564207369636b206c6561766520646f6573206e6f7420636172727920666f72776172642e20506172742d74696d6520656d706c6f7965657320726563656976652070726f2d7261746564207369636b206c65617665206261736564206f6e20746865697220636f6e7472616374656420686f7572732ea6646f6d61696ea24852a6736f75726365b268725f706f6c6963795f323032342e706466a86d6574616461746185ab6368756e6b5f696e64657801a7636f6e74656e74da010b5369636b204c656176653a20456d706c6f7965657320726563656976652031322064617973206f662070616964207369636b206c656176652070657220796561722e2041206d65646963616c20636572746966696361746520697320726571756972656420666f7220616273656e63657320657863656564696e67203320636f6e736563757469766520646179732e20556e75736564207369636b206c6561766520646f6573206e6f7420636172727920666f72776172642e20506172742d74696d6520656d706c6f7965657320726563656976652070726f2d7261746564207369636b206c65617665206261736564206f6e20746865697220636f6e7472616374656420686f7572732ea6646f6d61696ea24852a6736f75726365b268725f706f6c6963795f323032342e706466a974696d657374616d70cb41da7fca03bccd10aa73696d696c6172697479cb3fd7a9935fa158de86a26964af48522d356465346435373137333639a7636f6e74656e74da010d4d617465726e69747920262050617465726e697479204c656176653a2046656d616c6520656d706c6f796565732061726520656e7469746c656420746f203136207765656b73206f662070616964206d617465726e697479206c656176652e204d616c6520656d706c6f7965657320726563656976652034207765656b73206f6620706169642070617465726e697479206c656176652e20426f7468206d7573742062652074616b656e2077697468696e203132206d6f6e746873206f6620746865206368696c6427732062697274682e204164646974696f6e616c20756e70616964206c65617665206f6620757020746f2036206d6f6e746873206d6179206265207265717565737465642ea6646f6d61696ea24852a6736f75726365b268725f706f6c6963795f323032342e706466a86d6574616461746185ab6368756e6b5f696e64657802a7636f6e74656e74da010d4d617465726e69747920262050617465726e697479204c656176653a2046656d616c6520656d706c6f796565732061726520656e7469746c656420746f203136207765656b73206f662070616964206d617465726e697479206c656176652e204d616c6520656d706c6f7965657320726563656976652034207765656b73206f6620706169642070617465726e697479206c656176652e20426f7468206d7573742062652074616b656e2077697468696e203132206d6f6e746873206f6620746865206368696c6427732062697274682e204164646974696f6e616c20756e70616964206c65617665206f6620757020746f2036206d6f6e746873206d6179206265207265717565737465642ea6646f6d61696ea24852a6736f75726365b268725f706f6c6963795f323032342e706466a974696d657374616d70cb41da7fca03bccd10aa73696d696c6172697479cb3fd3ccd7c05703d986a26964af48522d616434323064626330666439a7636f6e74656e74da01005265746972656d656e742042656e65666974733a20343031286b2920706c616e207769746820636f6d70616e79206d61746368206f662031303025206f6e20666972737420332520616e6420353025206f6e206e657874203225206f662073616c6172792e20456d706c6f796565732061726520656c696769626c652061667465722039302064617973206f6620656d706c6f796d656e742e2056657374696e67207363686564756c653a20323525207065722079656172206f76657220342079656172732e2046696e616e6369616c20706c616e6e696e6720636f6e73756c746174696f6e732061726520617661696c61626c6520717561727465726c792ea6646f6d61696ea24852a6736f75726365b6636f6d70656e736174696f6e5f67756964652e706466a86d6574616461746185ab6368756e6b5f696e64657802a7636f6e74656e74da01005265746972656d656e742042656e65666974733a20343031286b2920706c616e207769746820636f6d70616e79206d61746368206f662031303025206f6e20666972737420332520616e6420353025206f6e206e657874203225206f662073616c6172792e20456d706c6f796565732061726520656c696769626c652061667465722039302064617973206f6620656d706c6f796d656e742e2056657374696e67207363686564756c653a20323525207065722079656172206f76657220342079656172732e2046696e616e6369616c20706c616e6e696e6720636f6e73756c746174696f6e732061726520617661696c61626c6520717561727465726c792ea6646f6d61696ea24852a6736f75726365b6636f6d70656e736174696f6e5f67756964652e706466a974696d657374616d70cb41da7fca03bccd10aa73696d696c6172697479cb3fd34c49602c76bd86a26964af48522d336563653237613133353166a7636f6e74656e74d9ef576f726b2046726f6d20486f6d6520506f6c6963793a20456d706c6f79656573206d617920776f726b2066726f6d20686f6d6520757020746f2033206461797320706572207765656b2077697468206d616e6167657220617070726f76616c2e204120737461626c6520696e7465726e657420636f6e6e656374696f6e20616e642064656469636174656420776f726b7370616365206172652072657175697265642e20436f726520686f757273206f6620313020414d202d203420504d206d757374206265206f6273657276656420666f72206d656574696e677320616e6420636f6c6c61626f726174696f6e2ea6646f6d61696ea24852a6736f75726365b268725f706f6c6963795f323032342e706466a86d6574616461746185ab6368756e6b5f696e64657803a7636f6e74656e74d9ef576f726b2046726f6d20486f6d6520506f6c6963793a20456d706c6f79656573206d617920776f726b2066726f6d20686f6d6520757020746f2033206461797320706572207765656b2077697468206d616e6167657220617070726f76616c2e204120737461626c6520696e7465726e657420636f6e6e656374696f6e20616e642064656469636174656420776f726b7370616365206172652072657175697265642e20436f726520686f757273206f6620313020414d202d203420504d206d757374206265206f6273657276656420666f72206d656574696e677320616e6420636f6c6c61626f726174696f6e2ea6646f6d61696ea24852a6736f75726365b268725f706f6c6963795f323032342e706466a974696d657374616d70cb41da7fca03bccd10aa73696d696c6172697479cb3fd30f8a7fa8e03c86a26964af48522d326436613761386234346164a7636f6e74656e74da010f4865616c746820496e737572616e63653a2054686520636f6d70616e792070726f766964657320636f6d70726568656e73697665206865616c746820696e737572616e636520636f766572696e67206d65646963616c2c2064656e74616c2c20616e6420766973696f6e20636172652e2046616d696c7920636f76657261676520697320617661696c61626c65207769746820656d706c6f79656520636f6e747269627574696f6e206f66203230252e20416e6e75616c2064656475637469626c65206973202435303020696e646976696475616c202f2024313530302066616d696c792e204d656e74616c206865616c7468207365727669636573206172652066756c6c7920636f76657265642ea6646f6d61696ea24852a6736f75726365b6636f6d70656e736174696f6e5f67756964652e706466a86d6574616461746185ab6368756e6b5f696e64657801a7636f6e74656e74da010f4865616c746820496e737572616e63653a2054686520636f6d70616e792070726f766964657320636f6d70726568656e73697665206865616c746820696e737572616e636520636f766572696e67206d65646963616c2c2064656e74616c2c20616e6420766973696f6e20636172652e2046616d696c7920636f76657261676520697320617661696c61626c65207769746820656d706c6f79656520636f6e747269627574696f6e206f66203230252e20416e6e75616c2064656475637469626c65206973202435303020696e646976696475616c202f2024313530302066616d696c792e204d656e74616c206865616c7468207365727669636573206172652066756c6c7920636f76657265642ea6646f6d61696ea24852a6736f75726365b6636f6d70656e736174696f6e5f67756964652e706466a974696d657374616d70cb41da7fca03bccd10aa73696d696c6172697479cb3fd1e120007b7af686a26964af48522d626134663537646566666161a7636f6e74656e74d9fa426173652053616c617279205374727563747572653a2053616c61726965732061726520726576696577656420616e6e75616c6c7920696e204d617263682e205061792062616e647320617265206f7267616e697a6564206279206a6f62206c6576656c3a204a756e696f7220284c312d4c33292c2053656e696f7220284c342d4c36292c204d616e6167656d656e7420284c372d4c39292c2045786563757469766520284c31302b292e2045616368206c6576656c2068617320612073616c6172792072616e6765207769746820323574682c20353074682c20616e6420373574682070657263656e74696c652062656e63686d61726b732ea6646f6d61696ea24852a6736f75726365b6636f6d70656e736174696f6e5f67756964652e706466a86d6574616461746185ab6368756e6b5f696e64657800a7636f6e74656e74d9fa426173652053616c617279205374727563747572653a2053616c61726965732061726520726576696577656420616e6e75616c6c7920696e204d617263682e205061792062616e647320617265206f7267616e697a6564206279206a6f62206c6576656c3a204a756e696f7220284c312d4c33292c2053656e696f7220284c342d4c36292c204d616e6167656d656e7420284c372d4c39292c2045786563757469766520284c31302b292e2045616368206c6576656c2068617320612073616c6172792072616e6765207769746820323574682c20353074682c20616e6420373574682070657263656e74696c652062656e63686d61726b732ea6646f6d61696ea24852a6736f75726365b6636f6d70656e736174696f6e5f67756964652e706466a974696d657374616d70cb41da7fca03bccd10aa73696d696c6172697479cb3fd07ff6ffc002ff	~__pregel_pull, rag_retrieval
test-rag-1-4de275a7		1f14ba2e-5f94-6337-8003-83a1b4ece8d7	313d464a-005c-c580-e99a-9f2ff63bcdf5	2	conversation_history	msgpack	\\x90	~__pregel_pull, rag_retrieval
test-rag-1-4de275a7		1f14ba2e-5f94-6337-8003-83a1b4ece8d7	313d464a-005c-c580-e99a-9f2ff63bcdf5	3	conversation_summary	msgpack	\\xa0	~__pregel_pull, rag_retrieval
test-rag-1-4de275a7		1f14ba2e-5f94-6337-8003-83a1b4ece8d7	313d464a-005c-c580-e99a-9f2ff63bcdf5	4	history_token_usage	msgpack	\\x00	~__pregel_pull, rag_retrieval
test-rag-1-4de275a7		1f14ba2e-5f94-6337-8003-83a1b4ece8d7	313d464a-005c-c580-e99a-9f2ff63bcdf5	5	decision_trace	msgpack	\\x9483a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40d6f24666666666a76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40d6684000000000a76f7574636f6d65a77375636365737383a46e6f6465b17261675f646f6d61696e5f726f75746572aa6c6174656e63795f6d73cb40d64dc666666666a76f7574636f6d65a77375636365737383a46e6f6465ad7261675f72657472696576616caa6c6174656e63795f6d73cb4095286666666666a76f7574636f6d65a773756363657373	~__pregel_pull, rag_retrieval
test-rag-1-4de275a7		1f14ba2e-5f94-6337-8003-83a1b4ece8d7	313d464a-005c-c580-e99a-9f2ff63bcdf5	6	branch:to:rag_generator	null	\\x	~__pregel_pull, rag_retrieval
test-rag-1-4de275a7		1f14ba2e-6c80-6732-8004-9412859b4b80	7c6f6597-7e46-cff7-39d0-b4cf897883ef	0	messages	msgpack	\\x90	~__pregel_pull, rag_generator
test-rag-1-4de275a7		1f14ba2e-6c80-6732-8004-9412859b4b80	7c6f6597-7e46-cff7-39d0-b4cf897883ef	1	rag_answer	msgpack	\\xda011a416c6c2066756c6c2d74696d6520656d706c6f796565732061726520656e7469746c656420746f2032342064617973206f66207061696420616e6e75616c206c65617665207065722063616c656e64617220796561722c20616363727565732061742032206461797320706572206d6f6e74682c20616e6420756e75736564206c656176652063616e206265206361727269656420666f727761726420757020746f2035206461797320696e746f20746865206e65787420796561722e204c65617665207265717565737473206d757374206265207375626d6974746564206174206c656173742032207765656b7320696e20616476616e636520666f7220706572696f6473206c6f6e676572207468616e203320646179732e	~__pregel_pull, rag_generator
test-rag-1-4de275a7		1f14ba2e-6c80-6732-8004-9412859b4b80	7c6f6597-7e46-cff7-39d0-b4cf897883ef	2	rag_confidence	msgpack	\\xa448494748	~__pregel_pull, rag_generator
test-rag-1-4de275a7		1f14ba2e-6c80-6732-8004-9412859b4b80	7c6f6597-7e46-cff7-39d0-b4cf897883ef	3	rag_sources	msgpack	\\x91b268725f706f6c6963795f323032342e706466	~__pregel_pull, rag_generator
test-rag-1-4de275a7		1f14ba2e-6c80-6732-8004-9412859b4b80	7c6f6597-7e46-cff7-39d0-b4cf897883ef	4	decision_trace	msgpack	\\x9583a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40d6f24666666666a76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40d6684000000000a76f7574636f6d65a77375636365737383a46e6f6465b17261675f646f6d61696e5f726f75746572aa6c6174656e63795f6d73cb40d64dc666666666a76f7574636f6d65a77375636365737383a46e6f6465ad7261675f72657472696576616caa6c6174656e63795f6d73cb4095286666666666a76f7574636f6d65a77375636365737383a46e6f6465ad7261675f67656e657261746f72aa6c6174656e63795f6d73cb40e567c333333333a76f7574636f6d65a773756363657373	~__pregel_pull, rag_generator
test-sql-1-52887a2a		1f14ba30-e420-6f17-bfff-204fd86440ca	a4b5b4fd-a9f0-430c-e281-38bbd3b15804	0	messages	msgpack	\\x90	~__pregel_pull, __start__
test-sql-1-52887a2a		1f14ba30-e420-6f17-bfff-204fd86440ca	a4b5b4fd-a9f0-430c-e281-38bbd3b15804	1	original_query	msgpack	\\xbc53686f7720746f7020352070726f6475637473206279207072696365	~__pregel_pull, __start__
test-sql-1-52887a2a		1f14ba30-e420-6f17-bfff-204fd86440ca	a4b5b4fd-a9f0-430c-e281-38bbd3b15804	2	session_id	msgpack	\\xaa746573742d73716c2d31	~__pregel_pull, __start__
test-sql-1-52887a2a		1f14ba30-e420-6f17-bfff-204fd86440ca	a4b5b4fd-a9f0-430c-e281-38bbd3b15804	3	require_approval	msgpack	\\xc2	~__pregel_pull, __start__
test-sql-1-52887a2a		1f14ba30-e420-6f17-bfff-204fd86440ca	a4b5b4fd-a9f0-430c-e281-38bbd3b15804	4	status	msgpack	\\xaa70726f63657373696e67	~__pregel_pull, __start__
test-sql-1-52887a2a		1f14ba30-e420-6f17-bfff-204fd86440ca	a4b5b4fd-a9f0-430c-e281-38bbd3b15804	5	intent	msgpack	\\xa0	~__pregel_pull, __start__
test-sql-1-52887a2a		1f14ba30-e420-6f17-bfff-204fd86440ca	a4b5b4fd-a9f0-430c-e281-38bbd3b15804	6	retry_count	msgpack	\\x00	~__pregel_pull, __start__
test-sql-1-52887a2a		1f14ba30-e420-6f17-bfff-204fd86440ca	a4b5b4fd-a9f0-430c-e281-38bbd3b15804	7	react_steps	msgpack	\\x90	~__pregel_pull, __start__
test-sql-1-52887a2a		1f14ba30-e420-6f17-bfff-204fd86440ca	a4b5b4fd-a9f0-430c-e281-38bbd3b15804	8	pending_tool_call	msgpack	\\x80	~__pregel_pull, __start__
test-sql-1-52887a2a		1f14ba30-e420-6f17-bfff-204fd86440ca	a4b5b4fd-a9f0-430c-e281-38bbd3b15804	9	decision_trace	msgpack	\\x90	~__pregel_pull, __start__
test-sql-1-52887a2a		1f14ba30-e420-6f17-bfff-204fd86440ca	a4b5b4fd-a9f0-430c-e281-38bbd3b15804	10	detected_domains	msgpack	\\x90	~__pregel_pull, __start__
test-sql-1-52887a2a		1f14ba30-e420-6f17-bfff-204fd86440ca	a4b5b4fd-a9f0-430c-e281-38bbd3b15804	11	branch:to:parallel_init	null	\\x	~__pregel_pull, __start__
test-sql-1-52887a2a		1f14ba30-e425-6d33-8000-7cbca118e52b	2edde6f9-bb58-88ca-dfc6-87478c8a343e	0	messages	msgpack	\\x90	~__pregel_pull, parallel_init
test-sql-1-52887a2a		1f14ba30-e425-6d33-8000-7cbca118e52b	2edde6f9-bb58-88ca-dfc6-87478c8a343e	1	input_guard_passed	msgpack	\\xc3	~__pregel_pull, parallel_init
test-sql-1-52887a2a		1f14ba30-e425-6d33-8000-7cbca118e52b	2edde6f9-bb58-88ca-dfc6-87478c8a343e	2	guard_issues	msgpack	\\x90	~__pregel_pull, parallel_init
test-compound-1-5774cb33		1f14ba43-45e7-6478-8001-cd896f58a5b8	4483dc6d-09ff-d512-4827-2e19e7af2b4f	1	intent	msgpack	\\xa8636f6d706f756e64	~__pregel_pull, supervisor_intent
test-sql-1-52887a2a		1f14ba30-e425-6d33-8000-7cbca118e52b	2edde6f9-bb58-88ca-dfc6-87478c8a343e	3	query_embedding	msgpack	\\xdc0180cb3f94080000000000cb3f8c180000000000cb3fa8fc0000000000cb3fafe80000000000cbbfa7800000000000cb3fa99c0000000000cb3fa6300000000000cb3fb7d80000000000cb3fb94c0000000000cbbfaa380000000000cbbf79940000000000cbbf61ac0000000000cbbfa9cc0000000000cb3f9e180000000000cb3f54040000000000cbbfb23c0000000000cbbf882c0000000000cbbfb2d00000000000cbbf9f740000000000cb3fa6500000000000cbbf7e000000000000cbbfa4280000000000cb3f9c840000000000cbbf8e600000000000cbbf43f00000000000cbbfb2240000000000cbbface00000000000cb3f247c0000000000cb3fb0940000000000cbbf80b00000000000cbbfa1600000000000cb3fa8a80000000000cb3f87bc0000000000cb3fa8080000000000cbbf94600000000000cbbf55d40000000000cbbf8ecc0000000000cb3fa9580000000000cbbf8b840000000000cb3f7c540000000000cb3fa1bc0000000000cbbf84940000000000cb3f907c0000000000cb3f7e6c0000000000cb3f72e40000000000cb3f5f640000000000cb3fa8e00000000000cb3fa1d80000000000cbbf88740000000000cbbf9e200000000000cb3f96800000000000cbbf75d40000000000cbbfa7b80000000000cbbf95800000000000cbbf8d700000000000cb3fb1800000000000cb3fadb40000000000cb3f91440000000000cb3f6fd00000000000cb3f67300000000000cb3f9e000000000000cbbfa1440000000000cb3fa4dc0000000000cbbf9f100000000000cbbfab7c0000000000cbbfbb6c0000000000cbbf98200000000000cbbf7e940000000000cbbfb2980000000000cb3fa3400000000000cb3fabe00000000000cbbfaec00000000000cbbfa3340000000000cbbfa2c00000000000cb3f77200000000000cb3f8b140000000000cbbf78540000000000cb3f6ca40000000000cb3fbec00000000000cbbfaba80000000000cbbf96e00000000000cb3fab580000000000cb3fa8000000000000cb3fb9480000000000cb3f72340000000000cb3f80d40000000000cbbf83800000000000cbbfa26c0000000000cb3f8c040000000000cbbf94300000000000cbbfa3240000000000cb3f60240000000000cbbfa9ec0000000000cbbfaa2c0000000000cbbfae400000000000cb3fb2cc0000000000cbbf8c180000000000cb3fa2d40000000000cbbf93b00000000000cb3f8fd80000000000cbbf963c0000000000cb3fa9040000000000cbbf22bc0000000000cbbf81980000000000cbbfb1500000000000cbbfab780000000000cb3f94980000000000cb3f88000000000000cbbf84140000000000cb3f45f80000000000cb3fa7dc0000000000cb3fc0580000000000cbbf79780000000000cbbfa5180000000000cbbfac9c0000000000cbbf99900000000000cb3f9eac0000000000cb3fa2080000000000cb3fb1640000000000cbbf92680000000000cbbf94500000000000cbbf89d80000000000cbbfbc400000000000cbbf95d80000000000cb3fa1dc0000000000cb3f87600000000000cbbf994c0000000000cbbf96100000000000cbbf94b80000000000cbbfa06c0000000000cbbfa4bc0000000000cbbfb1380000000000cbbfa2840000000000cbbfa9600000000000cb3f89240000000000cbbfb9300000000000cbbfa10c0000000000cb3fafbc0000000000cbbfa0d00000000000cb3fb3640000000000cbbfb2740000000000cbbfaa500000000000cbbfa4540000000000cbbf93ec0000000000cb3f936c0000000000cbbfb0ec0000000000cbbfa54c0000000000cb3fab940000000000cbbf9d500000000000cbbfb8040000000000cbbf77d00000000000cb3f6a340000000000cbbf967c0000000000cb3fa6d80000000000cbbfc1700000000000cb3f95580000000000cb3fb7040000000000cbbf88000000000000cb3f95ec0000000000cb3faa040000000000cbbfc1480000000000cb3fa9f00000000000cb3fae900000000000cbbfabe00000000000cbbf91240000000000cb3fba140000000000cb3f4e500000000000cbbf82d40000000000cbbfb9700000000000cb3fadf00000000000cbbfa0200000000000cbbf80bc0000000000cb3fb3240000000000cb3f97800000000000cb3fb5880000000000cbbfa1280000000000cbbfb5080000000000cb3fae800000000000cbbfc5bc0000000000cb3fb9300000000000cb3fbeec0000000000cbbf9afc0000000000cbbf8e0c0000000000cb3f9ce00000000000cb3fac800000000000cbbfb65c0000000000cb3f78ec0000000000cb3fb9280000000000cb3f746c0000000000cbbf9b900000000000cbbfa8380000000000cb3f53c00000000000cb3f8e380000000000cb3fa4300000000000cb3f94d40000000000cbbfb23c0000000000cb3f499c0000000000cbbfa5e00000000000cbbfb0680000000000cbbfad8c0000000000cb3f8ba40000000000cb3fa4e40000000000cb3f9e2c0000000000cbbf893c0000000000cbbf56400000000000cb3fa9d00000000000cbbfa9540000000000cbbfa9680000000000cb3f7e900000000000cb3fa0cc0000000000cbbf798c0000000000cb3f9fa80000000000cbbfb6800000000000cbbf929c0000000000cbbfb2cc0000000000cb3fb1840000000000cbbf89740000000000cbbfb9240000000000cb3faefc0000000000cb3f97f40000000000cbbf959c0000000000cb3fc0f40000000000cb3fa0040000000000cbbfa0240000000000cbbfbf2c0000000000cbbf90e00000000000cbbf758c0000000000cbbfa8700000000000cbbfae640000000000cb3f62b40000000000cbbfa0640000000000cbbf95500000000000cbbf90d40000000000cb3f9fe80000000000cbbfba600000000000cb3fa00c0000000000cb3f75180000000000cb3f90080000000000cbbfa8880000000000cbbfb2dc0000000000cb3fb1a40000000000cbbf7c680000000000cbbfc1cc0000000000cbbfb4680000000000cb3fa4640000000000cb3f91640000000000cb3f9a440000000000cb3fabe00000000000cb3f9a680000000000cbbfb3400000000000cb3f83dc0000000000cb3fb35c0000000000cb3fa3e40000000000cbbfb6700000000000cb3f8ab40000000000cb3fac100000000000cb3f33f40000000000cb3f75940000000000cb3faec80000000000cbbfa5a40000000000cbbf9c040000000000cbbfb2940000000000cbbfad940000000000cbbfa4440000000000cbbfb8480000000000cb3fa6f00000000000cb3f7b8c0000000000cbbfb1580000000000cbbfaa580000000000cb3f9ba40000000000cbbfaa440000000000cbbf956c0000000000cb3fb0680000000000cbbfa06c0000000000cbbfb0880000000000cbbf7d000000000000cbbfb4280000000000cb3f9b0c0000000000cbbf984c0000000000cb3f8cf80000000000cb3fa6a40000000000cb3fa4180000000000cbbf7f480000000000cb3f82d40000000000cb3f95340000000000cb3fa4300000000000cbbf7e340000000000cbbfb4680000000000cbbf98200000000000cb3fabdc0000000000cb3f85880000000000cb3fa5680000000000cbbf932c0000000000cbbfa6280000000000cb3fa1940000000000cbbfb1cc0000000000cb3f81d00000000000cb3fafc00000000000cb3f77f00000000000cb3fb4540000000000cb3fadb00000000000cbbfb2500000000000cbbf8c0c0000000000cbbfb2580000000000cb3fa3040000000000cb3f80240000000000cbbf942c0000000000cbbf96880000000000cbbf72980000000000cbbf673c0000000000cb3f90e80000000000cb3fb42c0000000000cb3f81100000000000cb3f68880000000000cb3f7fb40000000000cbbfc4080000000000cbbf87380000000000cbbfada00000000000cb3fa5d00000000000cb3fa0fc0000000000cb3f53600000000000cbbfa94c0000000000cbbfa4cc0000000000cbbfa9e00000000000cbbf8a900000000000cb3f96500000000000cbbfba640000000000cbbfa0180000000000cbbfa3280000000000cbbf86a00000000000cb3f9cf40000000000cbbfb6100000000000cb3f92bc0000000000cbbfa6180000000000cbbfae380000000000cb3f99440000000000cbbfb70c0000000000cb3f99680000000000cbbf87b00000000000cb3fb5100000000000cbbf8e740000000000cbbf89640000000000cbbfb1200000000000cbbfb78c0000000000cbbfa6100000000000cbbf9b440000000000cbbfabec0000000000cbbfbbd00000000000cb3fb6900000000000cb3f86d80000000000cb3fb08c0000000000cb3fbaec0000000000cbbf99640000000000cb3fa0880000000000cbbfa0e80000000000cb3f80880000000000cb3f9f800000000000cbbf73380000000000cb3f67100000000000cbbfa7600000000000cb3f7fb80000000000cb3f65480000000000cb3f9a240000000000cb3fa87c0000000000cbbf9b780000000000cb3fb1b80000000000cb3f7ad80000000000cb3fb3e40000000000cbbfc1ac0000000000cb3faa5c0000000000cbbf8e800000000000cb3fa8100000000000cbbfb0d80000000000cb3fa3100000000000cb3f8c300000000000cb3fb6d00000000000cb3fa5c80000000000cb3fa52c0000000000cbbf95380000000000cbbf94bc0000000000cb3f69f00000000000cb3fbe580000000000cbbf96b00000000000cbbf66880000000000	~__pregel_pull, parallel_init
test-sql-1-52887a2a		1f14ba30-e425-6d33-8000-7cbca118e52b	2edde6f9-bb58-88ca-dfc6-87478c8a343e	4	embedding_done	msgpack	\\xc3	~__pregel_pull, parallel_init
test-sql-1-52887a2a		1f14ba30-e425-6d33-8000-7cbca118e52b	2edde6f9-bb58-88ca-dfc6-87478c8a343e	5	conversation_history	msgpack	\\x90	~__pregel_pull, parallel_init
test-sql-1-52887a2a		1f14ba30-e425-6d33-8000-7cbca118e52b	2edde6f9-bb58-88ca-dfc6-87478c8a343e	6	conversation_summary	msgpack	\\xa0	~__pregel_pull, parallel_init
test-sql-1-52887a2a		1f14ba30-e425-6d33-8000-7cbca118e52b	2edde6f9-bb58-88ca-dfc6-87478c8a343e	7	history_token_usage	msgpack	\\x00	~__pregel_pull, parallel_init
test-sql-1-52887a2a		1f14ba30-e425-6d33-8000-7cbca118e52b	2edde6f9-bb58-88ca-dfc6-87478c8a343e	8	cache_hit	msgpack	\\xc2	~__pregel_pull, parallel_init
test-sql-1-52887a2a		1f14ba30-e425-6d33-8000-7cbca118e52b	2edde6f9-bb58-88ca-dfc6-87478c8a343e	9	l1_checked	msgpack	\\xc3	~__pregel_pull, parallel_init
test-sql-1-52887a2a		1f14ba30-e425-6d33-8000-7cbca118e52b	2edde6f9-bb58-88ca-dfc6-87478c8a343e	10	decision_trace	msgpack	\\x9183a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40e53d5ccccccccda76f7574636f6d65a773756363657373	~__pregel_pull, parallel_init
test-sql-1-52887a2a		1f14ba30-e425-6d33-8000-7cbca118e52b	2edde6f9-bb58-88ca-dfc6-87478c8a343e	11	branch:to:supervisor_intent	null	\\x	~__pregel_pull, parallel_init
test-sql-1-52887a2a		1f14ba32-8300-680a-8001-8d2b75fce1cb	4d520685-564f-271f-11a2-0393502e5b9a	0	messages	msgpack	\\x90	~__pregel_pull, supervisor_intent
test-sql-1-52887a2a		1f14ba32-8300-680a-8001-8d2b75fce1cb	4d520685-564f-271f-11a2-0393502e5b9a	1	intent	msgpack	\\xa373716c	~__pregel_pull, supervisor_intent
test-sql-1-52887a2a		1f14ba32-8300-680a-8001-8d2b75fce1cb	4d520685-564f-271f-11a2-0393502e5b9a	2	intent_confidence	msgpack	\\xcb3ff0000000000000	~__pregel_pull, supervisor_intent
test-sql-1-52887a2a		1f14ba32-8300-680a-8001-8d2b75fce1cb	4d520685-564f-271f-11a2-0393502e5b9a	3	detected_domains	msgpack	\\x92a750524f44554354a353514c	~__pregel_pull, supervisor_intent
test-sql-1-52887a2a		1f14ba32-8300-680a-8001-8d2b75fce1cb	4d520685-564f-271f-11a2-0393502e5b9a	4	decision_trace	msgpack	\\x9283a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40e53d5ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40e55d0ccccccccda76f7574636f6d65a773756363657373	~__pregel_pull, supervisor_intent
test-sql-1-52887a2a		1f14ba32-8300-680a-8001-8d2b75fce1cb	4d520685-564f-271f-11a2-0393502e5b9a	5	branch:to:sql_complexity	null	\\x	~__pregel_pull, supervisor_intent
test-sql-1-52887a2a		1f14ba34-2445-6cb3-8002-361730444231	92af4dfe-7252-66dd-b879-168123556744	0	messages	msgpack	\\x90	~__pregel_pull, sql_complexity
test-sql-1-52887a2a		1f14ba34-2445-6cb3-8002-361730444231	92af4dfe-7252-66dd-b879-168123556744	1	query_complexity	msgpack	\\xa673696d706c65	~__pregel_pull, sql_complexity
test-sql-1-52887a2a		1f14ba34-2445-6cb3-8002-361730444231	92af4dfe-7252-66dd-b879-168123556744	2	decision_trace	msgpack	\\x9383a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40e53d5ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40e55d0ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b773716c5f636f6d706c65786974795f6465746563746f72aa6c6174656e63795f6d73cb40e574a99999999aa76f7574636f6d65a773756363657373	~__pregel_pull, sql_complexity
test-sql-1-52887a2a		1f14ba34-2445-6cb3-8002-361730444231	92af4dfe-7252-66dd-b879-168123556744	3	branch:to:sql_cache_l2	null	\\x	~__pregel_pull, sql_complexity
test-sql-1-52887a2a		1f14ba35-c757-63e1-8003-8d500570b5fd	9dd231a1-839c-7046-6d4d-d60e90de056f	0	messages	msgpack	\\x90	~__pregel_pull, sql_cache_l2
test-sql-1-52887a2a		1f14ba35-c757-63e1-8003-8d500570b5fd	9dd231a1-839c-7046-6d4d-d60e90de056f	1	l2_hit	msgpack	\\xc2	~__pregel_pull, sql_cache_l2
test-sql-1-52887a2a		1f14ba35-c757-63e1-8003-8d500570b5fd	9dd231a1-839c-7046-6d4d-d60e90de056f	2	decision_trace	msgpack	\\x9483a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40e53d5ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40e55d0ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b773716c5f636f6d706c65786974795f6465746563746f72aa6c6174656e63795f6d73cb40e574a99999999aa76f7574636f6d65a77375636365737383a46e6f6465ac73716c5f63616368655f6c32aa6c6174656e63795f6d73cb4016cccccccccccda76f7574636f6d65a773756363657373	~__pregel_pull, sql_cache_l2
test-sql-1-52887a2a		1f14ba35-c757-63e1-8003-8d500570b5fd	9dd231a1-839c-7046-6d4d-d60e90de056f	3	branch:to:sql_schema	null	\\x	~__pregel_pull, sql_cache_l2
test-sql-1-52887a2a		1f14ba35-c766-6cd8-8004-1dc1c66eef69	7e42df45-bb3d-d0af-cce4-b4fee034eb2f	0	messages	msgpack	\\x90	~__pregel_pull, sql_schema
test-sql-1-52887a2a		1f14ba39-2467-6faa-8008-72a89d708cc4	3e7f5b39-4ff5-f12b-f6a3-b9a86fd488ff	1	sql_results	msgpack	\\x9583a2696401a3736b75ae534b552d4c4150544f502d303031aa756e69745f7072696365cb408c1feb851eb85283a2696404a3736b75ac534b552d4445534b2d303031aa756e69745f7072696365cb40812feb851eb85283a2696402a3736b75ae534b552d5441424c45542d303031aa756e69745f7072696365cb407f3fd70a3d70a483a2696405a3736b75ad534b552d43484149522d303031aa756e69745f7072696365cb4075dfd70a3d70a483a2696406a3736b75ac534b552d484841542d303031aa756e69745f7072696365cb4038fd70a3d70a3d	~__pregel_pull, sql_executor
test-sql-1-52887a2a		1f14ba39-2467-6faa-8008-72a89d708cc4	3e7f5b39-4ff5-f12b-f6a3-b9a86fd488ff	2	decision_trace	msgpack	\\x9983a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40e53d5ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40e55d0ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b773716c5f636f6d706c65786974795f6465746563746f72aa6c6174656e63795f6d73cb40e574a99999999aa76f7574636f6d65a77375636365737383a46e6f6465ac73716c5f63616368655f6c32aa6c6174656e63795f6d73cb4016cccccccccccda76f7574636f6d65a77375636365737383a46e6f6465b473716c5f736368656d615f726574726965766572aa6c6174656e63795f6d73cb40a3bd3333333333a76f7574636f6d65a77375636365737383a46e6f6465ad73716c5f67656e657261746f72aa6c6174656e63795f6d73cb40f56c3b33333333a76f7574636f6d65a77375636365737383a46e6f6465ad73716c5f76616c696461746f72aa6c6174656e63795f6d73cb0000000000000000a76f7574636f6d65a77375636365737383a46e6f6465ac73716c5f617070726f76616caa6c6174656e63795f6d73cb0000000000000000a76f7574636f6d65a77375636365737383a46e6f6465ac73716c5f6578656375746f72aa6c6174656e63795f6d73cb4023000000000000a76f7574636f6d65a773756363657373	~__pregel_pull, sql_executor
test-sql-1-52887a2a		1f14ba39-2467-6faa-8008-72a89d708cc4	3e7f5b39-4ff5-f12b-f6a3-b9a86fd488ff	3	branch:to:sql_response	null	\\x	~__pregel_pull, sql_executor
test-sql-1-52887a2a		1f14ba39-2484-616d-8009-cbcbfcf021b2	022a94f7-5f81-0c87-79f4-e6fc5c9fb50d	0	messages	msgpack	\\x90	~__pregel_pull, sql_response
test-sql-1-52887a2a		1f14ba35-c766-6cd8-8004-1dc1c66eef69	7e42df45-bb3d-d0af-cce4-b4fee034eb2f	1	schema_context	msgpack	\\xda193452656c6576616e7420636f6c756d6e733a0a202070726f647563742e756e69745f707269636520284e554d455249432831322c3229293a2053656c6c696e672070726963652070657220756e6974206f66207468652070726f647563740a202070726f647563742e636f73745f707269636520284e554d455249432831322c3229293a2050757263686173652f636f73742070726963652066726f6d20737570706c6965720a2020737570706c6965722e726174696e6720284e554d4552494328332c3229293a20537570706c69657220706572666f726d616e636520726174696e672066726f6d20302e303020746f20352e30300a2020696e76656e746f72792e7175616e746974795f6f6e5f68616e642028494e5445474552293a20546f74616c20706879736963616c207175616e7469747920696e2073746f636b206174206c6f636174696f6e0a202073616c65735f6f726465722e746f74616c5f616d6f756e7420284e554d455249432831342c3229293a20546f74616c206d6f6e65746172792076616c7565206f66207468652073616c6573206f726465720a202070757263686173655f6f726465722e746f74616c5f616d6f756e7420284e554d455249432831342c3229293a20546f74616c206d6f6e65746172792076616c7565206f6620746865207075726368617365206f726465720a202070726f647563742e2028293a2050726f6475637420636174616c6f67207769746820534b552c2070726963696e672c207765696768742c20616e642072656f726465722073657474696e67730a202070726f647563742e756e69745f707269636520284e554d455249432831322c3229293a2053656c6c696e672070726963652070657220756e6974206f66207468652070726f647563740a2020696e76656e746f72792e7175616e746974795f72657365727665642028494e5445474552293a205175616e7469747920726573657276656420666f722070656e64696e67206f72646572730a202073616c65735f6f726465722e746f74616c5f616d6f756e7420284e554d455249432831342c3229293a20546f74616c206d6f6e65746172792076616c7565206f66207468652073616c6573206f726465720a0a46756c6c2044444c3a0a5441424c452063617465676f727920280a2020696420626967696e74204e4f54204e554c4c205052494d415259204b45590a20206e616d65206368617261637465722076617279696e67204e4f54204e554c4c0a2020706172656e745f63617465676f72795f696420626967696e740a20206465736372697074696f6e20746578740a290a0a5441424c4520636865636b706f696e745f626c6f627320280a20207468726561645f69642074657874204e4f54204e554c4c0a2020636865636b706f696e745f6e732074657874204e4f54204e554c4c0a20206368616e6e656c2074657874204e4f54204e554c4c0a202076657273696f6e2074657874204e4f54204e554c4c0a2020747970652074657874204e4f54204e554c4c0a2020626c6f622062797465610a290a0a5441424c4520636865636b706f696e745f6d6967726174696f6e7320280a20207620696e7465676572204e4f54204e554c4c0a290a0a5441424c4520636865636b706f696e745f77726974657320280a20207468726561645f69642074657874204e4f54204e554c4c0a2020636865636b706f696e745f6e732074657874204e4f54204e554c4c0a2020636865636b706f696e745f69642074657874204e4f54204e554c4c0a20207461736b5f69642074657874204e4f54204e554c4c0a202069647820696e7465676572204e4f54204e554c4c0a20206368616e6e656c2074657874204e4f54204e554c4c0a20207479706520746578740a2020626c6f62206279746561204e4f54204e554c4c0a20207461736b5f706174682074657874204e4f54204e554c4c0a290a0a5441424c4520636865636b706f696e747320280a20207468726561645f69642074657874204e4f54204e554c4c0a2020636865636b706f696e745f6e732074657874204e4f54204e554c4c0a2020636865636b706f696e745f69642074657874204e4f54204e554c4c0a2020706172656e745f636865636b706f696e745f696420746578740a20207479706520746578740a2020636865636b706f696e74206a736f6e62204e4f54204e554c4c0a20206d65746164617461206a736f6e62204e4f54204e554c4c0a290a0a5441424c4520637573746f6d657220280a2020696420626967696e74204e4f54204e554c4c205052494d415259204b45590a2020636f6465206368617261637465722076617279696e67204e4f54204e554c4c0a20206e616d65206368617261637465722076617279696e67204e4f54204e554c4c0a2020656d61696c206368617261637465722076617279696e670a202070686f6e65206368617261637465722076617279696e670a202063697479206368617261637465722076617279696e670a20207374617465206368617261637465722076617279696e670a2020637573746f6d65725f74797065206368617261637465722076617279696e670a20206372656469745f6c696d6974206e756d657269630a202069735f61637469766520626f6f6c65616e0a290a0a5441424c4520696e76656e746f727920280a2020696420626967696e74204e4f54204e554c4c205052494d415259204b45590a202070726f647563745f696420626967696e74204e4f54204e554c4c0a20206c6f636174696f6e5f696420626967696e74204e4f54204e554c4c0a20207175616e746974795f6f6e5f68616e6420696e7465676572204e4f54204e554c4c0a20207175616e746974795f726573657276656420696e7465676572204e4f54204e554c4c0a20207175616e746974795f617661696c61626c6520696e74656765720a20206c6f745f6e756d626572206368617261637465722076617279696e670a20206578706972795f6461746520646174650a2020757064617465645f61742074696d657374616d7020776974686f75742074696d65207a6f6e650a290a0a5441424c4520696e76656e746f72795f7472616e73616374696f6e20280a2020696420626967696e74204e4f54204e554c4c205052494d415259204b45590a202070726f647563745f696420626967696e74204e4f54204e554c4c0a202066726f6d5f6c6f636174696f6e5f696420626967696e740a2020746f5f6c6f636174696f6e5f696420626967696e740a20207472616e73616374696f6e5f74797065206368617261637465722076617279696e67204e4f54204e554c4c0a20207175616e7469747920696e7465676572204e4f54204e554c4c0a20207265666572656e63655f74797065206368617261637465722076617279696e670a20207265666572656e63655f696420626967696e740a2020706572666f726d65645f6279206368617261637465722076617279696e670a2020637265617465645f61742074696d657374616d7020776974686f75742074696d65207a6f6e650a290a0a5441424c45206c6f636174696f6e20280a2020696420626967696e74204e4f54204e554c4c205052494d415259204b45590a20207a6f6e655f696420626967696e74204e4f54204e554c4c0a20206169736c65206368617261637465722076617279696e670a20207261636b206368617261637465722076617279696e670a20207368656c66206368617261637465722076617279696e670a202062696e206368617261637465722076617279696e670a2020626172636f6465206368617261637465722076617279696e670a20206c6f636174696f6e5f74797065206368617261637465722076617279696e67204e4f54204e554c4c0a20206d61785f7765696768745f6b67206e756d657269630a202069735f6f6363757069656420626f6f6c65616e0a290a0a5441424c452070726f6475637420280a2020696420626967696e74204e4f54204e554c4c205052494d415259204b45590a2020736b75206368617261637465722076617279696e67204e4f54204e554c4c0a20206e616d65206368617261637465722076617279696e67204e4f54204e554c4c0a20206465736372697074696f6e20746578740a202063617465676f72795f696420626967696e740a2020737570706c6965725f696420626967696e740a2020756e69745f7072696365206e756d657269630a2020636f73745f7072696365206e756d657269630a20207765696768745f6b67206e756d657269630a2020756f6d206368617261637465722076617279696e670a202069735f70657269736861626c6520626f6f6c65616e0a20206d696e5f73746f636b5f6c6576656c20696e74656765720a202072656f726465725f706f696e7420696e74656765720a202072656f726465725f71747920696e74656765720a202069735f61637469766520626f6f6c65616e0a2020637265617465645f61742074696d657374616d7020776974686f75742074696d65207a6f6e650a290a0a5441424c452070757263686173655f6f7264657220280a2020696420626967696e74204e4f54204e554c4c205052494d415259204b45590a2020706f5f6e756d626572206368617261637465722076617279696e67204e4f54204e554c4c0a2020737570706c6965725f696420626967696e74204e4f54204e554c4c0a202077617265686f7573655f696420626967696e74204e4f54204e554c4c0a2020737461747573206368617261637465722076617279696e670a20206f726465725f6461746520646174650a202065787065637465645f64656c697665727920646174650a2020746f74616c5f616d6f756e74206e756d657269630a2020637265617465645f6279206368617261637465722076617279696e670a2020637265617465645f61742074696d657374616d7020776974686f75742074696d65207a6f6e650a290a0a5441424c452070757263686173655f6f726465725f6c696e6520280a2020696420626967696e74204e4f54204e554c4c205052494d415259204b45590a202070757263686173655f6f726465725f696420626967696e74204e4f54204e554c4c0a202070726f647563745f696420626967696e74204e4f54204e554c4c0a20207175616e746974795f6f72646572656420696e7465676572204e4f54204e554c4c0a20207175616e746974795f726563656976656420696e74656765720a2020756e69745f7072696365206e756d657269630a290a0a5441424c452073616c65735f6f7264657220280a2020696420626967696e74204e4f54204e554c4c205052494d415259204b45590a20206f726465725f6e756d626572206368617261637465722076617279696e67204e4f54204e554c4c0a2020637573746f6d65725f696420626967696e74204e4f54204e554c4c0a202077617265686f7573655f696420626967696e74204e4f54204e554c4c0a2020737461747573206368617261637465722076617279696e670a20207072696f72697479206368617261637465722076617279696e670a20206f726465725f6461746520646174650a202072657175697265645f6461746520646174650a2020746f74616c5f616d6f756e74206e756d657269630a20207368697070696e675f6d6574686f64206368617261637465722076617279696e670a2020637265617465645f61742074696d657374616d7020776974686f75742074696d65207a6f6e650a290a0a5441424c452073616c65735f6f726465725f6c696e6520280a2020696420626967696e74204e4f54204e554c4c205052494d415259204b45590a202073616c65735f6f726465725f696420626967696e74204e4f54204e554c4c0a202070726f647563745f696420626967696e74204e4f54204e554c4c0a20207175616e746974795f6f72646572656420696e7465676572204e4f54204e554c4c0a20207175616e746974795f7368697070656420696e74656765720a2020756e69745f7072696365206e756d657269630a290a0a5441424c4520736869706d656e7420280a2020696420626967696e74204e4f54204e554c4c205052494d415259204b45590a2020736869706d656e745f6e756d626572206368617261637465722076617279696e67204e4f54204e554c4c0a202073616c65735f6f726465725f696420626967696e74204e4f54204e554c4c0a202063617272696572206368617261637465722076617279696e670a2020747261636b696e675f6e756d626572206368617261637465722076617279696e670a2020737461747573206368617261637465722076617279696e670a2020736869707065645f646174652074696d657374616d7020776974686f75742074696d65207a6f6e650a202064656c6976657265645f646174652074696d657374616d7020776974686f75742074696d65207a6f6e650a2020637265617465645f61742074696d657374616d7020776974686f75742074696d65207a6f6e650a290a0a5441424c4520737570706c69657220280a2020696420626967696e74204e4f54204e554c4c205052494d415259204b45590a2020636f6465206368617261637465722076617279696e67204e4f54204e554c4c0a20206e616d65206368617261637465722076617279696e67204e4f54204e554c4c0a2020636f6e746163745f6e616d65206368617261637465722076617279696e670a2020656d61696c206368617261637465722076617279696e670a202070686f6e65206368617261637465722076617279696e670a202063697479206368617261637465722076617279696e670a2020636f756e747279206368617261637465722076617279696e670a20206c6561645f74696d655f6461797320696e74656765720a2020726174696e67206e756d657269630a290a0a5441424c452077617265686f75736520280a2020696420626967696e74204e4f54204e554c4c205052494d415259204b45590a2020636f6465206368617261637465722076617279696e67204e4f54204e554c4c0a20206e616d65206368617261637465722076617279696e67204e4f54204e554c4c0a202063697479206368617261637465722076617279696e670a20207374617465206368617261637465722076617279696e670a202063617061636974795f73716674206e756d657269630a202069735f61637469766520626f6f6c65616e0a2020637265617465645f61742074696d657374616d7020776974686f75742074696d65207a6f6e650a290a0a5441424c45207a6f6e6520280a2020696420626967696e74204e4f54204e554c4c205052494d415259204b45590a202077617265686f7573655f696420626967696e74204e4f54204e554c4c0a2020636f6465206368617261637465722076617279696e67204e4f54204e554c4c0a20206e616d65206368617261637465722076617279696e67204e4f54204e554c4c0a20207a6f6e655f74797065206368617261637465722076617279696e67204e4f54204e554c4c0a202074656d70657261747572655f636f6e74726f6c6c656420626f6f6c65616e0a20206d61785f63617061636974795f756e69747320696e74656765720a20207574696c697a6174696f6e5f706374206e756d657269630a290a0a464f524549474e204b4559533a0a20207a6f6e652e77617265686f7573655f6964202d3e2077617265686f7573652e69640a20206c6f636174696f6e2e7a6f6e655f6964202d3e207a6f6e652e69640a202063617465676f72792e706172656e745f63617465676f72795f6964202d3e2063617465676f72792e69640a202070726f647563742e63617465676f72795f6964202d3e2063617465676f72792e69640a202070726f647563742e737570706c6965725f6964202d3e20737570706c6965722e69640a2020696e76656e746f72792e70726f647563745f6964202d3e2070726f647563742e69640a2020696e76656e746f72792e6c6f636174696f6e5f6964202d3e206c6f636174696f6e2e69640a2020696e76656e746f72795f7472616e73616374696f6e2e70726f647563745f6964202d3e2070726f647563742e69640a2020696e76656e746f72795f7472616e73616374696f6e2e66726f6d5f6c6f636174696f6e5f6964202d3e206c6f636174696f6e2e69640a2020696e76656e746f72795f7472616e73616374696f6e2e746f5f6c6f636174696f6e5f6964202d3e206c6f636174696f6e2e69640a202070757263686173655f6f726465722e737570706c6965725f6964202d3e20737570706c6965722e69640a202070757263686173655f6f726465722e77617265686f7573655f6964202d3e2077617265686f7573652e69640a202070757263686173655f6f726465725f6c696e652e70757263686173655f6f726465725f6964202d3e2070757263686173655f6f726465722e69640a202070757263686173655f6f726465725f6c696e652e70726f647563745f6964202d3e2070726f647563742e69640a202073616c65735f6f726465722e637573746f6d65725f6964202d3e20637573746f6d65722e69640a202073616c65735f6f726465722e77617265686f7573655f6964202d3e2077617265686f7573652e69640a202073616c65735f6f726465725f6c696e652e73616c65735f6f726465725f6964202d3e2073616c65735f6f726465722e69640a202073616c65735f6f726465725f6c696e652e70726f647563745f6964202d3e2070726f647563742e69640a2020736869706d656e742e73616c65735f6f726465725f6964202d3e2073616c65735f6f726465722e6964	~__pregel_pull, sql_schema
test-sql-1-52887a2a		1f14ba35-c766-6cd8-8004-1dc1c66eef69	7e42df45-bb3d-d0af-cce4-b4fee034eb2f	2	tables_used	msgpack	\\x95a9696e76656e746f7279a8737570706c696572a770726f64756374ab73616c65735f6f72646572ae70757263686173655f6f72646572	~__pregel_pull, sql_schema
test-sql-1-52887a2a		1f14ba35-c766-6cd8-8004-1dc1c66eef69	7e42df45-bb3d-d0af-cce4-b4fee034eb2f	3	decision_trace	msgpack	\\x9583a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40e53d5ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40e55d0ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b773716c5f636f6d706c65786974795f6465746563746f72aa6c6174656e63795f6d73cb40e574a99999999aa76f7574636f6d65a77375636365737383a46e6f6465ac73716c5f63616368655f6c32aa6c6174656e63795f6d73cb4016cccccccccccda76f7574636f6d65a77375636365737383a46e6f6465b473716c5f736368656d615f726574726965766572aa6c6174656e63795f6d73cb40a3bd3333333333a76f7574636f6d65a773756363657373	~__pregel_pull, sql_schema
test-sql-1-52887a2a		1f14ba35-c766-6cd8-8004-1dc1c66eef69	7e42df45-bb3d-d0af-cce4-b4fee034eb2f	4	branch:to:sql_generator	null	\\x	~__pregel_pull, sql_schema
test-sql-1-52887a2a		1f14ba35-df83-6cfd-8005-90112d0494b7	eb21b01d-caac-63b6-a1a6-8534c32ae6e6	0	messages	msgpack	\\x90	~__pregel_pull, sql_generator
test-sql-1-52887a2a		1f14ba35-df83-6cfd-8005-90112d0494b7	eb21b01d-caac-63b6-a1a6-8534c32ae6e6	1	generated_sql	msgpack	\\xd94853454c4543542069642c20736b752c20756e69745f70726963652046524f4d2070726f64756374204f5244455220425920756e69745f70726963652044455343204c494d49542035	~__pregel_pull, sql_generator
test-sql-1-52887a2a		1f14ba35-df83-6cfd-8005-90112d0494b7	eb21b01d-caac-63b6-a1a6-8534c32ae6e6	2	sql_confidence	msgpack	\\xcb3feccccccccccccd	~__pregel_pull, sql_generator
test-sql-1-52887a2a		1f14ba35-df83-6cfd-8005-90112d0494b7	eb21b01d-caac-63b6-a1a6-8534c32ae6e6	3	tables_used	msgpack	\\x91a770726f64756374	~__pregel_pull, sql_generator
test-sql-1-52887a2a		1f14ba35-df83-6cfd-8005-90112d0494b7	eb21b01d-caac-63b6-a1a6-8534c32ae6e6	4	retry_count	msgpack	\\x00	~__pregel_pull, sql_generator
test-sql-1-52887a2a		1f14ba35-df83-6cfd-8005-90112d0494b7	eb21b01d-caac-63b6-a1a6-8534c32ae6e6	5	decision_trace	msgpack	\\x9683a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40e53d5ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40e55d0ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b773716c5f636f6d706c65786974795f6465746563746f72aa6c6174656e63795f6d73cb40e574a99999999aa76f7574636f6d65a77375636365737383a46e6f6465ac73716c5f63616368655f6c32aa6c6174656e63795f6d73cb4016cccccccccccda76f7574636f6d65a77375636365737383a46e6f6465b473716c5f736368656d615f726574726965766572aa6c6174656e63795f6d73cb40a3bd3333333333a76f7574636f6d65a77375636365737383a46e6f6465ad73716c5f67656e657261746f72aa6c6174656e63795f6d73cb40f56c3b33333333a76f7574636f6d65a773756363657373	~__pregel_pull, sql_generator
test-sql-1-52887a2a		1f14ba35-df83-6cfd-8005-90112d0494b7	eb21b01d-caac-63b6-a1a6-8534c32ae6e6	6	branch:to:sql_validator	null	\\x	~__pregel_pull, sql_generator
test-sql-1-52887a2a		1f14ba39-245c-667a-8006-c6ce61a12af4	a914e362-f312-2773-a32d-c89fc120ba13	0	messages	msgpack	\\x90	~__pregel_pull, sql_validator
test-sql-1-52887a2a		1f14ba39-245c-667a-8006-c6ce61a12af4	a914e362-f312-2773-a32d-c89fc120ba13	1	validation_errors	msgpack	\\x90	~__pregel_pull, sql_validator
test-sql-1-52887a2a		1f14ba39-245c-667a-8006-c6ce61a12af4	a914e362-f312-2773-a32d-c89fc120ba13	2	sql_validated	msgpack	\\xc3	~__pregel_pull, sql_validator
test-sql-1-52887a2a		1f14ba39-245c-667a-8006-c6ce61a12af4	a914e362-f312-2773-a32d-c89fc120ba13	3	estimated_cost	msgpack	\\xa36c6f77	~__pregel_pull, sql_validator
test-sql-1-52887a2a		1f14ba39-245c-667a-8006-c6ce61a12af4	a914e362-f312-2773-a32d-c89fc120ba13	4	retry_count	msgpack	\\x00	~__pregel_pull, sql_validator
test-sql-1-52887a2a		1f14ba39-245c-667a-8006-c6ce61a12af4	a914e362-f312-2773-a32d-c89fc120ba13	5	decision_trace	msgpack	\\x9783a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40e53d5ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40e55d0ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b773716c5f636f6d706c65786974795f6465746563746f72aa6c6174656e63795f6d73cb40e574a99999999aa76f7574636f6d65a77375636365737383a46e6f6465ac73716c5f63616368655f6c32aa6c6174656e63795f6d73cb4016cccccccccccda76f7574636f6d65a77375636365737383a46e6f6465b473716c5f736368656d615f726574726965766572aa6c6174656e63795f6d73cb40a3bd3333333333a76f7574636f6d65a77375636365737383a46e6f6465ad73716c5f67656e657261746f72aa6c6174656e63795f6d73cb40f56c3b33333333a76f7574636f6d65a77375636365737383a46e6f6465ad73716c5f76616c696461746f72aa6c6174656e63795f6d73cb0000000000000000a76f7574636f6d65a773756363657373	~__pregel_pull, sql_validator
test-sql-1-52887a2a		1f14ba39-245c-667a-8006-c6ce61a12af4	a914e362-f312-2773-a32d-c89fc120ba13	6	branch:to:sql_approval	null	\\x	~__pregel_pull, sql_validator
test-sql-1-52887a2a		1f14ba39-245e-6be5-8007-aa7713c43ad0	5bf05bbe-3568-919b-b378-7b604544ae64	0	messages	msgpack	\\x90	~__pregel_pull, sql_approval
test-sql-1-52887a2a		1f14ba39-245e-6be5-8007-aa7713c43ad0	5bf05bbe-3568-919b-b378-7b604544ae64	1	approved	msgpack	\\xc3	~__pregel_pull, sql_approval
test-sql-1-52887a2a		1f14ba39-245e-6be5-8007-aa7713c43ad0	5bf05bbe-3568-919b-b378-7b604544ae64	2	approval_explanation	msgpack	\\xb84175746f2d617070726f7665642028646576206d6f646529	~__pregel_pull, sql_approval
test-sql-1-52887a2a		1f14ba39-245e-6be5-8007-aa7713c43ad0	5bf05bbe-3568-919b-b378-7b604544ae64	3	decision_trace	msgpack	\\x9883a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40e53d5ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40e55d0ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b773716c5f636f6d706c65786974795f6465746563746f72aa6c6174656e63795f6d73cb40e574a99999999aa76f7574636f6d65a77375636365737383a46e6f6465ac73716c5f63616368655f6c32aa6c6174656e63795f6d73cb4016cccccccccccda76f7574636f6d65a77375636365737383a46e6f6465b473716c5f736368656d615f726574726965766572aa6c6174656e63795f6d73cb40a3bd3333333333a76f7574636f6d65a77375636365737383a46e6f6465ad73716c5f67656e657261746f72aa6c6174656e63795f6d73cb40f56c3b33333333a76f7574636f6d65a77375636365737383a46e6f6465ad73716c5f76616c696461746f72aa6c6174656e63795f6d73cb0000000000000000a76f7574636f6d65a77375636365737383a46e6f6465ac73716c5f617070726f76616caa6c6174656e63795f6d73cb0000000000000000a76f7574636f6d65a773756363657373	~__pregel_pull, sql_approval
test-sql-1-52887a2a		1f14ba39-245e-6be5-8007-aa7713c43ad0	5bf05bbe-3568-919b-b378-7b604544ae64	4	branch:to:sql_executor	null	\\x	~__pregel_pull, sql_approval
test-sql-1-52887a2a		1f14ba39-2467-6faa-8008-72a89d708cc4	3e7f5b39-4ff5-f12b-f6a3-b9a86fd488ff	0	messages	msgpack	\\x90	~__pregel_pull, sql_executor
test-compound-1-5774cb33		1f14ba43-45e7-6478-8001-cd896f58a5b8	4483dc6d-09ff-d512-4827-2e19e7af2b4f	0	messages	msgpack	\\x90	~__pregel_pull, supervisor_intent
test-sql-1-52887a2a		1f14ba39-2484-616d-8009-cbcbfcf021b2	022a94f7-5f81-0c87-79f4-e6fc5c9fb50d	1	sql_explanation	msgpack	\\xda015554686520746f7020352070726f6475637473206279207072696365206172653a0a0a54686520726573756c74732073686f77207468617420746865204c6170746f702028534b552d4c4150544f502d3030312920697320746865206d6f737420657870656e736976652070726f6475637420617420243839392e39392c20666f6c6c6f77656420627920746865204465736b2028534b552d4445534b2d3030312920617420243534392e39392c20616e6420746865205461626c65742028534b552d5441424c45542d3030312920617420243439392e39392e205468652043686169722028534b552d43484149522d3030312920616e642048656164204861742028534b552d484841542d3030312920617265207369676e69666963616e746c7920636865617065722c2070726963656420617420243334392e393920616e64202432342e393920726573706563746976656c792e	~__pregel_pull, sql_response
test-sql-1-52887a2a		1f14ba39-2484-616d-8009-cbcbfcf021b2	022a94f7-5f81-0c87-79f4-e6fc5c9fb50d	2	final_answer	msgpack	\\xda015554686520746f7020352070726f6475637473206279207072696365206172653a0a0a54686520726573756c74732073686f77207468617420746865204c6170746f702028534b552d4c4150544f502d3030312920697320746865206d6f737420657870656e736976652070726f6475637420617420243839392e39392c20666f6c6c6f77656420627920746865204465736b2028534b552d4445534b2d3030312920617420243534392e39392c20616e6420746865205461626c65742028534b552d5441424c45542d3030312920617420243439392e39392e205468652043686169722028534b552d43484149522d3030312920616e642048656164204861742028534b552d484841542d3030312920617265207369676e69666963616e746c7920636865617065722c2070726963656420617420243334392e393920616e64202432342e393920726573706563746976656c792e	~__pregel_pull, sql_response
test-sql-1-52887a2a		1f14ba39-2484-616d-8009-cbcbfcf021b2	022a94f7-5f81-0c87-79f4-e6fc5c9fb50d	3	status	msgpack	\\xa9636f6d706c65746564	~__pregel_pull, sql_response
test-sql-1-52887a2a		1f14ba39-2484-616d-8009-cbcbfcf021b2	022a94f7-5f81-0c87-79f4-e6fc5c9fb50d	4	decision_trace	msgpack	\\x9a83a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40e53d5ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40e55d0ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b773716c5f636f6d706c65786974795f6465746563746f72aa6c6174656e63795f6d73cb40e574a99999999aa76f7574636f6d65a77375636365737383a46e6f6465ac73716c5f63616368655f6c32aa6c6174656e63795f6d73cb4016cccccccccccda76f7574636f6d65a77375636365737383a46e6f6465b473716c5f736368656d615f726574726965766572aa6c6174656e63795f6d73cb40a3bd3333333333a76f7574636f6d65a77375636365737383a46e6f6465ad73716c5f67656e657261746f72aa6c6174656e63795f6d73cb40f56c3b33333333a76f7574636f6d65a77375636365737383a46e6f6465ad73716c5f76616c696461746f72aa6c6174656e63795f6d73cb0000000000000000a76f7574636f6d65a77375636365737383a46e6f6465ac73716c5f617070726f76616caa6c6174656e63795f6d73cb0000000000000000a76f7574636f6d65a77375636365737383a46e6f6465ac73716c5f6578656375746f72aa6c6174656e63795f6d73cb4023000000000000a76f7574636f6d65a77375636365737383a46e6f6465ac73716c5f726573706f6e7365aa6c6174656e63795f6d73cb40e5347666666666a76f7574636f6d65a773756363657373	~__pregel_pull, sql_response
test-compound-1-5774cb33		1f14ba41-a2fa-6ad5-bfff-9207c13e1fad	240516ff-5ff6-4528-be8c-2cbfab4e7e8f	0	messages	msgpack	\\x90	~__pregel_pull, __start__
test-compound-1-5774cb33		1f14ba41-a2fa-6ad5-bfff-9207c13e1fad	240516ff-5ff6-4528-be8c-2cbfab4e7e8f	1	original_query	msgpack	\\xd9355768617420697320746865206c6561766520706f6c69637920616e642073686f77206d6520746f74616c20656d706c6f796565733f	~__pregel_pull, __start__
test-compound-1-5774cb33		1f14ba41-a2fa-6ad5-bfff-9207c13e1fad	240516ff-5ff6-4528-be8c-2cbfab4e7e8f	2	session_id	msgpack	\\xaf746573742d636f6d706f756e642d31	~__pregel_pull, __start__
test-compound-1-5774cb33		1f14ba41-a2fa-6ad5-bfff-9207c13e1fad	240516ff-5ff6-4528-be8c-2cbfab4e7e8f	3	require_approval	msgpack	\\xc2	~__pregel_pull, __start__
test-compound-1-5774cb33		1f14ba41-a2fa-6ad5-bfff-9207c13e1fad	240516ff-5ff6-4528-be8c-2cbfab4e7e8f	4	status	msgpack	\\xaa70726f63657373696e67	~__pregel_pull, __start__
test-compound-1-5774cb33		1f14ba41-a2fa-6ad5-bfff-9207c13e1fad	240516ff-5ff6-4528-be8c-2cbfab4e7e8f	5	intent	msgpack	\\xa0	~__pregel_pull, __start__
test-compound-1-5774cb33		1f14ba41-a2fa-6ad5-bfff-9207c13e1fad	240516ff-5ff6-4528-be8c-2cbfab4e7e8f	6	retry_count	msgpack	\\x00	~__pregel_pull, __start__
test-compound-1-5774cb33		1f14ba41-a2fa-6ad5-bfff-9207c13e1fad	240516ff-5ff6-4528-be8c-2cbfab4e7e8f	7	react_steps	msgpack	\\x90	~__pregel_pull, __start__
test-compound-1-5774cb33		1f14ba41-a2fa-6ad5-bfff-9207c13e1fad	240516ff-5ff6-4528-be8c-2cbfab4e7e8f	8	pending_tool_call	msgpack	\\x80	~__pregel_pull, __start__
test-compound-1-5774cb33		1f14ba41-a2fa-6ad5-bfff-9207c13e1fad	240516ff-5ff6-4528-be8c-2cbfab4e7e8f	9	decision_trace	msgpack	\\x90	~__pregel_pull, __start__
test-compound-1-5774cb33		1f14ba41-a2fa-6ad5-bfff-9207c13e1fad	240516ff-5ff6-4528-be8c-2cbfab4e7e8f	10	detected_domains	msgpack	\\x90	~__pregel_pull, __start__
test-compound-1-5774cb33		1f14ba41-a2fa-6ad5-bfff-9207c13e1fad	240516ff-5ff6-4528-be8c-2cbfab4e7e8f	11	branch:to:parallel_init	null	\\x	~__pregel_pull, __start__
test-compound-1-5774cb33		1f14ba41-a306-6e4e-8000-33ba300e82de	8dae2b6e-b57f-fa54-f4c0-beaef43fac3d	0	messages	msgpack	\\x90	~__pregel_pull, parallel_init
test-compound-1-5774cb33		1f14ba41-a306-6e4e-8000-33ba300e82de	8dae2b6e-b57f-fa54-f4c0-beaef43fac3d	1	input_guard_passed	msgpack	\\xc3	~__pregel_pull, parallel_init
test-compound-1-5774cb33		1f14ba41-a306-6e4e-8000-33ba300e82de	8dae2b6e-b57f-fa54-f4c0-beaef43fac3d	2	guard_issues	msgpack	\\x90	~__pregel_pull, parallel_init
test-compound-1-5774cb33		1f14ba41-a306-6e4e-8000-33ba300e82de	8dae2b6e-b57f-fa54-f4c0-beaef43fac3d	3	query_embedding	msgpack	\\xdc0180cb3f56500000000000cbbf98800000000000cb3fa7880000000000cbbfa6e00000000000cb3facf80000000000cbbf633c0000000000cbbfb01c0000000000cb3fa0cc0000000000cbbf81180000000000cb3f9b7c0000000000cbbfa1c00000000000cbbf93a80000000000cbbfa5740000000000cbbfa42c0000000000cb3fb7540000000000cbbfb7f00000000000cbbfc4240000000000cbbf77140000000000cbbfadfc0000000000cbbf8ef80000000000cbbf9d200000000000cbbf975c0000000000cbbf91000000000000cbbfa4100000000000cbbf9a800000000000cb3fa1f40000000000cbbfaca00000000000cbbfb3440000000000cb3fa2800000000000cbbf81d00000000000cb3f75a40000000000cbbf9c500000000000cbbf82240000000000cb3f9fe00000000000cbbfa76c0000000000cbbf93a00000000000cb3faad00000000000cb3fb5800000000000cbbfb1000000000000cb3f94f80000000000cbbfbd200000000000cb3fa1400000000000cbbf72c00000000000cb3fa5fc0000000000cbbfa0c00000000000cb3fa9f80000000000cb3f9fe40000000000cbbfa3200000000000cb3fa3000000000000cbbfa3980000000000cb3f946c0000000000cbbf88200000000000cbbf9fac0000000000cbbf973c0000000000cbbfa89c0000000000cb3fa0740000000000cbbf70440000000000cbbf99cc0000000000cbbfa3000000000000cbbfb8980000000000cbbf7eb80000000000cbbfc1a80000000000cb3fa3580000000000cbbfa1cc0000000000cbbf81a80000000000cbbfa4f80000000000cb3f9c200000000000cb3f98f80000000000cb3facd40000000000cbbf215c0000000000cb3f91bc0000000000cbbf8f340000000000cb3f83f00000000000cb3f60280000000000cbbfa28c0000000000cb3f7fac0000000000cb3fa4fc0000000000cb3f799c0000000000cb3fa0540000000000cb3f863c0000000000cbbfb0740000000000cb3fbe040000000000cbbf82500000000000cb3f75780000000000cbbf8f740000000000cbbfa3880000000000cbbfa1440000000000cb3fb1440000000000cb3fa6a80000000000cbbfb0180000000000cbbf99e80000000000cbbfb4000000000000cb3f91100000000000cbbfb56c0000000000cb3fa16c0000000000cb3fa1080000000000cbbfadec0000000000cbbf86440000000000cbbf81a40000000000cbbf9c180000000000cbbfa15c0000000000cb3fa0080000000000cbbf95b40000000000cb3fb1480000000000cb3fa5c00000000000cb3fb3140000000000cb3f7cb00000000000cbbf5c100000000000cbbfa83c0000000000cbbfa7180000000000cb3f719c0000000000cbbfa8680000000000cbbf56b00000000000cbbfa2700000000000cbbfb8700000000000cbbfc0900000000000cb3f61cc0000000000cbbf80c40000000000cbbf99880000000000cb3f7ac40000000000cb3fb1e00000000000cbbfa9240000000000cbbfa18c0000000000cbbfa7980000000000cbbf89880000000000cbbf62780000000000cbbfa3ec0000000000cbbf9c980000000000cbbf90900000000000cb3f9cb00000000000cbbf98700000000000cb3f80740000000000cbbfa0380000000000cb3f6c740000000000cbbf99dc0000000000cbbfb1c40000000000cb3f3e040000000000cbbfa36c0000000000cbbfa4340000000000cb3f7fc00000000000cbbf93100000000000cbbf7d0c0000000000cbbf69500000000000cb3fa8b40000000000cb3f7f340000000000cb3fb7140000000000cb3f9c580000000000cbbf85940000000000cbbf50700000000000cbbfb0440000000000cbbf70100000000000cb3faaac0000000000cb3f89d00000000000cbbf91600000000000cbbfb6700000000000cbbfa8c40000000000cb3fa2000000000000cb3fa2a00000000000cb3faed80000000000cb3fa6180000000000cbbf91040000000000cbbf78180000000000cb3fb6c00000000000cb3f5d740000000000cbbfaa480000000000cbbf8f2c0000000000cb3fab500000000000cbbfa4cc0000000000cbbfac140000000000cbbfa83c0000000000cb3f9d000000000000cbbfac240000000000cb3fa89c0000000000cbbfb10c0000000000cbbf63cc0000000000cbbfa22c0000000000cb3f93d40000000000cb3f7f840000000000cb3fa2680000000000cb3f9f940000000000cb3fa8e40000000000cbbfaa380000000000cbbfab7c0000000000cb3f8de80000000000cbbfa9f00000000000cbbfa1f80000000000cb3fa6f00000000000cb3fc4d80000000000cb3fa5940000000000cb3fa7980000000000cb3f85b80000000000cb3fb71c0000000000cb3f9f8c0000000000cb3f8f440000000000cbbf9f1c0000000000cbbf94b40000000000cb3f97a80000000000cbbf853c0000000000cbbfa8780000000000cbbfb8e40000000000cbbfa4680000000000cbbfab340000000000cb3fad680000000000cb3fa64c0000000000cbbfadd00000000000cb3facf80000000000cbbfaa680000000000cbbfc1240000000000cbbfa2a00000000000cbbf97e80000000000cb3f9c300000000000cbbfa2000000000000cbbfaf480000000000cb3f93d80000000000cb3fb2cc0000000000cbbf73240000000000cbbfbd6c0000000000cbbf91200000000000cbbfa3dc0000000000cb3fb0180000000000cbbfc7d40000000000cb3f7e900000000000cbbf992c0000000000cbbf94340000000000cbbf76d00000000000cb3f95280000000000cb3fa2f40000000000cbbf82e00000000000cbbf8d980000000000cbbf87880000000000cb3f46400000000000cb3fc2fc0000000000cb3f96880000000000cbbfb9c40000000000cbbfbdd80000000000cbbf8ca80000000000cb3fb1ec0000000000cbbfa1ac0000000000cb3faaa00000000000cb3f932c0000000000cb3f99800000000000cb3fb2440000000000cb3fa53c0000000000cbbfaafc0000000000cb3f93300000000000cb3f7db40000000000cbbf9aa40000000000cbbf87200000000000cb3f723c0000000000cb3f88f40000000000cb3fad700000000000cb3f97580000000000cbbfb0d40000000000cb3f9a040000000000cbbfaf540000000000cbbfb1540000000000cb3fa9180000000000cbbfac600000000000cbbf98b00000000000cb3fa2500000000000cb3f9fc40000000000cbbfab000000000000cbbfb6940000000000cb3f9fc80000000000cb3fa5e00000000000cb3f95c00000000000cb3fb6b80000000000cbbf93680000000000cbbfa0180000000000cb3f84440000000000cbbfb7700000000000cbbfc4e40000000000cb3f94080000000000cbbf931c0000000000cbbfa0480000000000cb3fb1300000000000cbbf6fbc0000000000cb3fb2ec0000000000cbbf88280000000000cb3fb7a40000000000cbbfb0040000000000cbbfa85c0000000000cbbf82680000000000cb3f8b900000000000cb3fb0dc0000000000cbbf74680000000000cbbf48400000000000cbbfb9c00000000000cb3fb7f00000000000cb3f6f800000000000cbbf91040000000000cb3f8e200000000000cbbfb2100000000000cbbf94e00000000000cbbfb3b40000000000cbbf99440000000000cb3fa7b40000000000cb3fa8680000000000cb3fb4c80000000000cbbf97140000000000cbbf9aec0000000000cb3fb6440000000000cb3f9f4c0000000000cb3f78640000000000cbbfa19c0000000000cbbfa23c0000000000cbbf90040000000000cbbfa2340000000000cb3fbb900000000000cb3f73dc0000000000cbbfa5b40000000000cbbf8d500000000000cbbfa17c0000000000cb3f9d0c0000000000cb3f8a640000000000cbbfa2f80000000000cb3f6f700000000000cbbfa6b00000000000cbbfabe00000000000cbbf9c600000000000cbbfb7f00000000000cb3faa500000000000cbbf53240000000000cb3f9da00000000000cb3fa6740000000000cbbf712c0000000000cb3fac7c0000000000cb3fb3940000000000cbbfa68c0000000000cb3f91c40000000000cb3fa1900000000000cb3f9c1c0000000000cb3f64080000000000cbbfb5bc0000000000cb3faf900000000000cb3f962c0000000000cbbf947c0000000000cb3fbad00000000000cb3f6b000000000000cb3f9f780000000000cb3fa1780000000000cbbfa8080000000000cbbfac300000000000cb3f94800000000000cb3fa15c0000000000cbbfb1a80000000000cbbf66cc0000000000cb3fa0700000000000cbbfa6480000000000cb3fa06c0000000000cbbfb4640000000000cbbf97d80000000000cbbf96300000000000cb3fb53c0000000000cbbfa3100000000000cbbfb4440000000000cb3faa4c0000000000cb3fa7380000000000cb3fac800000000000cbbfa24c0000000000cb3f6f1c0000000000cbbfb8340000000000cbbf99d80000000000cb3f88e80000000000cb3fb0300000000000cbbf7a600000000000cb3fbbf00000000000cbbfa7700000000000cbbf6ab40000000000cbbfbb2c0000000000cbbf8b400000000000cbbfac080000000000cb3fb1f40000000000cb3fb7f00000000000cb3fba340000000000cb3f98880000000000cbbfb2680000000000cbbfb5980000000000cb3fa1a40000000000cbbfa6a80000000000cb3f9ac00000000000cb3fad840000000000cbbfb7b40000000000cb3f9f680000000000	~__pregel_pull, parallel_init
test-compound-1-5774cb33		1f14ba41-a306-6e4e-8000-33ba300e82de	8dae2b6e-b57f-fa54-f4c0-beaef43fac3d	4	embedding_done	msgpack	\\xc3	~__pregel_pull, parallel_init
test-compound-1-5774cb33		1f14ba41-a306-6e4e-8000-33ba300e82de	8dae2b6e-b57f-fa54-f4c0-beaef43fac3d	5	conversation_history	msgpack	\\x90	~__pregel_pull, parallel_init
test-compound-1-5774cb33		1f14ba41-a306-6e4e-8000-33ba300e82de	8dae2b6e-b57f-fa54-f4c0-beaef43fac3d	6	conversation_summary	msgpack	\\xa0	~__pregel_pull, parallel_init
test-compound-1-5774cb33		1f14ba41-a306-6e4e-8000-33ba300e82de	8dae2b6e-b57f-fa54-f4c0-beaef43fac3d	7	history_token_usage	msgpack	\\x00	~__pregel_pull, parallel_init
test-compound-1-5774cb33		1f14ba41-a306-6e4e-8000-33ba300e82de	8dae2b6e-b57f-fa54-f4c0-beaef43fac3d	8	cache_hit	msgpack	\\xc2	~__pregel_pull, parallel_init
test-compound-1-5774cb33		1f14ba41-a306-6e4e-8000-33ba300e82de	8dae2b6e-b57f-fa54-f4c0-beaef43fac3d	9	l1_checked	msgpack	\\xc3	~__pregel_pull, parallel_init
test-compound-1-5774cb33		1f14ba41-a306-6e4e-8000-33ba300e82de	8dae2b6e-b57f-fa54-f4c0-beaef43fac3d	10	decision_trace	msgpack	\\x9183a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40e5721ccccccccda76f7574636f6d65a773756363657373	~__pregel_pull, parallel_init
test-compound-1-5774cb33		1f14ba41-a306-6e4e-8000-33ba300e82de	8dae2b6e-b57f-fa54-f4c0-beaef43fac3d	11	branch:to:supervisor_intent	null	\\x	~__pregel_pull, parallel_init
test-compound-1-5774cb33		1f14ba43-45e7-6478-8001-cd896f58a5b8	4483dc6d-09ff-d512-4827-2e19e7af2b4f	2	intent_confidence	msgpack	\\xcb3fe999999999999a	~__pregel_pull, supervisor_intent
test-compound-1-5774cb33		1f14ba43-45e7-6478-8001-cd896f58a5b8	4483dc6d-09ff-d512-4827-2e19e7af2b4f	3	detected_domains	msgpack	\\x92a24852a353514c	~__pregel_pull, supervisor_intent
test-compound-1-5774cb33		1f14ba43-45e7-6478-8001-cd896f58a5b8	4483dc6d-09ff-d512-4827-2e19e7af2b4f	4	decision_trace	msgpack	\\x9283a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40e5721ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40e548a666666666a76f7574636f6d65a773756363657373	~__pregel_pull, supervisor_intent
test-compound-1-5774cb33		1f14ba43-45e7-6478-8001-cd896f58a5b8	4483dc6d-09ff-d512-4827-2e19e7af2b4f	5	branch:to:compound_parallel	null	\\x	~__pregel_pull, supervisor_intent
test-compound-1-5774cb33		1f14ba44-e59e-6078-8002-5c7d4fa4f0ea	d530623c-4e0f-216a-4c53-a9e2e4a53579	0	messages	msgpack	\\x90	~__pregel_pull, compound_parallel
test-compound-1-5774cb33		1f14ba44-e59e-6078-8002-5c7d4fa4f0ea	d530623c-4e0f-216a-4c53-a9e2e4a53579	1	rag_answer	msgpack	\\xa0	~__pregel_pull, compound_parallel
test-compound-1-5774cb33		1f14ba44-e59e-6078-8002-5c7d4fa4f0ea	d530623c-4e0f-216a-4c53-a9e2e4a53579	2	sql_explanation	msgpack	\\xa0	~__pregel_pull, compound_parallel
test-compound-1-5774cb33		1f14ba44-e59e-6078-8002-5c7d4fa4f0ea	d530623c-4e0f-216a-4c53-a9e2e4a53579	3	decision_trace	msgpack	\\x9383a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40e5721ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40e548a666666666a76f7574636f6d65a77375636365737383a46e6f6465b1636f6d706f756e645f706172616c6c656caa6c6174656e63795f6d73cb410039119999999aa76f7574636f6d65a773756363657373	~__pregel_pull, compound_parallel
test-compound-1-5774cb33		1f14ba44-e59e-6078-8002-5c7d4fa4f0ea	d530623c-4e0f-216a-4c53-a9e2e4a53579	4	branch:to:supervisor_merge	null	\\x	~__pregel_pull, compound_parallel
test-compound-1-5774cb33		1f14ba49-d90a-6a81-8003-2d9f8462c21f	d2e99041-4367-f193-f83f-a868f9cf6584	0	messages	msgpack	\\x90	~__pregel_pull, supervisor_merge
test-compound-1-5774cb33		1f14ba49-d90a-6a81-8003-2d9f8462c21f	d2e99041-4367-f193-f83f-a868f9cf6584	1	final_answer	msgpack	\\xbd4e6f20726573756c74732066726f6d20616e7920706970656c696e652e	~__pregel_pull, supervisor_merge
test-compound-1-5774cb33		1f14ba49-d90a-6a81-8003-2d9f8462c21f	d2e99041-4367-f193-f83f-a868f9cf6584	2	status	msgpack	\\xa9636f6d706c65746564	~__pregel_pull, supervisor_merge
test-compound-1-5774cb33		1f14ba49-d90a-6a81-8003-2d9f8462c21f	d2e99041-4367-f193-f83f-a868f9cf6584	3	decision_trace	msgpack	\\x9483a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40e5721ccccccccda76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40e548a666666666a76f7574636f6d65a77375636365737383a46e6f6465b1636f6d706f756e645f706172616c6c656caa6c6174656e63795f6d73cb410039119999999aa76f7574636f6d65a77375636365737383a46e6f6465b073757065727669736f725f6d65726765aa6c6174656e63795f6d73cb0000000000000000a76f7574636f6d65a773756363657373	~__pregel_pull, supervisor_merge
test-compound-2-b99bb20f		1f14ba4f-957e-6029-bfff-591b3ebe7b22	d1905ccd-0c8f-dfb3-6147-952a82080b13	0	messages	msgpack	\\x90	~__pregel_pull, __start__
test-compound-2-b99bb20f		1f14ba4f-957e-6029-bfff-591b3ebe7b22	d1905ccd-0c8f-dfb3-6147-952a82080b13	1	original_query	msgpack	\\xd9405768617420697320746865206c6561766520706f6c69637920616e642073686f77206d6520746f74616c2070726f64756374732062792063617465676f72793f	~__pregel_pull, __start__
test-compound-2-b99bb20f		1f14ba4f-957e-6029-bfff-591b3ebe7b22	d1905ccd-0c8f-dfb3-6147-952a82080b13	2	session_id	msgpack	\\xaf746573742d636f6d706f756e642d32	~__pregel_pull, __start__
test-compound-2-b99bb20f		1f14ba4f-957e-6029-bfff-591b3ebe7b22	d1905ccd-0c8f-dfb3-6147-952a82080b13	3	require_approval	msgpack	\\xc2	~__pregel_pull, __start__
test-compound-2-b99bb20f		1f14ba4f-957e-6029-bfff-591b3ebe7b22	d1905ccd-0c8f-dfb3-6147-952a82080b13	4	status	msgpack	\\xaa70726f63657373696e67	~__pregel_pull, __start__
test-compound-2-b99bb20f		1f14ba4f-957e-6029-bfff-591b3ebe7b22	d1905ccd-0c8f-dfb3-6147-952a82080b13	5	intent	msgpack	\\xa0	~__pregel_pull, __start__
test-compound-2-b99bb20f		1f14ba4f-957e-6029-bfff-591b3ebe7b22	d1905ccd-0c8f-dfb3-6147-952a82080b13	6	retry_count	msgpack	\\x00	~__pregel_pull, __start__
test-compound-2-b99bb20f		1f14ba4f-957e-6029-bfff-591b3ebe7b22	d1905ccd-0c8f-dfb3-6147-952a82080b13	7	react_steps	msgpack	\\x90	~__pregel_pull, __start__
test-compound-2-b99bb20f		1f14ba4f-957e-6029-bfff-591b3ebe7b22	d1905ccd-0c8f-dfb3-6147-952a82080b13	8	pending_tool_call	msgpack	\\x80	~__pregel_pull, __start__
test-compound-2-b99bb20f		1f14ba4f-957e-6029-bfff-591b3ebe7b22	d1905ccd-0c8f-dfb3-6147-952a82080b13	9	decision_trace	msgpack	\\x90	~__pregel_pull, __start__
test-compound-2-b99bb20f		1f14ba4f-957e-6029-bfff-591b3ebe7b22	d1905ccd-0c8f-dfb3-6147-952a82080b13	10	detected_domains	msgpack	\\x90	~__pregel_pull, __start__
test-compound-2-b99bb20f		1f14ba4f-957e-6029-bfff-591b3ebe7b22	d1905ccd-0c8f-dfb3-6147-952a82080b13	11	branch:to:parallel_init	null	\\x	~__pregel_pull, __start__
test-compound-2-b99bb20f		1f14ba4f-9586-6caa-8000-7fd4d3dfa28c	2eb822ed-8d42-4fe4-ae44-48f4358fb085	0	messages	msgpack	\\x90	~__pregel_pull, parallel_init
test-compound-2-b99bb20f		1f14ba4f-9586-6caa-8000-7fd4d3dfa28c	2eb822ed-8d42-4fe4-ae44-48f4358fb085	1	input_guard_passed	msgpack	\\xc3	~__pregel_pull, parallel_init
test-compound-2-b99bb20f		1f14ba4f-9586-6caa-8000-7fd4d3dfa28c	2eb822ed-8d42-4fe4-ae44-48f4358fb085	2	guard_issues	msgpack	\\x90	~__pregel_pull, parallel_init
test-compound-2-b99bb20f		1f14ba4f-9586-6caa-8000-7fd4d3dfa28c	2eb822ed-8d42-4fe4-ae44-48f4358fb085	3	query_embedding	msgpack	\\xdc0180cbbf8d8c0000000000cbbf97340000000000cb3f82680000000000cbbf72e00000000000cb3f7c3c0000000000cbbfb6740000000000cbbfb0040000000000cb3fa3f80000000000cb3f9ff00000000000cb3f90540000000000cbbfaa540000000000cbbf902c0000000000cbbf91080000000000cbbf9c480000000000cb3fa5740000000000cbbfc0680000000000cbbfb5980000000000cbbfb28c0000000000cbbf8c2c0000000000cbbf92e00000000000cbbfb30c0000000000cbbf66f00000000000cb3f91940000000000cbbfa5780000000000cb3f92a00000000000cb3f9c2c0000000000cbbfb20c0000000000cbbf8db80000000000cb3fa6c40000000000cbbf93b00000000000cbbf9aa80000000000cb3fa7180000000000cb3fa2640000000000cb3f8c4c0000000000cb3fa8280000000000cbbfb1c40000000000cb3f95380000000000cb3fa9100000000000cbbfb5040000000000cb3f4e580000000000cbbfa8440000000000cbbf815c0000000000cb3f91a00000000000cb3fac040000000000cbbfb2680000000000cb3fb38c0000000000cb3fb0200000000000cbbf9cc00000000000cb3f849c0000000000cbbf93b40000000000cb3f91180000000000cbbfae240000000000cbbf8b880000000000cbbf8bac0000000000cbbfab280000000000cb3fa0540000000000cbbf9b5c0000000000cbbfa7840000000000cb3f9c2c0000000000cbbfb79c0000000000cbbfb0180000000000cbbfc4fc0000000000cb3fbc900000000000cbbf93400000000000cbbf937c0000000000cbbfab780000000000cbbf90140000000000cbbfb1180000000000cb3f751c0000000000cb3f9e380000000000cb3fb41c0000000000cb3fae840000000000cbbfa31c0000000000cbbfa7fc0000000000cbbf85800000000000cb3f6ea40000000000cb3faf9c0000000000cbbfa2500000000000cb3fa91c0000000000cbbf78a40000000000cbbf9e440000000000cb3fbb140000000000cb3f8e380000000000cb3f6e600000000000cb3f87200000000000cb3f77200000000000cbbfa1700000000000cb3fa5500000000000cb3faa140000000000cbbfba940000000000cb3f75180000000000cbbfb1300000000000cbbfb1d40000000000cbbfb0ac0000000000cbbf92980000000000cb3fb2880000000000cb3f72400000000000cbbfaac40000000000cbbfa9000000000000cbbfa1a40000000000cbbf8b5c0000000000cb3facf00000000000cbbfa0680000000000cb3f6cf00000000000cb3f92100000000000cbbfa4880000000000cb3f8a2c0000000000cb3f6df00000000000cb3f75480000000000cbbfa8b00000000000cbbfa3ec0000000000cbbf97200000000000cb3fa89c0000000000cb3f65680000000000cbbfb5ac0000000000cbbfbcf80000000000cb3fa1480000000000cbbf8b600000000000cbbf90bc0000000000cbbf70040000000000cb3fb9fc0000000000cbbfbb540000000000cbbface40000000000cb3f89b00000000000cb3f65540000000000cb3fa2900000000000cb3f72bc0000000000cbbf70800000000000cb3fa7000000000000cbbf87d40000000000cbbfa8bc0000000000cb3f73780000000000cbbfa4f80000000000cb3f764c0000000000cbbf93180000000000cbbfbb040000000000cbbfa7840000000000cb3fb1c80000000000cbbfb3080000000000cb3fb4b80000000000cbbfb14c0000000000cbbfa3900000000000cb3f9b140000000000cbbf93980000000000cb3f78f00000000000cb3fb4400000000000cbbf90100000000000cb3f89440000000000cbbf9b640000000000cbbfafa00000000000cbbfa98c0000000000cb3fb4c80000000000cbbf99e80000000000cb3fa1000000000000cbbfbeb80000000000cb3fa0d40000000000cb3fa6140000000000cbbf5bec0000000000cb3f9de40000000000cbbf7f300000000000cbbf9d780000000000cb3fa6d00000000000cb3fb1a80000000000cb3f79d80000000000cbbf5a780000000000cbbf9bd40000000000cb3fb21c0000000000cbbf95440000000000cbbfa2440000000000cb3fa4c80000000000cb3f96ec0000000000cbbf97b00000000000cb3fb02c0000000000cbbfa5500000000000cb3fb60c0000000000cbbfb6340000000000cbbfa3900000000000cb3fa26c0000000000cbbf9bec0000000000cb3f82ac0000000000cb3fc0e80000000000cbbfb4900000000000cbbfb4940000000000cb3f92040000000000cbbfa5480000000000cbbfaa740000000000cb3f93d40000000000cb3fbb540000000000cb3fa3c80000000000cb3f9a200000000000cbbfa5a40000000000cb3f95ec0000000000cb3fb5d40000000000cb3fa5c40000000000cbbfb4c40000000000cbbfbbe40000000000cbbfb3cc0000000000cbbfbb8c0000000000cb3f95d00000000000cbbfb2100000000000cbbf8e940000000000cbbf9c180000000000cb3f9e000000000000cbbf9a900000000000cbbf9b480000000000cb3fa8d80000000000cbbfa9a40000000000cbbfbadc0000000000cbbf9a100000000000cbbfa0a40000000000cbbfa9680000000000cbbed5400000000000cbbfb54c0000000000cb3f865c0000000000cb3f99dc0000000000cb3fb2d00000000000cbbfbd000000000000cbbfa87c0000000000cb3fa2ac0000000000cb3fa6fc0000000000cbbfbabc0000000000cb3fa4bc0000000000cb3f7b4c0000000000cbbfb1dc0000000000cb3f76900000000000cbbf89b00000000000cbbfa0e80000000000cbbfb3380000000000cb3f93580000000000cbbf72880000000000cbbf87780000000000cb3fb5480000000000cb3fb5140000000000cb3fa42c0000000000cbbfc2740000000000cb3f9f1c0000000000cb3fbbbc0000000000cb3fa1d40000000000cb3fa07c0000000000cbbfa3840000000000cb3fb3180000000000cb3f803c0000000000cb3f6ad00000000000cbbfa18c0000000000cb3f9a340000000000cb3fa2e80000000000cbbf91600000000000cb3f8d8c0000000000cbbf9a540000000000cbbf98580000000000cbbf74940000000000cb3fa9bc0000000000cb3fb0780000000000cbbfa5240000000000cbbfad880000000000cb3f97600000000000cbbf41240000000000cbbfa9440000000000cbbf66cc0000000000cbbf9dfc0000000000cb3fa5e40000000000cbbfa7fc0000000000cbbfbd400000000000cbbf93480000000000cb3f931c0000000000cb3fae140000000000cb3faee40000000000cbbfb23c0000000000cbbfb4800000000000cb3fa4d80000000000cbbfbc2c0000000000cbbfbbf40000000000cb3fac4c0000000000cbbf9cc40000000000cbbfb0240000000000cb3fb5940000000000cb3f86c80000000000cb3fb5380000000000cb3f89cc0000000000cb3fa4400000000000cbbf9c540000000000cb3f7fa80000000000cb3f9d0c0000000000cb3f9cc40000000000cb3fb16c0000000000cb3f81080000000000cbbfa30c0000000000cbbfb6000000000000cb3fa79c0000000000cb3f73b00000000000cb3f849c0000000000cb3fab0c0000000000cbbf97c40000000000cb3f88980000000000cbbf8a900000000000cbbf5e040000000000cbbf95c40000000000cb3fa0800000000000cb3fb1a40000000000cb3fa8600000000000cb3f57c40000000000cb3f95e00000000000cb3f937c0000000000cbbfa6280000000000cb3f5d680000000000cbbf51580000000000cb3f8d900000000000cbbfa40c0000000000cb3fb7500000000000cbbf915c0000000000cbbf71400000000000cb3f94f00000000000cbbf96280000000000cb3f8b740000000000cbbfa0d00000000000cbbfadb40000000000cb3f70940000000000cbbf9fa80000000000cb3f92300000000000cb3f93940000000000cbbfa24c0000000000cb3fa4d40000000000cbbfa1ec0000000000cbbfa2d00000000000cb3fb0900000000000cb3f5bc00000000000cbbf7c580000000000cb3faffc0000000000cbbfb8440000000000cb3f86300000000000cb3f8b900000000000cb3fa0280000000000cb3f72c00000000000cbbf9bac0000000000cb3f94740000000000cb3f87e80000000000cb3f18b00000000000cb3fb49c0000000000cb3f9da00000000000cbbf848c0000000000cbbf94f00000000000cb3f63140000000000cbbf941c0000000000cb3f65ec0000000000cb3f59a80000000000cbbfa8240000000000cbbf90100000000000cb3fb13c0000000000cb3f9b200000000000cb3faa780000000000cbbf99fc0000000000cb3f9afc0000000000cbbf96180000000000cb3fbd4c0000000000cbbfa4880000000000cbbfa97c0000000000cb3fa8c80000000000cb3fa0d80000000000cb3f51fc0000000000cbbfa0400000000000cbbfa6ec0000000000cbbf9bdc0000000000cbbfa50c0000000000cb3f9db80000000000cb3f85bc0000000000cb3f7d8c0000000000cb3fbcb80000000000cbbfaa240000000000cbbfb4680000000000cbbfbca00000000000cb3fa9340000000000cbbfa3d00000000000cb3fb07c0000000000cb3fbca00000000000cb3f88940000000000cb3fb3040000000000cbbfa5a80000000000cbbfb3d00000000000cbbf82500000000000cb3f89c80000000000cb3f76140000000000cb3fb2c00000000000cbbfbd880000000000cb3f94d00000000000	~__pregel_pull, parallel_init
test-compound-2-b99bb20f		1f14ba4f-9586-6caa-8000-7fd4d3dfa28c	2eb822ed-8d42-4fe4-ae44-48f4358fb085	4	embedding_done	msgpack	\\xc3	~__pregel_pull, parallel_init
test-compound-2-b99bb20f		1f14ba4f-9586-6caa-8000-7fd4d3dfa28c	2eb822ed-8d42-4fe4-ae44-48f4358fb085	5	conversation_history	msgpack	\\x90	~__pregel_pull, parallel_init
test-compound-2-b99bb20f		1f14ba4f-9586-6caa-8000-7fd4d3dfa28c	2eb822ed-8d42-4fe4-ae44-48f4358fb085	6	conversation_summary	msgpack	\\xa0	~__pregel_pull, parallel_init
test-compound-2-b99bb20f		1f14ba4f-9586-6caa-8000-7fd4d3dfa28c	2eb822ed-8d42-4fe4-ae44-48f4358fb085	7	history_token_usage	msgpack	\\x00	~__pregel_pull, parallel_init
test-compound-2-b99bb20f		1f14ba4f-9586-6caa-8000-7fd4d3dfa28c	2eb822ed-8d42-4fe4-ae44-48f4358fb085	8	cache_hit	msgpack	\\xc2	~__pregel_pull, parallel_init
test-compound-2-b99bb20f		1f14ba4f-9586-6caa-8000-7fd4d3dfa28c	2eb822ed-8d42-4fe4-ae44-48f4358fb085	9	l1_checked	msgpack	\\xc3	~__pregel_pull, parallel_init
test-compound-2-b99bb20f		1f14ba4f-9586-6caa-8000-7fd4d3dfa28c	2eb822ed-8d42-4fe4-ae44-48f4358fb085	10	decision_trace	msgpack	\\x9183a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40d670a000000000a76f7574636f6d65a773756363657373	~__pregel_pull, parallel_init
test-compound-2-b99bb20f		1f14ba4f-9586-6caa-8000-7fd4d3dfa28c	2eb822ed-8d42-4fe4-ae44-48f4358fb085	11	branch:to:supervisor_intent	null	\\x	~__pregel_pull, parallel_init
test-compound-2-b99bb20f		1f14ba50-70b1-6f8f-8001-b7aa1bd4f30d	38001e3a-1b85-826f-314e-9f2ce05232f4	0	messages	msgpack	\\x90	~__pregel_pull, supervisor_intent
test-compound-2-b99bb20f		1f14ba50-70b1-6f8f-8001-b7aa1bd4f30d	38001e3a-1b85-826f-314e-9f2ce05232f4	1	intent	msgpack	\\xa8636f6d706f756e64	~__pregel_pull, supervisor_intent
test-compound-2-b99bb20f		1f14ba50-70b1-6f8f-8001-b7aa1bd4f30d	38001e3a-1b85-826f-314e-9f2ce05232f4	2	intent_confidence	msgpack	\\xcb3fe999999999999a	~__pregel_pull, supervisor_intent
test-compound-2-b99bb20f		1f14ba50-70b1-6f8f-8001-b7aa1bd4f30d	38001e3a-1b85-826f-314e-9f2ce05232f4	3	detected_domains	msgpack	\\x92a24852a353514c	~__pregel_pull, supervisor_intent
test-compound-2-b99bb20f		1f14ba50-70b1-6f8f-8001-b7aa1bd4f30d	38001e3a-1b85-826f-314e-9f2ce05232f4	4	decision_trace	msgpack	\\x9283a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40d670a000000000a76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40e5423000000000a76f7574636f6d65a773756363657373	~__pregel_pull, supervisor_intent
test-compound-2-b99bb20f		1f14ba50-70b1-6f8f-8001-b7aa1bd4f30d	38001e3a-1b85-826f-314e-9f2ce05232f4	5	branch:to:compound_parallel	null	\\x	~__pregel_pull, supervisor_intent
test-compound-2-b99bb20f		1f14ba52-0fe9-6412-8002-3f968c9529f4	240b909e-6590-21e6-4831-b379472310ae	0	messages	msgpack	\\x90	~__pregel_pull, compound_parallel
test-compound-2-b99bb20f		1f14ba52-0fe9-6412-8002-3f968c9529f4	240b909e-6590-21e6-4831-b379472310ae	1	rag_answer	msgpack	\\xd94e4920646f6e2774206861766520656e6f75676820696e666f726d6174696f6e20696e20746865206b6e6f776c65646765206261736520746f20616e737765722074686973207175657374696f6e2e	~__pregel_pull, compound_parallel
test-compound-2-b99bb20f		1f14ba52-0fe9-6412-8002-3f968c9529f4	240b909e-6590-21e6-4831-b379472310ae	2	rag_confidence	msgpack	\\xa34c4f57	~__pregel_pull, compound_parallel
test-compound-2-b99bb20f		1f14ba52-0fe9-6412-8002-3f968c9529f4	240b909e-6590-21e6-4831-b379472310ae	3	rag_sources	msgpack	\\x90	~__pregel_pull, compound_parallel
test-compound-2-b99bb20f		1f14ba52-0fe9-6412-8002-3f968c9529f4	240b909e-6590-21e6-4831-b379472310ae	4	sql_explanation	msgpack	\\xda0136486572652773206120636f6e63697365206578706c616e6174696f6e206f66207468652053514c20726573756c74733a0a0a54686520746f7020352063617465676f72696573207769746820746865206d6f73742070726f64756374732061726520456c656374726f6e6963732c204675726e69747572652c205361666574792045717569706d656e742c205061636b6167696e672c20616e6420466f6f6420262042657665726167652c207769746820456c656374726f6e69637320686176696e6720746865206d6f73742070726f647563747320617420332e20546869732073756767657374732074686174207468652077617265686f757365206861732061207374726f6e6720666f637573206f6e20656c656374726f6e69637320616e64206675726e69747572652070726f64756374732e	~__pregel_pull, compound_parallel
test-compound-2-b99bb20f		1f14ba52-0fe9-6412-8002-3f968c9529f4	240b909e-6590-21e6-4831-b379472310ae	5	generated_sql	msgpack	\\xd9ac53454c4543542063617465676f72792e6e616d652c20434f554e542870726f647563742e6964292046524f4d2063617465676f7279204c454654204a4f494e2070726f64756374204f4e2063617465676f72792e6964203d2070726f647563742e63617465676f72795f69642047524f55502042592063617465676f72792e6e616d65204f5244455220425920434f554e542870726f647563742e6964292044455343204c494d4954203530	~__pregel_pull, compound_parallel
test-compound-2-b99bb20f		1f14ba52-0fe9-6412-8002-3f968c9529f4	240b909e-6590-21e6-4831-b379472310ae	6	sql_results	msgpack	\\x9582a46e616d65ab456c656374726f6e696373a5636f756e740382a46e616d65a94675726e6974757265a5636f756e740282a46e616d65b05361666574792045717569706d656e74a5636f756e740282a46e616d65a95061636b6167696e67a5636f756e740282a46e616d65af466f6f642026204265766572616765a5636f756e7401	~__pregel_pull, compound_parallel
test-compound-2-b99bb20f		1f14ba52-0fe9-6412-8002-3f968c9529f4	240b909e-6590-21e6-4831-b379472310ae	7	decision_trace	msgpack	\\x9383a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40d670a000000000a76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40e5423000000000a76f7574636f6d65a77375636365737383a46e6f6465b1636f6d706f756e645f706172616c6c656caa6c6174656e63795f6d73cb41058a48cccccccda76f7574636f6d65a773756363657373	~__pregel_pull, compound_parallel
test-compound-2-b99bb20f		1f14ba52-0fe9-6412-8002-3f968c9529f4	240b909e-6590-21e6-4831-b379472310ae	8	branch:to:supervisor_merge	null	\\x	~__pregel_pull, compound_parallel
test-compound-2-b99bb20f		1f14ba58-a2bf-63a8-8003-fa65909d5956	96ba9d32-e076-3353-bec7-b7e49859113f	0	messages	msgpack	\\x90	~__pregel_pull, supervisor_merge
test-compound-2-b99bb20f		1f14ba58-a2bf-63a8-8003-fa65909d5956	96ba9d32-e076-3353-bec7-b7e49859113f	1	final_answer	msgpack	\\xda01ec556e666f7274756e6174656c792c204920646f6e2774206861766520656e6f75676820696e666f726d6174696f6e20696e20746865206b6e6f776c65646765206261736520746f2070726f76696465206120636f6d70726568656e7369766520616e7377657220746f20796f7572207175657374696f6e2e20486f77657665722c20492063616e2070726f7669646520736f6d65206164646974696f6e616c20636f6e74657874206261736564206f6e20612064617461626173652071756572792e0a0a4163636f7264696e6720746f207468652064617461626173652c2074686520746f7020352063617465676f72696573207769746820746865206d6f73742070726f647563747320696e207468652077617265686f7573652061726520456c656374726f6e6963732c204675726e69747572652c205361666574792045717569706d656e742c205061636b6167696e672c20616e6420466f6f6420262042657665726167652e204e6f7461626c792c20456c656374726f6e6963732068617320746865206d6f73742070726f647563747320617420332c20696e6469636174696e672061207374726f6e6720666f637573206f6e20656c656374726f6e69637320616e64206675726e69747572652070726f647563747320696e207468652077617265686f7573652e	~__pregel_pull, supervisor_merge
test-compound-2-b99bb20f		1f14ba58-a2bf-63a8-8003-fa65909d5956	96ba9d32-e076-3353-bec7-b7e49859113f	2	status	msgpack	\\xa9636f6d706c65746564	~__pregel_pull, supervisor_merge
test-compound-2-b99bb20f		1f14ba58-a2bf-63a8-8003-fa65909d5956	96ba9d32-e076-3353-bec7-b7e49859113f	3	decision_trace	msgpack	\\x9483a46e6f6465ad706172616c6c656c5f696e6974aa6c6174656e63795f6d73cb40d670a000000000a76f7574636f6d65a77375636365737383a46e6f6465b173757065727669736f725f696e74656e74aa6c6174656e63795f6d73cb40e5423000000000a76f7574636f6d65a77375636365737383a46e6f6465b1636f6d706f756e645f706172616c6c656caa6c6174656e63795f6d73cb41058a48cccccccda76f7574636f6d65a77375636365737383a46e6f6465b073757065727669736f725f6d65726765aa6c6174656e63795f6d73cb40e559c99999999aa76f7574636f6d65a773756363657373	~__pregel_pull, supervisor_merge
\.


--
-- Data for Name: checkpoints; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.checkpoints (thread_id, checkpoint_ns, checkpoint_id, parent_checkpoint_id, type, checkpoint, metadata) FROM stdin;
test-rag-1-4de275a7		1f14ba2b-cac7-638b-bfff-d17effbe9c6e	\N	\N	{"v": 4, "id": "1f14ba2b-cac7-638b-bfff-d17effbe9c6e", "ts": "2026-05-09T12:29:34.739956+00:00", "versions_seen": {"__input__": {}}, "channel_values": {}, "channel_versions": {"__start__": "00000000000000000000000000000001.0.20624731437029808"}, "updated_channels": ["__start__"]}	{"step": -1, "source": "input", "parents": {}}
test-rag-1-4de275a7		1f14ba2b-cad1-6048-8000-f6f1b8dc8fec	1f14ba2b-cac7-638b-bfff-d17effbe9c6e	\N	{"v": 4, "id": "1f14ba2b-cad1-6048-8000-f6f1b8dc8fec", "ts": "2026-05-09T12:29:34.743968+00:00", "versions_seen": {"__input__": {}, "__start__": {"__start__": "00000000000000000000000000000001.0.20624731437029808"}}, "channel_values": {"intent": "", "status": "processing", "session_id": "test-rag-1", "retry_count": 0, "original_query": "What is the annual leave policy?", "require_approval": false, "branch:to:parallel_init": null}, "channel_versions": {"intent": "00000000000000000000000000000002.0.3186759760044504", "status": "00000000000000000000000000000002.0.3186759760044504", "messages": "00000000000000000000000000000002.0.3186759760044504", "__start__": "00000000000000000000000000000002.0.3186759760044504", "session_id": "00000000000000000000000000000002.0.3186759760044504", "react_steps": "00000000000000000000000000000002.0.3186759760044504", "retry_count": "00000000000000000000000000000002.0.3186759760044504", "decision_trace": "00000000000000000000000000000002.0.3186759760044504", "original_query": "00000000000000000000000000000002.0.3186759760044504", "detected_domains": "00000000000000000000000000000002.0.3186759760044504", "require_approval": "00000000000000000000000000000002.0.3186759760044504", "pending_tool_call": "00000000000000000000000000000002.0.3186759760044504", "branch:to:parallel_init": "00000000000000000000000000000002.0.3186759760044504"}, "updated_channels": ["branch:to:parallel_init", "decision_trace", "detected_domains", "intent", "messages", "original_query", "pending_tool_call", "react_steps", "require_approval", "retry_count", "session_id", "status"]}	{"step": 0, "source": "loop", "parents": {}}
test-rag-1-4de275a7		1f14ba2c-aaee-6a24-8001-4b89744fdc06	1f14ba2b-cad1-6048-8000-f6f1b8dc8fec	\N	{"v": 4, "id": "1f14ba2c-aaee-6a24-8001-4b89744fdc06", "ts": "2026-05-09T12:29:58.244202+00:00", "versions_seen": {"__input__": {}, "__start__": {"__start__": "00000000000000000000000000000001.0.20624731437029808"}, "parallel_init": {"branch:to:parallel_init": "00000000000000000000000000000002.0.3186759760044504"}}, "channel_values": {"intent": "", "status": "processing", "cache_hit": false, "l1_checked": true, "session_id": "test-rag-1", "retry_count": 0, "embedding_done": true, "original_query": "What is the annual leave policy?", "require_approval": false, "input_guard_passed": true, "history_token_usage": 0, "conversation_summary": "", "branch:to:supervisor_intent": null}, "channel_versions": {"intent": "00000000000000000000000000000002.0.3186759760044504", "status": "00000000000000000000000000000002.0.3186759760044504", "messages": "00000000000000000000000000000003.0.17773581668485716", "__start__": "00000000000000000000000000000002.0.3186759760044504", "cache_hit": "00000000000000000000000000000003.0.17773581668485716", "l1_checked": "00000000000000000000000000000003.0.17773581668485716", "session_id": "00000000000000000000000000000002.0.3186759760044504", "react_steps": "00000000000000000000000000000002.0.3186759760044504", "retry_count": "00000000000000000000000000000002.0.3186759760044504", "guard_issues": "00000000000000000000000000000003.0.17773581668485716", "decision_trace": "00000000000000000000000000000003.0.17773581668485716", "embedding_done": "00000000000000000000000000000003.0.17773581668485716", "original_query": "00000000000000000000000000000002.0.3186759760044504", "query_embedding": "00000000000000000000000000000003.0.17773581668485716", "detected_domains": "00000000000000000000000000000002.0.3186759760044504", "require_approval": "00000000000000000000000000000002.0.3186759760044504", "pending_tool_call": "00000000000000000000000000000002.0.3186759760044504", "input_guard_passed": "00000000000000000000000000000003.0.17773581668485716", "history_token_usage": "00000000000000000000000000000003.0.17773581668485716", "conversation_history": "00000000000000000000000000000003.0.17773581668485716", "conversation_summary": "00000000000000000000000000000003.0.17773581668485716", "branch:to:parallel_init": "00000000000000000000000000000003.0.17773581668485716", "branch:to:supervisor_intent": "00000000000000000000000000000003.0.17773581668485716"}, "updated_channels": ["branch:to:supervisor_intent", "cache_hit", "conversation_history", "conversation_summary", "decision_trace", "embedding_done", "guard_issues", "history_token_usage", "input_guard_passed", "l1_checked", "messages", "query_embedding"]}	{"step": 1, "source": "loop", "parents": {}}
test-rag-1-4de275a7		1f14ba2d-85c4-68f8-8002-89b6eaf0235a	1f14ba2c-aaee-6a24-8001-4b89744fdc06	\N	{"v": 4, "id": "1f14ba2d-85c4-68f8-8002-89b6eaf0235a", "ts": "2026-05-09T12:30:21.190783+00:00", "versions_seen": {"__input__": {}, "__start__": {"__start__": "00000000000000000000000000000001.0.20624731437029808"}, "parallel_init": {"branch:to:parallel_init": "00000000000000000000000000000002.0.3186759760044504"}, "supervisor_intent": {"branch:to:supervisor_intent": "00000000000000000000000000000003.0.17773581668485716"}}, "channel_values": {"intent": "rag", "status": "processing", "cache_hit": false, "l1_checked": true, "session_id": "test-rag-1", "retry_count": 0, "embedding_done": true, "original_query": "What is the annual leave policy?", "require_approval": false, "intent_confidence": 1.0, "input_guard_passed": true, "history_token_usage": 0, "conversation_summary": "", "branch:to:rag_domain_router": null}, "channel_versions": {"intent": "00000000000000000000000000000004.0.9213189263534638", "status": "00000000000000000000000000000002.0.3186759760044504", "messages": "00000000000000000000000000000004.0.9213189263534638", "__start__": "00000000000000000000000000000002.0.3186759760044504", "cache_hit": "00000000000000000000000000000003.0.17773581668485716", "l1_checked": "00000000000000000000000000000003.0.17773581668485716", "session_id": "00000000000000000000000000000002.0.3186759760044504", "react_steps": "00000000000000000000000000000002.0.3186759760044504", "retry_count": "00000000000000000000000000000002.0.3186759760044504", "guard_issues": "00000000000000000000000000000003.0.17773581668485716", "decision_trace": "00000000000000000000000000000004.0.9213189263534638", "embedding_done": "00000000000000000000000000000003.0.17773581668485716", "original_query": "00000000000000000000000000000002.0.3186759760044504", "query_embedding": "00000000000000000000000000000003.0.17773581668485716", "detected_domains": "00000000000000000000000000000004.0.9213189263534638", "require_approval": "00000000000000000000000000000002.0.3186759760044504", "intent_confidence": "00000000000000000000000000000004.0.9213189263534638", "pending_tool_call": "00000000000000000000000000000002.0.3186759760044504", "input_guard_passed": "00000000000000000000000000000003.0.17773581668485716", "history_token_usage": "00000000000000000000000000000003.0.17773581668485716", "conversation_history": "00000000000000000000000000000003.0.17773581668485716", "conversation_summary": "00000000000000000000000000000003.0.17773581668485716", "branch:to:parallel_init": "00000000000000000000000000000003.0.17773581668485716", "branch:to:rag_domain_router": "00000000000000000000000000000004.0.9213189263534638", "branch:to:supervisor_intent": "00000000000000000000000000000004.0.9213189263534638"}, "updated_channels": ["branch:to:rag_domain_router", "decision_trace", "detected_domains", "intent", "intent_confidence", "messages"]}	{"step": 2, "source": "loop", "parents": {}}
test-rag-1-4de275a7		1f14ba2e-5f94-6337-8003-83a1b4ece8d7	1f14ba2d-85c4-68f8-8002-89b6eaf0235a	\N	{"v": 4, "id": "1f14ba2e-5f94-6337-8003-83a1b4ece8d7", "ts": "2026-05-09T12:30:44.029931+00:00", "versions_seen": {"__input__": {}, "__start__": {"__start__": "00000000000000000000000000000001.0.20624731437029808"}, "parallel_init": {"branch:to:parallel_init": "00000000000000000000000000000002.0.3186759760044504"}, "rag_domain_router": {"branch:to:rag_domain_router": "00000000000000000000000000000004.0.9213189263534638"}, "supervisor_intent": {"branch:to:supervisor_intent": "00000000000000000000000000000003.0.17773581668485716"}}, "channel_values": {"intent": "rag", "status": "processing", "cache_hit": false, "l1_checked": true, "rag_domain": "HR", "session_id": "test-rag-1", "retry_count": 0, "embedding_done": true, "original_query": "What is the annual leave policy?", "rag_sub_question": "Annual leave policy details", "require_approval": false, "intent_confidence": 1.0, "input_guard_passed": true, "history_token_usage": 0, "conversation_summary": "", "branch:to:rag_retrieval": null}, "channel_versions": {"intent": "00000000000000000000000000000004.0.9213189263534638", "status": "00000000000000000000000000000002.0.3186759760044504", "messages": "00000000000000000000000000000005.0.34103043054889604", "__start__": "00000000000000000000000000000002.0.3186759760044504", "cache_hit": "00000000000000000000000000000003.0.17773581668485716", "l1_checked": "00000000000000000000000000000003.0.17773581668485716", "rag_domain": "00000000000000000000000000000005.0.34103043054889604", "session_id": "00000000000000000000000000000002.0.3186759760044504", "react_steps": "00000000000000000000000000000002.0.3186759760044504", "retry_count": "00000000000000000000000000000002.0.3186759760044504", "guard_issues": "00000000000000000000000000000003.0.17773581668485716", "decision_trace": "00000000000000000000000000000005.0.34103043054889604", "embedding_done": "00000000000000000000000000000003.0.17773581668485716", "original_query": "00000000000000000000000000000002.0.3186759760044504", "query_embedding": "00000000000000000000000000000003.0.17773581668485716", "detected_domains": "00000000000000000000000000000004.0.9213189263534638", "rag_sub_question": "00000000000000000000000000000005.0.34103043054889604", "require_approval": "00000000000000000000000000000002.0.3186759760044504", "intent_confidence": "00000000000000000000000000000004.0.9213189263534638", "pending_tool_call": "00000000000000000000000000000002.0.3186759760044504", "input_guard_passed": "00000000000000000000000000000003.0.17773581668485716", "history_token_usage": "00000000000000000000000000000003.0.17773581668485716", "conversation_history": "00000000000000000000000000000003.0.17773581668485716", "conversation_summary": "00000000000000000000000000000003.0.17773581668485716", "branch:to:parallel_init": "00000000000000000000000000000003.0.17773581668485716", "branch:to:rag_retrieval": "00000000000000000000000000000005.0.34103043054889604", "branch:to:rag_domain_router": "00000000000000000000000000000005.0.34103043054889604", "branch:to:supervisor_intent": "00000000000000000000000000000004.0.9213189263534638"}, "updated_channels": ["branch:to:rag_retrieval", "decision_trace", "messages", "rag_domain", "rag_sub_question"]}	{"step": 3, "source": "loop", "parents": {}}
test-rag-1-4de275a7		1f14ba2e-6c80-6732-8004-9412859b4b80	1f14ba2e-5f94-6337-8003-83a1b4ece8d7	\N	{"v": 4, "id": "1f14ba2e-6c80-6732-8004-9412859b4b80", "ts": "2026-05-09T12:30:45.384990+00:00", "versions_seen": {"__input__": {}, "__start__": {"__start__": "00000000000000000000000000000001.0.20624731437029808"}, "parallel_init": {"branch:to:parallel_init": "00000000000000000000000000000002.0.3186759760044504"}, "rag_retrieval": {"branch:to:rag_retrieval": "00000000000000000000000000000005.0.34103043054889604"}, "rag_domain_router": {"branch:to:rag_domain_router": "00000000000000000000000000000004.0.9213189263534638"}, "supervisor_intent": {"branch:to:supervisor_intent": "00000000000000000000000000000003.0.17773581668485716"}}, "channel_values": {"intent": "rag", "status": "processing", "cache_hit": false, "l1_checked": true, "rag_domain": "HR", "session_id": "test-rag-1", "retry_count": 0, "embedding_done": true, "original_query": "What is the annual leave policy?", "rag_sub_question": "Annual leave policy details", "require_approval": false, "intent_confidence": 1.0, "input_guard_passed": true, "history_token_usage": 0, "conversation_summary": "", "branch:to:rag_generator": null}, "channel_versions": {"intent": "00000000000000000000000000000004.0.9213189263534638", "status": "00000000000000000000000000000002.0.3186759760044504", "messages": "00000000000000000000000000000006.0.6183653630713223", "__start__": "00000000000000000000000000000002.0.3186759760044504", "cache_hit": "00000000000000000000000000000003.0.17773581668485716", "l1_checked": "00000000000000000000000000000003.0.17773581668485716", "rag_domain": "00000000000000000000000000000005.0.34103043054889604", "session_id": "00000000000000000000000000000002.0.3186759760044504", "react_steps": "00000000000000000000000000000002.0.3186759760044504", "retry_count": "00000000000000000000000000000002.0.3186759760044504", "guard_issues": "00000000000000000000000000000003.0.17773581668485716", "decision_trace": "00000000000000000000000000000006.0.6183653630713223", "embedding_done": "00000000000000000000000000000003.0.17773581668485716", "original_query": "00000000000000000000000000000002.0.3186759760044504", "query_embedding": "00000000000000000000000000000003.0.17773581668485716", "detected_domains": "00000000000000000000000000000004.0.9213189263534638", "rag_sub_question": "00000000000000000000000000000005.0.34103043054889604", "require_approval": "00000000000000000000000000000002.0.3186759760044504", "intent_confidence": "00000000000000000000000000000004.0.9213189263534638", "pending_tool_call": "00000000000000000000000000000002.0.3186759760044504", "rag_fused_results": "00000000000000000000000000000006.0.6183653630713223", "input_guard_passed": "00000000000000000000000000000003.0.17773581668485716", "history_token_usage": "00000000000000000000000000000006.0.6183653630713223", "conversation_history": "00000000000000000000000000000006.0.6183653630713223", "conversation_summary": "00000000000000000000000000000006.0.6183653630713223", "branch:to:parallel_init": "00000000000000000000000000000003.0.17773581668485716", "branch:to:rag_generator": "00000000000000000000000000000006.0.6183653630713223", "branch:to:rag_retrieval": "00000000000000000000000000000006.0.6183653630713223", "branch:to:rag_domain_router": "00000000000000000000000000000005.0.34103043054889604", "branch:to:supervisor_intent": "00000000000000000000000000000004.0.9213189263534638"}, "updated_channels": ["branch:to:rag_generator", "conversation_history", "conversation_summary", "decision_trace", "history_token_usage", "messages", "rag_fused_results"]}	{"step": 4, "source": "loop", "parents": {}}
test-rag-1-4de275a7		1f14ba30-0e95-66cd-8005-2bd63be8c432	1f14ba2e-6c80-6732-8004-9412859b4b80	\N	{"v": 4, "id": "1f14ba30-0e95-66cd-8005-2bd63be8c432", "ts": "2026-05-09T12:31:29.224058+00:00", "versions_seen": {"__input__": {}, "__start__": {"__start__": "00000000000000000000000000000001.0.20624731437029808"}, "parallel_init": {"branch:to:parallel_init": "00000000000000000000000000000002.0.3186759760044504"}, "rag_generator": {"branch:to:rag_generator": "00000000000000000000000000000006.0.6183653630713223"}, "rag_retrieval": {"branch:to:rag_retrieval": "00000000000000000000000000000005.0.34103043054889604"}, "rag_domain_router": {"branch:to:rag_domain_router": "00000000000000000000000000000004.0.9213189263534638"}, "supervisor_intent": {"branch:to:supervisor_intent": "00000000000000000000000000000003.0.17773581668485716"}}, "channel_values": {"intent": "rag", "status": "processing", "cache_hit": false, "l1_checked": true, "rag_answer": "All full-time employees are entitled to 24 days of paid annual leave per calendar year, accrues at 2 days per month, and unused leave can be carried forward up to 5 days into the next year. Leave requests must be submitted at least 2 weeks in advance for periods longer than 3 days.", "rag_domain": "HR", "session_id": "test-rag-1", "retry_count": 0, "embedding_done": true, "original_query": "What is the annual leave policy?", "rag_confidence": "HIGH", "rag_sub_question": "Annual leave policy details", "require_approval": false, "intent_confidence": 1.0, "input_guard_passed": true, "history_token_usage": 0, "conversation_summary": ""}, "channel_versions": {"intent": "00000000000000000000000000000004.0.9213189263534638", "status": "00000000000000000000000000000002.0.3186759760044504", "messages": "00000000000000000000000000000007.0.23808075529325656", "__start__": "00000000000000000000000000000002.0.3186759760044504", "cache_hit": "00000000000000000000000000000003.0.17773581668485716", "l1_checked": "00000000000000000000000000000003.0.17773581668485716", "rag_answer": "00000000000000000000000000000007.0.23808075529325656", "rag_domain": "00000000000000000000000000000005.0.34103043054889604", "session_id": "00000000000000000000000000000002.0.3186759760044504", "rag_sources": "00000000000000000000000000000007.0.23808075529325656", "react_steps": "00000000000000000000000000000002.0.3186759760044504", "retry_count": "00000000000000000000000000000002.0.3186759760044504", "guard_issues": "00000000000000000000000000000003.0.17773581668485716", "decision_trace": "00000000000000000000000000000007.0.23808075529325656", "embedding_done": "00000000000000000000000000000003.0.17773581668485716", "original_query": "00000000000000000000000000000002.0.3186759760044504", "rag_confidence": "00000000000000000000000000000007.0.23808075529325656", "query_embedding": "00000000000000000000000000000003.0.17773581668485716", "detected_domains": "00000000000000000000000000000004.0.9213189263534638", "rag_sub_question": "00000000000000000000000000000005.0.34103043054889604", "require_approval": "00000000000000000000000000000002.0.3186759760044504", "intent_confidence": "00000000000000000000000000000004.0.9213189263534638", "pending_tool_call": "00000000000000000000000000000002.0.3186759760044504", "rag_fused_results": "00000000000000000000000000000006.0.6183653630713223", "input_guard_passed": "00000000000000000000000000000003.0.17773581668485716", "history_token_usage": "00000000000000000000000000000006.0.6183653630713223", "conversation_history": "00000000000000000000000000000006.0.6183653630713223", "conversation_summary": "00000000000000000000000000000006.0.6183653630713223", "branch:to:parallel_init": "00000000000000000000000000000003.0.17773581668485716", "branch:to:rag_generator": "00000000000000000000000000000007.0.23808075529325656", "branch:to:rag_retrieval": "00000000000000000000000000000006.0.6183653630713223", "branch:to:rag_domain_router": "00000000000000000000000000000005.0.34103043054889604", "branch:to:supervisor_intent": "00000000000000000000000000000004.0.9213189263534638"}, "updated_channels": ["decision_trace", "messages", "rag_answer", "rag_confidence", "rag_sources"]}	{"step": 5, "source": "loop", "parents": {}}
test-sql-1-52887a2a		1f14ba30-e420-6f17-bfff-204fd86440ca	\N	\N	{"v": 4, "id": "1f14ba30-e420-6f17-bfff-204fd86440ca", "ts": "2026-05-09T12:31:51.615874+00:00", "versions_seen": {"__input__": {}}, "channel_values": {}, "channel_versions": {"__start__": "00000000000000000000000000000001.0.6192262901193353"}, "updated_channels": ["__start__"]}	{"step": -1, "source": "input", "parents": {}}
test-sql-1-52887a2a		1f14ba30-e425-6d33-8000-7cbca118e52b	1f14ba30-e420-6f17-bfff-204fd86440ca	\N	{"v": 4, "id": "1f14ba30-e425-6d33-8000-7cbca118e52b", "ts": "2026-05-09T12:31:51.617873+00:00", "versions_seen": {"__input__": {}, "__start__": {"__start__": "00000000000000000000000000000001.0.6192262901193353"}}, "channel_values": {"intent": "", "status": "processing", "session_id": "test-sql-1", "retry_count": 0, "original_query": "Show top 5 products by price", "require_approval": false, "branch:to:parallel_init": null}, "channel_versions": {"intent": "00000000000000000000000000000002.0.20385790867841658", "status": "00000000000000000000000000000002.0.20385790867841658", "messages": "00000000000000000000000000000002.0.20385790867841658", "__start__": "00000000000000000000000000000002.0.20385790867841658", "session_id": "00000000000000000000000000000002.0.20385790867841658", "react_steps": "00000000000000000000000000000002.0.20385790867841658", "retry_count": "00000000000000000000000000000002.0.20385790867841658", "decision_trace": "00000000000000000000000000000002.0.20385790867841658", "original_query": "00000000000000000000000000000002.0.20385790867841658", "detected_domains": "00000000000000000000000000000002.0.20385790867841658", "require_approval": "00000000000000000000000000000002.0.20385790867841658", "pending_tool_call": "00000000000000000000000000000002.0.20385790867841658", "branch:to:parallel_init": "00000000000000000000000000000002.0.20385790867841658"}, "updated_channels": ["branch:to:parallel_init", "decision_trace", "detected_domains", "intent", "messages", "original_query", "pending_tool_call", "react_steps", "require_approval", "retry_count", "session_id", "status"]}	{"step": 0, "source": "loop", "parents": {}}
test-sql-1-52887a2a		1f14ba32-8300-680a-8001-8d2b75fce1cb	1f14ba30-e425-6d33-8000-7cbca118e52b	\N	{"v": 4, "id": "1f14ba32-8300-680a-8001-8d2b75fce1cb", "ts": "2026-05-09T12:32:35.118490+00:00", "versions_seen": {"__input__": {}, "__start__": {"__start__": "00000000000000000000000000000001.0.6192262901193353"}, "parallel_init": {"branch:to:parallel_init": "00000000000000000000000000000002.0.20385790867841658"}}, "channel_values": {"intent": "", "status": "processing", "cache_hit": false, "l1_checked": true, "session_id": "test-sql-1", "retry_count": 0, "embedding_done": true, "original_query": "Show top 5 products by price", "require_approval": false, "input_guard_passed": true, "history_token_usage": 0, "conversation_summary": "", "branch:to:supervisor_intent": null}, "channel_versions": {"intent": "00000000000000000000000000000002.0.20385790867841658", "status": "00000000000000000000000000000002.0.20385790867841658", "messages": "00000000000000000000000000000003.0.13138599163551845", "__start__": "00000000000000000000000000000002.0.20385790867841658", "cache_hit": "00000000000000000000000000000003.0.13138599163551845", "l1_checked": "00000000000000000000000000000003.0.13138599163551845", "session_id": "00000000000000000000000000000002.0.20385790867841658", "react_steps": "00000000000000000000000000000002.0.20385790867841658", "retry_count": "00000000000000000000000000000002.0.20385790867841658", "guard_issues": "00000000000000000000000000000003.0.13138599163551845", "decision_trace": "00000000000000000000000000000003.0.13138599163551845", "embedding_done": "00000000000000000000000000000003.0.13138599163551845", "original_query": "00000000000000000000000000000002.0.20385790867841658", "query_embedding": "00000000000000000000000000000003.0.13138599163551845", "detected_domains": "00000000000000000000000000000002.0.20385790867841658", "require_approval": "00000000000000000000000000000002.0.20385790867841658", "pending_tool_call": "00000000000000000000000000000002.0.20385790867841658", "input_guard_passed": "00000000000000000000000000000003.0.13138599163551845", "history_token_usage": "00000000000000000000000000000003.0.13138599163551845", "conversation_history": "00000000000000000000000000000003.0.13138599163551845", "conversation_summary": "00000000000000000000000000000003.0.13138599163551845", "branch:to:parallel_init": "00000000000000000000000000000003.0.13138599163551845", "branch:to:supervisor_intent": "00000000000000000000000000000003.0.13138599163551845"}, "updated_channels": ["branch:to:supervisor_intent", "cache_hit", "conversation_history", "conversation_summary", "decision_trace", "embedding_done", "guard_issues", "history_token_usage", "input_guard_passed", "l1_checked", "messages", "query_embedding"]}	{"step": 1, "source": "loop", "parents": {}}
test-sql-1-52887a2a		1f14ba34-2445-6cb3-8002-361730444231	1f14ba32-8300-680a-8001-8d2b75fce1cb	\N	{"v": 4, "id": "1f14ba34-2445-6cb3-8002-361730444231", "ts": "2026-05-09T12:33:18.872491+00:00", "versions_seen": {"__input__": {}, "__start__": {"__start__": "00000000000000000000000000000001.0.6192262901193353"}, "parallel_init": {"branch:to:parallel_init": "00000000000000000000000000000002.0.20385790867841658"}, "supervisor_intent": {"branch:to:supervisor_intent": "00000000000000000000000000000003.0.13138599163551845"}}, "channel_values": {"intent": "sql", "status": "processing", "cache_hit": false, "l1_checked": true, "session_id": "test-sql-1", "retry_count": 0, "embedding_done": true, "original_query": "Show top 5 products by price", "require_approval": false, "intent_confidence": 1.0, "input_guard_passed": true, "history_token_usage": 0, "conversation_summary": "", "branch:to:sql_complexity": null}, "channel_versions": {"intent": "00000000000000000000000000000004.0.38727839415589693", "status": "00000000000000000000000000000002.0.20385790867841658", "messages": "00000000000000000000000000000004.0.38727839415589693", "__start__": "00000000000000000000000000000002.0.20385790867841658", "cache_hit": "00000000000000000000000000000003.0.13138599163551845", "l1_checked": "00000000000000000000000000000003.0.13138599163551845", "session_id": "00000000000000000000000000000002.0.20385790867841658", "react_steps": "00000000000000000000000000000002.0.20385790867841658", "retry_count": "00000000000000000000000000000002.0.20385790867841658", "guard_issues": "00000000000000000000000000000003.0.13138599163551845", "decision_trace": "00000000000000000000000000000004.0.38727839415589693", "embedding_done": "00000000000000000000000000000003.0.13138599163551845", "original_query": "00000000000000000000000000000002.0.20385790867841658", "query_embedding": "00000000000000000000000000000003.0.13138599163551845", "detected_domains": "00000000000000000000000000000004.0.38727839415589693", "require_approval": "00000000000000000000000000000002.0.20385790867841658", "intent_confidence": "00000000000000000000000000000004.0.38727839415589693", "pending_tool_call": "00000000000000000000000000000002.0.20385790867841658", "input_guard_passed": "00000000000000000000000000000003.0.13138599163551845", "history_token_usage": "00000000000000000000000000000003.0.13138599163551845", "conversation_history": "00000000000000000000000000000003.0.13138599163551845", "conversation_summary": "00000000000000000000000000000003.0.13138599163551845", "branch:to:parallel_init": "00000000000000000000000000000003.0.13138599163551845", "branch:to:sql_complexity": "00000000000000000000000000000004.0.38727839415589693", "branch:to:supervisor_intent": "00000000000000000000000000000004.0.38727839415589693"}, "updated_channels": ["branch:to:sql_complexity", "decision_trace", "detected_domains", "intent", "intent_confidence", "messages"]}	{"step": 2, "source": "loop", "parents": {}}
test-sql-1-52887a2a		1f14ba35-c757-63e1-8003-8d500570b5fd	1f14ba34-2445-6cb3-8002-361730444231	\N	{"v": 4, "id": "1f14ba35-c757-63e1-8003-8d500570b5fd", "ts": "2026-05-09T12:34:02.814972+00:00", "versions_seen": {"__input__": {}, "__start__": {"__start__": "00000000000000000000000000000001.0.6192262901193353"}, "parallel_init": {"branch:to:parallel_init": "00000000000000000000000000000002.0.20385790867841658"}, "sql_complexity": {"branch:to:sql_complexity": "00000000000000000000000000000004.0.38727839415589693"}, "supervisor_intent": {"branch:to:supervisor_intent": "00000000000000000000000000000003.0.13138599163551845"}}, "channel_values": {"intent": "sql", "status": "processing", "cache_hit": false, "l1_checked": true, "session_id": "test-sql-1", "retry_count": 0, "embedding_done": true, "original_query": "Show top 5 products by price", "query_complexity": "simple", "require_approval": false, "intent_confidence": 1.0, "input_guard_passed": true, "history_token_usage": 0, "conversation_summary": "", "branch:to:sql_cache_l2": null}, "channel_versions": {"intent": "00000000000000000000000000000004.0.38727839415589693", "status": "00000000000000000000000000000002.0.20385790867841658", "messages": "00000000000000000000000000000005.0.2629590109337936", "__start__": "00000000000000000000000000000002.0.20385790867841658", "cache_hit": "00000000000000000000000000000003.0.13138599163551845", "l1_checked": "00000000000000000000000000000003.0.13138599163551845", "session_id": "00000000000000000000000000000002.0.20385790867841658", "react_steps": "00000000000000000000000000000002.0.20385790867841658", "retry_count": "00000000000000000000000000000002.0.20385790867841658", "guard_issues": "00000000000000000000000000000003.0.13138599163551845", "decision_trace": "00000000000000000000000000000005.0.2629590109337936", "embedding_done": "00000000000000000000000000000003.0.13138599163551845", "original_query": "00000000000000000000000000000002.0.20385790867841658", "query_embedding": "00000000000000000000000000000003.0.13138599163551845", "detected_domains": "00000000000000000000000000000004.0.38727839415589693", "query_complexity": "00000000000000000000000000000005.0.2629590109337936", "require_approval": "00000000000000000000000000000002.0.20385790867841658", "intent_confidence": "00000000000000000000000000000004.0.38727839415589693", "pending_tool_call": "00000000000000000000000000000002.0.20385790867841658", "input_guard_passed": "00000000000000000000000000000003.0.13138599163551845", "history_token_usage": "00000000000000000000000000000003.0.13138599163551845", "conversation_history": "00000000000000000000000000000003.0.13138599163551845", "conversation_summary": "00000000000000000000000000000003.0.13138599163551845", "branch:to:sql_cache_l2": "00000000000000000000000000000005.0.2629590109337936", "branch:to:parallel_init": "00000000000000000000000000000003.0.13138599163551845", "branch:to:sql_complexity": "00000000000000000000000000000005.0.2629590109337936", "branch:to:supervisor_intent": "00000000000000000000000000000004.0.38727839415589693"}, "updated_channels": ["branch:to:sql_cache_l2", "decision_trace", "messages", "query_complexity"]}	{"step": 3, "source": "loop", "parents": {}}
test-sql-1-52887a2a		1f14ba35-c766-6cd8-8004-1dc1c66eef69	1f14ba35-c757-63e1-8003-8d500570b5fd	\N	{"v": 4, "id": "1f14ba35-c766-6cd8-8004-1dc1c66eef69", "ts": "2026-05-09T12:34:02.821346+00:00", "versions_seen": {"__input__": {}, "__start__": {"__start__": "00000000000000000000000000000001.0.6192262901193353"}, "sql_cache_l2": {"branch:to:sql_cache_l2": "00000000000000000000000000000005.0.2629590109337936"}, "parallel_init": {"branch:to:parallel_init": "00000000000000000000000000000002.0.20385790867841658"}, "sql_complexity": {"branch:to:sql_complexity": "00000000000000000000000000000004.0.38727839415589693"}, "supervisor_intent": {"branch:to:supervisor_intent": "00000000000000000000000000000003.0.13138599163551845"}}, "channel_values": {"intent": "sql", "l2_hit": false, "status": "processing", "cache_hit": false, "l1_checked": true, "session_id": "test-sql-1", "retry_count": 0, "embedding_done": true, "original_query": "Show top 5 products by price", "query_complexity": "simple", "require_approval": false, "intent_confidence": 1.0, "input_guard_passed": true, "history_token_usage": 0, "branch:to:sql_schema": null, "conversation_summary": ""}, "channel_versions": {"intent": "00000000000000000000000000000004.0.38727839415589693", "l2_hit": "00000000000000000000000000000006.0.867226227649625", "status": "00000000000000000000000000000002.0.20385790867841658", "messages": "00000000000000000000000000000006.0.867226227649625", "__start__": "00000000000000000000000000000002.0.20385790867841658", "cache_hit": "00000000000000000000000000000003.0.13138599163551845", "l1_checked": "00000000000000000000000000000003.0.13138599163551845", "session_id": "00000000000000000000000000000002.0.20385790867841658", "react_steps": "00000000000000000000000000000002.0.20385790867841658", "retry_count": "00000000000000000000000000000002.0.20385790867841658", "guard_issues": "00000000000000000000000000000003.0.13138599163551845", "decision_trace": "00000000000000000000000000000006.0.867226227649625", "embedding_done": "00000000000000000000000000000003.0.13138599163551845", "original_query": "00000000000000000000000000000002.0.20385790867841658", "query_embedding": "00000000000000000000000000000003.0.13138599163551845", "detected_domains": "00000000000000000000000000000004.0.38727839415589693", "query_complexity": "00000000000000000000000000000005.0.2629590109337936", "require_approval": "00000000000000000000000000000002.0.20385790867841658", "intent_confidence": "00000000000000000000000000000004.0.38727839415589693", "pending_tool_call": "00000000000000000000000000000002.0.20385790867841658", "input_guard_passed": "00000000000000000000000000000003.0.13138599163551845", "history_token_usage": "00000000000000000000000000000003.0.13138599163551845", "branch:to:sql_schema": "00000000000000000000000000000006.0.867226227649625", "conversation_history": "00000000000000000000000000000003.0.13138599163551845", "conversation_summary": "00000000000000000000000000000003.0.13138599163551845", "branch:to:sql_cache_l2": "00000000000000000000000000000006.0.867226227649625", "branch:to:parallel_init": "00000000000000000000000000000003.0.13138599163551845", "branch:to:sql_complexity": "00000000000000000000000000000005.0.2629590109337936", "branch:to:supervisor_intent": "00000000000000000000000000000004.0.38727839415589693"}, "updated_channels": ["branch:to:sql_schema", "decision_trace", "l2_hit", "messages"]}	{"step": 4, "source": "loop", "parents": {}}
test-sql-1-52887a2a		1f14ba35-df83-6cfd-8005-90112d0494b7	1f14ba35-c766-6cd8-8004-1dc1c66eef69	\N	{"v": 4, "id": "1f14ba35-df83-6cfd-8005-90112d0494b7", "ts": "2026-05-09T12:34:05.349810+00:00", "versions_seen": {"__input__": {}, "__start__": {"__start__": "00000000000000000000000000000001.0.6192262901193353"}, "sql_schema": {"branch:to:sql_schema": "00000000000000000000000000000006.0.867226227649625"}, "sql_cache_l2": {"branch:to:sql_cache_l2": "00000000000000000000000000000005.0.2629590109337936"}, "parallel_init": {"branch:to:parallel_init": "00000000000000000000000000000002.0.20385790867841658"}, "sql_complexity": {"branch:to:sql_complexity": "00000000000000000000000000000004.0.38727839415589693"}, "supervisor_intent": {"branch:to:supervisor_intent": "00000000000000000000000000000003.0.13138599163551845"}}, "channel_values": {"intent": "sql", "l2_hit": false, "status": "processing", "cache_hit": false, "l1_checked": true, "session_id": "test-sql-1", "retry_count": 0, "embedding_done": true, "original_query": "Show top 5 products by price", "schema_context": "Relevant columns:\\n  product.unit_price (NUMERIC(12,2)): Selling price per unit of the product\\n  product.cost_price (NUMERIC(12,2)): Purchase/cost price from supplier\\n  supplier.rating (NUMERIC(3,2)): Supplier performance rating from 0.00 to 5.00\\n  inventory.quantity_on_hand (INTEGER): Total physical quantity in stock at location\\n  sales_order.total_amount (NUMERIC(14,2)): Total monetary value of the sales order\\n  purchase_order.total_amount (NUMERIC(14,2)): Total monetary value of the purchase order\\n  product. (): Product catalog with SKU, pricing, weight, and reorder settings\\n  product.unit_price (NUMERIC(12,2)): Selling price per unit of the product\\n  inventory.quantity_reserved (INTEGER): Quantity reserved for pending orders\\n  sales_order.total_amount (NUMERIC(14,2)): Total monetary value of the sales order\\n\\nFull DDL:\\nTABLE category (\\n  id bigint NOT NULL PRIMARY KEY\\n  name character varying NOT NULL\\n  parent_category_id bigint\\n  description text\\n)\\n\\nTABLE checkpoint_blobs (\\n  thread_id text NOT NULL\\n  checkpoint_ns text NOT NULL\\n  channel text NOT NULL\\n  version text NOT NULL\\n  type text NOT NULL\\n  blob bytea\\n)\\n\\nTABLE checkpoint_migrations (\\n  v integer NOT NULL\\n)\\n\\nTABLE checkpoint_writes (\\n  thread_id text NOT NULL\\n  checkpoint_ns text NOT NULL\\n  checkpoint_id text NOT NULL\\n  task_id text NOT NULL\\n  idx integer NOT NULL\\n  channel text NOT NULL\\n  type text\\n  blob bytea NOT NULL\\n  task_path text NOT NULL\\n)\\n\\nTABLE checkpoints (\\n  thread_id text NOT NULL\\n  checkpoint_ns text NOT NULL\\n  checkpoint_id text NOT NULL\\n  parent_checkpoint_id text\\n  type text\\n  checkpoint jsonb NOT NULL\\n  metadata jsonb NOT NULL\\n)\\n\\nTABLE customer (\\n  id bigint NOT NULL PRIMARY KEY\\n  code character varying NOT NULL\\n  name character varying NOT NULL\\n  email character varying\\n  phone character varying\\n  city character varying\\n  state character varying\\n  customer_type character varying\\n  credit_limit numeric\\n  is_active boolean\\n)\\n\\nTABLE inventory (\\n  id bigint NOT NULL PRIMARY KEY\\n  product_id bigint NOT NULL\\n  location_id bigint NOT NULL\\n  quantity_on_hand integer NOT NULL\\n  quantity_reserved integer NOT NULL\\n  quantity_available integer\\n  lot_number character varying\\n  expiry_date date\\n  updated_at timestamp without time zone\\n)\\n\\nTABLE inventory_transaction (\\n  id bigint NOT NULL PRIMARY KEY\\n  product_id bigint NOT NULL\\n  from_location_id bigint\\n  to_location_id bigint\\n  transaction_type character varying NOT NULL\\n  quantity integer NOT NULL\\n  reference_type character varying\\n  reference_id bigint\\n  performed_by character varying\\n  created_at timestamp without time zone\\n)\\n\\nTABLE location (\\n  id bigint NOT NULL PRIMARY KEY\\n  zone_id bigint NOT NULL\\n  aisle character varying\\n  rack character varying\\n  shelf character varying\\n  bin character varying\\n  barcode character varying\\n  location_type character varying NOT NULL\\n  max_weight_kg numeric\\n  is_occupied boolean\\n)\\n\\nTABLE product (\\n  id bigint NOT NULL PRIMARY KEY\\n  sku character varying NOT NULL\\n  name character varying NOT NULL\\n  description text\\n  category_id bigint\\n  supplier_id bigint\\n  unit_price numeric\\n  cost_price numeric\\n  weight_kg numeric\\n  uom character varying\\n  is_perishable boolean\\n  min_stock_level integer\\n  reorder_point integer\\n  reorder_qty integer\\n  is_active boolean\\n  created_at timestamp without time zone\\n)\\n\\nTABLE purchase_order (\\n  id bigint NOT NULL PRIMARY KEY\\n  po_number character varying NOT NULL\\n  supplier_id bigint NOT NULL\\n  warehouse_id bigint NOT NULL\\n  status character varying\\n  order_date date\\n  expected_delivery date\\n  total_amount numeric\\n  created_by character varying\\n  created_at timestamp without time zone\\n)\\n\\nTABLE purchase_order_line (\\n  id bigint NOT NULL PRIMARY KEY\\n  purchase_order_id bigint NOT NULL\\n  product_id bigint NOT NULL\\n  quantity_ordered integer NOT NULL\\n  quantity_received integer\\n  unit_price numeric\\n)\\n\\nTABLE sales_order (\\n  id bigint NOT NULL PRIMARY KEY\\n  order_number character varying NOT NULL\\n  customer_id bigint NOT NULL\\n  warehouse_id bigint NOT NULL\\n  status character varying\\n  priority character varying\\n  order_date date\\n  required_date date\\n  total_amount numeric\\n  shipping_method character varying\\n  created_at timestamp without time zone\\n)\\n\\nTABLE sales_order_line (\\n  id bigint NOT NULL PRIMARY KEY\\n  sales_order_id bigint NOT NULL\\n  product_id bigint NOT NULL\\n  quantity_ordered integer NOT NULL\\n  quantity_shipped integer\\n  unit_price numeric\\n)\\n\\nTABLE shipment (\\n  id bigint NOT NULL PRIMARY KEY\\n  shipment_number character varying NOT NULL\\n  sales_order_id bigint NOT NULL\\n  carrier character varying\\n  tracking_number character varying\\n  status character varying\\n  shipped_date timestamp without time zone\\n  delivered_date timestamp without time zone\\n  created_at timestamp without time zone\\n)\\n\\nTABLE supplier (\\n  id bigint NOT NULL PRIMARY KEY\\n  code character varying NOT NULL\\n  name character varying NOT NULL\\n  contact_name character varying\\n  email character varying\\n  phone character varying\\n  city character varying\\n  country character varying\\n  lead_time_days integer\\n  rating numeric\\n)\\n\\nTABLE warehouse (\\n  id bigint NOT NULL PRIMARY KEY\\n  code character varying NOT NULL\\n  name character varying NOT NULL\\n  city character varying\\n  state character varying\\n  capacity_sqft numeric\\n  is_active boolean\\n  created_at timestamp without time zone\\n)\\n\\nTABLE zone (\\n  id bigint NOT NULL PRIMARY KEY\\n  warehouse_id bigint NOT NULL\\n  code character varying NOT NULL\\n  name character varying NOT NULL\\n  zone_type character varying NOT NULL\\n  temperature_controlled boolean\\n  max_capacity_units integer\\n  utilization_pct numeric\\n)\\n\\nFOREIGN KEYS:\\n  zone.warehouse_id -> warehouse.id\\n  location.zone_id -> zone.id\\n  category.parent_category_id -> category.id\\n  product.category_id -> category.id\\n  product.supplier_id -> supplier.id\\n  inventory.product_id -> product.id\\n  inventory.location_id -> location.id\\n  inventory_transaction.product_id -> product.id\\n  inventory_transaction.from_location_id -> location.id\\n  inventory_transaction.to_location_id -> location.id\\n  purchase_order.supplier_id -> supplier.id\\n  purchase_order.warehouse_id -> warehouse.id\\n  purchase_order_line.purchase_order_id -> purchase_order.id\\n  purchase_order_line.product_id -> product.id\\n  sales_order.customer_id -> customer.id\\n  sales_order.warehouse_id -> warehouse.id\\n  sales_order_line.sales_order_id -> sales_order.id\\n  sales_order_line.product_id -> product.id\\n  shipment.sales_order_id -> sales_order.id", "query_complexity": "simple", "require_approval": false, "intent_confidence": 1.0, "input_guard_passed": true, "history_token_usage": 0, "conversation_summary": "", "branch:to:sql_generator": null}, "channel_versions": {"intent": "00000000000000000000000000000004.0.38727839415589693", "l2_hit": "00000000000000000000000000000006.0.867226227649625", "status": "00000000000000000000000000000002.0.20385790867841658", "messages": "00000000000000000000000000000007.0.09580126371228426", "__start__": "00000000000000000000000000000002.0.20385790867841658", "cache_hit": "00000000000000000000000000000003.0.13138599163551845", "l1_checked": "00000000000000000000000000000003.0.13138599163551845", "session_id": "00000000000000000000000000000002.0.20385790867841658", "react_steps": "00000000000000000000000000000002.0.20385790867841658", "retry_count": "00000000000000000000000000000002.0.20385790867841658", "tables_used": "00000000000000000000000000000007.0.09580126371228426", "guard_issues": "00000000000000000000000000000003.0.13138599163551845", "decision_trace": "00000000000000000000000000000007.0.09580126371228426", "embedding_done": "00000000000000000000000000000003.0.13138599163551845", "original_query": "00000000000000000000000000000002.0.20385790867841658", "schema_context": "00000000000000000000000000000007.0.09580126371228426", "query_embedding": "00000000000000000000000000000003.0.13138599163551845", "detected_domains": "00000000000000000000000000000004.0.38727839415589693", "query_complexity": "00000000000000000000000000000005.0.2629590109337936", "require_approval": "00000000000000000000000000000002.0.20385790867841658", "intent_confidence": "00000000000000000000000000000004.0.38727839415589693", "pending_tool_call": "00000000000000000000000000000002.0.20385790867841658", "input_guard_passed": "00000000000000000000000000000003.0.13138599163551845", "history_token_usage": "00000000000000000000000000000003.0.13138599163551845", "branch:to:sql_schema": "00000000000000000000000000000007.0.09580126371228426", "conversation_history": "00000000000000000000000000000003.0.13138599163551845", "conversation_summary": "00000000000000000000000000000003.0.13138599163551845", "branch:to:sql_cache_l2": "00000000000000000000000000000006.0.867226227649625", "branch:to:parallel_init": "00000000000000000000000000000003.0.13138599163551845", "branch:to:sql_generator": "00000000000000000000000000000007.0.09580126371228426", "branch:to:sql_complexity": "00000000000000000000000000000005.0.2629590109337936", "branch:to:supervisor_intent": "00000000000000000000000000000004.0.38727839415589693"}, "updated_channels": ["branch:to:sql_generator", "decision_trace", "messages", "schema_context", "tables_used"]}	{"step": 5, "source": "loop", "parents": {}}
test-sql-1-52887a2a		1f14ba39-245c-667a-8006-c6ce61a12af4	1f14ba35-df83-6cfd-8005-90112d0494b7	\N	{"v": 4, "id": "1f14ba39-245c-667a-8006-c6ce61a12af4", "ts": "2026-05-09T12:35:33.099481+00:00", "versions_seen": {"__input__": {}, "__start__": {"__start__": "00000000000000000000000000000001.0.6192262901193353"}, "sql_schema": {"branch:to:sql_schema": "00000000000000000000000000000006.0.867226227649625"}, "sql_cache_l2": {"branch:to:sql_cache_l2": "00000000000000000000000000000005.0.2629590109337936"}, "parallel_init": {"branch:to:parallel_init": "00000000000000000000000000000002.0.20385790867841658"}, "sql_generator": {"branch:to:sql_generator": "00000000000000000000000000000007.0.09580126371228426"}, "sql_complexity": {"branch:to:sql_complexity": "00000000000000000000000000000004.0.38727839415589693"}, "supervisor_intent": {"branch:to:supervisor_intent": "00000000000000000000000000000003.0.13138599163551845"}}, "channel_values": {"intent": "sql", "l2_hit": false, "status": "processing", "cache_hit": false, "l1_checked": true, "session_id": "test-sql-1", "retry_count": 0, "generated_sql": "SELECT id, sku, unit_price FROM product ORDER BY unit_price DESC LIMIT 5", "embedding_done": true, "original_query": "Show top 5 products by price", "schema_context": "Relevant columns:\\n  product.unit_price (NUMERIC(12,2)): Selling price per unit of the product\\n  product.cost_price (NUMERIC(12,2)): Purchase/cost price from supplier\\n  supplier.rating (NUMERIC(3,2)): Supplier performance rating from 0.00 to 5.00\\n  inventory.quantity_on_hand (INTEGER): Total physical quantity in stock at location\\n  sales_order.total_amount (NUMERIC(14,2)): Total monetary value of the sales order\\n  purchase_order.total_amount (NUMERIC(14,2)): Total monetary value of the purchase order\\n  product. (): Product catalog with SKU, pricing, weight, and reorder settings\\n  product.unit_price (NUMERIC(12,2)): Selling price per unit of the product\\n  inventory.quantity_reserved (INTEGER): Quantity reserved for pending orders\\n  sales_order.total_amount (NUMERIC(14,2)): Total monetary value of the sales order\\n\\nFull DDL:\\nTABLE category (\\n  id bigint NOT NULL PRIMARY KEY\\n  name character varying NOT NULL\\n  parent_category_id bigint\\n  description text\\n)\\n\\nTABLE checkpoint_blobs (\\n  thread_id text NOT NULL\\n  checkpoint_ns text NOT NULL\\n  channel text NOT NULL\\n  version text NOT NULL\\n  type text NOT NULL\\n  blob bytea\\n)\\n\\nTABLE checkpoint_migrations (\\n  v integer NOT NULL\\n)\\n\\nTABLE checkpoint_writes (\\n  thread_id text NOT NULL\\n  checkpoint_ns text NOT NULL\\n  checkpoint_id text NOT NULL\\n  task_id text NOT NULL\\n  idx integer NOT NULL\\n  channel text NOT NULL\\n  type text\\n  blob bytea NOT NULL\\n  task_path text NOT NULL\\n)\\n\\nTABLE checkpoints (\\n  thread_id text NOT NULL\\n  checkpoint_ns text NOT NULL\\n  checkpoint_id text NOT NULL\\n  parent_checkpoint_id text\\n  type text\\n  checkpoint jsonb NOT NULL\\n  metadata jsonb NOT NULL\\n)\\n\\nTABLE customer (\\n  id bigint NOT NULL PRIMARY KEY\\n  code character varying NOT NULL\\n  name character varying NOT NULL\\n  email character varying\\n  phone character varying\\n  city character varying\\n  state character varying\\n  customer_type character varying\\n  credit_limit numeric\\n  is_active boolean\\n)\\n\\nTABLE inventory (\\n  id bigint NOT NULL PRIMARY KEY\\n  product_id bigint NOT NULL\\n  location_id bigint NOT NULL\\n  quantity_on_hand integer NOT NULL\\n  quantity_reserved integer NOT NULL\\n  quantity_available integer\\n  lot_number character varying\\n  expiry_date date\\n  updated_at timestamp without time zone\\n)\\n\\nTABLE inventory_transaction (\\n  id bigint NOT NULL PRIMARY KEY\\n  product_id bigint NOT NULL\\n  from_location_id bigint\\n  to_location_id bigint\\n  transaction_type character varying NOT NULL\\n  quantity integer NOT NULL\\n  reference_type character varying\\n  reference_id bigint\\n  performed_by character varying\\n  created_at timestamp without time zone\\n)\\n\\nTABLE location (\\n  id bigint NOT NULL PRIMARY KEY\\n  zone_id bigint NOT NULL\\n  aisle character varying\\n  rack character varying\\n  shelf character varying\\n  bin character varying\\n  barcode character varying\\n  location_type character varying NOT NULL\\n  max_weight_kg numeric\\n  is_occupied boolean\\n)\\n\\nTABLE product (\\n  id bigint NOT NULL PRIMARY KEY\\n  sku character varying NOT NULL\\n  name character varying NOT NULL\\n  description text\\n  category_id bigint\\n  supplier_id bigint\\n  unit_price numeric\\n  cost_price numeric\\n  weight_kg numeric\\n  uom character varying\\n  is_perishable boolean\\n  min_stock_level integer\\n  reorder_point integer\\n  reorder_qty integer\\n  is_active boolean\\n  created_at timestamp without time zone\\n)\\n\\nTABLE purchase_order (\\n  id bigint NOT NULL PRIMARY KEY\\n  po_number character varying NOT NULL\\n  supplier_id bigint NOT NULL\\n  warehouse_id bigint NOT NULL\\n  status character varying\\n  order_date date\\n  expected_delivery date\\n  total_amount numeric\\n  created_by character varying\\n  created_at timestamp without time zone\\n)\\n\\nTABLE purchase_order_line (\\n  id bigint NOT NULL PRIMARY KEY\\n  purchase_order_id bigint NOT NULL\\n  product_id bigint NOT NULL\\n  quantity_ordered integer NOT NULL\\n  quantity_received integer\\n  unit_price numeric\\n)\\n\\nTABLE sales_order (\\n  id bigint NOT NULL PRIMARY KEY\\n  order_number character varying NOT NULL\\n  customer_id bigint NOT NULL\\n  warehouse_id bigint NOT NULL\\n  status character varying\\n  priority character varying\\n  order_date date\\n  required_date date\\n  total_amount numeric\\n  shipping_method character varying\\n  created_at timestamp without time zone\\n)\\n\\nTABLE sales_order_line (\\n  id bigint NOT NULL PRIMARY KEY\\n  sales_order_id bigint NOT NULL\\n  product_id bigint NOT NULL\\n  quantity_ordered integer NOT NULL\\n  quantity_shipped integer\\n  unit_price numeric\\n)\\n\\nTABLE shipment (\\n  id bigint NOT NULL PRIMARY KEY\\n  shipment_number character varying NOT NULL\\n  sales_order_id bigint NOT NULL\\n  carrier character varying\\n  tracking_number character varying\\n  status character varying\\n  shipped_date timestamp without time zone\\n  delivered_date timestamp without time zone\\n  created_at timestamp without time zone\\n)\\n\\nTABLE supplier (\\n  id bigint NOT NULL PRIMARY KEY\\n  code character varying NOT NULL\\n  name character varying NOT NULL\\n  contact_name character varying\\n  email character varying\\n  phone character varying\\n  city character varying\\n  country character varying\\n  lead_time_days integer\\n  rating numeric\\n)\\n\\nTABLE warehouse (\\n  id bigint NOT NULL PRIMARY KEY\\n  code character varying NOT NULL\\n  name character varying NOT NULL\\n  city character varying\\n  state character varying\\n  capacity_sqft numeric\\n  is_active boolean\\n  created_at timestamp without time zone\\n)\\n\\nTABLE zone (\\n  id bigint NOT NULL PRIMARY KEY\\n  warehouse_id bigint NOT NULL\\n  code character varying NOT NULL\\n  name character varying NOT NULL\\n  zone_type character varying NOT NULL\\n  temperature_controlled boolean\\n  max_capacity_units integer\\n  utilization_pct numeric\\n)\\n\\nFOREIGN KEYS:\\n  zone.warehouse_id -> warehouse.id\\n  location.zone_id -> zone.id\\n  category.parent_category_id -> category.id\\n  product.category_id -> category.id\\n  product.supplier_id -> supplier.id\\n  inventory.product_id -> product.id\\n  inventory.location_id -> location.id\\n  inventory_transaction.product_id -> product.id\\n  inventory_transaction.from_location_id -> location.id\\n  inventory_transaction.to_location_id -> location.id\\n  purchase_order.supplier_id -> supplier.id\\n  purchase_order.warehouse_id -> warehouse.id\\n  purchase_order_line.purchase_order_id -> purchase_order.id\\n  purchase_order_line.product_id -> product.id\\n  sales_order.customer_id -> customer.id\\n  sales_order.warehouse_id -> warehouse.id\\n  sales_order_line.sales_order_id -> sales_order.id\\n  sales_order_line.product_id -> product.id\\n  shipment.sales_order_id -> sales_order.id", "sql_confidence": 0.9, "query_complexity": "simple", "require_approval": false, "intent_confidence": 1.0, "input_guard_passed": true, "history_token_usage": 0, "conversation_summary": "", "branch:to:sql_validator": null}, "channel_versions": {"intent": "00000000000000000000000000000004.0.38727839415589693", "l2_hit": "00000000000000000000000000000006.0.867226227649625", "status": "00000000000000000000000000000002.0.20385790867841658", "messages": "00000000000000000000000000000008.0.2197845575525217", "__start__": "00000000000000000000000000000002.0.20385790867841658", "cache_hit": "00000000000000000000000000000003.0.13138599163551845", "l1_checked": "00000000000000000000000000000003.0.13138599163551845", "session_id": "00000000000000000000000000000002.0.20385790867841658", "react_steps": "00000000000000000000000000000002.0.20385790867841658", "retry_count": "00000000000000000000000000000008.0.2197845575525217", "tables_used": "00000000000000000000000000000008.0.2197845575525217", "guard_issues": "00000000000000000000000000000003.0.13138599163551845", "generated_sql": "00000000000000000000000000000008.0.2197845575525217", "decision_trace": "00000000000000000000000000000008.0.2197845575525217", "embedding_done": "00000000000000000000000000000003.0.13138599163551845", "original_query": "00000000000000000000000000000002.0.20385790867841658", "schema_context": "00000000000000000000000000000007.0.09580126371228426", "sql_confidence": "00000000000000000000000000000008.0.2197845575525217", "query_embedding": "00000000000000000000000000000003.0.13138599163551845", "detected_domains": "00000000000000000000000000000004.0.38727839415589693", "query_complexity": "00000000000000000000000000000005.0.2629590109337936", "require_approval": "00000000000000000000000000000002.0.20385790867841658", "intent_confidence": "00000000000000000000000000000004.0.38727839415589693", "pending_tool_call": "00000000000000000000000000000002.0.20385790867841658", "input_guard_passed": "00000000000000000000000000000003.0.13138599163551845", "history_token_usage": "00000000000000000000000000000003.0.13138599163551845", "branch:to:sql_schema": "00000000000000000000000000000007.0.09580126371228426", "conversation_history": "00000000000000000000000000000003.0.13138599163551845", "conversation_summary": "00000000000000000000000000000003.0.13138599163551845", "branch:to:sql_cache_l2": "00000000000000000000000000000006.0.867226227649625", "branch:to:parallel_init": "00000000000000000000000000000003.0.13138599163551845", "branch:to:sql_generator": "00000000000000000000000000000008.0.2197845575525217", "branch:to:sql_validator": "00000000000000000000000000000008.0.2197845575525217", "branch:to:sql_complexity": "00000000000000000000000000000005.0.2629590109337936", "branch:to:supervisor_intent": "00000000000000000000000000000004.0.38727839415589693"}, "updated_channels": ["branch:to:sql_validator", "decision_trace", "generated_sql", "messages", "retry_count", "sql_confidence", "tables_used"]}	{"step": 6, "source": "loop", "parents": {}}
test-sql-1-52887a2a		1f14ba39-245e-6be5-8007-aa7713c43ad0	1f14ba39-245c-667a-8006-c6ce61a12af4	\N	{"v": 4, "id": "1f14ba39-245e-6be5-8007-aa7713c43ad0", "ts": "2026-05-09T12:35:33.100438+00:00", "versions_seen": {"__input__": {}, "__start__": {"__start__": "00000000000000000000000000000001.0.6192262901193353"}, "sql_schema": {"branch:to:sql_schema": "00000000000000000000000000000006.0.867226227649625"}, "sql_cache_l2": {"branch:to:sql_cache_l2": "00000000000000000000000000000005.0.2629590109337936"}, "parallel_init": {"branch:to:parallel_init": "00000000000000000000000000000002.0.20385790867841658"}, "sql_generator": {"branch:to:sql_generator": "00000000000000000000000000000007.0.09580126371228426"}, "sql_validator": {"branch:to:sql_validator": "00000000000000000000000000000008.0.2197845575525217"}, "sql_complexity": {"branch:to:sql_complexity": "00000000000000000000000000000004.0.38727839415589693"}, "supervisor_intent": {"branch:to:supervisor_intent": "00000000000000000000000000000003.0.13138599163551845"}}, "channel_values": {"intent": "sql", "l2_hit": false, "status": "processing", "cache_hit": false, "l1_checked": true, "session_id": "test-sql-1", "retry_count": 0, "generated_sql": "SELECT id, sku, unit_price FROM product ORDER BY unit_price DESC LIMIT 5", "sql_validated": true, "embedding_done": true, "estimated_cost": "low", "original_query": "Show top 5 products by price", "schema_context": "Relevant columns:\\n  product.unit_price (NUMERIC(12,2)): Selling price per unit of the product\\n  product.cost_price (NUMERIC(12,2)): Purchase/cost price from supplier\\n  supplier.rating (NUMERIC(3,2)): Supplier performance rating from 0.00 to 5.00\\n  inventory.quantity_on_hand (INTEGER): Total physical quantity in stock at location\\n  sales_order.total_amount (NUMERIC(14,2)): Total monetary value of the sales order\\n  purchase_order.total_amount (NUMERIC(14,2)): Total monetary value of the purchase order\\n  product. (): Product catalog with SKU, pricing, weight, and reorder settings\\n  product.unit_price (NUMERIC(12,2)): Selling price per unit of the product\\n  inventory.quantity_reserved (INTEGER): Quantity reserved for pending orders\\n  sales_order.total_amount (NUMERIC(14,2)): Total monetary value of the sales order\\n\\nFull DDL:\\nTABLE category (\\n  id bigint NOT NULL PRIMARY KEY\\n  name character varying NOT NULL\\n  parent_category_id bigint\\n  description text\\n)\\n\\nTABLE checkpoint_blobs (\\n  thread_id text NOT NULL\\n  checkpoint_ns text NOT NULL\\n  channel text NOT NULL\\n  version text NOT NULL\\n  type text NOT NULL\\n  blob bytea\\n)\\n\\nTABLE checkpoint_migrations (\\n  v integer NOT NULL\\n)\\n\\nTABLE checkpoint_writes (\\n  thread_id text NOT NULL\\n  checkpoint_ns text NOT NULL\\n  checkpoint_id text NOT NULL\\n  task_id text NOT NULL\\n  idx integer NOT NULL\\n  channel text NOT NULL\\n  type text\\n  blob bytea NOT NULL\\n  task_path text NOT NULL\\n)\\n\\nTABLE checkpoints (\\n  thread_id text NOT NULL\\n  checkpoint_ns text NOT NULL\\n  checkpoint_id text NOT NULL\\n  parent_checkpoint_id text\\n  type text\\n  checkpoint jsonb NOT NULL\\n  metadata jsonb NOT NULL\\n)\\n\\nTABLE customer (\\n  id bigint NOT NULL PRIMARY KEY\\n  code character varying NOT NULL\\n  name character varying NOT NULL\\n  email character varying\\n  phone character varying\\n  city character varying\\n  state character varying\\n  customer_type character varying\\n  credit_limit numeric\\n  is_active boolean\\n)\\n\\nTABLE inventory (\\n  id bigint NOT NULL PRIMARY KEY\\n  product_id bigint NOT NULL\\n  location_id bigint NOT NULL\\n  quantity_on_hand integer NOT NULL\\n  quantity_reserved integer NOT NULL\\n  quantity_available integer\\n  lot_number character varying\\n  expiry_date date\\n  updated_at timestamp without time zone\\n)\\n\\nTABLE inventory_transaction (\\n  id bigint NOT NULL PRIMARY KEY\\n  product_id bigint NOT NULL\\n  from_location_id bigint\\n  to_location_id bigint\\n  transaction_type character varying NOT NULL\\n  quantity integer NOT NULL\\n  reference_type character varying\\n  reference_id bigint\\n  performed_by character varying\\n  created_at timestamp without time zone\\n)\\n\\nTABLE location (\\n  id bigint NOT NULL PRIMARY KEY\\n  zone_id bigint NOT NULL\\n  aisle character varying\\n  rack character varying\\n  shelf character varying\\n  bin character varying\\n  barcode character varying\\n  location_type character varying NOT NULL\\n  max_weight_kg numeric\\n  is_occupied boolean\\n)\\n\\nTABLE product (\\n  id bigint NOT NULL PRIMARY KEY\\n  sku character varying NOT NULL\\n  name character varying NOT NULL\\n  description text\\n  category_id bigint\\n  supplier_id bigint\\n  unit_price numeric\\n  cost_price numeric\\n  weight_kg numeric\\n  uom character varying\\n  is_perishable boolean\\n  min_stock_level integer\\n  reorder_point integer\\n  reorder_qty integer\\n  is_active boolean\\n  created_at timestamp without time zone\\n)\\n\\nTABLE purchase_order (\\n  id bigint NOT NULL PRIMARY KEY\\n  po_number character varying NOT NULL\\n  supplier_id bigint NOT NULL\\n  warehouse_id bigint NOT NULL\\n  status character varying\\n  order_date date\\n  expected_delivery date\\n  total_amount numeric\\n  created_by character varying\\n  created_at timestamp without time zone\\n)\\n\\nTABLE purchase_order_line (\\n  id bigint NOT NULL PRIMARY KEY\\n  purchase_order_id bigint NOT NULL\\n  product_id bigint NOT NULL\\n  quantity_ordered integer NOT NULL\\n  quantity_received integer\\n  unit_price numeric\\n)\\n\\nTABLE sales_order (\\n  id bigint NOT NULL PRIMARY KEY\\n  order_number character varying NOT NULL\\n  customer_id bigint NOT NULL\\n  warehouse_id bigint NOT NULL\\n  status character varying\\n  priority character varying\\n  order_date date\\n  required_date date\\n  total_amount numeric\\n  shipping_method character varying\\n  created_at timestamp without time zone\\n)\\n\\nTABLE sales_order_line (\\n  id bigint NOT NULL PRIMARY KEY\\n  sales_order_id bigint NOT NULL\\n  product_id bigint NOT NULL\\n  quantity_ordered integer NOT NULL\\n  quantity_shipped integer\\n  unit_price numeric\\n)\\n\\nTABLE shipment (\\n  id bigint NOT NULL PRIMARY KEY\\n  shipment_number character varying NOT NULL\\n  sales_order_id bigint NOT NULL\\n  carrier character varying\\n  tracking_number character varying\\n  status character varying\\n  shipped_date timestamp without time zone\\n  delivered_date timestamp without time zone\\n  created_at timestamp without time zone\\n)\\n\\nTABLE supplier (\\n  id bigint NOT NULL PRIMARY KEY\\n  code character varying NOT NULL\\n  name character varying NOT NULL\\n  contact_name character varying\\n  email character varying\\n  phone character varying\\n  city character varying\\n  country character varying\\n  lead_time_days integer\\n  rating numeric\\n)\\n\\nTABLE warehouse (\\n  id bigint NOT NULL PRIMARY KEY\\n  code character varying NOT NULL\\n  name character varying NOT NULL\\n  city character varying\\n  state character varying\\n  capacity_sqft numeric\\n  is_active boolean\\n  created_at timestamp without time zone\\n)\\n\\nTABLE zone (\\n  id bigint NOT NULL PRIMARY KEY\\n  warehouse_id bigint NOT NULL\\n  code character varying NOT NULL\\n  name character varying NOT NULL\\n  zone_type character varying NOT NULL\\n  temperature_controlled boolean\\n  max_capacity_units integer\\n  utilization_pct numeric\\n)\\n\\nFOREIGN KEYS:\\n  zone.warehouse_id -> warehouse.id\\n  location.zone_id -> zone.id\\n  category.parent_category_id -> category.id\\n  product.category_id -> category.id\\n  product.supplier_id -> supplier.id\\n  inventory.product_id -> product.id\\n  inventory.location_id -> location.id\\n  inventory_transaction.product_id -> product.id\\n  inventory_transaction.from_location_id -> location.id\\n  inventory_transaction.to_location_id -> location.id\\n  purchase_order.supplier_id -> supplier.id\\n  purchase_order.warehouse_id -> warehouse.id\\n  purchase_order_line.purchase_order_id -> purchase_order.id\\n  purchase_order_line.product_id -> product.id\\n  sales_order.customer_id -> customer.id\\n  sales_order.warehouse_id -> warehouse.id\\n  sales_order_line.sales_order_id -> sales_order.id\\n  sales_order_line.product_id -> product.id\\n  shipment.sales_order_id -> sales_order.id", "sql_confidence": 0.9, "query_complexity": "simple", "require_approval": false, "intent_confidence": 1.0, "input_guard_passed": true, "history_token_usage": 0, "conversation_summary": "", "branch:to:sql_approval": null}, "channel_versions": {"intent": "00000000000000000000000000000004.0.38727839415589693", "l2_hit": "00000000000000000000000000000006.0.867226227649625", "status": "00000000000000000000000000000002.0.20385790867841658", "messages": "00000000000000000000000000000009.0.5595618818582142", "__start__": "00000000000000000000000000000002.0.20385790867841658", "cache_hit": "00000000000000000000000000000003.0.13138599163551845", "l1_checked": "00000000000000000000000000000003.0.13138599163551845", "session_id": "00000000000000000000000000000002.0.20385790867841658", "react_steps": "00000000000000000000000000000002.0.20385790867841658", "retry_count": "00000000000000000000000000000009.0.5595618818582142", "tables_used": "00000000000000000000000000000008.0.2197845575525217", "guard_issues": "00000000000000000000000000000003.0.13138599163551845", "generated_sql": "00000000000000000000000000000008.0.2197845575525217", "sql_validated": "00000000000000000000000000000009.0.5595618818582142", "decision_trace": "00000000000000000000000000000009.0.5595618818582142", "embedding_done": "00000000000000000000000000000003.0.13138599163551845", "estimated_cost": "00000000000000000000000000000009.0.5595618818582142", "original_query": "00000000000000000000000000000002.0.20385790867841658", "schema_context": "00000000000000000000000000000007.0.09580126371228426", "sql_confidence": "00000000000000000000000000000008.0.2197845575525217", "query_embedding": "00000000000000000000000000000003.0.13138599163551845", "detected_domains": "00000000000000000000000000000004.0.38727839415589693", "query_complexity": "00000000000000000000000000000005.0.2629590109337936", "require_approval": "00000000000000000000000000000002.0.20385790867841658", "intent_confidence": "00000000000000000000000000000004.0.38727839415589693", "pending_tool_call": "00000000000000000000000000000002.0.20385790867841658", "validation_errors": "00000000000000000000000000000009.0.5595618818582142", "input_guard_passed": "00000000000000000000000000000003.0.13138599163551845", "history_token_usage": "00000000000000000000000000000003.0.13138599163551845", "branch:to:sql_schema": "00000000000000000000000000000007.0.09580126371228426", "conversation_history": "00000000000000000000000000000003.0.13138599163551845", "conversation_summary": "00000000000000000000000000000003.0.13138599163551845", "branch:to:sql_approval": "00000000000000000000000000000009.0.5595618818582142", "branch:to:sql_cache_l2": "00000000000000000000000000000006.0.867226227649625", "branch:to:parallel_init": "00000000000000000000000000000003.0.13138599163551845", "branch:to:sql_generator": "00000000000000000000000000000008.0.2197845575525217", "branch:to:sql_validator": "00000000000000000000000000000009.0.5595618818582142", "branch:to:sql_complexity": "00000000000000000000000000000005.0.2629590109337936", "branch:to:supervisor_intent": "00000000000000000000000000000004.0.38727839415589693"}, "updated_channels": ["branch:to:sql_approval", "decision_trace", "estimated_cost", "messages", "retry_count", "sql_validated", "validation_errors"]}	{"step": 7, "source": "loop", "parents": {}}
test-sql-1-52887a2a		1f14ba39-2467-6faa-8008-72a89d708cc4	1f14ba39-245e-6be5-8007-aa7713c43ad0	\N	{"v": 4, "id": "1f14ba39-2467-6faa-8008-72a89d708cc4", "ts": "2026-05-09T12:35:33.104221+00:00", "versions_seen": {"__input__": {}, "__start__": {"__start__": "00000000000000000000000000000001.0.6192262901193353"}, "sql_schema": {"branch:to:sql_schema": "00000000000000000000000000000006.0.867226227649625"}, "sql_approval": {"branch:to:sql_approval": "00000000000000000000000000000009.0.5595618818582142"}, "sql_cache_l2": {"branch:to:sql_cache_l2": "00000000000000000000000000000005.0.2629590109337936"}, "parallel_init": {"branch:to:parallel_init": "00000000000000000000000000000002.0.20385790867841658"}, "sql_generator": {"branch:to:sql_generator": "00000000000000000000000000000007.0.09580126371228426"}, "sql_validator": {"branch:to:sql_validator": "00000000000000000000000000000008.0.2197845575525217"}, "sql_complexity": {"branch:to:sql_complexity": "00000000000000000000000000000004.0.38727839415589693"}, "supervisor_intent": {"branch:to:supervisor_intent": "00000000000000000000000000000003.0.13138599163551845"}}, "channel_values": {"intent": "sql", "l2_hit": false, "status": "processing", "approved": true, "cache_hit": false, "l1_checked": true, "session_id": "test-sql-1", "retry_count": 0, "generated_sql": "SELECT id, sku, unit_price FROM product ORDER BY unit_price DESC LIMIT 5", "sql_validated": true, "embedding_done": true, "estimated_cost": "low", "original_query": "Show top 5 products by price", "schema_context": "Relevant columns:\\n  product.unit_price (NUMERIC(12,2)): Selling price per unit of the product\\n  product.cost_price (NUMERIC(12,2)): Purchase/cost price from supplier\\n  supplier.rating (NUMERIC(3,2)): Supplier performance rating from 0.00 to 5.00\\n  inventory.quantity_on_hand (INTEGER): Total physical quantity in stock at location\\n  sales_order.total_amount (NUMERIC(14,2)): Total monetary value of the sales order\\n  purchase_order.total_amount (NUMERIC(14,2)): Total monetary value of the purchase order\\n  product. (): Product catalog with SKU, pricing, weight, and reorder settings\\n  product.unit_price (NUMERIC(12,2)): Selling price per unit of the product\\n  inventory.quantity_reserved (INTEGER): Quantity reserved for pending orders\\n  sales_order.total_amount (NUMERIC(14,2)): Total monetary value of the sales order\\n\\nFull DDL:\\nTABLE category (\\n  id bigint NOT NULL PRIMARY KEY\\n  name character varying NOT NULL\\n  parent_category_id bigint\\n  description text\\n)\\n\\nTABLE checkpoint_blobs (\\n  thread_id text NOT NULL\\n  checkpoint_ns text NOT NULL\\n  channel text NOT NULL\\n  version text NOT NULL\\n  type text NOT NULL\\n  blob bytea\\n)\\n\\nTABLE checkpoint_migrations (\\n  v integer NOT NULL\\n)\\n\\nTABLE checkpoint_writes (\\n  thread_id text NOT NULL\\n  checkpoint_ns text NOT NULL\\n  checkpoint_id text NOT NULL\\n  task_id text NOT NULL\\n  idx integer NOT NULL\\n  channel text NOT NULL\\n  type text\\n  blob bytea NOT NULL\\n  task_path text NOT NULL\\n)\\n\\nTABLE checkpoints (\\n  thread_id text NOT NULL\\n  checkpoint_ns text NOT NULL\\n  checkpoint_id text NOT NULL\\n  parent_checkpoint_id text\\n  type text\\n  checkpoint jsonb NOT NULL\\n  metadata jsonb NOT NULL\\n)\\n\\nTABLE customer (\\n  id bigint NOT NULL PRIMARY KEY\\n  code character varying NOT NULL\\n  name character varying NOT NULL\\n  email character varying\\n  phone character varying\\n  city character varying\\n  state character varying\\n  customer_type character varying\\n  credit_limit numeric\\n  is_active boolean\\n)\\n\\nTABLE inventory (\\n  id bigint NOT NULL PRIMARY KEY\\n  product_id bigint NOT NULL\\n  location_id bigint NOT NULL\\n  quantity_on_hand integer NOT NULL\\n  quantity_reserved integer NOT NULL\\n  quantity_available integer\\n  lot_number character varying\\n  expiry_date date\\n  updated_at timestamp without time zone\\n)\\n\\nTABLE inventory_transaction (\\n  id bigint NOT NULL PRIMARY KEY\\n  product_id bigint NOT NULL\\n  from_location_id bigint\\n  to_location_id bigint\\n  transaction_type character varying NOT NULL\\n  quantity integer NOT NULL\\n  reference_type character varying\\n  reference_id bigint\\n  performed_by character varying\\n  created_at timestamp without time zone\\n)\\n\\nTABLE location (\\n  id bigint NOT NULL PRIMARY KEY\\n  zone_id bigint NOT NULL\\n  aisle character varying\\n  rack character varying\\n  shelf character varying\\n  bin character varying\\n  barcode character varying\\n  location_type character varying NOT NULL\\n  max_weight_kg numeric\\n  is_occupied boolean\\n)\\n\\nTABLE product (\\n  id bigint NOT NULL PRIMARY KEY\\n  sku character varying NOT NULL\\n  name character varying NOT NULL\\n  description text\\n  category_id bigint\\n  supplier_id bigint\\n  unit_price numeric\\n  cost_price numeric\\n  weight_kg numeric\\n  uom character varying\\n  is_perishable boolean\\n  min_stock_level integer\\n  reorder_point integer\\n  reorder_qty integer\\n  is_active boolean\\n  created_at timestamp without time zone\\n)\\n\\nTABLE purchase_order (\\n  id bigint NOT NULL PRIMARY KEY\\n  po_number character varying NOT NULL\\n  supplier_id bigint NOT NULL\\n  warehouse_id bigint NOT NULL\\n  status character varying\\n  order_date date\\n  expected_delivery date\\n  total_amount numeric\\n  created_by character varying\\n  created_at timestamp without time zone\\n)\\n\\nTABLE purchase_order_line (\\n  id bigint NOT NULL PRIMARY KEY\\n  purchase_order_id bigint NOT NULL\\n  product_id bigint NOT NULL\\n  quantity_ordered integer NOT NULL\\n  quantity_received integer\\n  unit_price numeric\\n)\\n\\nTABLE sales_order (\\n  id bigint NOT NULL PRIMARY KEY\\n  order_number character varying NOT NULL\\n  customer_id bigint NOT NULL\\n  warehouse_id bigint NOT NULL\\n  status character varying\\n  priority character varying\\n  order_date date\\n  required_date date\\n  total_amount numeric\\n  shipping_method character varying\\n  created_at timestamp without time zone\\n)\\n\\nTABLE sales_order_line (\\n  id bigint NOT NULL PRIMARY KEY\\n  sales_order_id bigint NOT NULL\\n  product_id bigint NOT NULL\\n  quantity_ordered integer NOT NULL\\n  quantity_shipped integer\\n  unit_price numeric\\n)\\n\\nTABLE shipment (\\n  id bigint NOT NULL PRIMARY KEY\\n  shipment_number character varying NOT NULL\\n  sales_order_id bigint NOT NULL\\n  carrier character varying\\n  tracking_number character varying\\n  status character varying\\n  shipped_date timestamp without time zone\\n  delivered_date timestamp without time zone\\n  created_at timestamp without time zone\\n)\\n\\nTABLE supplier (\\n  id bigint NOT NULL PRIMARY KEY\\n  code character varying NOT NULL\\n  name character varying NOT NULL\\n  contact_name character varying\\n  email character varying\\n  phone character varying\\n  city character varying\\n  country character varying\\n  lead_time_days integer\\n  rating numeric\\n)\\n\\nTABLE warehouse (\\n  id bigint NOT NULL PRIMARY KEY\\n  code character varying NOT NULL\\n  name character varying NOT NULL\\n  city character varying\\n  state character varying\\n  capacity_sqft numeric\\n  is_active boolean\\n  created_at timestamp without time zone\\n)\\n\\nTABLE zone (\\n  id bigint NOT NULL PRIMARY KEY\\n  warehouse_id bigint NOT NULL\\n  code character varying NOT NULL\\n  name character varying NOT NULL\\n  zone_type character varying NOT NULL\\n  temperature_controlled boolean\\n  max_capacity_units integer\\n  utilization_pct numeric\\n)\\n\\nFOREIGN KEYS:\\n  zone.warehouse_id -> warehouse.id\\n  location.zone_id -> zone.id\\n  category.parent_category_id -> category.id\\n  product.category_id -> category.id\\n  product.supplier_id -> supplier.id\\n  inventory.product_id -> product.id\\n  inventory.location_id -> location.id\\n  inventory_transaction.product_id -> product.id\\n  inventory_transaction.from_location_id -> location.id\\n  inventory_transaction.to_location_id -> location.id\\n  purchase_order.supplier_id -> supplier.id\\n  purchase_order.warehouse_id -> warehouse.id\\n  purchase_order_line.purchase_order_id -> purchase_order.id\\n  purchase_order_line.product_id -> product.id\\n  sales_order.customer_id -> customer.id\\n  sales_order.warehouse_id -> warehouse.id\\n  sales_order_line.sales_order_id -> sales_order.id\\n  sales_order_line.product_id -> product.id\\n  shipment.sales_order_id -> sales_order.id", "sql_confidence": 0.9, "query_complexity": "simple", "require_approval": false, "intent_confidence": 1.0, "input_guard_passed": true, "history_token_usage": 0, "approval_explanation": "Auto-approved (dev mode)", "conversation_summary": "", "branch:to:sql_executor": null}, "channel_versions": {"intent": "00000000000000000000000000000004.0.38727839415589693", "l2_hit": "00000000000000000000000000000006.0.867226227649625", "status": "00000000000000000000000000000002.0.20385790867841658", "approved": "00000000000000000000000000000010.0.9903888885742909", "messages": "00000000000000000000000000000010.0.9903888885742909", "__start__": "00000000000000000000000000000002.0.20385790867841658", "cache_hit": "00000000000000000000000000000003.0.13138599163551845", "l1_checked": "00000000000000000000000000000003.0.13138599163551845", "session_id": "00000000000000000000000000000002.0.20385790867841658", "react_steps": "00000000000000000000000000000002.0.20385790867841658", "retry_count": "00000000000000000000000000000009.0.5595618818582142", "tables_used": "00000000000000000000000000000008.0.2197845575525217", "guard_issues": "00000000000000000000000000000003.0.13138599163551845", "generated_sql": "00000000000000000000000000000008.0.2197845575525217", "sql_validated": "00000000000000000000000000000009.0.5595618818582142", "decision_trace": "00000000000000000000000000000010.0.9903888885742909", "embedding_done": "00000000000000000000000000000003.0.13138599163551845", "estimated_cost": "00000000000000000000000000000009.0.5595618818582142", "original_query": "00000000000000000000000000000002.0.20385790867841658", "schema_context": "00000000000000000000000000000007.0.09580126371228426", "sql_confidence": "00000000000000000000000000000008.0.2197845575525217", "query_embedding": "00000000000000000000000000000003.0.13138599163551845", "detected_domains": "00000000000000000000000000000004.0.38727839415589693", "query_complexity": "00000000000000000000000000000005.0.2629590109337936", "require_approval": "00000000000000000000000000000002.0.20385790867841658", "intent_confidence": "00000000000000000000000000000004.0.38727839415589693", "pending_tool_call": "00000000000000000000000000000002.0.20385790867841658", "validation_errors": "00000000000000000000000000000009.0.5595618818582142", "input_guard_passed": "00000000000000000000000000000003.0.13138599163551845", "history_token_usage": "00000000000000000000000000000003.0.13138599163551845", "approval_explanation": "00000000000000000000000000000010.0.9903888885742909", "branch:to:sql_schema": "00000000000000000000000000000007.0.09580126371228426", "conversation_history": "00000000000000000000000000000003.0.13138599163551845", "conversation_summary": "00000000000000000000000000000003.0.13138599163551845", "branch:to:sql_approval": "00000000000000000000000000000010.0.9903888885742909", "branch:to:sql_cache_l2": "00000000000000000000000000000006.0.867226227649625", "branch:to:sql_executor": "00000000000000000000000000000010.0.9903888885742909", "branch:to:parallel_init": "00000000000000000000000000000003.0.13138599163551845", "branch:to:sql_generator": "00000000000000000000000000000008.0.2197845575525217", "branch:to:sql_validator": "00000000000000000000000000000009.0.5595618818582142", "branch:to:sql_complexity": "00000000000000000000000000000005.0.2629590109337936", "branch:to:supervisor_intent": "00000000000000000000000000000004.0.38727839415589693"}, "updated_channels": ["approval_explanation", "approved", "branch:to:sql_executor", "decision_trace", "messages"]}	{"step": 8, "source": "loop", "parents": {}}
test-sql-1-52887a2a		1f14ba39-2484-616d-8009-cbcbfcf021b2	1f14ba39-2467-6faa-8008-72a89d708cc4	\N	{"v": 4, "id": "1f14ba39-2484-616d-8009-cbcbfcf021b2", "ts": "2026-05-09T12:35:33.115735+00:00", "versions_seen": {"__input__": {}, "__start__": {"__start__": "00000000000000000000000000000001.0.6192262901193353"}, "sql_schema": {"branch:to:sql_schema": "00000000000000000000000000000006.0.867226227649625"}, "sql_approval": {"branch:to:sql_approval": "00000000000000000000000000000009.0.5595618818582142"}, "sql_cache_l2": {"branch:to:sql_cache_l2": "00000000000000000000000000000005.0.2629590109337936"}, "sql_executor": {"branch:to:sql_executor": "00000000000000000000000000000010.0.9903888885742909"}, "parallel_init": {"branch:to:parallel_init": "00000000000000000000000000000002.0.20385790867841658"}, "sql_generator": {"branch:to:sql_generator": "00000000000000000000000000000007.0.09580126371228426"}, "sql_validator": {"branch:to:sql_validator": "00000000000000000000000000000008.0.2197845575525217"}, "sql_complexity": {"branch:to:sql_complexity": "00000000000000000000000000000004.0.38727839415589693"}, "supervisor_intent": {"branch:to:supervisor_intent": "00000000000000000000000000000003.0.13138599163551845"}}, "channel_values": {"intent": "sql", "l2_hit": false, "status": "processing", "approved": true, "cache_hit": false, "l1_checked": true, "session_id": "test-sql-1", "retry_count": 0, "generated_sql": "SELECT id, sku, unit_price FROM product ORDER BY unit_price DESC LIMIT 5", "sql_validated": true, "embedding_done": true, "estimated_cost": "low", "original_query": "Show top 5 products by price", "schema_context": "Relevant columns:\\n  product.unit_price (NUMERIC(12,2)): Selling price per unit of the product\\n  product.cost_price (NUMERIC(12,2)): Purchase/cost price from supplier\\n  supplier.rating (NUMERIC(3,2)): Supplier performance rating from 0.00 to 5.00\\n  inventory.quantity_on_hand (INTEGER): Total physical quantity in stock at location\\n  sales_order.total_amount (NUMERIC(14,2)): Total monetary value of the sales order\\n  purchase_order.total_amount (NUMERIC(14,2)): Total monetary value of the purchase order\\n  product. (): Product catalog with SKU, pricing, weight, and reorder settings\\n  product.unit_price (NUMERIC(12,2)): Selling price per unit of the product\\n  inventory.quantity_reserved (INTEGER): Quantity reserved for pending orders\\n  sales_order.total_amount (NUMERIC(14,2)): Total monetary value of the sales order\\n\\nFull DDL:\\nTABLE category (\\n  id bigint NOT NULL PRIMARY KEY\\n  name character varying NOT NULL\\n  parent_category_id bigint\\n  description text\\n)\\n\\nTABLE checkpoint_blobs (\\n  thread_id text NOT NULL\\n  checkpoint_ns text NOT NULL\\n  channel text NOT NULL\\n  version text NOT NULL\\n  type text NOT NULL\\n  blob bytea\\n)\\n\\nTABLE checkpoint_migrations (\\n  v integer NOT NULL\\n)\\n\\nTABLE checkpoint_writes (\\n  thread_id text NOT NULL\\n  checkpoint_ns text NOT NULL\\n  checkpoint_id text NOT NULL\\n  task_id text NOT NULL\\n  idx integer NOT NULL\\n  channel text NOT NULL\\n  type text\\n  blob bytea NOT NULL\\n  task_path text NOT NULL\\n)\\n\\nTABLE checkpoints (\\n  thread_id text NOT NULL\\n  checkpoint_ns text NOT NULL\\n  checkpoint_id text NOT NULL\\n  parent_checkpoint_id text\\n  type text\\n  checkpoint jsonb NOT NULL\\n  metadata jsonb NOT NULL\\n)\\n\\nTABLE customer (\\n  id bigint NOT NULL PRIMARY KEY\\n  code character varying NOT NULL\\n  name character varying NOT NULL\\n  email character varying\\n  phone character varying\\n  city character varying\\n  state character varying\\n  customer_type character varying\\n  credit_limit numeric\\n  is_active boolean\\n)\\n\\nTABLE inventory (\\n  id bigint NOT NULL PRIMARY KEY\\n  product_id bigint NOT NULL\\n  location_id bigint NOT NULL\\n  quantity_on_hand integer NOT NULL\\n  quantity_reserved integer NOT NULL\\n  quantity_available integer\\n  lot_number character varying\\n  expiry_date date\\n  updated_at timestamp without time zone\\n)\\n\\nTABLE inventory_transaction (\\n  id bigint NOT NULL PRIMARY KEY\\n  product_id bigint NOT NULL\\n  from_location_id bigint\\n  to_location_id bigint\\n  transaction_type character varying NOT NULL\\n  quantity integer NOT NULL\\n  reference_type character varying\\n  reference_id bigint\\n  performed_by character varying\\n  created_at timestamp without time zone\\n)\\n\\nTABLE location (\\n  id bigint NOT NULL PRIMARY KEY\\n  zone_id bigint NOT NULL\\n  aisle character varying\\n  rack character varying\\n  shelf character varying\\n  bin character varying\\n  barcode character varying\\n  location_type character varying NOT NULL\\n  max_weight_kg numeric\\n  is_occupied boolean\\n)\\n\\nTABLE product (\\n  id bigint NOT NULL PRIMARY KEY\\n  sku character varying NOT NULL\\n  name character varying NOT NULL\\n  description text\\n  category_id bigint\\n  supplier_id bigint\\n  unit_price numeric\\n  cost_price numeric\\n  weight_kg numeric\\n  uom character varying\\n  is_perishable boolean\\n  min_stock_level integer\\n  reorder_point integer\\n  reorder_qty integer\\n  is_active boolean\\n  created_at timestamp without time zone\\n)\\n\\nTABLE purchase_order (\\n  id bigint NOT NULL PRIMARY KEY\\n  po_number character varying NOT NULL\\n  supplier_id bigint NOT NULL\\n  warehouse_id bigint NOT NULL\\n  status character varying\\n  order_date date\\n  expected_delivery date\\n  total_amount numeric\\n  created_by character varying\\n  created_at timestamp without time zone\\n)\\n\\nTABLE purchase_order_line (\\n  id bigint NOT NULL PRIMARY KEY\\n  purchase_order_id bigint NOT NULL\\n  product_id bigint NOT NULL\\n  quantity_ordered integer NOT NULL\\n  quantity_received integer\\n  unit_price numeric\\n)\\n\\nTABLE sales_order (\\n  id bigint NOT NULL PRIMARY KEY\\n  order_number character varying NOT NULL\\n  customer_id bigint NOT NULL\\n  warehouse_id bigint NOT NULL\\n  status character varying\\n  priority character varying\\n  order_date date\\n  required_date date\\n  total_amount numeric\\n  shipping_method character varying\\n  created_at timestamp without time zone\\n)\\n\\nTABLE sales_order_line (\\n  id bigint NOT NULL PRIMARY KEY\\n  sales_order_id bigint NOT NULL\\n  product_id bigint NOT NULL\\n  quantity_ordered integer NOT NULL\\n  quantity_shipped integer\\n  unit_price numeric\\n)\\n\\nTABLE shipment (\\n  id bigint NOT NULL PRIMARY KEY\\n  shipment_number character varying NOT NULL\\n  sales_order_id bigint NOT NULL\\n  carrier character varying\\n  tracking_number character varying\\n  status character varying\\n  shipped_date timestamp without time zone\\n  delivered_date timestamp without time zone\\n  created_at timestamp without time zone\\n)\\n\\nTABLE supplier (\\n  id bigint NOT NULL PRIMARY KEY\\n  code character varying NOT NULL\\n  name character varying NOT NULL\\n  contact_name character varying\\n  email character varying\\n  phone character varying\\n  city character varying\\n  country character varying\\n  lead_time_days integer\\n  rating numeric\\n)\\n\\nTABLE warehouse (\\n  id bigint NOT NULL PRIMARY KEY\\n  code character varying NOT NULL\\n  name character varying NOT NULL\\n  city character varying\\n  state character varying\\n  capacity_sqft numeric\\n  is_active boolean\\n  created_at timestamp without time zone\\n)\\n\\nTABLE zone (\\n  id bigint NOT NULL PRIMARY KEY\\n  warehouse_id bigint NOT NULL\\n  code character varying NOT NULL\\n  name character varying NOT NULL\\n  zone_type character varying NOT NULL\\n  temperature_controlled boolean\\n  max_capacity_units integer\\n  utilization_pct numeric\\n)\\n\\nFOREIGN KEYS:\\n  zone.warehouse_id -> warehouse.id\\n  location.zone_id -> zone.id\\n  category.parent_category_id -> category.id\\n  product.category_id -> category.id\\n  product.supplier_id -> supplier.id\\n  inventory.product_id -> product.id\\n  inventory.location_id -> location.id\\n  inventory_transaction.product_id -> product.id\\n  inventory_transaction.from_location_id -> location.id\\n  inventory_transaction.to_location_id -> location.id\\n  purchase_order.supplier_id -> supplier.id\\n  purchase_order.warehouse_id -> warehouse.id\\n  purchase_order_line.purchase_order_id -> purchase_order.id\\n  purchase_order_line.product_id -> product.id\\n  sales_order.customer_id -> customer.id\\n  sales_order.warehouse_id -> warehouse.id\\n  sales_order_line.sales_order_id -> sales_order.id\\n  sales_order_line.product_id -> product.id\\n  shipment.sales_order_id -> sales_order.id", "sql_confidence": 0.9, "query_complexity": "simple", "require_approval": false, "intent_confidence": 1.0, "input_guard_passed": true, "history_token_usage": 0, "approval_explanation": "Auto-approved (dev mode)", "conversation_summary": "", "branch:to:sql_response": null}, "channel_versions": {"intent": "00000000000000000000000000000004.0.38727839415589693", "l2_hit": "00000000000000000000000000000006.0.867226227649625", "status": "00000000000000000000000000000002.0.20385790867841658", "approved": "00000000000000000000000000000010.0.9903888885742909", "messages": "00000000000000000000000000000011.0.43487827726728223", "__start__": "00000000000000000000000000000002.0.20385790867841658", "cache_hit": "00000000000000000000000000000003.0.13138599163551845", "l1_checked": "00000000000000000000000000000003.0.13138599163551845", "session_id": "00000000000000000000000000000002.0.20385790867841658", "react_steps": "00000000000000000000000000000002.0.20385790867841658", "retry_count": "00000000000000000000000000000009.0.5595618818582142", "sql_results": "00000000000000000000000000000011.0.43487827726728223", "tables_used": "00000000000000000000000000000008.0.2197845575525217", "guard_issues": "00000000000000000000000000000003.0.13138599163551845", "generated_sql": "00000000000000000000000000000008.0.2197845575525217", "sql_validated": "00000000000000000000000000000009.0.5595618818582142", "decision_trace": "00000000000000000000000000000011.0.43487827726728223", "embedding_done": "00000000000000000000000000000003.0.13138599163551845", "estimated_cost": "00000000000000000000000000000009.0.5595618818582142", "original_query": "00000000000000000000000000000002.0.20385790867841658", "schema_context": "00000000000000000000000000000007.0.09580126371228426", "sql_confidence": "00000000000000000000000000000008.0.2197845575525217", "query_embedding": "00000000000000000000000000000003.0.13138599163551845", "detected_domains": "00000000000000000000000000000004.0.38727839415589693", "query_complexity": "00000000000000000000000000000005.0.2629590109337936", "require_approval": "00000000000000000000000000000002.0.20385790867841658", "intent_confidence": "00000000000000000000000000000004.0.38727839415589693", "pending_tool_call": "00000000000000000000000000000002.0.20385790867841658", "validation_errors": "00000000000000000000000000000009.0.5595618818582142", "input_guard_passed": "00000000000000000000000000000003.0.13138599163551845", "history_token_usage": "00000000000000000000000000000003.0.13138599163551845", "approval_explanation": "00000000000000000000000000000010.0.9903888885742909", "branch:to:sql_schema": "00000000000000000000000000000007.0.09580126371228426", "conversation_history": "00000000000000000000000000000003.0.13138599163551845", "conversation_summary": "00000000000000000000000000000003.0.13138599163551845", "branch:to:sql_approval": "00000000000000000000000000000010.0.9903888885742909", "branch:to:sql_cache_l2": "00000000000000000000000000000006.0.867226227649625", "branch:to:sql_executor": "00000000000000000000000000000011.0.43487827726728223", "branch:to:sql_response": "00000000000000000000000000000011.0.43487827726728223", "branch:to:parallel_init": "00000000000000000000000000000003.0.13138599163551845", "branch:to:sql_generator": "00000000000000000000000000000008.0.2197845575525217", "branch:to:sql_validator": "00000000000000000000000000000009.0.5595618818582142", "branch:to:sql_complexity": "00000000000000000000000000000005.0.2629590109337936", "branch:to:supervisor_intent": "00000000000000000000000000000004.0.38727839415589693"}, "updated_channels": ["branch:to:sql_response", "decision_trace", "messages", "sql_results"]}	{"step": 9, "source": "loop", "parents": {}}
test-sql-1-52887a2a		1f14ba3a-c2af-6624-800a-791c3b7d8363	1f14ba39-2484-616d-8009-cbcbfcf021b2	\N	{"v": 4, "id": "1f14ba3a-c2af-6624-800a-791c3b7d8363", "ts": "2026-05-09T12:36:16.544515+00:00", "versions_seen": {"__input__": {}, "__start__": {"__start__": "00000000000000000000000000000001.0.6192262901193353"}, "sql_schema": {"branch:to:sql_schema": "00000000000000000000000000000006.0.867226227649625"}, "sql_approval": {"branch:to:sql_approval": "00000000000000000000000000000009.0.5595618818582142"}, "sql_cache_l2": {"branch:to:sql_cache_l2": "00000000000000000000000000000005.0.2629590109337936"}, "sql_executor": {"branch:to:sql_executor": "00000000000000000000000000000010.0.9903888885742909"}, "sql_response": {"branch:to:sql_response": "00000000000000000000000000000011.0.43487827726728223"}, "parallel_init": {"branch:to:parallel_init": "00000000000000000000000000000002.0.20385790867841658"}, "sql_generator": {"branch:to:sql_generator": "00000000000000000000000000000007.0.09580126371228426"}, "sql_validator": {"branch:to:sql_validator": "00000000000000000000000000000008.0.2197845575525217"}, "sql_complexity": {"branch:to:sql_complexity": "00000000000000000000000000000004.0.38727839415589693"}, "supervisor_intent": {"branch:to:supervisor_intent": "00000000000000000000000000000003.0.13138599163551845"}}, "channel_values": {"intent": "sql", "l2_hit": false, "status": "completed", "approved": true, "cache_hit": false, "l1_checked": true, "session_id": "test-sql-1", "retry_count": 0, "final_answer": "The top 5 products by price are:\\n\\nThe results show that the Laptop (SKU-LAPTOP-001) is the most expensive product at $899.99, followed by the Desk (SKU-DESK-001) at $549.99, and the Tablet (SKU-TABLET-001) at $499.99. The Chair (SKU-CHAIR-001) and Head Hat (SKU-HHAT-001) are significantly cheaper, priced at $349.99 and $24.99 respectively.", "generated_sql": "SELECT id, sku, unit_price FROM product ORDER BY unit_price DESC LIMIT 5", "sql_validated": true, "embedding_done": true, "estimated_cost": "low", "original_query": "Show top 5 products by price", "schema_context": "Relevant columns:\\n  product.unit_price (NUMERIC(12,2)): Selling price per unit of the product\\n  product.cost_price (NUMERIC(12,2)): Purchase/cost price from supplier\\n  supplier.rating (NUMERIC(3,2)): Supplier performance rating from 0.00 to 5.00\\n  inventory.quantity_on_hand (INTEGER): Total physical quantity in stock at location\\n  sales_order.total_amount (NUMERIC(14,2)): Total monetary value of the sales order\\n  purchase_order.total_amount (NUMERIC(14,2)): Total monetary value of the purchase order\\n  product. (): Product catalog with SKU, pricing, weight, and reorder settings\\n  product.unit_price (NUMERIC(12,2)): Selling price per unit of the product\\n  inventory.quantity_reserved (INTEGER): Quantity reserved for pending orders\\n  sales_order.total_amount (NUMERIC(14,2)): Total monetary value of the sales order\\n\\nFull DDL:\\nTABLE category (\\n  id bigint NOT NULL PRIMARY KEY\\n  name character varying NOT NULL\\n  parent_category_id bigint\\n  description text\\n)\\n\\nTABLE checkpoint_blobs (\\n  thread_id text NOT NULL\\n  checkpoint_ns text NOT NULL\\n  channel text NOT NULL\\n  version text NOT NULL\\n  type text NOT NULL\\n  blob bytea\\n)\\n\\nTABLE checkpoint_migrations (\\n  v integer NOT NULL\\n)\\n\\nTABLE checkpoint_writes (\\n  thread_id text NOT NULL\\n  checkpoint_ns text NOT NULL\\n  checkpoint_id text NOT NULL\\n  task_id text NOT NULL\\n  idx integer NOT NULL\\n  channel text NOT NULL\\n  type text\\n  blob bytea NOT NULL\\n  task_path text NOT NULL\\n)\\n\\nTABLE checkpoints (\\n  thread_id text NOT NULL\\n  checkpoint_ns text NOT NULL\\n  checkpoint_id text NOT NULL\\n  parent_checkpoint_id text\\n  type text\\n  checkpoint jsonb NOT NULL\\n  metadata jsonb NOT NULL\\n)\\n\\nTABLE customer (\\n  id bigint NOT NULL PRIMARY KEY\\n  code character varying NOT NULL\\n  name character varying NOT NULL\\n  email character varying\\n  phone character varying\\n  city character varying\\n  state character varying\\n  customer_type character varying\\n  credit_limit numeric\\n  is_active boolean\\n)\\n\\nTABLE inventory (\\n  id bigint NOT NULL PRIMARY KEY\\n  product_id bigint NOT NULL\\n  location_id bigint NOT NULL\\n  quantity_on_hand integer NOT NULL\\n  quantity_reserved integer NOT NULL\\n  quantity_available integer\\n  lot_number character varying\\n  expiry_date date\\n  updated_at timestamp without time zone\\n)\\n\\nTABLE inventory_transaction (\\n  id bigint NOT NULL PRIMARY KEY\\n  product_id bigint NOT NULL\\n  from_location_id bigint\\n  to_location_id bigint\\n  transaction_type character varying NOT NULL\\n  quantity integer NOT NULL\\n  reference_type character varying\\n  reference_id bigint\\n  performed_by character varying\\n  created_at timestamp without time zone\\n)\\n\\nTABLE location (\\n  id bigint NOT NULL PRIMARY KEY\\n  zone_id bigint NOT NULL\\n  aisle character varying\\n  rack character varying\\n  shelf character varying\\n  bin character varying\\n  barcode character varying\\n  location_type character varying NOT NULL\\n  max_weight_kg numeric\\n  is_occupied boolean\\n)\\n\\nTABLE product (\\n  id bigint NOT NULL PRIMARY KEY\\n  sku character varying NOT NULL\\n  name character varying NOT NULL\\n  description text\\n  category_id bigint\\n  supplier_id bigint\\n  unit_price numeric\\n  cost_price numeric\\n  weight_kg numeric\\n  uom character varying\\n  is_perishable boolean\\n  min_stock_level integer\\n  reorder_point integer\\n  reorder_qty integer\\n  is_active boolean\\n  created_at timestamp without time zone\\n)\\n\\nTABLE purchase_order (\\n  id bigint NOT NULL PRIMARY KEY\\n  po_number character varying NOT NULL\\n  supplier_id bigint NOT NULL\\n  warehouse_id bigint NOT NULL\\n  status character varying\\n  order_date date\\n  expected_delivery date\\n  total_amount numeric\\n  created_by character varying\\n  created_at timestamp without time zone\\n)\\n\\nTABLE purchase_order_line (\\n  id bigint NOT NULL PRIMARY KEY\\n  purchase_order_id bigint NOT NULL\\n  product_id bigint NOT NULL\\n  quantity_ordered integer NOT NULL\\n  quantity_received integer\\n  unit_price numeric\\n)\\n\\nTABLE sales_order (\\n  id bigint NOT NULL PRIMARY KEY\\n  order_number character varying NOT NULL\\n  customer_id bigint NOT NULL\\n  warehouse_id bigint NOT NULL\\n  status character varying\\n  priority character varying\\n  order_date date\\n  required_date date\\n  total_amount numeric\\n  shipping_method character varying\\n  created_at timestamp without time zone\\n)\\n\\nTABLE sales_order_line (\\n  id bigint NOT NULL PRIMARY KEY\\n  sales_order_id bigint NOT NULL\\n  product_id bigint NOT NULL\\n  quantity_ordered integer NOT NULL\\n  quantity_shipped integer\\n  unit_price numeric\\n)\\n\\nTABLE shipment (\\n  id bigint NOT NULL PRIMARY KEY\\n  shipment_number character varying NOT NULL\\n  sales_order_id bigint NOT NULL\\n  carrier character varying\\n  tracking_number character varying\\n  status character varying\\n  shipped_date timestamp without time zone\\n  delivered_date timestamp without time zone\\n  created_at timestamp without time zone\\n)\\n\\nTABLE supplier (\\n  id bigint NOT NULL PRIMARY KEY\\n  code character varying NOT NULL\\n  name character varying NOT NULL\\n  contact_name character varying\\n  email character varying\\n  phone character varying\\n  city character varying\\n  country character varying\\n  lead_time_days integer\\n  rating numeric\\n)\\n\\nTABLE warehouse (\\n  id bigint NOT NULL PRIMARY KEY\\n  code character varying NOT NULL\\n  name character varying NOT NULL\\n  city character varying\\n  state character varying\\n  capacity_sqft numeric\\n  is_active boolean\\n  created_at timestamp without time zone\\n)\\n\\nTABLE zone (\\n  id bigint NOT NULL PRIMARY KEY\\n  warehouse_id bigint NOT NULL\\n  code character varying NOT NULL\\n  name character varying NOT NULL\\n  zone_type character varying NOT NULL\\n  temperature_controlled boolean\\n  max_capacity_units integer\\n  utilization_pct numeric\\n)\\n\\nFOREIGN KEYS:\\n  zone.warehouse_id -> warehouse.id\\n  location.zone_id -> zone.id\\n  category.parent_category_id -> category.id\\n  product.category_id -> category.id\\n  product.supplier_id -> supplier.id\\n  inventory.product_id -> product.id\\n  inventory.location_id -> location.id\\n  inventory_transaction.product_id -> product.id\\n  inventory_transaction.from_location_id -> location.id\\n  inventory_transaction.to_location_id -> location.id\\n  purchase_order.supplier_id -> supplier.id\\n  purchase_order.warehouse_id -> warehouse.id\\n  purchase_order_line.purchase_order_id -> purchase_order.id\\n  purchase_order_line.product_id -> product.id\\n  sales_order.customer_id -> customer.id\\n  sales_order.warehouse_id -> warehouse.id\\n  sales_order_line.sales_order_id -> sales_order.id\\n  sales_order_line.product_id -> product.id\\n  shipment.sales_order_id -> sales_order.id", "sql_confidence": 0.9, "sql_explanation": "The top 5 products by price are:\\n\\nThe results show that the Laptop (SKU-LAPTOP-001) is the most expensive product at $899.99, followed by the Desk (SKU-DESK-001) at $549.99, and the Tablet (SKU-TABLET-001) at $499.99. The Chair (SKU-CHAIR-001) and Head Hat (SKU-HHAT-001) are significantly cheaper, priced at $349.99 and $24.99 respectively.", "query_complexity": "simple", "require_approval": false, "intent_confidence": 1.0, "input_guard_passed": true, "history_token_usage": 0, "approval_explanation": "Auto-approved (dev mode)", "conversation_summary": ""}, "channel_versions": {"intent": "00000000000000000000000000000004.0.38727839415589693", "l2_hit": "00000000000000000000000000000006.0.867226227649625", "status": "00000000000000000000000000000012.0.22339826042277777", "approved": "00000000000000000000000000000010.0.9903888885742909", "messages": "00000000000000000000000000000012.0.22339826042277777", "__start__": "00000000000000000000000000000002.0.20385790867841658", "cache_hit": "00000000000000000000000000000003.0.13138599163551845", "l1_checked": "00000000000000000000000000000003.0.13138599163551845", "session_id": "00000000000000000000000000000002.0.20385790867841658", "react_steps": "00000000000000000000000000000002.0.20385790867841658", "retry_count": "00000000000000000000000000000009.0.5595618818582142", "sql_results": "00000000000000000000000000000011.0.43487827726728223", "tables_used": "00000000000000000000000000000008.0.2197845575525217", "final_answer": "00000000000000000000000000000012.0.22339826042277777", "guard_issues": "00000000000000000000000000000003.0.13138599163551845", "generated_sql": "00000000000000000000000000000008.0.2197845575525217", "sql_validated": "00000000000000000000000000000009.0.5595618818582142", "decision_trace": "00000000000000000000000000000012.0.22339826042277777", "embedding_done": "00000000000000000000000000000003.0.13138599163551845", "estimated_cost": "00000000000000000000000000000009.0.5595618818582142", "original_query": "00000000000000000000000000000002.0.20385790867841658", "schema_context": "00000000000000000000000000000007.0.09580126371228426", "sql_confidence": "00000000000000000000000000000008.0.2197845575525217", "query_embedding": "00000000000000000000000000000003.0.13138599163551845", "sql_explanation": "00000000000000000000000000000012.0.22339826042277777", "detected_domains": "00000000000000000000000000000004.0.38727839415589693", "query_complexity": "00000000000000000000000000000005.0.2629590109337936", "require_approval": "00000000000000000000000000000002.0.20385790867841658", "intent_confidence": "00000000000000000000000000000004.0.38727839415589693", "pending_tool_call": "00000000000000000000000000000002.0.20385790867841658", "validation_errors": "00000000000000000000000000000009.0.5595618818582142", "input_guard_passed": "00000000000000000000000000000003.0.13138599163551845", "history_token_usage": "00000000000000000000000000000003.0.13138599163551845", "approval_explanation": "00000000000000000000000000000010.0.9903888885742909", "branch:to:sql_schema": "00000000000000000000000000000007.0.09580126371228426", "conversation_history": "00000000000000000000000000000003.0.13138599163551845", "conversation_summary": "00000000000000000000000000000003.0.13138599163551845", "branch:to:sql_approval": "00000000000000000000000000000010.0.9903888885742909", "branch:to:sql_cache_l2": "00000000000000000000000000000006.0.867226227649625", "branch:to:sql_executor": "00000000000000000000000000000011.0.43487827726728223", "branch:to:sql_response": "00000000000000000000000000000012.0.22339826042277777", "branch:to:parallel_init": "00000000000000000000000000000003.0.13138599163551845", "branch:to:sql_generator": "00000000000000000000000000000008.0.2197845575525217", "branch:to:sql_validator": "00000000000000000000000000000009.0.5595618818582142", "branch:to:sql_complexity": "00000000000000000000000000000005.0.2629590109337936", "branch:to:supervisor_intent": "00000000000000000000000000000004.0.38727839415589693"}, "updated_channels": ["decision_trace", "final_answer", "messages", "sql_explanation", "status"]}	{"step": 10, "source": "loop", "parents": {}}
test-compound-1-5774cb33		1f14ba41-a2fa-6ad5-bfff-9207c13e1fad	\N	\N	{"v": 4, "id": "1f14ba41-a2fa-6ad5-bfff-9207c13e1fad", "ts": "2026-05-09T12:39:21.124731+00:00", "versions_seen": {"__input__": {}}, "channel_values": {}, "channel_versions": {"__start__": "00000000000000000000000000000001.0.8103278034384275"}, "updated_channels": ["__start__"]}	{"step": -1, "source": "input", "parents": {}}
test-compound-1-5774cb33		1f14ba41-a306-6e4e-8000-33ba300e82de	1f14ba41-a2fa-6ad5-bfff-9207c13e1fad	\N	{"v": 4, "id": "1f14ba41-a306-6e4e-8000-33ba300e82de", "ts": "2026-05-09T12:39:21.129735+00:00", "versions_seen": {"__input__": {}, "__start__": {"__start__": "00000000000000000000000000000001.0.8103278034384275"}}, "channel_values": {"intent": "", "status": "processing", "session_id": "test-compound-1", "retry_count": 0, "original_query": "What is the leave policy and show me total employees?", "require_approval": false, "branch:to:parallel_init": null}, "channel_versions": {"intent": "00000000000000000000000000000002.6.354093502591862e-05", "status": "00000000000000000000000000000002.6.354093502591862e-05", "messages": "00000000000000000000000000000002.6.354093502591862e-05", "__start__": "00000000000000000000000000000002.6.354093502591862e-05", "session_id": "00000000000000000000000000000002.6.354093502591862e-05", "react_steps": "00000000000000000000000000000002.6.354093502591862e-05", "retry_count": "00000000000000000000000000000002.6.354093502591862e-05", "decision_trace": "00000000000000000000000000000002.6.354093502591862e-05", "original_query": "00000000000000000000000000000002.6.354093502591862e-05", "detected_domains": "00000000000000000000000000000002.6.354093502591862e-05", "require_approval": "00000000000000000000000000000002.6.354093502591862e-05", "pending_tool_call": "00000000000000000000000000000002.6.354093502591862e-05", "branch:to:parallel_init": "00000000000000000000000000000002.6.354093502591862e-05"}, "updated_channels": ["branch:to:parallel_init", "decision_trace", "detected_domains", "intent", "messages", "original_query", "pending_tool_call", "react_steps", "require_approval", "retry_count", "session_id", "status"]}	{"step": 0, "source": "loop", "parents": {}}
test-compound-1-5774cb33		1f14ba43-45e7-6478-8001-cd896f58a5b8	1f14ba41-a306-6e4e-8000-33ba300e82de	\N	{"v": 4, "id": "1f14ba43-45e7-6478-8001-cd896f58a5b8", "ts": "2026-05-09T12:40:05.052120+00:00", "versions_seen": {"__input__": {}, "__start__": {"__start__": "00000000000000000000000000000001.0.8103278034384275"}, "parallel_init": {"branch:to:parallel_init": "00000000000000000000000000000002.6.354093502591862e-05"}}, "channel_values": {"intent": "", "status": "processing", "cache_hit": false, "l1_checked": true, "session_id": "test-compound-1", "retry_count": 0, "embedding_done": true, "original_query": "What is the leave policy and show me total employees?", "require_approval": false, "input_guard_passed": true, "history_token_usage": 0, "conversation_summary": "", "branch:to:supervisor_intent": null}, "channel_versions": {"intent": "00000000000000000000000000000002.6.354093502591862e-05", "status": "00000000000000000000000000000002.6.354093502591862e-05", "messages": "00000000000000000000000000000003.0.2571108248560736", "__start__": "00000000000000000000000000000002.6.354093502591862e-05", "cache_hit": "00000000000000000000000000000003.0.2571108248560736", "l1_checked": "00000000000000000000000000000003.0.2571108248560736", "session_id": "00000000000000000000000000000002.6.354093502591862e-05", "react_steps": "00000000000000000000000000000002.6.354093502591862e-05", "retry_count": "00000000000000000000000000000002.6.354093502591862e-05", "guard_issues": "00000000000000000000000000000003.0.2571108248560736", "decision_trace": "00000000000000000000000000000003.0.2571108248560736", "embedding_done": "00000000000000000000000000000003.0.2571108248560736", "original_query": "00000000000000000000000000000002.6.354093502591862e-05", "query_embedding": "00000000000000000000000000000003.0.2571108248560736", "detected_domains": "00000000000000000000000000000002.6.354093502591862e-05", "require_approval": "00000000000000000000000000000002.6.354093502591862e-05", "pending_tool_call": "00000000000000000000000000000002.6.354093502591862e-05", "input_guard_passed": "00000000000000000000000000000003.0.2571108248560736", "history_token_usage": "00000000000000000000000000000003.0.2571108248560736", "conversation_history": "00000000000000000000000000000003.0.2571108248560736", "conversation_summary": "00000000000000000000000000000003.0.2571108248560736", "branch:to:parallel_init": "00000000000000000000000000000003.0.2571108248560736", "branch:to:supervisor_intent": "00000000000000000000000000000003.0.2571108248560736"}, "updated_channels": ["branch:to:supervisor_intent", "cache_hit", "conversation_history", "conversation_summary", "decision_trace", "embedding_done", "guard_issues", "history_token_usage", "input_guard_passed", "l1_checked", "messages", "query_embedding"]}	{"step": 1, "source": "loop", "parents": {}}
test-compound-1-5774cb33		1f14ba44-e59e-6078-8002-5c7d4fa4f0ea	1f14ba43-45e7-6478-8001-cd896f58a5b8	\N	{"v": 4, "id": "1f14ba44-e59e-6078-8002-5c7d4fa4f0ea", "ts": "2026-05-09T12:40:48.642879+00:00", "versions_seen": {"__input__": {}, "__start__": {"__start__": "00000000000000000000000000000001.0.8103278034384275"}, "parallel_init": {"branch:to:parallel_init": "00000000000000000000000000000002.6.354093502591862e-05"}, "supervisor_intent": {"branch:to:supervisor_intent": "00000000000000000000000000000003.0.2571108248560736"}}, "channel_values": {"intent": "compound", "status": "processing", "cache_hit": false, "l1_checked": true, "session_id": "test-compound-1", "retry_count": 0, "embedding_done": true, "original_query": "What is the leave policy and show me total employees?", "require_approval": false, "intent_confidence": 0.8, "input_guard_passed": true, "history_token_usage": 0, "conversation_summary": "", "branch:to:compound_parallel": null}, "channel_versions": {"intent": "00000000000000000000000000000004.0.7834428818718785", "status": "00000000000000000000000000000002.6.354093502591862e-05", "messages": "00000000000000000000000000000004.0.7834428818718785", "__start__": "00000000000000000000000000000002.6.354093502591862e-05", "cache_hit": "00000000000000000000000000000003.0.2571108248560736", "l1_checked": "00000000000000000000000000000003.0.2571108248560736", "session_id": "00000000000000000000000000000002.6.354093502591862e-05", "react_steps": "00000000000000000000000000000002.6.354093502591862e-05", "retry_count": "00000000000000000000000000000002.6.354093502591862e-05", "guard_issues": "00000000000000000000000000000003.0.2571108248560736", "decision_trace": "00000000000000000000000000000004.0.7834428818718785", "embedding_done": "00000000000000000000000000000003.0.2571108248560736", "original_query": "00000000000000000000000000000002.6.354093502591862e-05", "query_embedding": "00000000000000000000000000000003.0.2571108248560736", "detected_domains": "00000000000000000000000000000004.0.7834428818718785", "require_approval": "00000000000000000000000000000002.6.354093502591862e-05", "intent_confidence": "00000000000000000000000000000004.0.7834428818718785", "pending_tool_call": "00000000000000000000000000000002.6.354093502591862e-05", "input_guard_passed": "00000000000000000000000000000003.0.2571108248560736", "history_token_usage": "00000000000000000000000000000003.0.2571108248560736", "conversation_history": "00000000000000000000000000000003.0.2571108248560736", "conversation_summary": "00000000000000000000000000000003.0.2571108248560736", "branch:to:parallel_init": "00000000000000000000000000000003.0.2571108248560736", "branch:to:compound_parallel": "00000000000000000000000000000004.0.7834428818718785", "branch:to:supervisor_intent": "00000000000000000000000000000004.0.7834428818718785"}, "updated_channels": ["branch:to:compound_parallel", "decision_trace", "detected_domains", "intent", "intent_confidence", "messages"]}	{"step": 2, "source": "loop", "parents": {}}
test-compound-1-5774cb33		1f14ba49-d90a-6a81-8003-2d9f8462c21f	1f14ba44-e59e-6078-8002-5c7d4fa4f0ea	\N	{"v": 4, "id": "1f14ba49-d90a-6a81-8003-2d9f8462c21f", "ts": "2026-05-09T12:43:01.541952+00:00", "versions_seen": {"__input__": {}, "__start__": {"__start__": "00000000000000000000000000000001.0.8103278034384275"}, "parallel_init": {"branch:to:parallel_init": "00000000000000000000000000000002.6.354093502591862e-05"}, "compound_parallel": {"branch:to:compound_parallel": "00000000000000000000000000000004.0.7834428818718785"}, "supervisor_intent": {"branch:to:supervisor_intent": "00000000000000000000000000000003.0.2571108248560736"}}, "channel_values": {"intent": "compound", "status": "processing", "cache_hit": false, "l1_checked": true, "rag_answer": "", "session_id": "test-compound-1", "retry_count": 0, "embedding_done": true, "original_query": "What is the leave policy and show me total employees?", "sql_explanation": "", "require_approval": false, "intent_confidence": 0.8, "input_guard_passed": true, "history_token_usage": 0, "conversation_summary": "", "branch:to:supervisor_merge": null}, "channel_versions": {"intent": "00000000000000000000000000000004.0.7834428818718785", "status": "00000000000000000000000000000002.6.354093502591862e-05", "messages": "00000000000000000000000000000005.0.8931033896742542", "__start__": "00000000000000000000000000000002.6.354093502591862e-05", "cache_hit": "00000000000000000000000000000003.0.2571108248560736", "l1_checked": "00000000000000000000000000000003.0.2571108248560736", "rag_answer": "00000000000000000000000000000005.0.8931033896742542", "session_id": "00000000000000000000000000000002.6.354093502591862e-05", "react_steps": "00000000000000000000000000000002.6.354093502591862e-05", "retry_count": "00000000000000000000000000000002.6.354093502591862e-05", "guard_issues": "00000000000000000000000000000003.0.2571108248560736", "decision_trace": "00000000000000000000000000000005.0.8931033896742542", "embedding_done": "00000000000000000000000000000003.0.2571108248560736", "original_query": "00000000000000000000000000000002.6.354093502591862e-05", "query_embedding": "00000000000000000000000000000003.0.2571108248560736", "sql_explanation": "00000000000000000000000000000005.0.8931033896742542", "detected_domains": "00000000000000000000000000000004.0.7834428818718785", "require_approval": "00000000000000000000000000000002.6.354093502591862e-05", "intent_confidence": "00000000000000000000000000000004.0.7834428818718785", "pending_tool_call": "00000000000000000000000000000002.6.354093502591862e-05", "input_guard_passed": "00000000000000000000000000000003.0.2571108248560736", "history_token_usage": "00000000000000000000000000000003.0.2571108248560736", "conversation_history": "00000000000000000000000000000003.0.2571108248560736", "conversation_summary": "00000000000000000000000000000003.0.2571108248560736", "branch:to:parallel_init": "00000000000000000000000000000003.0.2571108248560736", "branch:to:supervisor_merge": "00000000000000000000000000000005.0.8931033896742542", "branch:to:compound_parallel": "00000000000000000000000000000005.0.8931033896742542", "branch:to:supervisor_intent": "00000000000000000000000000000004.0.7834428818718785"}, "updated_channels": ["branch:to:supervisor_merge", "decision_trace", "messages", "rag_answer", "sql_explanation"]}	{"step": 3, "source": "loop", "parents": {}}
test-compound-1-5774cb33		1f14ba49-d90d-6515-8004-64eddf61dd87	1f14ba49-d90a-6a81-8003-2d9f8462c21f	\N	{"v": 4, "id": "1f14ba49-d90d-6515-8004-64eddf61dd87", "ts": "2026-05-09T12:43:01.543042+00:00", "versions_seen": {"__input__": {}, "__start__": {"__start__": "00000000000000000000000000000001.0.8103278034384275"}, "parallel_init": {"branch:to:parallel_init": "00000000000000000000000000000002.6.354093502591862e-05"}, "supervisor_merge": {"branch:to:supervisor_merge": "00000000000000000000000000000005.0.8931033896742542"}, "compound_parallel": {"branch:to:compound_parallel": "00000000000000000000000000000004.0.7834428818718785"}, "supervisor_intent": {"branch:to:supervisor_intent": "00000000000000000000000000000003.0.2571108248560736"}}, "channel_values": {"intent": "compound", "status": "completed", "cache_hit": false, "l1_checked": true, "rag_answer": "", "session_id": "test-compound-1", "retry_count": 0, "final_answer": "No results from any pipeline.", "embedding_done": true, "original_query": "What is the leave policy and show me total employees?", "sql_explanation": "", "require_approval": false, "intent_confidence": 0.8, "input_guard_passed": true, "history_token_usage": 0, "conversation_summary": ""}, "channel_versions": {"intent": "00000000000000000000000000000004.0.7834428818718785", "status": "00000000000000000000000000000006.0.9842096143120652", "messages": "00000000000000000000000000000006.0.9842096143120652", "__start__": "00000000000000000000000000000002.6.354093502591862e-05", "cache_hit": "00000000000000000000000000000003.0.2571108248560736", "l1_checked": "00000000000000000000000000000003.0.2571108248560736", "rag_answer": "00000000000000000000000000000005.0.8931033896742542", "session_id": "00000000000000000000000000000002.6.354093502591862e-05", "react_steps": "00000000000000000000000000000002.6.354093502591862e-05", "retry_count": "00000000000000000000000000000002.6.354093502591862e-05", "final_answer": "00000000000000000000000000000006.0.9842096143120652", "guard_issues": "00000000000000000000000000000003.0.2571108248560736", "decision_trace": "00000000000000000000000000000006.0.9842096143120652", "embedding_done": "00000000000000000000000000000003.0.2571108248560736", "original_query": "00000000000000000000000000000002.6.354093502591862e-05", "query_embedding": "00000000000000000000000000000003.0.2571108248560736", "sql_explanation": "00000000000000000000000000000005.0.8931033896742542", "detected_domains": "00000000000000000000000000000004.0.7834428818718785", "require_approval": "00000000000000000000000000000002.6.354093502591862e-05", "intent_confidence": "00000000000000000000000000000004.0.7834428818718785", "pending_tool_call": "00000000000000000000000000000002.6.354093502591862e-05", "input_guard_passed": "00000000000000000000000000000003.0.2571108248560736", "history_token_usage": "00000000000000000000000000000003.0.2571108248560736", "conversation_history": "00000000000000000000000000000003.0.2571108248560736", "conversation_summary": "00000000000000000000000000000003.0.2571108248560736", "branch:to:parallel_init": "00000000000000000000000000000003.0.2571108248560736", "branch:to:supervisor_merge": "00000000000000000000000000000006.0.9842096143120652", "branch:to:compound_parallel": "00000000000000000000000000000005.0.8931033896742542", "branch:to:supervisor_intent": "00000000000000000000000000000004.0.7834428818718785"}, "updated_channels": ["decision_trace", "final_answer", "messages", "status"]}	{"step": 4, "source": "loop", "parents": {}}
test-compound-2-b99bb20f		1f14ba4f-957e-6029-bfff-591b3ebe7b22	\N	\N	{"v": 4, "id": "1f14ba4f-957e-6029-bfff-591b3ebe7b22", "ts": "2026-05-09T12:45:35.520157+00:00", "versions_seen": {"__input__": {}}, "channel_values": {}, "channel_versions": {"__start__": "00000000000000000000000000000001.0.6568530195814937"}, "updated_channels": ["__start__"]}	{"step": -1, "source": "input", "parents": {}}
test-compound-2-b99bb20f		1f14ba4f-9586-6caa-8000-7fd4d3dfa28c	1f14ba4f-957e-6029-bfff-591b3ebe7b22	\N	{"v": 4, "id": "1f14ba4f-9586-6caa-8000-7fd4d3dfa28c", "ts": "2026-05-09T12:45:35.523754+00:00", "versions_seen": {"__input__": {}, "__start__": {"__start__": "00000000000000000000000000000001.0.6568530195814937"}}, "channel_values": {"intent": "", "status": "processing", "session_id": "test-compound-2", "retry_count": 0, "original_query": "What is the leave policy and show me total products by category?", "require_approval": false, "branch:to:parallel_init": null}, "channel_versions": {"intent": "00000000000000000000000000000002.0.41336010073608076", "status": "00000000000000000000000000000002.0.41336010073608076", "messages": "00000000000000000000000000000002.0.41336010073608076", "__start__": "00000000000000000000000000000002.0.41336010073608076", "session_id": "00000000000000000000000000000002.0.41336010073608076", "react_steps": "00000000000000000000000000000002.0.41336010073608076", "retry_count": "00000000000000000000000000000002.0.41336010073608076", "decision_trace": "00000000000000000000000000000002.0.41336010073608076", "original_query": "00000000000000000000000000000002.0.41336010073608076", "detected_domains": "00000000000000000000000000000002.0.41336010073608076", "require_approval": "00000000000000000000000000000002.0.41336010073608076", "pending_tool_call": "00000000000000000000000000000002.0.41336010073608076", "branch:to:parallel_init": "00000000000000000000000000000002.0.41336010073608076"}, "updated_channels": ["branch:to:parallel_init", "decision_trace", "detected_domains", "intent", "messages", "original_query", "pending_tool_call", "react_steps", "require_approval", "retry_count", "session_id", "status"]}	{"step": 0, "source": "loop", "parents": {}}
test-compound-2-b99bb20f		1f14ba50-70b1-6f8f-8001-b7aa1bd4f30d	1f14ba4f-9586-6caa-8000-7fd4d3dfa28c	\N	{"v": 4, "id": "1f14ba50-70b1-6f8f-8001-b7aa1bd4f30d", "ts": "2026-05-09T12:45:58.504256+00:00", "versions_seen": {"__input__": {}, "__start__": {"__start__": "00000000000000000000000000000001.0.6568530195814937"}, "parallel_init": {"branch:to:parallel_init": "00000000000000000000000000000002.0.41336010073608076"}}, "channel_values": {"intent": "", "status": "processing", "cache_hit": false, "l1_checked": true, "session_id": "test-compound-2", "retry_count": 0, "embedding_done": true, "original_query": "What is the leave policy and show me total products by category?", "require_approval": false, "input_guard_passed": true, "history_token_usage": 0, "conversation_summary": "", "branch:to:supervisor_intent": null}, "channel_versions": {"intent": "00000000000000000000000000000002.0.41336010073608076", "status": "00000000000000000000000000000002.0.41336010073608076", "messages": "00000000000000000000000000000003.0.40284794310255156", "__start__": "00000000000000000000000000000002.0.41336010073608076", "cache_hit": "00000000000000000000000000000003.0.40284794310255156", "l1_checked": "00000000000000000000000000000003.0.40284794310255156", "session_id": "00000000000000000000000000000002.0.41336010073608076", "react_steps": "00000000000000000000000000000002.0.41336010073608076", "retry_count": "00000000000000000000000000000002.0.41336010073608076", "guard_issues": "00000000000000000000000000000003.0.40284794310255156", "decision_trace": "00000000000000000000000000000003.0.40284794310255156", "embedding_done": "00000000000000000000000000000003.0.40284794310255156", "original_query": "00000000000000000000000000000002.0.41336010073608076", "query_embedding": "00000000000000000000000000000003.0.40284794310255156", "detected_domains": "00000000000000000000000000000002.0.41336010073608076", "require_approval": "00000000000000000000000000000002.0.41336010073608076", "pending_tool_call": "00000000000000000000000000000002.0.41336010073608076", "input_guard_passed": "00000000000000000000000000000003.0.40284794310255156", "history_token_usage": "00000000000000000000000000000003.0.40284794310255156", "conversation_history": "00000000000000000000000000000003.0.40284794310255156", "conversation_summary": "00000000000000000000000000000003.0.40284794310255156", "branch:to:parallel_init": "00000000000000000000000000000003.0.40284794310255156", "branch:to:supervisor_intent": "00000000000000000000000000000003.0.40284794310255156"}, "updated_channels": ["branch:to:supervisor_intent", "cache_hit", "conversation_history", "conversation_summary", "decision_trace", "embedding_done", "guard_issues", "history_token_usage", "input_guard_passed", "l1_checked", "messages", "query_embedding"]}	{"step": 1, "source": "loop", "parents": {}}
test-compound-2-b99bb20f		1f14ba52-0fe9-6412-8002-3f968c9529f4	1f14ba50-70b1-6f8f-8001-b7aa1bd4f30d	\N	{"v": 4, "id": "1f14ba52-0fe9-6412-8002-3f968c9529f4", "ts": "2026-05-09T12:46:42.043803+00:00", "versions_seen": {"__input__": {}, "__start__": {"__start__": "00000000000000000000000000000001.0.6568530195814937"}, "parallel_init": {"branch:to:parallel_init": "00000000000000000000000000000002.0.41336010073608076"}, "supervisor_intent": {"branch:to:supervisor_intent": "00000000000000000000000000000003.0.40284794310255156"}}, "channel_values": {"intent": "compound", "status": "processing", "cache_hit": false, "l1_checked": true, "session_id": "test-compound-2", "retry_count": 0, "embedding_done": true, "original_query": "What is the leave policy and show me total products by category?", "require_approval": false, "intent_confidence": 0.8, "input_guard_passed": true, "history_token_usage": 0, "conversation_summary": "", "branch:to:compound_parallel": null}, "channel_versions": {"intent": "00000000000000000000000000000004.0.902313906788756", "status": "00000000000000000000000000000002.0.41336010073608076", "messages": "00000000000000000000000000000004.0.902313906788756", "__start__": "00000000000000000000000000000002.0.41336010073608076", "cache_hit": "00000000000000000000000000000003.0.40284794310255156", "l1_checked": "00000000000000000000000000000003.0.40284794310255156", "session_id": "00000000000000000000000000000002.0.41336010073608076", "react_steps": "00000000000000000000000000000002.0.41336010073608076", "retry_count": "00000000000000000000000000000002.0.41336010073608076", "guard_issues": "00000000000000000000000000000003.0.40284794310255156", "decision_trace": "00000000000000000000000000000004.0.902313906788756", "embedding_done": "00000000000000000000000000000003.0.40284794310255156", "original_query": "00000000000000000000000000000002.0.41336010073608076", "query_embedding": "00000000000000000000000000000003.0.40284794310255156", "detected_domains": "00000000000000000000000000000004.0.902313906788756", "require_approval": "00000000000000000000000000000002.0.41336010073608076", "intent_confidence": "00000000000000000000000000000004.0.902313906788756", "pending_tool_call": "00000000000000000000000000000002.0.41336010073608076", "input_guard_passed": "00000000000000000000000000000003.0.40284794310255156", "history_token_usage": "00000000000000000000000000000003.0.40284794310255156", "conversation_history": "00000000000000000000000000000003.0.40284794310255156", "conversation_summary": "00000000000000000000000000000003.0.40284794310255156", "branch:to:parallel_init": "00000000000000000000000000000003.0.40284794310255156", "branch:to:compound_parallel": "00000000000000000000000000000004.0.902313906788756", "branch:to:supervisor_intent": "00000000000000000000000000000004.0.902313906788756"}, "updated_channels": ["branch:to:compound_parallel", "decision_trace", "detected_domains", "intent", "intent_confidence", "messages"]}	{"step": 2, "source": "loop", "parents": {}}
test-compound-2-b99bb20f		1f14ba58-a2bf-63a8-8003-fa65909d5956	1f14ba52-0fe9-6412-8002-3f968c9529f4	\N	{"v": 4, "id": "1f14ba58-a2bf-63a8-8003-fa65909d5956", "ts": "2026-05-09T12:49:38.501930+00:00", "versions_seen": {"__input__": {}, "__start__": {"__start__": "00000000000000000000000000000001.0.6568530195814937"}, "parallel_init": {"branch:to:parallel_init": "00000000000000000000000000000002.0.41336010073608076"}, "compound_parallel": {"branch:to:compound_parallel": "00000000000000000000000000000004.0.902313906788756"}, "supervisor_intent": {"branch:to:supervisor_intent": "00000000000000000000000000000003.0.40284794310255156"}}, "channel_values": {"intent": "compound", "status": "processing", "cache_hit": false, "l1_checked": true, "rag_answer": "I don't have enough information in the knowledge base to answer this question.", "session_id": "test-compound-2", "retry_count": 0, "generated_sql": "SELECT category.name, COUNT(product.id) FROM category LEFT JOIN product ON category.id = product.category_id GROUP BY category.name ORDER BY COUNT(product.id) DESC LIMIT 50", "embedding_done": true, "original_query": "What is the leave policy and show me total products by category?", "rag_confidence": "LOW", "sql_explanation": "Here's a concise explanation of the SQL results:\\n\\nThe top 5 categories with the most products are Electronics, Furniture, Safety Equipment, Packaging, and Food & Beverage, with Electronics having the most products at 3. This suggests that the warehouse has a strong focus on electronics and furniture products.", "require_approval": false, "intent_confidence": 0.8, "input_guard_passed": true, "history_token_usage": 0, "conversation_summary": "", "branch:to:supervisor_merge": null}, "channel_versions": {"intent": "00000000000000000000000000000004.0.902313906788756", "status": "00000000000000000000000000000002.0.41336010073608076", "messages": "00000000000000000000000000000005.0.10227584215759866", "__start__": "00000000000000000000000000000002.0.41336010073608076", "cache_hit": "00000000000000000000000000000003.0.40284794310255156", "l1_checked": "00000000000000000000000000000003.0.40284794310255156", "rag_answer": "00000000000000000000000000000005.0.10227584215759866", "session_id": "00000000000000000000000000000002.0.41336010073608076", "rag_sources": "00000000000000000000000000000005.0.10227584215759866", "react_steps": "00000000000000000000000000000002.0.41336010073608076", "retry_count": "00000000000000000000000000000002.0.41336010073608076", "sql_results": "00000000000000000000000000000005.0.10227584215759866", "guard_issues": "00000000000000000000000000000003.0.40284794310255156", "generated_sql": "00000000000000000000000000000005.0.10227584215759866", "decision_trace": "00000000000000000000000000000005.0.10227584215759866", "embedding_done": "00000000000000000000000000000003.0.40284794310255156", "original_query": "00000000000000000000000000000002.0.41336010073608076", "rag_confidence": "00000000000000000000000000000005.0.10227584215759866", "query_embedding": "00000000000000000000000000000003.0.40284794310255156", "sql_explanation": "00000000000000000000000000000005.0.10227584215759866", "detected_domains": "00000000000000000000000000000004.0.902313906788756", "require_approval": "00000000000000000000000000000002.0.41336010073608076", "intent_confidence": "00000000000000000000000000000004.0.902313906788756", "pending_tool_call": "00000000000000000000000000000002.0.41336010073608076", "input_guard_passed": "00000000000000000000000000000003.0.40284794310255156", "history_token_usage": "00000000000000000000000000000003.0.40284794310255156", "conversation_history": "00000000000000000000000000000003.0.40284794310255156", "conversation_summary": "00000000000000000000000000000003.0.40284794310255156", "branch:to:parallel_init": "00000000000000000000000000000003.0.40284794310255156", "branch:to:supervisor_merge": "00000000000000000000000000000005.0.10227584215759866", "branch:to:compound_parallel": "00000000000000000000000000000005.0.10227584215759866", "branch:to:supervisor_intent": "00000000000000000000000000000004.0.902313906788756"}, "updated_channels": ["branch:to:supervisor_merge", "decision_trace", "generated_sql", "messages", "rag_answer", "rag_confidence", "rag_sources", "sql_explanation", "sql_results"]}	{"step": 3, "source": "loop", "parents": {}}
test-compound-2-b99bb20f		1f14ba5a-43c3-65bb-8004-d90726019e9e	1f14ba58-a2bf-63a8-8003-fa65909d5956	\N	{"v": 4, "id": "1f14ba5a-43c3-65bb-8004-d90726019e9e", "ts": "2026-05-09T12:50:22.229241+00:00", "versions_seen": {"__input__": {}, "__start__": {"__start__": "00000000000000000000000000000001.0.6568530195814937"}, "parallel_init": {"branch:to:parallel_init": "00000000000000000000000000000002.0.41336010073608076"}, "supervisor_merge": {"branch:to:supervisor_merge": "00000000000000000000000000000005.0.10227584215759866"}, "compound_parallel": {"branch:to:compound_parallel": "00000000000000000000000000000004.0.902313906788756"}, "supervisor_intent": {"branch:to:supervisor_intent": "00000000000000000000000000000003.0.40284794310255156"}}, "channel_values": {"intent": "compound", "status": "completed", "cache_hit": false, "l1_checked": true, "rag_answer": "I don't have enough information in the knowledge base to answer this question.", "session_id": "test-compound-2", "retry_count": 0, "final_answer": "Unfortunately, I don't have enough information in the knowledge base to provide a comprehensive answer to your question. However, I can provide some additional context based on a database query.\\n\\nAccording to the database, the top 5 categories with the most products in the warehouse are Electronics, Furniture, Safety Equipment, Packaging, and Food & Beverage. Notably, Electronics has the most products at 3, indicating a strong focus on electronics and furniture products in the warehouse.", "generated_sql": "SELECT category.name, COUNT(product.id) FROM category LEFT JOIN product ON category.id = product.category_id GROUP BY category.name ORDER BY COUNT(product.id) DESC LIMIT 50", "embedding_done": true, "original_query": "What is the leave policy and show me total products by category?", "rag_confidence": "LOW", "sql_explanation": "Here's a concise explanation of the SQL results:\\n\\nThe top 5 categories with the most products are Electronics, Furniture, Safety Equipment, Packaging, and Food & Beverage, with Electronics having the most products at 3. This suggests that the warehouse has a strong focus on electronics and furniture products.", "require_approval": false, "intent_confidence": 0.8, "input_guard_passed": true, "history_token_usage": 0, "conversation_summary": ""}, "channel_versions": {"intent": "00000000000000000000000000000004.0.902313906788756", "status": "00000000000000000000000000000006.0.7441180169250563", "messages": "00000000000000000000000000000006.0.7441180169250563", "__start__": "00000000000000000000000000000002.0.41336010073608076", "cache_hit": "00000000000000000000000000000003.0.40284794310255156", "l1_checked": "00000000000000000000000000000003.0.40284794310255156", "rag_answer": "00000000000000000000000000000005.0.10227584215759866", "session_id": "00000000000000000000000000000002.0.41336010073608076", "rag_sources": "00000000000000000000000000000005.0.10227584215759866", "react_steps": "00000000000000000000000000000002.0.41336010073608076", "retry_count": "00000000000000000000000000000002.0.41336010073608076", "sql_results": "00000000000000000000000000000005.0.10227584215759866", "final_answer": "00000000000000000000000000000006.0.7441180169250563", "guard_issues": "00000000000000000000000000000003.0.40284794310255156", "generated_sql": "00000000000000000000000000000005.0.10227584215759866", "decision_trace": "00000000000000000000000000000006.0.7441180169250563", "embedding_done": "00000000000000000000000000000003.0.40284794310255156", "original_query": "00000000000000000000000000000002.0.41336010073608076", "rag_confidence": "00000000000000000000000000000005.0.10227584215759866", "query_embedding": "00000000000000000000000000000003.0.40284794310255156", "sql_explanation": "00000000000000000000000000000005.0.10227584215759866", "detected_domains": "00000000000000000000000000000004.0.902313906788756", "require_approval": "00000000000000000000000000000002.0.41336010073608076", "intent_confidence": "00000000000000000000000000000004.0.902313906788756", "pending_tool_call": "00000000000000000000000000000002.0.41336010073608076", "input_guard_passed": "00000000000000000000000000000003.0.40284794310255156", "history_token_usage": "00000000000000000000000000000003.0.40284794310255156", "conversation_history": "00000000000000000000000000000003.0.40284794310255156", "conversation_summary": "00000000000000000000000000000003.0.40284794310255156", "branch:to:parallel_init": "00000000000000000000000000000003.0.40284794310255156", "branch:to:supervisor_merge": "00000000000000000000000000000006.0.7441180169250563", "branch:to:compound_parallel": "00000000000000000000000000000005.0.10227584215759866", "branch:to:supervisor_intent": "00000000000000000000000000000004.0.902313906788756"}, "updated_channels": ["decision_trace", "final_answer", "messages", "status"]}	{"step": 4, "source": "loop", "parents": {}}
\.


--
-- Data for Name: conversation; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.conversation (id, session_id, role, content, sql_query, created_at) FROM stdin;
1	test-sql-1	user	Show top 5 products by price	\N	2026-05-09 12:36:16.537162
2	test-sql-1	assistant	The top 5 products by price are:\n\nThe results show that the Laptop (SKU-LAPTOP-001) is the most expensive product at $899.99, followed by the Desk (SKU-DESK-001) at $549.99, and the Tablet (SKU-TABLET-001) at $499.99. The Chair (SKU-CHAIR-001) and Head Hat (SKU-HHAT-001) are significantly cheaper, priced at $349.99 and $24.99 respectively.	SELECT id, sku, unit_price FROM product ORDER BY unit_price DESC LIMIT 5	2026-05-09 12:36:16.541308
3	test-compound-2	user	What is the leave policy and show me total products by category?	\N	2026-05-09 12:49:38.495734
4	test-compound-2	assistant	Here's a concise explanation of the SQL results:\n\nThe top 5 categories with the most products are Electronics, Furniture, Safety Equipment, Packaging, and Food & Beverage, with Electronics having the most products at 3. This suggests that the warehouse has a strong focus on electronics and furniture products.	SELECT category.name, COUNT(product.id) FROM category LEFT JOIN product ON category.id = product.category_id GROUP BY category.name ORDER BY COUNT(product.id) DESC LIMIT 50	2026-05-09 12:49:38.498873
\.


--
-- Data for Name: conversation_summary; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.conversation_summary (session_id, summary, approximate_tokens, updated_at) FROM stdin;
\.


--
-- Data for Name: customer; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.customer (id, code, name, email, phone, city, state, customer_type, credit_limit, is_active) FROM stdin;
1	CUST-001	Metro Office Supplies	john@metrooffice.com	\N	New York	NY	RETAIL	50000.00	t
2	CUST-002	BulkBuy Distributors	maria@bulkbuy.com	\N	Chicago	IL	WHOLESALE	250000.00	t
3	CUST-003	Pacific Coast Trading	kevin@pctrade.com	\N	Long Beach	CA	DISTRIBUTOR	500000.00	t
4	CUST-004	GreenTech Solutions	priya@greentech.com	\N	Austin	TX	RETAIL	75000.00	t
\.


--
-- Data for Name: inventory; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.inventory (id, product_id, location_id, quantity_on_hand, quantity_reserved, lot_number, expiry_date, updated_at) FROM stdin;
1	1	1	120	15	LOT-2024-001	\N	2026-05-09 11:49:55.71799
2	1	2	80	10	LOT-2024-002	\N	2026-05-09 11:49:55.71799
3	2	2	200	25	LOT-2024-003	\N	2026-05-09 11:49:55.71799
4	3	4	1500	200	LOT-2024-004	\N	2026-05-09 11:49:55.71799
5	4	4	25	3	LOT-2024-005	\N	2026-05-09 11:49:55.71799
6	5	4	40	5	LOT-2024-006	\N	2026-05-09 11:49:55.71799
7	6	6	450	50	LOT-2024-007	\N	2026-05-09 11:49:55.71799
8	7	6	600	75	LOT-2024-008	\N	2026-05-09 11:49:55.71799
9	8	6	3000	500	LOT-2024-009	\N	2026-05-09 11:49:55.71799
10	10	5	300	40	LOT-FRZ-001	\N	2026-05-09 11:49:55.71799
11	1	7	90	8	LOT-2024-010	\N	2026-05-09 11:49:55.71799
12	3	8	2500	300	LOT-2024-011	\N	2026-05-09 11:49:55.71799
13	9	9	180	25	LOT-2024-012	\N	2026-05-09 11:49:55.71799
\.


--
-- Data for Name: inventory_transaction; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.inventory_transaction (id, product_id, from_location_id, to_location_id, transaction_type, quantity, reference_type, reference_id, performed_by, created_at) FROM stdin;
1	1	\N	1	RECEIPT	120	PURCHASE_ORDER	1	warehouse_ops	2024-08-09 08:00:00
2	1	1	\N	PICK	5	SALES_ORDER	1	picker_01	2024-09-24 10:00:00
3	1	1	\N	PICK	25	SALES_ORDER	2	picker_01	2024-10-02 08:00:00
4	3	\N	4	RECEIPT	1500	PURCHASE_ORDER	1	warehouse_ops	2024-08-09 09:00:00
5	8	\N	6	ADJUSTMENT	-50	ADJUSTMENT	\N	supervisor	2024-10-20 14:00:00
\.


--
-- Data for Name: location; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.location (id, zone_id, aisle, rack, shelf, bin, barcode, location_type, max_weight_kg, is_occupied) FROM stdin;
1	2	A	01	01	01	LOC-A010101	RACK	500.00	t
2	2	A	01	02	01	LOC-A010201	RACK	500.00	t
3	2	A	02	01	01	LOC-A020101	RACK	500.00	f
4	2	B	01	01	01	LOC-B010101	BULK	2000.00	t
5	3	F	01	01	01	LOC-F010101	RACK	400.00	t
6	4	P	01	01	01	LOC-P010101	PICK_FACE	200.00	t
7	6	A	01	01	01	LOC-W-A0101	RACK	600.00	t
8	6	B	01	01	01	LOC-W-B0101	PALLET	1200.00	t
9	8	A	01	01	01	LOC-C-A0101	RACK	500.00	t
\.


--
-- Data for Name: product; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.product (id, sku, name, description, category_id, supplier_id, unit_price, cost_price, weight_kg, uom, is_perishable, min_stock_level, reorder_point, reorder_qty, is_active, created_at) FROM stdin;
1	SKU-LAPTOP-001	ProBook Laptop 15"	Business laptop 16GB RAM	1	1	899.99	650.00	2.100	EACH	f	50	100	200	t	2026-05-09 11:49:55.712828
2	SKU-TABLET-001	SmartTab Pro 10"	10-inch tablet with stylus	1	1	499.99	320.00	0.550	EACH	f	30	60	100	t	2026-05-09 11:49:55.712828
3	SKU-CABLE-001	Cat6 Ethernet Cable 10ft	Network cable	1	1	12.99	4.50	0.150	EACH	f	200	500	1000	t	2026-05-09 11:49:55.712828
4	SKU-DESK-001	Ergonomic Standing Desk	Electric height-adjustable	2	2	549.99	320.00	35.000	EACH	f	10	20	50	t	2026-05-09 11:49:55.712828
5	SKU-CHAIR-001	Executive Mesh Chair	Lumbar support chair	2	2	349.99	180.00	18.000	EACH	f	15	30	60	t	2026-05-09 11:49:55.712828
6	SKU-HHAT-001	Hard Hat Type II White	ANSI certified	3	3	24.99	8.50	0.400	EACH	f	100	200	500	t	2026-05-09 11:49:55.712828
7	SKU-VEST-001	Hi-Vis Safety Vest	Class 2 reflective	3	3	14.99	5.00	0.200	EACH	f	150	300	600	t	2026-05-09 11:49:55.712828
8	SKU-BOX-SM	Shipping Box Small	12x10x8 corrugated	4	4	1.99	0.45	0.300	EACH	f	500	1000	3000	t	2026-05-09 11:49:55.712828
9	SKU-BOX-LG	Shipping Box Large	24x18x18 heavy-duty	4	4	5.99	1.50	0.800	EACH	f	200	500	1500	t	2026-05-09 11:49:55.712828
10	SKU-CHICKEN	Frozen Chicken Breast 5lb	Boneless skinless	5	5	12.99	7.50	2.270	EACH	f	100	200	500	t	2026-05-09 11:49:55.712828
\.


--
-- Data for Name: prompt_template; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.prompt_template (id, name, version, template, description, model_hint, is_active, created_at, updated_at) FROM stdin;
1	supervisor_intent	1	You classify user queries into exactly one intent category.\n\nCategories:\n- "rag" - User wants to READ knowledge from documents: policies, benefits, product info, FAQs, how-to guides.\n  Examples: "What are leave benefits?", "Explain our return policy", "How does product X work?"\n\n- "sql" - User wants to QUERY structured data: reports, counts, listings, analytics from database tables.\n  Examples: "Show top 5 products by price", "How many orders today?", "List pending shipments"\n\n- "action" - User wants to MUTATE data or trigger a process: create, update, notify, sync, send, cancel.\n  Examples: "Create a purchase order for product 5", "Notify supplier 3", "Update shipment to SHIPPED"\n\n- "compound" - User asks about BOTH documents AND data in the same query.\n  Examples: "What is the leave policy and show me pending leave requests?"\n\nReply with ONLY JSON:\n{"intent": "rag|sql|action|compound", "confidence": 0.0-1.0, "detected_domains": ["HR"|"PRODUCT"|"AI"|"SQL"|"ACTION"]}\nNo explanation. No markdown.	Supervisor intent detection	fast	t	2026-05-09 12:06:46.20402	2026-05-09 12:06:46.20402
2	domain_router	1	You are a domain router for a knowledge base with these domains:\n- HR: Leave policies, benefits, compensation, employee handbook, HR procedures\n- PRODUCT: Product catalog, pricing, features, specifications, comparisons\n- AI: AI/ML concepts, GenAI, LangChain, RAG, prompt engineering, LLM topics\n\nGiven the user query, determine:\n1. Which domain to search\n2. A rewritten sub-question optimized for retrieval\n\nReply with ONLY JSON:\n{"domain": "HR|PRODUCT|AI", "sub_question": "optimized search query", "confidence": 0.0-1.0}\nNo explanation. No markdown.	RAG domain routing prompt	fast	t	2026-05-09 12:06:46.20402	2026-05-09 12:06:46.20402
3	rag_generation	1	You are a knowledgeable assistant. Answer the user's question using ONLY the provided context.\n\nRules:\n- If the context doesn't contain the answer, say "I don't have enough information to answer this."\n- Cite sources when available\n- Be concise but thorough (2-4 sentences for simple questions, more for complex)\n- Rate your confidence: HIGH (directly answered), MEDIUM (partially), LOW (inferred)\n\nContext:\n{context}\n\nConversation History:\n{history}\n\nQuestion: {query}\n\nProvide your answer in JSON format:\n{{"answer": "your answer here", "confidence": "HIGH|MEDIUM|LOW", "sources": ["source1", "source2"]}}	RAG answer generation with context	heavy	t	2026-05-09 12:06:46.20402	2026-05-09 12:06:46.20402
4	complexity_detection	1	Classify the following query complexity for SQL generation against a warehouse database.\n\nReply with ONLY JSON: {"complexity": "simple"} or {"complexity": "moderate"} or {"complexity": "complex"}\n\nsimple = single table lookups, counts, direct data retrieval\nmoderate = multi-table joins, filtering with conditions\ncomplex = aggregations with grouping, subqueries, temporal analysis\n\nNo explanation. No markdown.	Complexity detection	fast	t	2026-05-09 12:06:46.20402	2026-05-09 12:06:46.20402
5	ambiguity_resolution	1	You are an ambiguity resolution agent for a warehouse management SQL system.\n\nYour job:\n1. Determine if the user's query is ambiguous or unclear for SQL generation\n2. If CLEAR: set is_ambiguous=false and rewrite as a clearer natural language question\n3. If AMBIGUOUS: set is_ambiguous=true and provide 2-3 likely interpretations as suggestions\n\nContext from conversation history (use this to infer intent if available):\n{history_context}\n\nRules:\n- If conversation history exists and helps clarify, use it to infer intent\n- If ambiguous with history: provide interpretations based on context\n- If ambiguous without useful history: ask for clarification directly\n- Always prefer clarification over wrong assumptions\n- Keep suggestions concise and context-aware\n- Most queries are CLEAR. Only flag as ambiguous if truly impossible to answer.\n\nCall resolve_ambiguity with your determination.	Ambiguity resolution prompt	fast	t	2026-05-09 12:06:46.20402	2026-05-09 12:06:46.20402
6	sql_generation	1	Generate a PostgreSQL SELECT for a warehouse DB.\nRules: exact table/column names from schema, LIMIT <=50, proper JOINs via FK, no SELECT *.\nSchema: {schema}\nQuestion: {query}\n{context}\nCall generate_sql tool with sql, confidence, tables_used, reasoning.	SQL generation prompt	heavy	t	2026-05-09 12:06:46.20402	2026-05-09 12:06:46.20402
7	response_synthesis	1	Explain SQL results concisely (2-3 sentences). Highlight key insights.\nQuestion: {query}\nSQL: {sql}\nResults ({total_rows} rows, first 10): {results}	Response synthesis prompt	fast	t	2026-05-09 12:06:46.20402	2026-05-09 12:06:46.20402
8	response_system	1	You are a data analyst for a warehouse management system. Explain SQL query results concisely in 2-3 sentences. Highlight key insights, trends, or notable values. Use natural language that a business user would understand.	Response agent system message	fast	t	2026-05-09 12:06:46.20402	2026-05-09 12:06:46.20402
9	memory_summarization	1	You are a conversation summarizer for a multi-agent assistant.\nCreate a concise summary that captures key information from the conversation.\nPreserve: entities mentioned, queries asked, results discussed, user preferences.\nKeep it under 500 words. Focus on facts that would help answer future questions.	Memory summarization system prompt	fast	t	2026-05-09 12:06:46.20402	2026-05-09 12:06:46.20402
10	sql_self_consistency	1	You verify if a generated SQL query correctly answers the user's natural language question.\nReply with ONLY JSON: {"aligned": true, "penalty": 0.0} if SQL matches the question.\nOr {"aligned": false, "penalty": 0.15, "reason": "brief reason"} if misaligned.\nNo explanation outside JSON. No markdown.	SQL self-consistency check	fast	t	2026-05-09 12:06:46.20402	2026-05-09 12:06:46.20402
11	react_system	1	{tools_prompt}\n\nYou are a warehouse management action agent. Execute actions requested by the user.\n\nREACT LOOP RULES:\n1. Analyze the user request and any previous tool results.\n2. Decide: call a tool OR done?\n3. Reply with ONLY valid JSON.\n\nIf you need to call a tool:\n{{"action": "call_tool", "tool_name": "<name>", "tool_args": {{...}}, "reasoning": "..."}}\n\nIf done:\n{{"action": "done", "summary": "concise summary of what was accomplished"}}\n\nMaximum steps: {max_steps}	ReAct agent system prompt	heavy	t	2026-05-09 12:06:46.20402	2026-05-09 12:06:46.20402
12	supervisor_merge	1	Merge results from two pipelines into a unified response.\n\nRAG Result (from knowledge base):\n{rag_result}\n\nSQL Result (from database):\n{sql_result}\n\nCreate a unified, coherent response that combines both sources. Be concise.	Supervisor merge prompt for compound queries	fast	t	2026-05-09 12:06:46.20402	2026-05-09 12:06:46.20402
\.


--
-- Data for Name: purchase_order; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.purchase_order (id, po_number, supplier_id, warehouse_id, status, order_date, expected_delivery, total_amount, created_by, created_at) FROM stdin;
1	PO-2024-001	1	1	RECEIVED	2024-08-01	2024-08-10	175000.00	admin	2026-05-09 11:49:55.726144
2	PO-2024-002	4	1	RECEIVED	2024-09-15	2024-09-20	12500.00	admin	2026-05-09 11:49:55.726144
3	PO-2024-003	5	1	CONFIRMED	2024-10-15	2024-10-20	8500.00	admin	2026-05-09 11:49:55.726144
4	PO-2024-004	2	2	SUBMITTED	2024-11-05	2024-11-25	45000.00	admin	2026-05-09 11:49:55.726144
\.


--
-- Data for Name: purchase_order_line; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.purchase_order_line (id, purchase_order_id, product_id, quantity_ordered, quantity_received, unit_price) FROM stdin;
1	1	1	200	200	650.00
2	1	2	100	100	320.00
3	2	8	3000	3000	0.45
4	2	9	1000	1000	1.50
5	3	10	500	300	7.50
6	4	4	50	0	320.00
\.


--
-- Data for Name: query_feedback; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.query_feedback (id, session_id, run_id, query, generated_sql, pipeline, rating, comment, correction, created_at) FROM stdin;
\.


--
-- Data for Name: query_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.query_logs (id, query, response, domain, latency_ms, confidence, ragas_faithfulness, prompt_version, model, created_at) FROM stdin;
1	Annual leave policy details	All full-time employees are entitled to 24 days of paid annual leave per calendar year, accrues at 2 days per month, and unused leave can be carried forward up to 5 days into the next year. Leave requests must be submitted at least 2 weeks in advance for periods longer than 3 days.	HR	43811.78975105286	HIGH	\N	1	llama-3.3-70b-versatile	2026-05-09 12:31:29.204985
2	Show top 5 products by price	The top 5 products by price are:\n\nThe results show that the Laptop (SKU-LAPTOP-001) is the most expensive product at $899.99, followed by the Desk (SKU-DESK-001) at $549.99, and the Tablet (SKU-TABLET-001) at $499.99. The Chair (SKU-CHAIR-001) and Head Hat (SKU-HHAT-001) are significantly cheaper, priced at $349.99 and $24.99 respectively.	SQL	43409.56902503967		\N	\N	llama-3.1-8b-instant	2026-05-09 12:36:16.53135
3	leave policy and total employee count	The leave policy includes 12 days of paid sick leave, 16 weeks of paid maternity leave, 4 weeks of paid paternity leave, and 24 days of paid annual leave. However, I don't have enough information to answer the total employee count.	HR	44127.63690948486	MEDIUM	\N	1	llama-3.3-70b-versatile	2026-05-09 12:42:17.936954
4	What is the leave policy and show me total products by category?	Here's a concise explanation of the SQL results:\n\nThe top 5 categories with the most products are Electronics, Furniture, Safety Equipment, Packaging, and Food & Beverage, with Electronics having the most products at 3. This suggests that the warehouse has a strong focus on electronics and furniture products.	SQL	43489.6023273468		\N	\N	llama-3.1-8b-instant	2026-05-09 12:49:38.490005
\.


--
-- Data for Name: sales_order; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sales_order (id, order_number, customer_id, warehouse_id, status, priority, order_date, required_date, total_amount, shipping_method, created_at) FROM stdin;
1	SO-2024-001	1	1	DELIVERED	NORMAL	2024-09-20	2024-09-28	4500.00	UPS Ground	2026-05-09 11:49:55.735871
2	SO-2024-002	2	1	SHIPPED	HIGH	2024-10-01	2024-10-05	32500.00	FedEx Freight	2026-05-09 11:49:55.735871
3	SO-2024-003	3	2	PICKING	URGENT	2024-11-01	2024-11-04	55000.00	FedEx Express	2026-05-09 11:49:55.735871
4	SO-2024-004	1	1	PENDING	NORMAL	2024-11-08	2024-11-15	2100.00	USPS Priority	2026-05-09 11:49:55.735871
\.


--
-- Data for Name: sales_order_line; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sales_order_line (id, sales_order_id, product_id, quantity_ordered, quantity_shipped, unit_price) FROM stdin;
1	1	1	5	5	899.99
2	2	1	25	25	899.99
3	2	3	500	500	12.99
4	3	1	50	0	899.99
5	3	2	30	0	499.99
6	4	6	50	0	24.99
\.


--
-- Data for Name: schema_description; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.schema_description (id, table_name, column_name, domain, description, data_type, embedding_id, created_at) FROM stdin;
1	warehouse	\N	warehouse	Physical warehouse locations with capacity and active status	\N	\N	2026-05-09 11:49:55.684313
2	warehouse	code	warehouse	Unique warehouse identifier code like WH-EAST-01	VARCHAR(20)	\N	2026-05-09 11:49:55.684313
3	warehouse	capacity_sqft	warehouse	Total warehouse capacity in square feet	NUMERIC(12,2)	\N	2026-05-09 11:49:55.684313
4	zone	\N	warehouse	Storage zones within warehouses: RECEIVING, STORAGE, PICKING, SHIPPING, COLD_STORAGE, HAZMAT	\N	\N	2026-05-09 11:49:55.684313
5	zone	utilization_pct	warehouse	Current utilization percentage of the zone	NUMERIC(5,2)	\N	2026-05-09 11:49:55.684313
6	location	\N	warehouse	Physical storage locations (bins, racks, shelves) within zones	\N	\N	2026-05-09 11:49:55.684313
7	product	\N	product	Product catalog with SKU, pricing, weight, and reorder settings	\N	\N	2026-05-09 11:49:55.684313
8	product	unit_price	product	Selling price per unit of the product	NUMERIC(12,2)	\N	2026-05-09 11:49:55.684313
9	product	cost_price	product	Purchase/cost price from supplier	NUMERIC(12,2)	\N	2026-05-09 11:49:55.684313
10	product	reorder_point	product	Inventory level that triggers reorder	INTEGER	\N	2026-05-09 11:49:55.684313
11	category	\N	product	Product categories with hierarchical parent-child relationships	\N	\N	2026-05-09 11:49:55.684313
12	supplier	\N	procurement	Suppliers with contact info, lead time, and performance rating	\N	\N	2026-05-09 11:49:55.684313
13	supplier	lead_time_days	procurement	Average days for supplier to deliver orders	INTEGER	\N	2026-05-09 11:49:55.684313
14	supplier	rating	procurement	Supplier performance rating from 0.00 to 5.00	NUMERIC(3,2)	\N	2026-05-09 11:49:55.684313
15	inventory	\N	inventory	Current stock levels per product per location with lot tracking	\N	\N	2026-05-09 11:49:55.684313
16	inventory	quantity_on_hand	inventory	Total physical quantity in stock at location	INTEGER	\N	2026-05-09 11:49:55.684313
17	inventory	quantity_reserved	inventory	Quantity reserved for pending orders	INTEGER	\N	2026-05-09 11:49:55.684313
18	inventory	quantity_available	inventory	Available quantity (on_hand - reserved), computed column	INTEGER	\N	2026-05-09 11:49:55.684313
19	inventory_transaction	\N	inventory	Audit trail of all inventory movements: RECEIPT, PICK, TRANSFER, ADJUSTMENT, RETURN	\N	\N	2026-05-09 11:49:55.684313
20	purchase_order	\N	procurement	Purchase orders to suppliers with status: DRAFT, SUBMITTED, CONFIRMED, RECEIVED, CANCELLED	\N	\N	2026-05-09 11:49:55.684313
21	purchase_order	total_amount	procurement	Total monetary value of the purchase order	NUMERIC(14,2)	\N	2026-05-09 11:49:55.684313
22	purchase_order_line	\N	procurement	Line items in purchase orders with ordered vs received quantities	\N	\N	2026-05-09 11:49:55.684313
23	customer	\N	sales	Customer accounts: RETAIL, WHOLESALE, DISTRIBUTOR with credit limits	\N	\N	2026-05-09 11:49:55.684313
24	sales_order	\N	sales	Customer sales orders with status: PENDING, CONFIRMED, PICKING, SHIPPED, DELIVERED, CANCELLED	\N	\N	2026-05-09 11:49:55.684313
25	sales_order	priority	sales	Order priority: LOW, NORMAL, HIGH, URGENT	VARCHAR(10)	\N	2026-05-09 11:49:55.684313
26	sales_order	total_amount	sales	Total monetary value of the sales order	NUMERIC(14,2)	\N	2026-05-09 11:49:55.684313
27	sales_order_line	\N	sales	Line items in sales orders with ordered vs shipped quantities	\N	\N	2026-05-09 11:49:55.684313
28	shipment	\N	sales	Shipment tracking for sales orders with carrier and delivery info	\N	\N	2026-05-09 11:49:55.684313
29	shipment	status	sales	Shipment status: PENDING, IN_TRANSIT, DELIVERED	VARCHAR(20)	\N	2026-05-09 11:49:55.684313
\.


--
-- Data for Name: shipment; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.shipment (id, shipment_number, sales_order_id, carrier, tracking_number, status, shipped_date, delivered_date, created_at) FROM stdin;
1	SHP-001	1	UPS	1Z999AA10123456784	DELIVERED	2024-09-25 00:00:00	2024-09-27 00:00:00	2026-05-09 11:49:55.742325
2	SHP-002	2	FedEx	FX7890123456	IN_TRANSIT	2024-10-03 00:00:00	\N	2026-05-09 11:49:55.742325
\.


--
-- Data for Name: supplier; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.supplier (id, code, name, contact_name, email, phone, city, country, lead_time_days, rating) FROM stdin;
1	SUP-TECH	TechWave Electronics	David Park	david@techwave.com	\N	San Jose	USA	5	4.50
2	SUP-FURN	OfficeMax Furniture	Rachel Green	rachel@officemax.com	\N	Grand Rapids	USA	14	4.20
3	SUP-SAFE	SafeGuard Industries	Tom Bradley	tom@safeguard.com	\N	Cincinnati	USA	7	4.80
4	SUP-PACK	PackRight Solutions	Nina Patel	nina@packright.com	\N	Memphis	USA	3	4.60
5	SUP-FOOD	FreshChain Foods	Amy Wu	amy@freshchain.com	\N	Portland	USA	2	4.70
\.


--
-- Data for Name: warehouse; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.warehouse (id, code, name, city, state, capacity_sqft, is_active, created_at) FROM stdin;
1	WH-EAST-01	East Coast Distribution Center	Newark	NJ	250000.00	t	2026-05-09 11:49:55.691618
2	WH-WEST-01	West Coast Fulfillment Hub	Ontario	CA	320000.00	t	2026-05-09 11:49:55.691618
3	WH-CENT-01	Central Regional Warehouse	Dallas	TX	180000.00	t	2026-05-09 11:49:55.691618
\.


--
-- Data for Name: zone; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.zone (id, warehouse_id, code, name, zone_type, temperature_controlled, max_capacity_units, utilization_pct) FROM stdin;
1	1	RCV-01	Receiving Dock	RECEIVING	f	5000	45.00
2	1	STR-01	General Storage A	STORAGE	f	50000	72.00
3	1	STR-02	Cold Storage	COLD_STORAGE	f	10000	55.00
4	1	PCK-01	Picking Zone	PICKING	f	8000	60.00
5	1	SHP-01	Shipping Dock	SHIPPING	f	3000	35.00
6	2	STR-01	Main Storage	STORAGE	f	80000	78.00
7	2	PCK-01	Pick & Pack	PICKING	f	12000	65.00
8	3	STR-01	Primary Storage	STORAGE	f	40000	82.00
\.


--
-- Name: category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.category_id_seq', 5, true);


--
-- Name: conversation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.conversation_id_seq', 4, true);


--
-- Name: customer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.customer_id_seq', 4, true);


--
-- Name: inventory_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.inventory_id_seq', 13, true);


--
-- Name: inventory_transaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.inventory_transaction_id_seq', 5, true);


--
-- Name: location_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.location_id_seq', 9, true);


--
-- Name: product_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.product_id_seq', 10, true);


--
-- Name: prompt_template_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.prompt_template_id_seq', 12, true);


--
-- Name: purchase_order_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.purchase_order_id_seq', 4, true);


--
-- Name: purchase_order_line_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.purchase_order_line_id_seq', 6, true);


--
-- Name: query_feedback_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.query_feedback_id_seq', 1, false);


--
-- Name: query_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.query_logs_id_seq', 4, true);


--
-- Name: sales_order_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.sales_order_id_seq', 4, true);


--
-- Name: sales_order_line_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.sales_order_line_id_seq', 6, true);


--
-- Name: schema_description_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.schema_description_id_seq', 29, true);


--
-- Name: shipment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.shipment_id_seq', 2, true);


--
-- Name: supplier_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.supplier_id_seq', 5, true);


--
-- Name: warehouse_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.warehouse_id_seq', 3, true);


--
-- Name: zone_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.zone_id_seq', 8, true);


--
-- Name: category category_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.category
    ADD CONSTRAINT category_pkey PRIMARY KEY (id);


--
-- Name: checkpoint_blobs checkpoint_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.checkpoint_blobs
    ADD CONSTRAINT checkpoint_blobs_pkey PRIMARY KEY (thread_id, checkpoint_ns, channel, version);


--
-- Name: checkpoint_migrations checkpoint_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.checkpoint_migrations
    ADD CONSTRAINT checkpoint_migrations_pkey PRIMARY KEY (v);


--
-- Name: checkpoint_writes checkpoint_writes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.checkpoint_writes
    ADD CONSTRAINT checkpoint_writes_pkey PRIMARY KEY (thread_id, checkpoint_ns, checkpoint_id, task_id, idx);


--
-- Name: checkpoints checkpoints_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.checkpoints
    ADD CONSTRAINT checkpoints_pkey PRIMARY KEY (thread_id, checkpoint_ns, checkpoint_id);


--
-- Name: conversation conversation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation
    ADD CONSTRAINT conversation_pkey PRIMARY KEY (id);


--
-- Name: conversation_summary conversation_summary_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_summary
    ADD CONSTRAINT conversation_summary_pkey PRIMARY KEY (session_id);


--
-- Name: customer customer_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_code_key UNIQUE (code);


--
-- Name: customer customer_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (id);


--
-- Name: inventory inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_pkey PRIMARY KEY (id);


--
-- Name: inventory inventory_product_id_location_id_lot_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_product_id_location_id_lot_number_key UNIQUE (product_id, location_id, lot_number);


--
-- Name: inventory_transaction inventory_transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_transaction
    ADD CONSTRAINT inventory_transaction_pkey PRIMARY KEY (id);


--
-- Name: location location_barcode_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location
    ADD CONSTRAINT location_barcode_key UNIQUE (barcode);


--
-- Name: location location_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location
    ADD CONSTRAINT location_pkey PRIMARY KEY (id);


--
-- Name: product product_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product
    ADD CONSTRAINT product_pkey PRIMARY KEY (id);


--
-- Name: product product_sku_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product
    ADD CONSTRAINT product_sku_key UNIQUE (sku);


--
-- Name: prompt_template prompt_template_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prompt_template
    ADD CONSTRAINT prompt_template_name_key UNIQUE (name);


--
-- Name: prompt_template prompt_template_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prompt_template
    ADD CONSTRAINT prompt_template_pkey PRIMARY KEY (id);


--
-- Name: purchase_order_line purchase_order_line_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_order_line
    ADD CONSTRAINT purchase_order_line_pkey PRIMARY KEY (id);


--
-- Name: purchase_order purchase_order_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_order
    ADD CONSTRAINT purchase_order_pkey PRIMARY KEY (id);


--
-- Name: purchase_order purchase_order_po_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_order
    ADD CONSTRAINT purchase_order_po_number_key UNIQUE (po_number);


--
-- Name: query_feedback query_feedback_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.query_feedback
    ADD CONSTRAINT query_feedback_pkey PRIMARY KEY (id);


--
-- Name: query_logs query_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.query_logs
    ADD CONSTRAINT query_logs_pkey PRIMARY KEY (id);


--
-- Name: sales_order_line sales_order_line_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_order_line
    ADD CONSTRAINT sales_order_line_pkey PRIMARY KEY (id);


--
-- Name: sales_order sales_order_order_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_order
    ADD CONSTRAINT sales_order_order_number_key UNIQUE (order_number);


--
-- Name: sales_order sales_order_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_order
    ADD CONSTRAINT sales_order_pkey PRIMARY KEY (id);


--
-- Name: schema_description schema_description_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_description
    ADD CONSTRAINT schema_description_pkey PRIMARY KEY (id);


--
-- Name: shipment shipment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shipment
    ADD CONSTRAINT shipment_pkey PRIMARY KEY (id);


--
-- Name: shipment shipment_shipment_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shipment
    ADD CONSTRAINT shipment_shipment_number_key UNIQUE (shipment_number);


--
-- Name: supplier supplier_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supplier
    ADD CONSTRAINT supplier_code_key UNIQUE (code);


--
-- Name: supplier supplier_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supplier
    ADD CONSTRAINT supplier_pkey PRIMARY KEY (id);


--
-- Name: warehouse warehouse_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse
    ADD CONSTRAINT warehouse_code_key UNIQUE (code);


--
-- Name: warehouse warehouse_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse
    ADD CONSTRAINT warehouse_pkey PRIMARY KEY (id);


--
-- Name: zone zone_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zone
    ADD CONSTRAINT zone_pkey PRIMARY KEY (id);


--
-- Name: zone zone_warehouse_id_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zone
    ADD CONSTRAINT zone_warehouse_id_code_key UNIQUE (warehouse_id, code);


--
-- Name: checkpoint_blobs_thread_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX checkpoint_blobs_thread_id_idx ON public.checkpoint_blobs USING btree (thread_id);


--
-- Name: checkpoint_writes_thread_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX checkpoint_writes_thread_id_idx ON public.checkpoint_writes USING btree (thread_id);


--
-- Name: checkpoints_thread_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX checkpoints_thread_id_idx ON public.checkpoints USING btree (thread_id);


--
-- Name: idx_conv_session; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_conv_session ON public.conversation USING btree (session_id);


--
-- Name: idx_feedback_rating; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_feedback_rating ON public.query_feedback USING btree (rating);


--
-- Name: idx_feedback_session; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_feedback_session ON public.query_feedback USING btree (session_id);


--
-- Name: idx_schema_domain; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_schema_domain ON public.schema_description USING btree (domain);


--
-- Name: idx_schema_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_schema_fts ON public.schema_description USING gin (to_tsvector('english'::regconfig, ((((description || ' '::text) || (table_name)::text) || ' '::text) || (COALESCE(column_name, ''::character varying))::text)));


--
-- Name: category category_parent_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.category
    ADD CONSTRAINT category_parent_category_id_fkey FOREIGN KEY (parent_category_id) REFERENCES public.category(id);


--
-- Name: inventory inventory_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.location(id);


--
-- Name: inventory inventory_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.product(id);


--
-- Name: inventory_transaction inventory_transaction_from_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_transaction
    ADD CONSTRAINT inventory_transaction_from_location_id_fkey FOREIGN KEY (from_location_id) REFERENCES public.location(id);


--
-- Name: inventory_transaction inventory_transaction_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_transaction
    ADD CONSTRAINT inventory_transaction_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.product(id);


--
-- Name: inventory_transaction inventory_transaction_to_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_transaction
    ADD CONSTRAINT inventory_transaction_to_location_id_fkey FOREIGN KEY (to_location_id) REFERENCES public.location(id);


--
-- Name: location location_zone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location
    ADD CONSTRAINT location_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES public.zone(id);


--
-- Name: product product_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product
    ADD CONSTRAINT product_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.category(id);


--
-- Name: product product_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product
    ADD CONSTRAINT product_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.supplier(id);


--
-- Name: purchase_order_line purchase_order_line_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_order_line
    ADD CONSTRAINT purchase_order_line_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.product(id);


--
-- Name: purchase_order_line purchase_order_line_purchase_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_order_line
    ADD CONSTRAINT purchase_order_line_purchase_order_id_fkey FOREIGN KEY (purchase_order_id) REFERENCES public.purchase_order(id) ON DELETE CASCADE;


--
-- Name: purchase_order purchase_order_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_order
    ADD CONSTRAINT purchase_order_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.supplier(id);


--
-- Name: purchase_order purchase_order_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_order
    ADD CONSTRAINT purchase_order_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouse(id);


--
-- Name: sales_order sales_order_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_order
    ADD CONSTRAINT sales_order_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(id);


--
-- Name: sales_order_line sales_order_line_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_order_line
    ADD CONSTRAINT sales_order_line_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.product(id);


--
-- Name: sales_order_line sales_order_line_sales_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_order_line
    ADD CONSTRAINT sales_order_line_sales_order_id_fkey FOREIGN KEY (sales_order_id) REFERENCES public.sales_order(id) ON DELETE CASCADE;


--
-- Name: sales_order sales_order_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_order
    ADD CONSTRAINT sales_order_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouse(id);


--
-- Name: shipment shipment_sales_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shipment
    ADD CONSTRAINT shipment_sales_order_id_fkey FOREIGN KEY (sales_order_id) REFERENCES public.sales_order(id);


--
-- Name: zone zone_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zone
    ADD CONSTRAINT zone_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouse(id);


--
-- PostgreSQL database dump complete
--

\unrestrict 4vC5Mds55TXQebSVTCUHuGepZtlETenXxbtpILu4j2aBYzlzBtMudixsS7UWHmx

