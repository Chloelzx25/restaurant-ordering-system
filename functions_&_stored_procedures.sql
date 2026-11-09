--
-- PostgreSQL database dump
--

\restrict 8YVdNdY5fK6kaokwZRFkRhgdn14Dx2K51D50z0QEZqkYU7iuY11gxI3qURDa7OV

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

-- Started on 2026-07-01 10:07:45

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 244 (class 1255 OID 17308)
-- Name: create_feedback(integer, integer, integer, smallint, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_feedback(p_member_id integer, p_product_id integer, p_sale_order_id integer, p_rating smallint, p_comment text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_role        TEXT;
    v_status      TEXT;
    v_item_exists BOOLEAN;
BEGIN
    -- Check member exists and is a USER
    SELECT role INTO v_role
    FROM member_role
    WHERE member_id = p_member_id;

    IF NOT FOUND THEN
        RETURN 'ERROR: Member not found.';
    END IF;

    IF v_role != 'USER' THEN
        RETURN 'ERROR: Only customers (USER role) can submit feedback.';
    END IF;

    -- Check product exists
    IF NOT EXISTS (SELECT 1 FROM product WHERE product_id = p_product_id) THEN
        RETURN 'ERROR: Product not found.';
    END IF;

    -- Check order exists, belongs to member, and get status
    SELECT status INTO v_status
    FROM sale_order
    WHERE order_id = p_sale_order_id
      AND member_id = p_member_id;

    IF NOT FOUND THEN
        RETURN 'ERROR: Order not found or does not belong to you.';
    END IF;

    -- Check order is COMPLETED
    IF v_status != 'COMPLETED' THEN
        RETURN 'ERROR: Feedback can only be submitted for completed orders.';
    END IF;

    -- Check product was in that order
    SELECT EXISTS (
        SELECT 1 FROM sale_order_item
        WHERE order_id = p_sale_order_id
          AND product_id = p_product_id
    ) INTO v_item_exists;

    IF NOT v_item_exists THEN
        RETURN 'ERROR: You did not order this product in the specified order.';
    END IF;

    -- Validate rating
    IF p_rating < 1 OR p_rating > 5 THEN
        RETURN 'ERROR: Rating must be between 1 and 5.';
    END IF;

    -- Validate comment
    IF TRIM(p_comment) = '' THEN
        RETURN 'ERROR: Comment cannot be empty.';
    END IF;

    -- Check for duplicate feedback
    IF EXISTS (
        SELECT 1 FROM feedback
        WHERE member_id = p_member_id
          AND product_id = p_product_id
          AND sale_order_id = p_sale_order_id
    ) THEN
        RETURN 'ERROR: You have already submitted feedback for this product in this order.';
    END IF;

    -- Insert feedback
    INSERT INTO feedback (member_id, product_id, sale_order_id, rating, comment, created_at, updated_at)
    VALUES (p_member_id, p_product_id, p_sale_order_id, p_rating, TRIM(p_comment), NOW(), NOW());

    RETURN 'SUCCESS: Feedback submitted successfully.';

EXCEPTION
    WHEN OTHERS THEN
        RETURN 'ERROR: An unexpected error occurred: ' || SQLERRM;
END;
$$;


--
-- TOC entry 247 (class 1255 OID 17312)
-- Name: create_response(integer, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_response(p_feedback_id integer, p_member_id integer, p_comment text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_feedback_author INTEGER;
    v_role            TEXT;
BEGIN
    -- Check member exists and is a USER
    SELECT role INTO v_role
    FROM member_role
    WHERE member_id = p_member_id;

    IF NOT FOUND THEN
        RETURN 'ERROR: Member not found.';
    END IF;

    IF v_role != 'USER' THEN
        RETURN 'ERROR: Only customers (USER role) can submit responses.';
    END IF;

    -- Check feedback exists and get its author
    SELECT member_id INTO v_feedback_author
    FROM feedback
    WHERE feedback_id = p_feedback_id;

    IF NOT FOUND THEN
        RETURN 'ERROR: Feedback not found.';
    END IF;

    -- Prevent author from responding to their own feedback
    IF v_feedback_author = p_member_id THEN
        RETURN 'ERROR: You cannot respond to your own feedback.';
    END IF;

    -- Validate comment
    IF TRIM(p_comment) = '' THEN
        RETURN 'ERROR: Response comment cannot be empty.';
    END IF;

    -- Insert response
    INSERT INTO feedback_response (feedback_id, member_id, comment, created_at)
    VALUES (p_feedback_id, p_member_id, TRIM(p_comment), NOW());

    RETURN 'SUCCESS: Response submitted successfully.';

EXCEPTION
    WHEN OTHERS THEN
        RETURN 'ERROR: An unexpected error occurred: ' || SQLERRM;
END;
$$;


--
-- TOC entry 246 (class 1255 OID 17310)
-- Name: delete_feedback(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_feedback(p_feedback_id integer, p_member_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_owner INTEGER;
BEGIN
    -- Check feedback exists
    SELECT member_id INTO v_owner
    FROM feedback
    WHERE feedback_id = p_feedback_id;

    IF NOT FOUND THEN
        RETURN 'ERROR: Feedback not found.';
    END IF;

    -- Check ownership
    IF v_owner != p_member_id THEN
        RETURN 'ERROR: You can only delete your own feedback.';
    END IF;

    -- Delete (responses cascade automatically due to ON DELETE CASCADE)
    DELETE FROM feedback WHERE feedback_id = p_feedback_id;

    RETURN 'SUCCESS: Feedback deleted successfully.';

EXCEPTION
    WHEN OTHERS THEN
        RETURN 'ERROR: An unexpected error occurred: ' || SQLERRM;
END;
$$;


--
-- TOC entry 249 (class 1255 OID 17314)
-- Name: delete_response(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_response(p_response_id integer, p_member_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_owner INTEGER;
BEGIN
    -- Check response exists
    SELECT member_id INTO v_owner
    FROM feedback_response
    WHERE response_id = p_response_id;

    IF NOT FOUND THEN
        RETURN 'ERROR: Response not found.';
    END IF;

    -- Check ownership
    IF v_owner != p_member_id THEN
        RETURN 'ERROR: You can only delete your own responses.';
    END IF;

    -- Delete
    DELETE FROM feedback_response WHERE response_id = p_response_id;

    RETURN 'SUCCESS: Response deleted successfully.';

EXCEPTION
    WHEN OTHERS THEN
        RETURN 'ERROR: An unexpected error occurred: ' || SQLERRM;
END;
$$;


--
-- TOC entry 232 (class 1255 OID 17311)
-- Name: get_feedback(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_feedback(p_member_id integer) RETURNS TABLE(feedback_id integer, product_id integer, product_name text, rating smallint, comment text, updated_at timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM member WHERE member_id = p_member_id) THEN
        RAISE EXCEPTION 'Member not found.';
    END IF;

    RETURN QUERY
    SELECT
        f.feedback_id,
        f.product_id,
        p.name::TEXT AS product_name,
        f.rating,
        f.comment,
        f.updated_at
    FROM feedback f
    JOIN product p ON f.product_id = p.product_id
    WHERE f.member_id = p_member_id
    ORDER BY f.updated_at DESC;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'An unexpected error occurred: %', SQLERRM;
END;
$$;


--
-- TOC entry 248 (class 1255 OID 17313)
-- Name: get_response(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_response(p_feedback_id integer) RETURNS TABLE(response_id integer, member_id integer, username text, comment text, created_at timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM feedback WHERE feedback_id = p_feedback_id) THEN
        RAISE EXCEPTION 'Feedback not found.';
    END IF;

    RETURN QUERY
    SELECT
        fr.response_id,
        fr.member_id,
        m.username::TEXT,
        fr.comment,
        fr.created_at
    FROM feedback_response fr
    JOIN member m ON fr.member_id = m.member_id
    WHERE fr.feedback_id = p_feedback_id
    ORDER BY fr.created_at ASC;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'An unexpected error occurred: %', SQLERRM;
END;
$$;


--
-- TOC entry 250 (class 1255 OID 17315)
-- Name: get_sale_order_summary(date, date, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_sale_order_summary(p_start_date date DEFAULT NULL::date, p_end_date date DEFAULT NULL::date, p_category text DEFAULT NULL::text, p_sort_by text DEFAULT 'order_date'::text, p_sort_order text DEFAULT 'DESC'::text) RETURNS TABLE(order_id integer, customer_name text, order_date timestamp without time zone, total_amount numeric, status text, product_count bigint, products_ordered text)
    LANGUAGE plpgsql
    AS $_$
DECLARE
    v_sort_by    TEXT;
    v_sort_order TEXT;
    v_sql        TEXT;
BEGIN
    -- Whitelist sort column to prevent SQL injection
    v_sort_by := CASE p_sort_by
        WHEN 'total_amount'  THEN 'so.total_amount'
        WHEN 'customer_name' THEN 'customer_name'
        WHEN 'status'        THEN 'so.status'
        ELSE 'so.order_date'
    END;

    -- Whitelist sort order
    v_sort_order := CASE UPPER(p_sort_order)
        WHEN 'ASC' THEN 'ASC'
        ELSE 'DESC'
    END;

    v_sql := format('
        SELECT
            so.order_id,
            (m.first_name || '' '' || m.last_name)::TEXT AS customer_name,
            so.order_date,
            so.total_amount,
            so.status::TEXT,
            COUNT(soi.product_id)          AS product_count,
            STRING_AGG(p.name, '', '')     AS products_ordered
        FROM sale_order so
        JOIN member          m   ON so.member_id   = m.member_id
        JOIN sale_order_item soi ON so.order_id    = soi.order_id
        JOIN product         p   ON soi.product_id = p.product_id
        WHERE ($1 IS NULL OR so.order_date >= $1)
          AND ($2 IS NULL OR so.order_date <= ($2::DATE + INTERVAL ''1 day''))
          AND ($3 IS NULL OR p.category = $3)
        GROUP BY so.order_id, customer_name, so.order_date, so.total_amount, so.status
        ORDER BY %s %s
    ', v_sort_by, v_sort_order);

    RETURN QUERY EXECUTE v_sql USING p_start_date, p_end_date, p_category;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'An error occurred in get_sale_order_summary: %', SQLERRM;
END;
$_$;


--
-- TOC entry 245 (class 1255 OID 17309)
-- Name: update_feedback(integer, integer, smallint, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_feedback(p_feedback_id integer, p_member_id integer, p_rating smallint, p_comment text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_owner INTEGER;
BEGIN
    -- Check feedback exists and get owner
    SELECT member_id INTO v_owner
    FROM feedback
    WHERE feedback_id = p_feedback_id;

    IF NOT FOUND THEN
        RETURN 'ERROR: Feedback not found.';
    END IF;

    -- Check ownership
    IF v_owner != p_member_id THEN
        RETURN 'ERROR: You can only update your own feedback.';
    END IF;

    -- Validate rating
    IF p_rating < 1 OR p_rating > 5 THEN
        RETURN 'ERROR: Rating must be between 1 and 5.';
    END IF;

    -- Validate comment
    IF TRIM(p_comment) = '' THEN
        RETURN 'ERROR: Comment cannot be empty.';
    END IF;

    -- Update
    UPDATE feedback
    SET rating     = p_rating,
        comment    = TRIM(p_comment),
        updated_at = NOW()
    WHERE feedback_id = p_feedback_id;

    RETURN 'SUCCESS: Feedback updated successfully.';

EXCEPTION
    WHEN OTHERS THEN
        RETURN 'ERROR: An unexpected error occurred: ' || SQLERRM;
END;
$$;


--
-- TOC entry 229 (class 1259 OID 17248)
-- Name: feedback; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feedback (
    feedback_id integer NOT NULL,
    member_id integer NOT NULL,
    product_id integer NOT NULL,
    sale_order_id integer NOT NULL,
    rating smallint NOT NULL,
    comment text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT feedback_rating_check CHECK (((rating >= 1) AND (rating <= 5)))
);


--
-- TOC entry 228 (class 1259 OID 17247)
-- Name: feedback_feedback_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.feedback_feedback_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5091 (class 0 OID 0)
-- Dependencies: 228
-- Name: feedback_feedback_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.feedback_feedback_id_seq OWNED BY public.feedback.feedback_id;


--
-- TOC entry 231 (class 1259 OID 17284)
-- Name: feedback_response; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feedback_response (
    response_id integer NOT NULL,
    feedback_id integer NOT NULL,
    member_id integer NOT NULL,
    comment text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 230 (class 1259 OID 17283)
-- Name: feedback_response_response_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.feedback_response_response_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5092 (class 0 OID 0)
-- Dependencies: 230
-- Name: feedback_response_response_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.feedback_response_response_id_seq OWNED BY public.feedback_response.response_id;


--
-- TOC entry 219 (class 1259 OID 16753)
-- Name: member; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.member (
    member_id integer NOT NULL,
    username character varying(50) NOT NULL,
    email character varying(100) NOT NULL,
    password_hash character varying(255) NOT NULL,
    first_name character varying(50) NOT NULL,
    last_name character varying(50) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- TOC entry 220 (class 1259 OID 16765)
-- Name: member_member_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.member_member_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5093 (class 0 OID 0)
-- Dependencies: 220
-- Name: member_member_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.member_member_id_seq OWNED BY public.member.member_id;


--
-- TOC entry 221 (class 1259 OID 16766)
-- Name: member_role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.member_role (
    member_id integer NOT NULL,
    role character varying(20) NOT NULL,
    CONSTRAINT member_role_role_check CHECK (((role)::text = ANY (ARRAY[('ADMIN'::character varying)::text, ('USER'::character varying)::text])))
);


--
-- TOC entry 222 (class 1259 OID 16772)
-- Name: product; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product (
    product_id integer NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    price numeric(10,2) NOT NULL,
    category character varying(50),
    is_available boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- TOC entry 223 (class 1259 OID 16782)
-- Name: product_product_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_product_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5094 (class 0 OID 0)
-- Dependencies: 223
-- Name: product_product_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_product_id_seq OWNED BY public.product.product_id;


--
-- TOC entry 224 (class 1259 OID 16783)
-- Name: sale_order; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sale_order (
    order_id integer NOT NULL,
    member_id integer,
    order_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    total_amount numeric(10,2) NOT NULL,
    status character varying(20) NOT NULL,
    delivery_address text,
    CONSTRAINT sale_order_status_check CHECK (((status)::text = ANY (ARRAY[('COMPLETED'::character varying)::text, ('CANCELLED'::character varying)::text, ('PACKING'::character varying)::text])))
);


--
-- TOC entry 225 (class 1259 OID 16793)
-- Name: sale_order_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sale_order_item (
    order_item_id integer NOT NULL,
    order_id integer,
    product_id integer,
    quantity integer NOT NULL,
    unit_price numeric(10,2) NOT NULL,
    subtotal numeric(10,2) NOT NULL,
    CONSTRAINT sale_order_item_quantity_check CHECK ((quantity > 0))
);


--
-- TOC entry 226 (class 1259 OID 16801)
-- Name: sale_order_item_order_item_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sale_order_item_order_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5095 (class 0 OID 0)
-- Dependencies: 226
-- Name: sale_order_item_order_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sale_order_item_order_item_id_seq OWNED BY public.sale_order_item.order_item_id;


--
-- TOC entry 227 (class 1259 OID 16802)
-- Name: sale_order_order_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sale_order_order_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5096 (class 0 OID 0)
-- Dependencies: 227
-- Name: sale_order_order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sale_order_order_id_seq OWNED BY public.sale_order.order_id;


--
-- TOC entry 4901 (class 2604 OID 17251)
-- Name: feedback feedback_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback ALTER COLUMN feedback_id SET DEFAULT nextval('public.feedback_feedback_id_seq'::regclass);


--
-- TOC entry 4904 (class 2604 OID 17287)
-- Name: feedback_response response_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_response ALTER COLUMN response_id SET DEFAULT nextval('public.feedback_response_response_id_seq'::regclass);


--
-- TOC entry 4893 (class 2604 OID 16803)
-- Name: member member_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member ALTER COLUMN member_id SET DEFAULT nextval('public.member_member_id_seq'::regclass);


--
-- TOC entry 4895 (class 2604 OID 16804)
-- Name: product product_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product ALTER COLUMN product_id SET DEFAULT nextval('public.product_product_id_seq'::regclass);


--
-- TOC entry 4898 (class 2604 OID 16805)
-- Name: sale_order order_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order ALTER COLUMN order_id SET DEFAULT nextval('public.sale_order_order_id_seq'::regclass);


--
-- TOC entry 4900 (class 2604 OID 16806)
-- Name: sale_order_item order_item_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order_item ALTER COLUMN order_item_id SET DEFAULT nextval('public.sale_order_item_order_item_id_seq'::regclass);


--
-- TOC entry 4925 (class 2606 OID 17267)
-- Name: feedback feedback_member_id_product_id_sale_order_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT feedback_member_id_product_id_sale_order_id_key UNIQUE (member_id, product_id, sale_order_id);


--
-- TOC entry 4927 (class 2606 OID 17265)
-- Name: feedback feedback_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT feedback_pkey PRIMARY KEY (feedback_id);


--
-- TOC entry 4929 (class 2606 OID 17297)
-- Name: feedback_response feedback_response_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_response
    ADD CONSTRAINT feedback_response_pkey PRIMARY KEY (response_id);


--
-- TOC entry 4911 (class 2606 OID 16808)
-- Name: member member_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member
    ADD CONSTRAINT member_email_key UNIQUE (email);


--
-- TOC entry 4913 (class 2606 OID 16810)
-- Name: member member_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member
    ADD CONSTRAINT member_pkey PRIMARY KEY (member_id);


--
-- TOC entry 4917 (class 2606 OID 16812)
-- Name: member_role member_role_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_role
    ADD CONSTRAINT member_role_pkey PRIMARY KEY (member_id, role);


--
-- TOC entry 4915 (class 2606 OID 16814)
-- Name: member member_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member
    ADD CONSTRAINT member_username_key UNIQUE (username);


--
-- TOC entry 4919 (class 2606 OID 16816)
-- Name: product product_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product
    ADD CONSTRAINT product_pkey PRIMARY KEY (product_id);


--
-- TOC entry 4923 (class 2606 OID 16818)
-- Name: sale_order_item sale_order_item_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order_item
    ADD CONSTRAINT sale_order_item_pkey PRIMARY KEY (order_item_id);


--
-- TOC entry 4921 (class 2606 OID 16820)
-- Name: sale_order sale_order_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order
    ADD CONSTRAINT sale_order_pkey PRIMARY KEY (order_id);


--
-- TOC entry 4934 (class 2606 OID 17268)
-- Name: feedback feedback_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT feedback_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.member(member_id);


--
-- TOC entry 4935 (class 2606 OID 17273)
-- Name: feedback feedback_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT feedback_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.product(product_id);


--
-- TOC entry 4937 (class 2606 OID 17298)
-- Name: feedback_response feedback_response_feedback_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_response
    ADD CONSTRAINT feedback_response_feedback_id_fkey FOREIGN KEY (feedback_id) REFERENCES public.feedback(feedback_id) ON DELETE CASCADE;


--
-- TOC entry 4938 (class 2606 OID 17303)
-- Name: feedback_response feedback_response_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_response
    ADD CONSTRAINT feedback_response_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.member(member_id);


--
-- TOC entry 4936 (class 2606 OID 17278)
-- Name: feedback feedback_sale_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT feedback_sale_order_id_fkey FOREIGN KEY (sale_order_id) REFERENCES public.sale_order(order_id);


--
-- TOC entry 4930 (class 2606 OID 16821)
-- Name: member_role member_role_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_role
    ADD CONSTRAINT member_role_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.member(member_id);


--
-- TOC entry 4932 (class 2606 OID 16826)
-- Name: sale_order_item sale_order_item_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order_item
    ADD CONSTRAINT sale_order_item_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.sale_order(order_id);


--
-- TOC entry 4933 (class 2606 OID 16831)
-- Name: sale_order_item sale_order_item_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order_item
    ADD CONSTRAINT sale_order_item_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.product(product_id);


--
-- TOC entry 4931 (class 2606 OID 16836)
-- Name: sale_order sale_order_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order
    ADD CONSTRAINT sale_order_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.member(member_id);


-- Completed on 2026-07-01 10:07:45

--
-- PostgreSQL database dump complete
--

\unrestrict 8YVdNdY5fK6kaokwZRFkRhgdn14Dx2K51D50z0QEZqkYU7iuY11gxI3qURDa7OV

