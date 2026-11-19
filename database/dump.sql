--
-- PostgreSQL database dump
--

\restrict LxjEzDhxYbEjg0ztmBXGoG3EJetCqtq4BaB1ueT1BFyS8pas0O8Ywt75kQSrM7d

-- Dumped from database version 18.6
-- Dumped by pg_dump version 18.6

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
-- Name: activity_level; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.activity_level AS ENUM (
    'LOW',
    'MEDIUM',
    'HIGH'
);


--
-- Name: adoption_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.adoption_status AS ENUM (
    'PENDING',
    'APPROVED',
    'REJECTED',
    'NOT_SELECTED',
    'CANCELLED',
    'VOIDED',
    'COMPLETED',
    'RETURNED'
);


--
-- Name: age_range; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.age_range AS ENUM (
    'BABY',
    'YOUNG',
    'ADULT',
    'SENIOR'
);


--
-- Name: audit_operation; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.audit_operation AS ENUM (
    'INSERT',
    'UPDATE',
    'DELETE'
);


--
-- Name: block_reason; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.block_reason AS ENUM (
    'INAPPROPRIATE_BEHAVIOR',
    'FALSE_INFORMATION',
    'NON_COMPLIANCE',
    'OTHER'
);


--
-- Name: cancelled_by; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.cancelled_by AS ENUM (
    'ADOPTER',
    'SHELTER',
    'SYSTEM'
);


--
-- Name: compatibility; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.compatibility AS ENUM (
    'YES',
    'NO',
    'UNKNOWN'
);


--
-- Name: housing_tenure; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.housing_tenure AS ENUM (
    'OWNED',
    'RENTED'
);


--
-- Name: housing_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.housing_type AS ENUM (
    'FLAT',
    'HOUSE',
    'DETACHED_HOUSE',
    'OTHER'
);


--
-- Name: incident_reason; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.incident_reason AS ENUM (
    'INCORRECT_ATTENDANCE',
    'INAPPROPRIATE_BEHAVIOR',
    'FALSE_INFORMATION',
    'INAPPROPRIATE_CONTENT',
    'UNFAIR_BLOCK',
    'OTHER'
);


--
-- Name: incident_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.incident_status AS ENUM (
    'OPEN',
    'IN_REVIEW',
    'RESOLVED',
    'DISMISSED'
);


--
-- Name: notification_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.notification_type AS ENUM (
    'VISIT_CONFIRMED',
    'VISIT_REJECTED',
    'VISIT_EXPIRED',
    'VISIT_CANCELLED',
    'VISIT_VOIDED',
    'ADOPTION_APPROVED',
    'ADOPTION_REJECTED',
    'ADOPTION_NOT_SELECTED',
    'ADOPTION_CANCELLED',
    'ADOPTION_VOIDED',
    'PET_AVAILABLE_AGAIN',
    'ADOPTION_PENDING_REMINDER',
    'HANDOVER_PENDING_REMINDER',
    'ADOPTION_OVERDUE',
    'ADOPTER_BLOCKED',
    'INCIDENT_RESOLVED'
);


--
-- Name: party; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.party AS ENUM (
    'ADOPTER',
    'SHELTER'
);


--
-- Name: pet_sex; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.pet_sex AS ENUM (
    'MALE',
    'FEMALE'
);


--
-- Name: pet_size; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.pet_size AS ENUM (
    'SMALL',
    'MEDIUM',
    'LARGE'
);


--
-- Name: pet_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.pet_status AS ENUM (
    'AVAILABLE',
    'RESERVED',
    'ADOPTED',
    'WITHDRAWN'
);


--
-- Name: rating_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.rating_type AS ENUM (
    'FAVORITE',
    'DISCARDED'
);


--
-- Name: shelter_verification_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.shelter_verification_status AS ENUM (
    'PENDING',
    'VERIFIED',
    'REJECTED'
);


--
-- Name: suspension_reason; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.suspension_reason AS ENUM (
    'INAPPROPRIATE_BEHAVIOR',
    'FALSE_INFORMATION',
    'INAPPROPRIATE_CONTENT',
    'FRAUD',
    'REPEATED_INCIDENTS',
    'OTHER'
);


--
-- Name: user_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_role AS ENUM (
    'ADOPTER',
    'SHELTER',
    'ADMIN'
);


--
-- Name: visit_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.visit_status AS ENUM (
    'PENDING',
    'CONFIRMED',
    'REJECTED',
    'CANCELLED',
    'EXPIRED',
    'VOIDED',
    'COMPLETED',
    'NO_SHOW'
);


--
-- Name: void_reason; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.void_reason AS ENUM (
    'PET_RESERVED',
    'DECEASED',
    'TRANSFERRED',
    'MEDICAL_TREATMENT',
    'FOSTER_CARE',
    'ERROR',
    'OTHER',
    'REMOVED_BY_ADMIN',
    'ADOPTER_BLOCKED',
    'ADOPTER_SUSPENDED',
    'NO_SHOW',
    'SLOT_CANCELLED',
    'ACCOUNT_DELETED'
);


--
-- Name: withdrawal_reason; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.withdrawal_reason AS ENUM (
    'DECEASED',
    'TRANSFERRED',
    'MEDICAL_TREATMENT',
    'FOSTER_CARE',
    'ERROR',
    'OTHER',
    'REMOVED_BY_ADMIN'
);


