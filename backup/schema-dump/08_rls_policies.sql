ALTER TABLE public.career_ladders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.career_path_generations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.career_paths ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coffee_chat_bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.company_career_paths ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.company_enrichment ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.company_matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.company_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.company_unlocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_send_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_send_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_unsubscribe_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_interest ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fx_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.growth_plan_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.growth_plan_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.growth_plan_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.growth_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.industries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.joined_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.koffee_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leaderboards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mentors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.next_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ngke_import ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.onboarding_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.org_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.org_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.org_pipeline ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.org_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_limits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salary_bands ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sector_bands ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.signup_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.similar_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.skill_gaps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.suppressed_emails ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.talent_org_interest ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.talent_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.uk_companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.uk_sponsors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_career_paths ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_company_matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_credits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_saved_paths ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_task_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can delete their own ladder" ON public.career_ladders AS PERMISSIVE FOR DELETE TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "Users can insert their own ladder" ON public.career_ladders AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((auth.uid() = user_id));
CREATE POLICY "Users can update their own ladder" ON public.career_ladders AS PERMISSIVE FOR UPDATE TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));
CREATE POLICY "Users can view their own ladder" ON public.career_ladders AS PERMISSIVE FOR SELECT TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "cpg read own" ON public.career_path_generations AS PERMISSIVE FOR SELECT TO public USING (((user_id = auth.uid()) OR is_admin()));
CREATE POLICY "Admins can write career_paths" ON public.career_paths AS PERMISSIVE FOR ALL TO authenticated USING (has_role(auth.uid(), 'admin'::app_role)) WITH CHECK (has_role(auth.uid(), 'admin'::app_role));
CREATE POLICY read_all ON public.career_paths AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "challenges are publicly readable" ON public.challenges AS PERMISSIVE FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "mentors read their bookings" ON public.coffee_chat_bookings AS PERMISSIVE FOR SELECT TO public USING (((EXISTS ( SELECT 1
   FROM mentors m
  WHERE ((m.id = coffee_chat_bookings.mentor_id) AND (m.user_id = auth.uid())))) OR is_admin()));
CREATE POLICY "mentors update their bookings" ON public.coffee_chat_bookings AS PERMISSIVE FOR UPDATE TO public USING ((EXISTS ( SELECT 1
   FROM mentors m
  WHERE ((m.id = coffee_chat_bookings.mentor_id) AND (m.user_id = auth.uid()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM mentors m
  WHERE ((m.id = coffee_chat_bookings.mentor_id) AND (m.user_id = auth.uid())))));
CREATE POLICY "users manage their own bookings" ON public.coffee_chat_bookings AS PERMISSIVE FOR ALL TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));
CREATE POLICY "Admins can write companies" ON public.companies AS PERMISSIVE FOR ALL TO authenticated USING (has_role(auth.uid(), 'admin'::app_role)) WITH CHECK (has_role(auth.uid(), 'admin'::app_role));
CREATE POLICY read_all ON public.companies AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Admins can write company_career_paths" ON public.company_career_paths AS PERMISSIVE FOR ALL TO authenticated USING (has_role(auth.uid(), 'admin'::app_role)) WITH CHECK (has_role(auth.uid(), 'admin'::app_role));
CREATE POLICY read_all ON public.company_career_paths AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "premium members read enrichment" ON public.company_enrichment AS PERMISSIVE FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM user_subscriptions us
  WHERE ((us.user_id = auth.uid()) AND (us.status = 'active'::text) AND ((us.tier)::text = ANY (ARRAY['plus'::text, 'pro'::text])) AND ((us.current_period_end IS NULL) OR (us.current_period_end > now()))))));
