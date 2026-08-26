-- Storage bucket (objects themselves must be copied separately — 187 files in company-logos)
INSERT INTO storage.buckets (id, name, public) VALUES ('company-logos', 'company-logos', true) ON CONFLICT (id) DO NOTHING;
-- storage.objects RLS policies are included in 08_rls_policies.sql
