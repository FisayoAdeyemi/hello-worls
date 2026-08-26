CREATE TYPE public.app_role AS ENUM ('admin', 'moderator', 'user');
CREATE TYPE public.org_interest_kind AS ENUM ('followed', 'saved', 'applied', 'chatted');
CREATE TYPE public.org_member_role AS ENUM ('owner', 'admin', 'recruiter', 'shepherd', 'talent');
CREATE TYPE public.org_plan AS ENUM ('free', 'pro', 'enterprise');
CREATE TYPE public.org_visibility AS ENUM ('public', 'private');
CREATE TYPE public.pipeline_stage AS ENUM ('interested', 'screening', 'coffee_chat', 'shortlist', 'offer');
CREATE TYPE public.subscription_tier AS ENUM ('free', 'plus', 'pro');
CREATE TYPE public.talent_tier AS ENUM ('explorer', 'emerging', 'unicorn');

CREATE SEQUENCE IF NOT EXISTS public.uk_sponsors_id_seq;
