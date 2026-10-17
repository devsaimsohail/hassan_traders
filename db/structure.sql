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

--
-- Name: activity_logs_append_only(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.activity_logs_append_only() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  RAISE EXCEPTION 'activity_logs is append-only';
END;
$$;


--
-- Name: append_only_row(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.append_only_row() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  RAISE EXCEPTION '% is append-only', TG_TABLE_NAME;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- Name: activity_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_logs (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    user_id bigint,
    user_name character varying,
    role character varying,
    action character varying NOT NULL,
    section character varying NOT NULL,
    ref character varying,
    detail character varying NOT NULL,
    old_value jsonb,
    new_value jsonb,
    device character varying,
    ip character varying,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: activity_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.activity_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.activity_logs_id_seq OWNED BY public.activity_logs.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: companies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.companies (
    id bigint NOT NULL,
    name character varying NOT NULL,
    legal_name character varying,
    ntn character varying,
    strn character varying,
    address character varying,
    city character varying,
    phone character varying,
    mobile character varying,
    email character varying,
    brand_color character varying DEFAULT '#0F766E'::character varying NOT NULL,
    currency character varying DEFAULT 'PKR'::character varying NOT NULL,
    fiscal_year_start character varying DEFAULT '1 July'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: companies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.companies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: companies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.companies_id_seq OWNED BY public.companies.id;


--
-- Name: items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.items (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    code character varying NOT NULL,
    name character varying NOT NULL,
    category character varying NOT NULL,
    unit character varying NOT NULL,
    rate numeric(12,2) DEFAULT 0.0 NOT NULL,
    sale_price integer,
    reorder_level numeric(12,3) DEFAULT 0.0 NOT NULL,
    opening_qty numeric(12,3) DEFAULT 0.0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    last_purchase_rate numeric(12,2),
    last_purchase_on date,
    default_supplier_id bigint,
    CONSTRAINT items_category CHECK (((category)::text = ANY ((ARRAY['raw_material'::character varying, 'product'::character varying])::text[])))
);


--
-- Name: items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.items_id_seq OWNED BY public.items.id;


--
-- Name: purchase_order_lines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purchase_order_lines (
    id bigint NOT NULL,
    purchase_order_id bigint NOT NULL,
    item_id bigint NOT NULL,
    qty numeric(12,3) NOT NULL,
    rate numeric(12,2) NOT NULL,
    amount integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT purchase_order_lines_qty_positive CHECK ((qty > (0)::numeric)),
    CONSTRAINT purchase_order_lines_rate CHECK ((rate >= (0)::numeric))
);


--
-- Name: purchase_order_lines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.purchase_order_lines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: purchase_order_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.purchase_order_lines_id_seq OWNED BY public.purchase_order_lines.id;


--
-- Name: purchase_orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purchase_orders (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    supplier_id bigint NOT NULL,
    number character varying NOT NULL,
    date date NOT NULL,
    status character varying DEFAULT 'draft'::character varying NOT NULL,
    total integer DEFAULT 0 NOT NULL,
    note character varying,
    created_by_id bigint NOT NULL,
    approved_by_id bigint,
    approved_at timestamp(6) without time zone,
    received_by_id bigint,
    received_on date,
    cancelled_by_id bigint,
    cancelled_at timestamp(6) without time zone,
    cancel_reason character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT purchase_orders_status CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'pending_approval'::character varying, 'approved'::character varying, 'received'::character varying, 'cancelled'::character varying])::text[])))
);


--
-- Name: purchase_orders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.purchase_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: purchase_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.purchase_orders_id_seq OWNED BY public.purchase_orders.id;