CREATE POLICY "company_matches public read" ON public.company_matches AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Admins can write company_roles" ON public.company_roles AS PERMISSIVE FOR ALL TO authenticated USING (has_role(auth.uid(), 'admin'::app_role)) WITH CHECK (has_role(auth.uid(), 'admin'::app_role));
CREATE POLICY read_all ON public.company_roles AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "admin read unlocks" ON public.company_unlocks AS PERMISSIVE FOR SELECT TO authenticated USING (is_admin());
CREATE POLICY "admin unlocks read" ON public.company_unlocks AS PERMISSIVE FOR SELECT TO authenticated USING (is_admin());
CREATE POLICY "own unlocks read" ON public.company_unlocks AS PERMISSIVE FOR SELECT TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "users manage their own connections" ON public.connections AS PERMISSIVE FOR ALL TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));
CREATE POLICY "Service role can insert send log" ON public.email_send_log AS PERMISSIVE FOR INSERT TO public WITH CHECK ((auth.role() = 'service_role'::text));
CREATE POLICY "Service role can read send log" ON public.email_send_log AS PERMISSIVE FOR SELECT TO public USING ((auth.role() = 'service_role'::text));
CREATE POLICY "Service role can update send log" ON public.email_send_log AS PERMISSIVE FOR UPDATE TO public USING ((auth.role() = 'service_role'::text)) WITH CHECK ((auth.role() = 'service_role'::text));
CREATE POLICY "Service role can manage send state" ON public.email_send_state AS PERMISSIVE FOR ALL TO public USING ((auth.role() = 'service_role'::text)) WITH CHECK ((auth.role() = 'service_role'::text));
CREATE POLICY "Service role can insert tokens" ON public.email_unsubscribe_tokens AS PERMISSIVE FOR INSERT TO public WITH CHECK ((auth.role() = 'service_role'::text));
CREATE POLICY "Service role can mark tokens as used" ON public.email_unsubscribe_tokens AS PERMISSIVE FOR UPDATE TO public USING ((auth.role() = 'service_role'::text)) WITH CHECK ((auth.role() = 'service_role'::text));
CREATE POLICY "Service role can read tokens" ON public.email_unsubscribe_tokens AS PERMISSIVE FOR SELECT TO public USING ((auth.role() = 'service_role'::text));
CREATE POLICY "Admins read all feature interest" ON public.feature_interest AS PERMISSIVE FOR SELECT TO public USING (is_admin());
CREATE POLICY "Users insert own feature interest" ON public.feature_interest AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((auth.uid() = user_id));
CREATE POLICY "Users read own feature interest" ON public.feature_interest AS PERMISSIVE FOR SELECT TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "fx_rates public read" ON public.fx_rates AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "growth_plan_categories public read" ON public.growth_plan_categories AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Active shepherds read growth plan items" ON public.growth_plan_items AS PERMISSIVE FOR SELECT TO authenticated USING (is_active_shepherd());
CREATE POLICY "own plan_items delete" ON public.growth_plan_items AS PERMISSIVE FOR DELETE TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "own plan_items insert" ON public.growth_plan_items AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((auth.uid() = user_id));
CREATE POLICY "own plan_items select" ON public.growth_plan_items AS PERMISSIVE FOR SELECT TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "own plan_items update" ON public.growth_plan_items AS PERMISSIVE FOR UPDATE TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));
CREATE POLICY "growth_plan_tasks public read" ON public.growth_plan_tasks AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Active shepherds read growth plans" ON public.growth_plans AS PERMISSIVE FOR SELECT TO authenticated USING (is_active_shepherd());
CREATE POLICY "own growth_plans delete" ON public.growth_plans AS PERMISSIVE FOR DELETE TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "own growth_plans insert" ON public.growth_plans AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((auth.uid() = user_id));
CREATE POLICY "own growth_plans select" ON public.growth_plans AS PERMISSIVE FOR SELECT TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "own growth_plans update" ON public.growth_plans AS PERMISSIVE FOR UPDATE TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));
CREATE POLICY "Admins can write industries" ON public.industries AS PERMISSIVE FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY read_all ON public.industries AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "users manage their own joined challenges" ON public.joined_challenges AS PERMISSIVE FOR ALL TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));
CREATE POLICY "admin ledger read" ON public.koffee_ledger AS PERMISSIVE FOR SELECT TO authenticated USING (is_admin());
CREATE POLICY "own ledger read" ON public.koffee_ledger AS PERMISSIVE FOR SELECT TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "leaderboards readable by authenticated" ON public.leaderboards AS PERMISSIVE FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admins manage mentors" ON public.mentors AS PERMISSIVE FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "Shepherd can update own row" ON public.mentors AS PERMISSIVE FOR UPDATE TO authenticated USING ((user_id = auth.uid())) WITH CHECK ((user_id = auth.uid()));
CREATE POLICY "mentors are publicly readable" ON public.mentors AS PERMISSIVE FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "shepherds update own profile" ON public.mentors AS PERMISSIVE FOR UPDATE TO public USING ((user_id = auth.uid())) WITH CHECK ((user_id = auth.uid()));
CREATE POLICY "next_actions public read" ON public.next_actions AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "notifications delete own" ON public.notifications AS PERMISSIVE FOR DELETE TO authenticated USING (((user_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM mentors m
  WHERE ((m.id = notifications.mentor_id) AND (m.user_id = auth.uid()))))));
CREATE POLICY "notifications mark read own" ON public.notifications AS PERMISSIVE FOR UPDATE TO public USING (((user_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM mentors m
  WHERE ((m.id = notifications.mentor_id) AND (m.user_id = auth.uid())))))) WITH CHECK (((user_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM mentors m
  WHERE ((m.id = notifications.mentor_id) AND (m.user_id = auth.uid()))))));
