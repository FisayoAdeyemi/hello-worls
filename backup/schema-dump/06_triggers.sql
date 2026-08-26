CREATE TRIGGER career_ladders_set_updated_at BEFORE UPDATE ON public.career_ladders FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER challenges_set_updated_at BEFORE UPDATE ON public.challenges FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER charge_coffee_chat_points AFTER INSERT ON public.coffee_chat_bookings FOR EACH ROW EXECUTE FUNCTION charge_coffee_chat();
CREATE TRIGGER trg_enforce_coffee_chat_limit BEFORE INSERT ON public.coffee_chat_bookings FOR EACH ROW EXECUTE FUNCTION enforce_coffee_chat_limit();
CREATE TRIGGER trg_notify_booking_status AFTER UPDATE ON public.coffee_chat_bookings FOR EACH ROW EXECUTE FUNCTION notify_on_booking_status();
CREATE TRIGGER trg_notify_on_booking AFTER INSERT ON public.coffee_chat_bookings FOR EACH ROW EXECUTE FUNCTION notify_on_booking();
CREATE TRIGGER trg_validate_booking BEFORE INSERT ON public.coffee_chat_bookings FOR EACH ROW EXECUTE FUNCTION validate_booking();
CREATE TRIGGER trg_companies_updated_at BEFORE UPDATE ON public.companies FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER mentors_set_updated_at BEFORE UPDATE ON public.mentors FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_guard_mentor_org BEFORE UPDATE ON public.mentors FOR EACH ROW EXECUTE FUNCTION guard_mentor_org_change();
CREATE TRIGGER trg_notify_on_shepherd_approved AFTER UPDATE OF status ON public.mentors FOR EACH ROW EXECUTE FUNCTION notify_on_shepherd_approved();
CREATE TRIGGER onboarding_responses_set_updated_at BEFORE UPDATE ON public.onboarding_responses FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_bootstrap_org_owner AFTER INSERT ON public.organizations FOR EACH ROW EXECUTE FUNCTION bootstrap_org_owner();
CREATE TRIGGER trg_cleanup_unlinked_org_card AFTER UPDATE ON public.organizations FOR EACH ROW EXECUTE FUNCTION cleanup_unlinked_org_card();
CREATE TRIGGER trg_sync_org_to_company BEFORE INSERT OR UPDATE ON public.organizations FOR EACH ROW EXECUTE FUNCTION sync_org_to_company();
CREATE TRIGGER profiles_set_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER signup_applications_set_updated_at BEFORE UPDATE ON public.signup_applications FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER uk_companies_touch BEFORE UPDATE ON public.uk_companies FOR EACH ROW EXECUTE FUNCTION uk_touch_updated_at();
CREATE TRIGGER user_company_matches_updated_at BEFORE UPDATE ON public.user_company_matches FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER user_credits_set_updated_at BEFORE UPDATE ON public.user_credits FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_saved_path_limit BEFORE INSERT ON public.user_saved_paths FOR EACH ROW EXECUTE FUNCTION enforce_saved_path_limit();
CREATE TRIGGER user_task_progress_set_updated_at BEFORE UPDATE ON public.user_task_progress FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Triggers on auth.users (outside public schema — captured separately)
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION handle_new_user();
CREATE TRIGGER on_auth_user_created_grant_admin AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION grant_permanent_admin();
CREATE TRIGGER on_auth_user_created_subscription AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION ensure_subscription_on_signup();
