CREATE TABLE public.career_ladders (
  user_id uuid NOT NULL,
  base_role text NOT NULL,
  steps jsonb NOT NULL DEFAULT '[]'::jsonb,
  model text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  answers_hash text
);

CREATE TABLE public.career_path_generations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  industries jsonb NOT NULL DEFAULT '[]'::jsonb,
  roles jsonb NOT NULL,
  source_role text,
  model text,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.career_paths (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text NOT NULL,
  description text,
  icon text,
  category text,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  industry_id uuid
);

CREATE TABLE public.challenges (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  slug text NOT NULL,
  name text NOT NULL,
  description text NOT NULL DEFAULT ''::text,
  level text NOT NULL,
  level_bg text NOT NULL DEFAULT '#E8F2EA'::text,
  level_fg text NOT NULL DEFAULT '#155C3A'::text,
  tile_bg text NOT NULL DEFAULT '#E8F2EA'::text,
  tile_fg text NOT NULL DEFAULT '#155C3A'::text,
  points integer NOT NULL DEFAULT 0,
  duration_label text NOT NULL DEFAULT ''::text,
  icon text NOT NULL DEFAULT '★'::text,
  peers_joined integer NOT NULL DEFAULT 0,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.coffee_chat_bookings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  mentor_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'requested'::text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  booking_day date,
  booking_time text,
  topic text,
  questions text
);

CREATE TABLE public.companies (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text NOT NULL,
  ticker text,
  exchange text,
  country text NOT NULL,
  ownership_type text NOT NULL DEFAULT 'public'::text,
  sector text,
  logo_url text,
  short_description text,
  summary text,
  website text,
  linkedin_url text,
  headquarters text,
  founded_year integer,
  employee_count text,
  is_featured boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  industry_id uuid,
  footprint text,
  size_band text,
  hiring text[] NOT NULL DEFAULT '{}'::text[],
  subs text[] NOT NULL DEFAULT '{}'::text[],
  shepherds_count integer NOT NULL DEFAULT 0,
  uk_company_number text,
  is_visa_sponsor boolean NOT NULL DEFAULT false,
  sponsor_routes text[] NOT NULL DEFAULT '{}'::text[]
);

CREATE TABLE public.company_career_paths (
  company_id uuid NOT NULL,
  career_path_id uuid NOT NULL
);