CREATE POLICY "notifications read own" ON public.notifications AS PERMISSIVE FOR SELECT TO public USING (((user_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM mentors m
  WHERE ((m.id = notifications.mentor_id) AND (m.user_id = auth.uid())))) OR is_admin()));
CREATE POLICY "Users manage own onboarding" ON public.onboarding_responses AS PERMISSIVE FOR ALL TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));
CREATE POLICY "jobs readable" ON public.org_jobs AS PERMISSIVE FOR SELECT TO public USING (((status = 'live'::text) OR is_org_member(org_id) OR is_admin()));
CREATE POLICY "jobs write recruiters" ON public.org_jobs AS PERMISSIVE FOR ALL TO public USING ((is_org_recruiter(org_id) OR is_admin())) WITH CHECK ((is_org_recruiter(org_id) OR is_admin()));
CREATE POLICY "members managed by org admins" ON public.org_members AS PERMISSIVE FOR ALL TO public USING ((is_org_admin(org_id) OR is_admin())) WITH CHECK ((is_org_admin(org_id) OR is_admin()));
CREATE POLICY "members readable" ON public.org_members AS PERMISSIVE FOR SELECT TO public USING ((is_org_member(org_id) OR is_admin()));
CREATE POLICY "pipeline recruiters" ON public.org_pipeline AS PERMISSIVE FOR ALL TO public USING ((is_org_recruiter(org_id) OR is_admin())) WITH CHECK ((is_org_recruiter(org_id) OR is_admin()));
CREATE POLICY "views insert authed" ON public.org_views AS PERMISSIVE FOR INSERT TO public WITH CHECK (((auth.uid() IS NOT NULL) AND ((viewer_user_id IS NULL) OR (viewer_user_id = auth.uid()))));
CREATE POLICY "views read org members" ON public.org_views AS PERMISSIVE FOR SELECT TO public USING ((is_org_member(org_id) OR is_admin()));
CREATE POLICY "orgs insert own" ON public.organizations AS PERMISSIVE FOR INSERT TO public WITH CHECK (((auth.uid() IS NOT NULL) AND (created_by = auth.uid())));
CREATE POLICY "orgs readable" ON public.organizations AS PERMISSIVE FOR SELECT TO public USING (((visibility = 'public'::org_visibility) OR is_org_member(id) OR is_admin()));
CREATE POLICY "orgs update admin" ON public.organizations AS PERMISSIVE FOR UPDATE TO public USING ((is_org_admin(id) OR is_admin()));
CREATE POLICY "plan limits public read" ON public.plan_limits AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Active shepherds can view talent profiles" ON public.profiles AS PERMISSIVE FOR SELECT TO authenticated USING ((is_active_shepherd() AND (NOT (EXISTS ( SELECT 1
   FROM mentors mm
  WHERE (mm.user_id = profiles.id)))) AND (NOT (EXISTS ( SELECT 1
   FROM org_members om
  WHERE (om.user_id = profiles.id))))));
CREATE POLICY "Org recruiters read interested talent profiles" ON public.profiles AS PERMISSIVE FOR SELECT TO public USING (((auth.uid() = id) OR is_admin() OR (EXISTS ( SELECT 1
   FROM talent_org_interest i
  WHERE ((i.user_id = profiles.id) AND is_org_recruiter(i.org_id)))) OR (EXISTS ( SELECT 1
   FROM org_pipeline pp
  WHERE ((pp.talent_user_id = profiles.id) AND is_org_recruiter(pp.org_id)))) OR (EXISTS ( SELECT 1
   FROM org_members m
  WHERE ((m.user_id = profiles.id) AND is_org_member(m.org_id))))));
