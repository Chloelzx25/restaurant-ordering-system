--
-- PostgreSQL database dump
--

\restrict MPZ1bEC7OGxamhds634zOeauzb2hfhngIePwhBhtu4ltTIEtVIuUrbcwVdzZaZe

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

-- Started on 2026-08-13 21:43:32

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
-- TOC entry 253 (class 1255 OID 17308)
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
-- TOC entry 256 (class 1255 OID 17312)
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
-- TOC entry 255 (class 1255 OID 17310)
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
-- TOC entry 258 (class 1255 OID 17314)
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
-- TOC entry 241 (class 1255 OID 17311)
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
-- TOC entry 257 (class 1255 OID 17313)
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
-- TOC entry 259 (class 1255 OID 17315)
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
-- TOC entry 260 (class 1255 OID 41813)
-- Name: place_orders(integer, integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.place_orders(IN p_member_id integer, IN p_cart_id integer, OUT p_processed integer, OUT p_skipped integer, OUT p_message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_item         RECORD;
    v_order_id     INTEGER;
    v_total_amount NUMERIC;
BEGIN
    p_processed := 0;
    p_skipped   := 0;
    p_message   := '';

    -- Validate member owns this cart
    IF NOT EXISTS (
        SELECT 1 FROM cart
        WHERE cart_id = p_cart_id AND member_id = p_member_id
    ) THEN
        p_message := 'Cart not found or does not belong to you.';
        RETURN;
    END IF;

    -- Loop through each item in the cart
    FOR v_item IN
        SELECT ci.cart_item_id, ci.product_id, ci.quantity, ci.unit_price,
               p.is_available, p.name AS product_name
        FROM cart_item ci
        JOIN product p ON ci.product_id = p.product_id
        WHERE ci.cart_id = p_cart_id
        ORDER BY ci.cart_item_id
    LOOP
        IF v_item.is_available THEN
            v_total_amount := v_item.unit_price * v_item.quantity;

            -- Create sale order with status PACKING
            INSERT INTO sale_order (member_id, order_date, total_amount, status, delivery_address)
            VALUES (p_member_id, NOW(), v_total_amount, 'PACKING', 'Default Address')
            RETURNING order_id INTO v_order_id;

            -- Create sale order item
            INSERT INTO sale_order_item (order_id, product_id, quantity, unit_price, subtotal)
            VALUES (v_order_id, v_item.product_id, v_item.quantity, v_item.unit_price, v_total_amount);

            -- Remove from cart
            DELETE FROM cart_item WHERE cart_item_id = v_item.cart_item_id;

            p_processed := p_processed + 1;
        ELSE
            -- Item not available — skip, leave in cart
            p_skipped := p_skipped + 1;
        END IF;

    END LOOP;

    -- Build result message
    IF p_processed = 0 AND p_skipped > 0 THEN
        p_message := 'No items were available to order. '
                     || p_skipped || ' item(s) remain in your cart.';
    ELSIF p_processed > 0 AND p_skipped > 0 THEN
        p_message := p_processed || ' order(s) placed successfully. '
                     || p_skipped || ' item(s) were unavailable and remain in your cart.';
    ELSIF p_processed > 0 THEN
        p_message := p_processed || ' order(s) placed successfully.';
    ELSE
        p_message := 'No items found in cart.';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        p_message := 'An unexpected error occurred: ' || SQLERRM;
END;
$$;


--
-- TOC entry 254 (class 1255 OID 17309)
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
-- TOC entry 232 (class 1259 OID 38750)
-- Name: _prisma_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._prisma_migrations (
    id character varying(36) NOT NULL,
    checksum character varying(64) NOT NULL,
    finished_at timestamp with time zone,
    migration_name character varying(255) NOT NULL,
    logs text,
    rolled_back_at timestamp with time zone,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    applied_steps_count integer DEFAULT 0 NOT NULL
);


--
-- TOC entry 234 (class 1259 OID 41743)
-- Name: cart; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cart (
    cart_id integer NOT NULL,
    member_id integer NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- TOC entry 233 (class 1259 OID 41742)
-- Name: cart_cart_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cart_cart_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5139 (class 0 OID 0)
-- Dependencies: 233
-- Name: cart_cart_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cart_cart_id_seq OWNED BY public.cart.cart_id;


--
-- TOC entry 236 (class 1259 OID 41755)
-- Name: cart_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cart_item (
    cart_item_id integer NOT NULL,
    cart_id integer NOT NULL,
    product_id integer NOT NULL,
    quantity integer NOT NULL,
    unit_price numeric(10,2) NOT NULL
);


--
-- TOC entry 235 (class 1259 OID 41754)
-- Name: cart_item_cart_item_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cart_item_cart_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5140 (class 0 OID 0)
-- Dependencies: 235
-- Name: cart_item_cart_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cart_item_cart_item_id_seq OWNED BY public.cart_item.cart_item_id;


--
-- TOC entry 240 (class 1259 OID 41782)
-- Name: delivery_tier; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delivery_tier (
    tier_id integer NOT NULL,
    min_order_value numeric(10,2) NOT NULL,
    delivery_fee numeric(10,2) NOT NULL,
    description text NOT NULL
);


--
-- TOC entry 239 (class 1259 OID 41781)
-- Name: delivery_tier_tier_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.delivery_tier_tier_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5141 (class 0 OID 0)
-- Dependencies: 239
-- Name: delivery_tier_tier_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.delivery_tier_tier_id_seq OWNED BY public.delivery_tier.tier_id;


--
-- TOC entry 238 (class 1259 OID 41767)
-- Name: discount; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.discount (
    discount_id integer NOT NULL,
    type character varying(20) NOT NULL,
    min_quantity integer,
    min_cart_value numeric(10,2),
    percentage numeric(5,2) NOT NULL,
    description text NOT NULL,
    is_active boolean DEFAULT true NOT NULL
);


--
-- TOC entry 237 (class 1259 OID 41766)
-- Name: discount_discount_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.discount_discount_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5142 (class 0 OID 0)
-- Dependencies: 237
-- Name: discount_discount_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.discount_discount_id_seq OWNED BY public.discount.discount_id;


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
-- TOC entry 5143 (class 0 OID 0)
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
-- TOC entry 5144 (class 0 OID 0)
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
-- TOC entry 5145 (class 0 OID 0)
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
-- TOC entry 5146 (class 0 OID 0)
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
-- TOC entry 5147 (class 0 OID 0)
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
-- TOC entry 5148 (class 0 OID 0)
-- Dependencies: 227
-- Name: sale_order_order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sale_order_order_id_seq OWNED BY public.sale_order.order_id;


--
-- TOC entry 4933 (class 2604 OID 41746)
-- Name: cart cart_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cart ALTER COLUMN cart_id SET DEFAULT nextval('public.cart_cart_id_seq'::regclass);


--
-- TOC entry 4935 (class 2604 OID 41758)
-- Name: cart_item cart_item_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cart_item ALTER COLUMN cart_item_id SET DEFAULT nextval('public.cart_item_cart_item_id_seq'::regclass);


--
-- TOC entry 4938 (class 2604 OID 41785)
-- Name: delivery_tier tier_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delivery_tier ALTER COLUMN tier_id SET DEFAULT nextval('public.delivery_tier_tier_id_seq'::regclass);


--
-- TOC entry 4936 (class 2604 OID 41770)
-- Name: discount discount_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discount ALTER COLUMN discount_id SET DEFAULT nextval('public.discount_discount_id_seq'::regclass);


--
-- TOC entry 4926 (class 2604 OID 17251)
-- Name: feedback feedback_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback ALTER COLUMN feedback_id SET DEFAULT nextval('public.feedback_feedback_id_seq'::regclass);


--
-- TOC entry 4929 (class 2604 OID 17287)
-- Name: feedback_response response_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_response ALTER COLUMN response_id SET DEFAULT nextval('public.feedback_response_response_id_seq'::regclass);


--
-- TOC entry 4918 (class 2604 OID 16803)
-- Name: member member_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member ALTER COLUMN member_id SET DEFAULT nextval('public.member_member_id_seq'::regclass);


--
-- TOC entry 4920 (class 2604 OID 16804)
-- Name: product product_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product ALTER COLUMN product_id SET DEFAULT nextval('public.product_product_id_seq'::regclass);


--
-- TOC entry 4923 (class 2604 OID 16805)
-- Name: sale_order order_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order ALTER COLUMN order_id SET DEFAULT nextval('public.sale_order_order_id_seq'::regclass);


--
-- TOC entry 4925 (class 2604 OID 16806)
-- Name: sale_order_item order_item_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order_item ALTER COLUMN order_item_id SET DEFAULT nextval('public.sale_order_item_order_item_id_seq'::regclass);


--
-- TOC entry 4964 (class 2606 OID 38763)
-- Name: _prisma_migrations _prisma_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._prisma_migrations
    ADD CONSTRAINT _prisma_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4970 (class 2606 OID 41765)
-- Name: cart_item cart_item_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cart_item
    ADD CONSTRAINT cart_item_pkey PRIMARY KEY (cart_item_id);


--
-- TOC entry 4967 (class 2606 OID 41753)
-- Name: cart cart_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cart
    ADD CONSTRAINT cart_pkey PRIMARY KEY (cart_id);


--
-- TOC entry 4974 (class 2606 OID 41793)
-- Name: delivery_tier delivery_tier_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delivery_tier
    ADD CONSTRAINT delivery_tier_pkey PRIMARY KEY (tier_id);


--
-- TOC entry 4972 (class 2606 OID 41780)
-- Name: discount discount_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discount
    ADD CONSTRAINT discount_pkey PRIMARY KEY (discount_id);


--
-- TOC entry 4958 (class 2606 OID 17267)
-- Name: feedback feedback_member_id_product_id_sale_order_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT feedback_member_id_product_id_sale_order_id_key UNIQUE (member_id, product_id, sale_order_id);


--
-- TOC entry 4960 (class 2606 OID 17265)
-- Name: feedback feedback_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT feedback_pkey PRIMARY KEY (feedback_id);


--
-- TOC entry 4962 (class 2606 OID 17297)
-- Name: feedback_response feedback_response_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_response
    ADD CONSTRAINT feedback_response_pkey PRIMARY KEY (response_id);


--
-- TOC entry 4944 (class 2606 OID 16808)
-- Name: member member_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member
    ADD CONSTRAINT member_email_key UNIQUE (email);


--
-- TOC entry 4946 (class 2606 OID 16810)
-- Name: member member_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member
    ADD CONSTRAINT member_pkey PRIMARY KEY (member_id);


--
-- TOC entry 4950 (class 2606 OID 16812)
-- Name: member_role member_role_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_role
    ADD CONSTRAINT member_role_pkey PRIMARY KEY (member_id, role);


--
-- TOC entry 4948 (class 2606 OID 16814)
-- Name: member member_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member
    ADD CONSTRAINT member_username_key UNIQUE (username);


--
-- TOC entry 4952 (class 2606 OID 16816)
-- Name: product product_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product
    ADD CONSTRAINT product_pkey PRIMARY KEY (product_id);


--
-- TOC entry 4956 (class 2606 OID 16818)
-- Name: sale_order_item sale_order_item_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order_item
    ADD CONSTRAINT sale_order_item_pkey PRIMARY KEY (order_item_id);


--
-- TOC entry 4954 (class 2606 OID 16820)
-- Name: sale_order sale_order_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order
    ADD CONSTRAINT sale_order_pkey PRIMARY KEY (order_id);


--
-- TOC entry 4968 (class 1259 OID 41795)
-- Name: cart_item_cart_id_product_id_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX cart_item_cart_id_product_id_key ON public.cart_item USING btree (cart_id, product_id);


--
-- TOC entry 4965 (class 1259 OID 41794)
-- Name: cart_member_id_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX cart_member_id_key ON public.cart USING btree (member_id);


--
-- TOC entry 4985 (class 2606 OID 41801)
-- Name: cart_item cart_item_cart_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cart_item
    ADD CONSTRAINT cart_item_cart_id_fkey FOREIGN KEY (cart_id) REFERENCES public.cart(cart_id) ON DELETE CASCADE;


--
-- TOC entry 4986 (class 2606 OID 41806)
-- Name: cart_item cart_item_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cart_item
    ADD CONSTRAINT cart_item_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.product(product_id);


--
-- TOC entry 4984 (class 2606 OID 41796)
-- Name: cart cart_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cart
    ADD CONSTRAINT cart_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.member(member_id) ON DELETE CASCADE;


--
-- TOC entry 4979 (class 2606 OID 17268)
-- Name: feedback feedback_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT feedback_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.member(member_id);


--
-- TOC entry 4980 (class 2606 OID 17273)
-- Name: feedback feedback_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT feedback_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.product(product_id);


--
-- TOC entry 4982 (class 2606 OID 17298)
-- Name: feedback_response feedback_response_feedback_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_response
    ADD CONSTRAINT feedback_response_feedback_id_fkey FOREIGN KEY (feedback_id) REFERENCES public.feedback(feedback_id) ON DELETE CASCADE;


--
-- TOC entry 4983 (class 2606 OID 17303)
-- Name: feedback_response feedback_response_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_response
    ADD CONSTRAINT feedback_response_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.member(member_id);


--
-- TOC entry 4981 (class 2606 OID 17278)
-- Name: feedback feedback_sale_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT feedback_sale_order_id_fkey FOREIGN KEY (sale_order_id) REFERENCES public.sale_order(order_id);


--
-- TOC entry 4975 (class 2606 OID 16821)
-- Name: member_role member_role_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_role
    ADD CONSTRAINT member_role_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.member(member_id);


--
-- TOC entry 4977 (class 2606 OID 16826)
-- Name: sale_order_item sale_order_item_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order_item
    ADD CONSTRAINT sale_order_item_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.sale_order(order_id);


--
-- TOC entry 4978 (class 2606 OID 16831)
-- Name: sale_order_item sale_order_item_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order_item
    ADD CONSTRAINT sale_order_item_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.product(product_id);


--
-- TOC entry 4976 (class 2606 OID 16836)
-- Name: sale_order sale_order_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order
    ADD CONSTRAINT sale_order_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.member(member_id);


-- Completed on 2026-08-13 21:43:33

--
-- PostgreSQL database dump complete
--

\unrestrict MPZ1bEC7OGxamhds634zOeauzb2hfhngIePwhBhtu4ltTIEtVIuUrbcwVdzZaZe

