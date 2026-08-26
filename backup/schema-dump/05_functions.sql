CREATE OR REPLACE FUNCTION public.adopt_uk_company(p_company_number text)
 RETURNS TABLE(company_id uuid, company_slug text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE uk RECORD; base_slug text; final_slug text; existing RECORD;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'auth required';
  END IF;

  SELECT * INTO uk FROM uk_companies WHERE company_number = p_company_number;
  IF uk.company_number IS NULL THEN
    RAISE EXCEPTION 'uk company not found';
  END IF;

  SELECT id, slug INTO existing FROM companies WHERE uk_company_number = p_company_number;
  IF existing.id IS NOT NULL THEN
    RETURN QUERY SELECT existing.id, existing.slug; RETURN;
  END IF;

  base_slug := left(regexp_replace(regexp_replace(lower(uk.name), '[^a-z0-9]+', '-', 'g'), '(^-+|-+$)', '', 'g'), 60);
  IF base_slug = '' THEN base_slug := 'uk-company'; END IF;
  final_slug := base_slug;
  IF EXISTS (SELECT 1 FROM companies WHERE slug = final_slug) THEN
    final_slug := base_slug || '-' || substr(md5(p_company_number), 1, 4);
  END IF;

  RETURN QUERY
  INSERT INTO companies (name, slug, country, ownership_type, sector, short_description,
                         logo_url, website, uk_company_number, is_visa_sponsor, sponsor_routes)
  VALUES (uk.name, final_slug, 'United Kingdom', 'private', 'UK Employer',
          CASE WHEN uk.is_visa_sponsor
               THEN 'Licensed UK visa sponsor' || COALESCE(' based in ' || uk.post_town, '') || '.'
               ELSE 'UK-registered company' || COALESCE(' based in ' || uk.post_town, '') || '.' END,
          uk.logo_url, CASE WHEN uk.domain IS NOT NULL THEN 'https://' || uk.domain END,
          uk.company_number, uk.is_visa_sponsor, COALESCE(uk.sponsor_routes, '{}'))
  RETURNING id, slug;
END $function$
;

CREATE OR REPLACE FUNCTION public.bootstrap_org_owner()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if new.created_by is not null then
    insert into public.org_members (org_id, user_id, role, joined_via)
    values (new.id, new.created_by, 'owner', 'creator')
    on conflict (org_id, user_id) do nothing;
  end if;
  return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.browse_companies(p_q text DEFAULT NULL::text, p_industry_slug text DEFAULT NULL::text, p_sub text DEFAULT NULL::text, p_country text DEFAULT NULL::text, p_ownership text DEFAULT NULL::text, p_hiring text[] DEFAULT NULL::text[], p_footprints text[] DEFAULT NULL::text[], p_sizes text[] DEFAULT NULL::text[], p_shepherd_names text[] DEFAULT NULL::text[], p_shepherds_only boolean DEFAULT false, p_offset integer DEFAULT 0, p_lim integer DEFAULT 30)
 RETURNS TABLE(id uuid, name text, slug text, ticker text, exchange text, country text, ownership_type text, sector text, logo_url text, website text, short_description text, headquarters text, employee_count text, industry_id uuid, industry_slug text, industry_name text, footprint text, size_band text, hiring text[], subs text[], shepherds_count integer, is_featured boolean, is_visa_sponsor boolean, total bigint)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  WITH shep AS (
    SELECT array_agg(DISTINCT public.uk_normalize_name(x)) AS names
      FROM unnest(COALESCE(p_shepherd_names, ARRAY[]::text[])) AS x
  ), base AS (
    SELECT c.*, i.slug AS i_slug, i.name AS i_name
      FROM public.companies c
      LEFT JOIN public.industries i ON i.id = c.industry_id
     WHERE (p_industry_slug IS NULL OR p_industry_slug = 'all' OR COALESCE(i.slug,'services') = p_industry_slug)
       AND (p_sub IS NULL OR p_sub = 'all' OR p_sub = ANY(COALESCE(c.subs, ARRAY[]::text[])) OR c.sector = p_sub)
       AND (p_country IS NULL OR p_country = 'all' OR c.country = p_country)
       AND (p_ownership IS NULL OR p_ownership = 'all' OR c.ownership_type = p_ownership)
       AND (p_hiring IS NULL OR array_length(p_hiring,1) IS NULL OR COALESCE(c.hiring, ARRAY[]::text[]) && p_hiring)
       AND (p_footprints IS NULL OR array_length(p_footprints,1) IS NULL OR c.footprint = ANY(p_footprints))
       AND (p_sizes IS NULL OR array_length(p_sizes,1) IS NULL OR c.size_band = ANY(p_sizes))
       AND (
         NOT COALESCE(p_shepherds_only, false)
         OR COALESCE(c.shepherds_count,0) > 0
         OR public.uk_normalize_name(c.name) = ANY (SELECT unnest(names) FROM shep)
       )
       AND (
         p_q IS NULL OR btrim(p_q) = ''
         OR c.name ILIKE '%' || btrim(p_q) || '%'
         OR c.ticker ILIKE btrim(p_q) || '%'
       )
  ), counted AS (SELECT count(*) AS n FROM base)
  SELECT b.id, b.name, b.slug, b.ticker, b.exchange, b.country,
         b.ownership_type, b.sector, b.logo_url, b.website,
         b.short_description, b.headquarters, b.employee_count,
         b.industry_id, COALESCE(b.i_slug,'services'), b.i_name,
         b.footprint, b.size_band, COALESCE(b.hiring, ARRAY[]::text[]), COALESCE(b.subs, ARRAY[]::text[]),
         COALESCE(b.shepherds_count,0), b.is_featured, b.is_visa_sponsor,
         (SELECT n FROM counted)
    FROM base b
   ORDER BY b.is_featured DESC, COALESCE(b.shepherds_count,0) DESC, b.name
   OFFSET GREATEST(COALESCE(p_offset,0),0)
   LIMIT LEAST(GREATEST(COALESCE(p_lim,30),1), 100);
$function$
;

CREATE OR REPLACE FUNCTION public.can_access_company(_company_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare t public.subscription_tier; own text;
begin
  t := public.get_my_tier();
  select ownership_type into own from public.companies where id=_company_id;
  if own is null then return false; end if;
  if t='pro' then return true; end if;
  if t='plus' then return own='public'; end if;
  return false;
end $function$
;

CREATE OR REPLACE FUNCTION public.charge_coffee_chat()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE info json; bal int; cost int := public.koffee_cost('coffee_chat');
BEGIN
  info := public.koffee_balance_for(NEW.user_id);
  bal := (info->>'balance')::int;
  IF bal < cost THEN
    RAISE EXCEPTION 'insufficient_koffee_points' USING ERRCODE = 'P0001';
  END IF;
  INSERT INTO public.koffee_ledger (user_id, action, subject, points, metadata)
  VALUES (NEW.user_id, 'coffee_chat', NEW.topic, -cost, jsonb_build_object('booking_id', NEW.id, 'mentor_id', NEW.mentor_id));
  INSERT INTO public.user_credits(user_id, koffee_points)
  VALUES (NEW.user_id, GREATEST(bal - cost, 0))
  ON CONFLICT (user_id) DO UPDATE SET koffee_points = EXCLUDED.koffee_points, updated_at = now();
  RETURN NEW;
END $function$
;

CREATE OR REPLACE FUNCTION public.claim_shepherd_profile()
 RETURNS TABLE(mentor_id uuid, claimed boolean, status text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE u_email text; u_name text; m RECORD;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'auth required'; END IF;
  SELECT email INTO u_email FROM auth.users WHERE id = auth.uid();
  SELECT COALESCE(NULLIF(display_name,''), split_part(u_email,'@',1)) INTO u_name FROM profiles WHERE id = auth.uid();

  SELECT * INTO m FROM mentors WHERE user_id = auth.uid() LIMIT 1;
  IF m.id IS NOT NULL THEN
    IF m.username IS NULL THEN
      UPDATE mentors SET username = public.gen_shepherd_username(COALESCE(m.email, u_email), COALESCE(m.name, u_name))
       WHERE id = m.id;
    END IF;
    IF COALESCE(m.status,'active') = 'invited' THEN
      UPDATE mentors SET status = 'active', updated_at = now() WHERE id = m.id;
      RETURN QUERY SELECT m.id, true, 'active'::text; RETURN;
    END IF;
    RETURN QUERY SELECT m.id, true, COALESCE(m.status,'active'); RETURN;
  END IF;

  SELECT * INTO m FROM mentors WHERE user_id IS NULL AND lower(email) = lower(u_email) LIMIT 1;
  IF m.id IS NOT NULL THEN
    UPDATE mentors SET user_id = auth.uid(), status = 'active', updated_at = now(),
           username = COALESCE(m.username, public.gen_shepherd_username(COALESCE(m.email, u_email), COALESCE(m.name, u_name)))
     WHERE id = m.id;
    RETURN QUERY SELECT m.id, true, 'active'::text; RETURN;
  END IF;

  RETURN QUERY
  INSERT INTO mentors (name, role_title, focus_area, region, city, city_key, country, location_label,
                       step_ahead, bio, availability, avatar_initials, avatar_color, sort_order,
                       email, user_id, status, username)
  VALUES (COALESCE(u_name,'New Shepherd'), 'Shepherd', 'Fintech', 'Africa', 'Lagos', 'lagos', 'Nigeria', '🇳🇬 Lagos',
          '1 step ahead', '', 'Available this week',
          upper(left(COALESCE(u_name,'NS'),1)) || upper(substr(COALESCE(u_name,'NS'), strpos(COALESCE(u_name,'NS'),' ')+1, 1)),
          '#1F5A3E', 999, u_email, auth.uid(), 'pending',
          public.gen_shepherd_username(u_email, u_name))
  RETURNING id, true, 'pending';
END $function$
;

CREATE OR REPLACE FUNCTION public.claim_shepherd_username(_desired text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  uid uuid := auth.uid();
  mentor_id uuid;
  base text;
  candidate text;
  i int := 1;
BEGIN
  IF uid IS NULL THEN RAISE EXCEPTION 'not-authenticated'; END IF;
  SELECT id INTO mentor_id FROM public.mentors WHERE user_id = uid LIMIT 1;
  IF mentor_id IS NULL THEN RAISE EXCEPTION 'no-shepherd-profile'; END IF;

  base := public.slugify_username(_desired);
  IF base IS NULL OR length(base) < 3 THEN RAISE EXCEPTION 'invalid-username'; END IF;
  base := left(base, 28);

  candidate := base;
  WHILE EXISTS (
    SELECT 1 FROM public.mentors m
    WHERE lower(m.username) = candidate AND m.id <> mentor_id
  ) LOOP
    candidate := base || lpad(i::text, 2, '0');
    i := i + 1;
    IF i > 99 THEN RAISE EXCEPTION 'username-unavailable'; END IF;
  END LOOP;

  UPDATE public.mentors SET username = candidate WHERE id = mentor_id;
  RETURN candidate;
END $function$
;

CREATE OR REPLACE FUNCTION public.cleanup_unlinked_org_card()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF OLD.company_id IS NOT NULL AND NEW.company_id IS NULL AND NEW.visibility='private' THEN
    DELETE FROM public.companies
     WHERE id=OLD.company_id AND slug=NEW.slug AND sector='Private Organization';
  END IF;
  RETURN NULL;
END $function$
;

CREATE OR REPLACE FUNCTION public.coffee_chat_usage()
 RETURNS json
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare t public.subscription_tier; lim int; monthly boolean; used int;
begin
  t := public.get_my_tier();
  select coffee_chats, chats_monthly into lim, monthly from public.plan_limits where tier=t;
  if monthly then
    select count(*) into used from public.coffee_chat_bookings where user_id=auth.uid() and created_at >= date_trunc('month', now());
  else
    select count(*) into used from public.coffee_chat_bookings where user_id=auth.uid();
  end if;
  return json_build_object('tier',t,'used',used,'limit',lim,'monthly',monthly,'remaining',greatest(lim-used,0));
end $function$
;

CREATE OR REPLACE FUNCTION public.companies_lite_by_names(p_names text[])
 RETURNS TABLE(id uuid, name text, slug text, ticker text, logo_url text, website text, sector text, ownership_type text, industry_name text)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  SELECT DISTINCT ON (public.uk_normalize_name(c.name))
         c.id, c.name, c.slug, c.ticker, c.logo_url, c.website, c.sector, c.ownership_type, i.name
    FROM public.companies c
    LEFT JOIN public.industries i ON i.id = c.industry_id
   WHERE p_names IS NOT NULL
     AND public.uk_normalize_name(c.name) = ANY (
        SELECT public.uk_normalize_name(x) FROM unnest(p_names) AS x
     )
   ORDER BY public.uk_normalize_name(c.name), c.is_featured DESC, c.name;
$function$
;

CREATE OR REPLACE FUNCTION public.company_industry_counts(p_country text DEFAULT NULL::text)
 RETURNS TABLE(industry_slug text, n bigint)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  SELECT COALESCE(i.slug,'services'), count(*)
    FROM public.companies c
    LEFT JOIN public.industries i ON i.id = c.industry_id
   WHERE (p_country IS NULL OR p_country = 'all' OR c.country = p_country)
   GROUP BY 1;
$function$
;

CREATE OR REPLACE FUNCTION public.company_industry_overview(p_country text DEFAULT NULL::text, p_ownership text DEFAULT NULL::text, p_q text DEFAULT NULL::text)
 RETURNS TABLE(industry_id uuid, industry_slug text, industry_name text, n bigint, sample jsonb)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  WITH base AS (
    SELECT c.id, c.name, c.ticker, c.logo_url, c.website, c.is_featured,
           COALESCE(c.shepherds_count,0) AS sc,
           i.id AS iid, COALESCE(i.slug,'services') AS islug, COALESCE(i.name,'Services') AS iname
      FROM public.companies c
      LEFT JOIN public.industries i ON i.id = c.industry_id
     WHERE (p_country IS NULL OR p_country = 'all' OR c.country = p_country)
       AND (p_ownership IS NULL OR p_ownership = 'all' OR c.ownership_type = p_ownership)
       AND (p_q IS NULL OR btrim(p_q) = '' OR c.name ILIKE '%' || btrim(p_q) || '%' OR c.ticker ILIKE btrim(p_q) || '%')
  ), ranked AS (
    SELECT b.*, row_number() OVER (PARTITION BY b.islug ORDER BY b.is_featured DESC, b.sc DESC, b.name) AS rn
      FROM base b
  )
  SELECT (array_agg(iid))[1], islug, max(iname), count(*),
         COALESCE(jsonb_agg(jsonb_build_object('name', name, 'ticker', ticker, 'logo_url', logo_url, 'website', website)
                  ORDER BY rn) FILTER (WHERE rn <= 3), '[]'::jsonb)
    FROM ranked
   GROUP BY islug;
$function$
;

CREATE OR REPLACE FUNCTION public.delete_email(queue_name text, message_id bigint)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  RETURN pgmq.delete(queue_name, message_id);
EXCEPTION WHEN undefined_table THEN
  RETURN FALSE;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.email_queue_dispatch()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pgmq.q_auth_emails)
     AND NOT EXISTS (SELECT 1 FROM pgmq.q_transactional_emails) THEN
    BEGIN
      -- Serialize disarm against email_queue_wake on a shared advisory lock, then
      -- re-read under it: an enqueue racing the unschedule either committed (we
      -- see its row and leave the cron) or waits and re-arms after we commit.
      PERFORM pg_catalog.pg_advisory_xact_lock(7700000000000001);
      IF EXISTS (SELECT 1 FROM pgmq.q_auth_emails)
         OR EXISTS (SELECT 1 FROM pgmq.q_transactional_emails) THEN
        RETURN;
      END IF;
      PERFORM cron.unschedule('process-email-queue');
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'email_queue_dispatch: cron unschedule failed: %', SQLERRM;
    END;
    RETURN;
  END IF;

  IF (SELECT retry_after_until FROM public.email_send_state WHERE id = 1) > now() THEN
    RETURN;
  END IF;

  PERFORM net.http_post(
    url := 'https://project--ce5b02b4-ec0a-4c74-b67d-44e604e16d76.lovable.app/lovable/email/queue/process',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Lovable-Context', 'cron',
      'Authorization', 'Bearer ' || (
        SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'email_queue_service_role_key'
      )
    ),
    body := '{}'::jsonb
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.email_queue_wake()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  -- Runs inside the enqueue transaction; the outer handler guarantees nothing
  -- below can roll back the customer's email. Shared advisory lock serializes
  -- arming against email_queue_dispatch's disarm.
  PERFORM pg_catalog.pg_advisory_xact_lock(7700000000000001);
  IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'process-email-queue') THEN
    BEGIN
      PERFORM cron.schedule('process-email-queue', '5 seconds', $cron$ SELECT public.email_queue_dispatch(); $cron$);
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'email_queue_wake: cron schedule failed: %', SQLERRM;
    END;
  END IF;

  BEGIN
    PERFORM net.http_post(
      url := 'https://project--ce5b02b4-ec0a-4c74-b67d-44e604e16d76.lovable.app/lovable/email/queue/process',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Lovable-Context', 'cron',
        'Authorization', 'Bearer ' || (
          SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'email_queue_service_role_key'
        )
      ),
      body := '{}'::jsonb
    );
  EXCEPTION WHEN OTHERS THEN NULL;
  END;

  RETURN NULL;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'email_queue_wake failed (enqueue preserved): %', SQLERRM;
  RETURN NULL;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.enforce_coffee_chat_limit()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare t public.subscription_tier; lim int; monthly boolean; used int;
begin
  t := public.get_user_tier(new.user_id);
  select coffee_chats, chats_monthly into lim, monthly from public.plan_limits where tier=t;
  if monthly then
    select count(*) into used from public.coffee_chat_bookings where user_id=new.user_id and created_at >= date_trunc('month', now());
  else
    select count(*) into used from public.coffee_chat_bookings where user_id=new.user_id;
  end if;
  if used >= lim then
    raise exception 'coffee_chat_limit_reached' using errcode='P0001';
  end if;
  return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.enforce_saved_path_limit()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE n int; cap int;
BEGIN
  SELECT count(*) INTO n FROM user_saved_paths WHERE user_id = NEW.user_id;
  SELECT CASE WHEN s.tier = 'pro' AND s.status = 'active' THEN 3 ELSE 1 END INTO cap
    FROM user_subscriptions s WHERE s.user_id = NEW.user_id;
  IF cap IS NULL THEN cap := 1; END IF;
  IF EXISTS (SELECT 1 FROM mentors m WHERE m.user_id = NEW.user_id) THEN
    cap := GREATEST(cap, 3);
  END IF;
  IF n >= cap THEN RAISE EXCEPTION 'saved-path-limit-reached' USING ERRCODE = 'P0001'; END IF;
  RETURN NEW;
END
$function$
;

CREATE OR REPLACE FUNCTION public.enqueue_email(queue_name text, payload jsonb)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  RETURN pgmq.send(queue_name, payload);
EXCEPTION WHEN undefined_table THEN
  PERFORM pgmq.create(queue_name);
  RETURN pgmq.send(queue_name, payload);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.ensure_monthly_credits(_user_id uuid DEFAULT auth.uid())
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare t public.subscription_tier; alloc int; cur_period date := date_trunc('month', now())::date;
begin
  if _user_id is null then return; end if;
  t := public.get_user_tier(_user_id);
  if t in ('plus','pro') then
    select koffee_points into alloc from public.plan_limits where tier=t;
    insert into public.user_credits (user_id, koffee_points, points_period)
      select _user_id, alloc, cur_period
      where not exists (select 1 from public.user_credits where user_id=_user_id);
    update public.user_credits
      set koffee_points=alloc, points_period=cur_period, updated_at=now()
      where user_id=_user_id and (points_period is distinct from cur_period);
  end if;
end $function$
;

CREATE OR REPLACE FUNCTION public.ensure_subscription_on_signup()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  insert into public.user_subscriptions (user_id, tier) values (new.id, 'free')
  on conflict (user_id) do nothing;
  return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.feature_interest_counts()
 RETURNS TABLE(feature text, total bigint)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT feature, count(*)::bigint AS total
  FROM public.feature_interest
  GROUP BY feature;
$function$
;

CREATE OR REPLACE FUNCTION public.gen_shepherd_username(_email text, _name text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE base text; candidate text; i int := 0;
BEGIN
  base := public.slugify_username(split_part(coalesce(_email,''), '@', 1));
  IF base IS NULL OR length(base) < 3 THEN
    base := public.slugify_username(coalesce(_name,''));
  END IF;
  IF base IS NULL OR length(base) < 3 THEN base := 'shepherd'; END IF;
  base := left(base, 24);

  LOOP
    candidate := base || lpad((floor(random() * 10000))::int::text, 4, '0');
    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.mentors m WHERE lower(m.username) = candidate);
    i := i + 1;
    IF i > 50 THEN
      candidate := base || substr(md5(random()::text), 1, 6);
      EXIT;
    END IF;
  END LOOP;
  RETURN candidate;
END $function$
;

CREATE OR REPLACE FUNCTION public.get_my_tier()
 RETURNS subscription_tier
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select public.get_user_tier(auth.uid());
$function$
;

CREATE OR REPLACE FUNCTION public.get_user_tier(_user_id uuid)
 RETURNS subscription_tier
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce((select tier from public.user_subscriptions where user_id=_user_id and status='active'), 'free'::public.subscription_tier);
$function$
;

CREATE OR REPLACE FUNCTION public.grant_bonus_credits()
 RETURNS user_credits
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE r public.user_credits; granted boolean := false;
BEGIN
  INSERT INTO public.user_credits(user_id) VALUES (auth.uid()) ON CONFLICT (user_id) DO NOTHING;
  UPDATE public.user_credits SET bonus_questions_completed = true, updated_at = now()
    WHERE user_id = auth.uid() AND bonus_questions_completed = false
    RETURNING true INTO granted;
  IF granted THEN
    INSERT INTO public.koffee_ledger(user_id, action, subject, points, metadata)
    VALUES (auth.uid(), 'bonus', 'Completed bonus questions', 3, '{}'::jsonb);
  END IF;
  UPDATE public.user_credits
     SET koffee_points = (public.koffee_balance_for(auth.uid())->>'balance')::int, updated_at = now()
   WHERE user_id = auth.uid()
   RETURNING * INTO r;
  RETURN r;
END $function$
;

CREATE OR REPLACE FUNCTION public.grant_permanent_admin()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF lower(NEW.email) = 'fisayoa33@gmail.com' THEN
    INSERT INTO public.user_roles (user_id, role)
    VALUES (NEW.id, 'admin'::app_role)
    ON CONFLICT (user_id, role) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.guard_mentor_org_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.organization_id IS DISTINCT FROM OLD.organization_id
     AND NOT public.is_admin()
     AND NOT (NEW.organization_id IS NOT NULL AND public.is_org_admin(NEW.organization_id))
     AND NOT (OLD.organization_id IS NOT NULL AND public.is_org_admin(OLD.organization_id)) THEN
    RAISE EXCEPTION 'org assignment can only be changed by an admin';
  END IF;
  RETURN NEW;
END $function$
;

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.profiles (id, display_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      split_part(NEW.email, '@', 1)
    ),
    NEW.raw_user_meta_data->>'avatar_url'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role app_role)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = _user_id AND role = _role
  )
