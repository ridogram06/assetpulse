-- AssetPulse — Supabase PostgreSQL Schema v1.0
-- Run this in Supabase SQL Editor

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_cron";

-- TABLE 1: PROFILES
CREATE TABLE profiles (
  id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name    TEXT,
  avatar_url      TEXT,
  currency        TEXT    DEFAULT 'BDT',
  currency_symbol TEXT    DEFAULT '৳',
  monthly_budget  NUMERIC(12,2),
  language        TEXT    DEFAULT 'bn',
  theme           TEXT    DEFAULT 'dark',
  fcm_token       TEXT,
  last_sync_at    TIMESTAMPTZ DEFAULT NOW(),
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO profiles (id, display_name)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'display_name')
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- TABLE 2: VAULTS
CREATE TABLE vaults (
  id          UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID    REFERENCES profiles(id) ON DELETE CASCADE,
  name        TEXT    NOT NULL,
  icon        TEXT    DEFAULT '📁',
  color       TEXT    DEFAULT '#6366F1',
  budget      NUMERIC(12,2),
  is_default  BOOLEAN DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- TABLE 3: PAYMENT METHODS
CREATE TABLE payment_methods (
  id          UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID    REFERENCES profiles(id) ON DELETE CASCADE,
  name        TEXT    NOT NULL,
  icon        TEXT    DEFAULT '💳',
  color       TEXT    DEFAULT '#E91E8C',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- TABLE 4: ASSETS
CREATE TABLE assets (
  id                    UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID    REFERENCES profiles(id) ON DELETE CASCADE,
  vault_id              UUID    REFERENCES vaults(id) ON DELETE SET NULL,
  payment_method_id     UUID    REFERENCES payment_methods(id) ON DELETE SET NULL,
  name                  TEXT    NOT NULL,
  category              TEXT,
  icon                  TEXT    DEFAULT '📦',
  color                 TEXT    DEFAULT '#6366F1',
  notes                 TEXT,
  asset_type            TEXT    NOT NULL CHECK (asset_type IN ('deterministic','probabilistic')),
  cost                  NUMERIC(12,2) NOT NULL,
  currency              TEXT    DEFAULT 'BDT',
  start_date            DATE    NOT NULL,
  end_date              DATE,
  billing_cycle         TEXT    CHECK (billing_cycle IN ('monthly','quarterly','annually','custom')),
  auto_renew            BOOLEAN DEFAULT false,
  notify_days_before    INT     DEFAULT 3,
  suspended_at          TIMESTAMPTZ,
  suspended_until       TIMESTAMPTZ,
  finished_at           TIMESTAMPTZ,
  predicted_end_date    DATE,
  prediction_confidence NUMERIC(5,2),
  status                TEXT    DEFAULT 'active'
                        CHECK (status IN ('active','warning','critical','expired','finished','suspended')),
  client_updated_at     TIMESTAMPTZ DEFAULT NOW(),
  created_at            TIMESTAMPTZ DEFAULT NOW(),
  updated_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION touch_client_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.client_updated_at := NOW(); RETURN NEW; END;
$$;
CREATE TRIGGER assets_touch_updated
  BEFORE UPDATE ON assets FOR EACH ROW EXECUTE FUNCTION touch_client_updated_at();

-- TABLE 5: ASSET HISTORY
CREATE TABLE asset_history (
  id            UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID    REFERENCES profiles(id) ON DELETE CASCADE,
  asset_id      UUID    REFERENCES assets(id) ON DELETE SET NULL,
  asset_name    TEXT    NOT NULL,
  category      TEXT,
  cost          NUMERIC(12,2),
  currency      TEXT    DEFAULT 'BDT',
  start_date    DATE    NOT NULL,
  finished_at   TIMESTAMPTZ NOT NULL,
  lifespan_days INT     GENERATED ALWAYS AS
                (EXTRACT(DAY FROM finished_at - start_date::TIMESTAMPTZ)::INT) STORED,
  cost_per_day  NUMERIC(10,4) GENERATED ALWAYS AS
                (cost / NULLIF(EXTRACT(DAY FROM finished_at - start_date::TIMESTAMPTZ), 0)) STORED,
  notes         TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- TABLE 6: AUDIT LOG
CREATE TABLE audit_log (
  id          UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID    REFERENCES profiles(id) ON DELETE CASCADE,
  asset_id    UUID    REFERENCES assets(id) ON DELETE SET NULL,
  action      TEXT    NOT NULL,
  old_data    JSONB,
  new_data    JSONB,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- TABLE 7: NOTIFICATION LOG
CREATE TABLE notification_log (
  id          UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID    REFERENCES profiles(id) ON DELETE CASCADE,
  asset_id    UUID    REFERENCES assets(id) ON DELETE CASCADE,
  notif_type  TEXT    NOT NULL,
  channel     TEXT    NOT NULL,
  sent_at     TIMESTAMPTZ DEFAULT NOW(),
  read_at     TIMESTAMPTZ,
  title       TEXT,
  body        TEXT
);

-- TABLE 8: NOTIFICATION PREFERENCES
CREATE TABLE notification_preferences (
  id                UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID    REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,
  email_enabled     BOOLEAN DEFAULT true,
  push_enabled      BOOLEAN DEFAULT true,
  dnd_start         TIME,
  dnd_end           TIME,
  budget_alerts     BOOLEAN DEFAULT true,
  prediction_alerts BOOLEAN DEFAULT true,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

-- INDEXES
CREATE INDEX IF NOT EXISTS idx_assets_user_status
  ON assets(user_id, status) WHERE status NOT IN ('expired','finished');
CREATE INDEX IF NOT EXISTS idx_assets_end_date
  ON assets(end_date) WHERE asset_type = 'deterministic';
CREATE INDEX IF NOT EXISTS idx_history_user_name
  ON asset_history(user_id, LOWER(asset_name));
CREATE INDEX IF NOT EXISTS idx_notif_log_dedup
  ON notification_log(asset_id, notif_type, sent_at DESC);

-- FUNCTION: predict_next_expiry
CREATE OR REPLACE FUNCTION predict_next_expiry(
  p_user_id UUID, p_asset_name TEXT, p_start_date DATE
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
  SELECT COUNT(*), AVG(lifespan_days), STDDEV(lifespan_days)
  INTO v_count, v_mean, v_stddev FROM asset_history
  WHERE user_id = p_user_id AND LOWER(asset_name) = LOWER(p_asset_name);

  IF v_count < 3 THEN
    RETURN QUERY SELECT NULL::DATE, 0::NUMERIC, v_count,
      COALESCE(v_mean,0)::NUMERIC, 0::NUMERIC, 'insufficient_data'::TEXT;
    RETURN;
  END IF;

  SELECT PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY lifespan_days),
         PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY lifespan_days)
  INTO v_q1, v_q3 FROM asset_history
  WHERE user_id = p_user_id AND LOWER(asset_name) = LOWER(p_asset_name);

  v_iqr := GREATEST(v_q3 - v_q1, 1.0);

  SELECT AVG(lifespan_days) INTO v_mean FROM asset_history
  WHERE user_id = p_user_id AND LOWER(asset_name) = LOWER(p_asset_name)
    AND lifespan_days BETWEEN (v_q1 - 1.5*v_iqr) AND (v_q3 + 1.5*v_iqr);

  IF v_mean IS NULL THEN
    SELECT AVG(lifespan_days) INTO v_mean FROM asset_history
    WHERE user_id = p_user_id AND LOWER(asset_name) = LOWER(p_asset_name);
    v_algorithm := 'mean_fallback';
  END IF;

  IF v_count >= 6 THEN
    SELECT SUM(lifespan_days * weight) / NULLIF(SUM(weight), 0)
    INTO v_weighted FROM (
      SELECT lifespan_days,
        1.0 / ROW_NUMBER() OVER (ORDER BY finished_at DESC) AS weight
      FROM asset_history
      WHERE user_id = p_user_id AND LOWER(asset_name) = LOWER(p_asset_name)
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

-- FUNCTION: nightly status updater
CREATE OR REPLACE FUNCTION update_asset_statuses()
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  UPDATE assets SET status = CASE
    WHEN end_date < CURRENT_DATE         THEN 'expired'
    WHEN end_date <= CURRENT_DATE + 3   THEN 'critical'
    WHEN end_date <= CURRENT_DATE + 7   THEN 'warning'
    ELSE 'active'
  END
  WHERE asset_type = 'deterministic'
    AND status NOT IN ('suspended','finished','expired');
END;
$$;

SELECT cron.schedule('nightly-asset-scan', '0 0 * * *', $$ SELECT update_asset_statuses(); $$);

-- ROW LEVEL SECURITY
ALTER TABLE profiles             ENABLE ROW LEVEL SECURITY;
ALTER TABLE assets               ENABLE ROW LEVEL SECURITY;
ALTER TABLE asset_history        ENABLE ROW LEVEL SECURITY;
ALTER TABLE vaults               ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_methods      ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log            ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_log     ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "own_data" ON profiles             FOR ALL USING (auth.uid() = id);
CREATE POLICY "own_data" ON assets               FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "own_data" ON asset_history        FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "own_data" ON vaults               FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "own_data" ON payment_methods      FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "own_data" ON audit_log            FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "own_data" ON notification_log     FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "own_data" ON notification_preferences FOR ALL USING (auth.uid() = user_id);
