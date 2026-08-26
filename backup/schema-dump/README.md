# KoffeeChat — live database schema dump

Extracted directly from the production Lovable Cloud database (project xgzocrxujslfoaotrzlr)
on 2026-08-24. This is the SOURCE OF TRUTH for Phase B (standing up an independent Supabase
project). Do NOT use `supabase/migrations/` replay for that — the 45 migration files are
missing objects that were created via direct SQL, including: the entire UK companies register
(uk_companies, uk_sponsors + functions), company_enrichment, validate_booking, the org
subsystem functions (is_org_admin/member/recruiter, join codes, org_views), the booking
notification triggers, and profiles.welcome_email_sent_at.

## Apply order (files are numbered)
00 extensions → 01 enum types + sequences → 02 tables → 03 constraints → 04 indexes
→ 05 functions → 06 triggers (incl. 3 triggers on auth.users) → 07 views
→ 08 RLS enables + policies (public + storage) → 09 grants/ACLs (incl. mentors email
column lockdown) → 10 storage bucket row.

Note: 02 runs before 05, but uk_companies has a DEFAULT calling uk_normalize_name().
If a fresh apply complains, create that one function first (it is in 05) or drop/re-add
the column default after.

## Deliberately NOT included — handle separately in Phase B
- DATA: use the Lovable Cloud full export (Cloud → Advanced → Export data), which also
  carries auth.users (incl. password hashes) and auth.identities.
- STORAGE OBJECTS: 187 files in the public `company-logos` bucket (mentor avatars +
  curated logos) — copy via the storage API; the bucket row + RLS policies are covered here.
- AUTH CONFIG: Google OAuth provider (create your own client), redirect allowlist,
  site URL, OTP expiry = 86400, email confirmation ON, SMTP via Resend
  (smtp.resend.com:465, user `resend`, password = RESEND_API_KEY, from hello@koffeechat.com).
- EDGE FUNCTIONS + SECRETS: deploy from supabase/functions/ in the app repo; secrets:
  RESEND_API_KEY, OPENAI_API_KEY (until the Claude API swap), ANTHROPIC_API_KEY (after),
  STRIPE_SECRET_KEY, PAYSTACK_SECRET_KEY, PUBLIC_APP_URL. Repoint Stripe/Paystack webhooks.
- Lovable-only machinery excluded on purpose: pgmq email queue, email_queue_dispatch/wake
  cron — replaced by direct Resend sending off-platform.
- DNS at cutover: point app.koffeechat.com at the new host; DELETE the two NS records
  delegating notify.app.koffeechat.com to ns5/ns6.lovable.cloud.