--
-- Name: fn_audit(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_audit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_user  integer := NULLIF(current_setting('app.current_user_id', true), '')::integer;
    v_old   jsonb;
    v_new   jsonb;
BEGIN
    -- Cargas masivas (seed de prueba): SET LOCAL app.skip_audit = 'on'
    IF current_setting('app.skip_audit', true) = 'on' THEN
        RETURN COALESCE(NEW, OLD);
    END IF;

    IF TG_OP IN ('UPDATE', 'DELETE') THEN
        v_old := to_jsonb(OLD) - 'password';
    END IF;
    IF TG_OP IN ('INSERT', 'UPDATE') THEN
        v_new := to_jsonb(NEW) - 'password';
    END IF;

    -- Un UPDATE que no cambia nada no se registra
    IF TG_OP = 'UPDATE' AND v_old = v_new THEN
        RETURN NEW;
    END IF;

    INSERT INTO audit_log (id_user, table_name, id_record, operation, old_data, new_data)
    VALUES (
        v_user,
        TG_TABLE_NAME,
        (COALESCE(v_new, v_old)->>'id')::integer,
        TG_OP::audit_operation,
        v_old,
        v_new
    );

    RETURN COALESCE(NEW, OLD);
END;
$$;


--
-- Name: fn_set_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: adopter; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.adopter (
    id integer NOT NULL,
    id_user integer NOT NULL,
    first_name character varying(80) NOT NULL,
    last_name character varying(120) NOT NULL,
    phone character varying(20) NOT NULL,
    birth_date date NOT NULL,
    id_province smallint NOT NULL,
    city character varying(100) NOT NULL,
    profile_photo_url character varying(500),
    housing_type public.housing_type,
    has_garden boolean,
    has_terrace boolean,
    housing_tenure public.housing_tenure,
    household_members smallint,
    has_children boolean,
    other_pets text,
    previous_experience text,
    hours_alone_per_day smallint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT adopter_hours_alone_per_day_check CHECK (((hours_alone_per_day >= 0) AND (hours_alone_per_day <= 24))),
    CONSTRAINT adopter_household_members_check CHECK ((household_members >= 1))
);


--
-- Name: adopter_block; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.adopter_block (
    id integer NOT NULL,
    id_shelter integer NOT NULL,
    id_adopter integer NOT NULL,
    reason public.block_reason NOT NULL,
    details text,
    unblocked_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by integer,
    updated_by integer,
    CONSTRAINT chk_block_dates CHECK (((unblocked_at IS NULL) OR (unblocked_at >= created_at)))
);


--
-- Name: adopter_block_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.adopter_block ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.adopter_block_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: adopter_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.adopter ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.adopter_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: adopter_preference; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.adopter_preference (
    id integer NOT NULL,
    id_adopter integer NOT NULL,
    requires_children_compatibility boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: adopter_preference_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.adopter_preference ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.adopter_preference_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: adoption; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.adoption (
    id integer NOT NULL,
    id_adopter integer NOT NULL,
    id_pet integer NOT NULL,
    id_visit integer NOT NULL,
    status public.adoption_status DEFAULT 'PENDING'::public.adoption_status NOT NULL,
    responded_at timestamp with time zone,
    rejection_reason text,
    cancelled_at timestamp with time zone,
    cancelled_by public.cancelled_by,
    cancellation_reason text,
    void_reason public.void_reason,
    handed_over_at timestamp with time zone,
    returned_at timestamp with time zone,
    return_reason text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by integer,
    updated_by integer,
    CONSTRAINT chk_adoption_cancelled CHECK (((status = 'CANCELLED'::public.adoption_status) = (cancelled_by IS NOT NULL))),
    CONSTRAINT chk_adoption_handover CHECK (((status = ANY (ARRAY['COMPLETED'::public.adoption_status, 'RETURNED'::public.adoption_status])) = (handed_over_at IS NOT NULL))),
    CONSTRAINT chk_adoption_returned CHECK (((status = 'RETURNED'::public.adoption_status) = (returned_at IS NOT NULL))),
    CONSTRAINT chk_adoption_voided CHECK (((status = 'VOIDED'::public.adoption_status) = (void_reason IS NOT NULL)))
);


--
-- Name: adoption_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.adoption ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.adoption_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: app_user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.app_user (
    id integer NOT NULL,
    email character varying(254) NOT NULL,
    password character varying(255) NOT NULL,
    role public.user_role NOT NULL,
    email_verified boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: app_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.app_user ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.app_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_log (
    id bigint NOT NULL,
    id_user integer,
    table_name character varying(63) NOT NULL,
    id_record integer NOT NULL,
    operation public.audit_operation NOT NULL,
    old_data jsonb,
    new_data jsonb,
    logged_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: audit_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.audit_log ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.audit_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: breed; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.breed (
    id integer NOT NULL,
    id_species integer NOT NULL,
    name character varying(100) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: breed_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.breed ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.breed_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: conversation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversation (
    id integer NOT NULL,
    id_adopter integer NOT NULL,
    id_shelter integer NOT NULL,
    last_message_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: conversation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.conversation ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.conversation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: incident; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.incident (
    id integer NOT NULL,
    id_adopter integer NOT NULL,
    id_shelter integer NOT NULL,
    opened_by public.party NOT NULL,
    id_visit integer,
    id_adoption integer,
    reason public.incident_reason NOT NULL,
    details text NOT NULL,
    status public.incident_status DEFAULT 'OPEN'::public.incident_status NOT NULL,
    resolved_at timestamp with time zone,
    resolution text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by integer,
    updated_by integer,
    CONSTRAINT chk_incident_resolved CHECK (((status = ANY (ARRAY['RESOLVED'::public.incident_status, 'DISMISSED'::public.incident_status])) = (resolved_at IS NOT NULL))),
    CONSTRAINT chk_incident_single_link CHECK ((num_nonnulls(id_visit, id_adoption) <= 1))
);


--
-- Name: incident_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.incident ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.incident_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: message; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.message (
    id integer NOT NULL,
    id_conversation integer NOT NULL,
    sender public.party NOT NULL,
    body text,
    image_url character varying(500),
    read_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_message_content CHECK (((body IS NOT NULL) OR (image_url IS NOT NULL)))
);


--
-- Name: message_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.message ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.message_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: notification; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification (
    id integer NOT NULL,
    id_user integer NOT NULL,
    type public.notification_type NOT NULL,
    body text NOT NULL,
    read_at timestamp with time zone,
    id_visit integer,
    id_adoption integer,
    id_incident integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_notification_single_link CHECK ((num_nonnulls(id_visit, id_adoption, id_incident) <= 1))
);


--
-- Name: notification_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.notification ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.notification_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: pet; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pet (
    id integer NOT NULL,
    id_shelter integer NOT NULL,
    id_breed integer NOT NULL,
    name character varying(80) NOT NULL,
    sex public.pet_sex NOT NULL,
    size public.pet_size NOT NULL,
    approx_birth_date date NOT NULL,
    activity_level public.activity_level NOT NULL,
    children_compatibility public.compatibility DEFAULT 'UNKNOWN'::public.compatibility NOT NULL,
    description text,
    vaccinated boolean DEFAULT false NOT NULL,
    dewormed boolean DEFAULT false NOT NULL,
    neutered boolean DEFAULT false NOT NULL,
    microchipped boolean DEFAULT false NOT NULL,
    special_needs text,
    adoption_fee numeric(7,2),
    status public.pet_status DEFAULT 'AVAILABLE'::public.pet_status NOT NULL,
    withdrawn_at timestamp with time zone,
    withdrawal_reason public.withdrawal_reason,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by integer,
    updated_by integer,
    CONSTRAINT chk_pet_withdrawal CHECK (((status = 'WITHDRAWN'::public.pet_status) = ((withdrawn_at IS NOT NULL) AND (withdrawal_reason IS NOT NULL)))),
    CONSTRAINT pet_adoption_fee_check CHECK ((adoption_fee >= (0)::numeric))
);


--
-- Name: pet_compatibility_rel; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pet_compatibility_rel (
    id_pet integer NOT NULL,
    id_species integer NOT NULL,
    result public.compatibility NOT NULL,
    CONSTRAINT pet_compatibility_rel_result_check CHECK ((result <> 'UNKNOWN'::public.compatibility))
);


--
-- Name: pet_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.pet ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.pet_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: pet_photo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pet_photo (
    id integer NOT NULL,
    id_pet integer NOT NULL,
    url character varying(500) NOT NULL,
    display_order smallint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT pet_photo_display_order_check CHECK (((display_order >= 1) AND (display_order <= 6)))
);


--
-- Name: pet_photo_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.pet_photo ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.pet_photo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: pet_rating_rel; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pet_rating_rel (
    id_adopter integer NOT NULL,
    id_pet integer NOT NULL,
    rating public.rating_type NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: preference_activity_level; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.preference_activity_level (
    id_preference integer NOT NULL,
    activity_level public.activity_level NOT NULL
);


--
-- Name: preference_age_range; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.preference_age_range (
    id_preference integer NOT NULL,
    age_range public.age_range NOT NULL
);


--
-- Name: preference_breed_rel; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.preference_breed_rel (
    id_preference integer NOT NULL,
    id_breed integer NOT NULL
);


--
-- Name: preference_compatibility_rel; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.preference_compatibility_rel (
    id_preference integer NOT NULL,
    id_species integer NOT NULL
);


--
-- Name: preference_sex; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.preference_sex (
    id_preference integer NOT NULL,
    sex public.pet_sex NOT NULL
);


--
-- Name: preference_size; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.preference_size (
    id_preference integer NOT NULL,
    size public.pet_size NOT NULL
);


--
-- Name: preference_species_rel; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.preference_species_rel (
    id_preference integer NOT NULL,
    id_species integer NOT NULL
);


--
-- Name: province; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.province (
    id smallint NOT NULL,
    name character varying(60) NOT NULL
);


--
-- Name: shelter; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shelter (
    id integer NOT NULL,
    id_user integer NOT NULL,
    name character varying(150) NOT NULL,
    cif character varying(9) NOT NULL,
    description text,
    phone character varying(20) NOT NULL,
    contact_email character varying(254),
    address character varying(200) NOT NULL,
    postal_code character(5) NOT NULL,
    city character varying(100) NOT NULL,
    id_province smallint NOT NULL,
    website character varying(300),
    logo_url character varying(500),
    opening_hours text,
    verification_status public.shelter_verification_status DEFAULT 'PENDING'::public.shelter_verification_status NOT NULL,
    verified_at timestamp with time zone,
    rejection_reason text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_shelter_rejection CHECK (((verification_status <> 'REJECTED'::public.shelter_verification_status) OR (rejection_reason IS NOT NULL)))
);


--
-- Name: shelter_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.shelter ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.shelter_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: species; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.species (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: species_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.species ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.species_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: suspension; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.suspension (
    id integer NOT NULL,
    id_user integer NOT NULL,
    reason public.suspension_reason NOT NULL,
    details text,
    ended_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by integer,
    updated_by integer,
    CONSTRAINT chk_suspension_dates CHECK (((ended_at IS NULL) OR (ended_at >= created_at)))
);


--
-- Name: suspension_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.suspension ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.suspension_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: visit; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.visit (
    id integer NOT NULL,
    id_adopter integer NOT NULL,
    id_pet integer NOT NULL,
    id_visit_slot integer NOT NULL,
    status public.visit_status DEFAULT 'PENDING'::public.visit_status NOT NULL,
    responded_at timestamp with time zone,
    rejection_reason text,
    cancelled_at timestamp with time zone,
    cancelled_by public.cancelled_by,
    void_reason public.void_reason,
    attendance_recorded_at timestamp with time zone,
    attendance_automatic boolean DEFAULT false NOT NULL,
    corrected_by_admin boolean DEFAULT false NOT NULL,
    corrected_at timestamp with time zone,
    id_replaced_visit integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by integer,
    updated_by integer,
    CONSTRAINT chk_visit_cancelled CHECK ((((status = 'CANCELLED'::public.visit_status) = (cancelled_by IS NOT NULL)) AND ((cancelled_by IS NULL) OR (cancelled_by <> 'SYSTEM'::public.cancelled_by)))),
    CONSTRAINT chk_visit_correction CHECK (((NOT corrected_by_admin) OR (corrected_at IS NOT NULL))),
    CONSTRAINT chk_visit_not_self_replaced CHECK ((id_replaced_visit <> id)),
    CONSTRAINT chk_visit_voided CHECK (((status = 'VOIDED'::public.visit_status) = (void_reason IS NOT NULL)))
);


--
-- Name: visit_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.visit ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.visit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: visit_slot; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.visit_slot (
    id integer NOT NULL,
    id_shelter integer NOT NULL,
    slot_date date NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    capacity smallint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by integer,
    updated_by integer,
    CONSTRAINT chk_visit_slot_times CHECK ((end_time > start_time)),
    CONSTRAINT visit_slot_capacity_check CHECK ((capacity >= 1))
);


--
-- Name: visit_slot_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.visit_slot ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.visit_slot_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Data for Name: adopter; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.adopter (id, id_user, first_name, last_name, phone, birth_date, id_province, city, profile_photo_url, housing_type, has_garden, has_terrace, housing_tenure, household_members, has_children, other_pets, previous_experience, hours_alone_per_day, created_at, updated_at) FROM stdin;
1	5	Lucía	Martínez Soler	600000001	1988-04-12	46	Valencia	/uploads/adopters/1.jpg	HOUSE	t	f	OWNED	4	t	Una gata de 6 años, esterilizada.	He tenido perros toda la vida.	4	2026-08-21 02:15:32.768865+02	2026-08-22 02:15:32.768865+02
2	6	Javier	López Ferrer	600000002	1992-09-30	46	Paterna	\N	FLAT	f	t	RENTED	2	f	\N	Primera vez que adopto.	6	2026-09-20 02:15:32.768865+02	2026-09-21 02:15:32.768865+02
3	7	Marta	Sánchez Vidal	600000003	1985-01-22	46	Burjassot	\N	DETACHED_HOUSE	t	t	OWNED	3	t	\N	Fui casa de acogida de dos podencos.	3	2026-10-05 02:15:32.768865+02	2026-10-06 02:15:32.768865+02
4	8	Pablo	Romero Gil	600000004	1979-06-03	28	Getafe	\N	FLAT	f	f	OWNED	1	f	\N	Tuve un beagle durante 12 años.	8	2026-10-10 02:15:32.768865+02	2026-10-11 02:15:32.768865+02
5	9	Elena	Navarro Pons	600000005	1995-11-15	46	Valencia	\N	FLAT	f	t	RENTED	2	f	\N	\N	5	2026-10-20 02:15:32.768865+02	2026-10-21 02:15:32.768865+02
6	10	Sergio	Gil Andrés	600000006	1990-02-08	46	Mislata	\N	HOUSE	t	f	OWNED	2	f	Un perro mestizo.	Siempre he tenido perros.	6	2026-08-31 02:15:32.768865+02	2026-09-01 02:15:32.768865+02
7	11	Carmen	Ruiz Blasco	600000007	1968-07-19	28	Madrid	\N	FLAT	f	t	OWNED	2	f	\N	He tenido gatos.	4	2026-09-10 02:15:32.768865+02	2026-09-11 02:15:32.768865+02
8	12	Diego	Torres Mena	600000008	2001-03-27	50	Zaragoza	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-11-19 01:15:32.768865+01	2026-11-19 01:15:32.768865+01
\.


--
-- Data for Name: adopter_block; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.adopter_block (id, id_shelter, id_adopter, reason, details, unblocked_at, created_at, updated_at, created_by, updated_by) FROM stdin;
1	1	6	INAPPROPRIATE_BEHAVIOR	Mensajes ofensivos a una voluntaria.	\N	2026-11-13 02:15:32.768865+01	2026-11-13 02:15:32.768865+01	2	2
2	2	5	OTHER	Bloqueo por error.	2026-10-31 02:15:32.768865+01	2026-10-30 02:15:32.768865+01	2026-10-31 02:15:32.768865+01	3	3
\.


--
-- Data for Name: adopter_preference; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.adopter_preference (id, id_adopter, requires_children_compatibility, created_at, updated_at) FROM stdin;
1	1	t	2026-08-21 02:15:32.768865+02	2026-10-20 02:15:32.768865+02
2	2	f	2026-09-20 02:15:32.768865+02	2026-09-20 02:15:32.768865+02
3	3	t	2026-10-05 02:15:32.768865+02	2026-10-05 02:15:32.768865+02
4	4	f	2026-10-10 02:15:32.768865+02	2026-10-10 02:15:32.768865+02
5	5	f	2026-10-20 02:15:32.768865+02	2026-10-20 02:15:32.768865+02
6	6	f	2026-08-31 02:15:32.768865+02	2026-08-31 02:15:32.768865+02
7	7	f	2026-09-10 02:15:32.768865+02	2026-09-10 02:15:32.768865+02
\.


--
-- Data for Name: adoption; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.adoption (id, id_adopter, id_pet, id_visit, status, responded_at, rejection_reason, cancelled_at, cancelled_by, cancellation_reason, void_reason, handed_over_at, returned_at, return_reason, created_at, updated_at, created_by, updated_by) FROM stdin;
1	1	1	1	COMPLETED	2026-10-25 02:15:32.768865+01	\N	\N	\N	\N	\N	2026-10-29 02:15:32.768865+01	\N	\N	2026-10-23 02:15:32.768865+02	2026-10-29 02:15:32.768865+01	5	2
2	2	2	2	APPROVED	2026-11-17 02:15:32.768865+01	\N	\N	\N	\N	\N	\N	\N	\N	2026-11-12 02:15:32.768865+01	2026-11-17 02:15:32.768865+01	6	2
3	3	2	3	NOT_SELECTED	2026-11-17 02:15:32.768865+01	\N	\N	\N	\N	\N	\N	\N	\N	2026-11-13 02:15:32.768865+01	2026-11-17 02:15:32.768865+01	7	2
4	3	3	4	PENDING	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-11-15 02:15:32.768865+01	2026-11-15 02:15:32.768865+01	7	\N
5	4	3	5	PENDING	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-11-18 02:15:32.768865+01	2026-11-18 02:15:32.768865+01	8	\N
6	7	13	15	RETURNED	2026-10-15 02:15:32.768865+02	\N	\N	\N	\N	\N	2026-10-17 02:15:32.768865+02	2026-11-14 02:15:32.768865+01	Alergia de un miembro de la familia.	2026-10-13 02:15:32.768865+02	2026-11-14 02:15:32.768865+01	11	3
7	4	20	21	CANCELLED	\N	\N	2026-11-19 00:15:32.768865+01	ADOPTER	Me han ofrecido acoger al perro de un familiar.	\N	\N	\N	\N	2026-11-18 14:15:32.768865+01	2026-11-19 00:15:32.768865+01	8	8
\.


--
-- Data for Name: app_user; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.app_user (id, email, password, role, email_verified, deleted_at, created_at, updated_at) FROM stdin;
1	admin@adopciones.test	$2a$10$2Dq0w6NRTOID2G1xporNUO2ZG2e3qYOzHmDdzmwk89UymFC5YUJAi	ADMIN	t	\N	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
2	huellas@protectora.test	$2a$10$2Dq0w6NRTOID2G1xporNUO2ZG2e3qYOzHmDdzmwk89UymFC5YUJAi	SHELTER	t	\N	2026-07-22 02:15:32.768865+02	2026-07-22 02:15:32.768865+02
3	bigotes@protectora.test	$2a$10$2Dq0w6NRTOID2G1xporNUO2ZG2e3qYOzHmDdzmwk89UymFC5YUJAi	SHELTER	t	\N	2026-06-22 02:15:32.768865+02	2026-06-22 02:15:32.768865+02
4	patas@protectora.test	$2a$10$2Dq0w6NRTOID2G1xporNUO2ZG2e3qYOzHmDdzmwk89UymFC5YUJAi	SHELTER	t	\N	2026-11-14 02:15:32.768865+01	2026-11-14 02:15:32.768865+01
5	lucia.martinez@correo.test	$2a$10$2Dq0w6NRTOID2G1xporNUO2ZG2e3qYOzHmDdzmwk89UymFC5YUJAi	ADOPTER	t	\N	2026-08-21 02:15:32.768865+02	2026-08-21 02:15:32.768865+02
6	javier.lopez@correo.test	$2a$10$2Dq0w6NRTOID2G1xporNUO2ZG2e3qYOzHmDdzmwk89UymFC5YUJAi	ADOPTER	t	\N	2026-09-20 02:15:32.768865+02	2026-09-20 02:15:32.768865+02
7	marta.sanchez@correo.test	$2a$10$2Dq0w6NRTOID2G1xporNUO2ZG2e3qYOzHmDdzmwk89UymFC5YUJAi	ADOPTER	t	\N	2026-10-05 02:15:32.768865+02	2026-10-05 02:15:32.768865+02
8	pablo.romero@correo.test	$2a$10$2Dq0w6NRTOID2G1xporNUO2ZG2e3qYOzHmDdzmwk89UymFC5YUJAi	ADOPTER	t	\N	2026-10-10 02:15:32.768865+02	2026-10-10 02:15:32.768865+02
9	elena.navarro@correo.test	$2a$10$2Dq0w6NRTOID2G1xporNUO2ZG2e3qYOzHmDdzmwk89UymFC5YUJAi	ADOPTER	t	\N	2026-10-20 02:15:32.768865+02	2026-10-20 02:15:32.768865+02
10	sergio.gil@correo.test	$2a$10$2Dq0w6NRTOID2G1xporNUO2ZG2e3qYOzHmDdzmwk89UymFC5YUJAi	ADOPTER	t	\N	2026-08-31 02:15:32.768865+02	2026-08-31 02:15:32.768865+02
11	carmen.ruiz@correo.test	$2a$10$2Dq0w6NRTOID2G1xporNUO2ZG2e3qYOzHmDdzmwk89UymFC5YUJAi	ADOPTER	t	\N	2026-09-10 02:15:32.768865+02	2026-09-10 02:15:32.768865+02
12	diego.torres@correo.test	$2a$10$2Dq0w6NRTOID2G1xporNUO2ZG2e3qYOzHmDdzmwk89UymFC5YUJAi	ADOPTER	f	\N	2026-11-19 01:15:32.768865+01	2026-11-19 01:15:32.768865+01
\.


--
-- Data for Name: audit_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.audit_log (id, id_user, table_name, id_record, operation, old_data, new_data, logged_at) FROM stdin;
1	\N	app_user	1	INSERT	\N	{"id": 1, "role": "ADMIN", "email": "admin@adopciones.test", "created_at": "2026-11-19T02:15:32.651419+01:00", "deleted_at": null, "updated_at": "2026-11-19T02:15:32.651419+01:00", "email_verified": true}	2026-11-19 02:15:32.651419+01
\.


--
-- Data for Name: breed; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.breed (id, id_species, name, created_at, updated_at) FROM stdin;
1	1	Mestizo / Desconocida	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
2	1	Labrador Retriever	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
3	1	Golden Retriever	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
4	1	Pastor Alemán	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
5	1	Pastor Belga Malinois	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
6	1	Podenco Andaluz	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
7	1	Podenco Ibicenco	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
8	1	Galgo Español	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
9	1	Bodeguero Andaluz	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
10	1	Mastín Español	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
11	1	Border Collie	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
12	1	Beagle	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
13	1	Bóxer	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
14	1	American Staffordshire Terrier	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
15	1	Pit Bull Terrier	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
16	1	Yorkshire Terrier	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
17	1	Chihuahua	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
18	1	Teckel	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
19	1	Caniche	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
20	1	Bulldog Francés	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
21	1	Husky Siberiano	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
22	1	Setter Inglés	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
23	2	Mestizo / Desconocida	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
24	2	Común Europeo	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
25	2	Siamés	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
26	2	Persa	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
27	2	Maine Coon	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
28	2	Británico de Pelo Corto	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
29	2	Bengalí	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
30	2	Ragdoll	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
31	2	Azul Ruso	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
32	2	Angora Turco	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
33	2	Sphynx	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
\.


--
-- Data for Name: conversation; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.conversation (id, id_adopter, id_shelter, last_message_at, created_at, updated_at) FROM stdin;
1	1	1	2026-10-30 02:15:32.768865+01	2026-10-16 02:15:32.768865+02	2026-10-30 02:15:32.768865+01
2	2	1	2026-11-17 02:15:32.768865+01	2026-11-05 02:15:32.768865+01	2026-11-17 02:15:32.768865+01
3	3	1	2026-11-14 02:15:32.768865+01	2026-11-06 02:15:32.768865+01	2026-11-14 02:15:32.768865+01
4	6	1	2026-11-13 02:15:32.768865+01	2026-11-13 02:15:32.768865+01	2026-11-13 02:15:32.768865+01
5	7	2	2026-11-14 02:15:32.768865+01	2026-10-06 02:15:32.768865+02	2026-11-14 02:15:32.768865+01
6	2	2	2026-11-18 06:15:32.768865+01	2026-11-13 02:15:32.768865+01	2026-11-18 06:15:32.768865+01
7	4	1	\N	2026-11-11 02:15:32.768865+01	2026-11-11 02:15:32.768865+01
8	5	1	\N	2026-11-09 02:15:32.768865+01	2026-11-09 02:15:32.768865+01
9	5	2	\N	2026-11-13 02:15:32.768865+01	2026-11-13 02:15:32.768865+01
10	3	2	\N	2026-11-18 21:15:32.768865+01	2026-11-18 21:15:32.768865+01
11	4	2	\N	2026-11-12 02:15:32.768865+01	2026-11-12 02:15:32.768865+01
\.


--
-- Data for Name: incident; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.incident (id, id_adopter, id_shelter, opened_by, id_visit, id_adoption, reason, details, status, resolved_at, resolution, created_at, updated_at, created_by, updated_by) FROM stdin;
1	4	2	ADOPTER	21	\N	INCORRECT_ATTENDANCE	Me marcaron como no asistido, pero estuve allí; tengo fotos con Canela.	RESOLVED	2026-11-18 02:15:32.768865+01	Confirmado con la protectora: la visita se realizó. Asistencia corregida.	2026-11-17 02:15:32.768865+01	2026-11-18 02:15:32.768865+01	8	1
2	6	1	ADOPTER	\N	\N	UNFAIR_BLOCK	Creo que me han bloqueado sin motivo.	OPEN	\N	\N	2026-11-14 02:15:32.768865+01	2026-11-14 02:15:32.768865+01	10	\N
3	5	2	SHELTER	17	\N	INAPPROPRIATE_BEHAVIOR	La adoptante respondió con insultos por chat cuando cancelamos su visita.	IN_REVIEW	\N	\N	2026-11-18 02:15:32.768865+01	2026-11-18 14:15:32.768865+01	3	1
\.


--
-- Data for Name: message; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.message (id, id_conversation, sender, body, image_url, read_at, created_at, updated_at) FROM stdin;
1	1	ADOPTER	¡Hola! Me encantó Toby en la visita. ¿Qué necesito para adoptarle?	\N	2026-10-23 02:15:32.768865+02	2026-10-23 02:15:32.768865+02	2026-10-23 02:15:32.768865+02
2	1	SHELTER	¡Hola, Lucía! Solo tienes que enviar la solicitud desde su ficha.	\N	2026-10-23 02:15:32.768865+02	2026-10-23 02:15:32.768865+02	2026-10-23 02:15:32.768865+02
3	1	ADOPTER	¡Toby ya está en casa y se lleva genial con mi gata!	/uploads/chat/1-1.jpg	2026-10-31 02:15:32.768865+01	2026-10-30 02:15:32.768865+01	2026-10-30 02:15:32.768865+01
4	2	ADOPTER	¿Luna se lleva bien con gatos?	\N	2026-11-06 02:15:32.768865+01	2026-11-06 02:15:32.768865+01	2026-11-06 02:15:32.768865+01
5	2	SHELTER	Sí, convive con dos gatos aquí en la protectora.	\N	2026-11-06 02:15:32.768865+01	2026-11-06 02:15:32.768865+01	2026-11-06 02:15:32.768865+01
6	2	SHELTER	¡Enhorabuena, Javier! ¿Qué día te viene bien para recoger a Luna?	\N	\N	2026-11-17 02:15:32.768865+01	2026-11-17 02:15:32.768865+01
7	3	ADOPTER	¿Rocky podría acompañarme a correr por las mañanas?	\N	2026-11-14 02:15:32.768865+01	2026-11-13 02:15:32.768865+01	2026-11-13 02:15:32.768865+01
8	3	SHELTER	¡Le encantaría! Tiene muchísima energía.	\N	\N	2026-11-14 02:15:32.768865+01	2026-11-14 02:15:32.768865+01
9	4	ADOPTER	¿Puedo llevar a mi perro a la visita de Max?	\N	2026-11-13 02:15:32.768865+01	2026-11-13 02:15:32.768865+01	2026-11-13 02:15:32.768865+01
10	5	ADOPTER	Michi se está adaptando muy bien.	\N	2026-10-20 02:15:32.768865+02	2026-10-20 02:15:32.768865+02	2026-10-20 02:15:32.768865+02
11	5	ADOPTER	Lo siento muchísimo: tengo que devolver a Michi por una alergia en casa.	\N	2026-11-13 02:15:32.768865+01	2026-11-13 02:15:32.768865+01	2026-11-13 02:15:32.768865+01
12	5	SHELTER	Lo entendemos, Carmen. Gracias por avisarnos con tiempo.	\N	2026-11-14 02:15:32.768865+01	2026-11-14 02:15:32.768865+01	2026-11-14 02:15:32.768865+01
13	6	SHELTER	Hemos cambiado el horario del turno del jueves; por favor, elige otro turno.	\N	2026-11-18 02:15:32.768865+01	2026-11-18 02:15:32.768865+01	2026-11-18 02:15:32.768865+01
14	6	ADOPTER	Hecho, ya he elegido el del viernes. ¡Gracias!	\N	\N	2026-11-18 06:15:32.768865+01	2026-11-18 06:15:32.768865+01
\.


--
-- Data for Name: notification; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.notification (id, id_user, type, body, read_at, id_visit, id_adoption, id_incident, created_at, updated_at) FROM stdin;
1	5	ADOPTION_APPROVED	¡Enhorabuena! Has sido elegida para adoptar a Toby.	2026-10-25 02:15:32.768865+01	\N	1	\N	2026-10-25 02:15:32.768865+01	2026-10-25 02:15:32.768865+01
2	5	VISIT_CONFIRMED	Tu visita para conocer a Kira está confirmada.	2026-11-15 02:15:32.768865+01	9	\N	\N	2026-11-15 02:15:32.768865+01	2026-11-15 02:15:32.768865+01
3	5	VISIT_VOIDED	Thor necesita un tratamiento veterinario y no está disponible por ahora. Te avisaremos si vuelve a estarlo.	\N	14	\N	\N	2026-11-17 02:15:32.768865+01	2026-11-17 02:15:32.768865+01
4	6	ADOPTION_APPROVED	¡Enhorabuena! Has sido elegido para adoptar a Luna.	\N	\N	2	\N	2026-11-17 02:15:32.768865+01	2026-11-17 02:15:32.768865+01
5	6	VISIT_EXPIRED	La protectora no respondió a tiempo a tu solicitud para conocer a Bruno.	\N	11	\N	\N	2026-11-18 02:15:32.768865+01	2026-11-18 02:15:32.768865+01
6	6	VISIT_VOIDED	La protectora ha cambiado el turno de tu visita a Nube. Elige otro turno.	2026-11-18 02:15:32.768865+01	19	\N	\N	2026-11-18 02:15:32.768865+01	2026-11-18 02:15:32.768865+01
7	6	VISIT_CONFIRMED	Tu visita para conocer a Nube está confirmada.	\N	20	\N	\N	2026-11-18 02:15:32.768865+01	2026-11-18 02:15:32.768865+01
8	7	VISIT_REJECTED	La protectora no ha podido confirmar tu visita para conocer a Kira.	2026-11-15 02:15:32.768865+01	12	\N	\N	2026-11-15 02:15:32.768865+01	2026-11-15 02:15:32.768865+01
9	7	ADOPTION_NOT_SELECTED	Luna ya ha encontrado un hogar. ¡Gracias por tu interés!	\N	\N	3	\N	2026-11-17 02:15:32.768865+01	2026-11-17 02:15:32.768865+01
10	8	INCIDENT_RESOLVED	Tu incidencia sobre la visita a Canela se ha resuelto.	\N	\N	\N	1	2026-11-18 02:15:32.768865+01	2026-11-18 02:15:32.768865+01
11	9	VISIT_VOIDED	Tu visita para conocer a Coco se ha anulado.	2026-11-13 02:15:32.768865+01	7	\N	\N	2026-11-13 02:15:32.768865+01	2026-11-13 02:15:32.768865+01
12	9	VISIT_CANCELLED	La protectora ha cancelado tu visita para conocer a Oliver.	\N	17	\N	\N	2026-11-18 02:15:32.768865+01	2026-11-18 02:15:32.768865+01
13	10	ADOPTER_BLOCKED	La protectora Huellas de Valencia ha restringido tu acceso a sus mascotas.	2026-11-13 02:15:32.768865+01	\N	\N	\N	2026-11-13 02:15:32.768865+01	2026-11-13 02:15:32.768865+01
14	10	VISIT_VOIDED	Tu visita para conocer a Max se ha anulado.	2026-11-13 02:15:32.768865+01	8	\N	\N	2026-11-13 02:15:32.768865+01	2026-11-13 02:15:32.768865+01
15	11	VISIT_CONFIRMED	Tu visita para conocer a Garfield está confirmada.	2026-11-14 02:15:32.768865+01	16	\N	\N	2026-11-14 02:15:32.768865+01	2026-11-14 02:15:32.768865+01
16	2	ADOPTION_PENDING_REMINDER	Tienes solicitudes de adopción de Rocky pendientes de respuesta.	\N	\N	4	\N	2026-11-18 02:15:32.768865+01	2026-11-18 02:15:32.768865+01
17	2	HANDOVER_PENDING_REMINDER	Recuerda registrar la entrega de Luna cuando se vaya con Javier.	\N	\N	2	\N	2026-11-18 02:15:32.768865+01	2026-11-18 02:15:32.768865+01
\.


--
-- Data for Name: pet; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pet (id, id_shelter, id_breed, name, sex, size, approx_birth_date, activity_level, children_compatibility, description, vaccinated, dewormed, neutered, microchipped, special_needs, adoption_fee, status, withdrawn_at, withdrawal_reason, created_at, updated_at, created_by, updated_by) FROM stdin;
1	1	2	Toby	MALE	LARGE	2022-11-19	HIGH	YES	Labrador cariñoso y juguetón. Adoptado.	t	t	t	t	\N	150.00	ADOPTED	\N	\N	2026-09-20 02:15:32.768865+02	2026-10-29 02:15:32.768865+01	2	2
2	1	1	Luna	FEMALE	MEDIUM	2024-11-19	MEDIUM	YES	Mestiza muy sociable con personas y animales.	t	t	t	t	\N	150.00	RESERVED	\N	\N	2026-10-05 02:15:32.768865+02	2026-11-17 02:15:32.768865+01	2	2
3	1	6	Rocky	MALE	MEDIUM	2023-11-19	HIGH	UNKNOWN	Podenco rescatado de una rehala. Necesita correr cada día.	t	t	t	t	\N	150.00	AVAILABLE	\N	\N	2026-10-10 02:15:32.768865+02	2026-10-10 02:15:32.768865+02	2	2
4	1	8	Nala	FEMALE	LARGE	2021-11-19	LOW	YES	Galga tranquila, ideal para un hogar sosegado.	t	t	t	t	\N	150.00	AVAILABLE	\N	\N	2026-10-15 02:15:32.768865+02	2026-10-15 02:15:32.768865+02	2	2
5	1	9	Coco	MALE	SMALL	2025-11-19	HIGH	YES	Bodeguero joven con mucha energía.	t	t	f	t	\N	120.00	AVAILABLE	\N	\N	2026-10-20 02:15:32.768865+02	2026-10-20 02:15:32.768865+02	2	2
6	1	4	Max	MALE	LARGE	2020-11-19	MEDIUM	NO	Pastor alemán protector; mejor sin niños pequeños ni otros animales.	t	t	t	t	\N	150.00	AVAILABLE	\N	\N	2026-10-22 02:15:32.768865+02	2026-10-22 02:15:32.768865+02	2	2
7	1	11	Kira	FEMALE	MEDIUM	2024-11-19	HIGH	YES	Border collie muy lista; le encanta aprender trucos.	t	t	t	t	\N	150.00	AVAILABLE	\N	\N	2026-10-25 02:15:32.768865+01	2026-10-25 02:15:32.768865+01	2	2
8	1	10	Thor	MALE	LARGE	2019-11-19	LOW	YES	Mastín noble y tranquilo.	t	t	t	t	Displasia de cadera en tratamiento.	150.00	WITHDRAWN	2026-11-17 02:15:32.768865+01	MEDICAL_TREATMENT	2026-10-28 02:15:32.768865+01	2026-11-17 02:15:32.768865+01	2	2
9	1	16	Lola	FEMALE	SMALL	2017-11-19	LOW	UNKNOWN	Yorkshire senior que busca un sofá donde descansar.	t	t	t	t	Necesita pienso renal.	80.00	AVAILABLE	\N	\N	2026-10-30 02:15:32.768865+01	2026-10-30 02:15:32.768865+01	2	2
10	1	14	Bruno	MALE	MEDIUM	2022-11-19	MEDIUM	YES	Amstaff bonachón, muy apegado a las personas.	t	t	t	t	\N	150.00	AVAILABLE	\N	\N	2026-11-01 02:15:32.768865+01	2026-11-01 02:15:32.768865+01	2	2
11	1	24	Misi	FEMALE	SMALL	2023-11-19	LOW	YES	Gata tranquila que convive con perros.	t	t	t	t	\N	60.00	AVAILABLE	\N	\N	2026-11-04 02:15:32.768865+01	2026-11-04 02:15:32.768865+01	2	2
12	1	23	Simba	MALE	SMALL	2026-07-19	HIGH	UNKNOWN	Gatito de cuatro meses, curioso y juguetón.	t	t	f	f	\N	\N	AVAILABLE	\N	\N	2026-11-12 02:15:32.768865+01	2026-11-12 02:15:32.768865+01	2	2
13	2	24	Michi	MALE	SMALL	2024-11-19	MEDIUM	YES	Volvió a la asociación tras una adopción que no salió bien.	t	t	t	t	\N	80.00	AVAILABLE	\N	\N	2026-09-10 02:15:32.768865+02	2026-11-14 02:15:32.768865+01	3	3
14	2	26	Garfield	MALE	MEDIUM	2018-11-19	LOW	YES	Persa dormilón y muy mimoso.	t	t	t	t	Cepillado diario.	80.00	AVAILABLE	\N	\N	2026-09-30 02:15:32.768865+02	2026-09-30 02:15:32.768865+02	3	3
15	2	23	Salem	MALE	SMALL	2025-11-19	HIGH	UNKNOWN	Gato negro rescatado de una colonia.	t	t	t	t	\N	80.00	AVAILABLE	\N	\N	2026-10-20 02:15:32.768865+02	2026-10-20 02:15:32.768865+02	3	3
16	2	32	Nube	FEMALE	SMALL	2023-11-19	LOW	YES	Angora blanca, tímida al principio.	t	t	t	t	\N	80.00	AVAILABLE	\N	\N	2026-10-24 02:15:32.768865+02	2026-10-24 02:15:32.768865+02	3	3
17	2	29	Tigre	MALE	MEDIUM	2024-11-19	HIGH	NO	Bengalí muy activo; mejor como único gato.	t	t	t	t	\N	100.00	AVAILABLE	\N	\N	2026-10-28 02:15:32.768865+01	2026-10-28 02:15:32.768865+01	3	3
18	2	30	Pelusa	FEMALE	MEDIUM	2021-11-19	LOW	YES	Ragdoll muy dócil.	t	t	t	t	\N	80.00	WITHDRAWN	2026-11-13 02:15:32.768865+01	FOSTER_CARE	2026-10-10 02:15:32.768865+02	2026-11-13 02:15:32.768865+01	3	3
19	2	25	Oliver	MALE	SMALL	2020-11-19	MEDIUM	YES	Siamés hablador y sociable.	t	t	t	t	\N	80.00	AVAILABLE	\N	\N	2026-11-07 02:15:32.768865+01	2026-11-07 02:15:32.768865+01	3	3
20	2	12	Canela	FEMALE	MEDIUM	2023-11-19	HIGH	YES	Beagle rescatada de un laboratorio.	t	t	t	t	\N	150.00	AVAILABLE	\N	\N	2026-10-30 02:15:32.768865+01	2026-10-30 02:15:32.768865+01	3	3
21	2	17	Chispa	FEMALE	SMALL	2016-11-19	LOW	NO	Chihuahua senior que busca un hogar tranquilo sin niños.	t	t	t	t	\N	50.00	AVAILABLE	\N	\N	2026-11-09 02:15:32.768865+01	2026-11-09 02:15:32.768865+01	3	3
22	3	1	Duque	MALE	LARGE	2023-11-19	MEDIUM	UNKNOWN	Mestizo grande y tranquilo.	t	f	f	t	\N	\N	AVAILABLE	\N	\N	2026-11-15 02:15:32.768865+01	2026-11-15 02:15:32.768865+01	4	4
23	3	23	Perla	FEMALE	SMALL	2024-11-19	LOW	UNKNOWN	Gata rescatada en la calle.	t	f	t	f	\N	\N	AVAILABLE	\N	\N	2026-11-15 02:15:32.768865+01	2026-11-15 02:15:32.768865+01	4	4
24	3	8	Rayo	MALE	LARGE	2022-11-19	LOW	YES	Galgo recuperado tras la temporada de caza.	t	t	t	t	\N	\N	AVAILABLE	\N	\N	2026-11-16 02:15:32.768865+01	2026-11-16 02:15:32.768865+01	4	4
25	3	24	Mora	FEMALE	SMALL	2025-11-19	MEDIUM	UNKNOWN	Gata joven y cariñosa.	t	f	f	f	\N	\N	AVAILABLE	\N	\N	2026-11-16 02:15:32.768865+01	2026-11-16 02:15:32.768865+01	4	4
\.


--
-- Data for Name: pet_compatibility_rel; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pet_compatibility_rel (id_pet, id_species, result) FROM stdin;
1	1	YES
1	2	NO
2	1	YES
2	2	YES
3	1	YES
4	1	YES
4	2	NO
5	1	YES
6	1	NO
6	2	NO
7	1	YES
7	2	YES
11	1	YES
11	2	YES
13	2	YES
14	1	YES
14	2	YES
17	2	NO
19	2	YES
20	1	YES
20	2	YES
21	1	NO
\.


--
-- Data for Name: pet_photo; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pet_photo (id, id_pet, url, display_order, created_at, updated_at) FROM stdin;
1	1	/uploads/pets/1-1.jpg	1	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
2	1	/uploads/pets/1-2.jpg	2	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
3	2	/uploads/pets/2-1.jpg	1	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
4	2	/uploads/pets/2-2.jpg	2	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
5	2	/uploads/pets/2-3.jpg	3	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
6	3	/uploads/pets/3-1.jpg	1	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
7	3	/uploads/pets/3-2.jpg	2	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
8	4	/uploads/pets/4-1.jpg	1	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
9	5	/uploads/pets/5-1.jpg	1	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
10	5	/uploads/pets/5-2.jpg	2	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
11	6	/uploads/pets/6-1.jpg	1	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
12	7	/uploads/pets/7-1.jpg	1	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
13	7	/uploads/pets/7-2.jpg	2	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
14	7	/uploads/pets/7-3.jpg	3	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
15	8	/uploads/pets/8-1.jpg	1	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
16	9	/uploads/pets/9-1.jpg	1	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
17	10	/uploads/pets/10-1.jpg	1	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
18	11	/uploads/pets/11-1.jpg	1	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
19	12	/uploads/pets/12-1.jpg	1	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
20	12	/uploads/pets/12-2.jpg	2	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
21	13	/uploads/pets/13-1.jpg	1	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
22	14	/uploads/pets/14-1.jpg	1	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
23	14	/uploads/pets/14-2.jpg	2	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
24	15	/uploads/pets/15-1.jpg	1	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
25	16	/uploads/pets/16-1.jpg	1	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
26	17	/uploads/pets/17-1.jpg	1	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
27	18	/uploads/pets/18-1.jpg	1	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
28	19	/uploads/pets/19-1.jpg	1	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
29	20	/uploads/pets/20-1.jpg	1	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
30	20	/uploads/pets/20-2.jpg	2	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
31	21	/uploads/pets/21-1.jpg	1	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
32	22	/uploads/pets/22-1.jpg	1	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
33	23	/uploads/pets/23-1.jpg	1	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
34	24	/uploads/pets/24-1.jpg	1	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
35	25	/uploads/pets/25-1.jpg	1	2026-11-19 02:15:32.768865+01	2026-11-19 02:15:32.768865+01
\.


--
-- Data for Name: pet_rating_rel; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pet_rating_rel (id_adopter, id_pet, rating, created_at, updated_at) FROM stdin;
1	7	FAVORITE	2026-11-09 02:15:32.768865+01	2026-11-09 02:15:32.768865+01
1	6	DISCARDED	2026-11-14 02:15:32.768865+01	2026-11-14 02:15:32.768865+01
1	9	DISCARDED	2026-10-10 02:15:32.768865+02	2026-10-10 02:15:32.768865+02
2	16	FAVORITE	2026-11-11 02:15:32.768865+01	2026-11-11 02:15:32.768865+01
2	13	FAVORITE	2026-11-16 02:15:32.768865+01	2026-11-16 02:15:32.768865+01
2	10	DISCARDED	2026-11-17 02:15:32.768865+01	2026-11-17 02:15:32.768865+01
3	3	FAVORITE	2026-11-07 02:15:32.768865+01	2026-11-07 02:15:32.768865+01
3	4	FAVORITE	2026-11-07 02:15:32.768865+01	2026-11-07 02:15:32.768865+01
4	3	FAVORITE	2026-11-10 02:15:32.768865+01	2026-11-10 02:15:32.768865+01
4	9	FAVORITE	2026-11-15 02:15:32.768865+01	2026-11-15 02:15:32.768865+01
7	14	FAVORITE	2026-11-13 02:15:32.768865+01	2026-11-13 02:15:32.768865+01
7	19	DISCARDED	2026-11-18 02:15:32.768865+01	2026-11-18 02:15:32.768865+01
\.


--
-- Data for Name: preference_activity_level; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.preference_activity_level (id_preference, activity_level) FROM stdin;
1	MEDIUM
1	HIGH
7	LOW
\.


--
-- Data for Name: preference_age_range; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.preference_age_range (id_preference, age_range) FROM stdin;
2	YOUNG
2	ADULT
7	ADULT
7	SENIOR
\.


--
-- Data for Name: preference_breed_rel; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.preference_breed_rel (id_preference, id_breed) FROM stdin;
3	6
3	8
\.


--
-- Data for Name: preference_compatibility_rel; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.preference_compatibility_rel (id_preference, id_species) FROM stdin;
1	2
\.


--
-- Data for Name: preference_sex; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.preference_sex (id_preference, sex) FROM stdin;
5	FEMALE
\.


--
-- Data for Name: preference_size; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.preference_size (id_preference, size) FROM stdin;
1	MEDIUM
1	LARGE
3	MEDIUM
6	LARGE
\.


--
-- Data for Name: preference_species_rel; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.preference_species_rel (id_preference, id_species) FROM stdin;
1	1
2	1
2	2
3	1
5	2
6	1
7	2
\.


--
-- Data for Name: province; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.province (id, name) FROM stdin;
1	Araba/Álava
2	Albacete
3	Alicante/Alacant
4	Almería
5	Ávila
6	Badajoz
7	Illes Balears
8	Barcelona
9	Burgos
10	Cáceres
11	Cádiz
12	Castellón/Castelló
13	Ciudad Real
14	Córdoba
15	A Coruña
16	Cuenca
17	Girona
18	Granada
19	Guadalajara
20	Gipuzkoa
21	Huelva
22	Huesca
23	Jaén
24	León
25	Lleida
26	La Rioja
27	Lugo
28	Madrid
29	Málaga
30	Murcia
31	Navarra
32	Ourense
33	Asturias
34	Palencia
35	Las Palmas
36	Pontevedra
37	Salamanca
38	Santa Cruz de Tenerife
39	Cantabria
40	Segovia
41	Sevilla
42	Soria
43	Tarragona
44	Teruel
45	Toledo
46	Valencia/València
47	Valladolid
48	Bizkaia
49	Zamora
50	Zaragoza
51	Ceuta
52	Melilla
\.


--
-- Data for Name: shelter; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.shelter (id, id_user, name, cif, description, phone, contact_email, address, postal_code, city, id_province, website, logo_url, opening_hours, verification_status, verified_at, rejection_reason, created_at, updated_at) FROM stdin;
1	2	Protectora Huellas de Valencia	G46123456	Rescatamos perros y gatos abandonados en la comarca de L'Horta desde 2012.	961000001	info@huellasvalencia.test	Camí del Riu, 15	46019	Valencia	46	https://huellasvalencia.test	/uploads/shelters/1.png	Lunes a sábado, de 10:00 a 13:00 y de 17:00 a 19:00	VERIFIED	2026-07-24 02:15:32.768865+02	\N	2026-07-22 02:15:32.768865+02	2026-07-24 02:15:32.768865+02
2	3	Asociación Bigotes Libres	G28123456	Asociación felina con colonias controladas y casas de acogida en Madrid.	911000002	hola@bigoteslibres.test	Calle del Gato, 7	28045	Madrid	28	\N	/uploads/shelters/2.png	Visitas con cita previa	VERIFIED	2026-06-24 02:15:32.768865+02	\N	2026-06-22 02:15:32.768865+02	2026-06-24 02:15:32.768865+02
3	4	Refugio Patas Nuevas	G03123456	Refugio recién creado en la Vega Baja.	965000003	\N	Partida La Matanza, s/n	03300	Orihuela	3	\N	\N	\N	PENDING	\N	\N	2026-11-14 02:15:32.768865+01	2026-11-14 02:15:32.768865+01
\.


--
-- Data for Name: species; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.species (id, name, created_at, updated_at) FROM stdin;
1	Perro	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
2	Gato	2026-11-19 02:15:32.651419+01	2026-11-19 02:15:32.651419+01
\.


--
-- Data for Name: suspension; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.suspension (id, id_user, reason, details, ended_at, created_at, updated_at, created_by, updated_by) FROM stdin;
1	10	INAPPROPRIATE_BEHAVIOR	Varias incidencias por mensajes ofensivos.	2026-10-05 02:15:32.768865+02	2026-09-20 02:15:32.768865+02	2026-10-05 02:15:32.768865+02	1	1
\.


--
-- Data for Name: visit; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.visit (id, id_adopter, id_pet, id_visit_slot, status, responded_at, rejection_reason, cancelled_at, cancelled_by, void_reason, attendance_recorded_at, attendance_automatic, corrected_by_admin, corrected_at, id_replaced_visit, created_at, updated_at, created_by, updated_by) FROM stdin;
1	1	1	1	COMPLETED	2026-10-17 02:15:32.768865+02	\N	\N	\N	\N	2026-10-22 02:15:32.768865+02	t	f	\N	\N	2026-10-16 02:15:32.768865+02	2026-10-22 02:15:32.768865+02	5	\N
2	2	2	2	COMPLETED	2026-11-06 02:15:32.768865+01	\N	\N	\N	\N	2026-11-11 02:15:32.768865+01	t	f	\N	\N	2026-11-05 02:15:32.768865+01	2026-11-11 02:15:32.768865+01	6	\N
3	3	2	3	COMPLETED	2026-11-06 02:15:32.768865+01	\N	\N	\N	\N	2026-11-12 02:15:32.768865+01	t	f	\N	\N	2026-11-06 02:15:32.768865+01	2026-11-12 02:15:32.768865+01	7	\N
4	3	3	5	COMPLETED	2026-11-08 02:15:32.768865+01	\N	\N	\N	\N	2026-11-14 02:15:32.768865+01	t	f	\N	\N	2026-11-08 02:15:32.768865+01	2026-11-14 02:15:32.768865+01	7	\N
5	4	3	6	COMPLETED	2026-11-11 02:15:32.768865+01	\N	\N	\N	\N	2026-11-17 02:15:32.768865+01	t	f	\N	\N	2026-11-11 02:15:32.768865+01	2026-11-17 02:15:32.768865+01	8	\N
6	5	4	4	NO_SHOW	2026-11-09 02:15:32.768865+01	\N	\N	\N	\N	2026-11-13 13:00:00+01	f	f	\N	\N	2026-11-09 02:15:32.768865+01	2026-11-13 02:15:32.768865+01	9	2
7	5	5	7	VOIDED	2026-11-12 02:15:32.768865+01	\N	\N	\N	NO_SHOW	\N	f	f	\N	\N	2026-11-12 02:15:32.768865+01	2026-11-13 02:15:32.768865+01	9	\N
8	6	6	7	VOIDED	2026-11-13 02:15:32.768865+01	\N	\N	\N	ADOPTER_BLOCKED	\N	f	f	\N	\N	2026-11-13 02:15:32.768865+01	2026-11-13 02:15:32.768865+01	10	\N
9	1	7	7	CONFIRMED	2026-11-15 02:15:32.768865+01	\N	\N	\N	\N	\N	f	f	\N	\N	2026-11-14 02:15:32.768865+01	2026-11-15 02:15:32.768865+01	5	2
10	4	9	8	PENDING	\N	\N	\N	\N	\N	\N	f	f	\N	\N	2026-11-18 23:15:32.768865+01	2026-11-18 23:15:32.768865+01	8	\N
11	2	10	9	EXPIRED	\N	\N	\N	\N	\N	\N	f	f	\N	\N	2026-11-17 02:15:32.768865+01	2026-11-18 02:15:32.768865+01	6	\N
12	3	7	8	REJECTED	2026-11-15 02:15:32.768865+01	Kira ya tiene una visita confirmada esa semana; te proponemos otro turno por el chat.	\N	\N	\N	\N	f	f	\N	\N	2026-11-15 02:15:32.768865+01	2026-11-15 02:15:32.768865+01	7	2
13	4	6	8	CANCELLED	2026-11-16 02:15:32.768865+01	\N	2026-11-18 02:15:32.768865+01	ADOPTER	\N	\N	f	f	\N	\N	2026-11-15 02:15:32.768865+01	2026-11-18 02:15:32.768865+01	8	8
14	1	8	8	VOIDED	2026-11-16 02:15:32.768865+01	\N	\N	\N	MEDICAL_TREATMENT	\N	f	f	\N	\N	2026-11-15 02:15:32.768865+01	2026-11-17 02:15:32.768865+01	5	2
15	7	13	11	COMPLETED	2026-10-07 02:15:32.768865+02	\N	\N	\N	\N	2026-10-12 02:15:32.768865+02	t	f	\N	\N	2026-10-06 02:15:32.768865+02	2026-10-12 02:15:32.768865+02	11	\N
16	7	14	13	CONFIRMED	2026-11-14 02:15:32.768865+01	\N	\N	\N	\N	\N	f	f	\N	\N	2026-11-14 02:15:32.768865+01	2026-11-14 02:15:32.768865+01	11	3
17	5	19	13	CANCELLED	2026-11-14 02:15:32.768865+01	\N	2026-11-18 02:15:32.768865+01	SHELTER	\N	\N	f	f	\N	\N	2026-11-13 02:15:32.768865+01	2026-11-18 02:15:32.768865+01	9	3
18	3	15	13	PENDING	\N	\N	\N	\N	\N	\N	f	f	\N	\N	2026-11-18 21:15:32.768865+01	2026-11-18 21:15:32.768865+01	7	\N
19	2	16	14	VOIDED	2026-11-13 02:15:32.768865+01	\N	\N	\N	SLOT_CANCELLED	\N	f	f	\N	\N	2026-11-13 02:15:32.768865+01	2026-11-18 02:15:32.768865+01	6	3
20	2	16	15	CONFIRMED	2026-11-18 02:15:32.768865+01	\N	\N	\N	\N	\N	f	f	\N	19	2026-11-18 02:15:32.768865+01	2026-11-18 02:15:32.768865+01	6	\N
21	4	20	12	COMPLETED	2026-11-12 02:15:32.768865+01	\N	\N	\N	\N	2026-11-16 14:00:00+01	f	t	2026-11-18 02:15:32.768865+01	\N	2026-11-12 02:15:32.768865+01	2026-11-18 02:15:32.768865+01	8	1
\.


--
-- Data for Name: visit_slot; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.visit_slot (id, id_shelter, slot_date, start_time, end_time, capacity, created_at, updated_at, created_by, updated_by) FROM stdin;
1	1	2026-10-20	10:00:00	11:00:00	3	2026-10-15 02:15:32.768865+02	2026-10-15 02:15:32.768865+02	2	2
2	1	2026-11-09	10:00:00	11:00:00	3	2026-11-04 02:15:32.768865+01	2026-11-04 02:15:32.768865+01	2	2
3	1	2026-11-10	17:00:00	18:00:00	3	2026-11-04 02:15:32.768865+01	2026-11-04 02:15:32.768865+01	2	2
4	1	2026-11-13	10:00:00	11:00:00	3	2026-11-07 02:15:32.768865+01	2026-11-07 02:15:32.768865+01	2	2
5	1	2026-11-12	17:00:00	18:00:00	3	2026-11-07 02:15:32.768865+01	2026-11-07 02:15:32.768865+01	2	2
6	1	2026-11-15	10:00:00	11:00:00	3	2026-11-07 02:15:32.768865+01	2026-11-07 02:15:32.768865+01	2	2
7	1	2026-11-22	10:00:00	11:00:00	4	2026-11-11 02:15:32.768865+01	2026-11-11 02:15:32.768865+01	2	2
8	1	2026-11-24	17:00:00	18:00:00	4	2026-11-11 02:15:32.768865+01	2026-11-11 02:15:32.768865+01	2	2
9	1	2026-11-25	10:00:00	11:00:00	2	2026-11-11 02:15:32.768865+01	2026-11-11 02:15:32.768865+01	2	2
10	1	2026-11-29	10:00:00	12:00:00	5	2026-11-18 02:15:32.768865+01	2026-11-18 02:15:32.768865+01	2	2
11	2	2026-10-10	11:00:00	12:00:00	2	2026-10-05 02:15:32.768865+02	2026-10-05 02:15:32.768865+02	3	3
12	2	2026-11-16	11:00:00	12:00:00	2	2026-11-09 02:15:32.768865+01	2026-11-09 02:15:32.768865+01	3	3
13	2	2026-11-22	11:00:00	12:00:00	3	2026-11-12 02:15:32.768865+01	2026-11-12 02:15:32.768865+01	3	3
14	2	2026-11-23	18:00:00	19:00:00	2	2026-11-12 02:15:32.768865+01	2026-11-18 02:15:32.768865+01	3	3
15	2	2026-11-24	11:00:00	12:00:00	3	2026-11-18 02:15:32.768865+01	2026-11-18 02:15:32.768865+01	3	3
16	3	2026-11-26	10:00:00	11:00:00	2	2026-11-16 02:15:32.768865+01	2026-11-16 02:15:32.768865+01	4	4
\.


--
-- Name: adopter_block_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.adopter_block_id_seq', 2, true);


--
-- Name: adopter_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.adopter_id_seq', 8, true);


--
-- Name: adopter_preference_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.adopter_preference_id_seq', 7, true);


--
-- Name: adoption_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.adoption_id_seq', 7, true);


--
-- Name: app_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.app_user_id_seq', 12, true);


--
-- Name: audit_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.audit_log_id_seq', 1, true);


--
-- Name: breed_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.breed_id_seq', 33, true);


--
-- Name: conversation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.conversation_id_seq', 11, true);


--
-- Name: incident_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.incident_id_seq', 3, true);


--
-- Name: message_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.message_id_seq', 14, true);


--
-- Name: notification_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.notification_id_seq', 17, true);


--
-- Name: pet_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.pet_id_seq', 25, true);


--
-- Name: pet_photo_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.pet_photo_id_seq', 35, true);


--
-- Name: shelter_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.shelter_id_seq', 3, true);


--
-- Name: species_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.species_id_seq', 2, true);


--
-- Name: suspension_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.suspension_id_seq', 1, true);


--
-- Name: visit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.visit_id_seq', 21, true);


--
-- Name: visit_slot_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.visit_slot_id_seq', 16, true);


--
-- Name: adopter_block adopter_block_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adopter_block
    ADD CONSTRAINT adopter_block_pkey PRIMARY KEY (id);


--
-- Name: adopter adopter_id_user_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adopter
    ADD CONSTRAINT adopter_id_user_key UNIQUE (id_user);


--
-- Name: adopter adopter_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adopter
    ADD CONSTRAINT adopter_pkey PRIMARY KEY (id);


--
-- Name: adopter_preference adopter_preference_id_adopter_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adopter_preference
    ADD CONSTRAINT adopter_preference_id_adopter_key UNIQUE (id_adopter);


--
-- Name: adopter_preference adopter_preference_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adopter_preference
    ADD CONSTRAINT adopter_preference_pkey PRIMARY KEY (id);


--
-- Name: adoption adoption_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adoption
    ADD CONSTRAINT adoption_pkey PRIMARY KEY (id);


--
-- Name: app_user app_user_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT app_user_pkey PRIMARY KEY (id);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: breed breed_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.breed
    ADD CONSTRAINT breed_pkey PRIMARY KEY (id);


--
-- Name: conversation conversation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation
    ADD CONSTRAINT conversation_pkey PRIMARY KEY (id);


--
-- Name: incident incident_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident
    ADD CONSTRAINT incident_pkey PRIMARY KEY (id);


--
-- Name: message message_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message
    ADD CONSTRAINT message_pkey PRIMARY KEY (id);


--
-- Name: notification notification_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_pkey PRIMARY KEY (id);


--
-- Name: pet_compatibility_rel pet_compatibility_rel_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pet_compatibility_rel
    ADD CONSTRAINT pet_compatibility_rel_pkey PRIMARY KEY (id_pet, id_species);


--
-- Name: pet_photo pet_photo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pet_photo
    ADD CONSTRAINT pet_photo_pkey PRIMARY KEY (id);


--
-- Name: pet pet_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pet
    ADD CONSTRAINT pet_pkey PRIMARY KEY (id);


--
-- Name: pet_rating_rel pet_rating_rel_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pet_rating_rel
    ADD CONSTRAINT pet_rating_rel_pkey PRIMARY KEY (id_adopter, id_pet);


--
-- Name: preference_activity_level preference_activity_level_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preference_activity_level
    ADD CONSTRAINT preference_activity_level_pkey PRIMARY KEY (id_preference, activity_level);


--
-- Name: preference_age_range preference_age_range_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preference_age_range
    ADD CONSTRAINT preference_age_range_pkey PRIMARY KEY (id_preference, age_range);


--
-- Name: preference_breed_rel preference_breed_rel_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preference_breed_rel
    ADD CONSTRAINT preference_breed_rel_pkey PRIMARY KEY (id_preference, id_breed);


--
-- Name: preference_compatibility_rel preference_compatibility_rel_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preference_compatibility_rel
    ADD CONSTRAINT preference_compatibility_rel_pkey PRIMARY KEY (id_preference, id_species);


--
-- Name: preference_sex preference_sex_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preference_sex
    ADD CONSTRAINT preference_sex_pkey PRIMARY KEY (id_preference, sex);


--
-- Name: preference_size preference_size_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preference_size
    ADD CONSTRAINT preference_size_pkey PRIMARY KEY (id_preference, size);


--
-- Name: preference_species_rel preference_species_rel_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preference_species_rel
    ADD CONSTRAINT preference_species_rel_pkey PRIMARY KEY (id_preference, id_species);


--
-- Name: province province_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.province
    ADD CONSTRAINT province_name_key UNIQUE (name);


--
-- Name: province province_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.province
    ADD CONSTRAINT province_pkey PRIMARY KEY (id);


--
-- Name: shelter shelter_cif_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shelter
    ADD CONSTRAINT shelter_cif_key UNIQUE (cif);


--
-- Name: shelter shelter_id_user_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shelter
    ADD CONSTRAINT shelter_id_user_key UNIQUE (id_user);


--
-- Name: shelter shelter_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shelter
    ADD CONSTRAINT shelter_pkey PRIMARY KEY (id);


--
-- Name: species species_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.species
    ADD CONSTRAINT species_name_key UNIQUE (name);


--
-- Name: species species_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.species
    ADD CONSTRAINT species_pkey PRIMARY KEY (id);


--
-- Name: suspension suspension_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suspension
    ADD CONSTRAINT suspension_pkey PRIMARY KEY (id);


--
-- Name: breed uq_breed_species_name; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.breed
    ADD CONSTRAINT uq_breed_species_name UNIQUE (id_species, name);


--
-- Name: conversation uq_conversation_pair; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation
    ADD CONSTRAINT uq_conversation_pair UNIQUE (id_adopter, id_shelter);


--
-- Name: pet_photo uq_pet_photo_order; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pet_photo
    ADD CONSTRAINT uq_pet_photo_order UNIQUE (id_pet, display_order);


--
-- Name: visit uq_visit_adopter_pet; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visit
    ADD CONSTRAINT uq_visit_adopter_pet UNIQUE (id, id_adopter, id_pet);


--
-- Name: visit visit_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visit
    ADD CONSTRAINT visit_pkey PRIMARY KEY (id);


--
-- Name: visit_slot visit_slot_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visit_slot
    ADD CONSTRAINT visit_slot_pkey PRIMARY KEY (id);


--
-- Name: ix_adopter_block_adopter; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_adopter_block_adopter ON public.adopter_block USING btree (id_adopter);


--
-- Name: ix_adopter_province; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_adopter_province ON public.adopter USING btree (id_province);


--
-- Name: ix_adoption_adopter; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_adoption_adopter ON public.adoption USING btree (id_adopter);


--
-- Name: ix_adoption_pet; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_adoption_pet ON public.adoption USING btree (id_pet);


--
-- Name: ix_adoption_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_adoption_status ON public.adoption USING btree (status);


--
-- Name: ix_adoption_visit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_adoption_visit ON public.adoption USING btree (id_visit);


--
-- Name: ix_audit_log_record; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_audit_log_record ON public.audit_log USING btree (table_name, id_record);


--
-- Name: ix_conversation_shelter; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_conversation_shelter ON public.conversation USING btree (id_shelter);


--
-- Name: ix_incident_adopter; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_incident_adopter ON public.incident USING btree (id_adopter);


--
-- Name: ix_incident_shelter; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_incident_shelter ON public.incident USING btree (id_shelter);


--
-- Name: ix_incident_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_incident_status ON public.incident USING btree (status);


--
-- Name: ix_message_conversation_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_message_conversation_date ON public.message USING btree (id_conversation, created_at);


--
-- Name: ix_notification_user_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_notification_user_date ON public.notification USING btree (id_user, created_at DESC);


--
-- Name: ix_pet_breed; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_pet_breed ON public.pet USING btree (id_breed);


--
-- Name: ix_pet_rating_pet; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_pet_rating_pet ON public.pet_rating_rel USING btree (id_pet);


--
-- Name: ix_pet_shelter; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_pet_shelter ON public.pet USING btree (id_shelter);


--
-- Name: ix_pet_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_pet_status ON public.pet USING btree (status);


--
-- Name: ix_shelter_province; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_shelter_province ON public.shelter USING btree (id_province);


--
-- Name: ix_shelter_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_shelter_status ON public.shelter USING btree (verification_status);


--
-- Name: ix_suspension_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_suspension_user ON public.suspension USING btree (id_user);


--
-- Name: ix_visit_adopter; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_visit_adopter ON public.visit USING btree (id_adopter);


--
-- Name: ix_visit_pet; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_visit_pet ON public.visit USING btree (id_pet);


--
-- Name: ix_visit_slot; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_visit_slot ON public.visit USING btree (id_visit_slot);


--
-- Name: ix_visit_slot_shelter_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_visit_slot_shelter_date ON public.visit_slot USING btree (id_shelter, slot_date);


--
-- Name: ix_visit_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_visit_status ON public.visit USING btree (status);


--
-- Name: uq_adopter_block_active; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_adopter_block_active ON public.adopter_block USING btree (id_shelter, id_adopter) WHERE (unblocked_at IS NULL);


--
-- Name: uq_adoption_active_pet; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_adoption_active_pet ON public.adoption USING btree (id_pet) WHERE (status = ANY (ARRAY['APPROVED'::public.adoption_status, 'COMPLETED'::public.adoption_status]));


--
-- Name: uq_adoption_open_adopter_pet; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_adoption_open_adopter_pet ON public.adoption USING btree (id_adopter, id_pet) WHERE (status = ANY (ARRAY['PENDING'::public.adoption_status, 'APPROVED'::public.adoption_status]));


--
-- Name: uq_app_user_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_app_user_email ON public.app_user USING btree (lower((email)::text));


--
-- Name: uq_suspension_active; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_suspension_active ON public.suspension USING btree (id_user) WHERE (ended_at IS NULL);


--
-- Name: uq_visit_active_slot_pet; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_visit_active_slot_pet ON public.visit USING btree (id_visit_slot, id_pet) WHERE (status = ANY (ARRAY['PENDING'::public.visit_status, 'CONFIRMED'::public.visit_status, 'COMPLETED'::public.visit_status, 'NO_SHOW'::public.visit_status]));


--
-- Name: adopter trg_adopter_audit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_adopter_audit AFTER INSERT OR DELETE OR UPDATE ON public.adopter FOR EACH ROW EXECUTE FUNCTION public.fn_audit();


--
-- Name: adopter_block trg_adopter_block_audit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_adopter_block_audit AFTER INSERT OR DELETE OR UPDATE ON public.adopter_block FOR EACH ROW EXECUTE FUNCTION public.fn_audit();


--
-- Name: adopter_block trg_adopter_block_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_adopter_block_updated_at BEFORE UPDATE ON public.adopter_block FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: adopter_preference trg_adopter_preference_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_adopter_preference_updated_at BEFORE UPDATE ON public.adopter_preference FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: adopter trg_adopter_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_adopter_updated_at BEFORE UPDATE ON public.adopter FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: adoption trg_adoption_audit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_adoption_audit AFTER INSERT OR DELETE OR UPDATE ON public.adoption FOR EACH ROW EXECUTE FUNCTION public.fn_audit();


--
-- Name: adoption trg_adoption_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_adoption_updated_at BEFORE UPDATE ON public.adoption FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: app_user trg_app_user_audit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_app_user_audit AFTER INSERT OR DELETE OR UPDATE ON public.app_user FOR EACH ROW EXECUTE FUNCTION public.fn_audit();


--
-- Name: app_user trg_app_user_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_app_user_updated_at BEFORE UPDATE ON public.app_user FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: breed trg_breed_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_breed_updated_at BEFORE UPDATE ON public.breed FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: conversation trg_conversation_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_conversation_updated_at BEFORE UPDATE ON public.conversation FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: incident trg_incident_audit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_incident_audit AFTER INSERT OR DELETE OR UPDATE ON public.incident FOR EACH ROW EXECUTE FUNCTION public.fn_audit();


--
-- Name: incident trg_incident_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_incident_updated_at BEFORE UPDATE ON public.incident FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: message trg_message_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_message_updated_at BEFORE UPDATE ON public.message FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: notification trg_notification_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_notification_updated_at BEFORE UPDATE ON public.notification FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: pet trg_pet_audit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_pet_audit AFTER INSERT OR DELETE OR UPDATE ON public.pet FOR EACH ROW EXECUTE FUNCTION public.fn_audit();


--
-- Name: pet_photo trg_pet_photo_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_pet_photo_updated_at BEFORE UPDATE ON public.pet_photo FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: pet_rating_rel trg_pet_rating_rel_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_pet_rating_rel_updated_at BEFORE UPDATE ON public.pet_rating_rel FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: pet trg_pet_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_pet_updated_at BEFORE UPDATE ON public.pet FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: shelter trg_shelter_audit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_shelter_audit AFTER INSERT OR DELETE OR UPDATE ON public.shelter FOR EACH ROW EXECUTE FUNCTION public.fn_audit();


--
-- Name: shelter trg_shelter_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_shelter_updated_at BEFORE UPDATE ON public.shelter FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: species trg_species_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_species_updated_at BEFORE UPDATE ON public.species FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: suspension trg_suspension_audit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_suspension_audit AFTER INSERT OR DELETE OR UPDATE ON public.suspension FOR EACH ROW EXECUTE FUNCTION public.fn_audit();


--
-- Name: suspension trg_suspension_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_suspension_updated_at BEFORE UPDATE ON public.suspension FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: visit trg_visit_audit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_visit_audit AFTER INSERT OR DELETE OR UPDATE ON public.visit FOR EACH ROW EXECUTE FUNCTION public.fn_audit();


--
-- Name: visit_slot trg_visit_slot_audit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_visit_slot_audit AFTER INSERT OR DELETE OR UPDATE ON public.visit_slot FOR EACH ROW EXECUTE FUNCTION public.fn_audit();


--
-- Name: visit_slot trg_visit_slot_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_visit_slot_updated_at BEFORE UPDATE ON public.visit_slot FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: visit trg_visit_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_visit_updated_at BEFORE UPDATE ON public.visit FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: adopter_block adopter_block_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adopter_block
    ADD CONSTRAINT adopter_block_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.app_user(id);


--
-- Name: adopter_block adopter_block_id_adopter_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adopter_block
    ADD CONSTRAINT adopter_block_id_adopter_fkey FOREIGN KEY (id_adopter) REFERENCES public.adopter(id);


--
-- Name: adopter_block adopter_block_id_shelter_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adopter_block
    ADD CONSTRAINT adopter_block_id_shelter_fkey FOREIGN KEY (id_shelter) REFERENCES public.shelter(id);


--
-- Name: adopter_block adopter_block_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adopter_block
    ADD CONSTRAINT adopter_block_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.app_user(id);


--
-- Name: adopter adopter_id_province_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adopter
    ADD CONSTRAINT adopter_id_province_fkey FOREIGN KEY (id_province) REFERENCES public.province(id);


--
-- Name: adopter adopter_id_user_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adopter
    ADD CONSTRAINT adopter_id_user_fkey FOREIGN KEY (id_user) REFERENCES public.app_user(id);


--
-- Name: adopter_preference adopter_preference_id_adopter_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adopter_preference
    ADD CONSTRAINT adopter_preference_id_adopter_fkey FOREIGN KEY (id_adopter) REFERENCES public.adopter(id) ON DELETE CASCADE;


--
-- Name: adoption adoption_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adoption
    ADD CONSTRAINT adoption_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.app_user(id);


--
-- Name: adoption adoption_id_adopter_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adoption
    ADD CONSTRAINT adoption_id_adopter_fkey FOREIGN KEY (id_adopter) REFERENCES public.adopter(id);


--
-- Name: adoption adoption_id_pet_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adoption
    ADD CONSTRAINT adoption_id_pet_fkey FOREIGN KEY (id_pet) REFERENCES public.pet(id);


--
-- Name: adoption adoption_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adoption
    ADD CONSTRAINT adoption_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.app_user(id);


--
-- Name: audit_log audit_log_id_user_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_id_user_fkey FOREIGN KEY (id_user) REFERENCES public.app_user(id);


--
-- Name: breed breed_id_species_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.breed
    ADD CONSTRAINT breed_id_species_fkey FOREIGN KEY (id_species) REFERENCES public.species(id);


--
-- Name: conversation conversation_id_adopter_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation
    ADD CONSTRAINT conversation_id_adopter_fkey FOREIGN KEY (id_adopter) REFERENCES public.adopter(id);


--
-- Name: conversation conversation_id_shelter_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation
    ADD CONSTRAINT conversation_id_shelter_fkey FOREIGN KEY (id_shelter) REFERENCES public.shelter(id);


--
-- Name: adoption fk_adoption_visit; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adoption
    ADD CONSTRAINT fk_adoption_visit FOREIGN KEY (id_visit, id_adopter, id_pet) REFERENCES public.visit(id, id_adopter, id_pet);


--
-- Name: incident incident_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident
    ADD CONSTRAINT incident_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.app_user(id);


--
-- Name: incident incident_id_adopter_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident
    ADD CONSTRAINT incident_id_adopter_fkey FOREIGN KEY (id_adopter) REFERENCES public.adopter(id);


--
-- Name: incident incident_id_adoption_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident
    ADD CONSTRAINT incident_id_adoption_fkey FOREIGN KEY (id_adoption) REFERENCES public.adoption(id);


--
-- Name: incident incident_id_shelter_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident
    ADD CONSTRAINT incident_id_shelter_fkey FOREIGN KEY (id_shelter) REFERENCES public.shelter(id);


--
-- Name: incident incident_id_visit_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident
    ADD CONSTRAINT incident_id_visit_fkey FOREIGN KEY (id_visit) REFERENCES public.visit(id);


--
-- Name: incident incident_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident
    ADD CONSTRAINT incident_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.app_user(id);


--
-- Name: message message_id_conversation_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message
    ADD CONSTRAINT message_id_conversation_fkey FOREIGN KEY (id_conversation) REFERENCES public.conversation(id);


--
-- Name: notification notification_id_adoption_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_id_adoption_fkey FOREIGN KEY (id_adoption) REFERENCES public.adoption(id);


--
-- Name: notification notification_id_incident_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_id_incident_fkey FOREIGN KEY (id_incident) REFERENCES public.incident(id);


--
-- Name: notification notification_id_user_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_id_user_fkey FOREIGN KEY (id_user) REFERENCES public.app_user(id);


--
-- Name: notification notification_id_visit_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_id_visit_fkey FOREIGN KEY (id_visit) REFERENCES public.visit(id);


--
-- Name: pet_compatibility_rel pet_compatibility_rel_id_pet_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pet_compatibility_rel
    ADD CONSTRAINT pet_compatibility_rel_id_pet_fkey FOREIGN KEY (id_pet) REFERENCES public.pet(id) ON DELETE CASCADE;


--
-- Name: pet_compatibility_rel pet_compatibility_rel_id_species_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pet_compatibility_rel
    ADD CONSTRAINT pet_compatibility_rel_id_species_fkey FOREIGN KEY (id_species) REFERENCES public.species(id);


--
-- Name: pet pet_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pet
    ADD CONSTRAINT pet_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.app_user(id);


--
-- Name: pet pet_id_breed_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pet
    ADD CONSTRAINT pet_id_breed_fkey FOREIGN KEY (id_breed) REFERENCES public.breed(id);


--
-- Name: pet pet_id_shelter_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pet
    ADD CONSTRAINT pet_id_shelter_fkey FOREIGN KEY (id_shelter) REFERENCES public.shelter(id);


--
-- Name: pet_photo pet_photo_id_pet_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pet_photo
    ADD CONSTRAINT pet_photo_id_pet_fkey FOREIGN KEY (id_pet) REFERENCES public.pet(id) ON DELETE CASCADE;


--
-- Name: pet_rating_rel pet_rating_rel_id_adopter_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pet_rating_rel
    ADD CONSTRAINT pet_rating_rel_id_adopter_fkey FOREIGN KEY (id_adopter) REFERENCES public.adopter(id) ON DELETE CASCADE;


--
-- Name: pet_rating_rel pet_rating_rel_id_pet_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pet_rating_rel
    ADD CONSTRAINT pet_rating_rel_id_pet_fkey FOREIGN KEY (id_pet) REFERENCES public.pet(id) ON DELETE CASCADE;


--
-- Name: pet pet_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pet
    ADD CONSTRAINT pet_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.app_user(id);


--
-- Name: preference_activity_level preference_activity_level_id_preference_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preference_activity_level
    ADD CONSTRAINT preference_activity_level_id_preference_fkey FOREIGN KEY (id_preference) REFERENCES public.adopter_preference(id) ON DELETE CASCADE;


--
-- Name: preference_age_range preference_age_range_id_preference_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preference_age_range
    ADD CONSTRAINT preference_age_range_id_preference_fkey FOREIGN KEY (id_preference) REFERENCES public.adopter_preference(id) ON DELETE CASCADE;


--
-- Name: preference_breed_rel preference_breed_rel_id_breed_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preference_breed_rel
    ADD CONSTRAINT preference_breed_rel_id_breed_fkey FOREIGN KEY (id_breed) REFERENCES public.breed(id);


--
-- Name: preference_breed_rel preference_breed_rel_id_preference_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preference_breed_rel
    ADD CONSTRAINT preference_breed_rel_id_preference_fkey FOREIGN KEY (id_preference) REFERENCES public.adopter_preference(id) ON DELETE CASCADE;


--
-- Name: preference_compatibility_rel preference_compatibility_rel_id_preference_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preference_compatibility_rel
    ADD CONSTRAINT preference_compatibility_rel_id_preference_fkey FOREIGN KEY (id_preference) REFERENCES public.adopter_preference(id) ON DELETE CASCADE;


--
-- Name: preference_compatibility_rel preference_compatibility_rel_id_species_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preference_compatibility_rel
    ADD CONSTRAINT preference_compatibility_rel_id_species_fkey FOREIGN KEY (id_species) REFERENCES public.species(id);


--
-- Name: preference_sex preference_sex_id_preference_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preference_sex
    ADD CONSTRAINT preference_sex_id_preference_fkey FOREIGN KEY (id_preference) REFERENCES public.adopter_preference(id) ON DELETE CASCADE;


--
-- Name: preference_size preference_size_id_preference_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preference_size
    ADD CONSTRAINT preference_size_id_preference_fkey FOREIGN KEY (id_preference) REFERENCES public.adopter_preference(id) ON DELETE CASCADE;


--
-- Name: preference_species_rel preference_species_rel_id_preference_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preference_species_rel
    ADD CONSTRAINT preference_species_rel_id_preference_fkey FOREIGN KEY (id_preference) REFERENCES public.adopter_preference(id) ON DELETE CASCADE;


--
-- Name: preference_species_rel preference_species_rel_id_species_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preference_species_rel
    ADD CONSTRAINT preference_species_rel_id_species_fkey FOREIGN KEY (id_species) REFERENCES public.species(id);


--
-- Name: shelter shelter_id_province_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shelter
    ADD CONSTRAINT shelter_id_province_fkey FOREIGN KEY (id_province) REFERENCES public.province(id);


--
-- Name: shelter shelter_id_user_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shelter
    ADD CONSTRAINT shelter_id_user_fkey FOREIGN KEY (id_user) REFERENCES public.app_user(id);


--
-- Name: suspension suspension_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suspension
    ADD CONSTRAINT suspension_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.app_user(id);


--
-- Name: suspension suspension_id_user_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suspension
    ADD CONSTRAINT suspension_id_user_fkey FOREIGN KEY (id_user) REFERENCES public.app_user(id);


--
-- Name: suspension suspension_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suspension
    ADD CONSTRAINT suspension_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.app_user(id);


--
-- Name: visit visit_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visit
    ADD CONSTRAINT visit_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.app_user(id);


--
-- Name: visit visit_id_adopter_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visit
    ADD CONSTRAINT visit_id_adopter_fkey FOREIGN KEY (id_adopter) REFERENCES public.adopter(id);


--
-- Name: visit visit_id_pet_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visit
    ADD CONSTRAINT visit_id_pet_fkey FOREIGN KEY (id_pet) REFERENCES public.pet(id);


--
-- Name: visit visit_id_replaced_visit_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visit
    ADD CONSTRAINT visit_id_replaced_visit_fkey FOREIGN KEY (id_replaced_visit) REFERENCES public.visit(id);


--
-- Name: visit visit_id_visit_slot_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visit
    ADD CONSTRAINT visit_id_visit_slot_fkey FOREIGN KEY (id_visit_slot) REFERENCES public.visit_slot(id);


--
-- Name: visit_slot visit_slot_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visit_slot
    ADD CONSTRAINT visit_slot_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.app_user(id);


--
-- Name: visit_slot visit_slot_id_shelter_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visit_slot
    ADD CONSTRAINT visit_slot_id_shelter_fkey FOREIGN KEY (id_shelter) REFERENCES public.shelter(id);


--
-- Name: visit_slot visit_slot_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visit_slot
    ADD CONSTRAINT visit_slot_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.app_user(id);


--
-- Name: visit visit_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visit
    ADD CONSTRAINT visit_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.app_user(id);


--
-- PostgreSQL database dump complete
--

\unrestrict LxjEzDhxYbEjg0ztmBXGoG3EJetCqtq4BaB1ueT1BFyS8pas0O8Ywt75kQSrM7d

