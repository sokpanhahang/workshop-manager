-- ============================================================
-- CARPENTRY WORKSHOP MANAGEMENT SYSTEM
-- Supabase SQL Schema (PostgreSQL)
-- Copy and paste this entire file into Supabase SQL Editor
-- then click "Run"
-- ============================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. USER PROFILES & ROLES
-- ============================================================

CREATE TABLE public.profiles (
    id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name   TEXT NOT NULL,
    role        TEXT NOT NULL CHECK (role IN ('boss', 'worker', 'purchasing', 'accountant', 'stock_manager')),
    phone       TEXT,
    hourly_rate NUMERIC(10,2) DEFAULT 0,  -- for payroll calculation
    is_active   BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 2. JOB SITES
-- ============================================================

CREATE TABLE public.sites (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        TEXT NOT NULL,
    address     TEXT,
    is_active   BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 3. SUPPLIERS
-- ============================================================

CREATE TABLE public.suppliers (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        TEXT NOT NULL,
    contact     TEXT,
    phone       TEXT,
    email       TEXT,
    address     TEXT,
    notes       TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 4. PURCHASE ORDERS & APPROVALS
-- ============================================================

CREATE TABLE public.purchase_orders (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number    TEXT UNIQUE NOT NULL DEFAULT 'PO-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || FLOOR(RANDOM()*9000+1000)::TEXT,
    requested_by    UUID REFERENCES public.profiles(id),
    site_id         UUID REFERENCES public.sites(id),
    supplier_id     UUID REFERENCES public.suppliers(id),
    description     TEXT NOT NULL,
    quantity        NUMERIC(10,2),
    unit            TEXT,
    estimated_cost  NUMERIC(10,2),
    actual_cost     NUMERIC(10,2),
    urgency         TEXT CHECK (urgency IN ('low', 'normal', 'urgent')) DEFAULT 'normal',
    status          TEXT NOT NULL CHECK (status IN (
                        'draft',
                        'submitted',
                        'purchasing_review',
                        'boss_review',
                        'approved',
                        'rejected',
                        'ordered',
                        'received'
                    )) DEFAULT 'submitted',
    purchasing_note TEXT,
    boss_note       TEXT,
    reviewed_by     UUID REFERENCES public.profiles(id),
    approved_by     UUID REFERENCES public.profiles(id),
    reviewed_at     TIMESTAMPTZ,
    approved_at     TIMESTAMPTZ,
    attachment_url  TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Approval history log
CREATE TABLE public.order_approval_log (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id    UUID REFERENCES public.purchase_orders(id) ON DELETE CASCADE,
    action      TEXT NOT NULL,  -- 'submitted', 'reviewed', 'approved', 'rejected', 'ordered', 'received'
    action_by   UUID REFERENCES public.profiles(id),
    note        TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 5. STOCK / INVENTORY
-- ============================================================

CREATE TABLE public.stock_items (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name            TEXT NOT NULL,
    category        TEXT,
    unit            TEXT NOT NULL,  -- pcs, kg, m, litre, etc.
    quantity        NUMERIC(10,2) DEFAULT 0,
    reorder_level   NUMERIC(10,2) DEFAULT 0,  -- alert when below this
    location        TEXT,  -- shelf / storage area
    notes           TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.stock_requests (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    requested_by    UUID REFERENCES public.profiles(id),
    site_id         UUID REFERENCES public.sites(id),
    item_id         UUID REFERENCES public.stock_items(id),
    quantity_needed NUMERIC(10,2) NOT NULL,
    purpose         TEXT,
    status          TEXT CHECK (status IN ('pending', 'approved', 'issued', 'rejected')) DEFAULT 'pending',
    issued_qty      NUMERIC(10,2),
    handled_by      UUID REFERENCES public.profiles(id),
    handled_at      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.stock_movements (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    item_id     UUID REFERENCES public.stock_items(id),
    type        TEXT CHECK (type IN ('in', 'out', 'adjustment')),
    quantity    NUMERIC(10,2) NOT NULL,
    reference   TEXT,  -- PO number, request ID, etc.
    note        TEXT,
    done_by     UUID REFERENCES public.profiles(id),
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 6. DAILY WORK REPORTS
-- ============================================================

CREATE TABLE public.daily_reports (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    worker_id       UUID REFERENCES public.profiles(id),
    site_id         UUID REFERENCES public.sites(id),
    report_date     DATE NOT NULL DEFAULT CURRENT_DATE,
    start_time      TIME,
    end_time        TIME,
    hours_worked    NUMERIC(4,2),  -- auto-calculated or manual
    tasks_done      TEXT NOT NULL,
    materials_used  TEXT,
    issues          TEXT,
    next_steps      TEXT,
    photo_url       TEXT,  -- optional site photo
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 7. ACCOUNTING
-- ============================================================

-- Expenses (by project/site)
CREATE TABLE public.expenses (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id         UUID REFERENCES public.sites(id),
    category        TEXT NOT NULL,  -- materials, labour, transport, misc
    description     TEXT NOT NULL,
    amount          NUMERIC(10,2) NOT NULL,
    expense_date    DATE DEFAULT CURRENT_DATE,
    receipt_url     TEXT,
    recorded_by     UUID REFERENCES public.profiles(id),
    purchase_order_id UUID REFERENCES public.purchase_orders(id),
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Supplier invoices
CREATE TABLE public.invoices (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    supplier_id     UUID REFERENCES public.suppliers(id),
    invoice_number  TEXT,
    amount          NUMERIC(10,2) NOT NULL,
    due_date        DATE,
    paid_date       DATE,
    status          TEXT CHECK (status IN ('unpaid', 'paid', 'overdue')) DEFAULT 'unpaid',
    purchase_order_id UUID REFERENCES public.purchase_orders(id),
    attachment_url  TEXT,
    recorded_by     UUID REFERENCES public.profiles(id),
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Payroll records (auto-generated from daily reports)
CREATE TABLE public.payroll (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    worker_id       UUID REFERENCES public.profiles(id),
    period_start    DATE NOT NULL,
    period_end      DATE NOT NULL,
    total_hours     NUMERIC(6,2),
    hourly_rate     NUMERIC(10,2),
    gross_pay       NUMERIC(10,2),
    deductions      NUMERIC(10,2) DEFAULT 0,
    net_pay         NUMERIC(10,2),
    status          TEXT CHECK (status IN ('draft', 'approved', 'paid')) DEFAULT 'draft',
    paid_date       DATE,
    notes           TEXT,
    created_by      UUID REFERENCES public.profiles(id),
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 8. ROW LEVEL SECURITY (RLS)
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_approval_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payroll ENABLE ROW LEVEL SECURITY;

-- Helper function to get current user role
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER;

-- PROFILES: users see own, boss sees all
CREATE POLICY "profiles_self" ON public.profiles
    FOR SELECT USING (id = auth.uid() OR public.get_my_role() = 'boss');
CREATE POLICY "profiles_insert_self" ON public.profiles
    FOR INSERT WITH CHECK (id = auth.uid());
CREATE POLICY "profiles_update_self" ON public.profiles
    FOR UPDATE USING (id = auth.uid() OR public.get_my_role() = 'boss');

-- SITES: all authenticated users can view
CREATE POLICY "sites_all_read" ON public.sites
    FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "sites_boss_write" ON public.sites
    FOR ALL USING (public.get_my_role() = 'boss');

-- PURCHASE ORDERS: workers see own, purchasing/boss see all
CREATE POLICY "orders_read" ON public.purchase_orders
    FOR SELECT USING (
        requested_by = auth.uid()
        OR public.get_my_role() IN ('boss', 'purchasing', 'accountant')
    );
CREATE POLICY "orders_insert" ON public.purchase_orders
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "orders_update" ON public.purchase_orders
    FOR UPDATE USING (
        public.get_my_role() IN ('boss', 'purchasing')
        OR (requested_by = auth.uid() AND status = 'draft')
    );

-- APPROVAL LOG: same as orders
CREATE POLICY "approval_log_read" ON public.order_approval_log
    FOR SELECT USING (
        public.get_my_role() IN ('boss', 'purchasing', 'accountant')
        OR EXISTS (
            SELECT 1 FROM public.purchase_orders po
            WHERE po.id = order_id AND po.requested_by = auth.uid()
        )
    );
CREATE POLICY "approval_log_insert" ON public.order_approval_log
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- STOCK: all can view, stock_manager/boss can modify
CREATE POLICY "stock_items_read" ON public.stock_items
    FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "stock_items_write" ON public.stock_items
    FOR ALL USING (public.get_my_role() IN ('boss', 'stock_manager'));

CREATE POLICY "stock_requests_read" ON public.stock_requests
    FOR SELECT USING (
        requested_by = auth.uid()
        OR public.get_my_role() IN ('boss', 'stock_manager')
    );
CREATE POLICY "stock_requests_insert" ON public.stock_requests
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "stock_requests_update" ON public.stock_requests
    FOR UPDATE USING (public.get_my_role() IN ('boss', 'stock_manager'));

CREATE POLICY "stock_movements_read" ON public.stock_movements
    FOR SELECT USING (public.get_my_role() IN ('boss', 'stock_manager', 'accountant'));
CREATE POLICY "stock_movements_write" ON public.stock_movements
    FOR ALL USING (public.get_my_role() IN ('boss', 'stock_manager'));

-- DAILY REPORTS: workers see own, boss sees all
CREATE POLICY "daily_reports_read" ON public.daily_reports
    FOR SELECT USING (
        worker_id = auth.uid()
        OR public.get_my_role() = 'boss'
    );
CREATE POLICY "daily_reports_insert" ON public.daily_reports
    FOR INSERT WITH CHECK (worker_id = auth.uid() OR public.get_my_role() = 'boss');
CREATE POLICY "daily_reports_update" ON public.daily_reports
    FOR UPDATE USING (worker_id = auth.uid() OR public.get_my_role() = 'boss');

-- EXPENSES & INVOICES: accountant and boss
CREATE POLICY "expenses_read" ON public.expenses
    FOR SELECT USING (public.get_my_role() IN ('boss', 'accountant'));
CREATE POLICY "expenses_write" ON public.expenses
    FOR ALL USING (public.get_my_role() IN ('boss', 'accountant'));

CREATE POLICY "invoices_read" ON public.invoices
    FOR SELECT USING (public.get_my_role() IN ('boss', 'accountant', 'purchasing'));
CREATE POLICY "invoices_write" ON public.invoices
    FOR ALL USING (public.get_my_role() IN ('boss', 'accountant'));

-- PAYROLL: accountant and boss only
CREATE POLICY "payroll_read" ON public.payroll
    FOR SELECT USING (
        worker_id = auth.uid()
        OR public.get_my_role() IN ('boss', 'accountant')
    );
CREATE POLICY "payroll_write" ON public.payroll
    FOR ALL USING (public.get_my_role() IN ('boss', 'accountant'));

-- SUPPLIERS: purchasing, boss, accountant
CREATE POLICY "suppliers_read" ON public.suppliers
    FOR SELECT USING (public.get_my_role() IN ('boss', 'purchasing', 'accountant'));
CREATE POLICY "suppliers_write" ON public.suppliers
    FOR ALL USING (public.get_my_role() IN ('boss', 'purchasing'));

-- ============================================================
-- 9. USEFUL VIEWS
-- ============================================================

-- Boss dashboard: today's active workers
CREATE VIEW public.v_today_reports AS
SELECT
    dr.id,
    p.full_name AS worker_name,
    s.name AS site_name,
    dr.start_time,
    dr.end_time,
    dr.hours_worked,
    dr.tasks_done,
    dr.issues,
    dr.report_date
FROM public.daily_reports dr
JOIN public.profiles p ON dr.worker_id = p.id
JOIN public.sites s ON dr.site_id = s.id
WHERE dr.report_date = CURRENT_DATE;

-- Pending purchase orders for boss
CREATE VIEW public.v_pending_orders AS
SELECT
    po.id,
    po.order_number,
    p.full_name AS requested_by,
    s.name AS site_name,
    po.description,
    po.estimated_cost,
    po.urgency,
    po.status,
    po.created_at
FROM public.purchase_orders po
JOIN public.profiles p ON po.requested_by = p.id
LEFT JOIN public.sites s ON po.site_id = s.id
WHERE po.status IN ('submitted', 'purchasing_review', 'boss_review')
ORDER BY po.urgency DESC, po.created_at ASC;

-- Low stock alert view
CREATE VIEW public.v_low_stock AS
SELECT
    id,
    name,
    category,
    quantity,
    reorder_level,
    unit,
    location
FROM public.stock_items
WHERE quantity <= reorder_level;

-- Monthly expense summary by site
CREATE VIEW public.v_monthly_expenses AS
SELECT
    s.name AS site_name,
    TO_CHAR(e.expense_date, 'YYYY-MM') AS month,
    e.category,
    SUM(e.amount) AS total
FROM public.expenses e
JOIN public.sites s ON e.site_id = s.id
GROUP BY s.name, TO_CHAR(e.expense_date, 'YYYY-MM'), e.category
ORDER BY month DESC, site_name;

-- ============================================================
-- 10. SAMPLE SEED DATA (optional — delete if not needed)
-- ============================================================

-- Sample sites
INSERT INTO public.sites (name, address) VALUES
    ('Main Workshop', '123 Timber Street, Kuala Lumpur'),
    ('Site A - Taman Maju', 'Jalan Maju 5, Petaling Jaya'),
    ('Site B - Ara Damansara', 'Block C, Ara Damansara');

-- Sample suppliers
INSERT INTO public.suppliers (name, contact, phone) VALUES
    ('Timber Direct Sdn Bhd', 'Mr. Ahmad', '012-3456789'),
    ('Hardware Pro', 'Ms. Lee', '011-9876543'),
    ('Varnish & Finish Co.', 'Mr. Ravi', '019-1112222');

-- Sample stock items
INSERT INTO public.stock_items (name, category, unit, quantity, reorder_level) VALUES
    ('Plywood 4x8 (18mm)', 'Wood', 'sheets', 50, 10),
    ('Nails 3 inch', 'Fasteners', 'kg', 20, 5),
    ('Wood Varnish (clear)', 'Finishing', 'litre', 15, 5),
    ('Sandpaper 120 grit', 'Abrasives', 'pcs', 100, 20),
    ('Timber 2x4 (12ft)', 'Wood', 'pcs', 30, 8),
    ('Wood Glue', 'Adhesives', 'bottle', 12, 3),
    ('Screws M6x50', 'Fasteners', 'pcs', 500, 100),
    ('Hinges (3 inch)', 'Hardware', 'pcs', 60, 10);

-- ============================================================
-- SCHEMA COMPLETE
-- All tables, security policies, views, and sample data ready.
-- ============================================================