CREATE TABLE public.company_enrichment (
  company_id uuid NOT NULL,
  growth_tier text,
  heat_tier text,
  stage text,
  revenue_range text,
  employees_range text,
  funding_rounds integer,
  total_funding_usd numeric,
  last_funding_date date,
  last_funding_type text,
  investors_top5 text,
  actively_hiring boolean,
  source text,
  imported_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.company_matches (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  target_role text NOT NULL DEFAULT 'Investment Banking Analyst'::text,
  company_name text NOT NULL,
  ticker text NOT NULL,
  exchange text NOT NULL,
  fit_score integer NOT NULL,
  reason text NOT NULL,
  initials text NOT NULL,
  color text NOT NULL,
  sort_order integer NOT NULL DEFAULT 0
);

CREATE TABLE public.company_roles (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL,
  career_path_id uuid,
  title text NOT NULL,
  description text,
  seniority text,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.company_unlocks (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  company_id uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.connections (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  target_name text NOT NULL,
  status text NOT NULL DEFAULT 'requested'::text,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.email_send_log (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  message_id text,
  template_name text NOT NULL,
  recipient_email text NOT NULL,
  status text NOT NULL,
  error_message text,
  metadata jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.email_send_state (
  id integer NOT NULL DEFAULT 1,
  retry_after_until timestamp with time zone,
  batch_size integer NOT NULL DEFAULT 10,
  send_delay_ms integer NOT NULL DEFAULT 200,
  auth_email_ttl_minutes integer NOT NULL DEFAULT 15,
  transactional_email_ttl_minutes integer NOT NULL DEFAULT 60,
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.email_unsubscribe_tokens (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  token text NOT NULL,
  email text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  used_at timestamp with time zone
);

CREATE TABLE public.feature_interest (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  feature text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.fx_rates (
  currency_code text NOT NULL,
  label text NOT NULL,
  rate_to_usd numeric NOT NULL,
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.growth_plan_categories (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  key text NOT NULL,
  name text NOT NULL,
  blurb text NOT NULL,
  sort_order integer NOT NULL DEFAULT 0
);

CREATE TABLE public.growth_plan_items (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  plan_id uuid NOT NULL,
  user_id uuid NOT NULL,
  kind text NOT NULL,
  category text,
  label text NOT NULL,
  level text,
  points integer,
  duration_label text,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  resource_category text,
  resource_query text
);

CREATE TABLE public.growth_plan_tasks (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  category_id uuid NOT NULL,
  label text NOT NULL,
  sort_order integer NOT NULL DEFAULT 0
);

CREATE TABLE public.growth_plans (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  role text NOT NULL,
  rationale text,
  model text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  category_blurbs jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE public.industries (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text NOT NULL,
  description text,
  icon text,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.joined_challenges (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  challenge_id uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.koffee_ledger (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  action text NOT NULL,
  subject text,
  points integer NOT NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.leaderboards (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  board_key text NOT NULL,
  rank integer NOT NULL,
  person_name text NOT NULL,
  initials text NOT NULL,
  color text NOT NULL,
  points integer NOT NULL,
  weekly_delta integer NOT NULL DEFAULT 0,
  challenges_completed integer NOT NULL DEFAULT 0,
  is_self boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.mentors (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  role_title text NOT NULL,
  company_name text,
  company_initials text,
  company_color text,
  focus_area text NOT NULL,
  region text NOT NULL,
  city text NOT NULL,
  city_key text NOT NULL,
  country text,
  location_label text NOT NULL,
  step_ahead text NOT NULL,
  bio text NOT NULL DEFAULT ''::text,
  availability text NOT NULL DEFAULT ''::text,
  avatar_initials text NOT NULL,
  avatar_color text NOT NULL,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  latitude double precision,
  longitude double precision,
  email text,
  user_id uuid,
  status text NOT NULL DEFAULT 'active'::text,
  organization_id uuid,
  past_companies text[] NOT NULL DEFAULT '{}'::text[],
  shepherd_settings jsonb NOT NULL DEFAULT '{}'::jsonb,
  avatar_url text,
  username text
);

CREATE TABLE public.next_actions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  target_role text NOT NULL DEFAULT 'Investment Banking Analyst'::text,
  text text NOT NULL,
  tag text NOT NULL,
  readiness_delta text NOT NULL,
  accent_color text NOT NULL DEFAULT '#1F8A5B'::text,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  mentor_id uuid,
  type text NOT NULL,
  title text NOT NULL,
  body text,
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  read boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.onboarding_responses (
  user_id uuid NOT NULL,
  answers jsonb NOT NULL DEFAULT '{}'::jsonb,
  intent text,
  completed_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  occupation_title text,
  occupation_code text,
  role text NOT NULL DEFAULT 'talent'::text
);

CREATE TABLE public.org_jobs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL,
  title text NOT NULL,
  dept text,
  location text,
  job_type text NOT NULL DEFAULT 'Full-time'::text,
  description text,
  status text NOT NULL DEFAULT 'live'::text,
  boosted boolean NOT NULL DEFAULT false,
  views integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.org_members (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL,
  user_id uuid NOT NULL,
  role org_member_role NOT NULL DEFAULT 'talent'::org_member_role,
  joined_via text,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.org_pipeline (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL,
  talent_user_id uuid NOT NULL,
  job_id uuid,
  stage pipeline_stage NOT NULL DEFAULT 'interested'::pipeline_stage,
  source text NOT NULL DEFAULT 'inbound'::text,
  referred_by_mentor_id uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.org_views (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL,
  job_id uuid,
  viewer_user_id uuid,
  kind text NOT NULL DEFAULT 'profile'::text,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.organizations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text NOT NULL,
  company_id uuid,
  visibility org_visibility NOT NULL DEFAULT 'public'::org_visibility,
  plan org_plan NOT NULL DEFAULT 'free'::org_plan,
  logo_url text,
  tagline text,
  mission text,
  culture_chips text[] NOT NULL DEFAULT '{}'::text[],
  work_email_domain text,
  open_roles_hint integer,
  shepherd_code text NOT NULL DEFAULT ('SH-'::text || upper(substr(md5((random())::text), 1, 6))),
  talent_code text NOT NULL DEFAULT ('TL-'::text || upper(substr(md5((random())::text), 1, 6))),
  inmail_used integer NOT NULL DEFAULT 0,
  created_by uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  careers_url text,
  qa jsonb NOT NULL DEFAULT '[]'::jsonb
);

CREATE TABLE public.plan_limits (
  tier subscription_tier NOT NULL,
  coffee_chats integer NOT NULL,
  chats_monthly boolean NOT NULL,
  koffee_points integer NOT NULL,
  company_access text NOT NULL
);

CREATE TABLE public.profiles (
  id uuid NOT NULL,
  display_name text,
  avatar_url text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  country text,
  email_notifications boolean NOT NULL DEFAULT true,
  product_updates boolean NOT NULL DEFAULT true,
  headline text,
  university text,
  city text,
  career_stage text,
  skills text[] NOT NULL DEFAULT '{}'::text[],
  welcome_email_sent_at timestamp with time zone
);

CREATE TABLE public.resources (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  collection_key text NOT NULL,
  category text NOT NULL,
  kind_label text NOT NULL DEFAULT ''::text,
  title text NOT NULL DEFAULT ''::text,
  by_line text NOT NULL DEFAULT ''::text,
  meta text NOT NULL DEFAULT ''::text,
  cover_bg text NOT NULL DEFAULT '#14342B'::text,
  cover_fg text NOT NULL DEFAULT '#BDE9CC'::text,
  is_leader boolean NOT NULL DEFAULT false,
  leader_initials text,
  leader_color text,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  career_path_id uuid,
  url text
);

CREATE TABLE public.salary_bands (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  label text NOT NULL,
  location text NOT NULL DEFAULT ''::text,
  band_text text NOT NULL,
  value_low numeric NOT NULL,
  value_high numeric NOT NULL,
  tone_color text NOT NULL DEFAULT '#1F8A5B'::text,
  sort_order integer NOT NULL DEFAULT 0
);

CREATE TABLE public.sector_bands (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  sector text NOT NULL,
  band_text text NOT NULL,
  value_low numeric NOT NULL,
  value_high numeric NOT NULL,
  tone_color text NOT NULL DEFAULT '#14342B'::text,
  is_target boolean NOT NULL DEFAULT false,
  sort_order integer NOT NULL DEFAULT 0
);

CREATE TABLE public.signup_applications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  role text NOT NULL,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  status text NOT NULL DEFAULT 'pending'::text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.similar_roles (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  role text NOT NULL,
  band_text text NOT NULL,
  value_low numeric NOT NULL,
  value_high numeric NOT NULL,
  firm_names text NOT NULL,
  more_count integer NOT NULL DEFAULT 0,
  firm_avatars jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0
);

CREATE TABLE public.skill_gaps (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  target_role text NOT NULL,
  skill_name text NOT NULL,
  have_level integer NOT NULL,
  need_level integer NOT NULL,
  status text NOT NULL,
  recommendation text NOT NULL DEFAULT ''::text,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.suppressed_emails (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  email text NOT NULL,
  reason text NOT NULL,
  metadata jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.talent_org_interest (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL,
  user_id uuid NOT NULL,
  kind org_interest_kind NOT NULL,
  reason text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  job_id uuid
);

CREATE TABLE public.talent_tiers (
  user_id uuid NOT NULL,
  tier talent_tier NOT NULL DEFAULT 'explorer'::talent_tier,
  verified_by uuid,
  verified_at timestamp with time zone,
  notes text,
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.uk_companies (
  company_number text NOT NULL,
  name text NOT NULL,
  normalized_name text DEFAULT uk_normalize_name(name),
  status text,
  company_category text,
  incorporation_date date,
  address_line text,
  post_town text,
  postcode text,
  country text,
  sic_codes text[] DEFAULT '{}'::text[],
  is_visa_sponsor boolean NOT NULL DEFAULT false,
  sponsor_routes text[] DEFAULT '{}'::text[],
  sponsor_rating text,
  sponsor_matched_via text,
  sponsor_match_score numeric,
  domain text,
  domain_source text,
  logo_url text,
  logo_status text NOT NULL DEFAULT 'pending'::text,
  logo_fetched_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.uk_sponsors (
  id bigint NOT NULL DEFAULT nextval('uk_sponsors_id_seq'::regclass),
  normalized_name text NOT NULL,
  display_name text NOT NULL,
  primary_city text,
  routes text[] DEFAULT '{}'::text[],
  best_rating text,
  company_number text,
  match_method text,
  match_score numeric,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.user_career_paths (
  user_id uuid NOT NULL,
  industries jsonb NOT NULL DEFAULT '[]'::jsonb,
  roles jsonb NOT NULL DEFAULT '[]'::jsonb,
  source_role text,
  model text,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  seen_titles text[] NOT NULL DEFAULT '{}'::text[]
);

CREATE TABLE public.user_company_matches (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  target_role text NOT NULL,
  items jsonb NOT NULL DEFAULT '[]'::jsonb,
  model text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.user_credits (
  user_id uuid NOT NULL,
  koffee_points integer NOT NULL DEFAULT 2,
  bonus_questions_completed boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  points_period date
);

CREATE TABLE public.user_roles (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  role app_role NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.user_saved_paths (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  role jsonb NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.user_subscriptions (
  user_id uuid NOT NULL,
  tier subscription_tier NOT NULL DEFAULT 'free'::subscription_tier,
  status text NOT NULL DEFAULT 'active'::text,
  current_period_start timestamp with time zone,
  current_period_end timestamp with time zone,
  provider text,
  provider_customer_id text,
  provider_subscription_id text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.user_task_progress (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  task_id uuid NOT NULL,
  completed boolean NOT NULL DEFAULT true,
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);
