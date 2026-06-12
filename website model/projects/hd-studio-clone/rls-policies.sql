-- ============================================================
-- HD Studio Clone — Supabase Row Level Security Policies
-- Apply in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================
-- Roles are stored in user_metadata.role (set during signUp)
-- Access via: auth.jwt() -> 'user_metadata' ->> 'role'
-- Owner check via: auth.uid() = owner_id (for projects table)
-- ============================================================


-- ──────────────────────────────────────────────────────────
-- TABLE: users   (admin-only for all operations)
-- ──────────────────────────────────────────────────────────
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_select_admin" ON users
  FOR SELECT TO authenticated
  USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

CREATE POLICY "users_insert_admin" ON users
  FOR INSERT TO authenticated
  WITH CHECK ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

CREATE POLICY "users_update_admin" ON users
  FOR UPDATE TO authenticated
  USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

CREATE POLICY "users_delete_admin" ON users
  FOR DELETE TO authenticated
  USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');


-- ──────────────────────────────────────────────────────────
-- TABLE: projects   (admin: all rows; user: own rows only)
-- ──────────────────────────────────────────────────────────
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

-- Admin reads all projects
CREATE POLICY "projects_select_admin" ON projects
  FOR SELECT TO authenticated
  USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- User reads own projects
CREATE POLICY "projects_select_user" ON projects
  FOR SELECT TO authenticated
  USING (auth.uid() = owner_id);

-- Admin inserts any project
CREATE POLICY "projects_insert_admin" ON projects
  FOR INSERT TO authenticated
  WITH CHECK ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- User inserts own projects (owner_id must equal their uid)
CREATE POLICY "projects_insert_user" ON projects
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = owner_id);

-- Admin updates any project
CREATE POLICY "projects_update_admin" ON projects
  FOR UPDATE TO authenticated
  USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- User updates own projects
CREATE POLICY "projects_update_user" ON projects
  FOR UPDATE TO authenticated
  USING (auth.uid() = owner_id);

-- Admin deletes any project
CREATE POLICY "projects_delete_admin" ON projects
  FOR DELETE TO authenticated
  USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- User deletes own projects
CREATE POLICY "projects_delete_user" ON projects
  FOR DELETE TO authenticated
  USING (auth.uid() = owner_id);


-- ──────────────────────────────────────────────────────────
-- TABLE: showcase_items   (public read; admin write)
-- ──────────────────────────────────────────────────────────
ALTER TABLE showcase_items ENABLE ROW LEVEL SECURITY;

-- Public read — anyone (including anonymous visitors)
CREATE POLICY "showcase_select_public" ON showcase_items
  FOR SELECT TO anon, authenticated
  USING (true);

CREATE POLICY "showcase_insert_admin" ON showcase_items
  FOR INSERT TO authenticated
  WITH CHECK ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

CREATE POLICY "showcase_update_admin" ON showcase_items
  FOR UPDATE TO authenticated
  USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

CREATE POLICY "showcase_delete_admin" ON showcase_items
  FOR DELETE TO authenticated
  USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');


-- ──────────────────────────────────────────────────────────
-- TABLE: pricing_plans   (public read; admin write)
-- ──────────────────────────────────────────────────────────
ALTER TABLE pricing_plans ENABLE ROW LEVEL SECURITY;

-- Public read — anyone
CREATE POLICY "pricing_select_public" ON pricing_plans
  FOR SELECT TO anon, authenticated
  USING (true);

CREATE POLICY "pricing_insert_admin" ON pricing_plans
  FOR INSERT TO authenticated
  WITH CHECK ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

CREATE POLICY "pricing_update_admin" ON pricing_plans
  FOR UPDATE TO authenticated
  USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

CREATE POLICY "pricing_delete_admin" ON pricing_plans
  FOR DELETE TO authenticated
  USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');


-- ============================================================
-- NOTE: The frontend admin-guard.js is active and will block
-- non-admin access in the browser. The policies above enforce
-- the same rules at the API/database level. Both layers are
-- required for complete security.
-- ============================================================