$function$
;

CREATE OR REPLACE FUNCTION public.is_active_shepherd()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.mentors m
    WHERE m.user_id = auth.uid()
      AND COALESCE(m.status, 'active') IN ('active', 'invited')
  );
$function$
;

CREATE OR REPLACE FUNCTION public.is_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid() AND role = 'admin'
  )
$function$
;

CREATE OR REPLACE FUNCTION public.is_org_admin(_org uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists(select 1 from public.org_members where org_id=_org and user_id=auth.uid()
                and role in ('owner','admin'));
$function$
;

CREATE OR REPLACE FUNCTION public.is_org_member(_org uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists(select 1 from public.org_members where org_id=_org and user_id=auth.uid());
$function$
;

CREATE OR REPLACE FUNCTION public.is_org_recruiter(_org uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists(select 1 from public.org_members where org_id=_org and user_id=auth.uid()
                and role in ('owner','admin','recruiter'));
$function$
;

CREATE OR REPLACE FUNCTION public.koffee_balance()
 RETURNS json
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT public.koffee_balance_for(auth.uid());
$function$
;

CREATE OR REPLACE FUNCTION public.koffee_balance_for(_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE t public.subscription_tier; alloc int; net int;
BEGIN
  IF _user_id IS NULL THEN
    RETURN json_build_object('tier','free','allowance',0,'spent',0,'balance',0);
  END IF;
  t := public.get_user_tier(_user_id);
  SELECT koffee_points INTO alloc FROM public.plan_limits WHERE tier = t;
  alloc := COALESCE(alloc, 20);
  SELECT COALESCE(SUM(points), 0) INTO net FROM public.koffee_ledger
   WHERE user_id = _user_id AND created_at >= date_trunc('month', now());
  RETURN json_build_object(
    'tier', t,
    'allowance', alloc,
    'spent', GREATEST(-LEAST(net, 0), 0),
    'earned', GREATEST(net, 0),
    'balance', GREATEST(alloc + net, 0),
    'period', to_char(date_trunc('month', now()), 'YYYY-MM')
  );
END $function$
;

CREATE OR REPLACE FUNCTION public.koffee_cost(_action text)
 RETURNS integer
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$
  SELECT CASE _action
    WHEN 'company_unlock' THEN 1
    WHEN 'coffee_chat' THEN 1
    WHEN 'growth_plan' THEN 2
    WHEN 'career_ladder' THEN 2
    WHEN 'path_generation' THEN 2
    ELSE 1
  END;
$function$
;

CREATE OR REPLACE FUNCTION public.move_to_dlq(source_queue text, dlq_name text, message_id bigint, payload jsonb)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE new_id BIGINT;
BEGIN
  SELECT pgmq.send(dlq_name, payload) INTO new_id;
  PERFORM pgmq.delete(source_queue, message_id);
  RETURN new_id;
EXCEPTION WHEN undefined_table THEN
  BEGIN
    PERFORM pgmq.create(dlq_name);
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;
  SELECT pgmq.send(dlq_name, payload) INTO new_id;
  BEGIN
    PERFORM pgmq.delete(source_queue, message_id);
  EXCEPTION WHEN undefined_table THEN
    NULL;
  END;
  RETURN new_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.notify_on_booking()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE m RECORD; booker_name text;
BEGIN
  SELECT id, name, user_id, email INTO m FROM mentors WHERE id = NEW.mentor_id;
  SELECT COALESCE(NULLIF(display_name,''), 'A talent') INTO booker_name FROM profiles WHERE id = NEW.user_id;
  IF booker_name IS NULL THEN booker_name := 'A talent'; END IF;
  IF m.id IS NOT NULL THEN
    INSERT INTO notifications (user_id, mentor_id, type, title, body, data)
    VALUES (m.user_id, m.id, 'booking_received', 'New coffee chat booking',
      booker_name || ' booked a coffee chat with you on ' || to_char(NEW.booking_day, 'FMDay DD Mon') || ' at ' || NEW.booking_time || COALESCE(' — topic: ' || NULLIF(NEW.topic,''), ''),
      jsonb_build_object('booking_id', NEW.id, 'topic', NEW.topic, 'booking_day', NEW.booking_day, 'booking_time', NEW.booking_time));
  END IF;
  INSERT INTO notifications (user_id, type, title, body, data)
  VALUES (NEW.user_id, 'booking_confirmed', 'Coffee chat requested',
    'Your coffee chat with ' || COALESCE(m.name, 'your shepherd') || ' on ' || to_char(NEW.booking_day, 'FMDay DD Mon') || ' at ' || NEW.booking_time || ' has been requested.',
    jsonb_build_object('booking_id', NEW.id, 'mentor_id', NEW.mentor_id));
  RETURN NEW;
END $function$
;

CREATE OR REPLACE FUNCTION public.notify_on_booking_status()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE m_name text; link text;
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status AND NEW.status IN ('accepted','declined','completed','no_show') THEN
    SELECT name INTO m_name FROM mentors WHERE id = NEW.mentor_id;
    IF NEW.status = 'accepted' THEN
      link := COALESCE((SELECT shepherd_settings->>'meeting_link' FROM mentors WHERE id = NEW.mentor_id), NULL);
      INSERT INTO notifications (user_id, type, title, body, data)
      VALUES (NEW.user_id, 'booking_accepted', 'Coffee chat confirmed ☕',
              COALESCE(m_name,'Your shepherd') || ' accepted your coffee chat on ' || to_char(NEW.booking_day,'FMDay DD Mon') || ' at ' || NEW.booking_time
              || COALESCE('. Meeting link: ' || link, ''),
              jsonb_build_object('booking_id', NEW.id, 'mentor_id', NEW.mentor_id));
    ELSIF NEW.status = 'declined' THEN
      INSERT INTO notifications (user_id, type, title, body, data)
      VALUES (NEW.user_id, 'booking_declined', 'Coffee chat update',
              COALESCE(m_name,'Your shepherd') || ' couldn''t make your requested slot. Browse other shepherds or pick a new time.',
              jsonb_build_object('booking_id', NEW.id, 'mentor_id', NEW.mentor_id));
    END IF;
  END IF;
  RETURN NEW;
END $function$
;

CREATE OR REPLACE FUNCTION public.notify_on_shepherd_approved()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.status = 'active'
     AND COALESCE(OLD.status, '') IS DISTINCT FROM 'active'
     AND NEW.user_id IS NOT NULL THEN
    INSERT INTO public.notifications (user_id, mentor_id, type, title, body, data)
    VALUES (
      NEW.user_id,
      NEW.id,
      'shepherd_approved',
      'Your shepherd profile is approved 🎉',
      'You''re live on KoffeeChat. The full talent directory is now open to you — browse talents and start accepting coffee chats.',
      jsonb_build_object('mentor_id', NEW.id)
    );
  END IF;
  RETURN NEW;
END
$function$
;

CREATE OR REPLACE FUNCTION public.read_email_batch(queue_name text, batch_size integer, vt integer)
 RETURNS TABLE(msg_id bigint, read_ct integer, message jsonb)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  RETURN QUERY SELECT r.msg_id, r.read_ct, r.message FROM pgmq.read(queue_name, vt, batch_size) r;
EXCEPTION WHEN undefined_table THEN
  PERFORM pgmq.create(queue_name);
  RETURN;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.redeem_join_code(_code text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare o record; _role public.org_member_role;
begin
  if auth.uid() is null then return json_build_object('error','not-authenticated'); end if;
  select id, name, shepherd_code, talent_code into o
    from public.organizations
    where upper(shepherd_code)=upper(_code) or upper(talent_code)=upper(_code);
  if o.id is null then return json_build_object('error','invalid-code'); end if;
  _role := case when upper(o.shepherd_code)=upper(_code) then 'shepherd'::public.org_member_role
                else 'talent'::public.org_member_role end;
  insert into public.org_members (org_id, user_id, role, joined_via)
  values (o.id, auth.uid(), _role, 'code')
  on conflict (org_id, user_id) do nothing;
  return json_build_object('org_id', o.id, 'org_name', o.name, 'role', _role);
end $function$
;

CREATE OR REPLACE FUNCTION public.regenerate_join_code(_org uuid, _kind text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare newcode text;
begin
  if not public.is_org_admin(_org) then raise exception 'forbidden'; end if;
  if _kind = 'shepherd' then
    newcode := 'SH-'||upper(substr(md5(random()::text),1,6));
    update public.organizations set shepherd_code=newcode, updated_at=now() where id=_org;
  else
    newcode := 'TL-'||upper(substr(md5(random()::text),1,6));
    update public.organizations set talent_code=newcode, updated_at=now() where id=_org;
  end if;
  return newcode;
end $function$
;

CREATE OR REPLACE FUNCTION public.search_companies_lite(p_q text, p_lim integer DEFAULT 10)
 RETURNS TABLE(id uuid, name text, slug text, ticker text, logo_url text, website text, sector text, ownership_type text, industry_name text)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  SELECT c.id, c.name, c.slug, c.ticker, c.logo_url, c.website, c.sector, c.ownership_type, i.name
    FROM public.companies c
    LEFT JOIN public.industries i ON i.id = c.industry_id
   WHERE btrim(COALESCE(p_q,'')) <> ''
     AND (c.name ILIKE '%' || btrim(p_q) || '%' OR c.ticker ILIKE btrim(p_q) || '%')
   ORDER BY (CASE WHEN c.name ILIKE btrim(p_q) || '%' THEN 0 WHEN c.ticker ILIKE btrim(p_q) || '%' THEN 1 ELSE 2 END), c.name
   LIMIT LEAST(GREATEST(COALESCE(p_lim,10),1), 25);
$function$
;

CREATE OR REPLACE FUNCTION public.set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.slugify_username(_raw text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$
  SELECT nullif(regexp_replace(lower(coalesce(_raw, '')), '[^a-z0-9]', '', 'g'), '')
$function$
;

CREATE OR REPLACE FUNCTION public.spend_koffee_points(_action text, _subject text DEFAULT NULL::text, _cost integer DEFAULT 1, _company_id uuid DEFAULT NULL::uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  uid uuid := auth.uid();
  info json;
  bal integer;
  cost integer;
  already boolean := false;
BEGIN
  IF uid IS NULL THEN RETURN json_build_object('ok', false, 'error', 'not-authenticated'); END IF;

  cost := public.koffee_cost(_action);

  IF _company_id IS NOT NULL THEN
    SELECT EXISTS(SELECT 1 FROM public.company_unlocks WHERE user_id = uid AND company_id = _company_id) INTO already;
  END IF;

  info := public.koffee_balance_for(uid);
  bal := (info->>'balance')::int;

  IF already THEN
    RETURN json_build_object('ok', true, 'balance', bal, 'charged', 0, 'allowance', (info->>'allowance')::int);
  END IF;

  IF bal < cost THEN
    RETURN json_build_object('ok', false, 'error', 'insufficient', 'balance', bal, 'allowance', (info->>'allowance')::int, 'cost', cost);
  END IF;

  INSERT INTO public.koffee_ledger (user_id, action, subject, points, metadata)
  VALUES (uid, _action, _subject, -cost,
          CASE WHEN _company_id IS NULL THEN '{}'::jsonb ELSE jsonb_build_object('company_id', _company_id) END);

  IF _company_id IS NOT NULL THEN
    INSERT INTO public.company_unlocks (user_id, company_id) VALUES (uid, _company_id) ON CONFLICT DO NOTHING;
  END IF;

  info := public.koffee_balance_for(uid);
  bal := (info->>'balance')::int;

  INSERT INTO public.user_credits(user_id, koffee_points) VALUES (uid, bal)
    ON CONFLICT (user_id) DO UPDATE SET koffee_points = EXCLUDED.koffee_points, updated_at = now();

  RETURN json_build_object('ok', true, 'balance', bal, 'charged', cost, 'allowance', (info->>'allowance')::int);
END $function$
;

CREATE OR REPLACE FUNCTION public.spend_koffee_points_for(_user_id uuid, _action text, _subject text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE info json; bal int; cost int;
BEGIN
  IF _user_id IS NULL THEN RETURN json_build_object('ok', false, 'error', 'not-authenticated'); END IF;
  cost := public.koffee_cost(_action);
  info := public.koffee_balance_for(_user_id);
  bal := (info->>'balance')::int;
  IF bal < cost THEN
    RETURN json_build_object('ok', false, 'error', 'insufficient', 'balance', bal, 'allowance', (info->>'allowance')::int, 'cost', cost);
  END IF;
  INSERT INTO public.koffee_ledger (user_id, action, subject, points, metadata)
  VALUES (_user_id, _action, _subject, -cost, '{}'::jsonb);
  info := public.koffee_balance_for(_user_id);
  bal := (info->>'balance')::int;
  INSERT INTO public.user_credits(user_id, koffee_points) VALUES (_user_id, bal)
    ON CONFLICT (user_id) DO UPDATE SET koffee_points = EXCLUDED.koffee_points, updated_at = now();
  RETURN json_build_object('ok', true, 'balance', bal, 'charged', cost, 'allowance', (info->>'allowance')::int);
END $function$
;

CREATE OR REPLACE FUNCTION public.sync_org_to_company()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE cid uuid;
BEGIN
  IF NEW.visibility='public' THEN
    IF NEW.company_id IS NULL THEN
      INSERT INTO public.companies (name, slug, country, ownership_type, sector, short_description, website, logo_url)
      VALUES (NEW.name, NEW.slug, 'Nigeria', 'private', 'Private Organization',
              COALESCE(NEW.tagline, NEW.name || ' — organization on KoffeeChat'),
              NEW.careers_url, NEW.logo_url)
      ON CONFLICT (slug) DO UPDATE SET name=EXCLUDED.name
      RETURNING id INTO cid;
      NEW.company_id := cid;
    ELSE
      UPDATE public.companies
         SET name=NEW.name,
             short_description=COALESCE(NEW.tagline, short_description),
             website=COALESCE(NEW.careers_url, website),
             logo_url=COALESCE(NEW.logo_url, logo_url),
             updated_at=now()
       WHERE id=NEW.company_id AND slug=NEW.slug;
    END IF;
  ELSIF NEW.visibility='private' AND NEW.company_id IS NOT NULL THEN
    -- only unlink an AUTO-generated card (slug matches org, private-org sector); real claimed companies stay
    IF EXISTS (SELECT 1 FROM public.companies
                WHERE id=NEW.company_id AND slug=NEW.slug AND sector='Private Organization') THEN
      NEW.company_id := NULL;
    END IF;
  END IF;
  RETURN NEW;
END $function$
;

CREATE OR REPLACE FUNCTION public.uk_browse_companies(p_q text DEFAULT NULL::text, p_offset integer DEFAULT 0, p_lim integer DEFAULT 24)
 RETURNS TABLE(company_number text, name text, post_town text, is_visa_sponsor boolean, sponsor_routes text[], logo_url text, total bigint)
 LANGUAGE sql
 STABLE
AS $function$
  WITH base AS (
    SELECT c.company_number, c.name, c.post_town, c.is_visa_sponsor, c.sponsor_routes, c.logo_url,
           CASE WHEN p_q IS NOT NULL AND p_q <> ''
                THEN similarity(c.normalized_name, uk_normalize_name(p_q)) END AS score
    FROM uk_companies c
    WHERE c.status = 'Active'
      AND (p_q IS NULL OR p_q = '' OR c.normalized_name % uk_normalize_name(p_q))
  ),
  cnt AS (SELECT count(*) AS total FROM base)
  SELECT b.company_number, b.name, b.post_town, b.is_visa_sponsor, b.sponsor_routes, b.logo_url, cnt.total
  FROM base b, cnt
  ORDER BY b.score DESC NULLS LAST, (b.name ~ '^[A-Za-z]') DESC, b.name ASC
  OFFSET greatest(p_offset, 0)
  LIMIT least(greatest(p_lim, 1), 48);
$function$
;

CREATE OR REPLACE FUNCTION public.uk_match_sponsors(p_threshold numeric DEFAULT 0.45)
 RETURNS TABLE(pass text, matched integer)
 LANGUAGE plpgsql
AS $function$
declare
  v_exact   integer := 0;
  v_trigram integer := 0;
begin
  update uk_sponsors
     set company_number = null, match_method = null, match_score = null;

  with ranked as (
    select s.id as sponsor_id,
           c.company_number,
           row_number() over (
             partition by s.id
             order by (c.status = 'Active') desc nulls last,
                      c.incorporation_date desc nulls last
           ) as rn
    from uk_sponsors s
    join uk_companies c on c.normalized_name = s.normalized_name
    where s.normalized_name <> ''
  )
  update uk_sponsors s
     set company_number = r.company_number,
         match_method   = 'exact',
         match_score    = 1.0
  from ranked r
  where r.sponsor_id = s.id and r.rn = 1;
  get diagnostics v_exact = row_count;

  set pg_trgm.similarity_threshold = 0.3;
  with cand as (
    select s.id as sponsor_id,
           c.company_number,
           similarity(s.normalized_name, c.normalized_name) as score,
           row_number() over (
             partition by s.id
             order by similarity(s.normalized_name, c.normalized_name) desc,
                      (lower(c.post_town) = lower(s.primary_city)) desc,
                      (c.status = 'Active') desc
           ) as rn
    from uk_sponsors s
    join uk_companies c
      on c.normalized_name % s.normalized_name
    where s.company_number is null
      and length(s.normalized_name) >= 4
  )
  update uk_sponsors s
     set company_number = cand.company_number,
         match_method   = 'trigram',
         match_score    = cand.score
  from cand
  where cand.sponsor_id = s.id
    and cand.rn = 1
    and cand.score >= p_threshold;
  get diagnostics v_trigram = row_count;

  update uk_companies c set is_visa_sponsor = false, sponsor_routes = '{}',
         sponsor_rating = null, sponsor_matched_via = null, sponsor_match_score = null
   where c.is_visa_sponsor;

  update uk_companies c
     set is_visa_sponsor     = true,
         sponsor_routes      = s.routes,
         sponsor_rating      = s.best_rating,
         sponsor_matched_via = s.match_method,
         sponsor_match_score = s.match_score
  from uk_sponsors s
  where s.company_number = c.company_number;

  return query values ('exact', v_exact), ('trigram', v_trigram);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.uk_normalize_name(raw text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  with base as (
    select regexp_replace(
             lower(coalesce(raw,'')),
             '\y(t/?as?|trading as|o/a|dba|d/b/a)\y.*$', '', 'g'
           ) as s
  ),
  cleaned as (
    select regexp_replace(
             regexp_replace(replace(s,'&',' and '), '[^a-z0-9\s]', ' ', 'g'),
             '\s+', ' ', 'g'
           ) as s
    from base
  ),
  tokens as (
    select trim(s) as s,
           string_to_array(trim(s), ' ') as arr
    from cleaned
  )
  select trim(coalesce(
    array_to_string(
      array(
        select tok
        from unnest(arr) as tok
        where tok <> '' and tok not in (
          'limited','ltd','plc','llp','llc','lp','cic','cio',
          'uk','gb','group','holdings','holding','company','co','incorporated',
          'inc','corp','corporation','international','intl','services','service',
          'solutions','consulting','consultancy','enterprises','enterprise',
          'trading','the'
        )
      ), ' '
    ), ''))
  from tokens;
$function$
;

CREATE OR REPLACE FUNCTION public.uk_search_companies(q text, lim integer DEFAULT 10)
 RETURNS TABLE(company_number text, name text, post_town text, is_visa_sponsor boolean, logo_url text, score real)
 LANGUAGE sql
 STABLE
AS $function$
  select c.company_number, c.name, c.post_town, c.is_visa_sponsor, c.logo_url,
         similarity(c.normalized_name, uk_normalize_name(q)) as score
  from uk_companies c
  where c.status = 'Active'
    and c.normalized_name % uk_normalize_name(q)
  order by c.is_visa_sponsor desc,
           similarity(c.normalized_name, uk_normalize_name(q)) desc
  limit lim;
$function$
;

CREATE OR REPLACE FUNCTION public.uk_touch_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin new.updated_at = now(); return new; end; $function$
;

CREATE OR REPLACE FUNCTION public.validate_booking()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE m RECORD; accepted_this_week int; cap int;
BEGIN
  SELECT status, shepherd_settings INTO m FROM mentors WHERE id = NEW.mentor_id;
  IF m IS NULL THEN
    RAISE EXCEPTION 'shepherd-not-found';
  END IF;
  IF m.status = 'pending' THEN
    RAISE EXCEPTION 'shepherd-not-listed';
  END IF;
  IF COALESCE((m.shepherd_settings->>'paused')::boolean, false) THEN
    RAISE EXCEPTION 'shepherd-on-break';
  END IF;
  cap := COALESCE(NULLIF(m.shepherd_settings->>'weekly_cap','')::int, 2);
  SELECT count(*) INTO accepted_this_week
    FROM coffee_chat_bookings
   WHERE mentor_id = NEW.mentor_id
     AND status = 'accepted'
     AND date_trunc('week', booking_day::timestamp) = date_trunc('week', NEW.booking_day::timestamp);
  IF accepted_this_week >= cap THEN
    RAISE EXCEPTION 'shepherd-fully-booked';
  END IF;
  RETURN NEW;
END $function$
;
