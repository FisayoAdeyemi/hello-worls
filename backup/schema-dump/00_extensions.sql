-- KoffeeChat live-schema dump — extensions
-- Extracted from the production Lovable Cloud database (xgzocrxujslfoaotrzlr), 2026-08-24.
-- pg_cron / pgmq / supabase_vault / pg_net are Supabase-platform pieces; a fresh Supabase
-- project provisions them itself. The ones the app schema actually depends on: http, pg_trgm, pgcrypto, uuid-ossp.
CREATE EXTENSION IF NOT EXISTS http WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