CREATE POLICY "Users can insert own profile" ON public.profiles AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((auth.uid() = id));
CREATE POLICY "Users can update own profile" ON public.profiles AS PERMISSIVE FOR UPDATE TO authenticated USING ((auth.uid() = id)) WITH CHECK ((auth.uid() = id));
CREATE POLICY "Users can view own profile" ON public.profiles AS PERMISSIVE FOR SELECT TO authenticated USING ((auth.uid() = id));
CREATE POLICY "admins manage resources" ON public.resources AS PERMISSIVE FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "resources public read" ON public.resources AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "salary_bands public read" ON public.salary_bands AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "sector_bands public read" ON public.sector_bands AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Users insert own application" ON public.signup_applications AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((auth.uid() = user_id));
CREATE POLICY "Users read own application" ON public.signup_applications AS PERMISSIVE FOR SELECT TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "Users update own application" ON public.signup_applications AS PERMISSIVE FOR UPDATE TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));
CREATE POLICY "similar_roles public read" ON public.similar_roles AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "skill_gaps public read" ON public.skill_gaps AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Service role can insert suppressed emails" ON public.suppressed_emails AS PERMISSIVE FOR INSERT TO public WITH CHECK ((auth.role() = 'service_role'::text));
CREATE POLICY "Service role can read suppressed emails" ON public.suppressed_emails AS PERMISSIVE FOR SELECT TO public USING ((auth.role() = 'service_role'::text));
CREATE POLICY "interest delete own" ON public.talent_org_interest AS PERMISSIVE FOR DELETE TO public USING ((user_id = auth.uid()));
CREATE POLICY "interest insert own" ON public.talent_org_interest AS PERMISSIVE FOR INSERT TO public WITH CHECK ((user_id = auth.uid()));
CREATE POLICY "interest readable" ON public.talent_org_interest AS PERMISSIVE FOR SELECT TO public USING (((user_id = auth.uid()) OR is_org_member(org_id) OR is_admin()));
CREATE POLICY "tiers admin write" ON public.talent_tiers AS PERMISSIVE FOR ALL TO public USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "tiers readable" ON public.talent_tiers AS PERMISSIVE FOR SELECT TO public USING ((auth.uid() IS NOT NULL));
CREATE POLICY uk_companies_read ON public.uk_companies AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY uk_sponsors_read ON public.uk_sponsors AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "owner delete user_career_paths" ON public.user_career_paths AS PERMISSIVE FOR DELETE TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "owner insert user_career_paths" ON public.user_career_paths AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((auth.uid() = user_id));
CREATE POLICY "owner read user_career_paths" ON public.user_career_paths AS PERMISSIVE FOR SELECT TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "owner update user_career_paths" ON public.user_career_paths AS PERMISSIVE FOR UPDATE TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));
CREATE POLICY "own user_company_matches delete" ON public.user_company_matches AS PERMISSIVE FOR DELETE TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "own user_company_matches insert" ON public.user_company_matches AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((auth.uid() = user_id));
CREATE POLICY "own user_company_matches select" ON public.user_company_matches AS PERMISSIVE FOR SELECT TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "own user_company_matches update" ON public.user_company_matches AS PERMISSIVE FOR UPDATE TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));
CREATE POLICY "Users insert own credits" ON public.user_credits AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((auth.uid() = user_id));
CREATE POLICY "Users read own credits" ON public.user_credits AS PERMISSIVE FOR SELECT TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "admin read credits" ON public.user_credits AS PERMISSIVE FOR SELECT TO authenticated USING (is_admin());
CREATE POLICY "Admins manage user_roles delete" ON public.user_roles AS PERMISSIVE FOR DELETE TO authenticated USING (is_admin());
CREATE POLICY "Admins manage user_roles insert" ON public.user_roles AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK (is_admin());
CREATE POLICY "Admins manage user_roles update" ON public.user_roles AS PERMISSIVE FOR UPDATE TO authenticated USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "Users can view their own roles" ON public.user_roles AS PERMISSIVE FOR SELECT TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "usp all own" ON public.user_saved_paths AS PERMISSIVE FOR ALL TO public USING ((user_id = auth.uid())) WITH CHECK ((user_id = auth.uid()));
CREATE POLICY "admin manage subscriptions" ON public.user_subscriptions AS PERMISSIVE FOR ALL TO public USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "read own subscription" ON public.user_subscriptions AS PERMISSIVE FOR SELECT TO public USING ((auth.uid() = user_id));
CREATE POLICY "Active shepherds read task progress" ON public.user_task_progress AS PERMISSIVE FOR SELECT TO authenticated USING (is_active_shepherd());
CREATE POLICY "task progress owner delete" ON public.user_task_progress AS PERMISSIVE FOR DELETE TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "task progress owner insert" ON public.user_task_progress AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((auth.uid() = user_id));
CREATE POLICY "task progress owner select" ON public.user_task_progress AS PERMISSIVE FOR SELECT TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "task progress owner update" ON public.user_task_progress AS PERMISSIVE FOR UPDATE TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));
CREATE POLICY "avatar updates" ON storage.objects AS PERMISSIVE FOR UPDATE TO authenticated USING (((bucket_id = 'company-logos'::text) AND (name ~~ (('avatars/'::text || (auth.uid())::text) || '%'::text)))) WITH CHECK (((bucket_id = 'company-logos'::text) AND (name ~~ (('avatars/'::text || (auth.uid())::text) || '%'::text))));
CREATE POLICY "avatar uploads" ON storage.objects AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK (((bucket_id = 'company-logos'::text) AND (name ~~ (('avatars/'::text || (auth.uid())::text) || '%'::text))));
