-- ============================================================================
-- AssetPulse V5 Migration
-- Run AFTER 001_initial_schema.sql on Supabase SQL Editor.
-- Idempotent: safe to re-run.
-- Covers: FIX-1, FIX-2, FIX-3, FIX-4, FIX-6, FIX-7
--         FEAT-2, FEAT-4, FEAT-8, FEAT-10
-- ============================================================================

-- =========================
-- FIX-2: Payment status
-- =========================
ALTER TABLE assets
  ADD COLUMN IF NOT EXISTS payment_status TEXT DEFAULT 'confirmed'
  CHECK (payment_status IN ('confirmed','pending_payment','failed'));

-- =========================
-- FIX-1: Conflict resolution
-- =========================
CREATE TABLE IF NOT EXISTS pending_conflicts (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES profiles(id) ON DELETE CASCADE,
  asset_id    UUID REFERENCES assets(id) ON DELETE CASCADE,
  local_data  JSONB NOT NULL,
  server_data JSONB NOT NULL,
  detected_at TIMESTAMPTZ DEFAULT NOW()
);

-- =========================
-- FIX-3: Canonical asset id (rename-safe prediction history)
-- =========================
ALTER TABLE asset_history
  ADD COLUMN IF NOT EXISTS canonical_asset_id UUID;

CREATE INDEX IF NOT EXISTS idx_history_canonical
  ON asset_history(canonical_asset_id);

-- Backfill canonical_asset_id from existing asset_id where possible
UPDATE asset_history
   SET canonical_asset_id = asset_id
 WHERE canonical_asset_id IS NULL AND asset_id IS NOT NULL;

-- Updated predict_next_expiry: prefers canonical_asset_id, falls back to name
CREATE OR REPLACE FUNCTION predict_next_expiry(
  p_user_id      UUID,
  p_asset_name   TEXT,
  p_start_date   DATE,
  p_canonical_id UUID DEFAULT NULL
)
RETURNS TABLE(
  predicted_date DATE, confidence NUMERIC, sample_count INT,
  mean_days NUMERIC, iqr_days NUMERIC, algorithm_used TEXT
)
LANGUAGE plpgsql AS $$
DECLARE
  v_count INT; v_mean NUMERIC; v_stddev NUMERIC;
  v_q1 NUMERIC; v_q3 NUMERIC; v_iqr NUMERIC;
  v_weighted NUMERIC; v_confidence NUMERIC;
  v_algorithm TEXT := 'mean';