--
-- Name: role_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.role_permissions (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    role character varying NOT NULL,
    permission character varying NOT NULL,
    level character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: role_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.role_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: role_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.role_permissions_id_seq OWNED BY public.role_permissions.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id bigint NOT NULL,
    name character varying NOT NULL,
    resource_type character varying,
    resource_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: stock_moves; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stock_moves (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    item_id bigint NOT NULL,
    user_id bigint,
    date date NOT NULL,
    direction character varying NOT NULL,
    reason character varying NOT NULL,
    qty numeric(12,3) NOT NULL,
    ref character varying,
    note character varying,
    created_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT stock_moves_direction CHECK (((direction)::text = ANY ((ARRAY['in'::character varying, 'out'::character varying])::text[]))),
    CONSTRAINT stock_moves_qty_positive CHECK ((qty > (0)::numeric))
);


--
-- Name: stock_moves_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stock_moves_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stock_moves_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stock_moves_id_seq OWNED BY public.stock_moves.id;


--
-- Name: supplier_payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.supplier_payments (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    supplier_id bigint NOT NULL,
    purchase_order_id bigint,
    date date NOT NULL,
    amount integer NOT NULL,
    method character varying NOT NULL,
    ref character varying,
    user_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT supplier_payments_amount_positive CHECK ((amount > 0))
);


--
-- Name: supplier_payments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.supplier_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: supplier_payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.supplier_payments_id_seq OWNED BY public.supplier_payments.id;


--
-- Name: suppliers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.suppliers (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    code character varying NOT NULL,
    name character varying NOT NULL,
    city character varying,
    phone character varying,
    supplies character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: suppliers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.suppliers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: suppliers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.suppliers_id_seq OWNED BY public.suppliers.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    name character varying NOT NULL,
    mobile character varying NOT NULL,
    email character varying,
    city character varying,
    encrypted_password character varying NOT NULL,
    must_change_password boolean DEFAULT false NOT NULL,
    failed_attempts integer DEFAULT 0 NOT NULL,
    locked_at timestamp(6) without time zone,
    current_sign_in_at timestamp(6) without time zone,
    last_device character varying,
    disabled_at timestamp(6) without time zone,
    disabled_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    last_sign_in_at timestamp(6) without time zone,
    current_sign_in_ip character varying,
    last_sign_in_ip character varying,
    sign_in_count integer DEFAULT 0 NOT NULL,
    remember_created_at timestamp(6) without time zone
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: users_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users_roles (
    user_id bigint NOT NULL,
    role_id bigint NOT NULL
);


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: activity_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_logs ALTER COLUMN id SET DEFAULT nextval('public.activity_logs_id_seq'::regclass);


--
-- Name: companies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.companies ALTER COLUMN id SET DEFAULT nextval('public.companies_id_seq'::regclass);


--
-- Name: items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items ALTER COLUMN id SET DEFAULT nextval('public.items_id_seq'::regclass);


--
-- Name: purchase_order_lines id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_order_lines ALTER COLUMN id SET DEFAULT nextval('public.purchase_order_lines_id_seq'::regclass);


--
-- Name: purchase_orders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_orders ALTER COLUMN id SET DEFAULT nextval('public.purchase_orders_id_seq'::regclass);


--
-- Name: role_permissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permissions ALTER COLUMN id SET DEFAULT nextval('public.role_permissions_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: stock_moves id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_moves ALTER COLUMN id SET DEFAULT nextval('public.stock_moves_id_seq'::regclass);


--
-- Name: supplier_payments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supplier_payments ALTER COLUMN id SET DEFAULT nextval('public.supplier_payments_id_seq'::regclass);


--
-- Name: suppliers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppliers ALTER COLUMN id SET DEFAULT nextval('public.suppliers_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: activity_logs activity_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: companies companies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_pkey PRIMARY KEY (id);


--
-- Name: items items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: purchase_order_lines purchase_order_lines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_order_lines
    ADD CONSTRAINT purchase_order_lines_pkey PRIMARY KEY (id);


--
-- Name: purchase_orders purchase_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT purchase_orders_pkey PRIMARY KEY (id);


--
-- Name: role_permissions role_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: stock_moves stock_moves_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_moves
    ADD CONSTRAINT stock_moves_pkey PRIMARY KEY (id);


--
-- Name: supplier_payments supplier_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supplier_payments
    ADD CONSTRAINT supplier_payments_pkey PRIMARY KEY (id);


--
-- Name: suppliers suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_activity_logs_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_logs_on_company_id ON public.activity_logs USING btree (company_id);


--
-- Name: index_activity_logs_on_company_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_logs_on_company_id_and_created_at ON public.activity_logs USING btree (company_id, created_at);


--
-- Name: index_activity_logs_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_logs_on_user_id ON public.activity_logs USING btree (user_id);


--
-- Name: index_items_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_items_on_company_id ON public.items USING btree (company_id);


--
-- Name: index_items_on_company_id_and_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_items_on_company_id_and_code ON public.items USING btree (company_id, code);


--
-- Name: index_items_on_company_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_items_on_company_id_and_name ON public.items USING btree (company_id, name);


--
-- Name: index_items_on_default_supplier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_items_on_default_supplier_id ON public.items USING btree (default_supplier_id);


--
-- Name: index_purchase_order_lines_on_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_order_lines_on_item_id ON public.purchase_order_lines USING btree (item_id);


--
-- Name: index_purchase_order_lines_on_purchase_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_order_lines_on_purchase_order_id ON public.purchase_order_lines USING btree (purchase_order_id);


--
-- Name: index_purchase_orders_on_approved_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_orders_on_approved_by_id ON public.purchase_orders USING btree (approved_by_id);


--
-- Name: index_purchase_orders_on_cancelled_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_orders_on_cancelled_by_id ON public.purchase_orders USING btree (cancelled_by_id);


--
-- Name: index_purchase_orders_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_orders_on_company_id ON public.purchase_orders USING btree (company_id);


--
-- Name: index_purchase_orders_on_company_id_and_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_orders_on_company_id_and_date ON public.purchase_orders USING btree (company_id, date);


--
-- Name: index_purchase_orders_on_company_id_and_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_purchase_orders_on_company_id_and_number ON public.purchase_orders USING btree (company_id, number);


--
-- Name: index_purchase_orders_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_orders_on_created_by_id ON public.purchase_orders USING btree (created_by_id);


--
-- Name: index_purchase_orders_on_received_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_orders_on_received_by_id ON public.purchase_orders USING btree (received_by_id);


--
-- Name: index_purchase_orders_on_supplier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_orders_on_supplier_id ON public.purchase_orders USING btree (supplier_id);


--
-- Name: index_role_permissions_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_role_permissions_on_company_id ON public.role_permissions USING btree (company_id);


--
-- Name: index_role_permissions_on_company_id_and_role_and_permission; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_role_permissions_on_company_id_and_role_and_permission ON public.role_permissions USING btree (company_id, role, permission);


--
-- Name: index_roles_on_name_and_resource_type_and_resource_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_roles_on_name_and_resource_type_and_resource_id ON public.roles USING btree (name, resource_type, resource_id);


--
-- Name: index_roles_on_resource; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_resource ON public.roles USING btree (resource_type, resource_id);


--
-- Name: index_stock_moves_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stock_moves_on_company_id ON public.stock_moves USING btree (company_id);


--
-- Name: index_stock_moves_on_company_id_and_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stock_moves_on_company_id_and_date ON public.stock_moves USING btree (company_id, date);


--
-- Name: index_stock_moves_on_company_id_and_ref; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stock_moves_on_company_id_and_ref ON public.stock_moves USING btree (company_id, ref);


--
-- Name: index_stock_moves_on_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stock_moves_on_item_id ON public.stock_moves USING btree (item_id);


--
-- Name: index_stock_moves_on_item_id_and_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stock_moves_on_item_id_and_date ON public.stock_moves USING btree (item_id, date);


--
-- Name: index_stock_moves_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stock_moves_on_user_id ON public.stock_moves USING btree (user_id);


--
-- Name: index_supplier_payments_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_supplier_payments_on_company_id ON public.supplier_payments USING btree (company_id);


--
-- Name: index_supplier_payments_on_purchase_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_supplier_payments_on_purchase_order_id ON public.supplier_payments USING btree (purchase_order_id);


--
-- Name: index_supplier_payments_on_supplier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_supplier_payments_on_supplier_id ON public.supplier_payments USING btree (supplier_id);


--
-- Name: index_supplier_payments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_supplier_payments_on_user_id ON public.supplier_payments USING btree (user_id);


--
-- Name: index_suppliers_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_suppliers_on_company_id ON public.suppliers USING btree (company_id);


--
-- Name: index_suppliers_on_company_id_and_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_suppliers_on_company_id_and_code ON public.suppliers USING btree (company_id, code);


--
-- Name: index_suppliers_on_company_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_suppliers_on_company_id_and_name ON public.suppliers USING btree (company_id, name);


--
-- Name: index_users_on_disabled_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_disabled_by_id ON public.users USING btree (disabled_by_id);


--
-- Name: index_users_on_mobile; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_mobile ON public.users USING btree (mobile);


--
-- Name: index_users_roles_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_roles_on_role_id ON public.users_roles USING btree (role_id);


--
-- Name: index_users_roles_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_roles_on_user_id ON public.users_roles USING btree (user_id);


--
-- Name: index_users_roles_on_user_id_and_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_roles_on_user_id_and_role_id ON public.users_roles USING btree (user_id, role_id);


--
-- Name: activity_logs activity_logs_append_only; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER activity_logs_append_only BEFORE DELETE OR UPDATE ON public.activity_logs FOR EACH ROW EXECUTE FUNCTION public.activity_logs_append_only();


--
-- Name: stock_moves stock_moves_append_only; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER stock_moves_append_only BEFORE DELETE OR UPDATE ON public.stock_moves FOR EACH ROW EXECUTE FUNCTION public.append_only_row();


--
-- Name: supplier_payments supplier_payments_append_only; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER supplier_payments_append_only BEFORE DELETE OR UPDATE ON public.supplier_payments FOR EACH ROW EXECUTE FUNCTION public.append_only_row();


--
-- Name: supplier_payments fk_rails_1846f352d5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supplier_payments
    ADD CONSTRAINT fk_rails_1846f352d5 FOREIGN KEY (supplier_id) REFERENCES public.suppliers(id);


--
-- Name: purchase_orders fk_rails_1d67bb2d7b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT fk_rails_1d67bb2d7b FOREIGN KEY (supplier_id) REFERENCES public.suppliers(id);


--
-- Name: supplier_payments fk_rails_2c224002a2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supplier_payments
    ADD CONSTRAINT fk_rails_2c224002a2 FOREIGN KEY (purchase_order_id) REFERENCES public.purchase_orders(id);


--
-- Name: purchase_orders fk_rails_3079d73660; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT fk_rails_3079d73660 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: purchase_orders fk_rails_3c1ce09582; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT fk_rails_3c1ce09582 FOREIGN KEY (approved_by_id) REFERENCES public.users(id);


--
-- Name: stock_moves fk_rails_453272e40c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_moves
    ADD CONSTRAINT fk_rails_453272e40c FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: users_roles fk_rails_4a41696df6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_roles
    ADD CONSTRAINT fk_rails_4a41696df6 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: items fk_rails_4bcb302629; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT fk_rails_4bcb302629 FOREIGN KEY (default_supplier_id) REFERENCES public.suppliers(id);


--
-- Name: stock_moves fk_rails_525bab533d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_moves
    ADD CONSTRAINT fk_rails_525bab533d FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: supplier_payments fk_rails_53508e4704; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supplier_payments
    ADD CONSTRAINT fk_rails_53508e4704 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: purchase_orders fk_rails_7139e543c2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT fk_rails_7139e543c2 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: purchase_order_lines fk_rails_7b2f871d0c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_order_lines
    ADD CONSTRAINT fk_rails_7b2f871d0c FOREIGN KEY (item_id) REFERENCES public.items(id);


--
-- Name: role_permissions fk_rails_81b1f496e0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT fk_rails_81b1f496e0 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: supplier_payments fk_rails_9ab47cc64a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supplier_payments
    ADD CONSTRAINT fk_rails_9ab47cc64a FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: purchase_order_lines fk_rails_a4215877c0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_order_lines
    ADD CONSTRAINT fk_rails_a4215877c0 FOREIGN KEY (purchase_order_id) REFERENCES public.purchase_orders(id);


--
-- Name: items fk_rails_ad750f090b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT fk_rails_ad750f090b FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: purchase_orders fk_rails_ae534c0277; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT fk_rails_ae534c0277 FOREIGN KEY (cancelled_by_id) REFERENCES public.users(id);


--
-- Name: stock_moves fk_rails_c219f986cb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_moves
    ADD CONSTRAINT fk_rails_c219f986cb FOREIGN KEY (item_id) REFERENCES public.items(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: users fk_rails_c7f53866d3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_c7f53866d3 FOREIGN KEY (disabled_by_id) REFERENCES public.users(id);


--
-- Name: activity_logs fk_rails_c9badf82db; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT fk_rails_c9badf82db FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: suppliers fk_rails_cfcc7596f6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT fk_rails_cfcc7596f6 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: activity_logs fk_rails_d714aa4e44; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT fk_rails_d714aa4e44 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: purchase_orders fk_rails_d79cad4235; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT fk_rails_d79cad4235 FOREIGN KEY (received_by_id) REFERENCES public.users(id);


--
-- Name: users_roles fk_rails_eb7b4658f8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_roles
    ADD CONSTRAINT fk_rails_eb7b4658f8 FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20261018000010'),
('20261018000009'),
('20261018000008'),
('20261018000007'),
('20261018000006'),
('20261018000005'),
('20261018000003'),
('20261018000002'),
('20261018000001'),
('20261017215508');