BEGIN
  -- Match: canonical_asset_id wins; otherwise fall back to LOWER(name)
  SELECT COUNT(*), AVG(lifespan_days), STDDEV(lifespan_days)
    INTO v_count, v_mean, v_stddev
    FROM asset_history
   WHERE user_id = p_user_id
     AND (
       (p_canonical_id IS NOT NULL AND canonical_asset_id = p_canonical_id)
       OR (p_canonical_id IS NULL AND LOWER(asset_name) = LOWER(p_asset_name))
     );

  IF v_count < 3 THEN
    RETURN QUERY SELECT NULL::DATE, 0::NUMERIC, v_count,
      COALESCE(v_mean,0)::NUMERIC, 0::NUMERIC, 'insufficient_data'::TEXT;
    RETURN;
  END IF;

  SELECT PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY lifespan_days),
         PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY lifespan_days)
    INTO v_q1, v_q3
    FROM asset_history
   WHERE user_id = p_user_id
     AND (
       (p_canonical_id IS NOT NULL AND canonical_asset_id = p_canonical_id)
       OR (p_canonical_id IS NULL AND LOWER(asset_name) = LOWER(p_asset_name))
     );

  v_iqr := GREATEST(v_q3 - v_q1, 1.0);

  SELECT AVG(lifespan_days) INTO v_mean
    FROM asset_history
   WHERE user_id = p_user_id
     AND (
       (p_canonical_id IS NOT NULL AND canonical_asset_id = p_canonical_id)
       OR (p_canonical_id IS NULL AND LOWER(asset_name) = LOWER(p_asset_name))
     )
     AND lifespan_days BETWEEN (v_q1 - 1.5*v_iqr) AND (v_q3 + 1.5*v_iqr);

  IF v_mean IS NULL THEN
    SELECT AVG(lifespan_days) INTO v_mean
      FROM asset_history
     WHERE user_id = p_user_id
       AND (
         (p_canonical_id IS NOT NULL AND canonical_asset_id = p_canonical_id)
         OR (p_canonical_id IS NULL AND LOWER(asset_name) = LOWER(p_asset_name))
       );
    v_algorithm := 'mean_fallback';
  END IF;

  IF v_count >= 6 THEN
    SELECT SUM(lifespan_days * weight) / NULLIF(SUM(weight), 0)
      INTO v_weighted FROM (
        SELECT lifespan_days,
          1.0 / ROW_NUMBER() OVER (ORDER BY finished_at DESC) AS weight
          FROM asset_history
         WHERE user_id = p_user_id
           AND (
             (p_canonical_id IS NOT NULL AND canonical_asset_id = p_canonical_id)
             OR (p_canonical_id IS NULL AND LOWER(asset_name) = LOWER(p_asset_name))
           )
           AND lifespan_days BETWEEN (v_q1 - 1.5*v_iqr) AND (v_q3 + 1.5*v_iqr)
      ) sub;
    v_mean := COALESCE(v_weighted, v_mean);
    v_algorithm := 'wma';
  END IF;

  IF v_count >= 10 THEN v_algorithm := 'wma_exp_ready'; END IF;

  v_confidence := LEAST(95.0, GREATEST(40.0,
    (v_count::NUMERIC * 7.0) - (COALESCE(v_stddev,0) * 1.5)
    + (CASE WHEN v_iqr <= 3 THEN 5.0 ELSE 0.0 END)
  ));

  RETURN QUERY SELECT
    (p_start_date + CEIL(COALESCE(v_mean, 30))::INT)::DATE,
    ROUND(v_confidence, 1), v_count,
    ROUND(COALESCE(v_mean,0), 1), ROUND(v_iqr, 2), v_algorithm;
END;
$$;

-- =========================
-- FIX-7: 2FA tracking
-- =========================
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS last_2fa_verified_at TIMESTAMPTZ;

-- =========================
-- FEAT-2: Vault sharing
-- =========================
CREATE TABLE IF NOT EXISTS vault_members (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vault_id    UUID REFERENCES vaults(id) ON DELETE CASCADE,
  user_id     UUID REFERENCES profiles(id) ON DELETE CASCADE,
  role        TEXT CHECK (role IN ('viewer','editor')),
  invited_by  UUID REFERENCES profiles(id),
  accepted_at TIMESTAMPTZ,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Update assets RLS to allow shared-vault access
DROP POLICY IF EXISTS "own_data" ON assets;
CREATE POLICY "own_or_shared" ON assets FOR ALL USING (
  auth.uid() = user_id
  OR vault_id IN (
    SELECT vault_id FROM vault_members
     WHERE user_id = auth.uid() AND accepted_at IS NOT NULL
  )
);

-- =========================
-- FEAT-4: Monthly budget log (streak)
-- =========================
CREATE TABLE IF NOT EXISTS monthly_budget_log (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID REFERENCES profiles(id) ON DELETE CASCADE,
  year_month   TEXT NOT NULL,
  budget_set   NUMERIC(12,2),
  actual_spend NUMERIC(12,2),
  under_budget BOOLEAN GENERATED ALWAYS AS (actual_spend <= budget_set) STORED,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, year_month)
);

-- =========================
-- FEAT-8: Asset templates
-- =========================
CREATE TABLE IF NOT EXISTS asset_templates (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID REFERENCES profiles(id) ON DELETE CASCADE,
  name                TEXT NOT NULL,
  asset_type          TEXT,
  cost                NUMERIC(12,2),
  category            TEXT,
  icon                TEXT,
  billing_cycle       TEXT,
  notify_days_before  INT DEFAULT 3,
  vault_id            UUID,
  payment_method_id   UUID,
  use_count           INT DEFAULT 0,
  created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- =========================
-- FEAT-10: Asset attachments (photos)
-- =========================
CREATE TABLE IF NOT EXISTS asset_attachments (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES profiles(id) ON DELETE CASCADE,
  asset_id    UUID REFERENCES assets(id) ON DELETE CASCADE,
  file_path   TEXT NOT NULL,
  file_type   TEXT,
  file_size   INT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- =========================
-- FIX-6: Edge function rate-limit log
-- =========================
CREATE TABLE IF NOT EXISTS edge_function_log (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  func_name TEXT,
  called_at TIMESTAMPTZ DEFAULT NOW(),
  user_id   UUID
);

CREATE INDEX IF NOT EXISTS idx_edge_log_recent
  ON edge_function_log(user_id, called_at DESC);

-- =========================
-- RLS for new tables
-- =========================
ALTER TABLE pending_conflicts    ENABLE ROW LEVEL SECURITY;
ALTER TABLE vault_members        ENABLE ROW LEVEL SECURITY;
ALTER TABLE monthly_budget_log   ENABLE ROW LEVEL SECURITY;
ALTER TABLE asset_templates      ENABLE ROW LEVEL SECURITY;
ALTER TABLE asset_attachments    ENABLE ROW LEVEL SECURITY;
ALTER TABLE edge_function_log    ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "own_data" ON pending_conflicts;
CREATE POLICY "own_data" ON pending_conflicts
  FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "own_data" ON monthly_budget_log;
CREATE POLICY "own_data" ON monthly_budget_log
  FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "own_data" ON asset_templates;
CREATE POLICY "own_data" ON asset_templates
  FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "own_data" ON asset_attachments;
CREATE POLICY "own_data" ON asset_attachments
  FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "own_or_invited" ON vault_members;
CREATE POLICY "own_or_invited" ON vault_members
  FOR ALL USING (auth.uid() = user_id OR auth.uid() = invited_by);

-- edge_function_log: only service-role writes; users can read their own
DROP POLICY IF EXISTS "read_own" ON edge_function_log;
CREATE POLICY "read_own" ON edge_function_log
  FOR SELECT USING (auth.uid() = user_id);

-- =========================
-- FIX-4: pg_cron master orchestrator
-- (requires pg_net extension enabled in Supabase: Database → Extensions)
-- =========================
-- NOTE: Before running the cron schedule, set these once in SQL editor:
--   ALTER DATABASE postgres SET app.supabase_url        = 'https://<your-ref>.supabase.co';
--   ALTER DATABASE postgres SET app.service_role_key    = '<service-role-jwt>';
-- Then reload the connection. The function reads them via current_setting().

CREATE OR REPLACE FUNCTION nightly_master_job()
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_url  TEXT;
  v_key  TEXT;
BEGIN
  -- Step 1: status updates
  PERFORM update_asset_statuses();

  -- Step 2: only attempt notification call if pg_net is available AND
  --         the secrets are configured. Wrap in exception block so a
  --         missing extension never breaks the status update.
  BEGIN
    v_url := current_setting('app.supabase_url', true);
    v_key := current_setting('app.service_role_key', true);

    IF v_url IS NOT NULL AND v_key IS NOT NULL THEN
      PERFORM net.http_post(
        url     := v_url || '/functions/v1/send-notification',
        headers := jsonb_build_object(
          'Content-Type',  'application/json',
          'Authorization', 'Bearer ' || v_key
        ),
        body    := '{}'::jsonb
      );
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Edge call skipped: %', SQLERRM;
  END;
END;
$$;

-- Replace old cron schedule (idempotent)
DO $$
BEGIN
  PERFORM cron.unschedule('nightly-asset-scan');
EXCEPTION WHEN OTHERS THEN
  -- ignore if not scheduled
  NULL;
END $$;

DO $$
BEGIN
  PERFORM cron.unschedule('nightly-master');
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;

-- Schedule the new master job at midnight UTC (06:00 BDT).
-- Wrapped so the migration succeeds even if pg_cron is not enabled yet.
-- Enable pg_cron under: Database → Extensions, then re-run THIS block only.
DO $$
BEGIN
  PERFORM cron.schedule(
    'nightly-master',
    '0 0 * * *',
    $cron$ SELECT nightly_master_job(); $cron$
  );
  RAISE NOTICE 'pg_cron schedule installed: nightly-master @ 00:00 UTC';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'pg_cron not available — schedule skipped (%). Enable pg_cron extension and re-run this block.', SQLERRM;
END $$;
