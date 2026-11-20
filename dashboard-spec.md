# Boss Dashboard — Carpentry Workshop
**Platform:** AppSmith + Supabase  
**Audience:** Workshop owner / manager  
**Entry point:** First page after login  
**Layout:** Responsive grid — 12-column on desktop, single-column stack on mobile

---

## 1. Layout Overview

```
┌─────────────────────────────────────────────────────────┐
│  [KPI: Pending Approvals] [KPI: Active Workers Today]   │
│  [KPI: Low Stock Items]   [KPI: Monthly Expenses Total] │
├─────────────────────────────────────────────────────────┤
│  [Today's Site Activity Feed]  [PO Status Chart]        │
├─────────────────────────────────────────────────────────┤
│  [Stock Level Table]                                    │
├─────────────────────────────────────────────────────────┤
│  [Payroll Summary]                                      │
└─────────────────────────────────────────────────────────┘
```

**Desktop:** Two-column sections where noted. All sections collapse to full-width on screens < 768 px.

---

## 2. KPI Cards Row

Four stat cards across the top. Each uses an AppSmith **Stat Box widget**.

---

### 2.1 Pending Approvals

| Field | Value |
|---|---|
| **Widget** | Stat Box |
| **Label** | Pending Approvals |
| **Icon** | Clock / alert |
| **Colour rule** | Amber if > 0, green if 0 |

**Supabase query — `qry_pending_approvals`**
```sql
SELECT COUNT(*) AS count
FROM approvals
WHERE status = 'pending';
```
Bind `{{qry_pending_approvals.data[0].count}}` to the widget value.

---

### 2.2 Active Workers Today

| Field | Value |
|---|---|
| **Widget** | Stat Box |
| **Label** | Active Workers Today |
| **Icon** | Person / hard-hat |
| **Colour rule** | Static (neutral) |

**Supabase query — `qry_active_workers`**
```sql
SELECT COUNT(DISTINCT worker_id) AS count
FROM attendance
WHERE date = CURRENT_DATE
  AND status = 'present';
```
Bind `{{qry_active_workers.data[0].count}}`.

---

### 2.3 Low Stock Items

| Field | Value |
|---|---|
| **Widget** | Stat Box |
| **Label** | Low Stock Items |
| **Icon** | Box / warning |
| **Colour rule** | Red if > 0, green if 0 |

**Supabase query — `qry_low_stock_count`**
```sql
SELECT COUNT(*) AS count
FROM inventory
WHERE quantity_on_hand <= reorder_threshold;
```
Bind `{{qry_low_stock_count.data[0].count}}`.

---

### 2.4 Monthly Expenses Total

| Field | Value |
|---|---|
| **Widget** | Stat Box |
| **Label** | Expenses — {{current month}} |
| **Icon** | Currency / receipt |
| **Colour rule** | Static (neutral) |

**Supabase query — `qry_monthly_expenses`**
```sql
SELECT SUM(amount) AS total
FROM expenses
WHERE date_trunc('month', expense_date) = date_trunc('month', CURRENT_DATE);
```
Bind `{{qry_monthly_expenses.data[0].total}}`. Format as currency (set in widget's display format field).

---

## 3. Today's Site Activity Feed

Positioned left of the PO chart on desktop; full-width above it on mobile.

| Field | Value |
|---|---|
| **Widget** | List widget |
| **Height** | Fixed scroll — 400 px desktop, 300 px mobile |
| **Refresh** | Auto-refresh every 60 seconds |

**Supabase query — `qry_site_activity`**
```sql
SELECT
  a.created_at,
  a.event_type,
  a.description,
  w.full_name AS worker_name
FROM activity_log a
LEFT JOIN workers w ON w.id = a.worker_id
WHERE a.created_at::date = CURRENT_DATE
ORDER BY a.created_at DESC
LIMIT 50;
```

**List item template** (inside List widget):
- **Text widget (bold):** `{{currentItem.event_type}}`
- **Text widget:** `{{currentItem.description}}`
- **Text widget (muted, small):** `{{currentItem.worker_name}} · {{moment(currentItem.created_at).format('HH:mm')}}`

---

## 4. Purchase Order Status Breakdown Chart

Positioned right of the activity feed on desktop; full-width below it on mobile.

| Field | Value |
|---|---|
| **Widget** | Chart widget — Doughnut / Pie type |
| **Title** | Purchase Orders — This Month |
| **Legend** | Shown below chart |

**Supabase query — `qry_po_status`**
```sql
SELECT
  status,
  COUNT(*) AS count
FROM purchase_orders
WHERE date_trunc('month', created_at) = date_trunc('month', CURRENT_DATE)
GROUP BY status;
```

**Chart data binding:**
```js
// Chart widget → "Chart Data" property
qry_po_status.data.map(row => ({
  x: row.status,   // "Pending", "Approved", "Delivered", "Cancelled"
  y: row.count
}))
```

Colour segments: Pending = amber, Approved = blue, Delivered = green, Cancelled = red.

---

## 5. Stock Level Table

Full-width section below the feed + chart row.

| Field | Value |
|---|---|
| **Widget** | Table widget |
| **Title** | Current Stock Levels |
| **Row highlight** | Red background where `quantity_on_hand <= reorder_threshold` |
| **Searchable** | Yes — enable built-in Table search bar |
| **Sortable columns** | All columns enabled |
| **Page size** | 15 rows |

**Supabase query — `qry_stock_levels`**
```sql
SELECT
  i.sku,
  i.item_name,
  i.category,
  i.unit,
  i.quantity_on_hand,
  i.reorder_threshold,
  s.name AS supplier_name,
  i.last_updated
FROM inventory i
LEFT JOIN suppliers s ON s.id = i.supplier_id
ORDER BY
  (i.quantity_on_hand <= i.reorder_threshold) DESC,
  i.item_name ASC;
```

**Column configuration:**

| Column | Display Name | Type |
|---|---|---|
| `sku` | SKU | Text |
| `item_name` | Item | Text |
| `category` | Category | Text |
| `unit` | Unit | Text |
| `quantity_on_hand` | On Hand | Number |
| `reorder_threshold` | Reorder At | Number |
| `supplier_name` | Supplier | Text |
| `last_updated` | Last Updated | Date |

**Row colour expression** (Table widget → Row Colour property):
```js
currentRow.quantity_on_hand <= currentRow.reorder_threshold
  ? "#fde8e8"
  : "transparent"
```

---

## 6. Payroll Summary

Full-width section at the bottom of the dashboard.

| Field | Value |
|---|---|
| **Widget** | Table widget (read-only) |
| **Title** | Payroll — Current Period |
| **Sortable** | Yes |
| **Export** | Icon Button beside title → CSV download action |

**Supabase query — `qry_payroll_summary`**
```sql
SELECT
  w.full_name,
  w.role,
  p.regular_hours,
  p.overtime_hours,
  p.gross_pay,
  p.deductions,
  p.net_pay,
  p.payment_status
FROM payroll p
JOIN workers w ON w.id = p.worker_id
WHERE p.period_start <= CURRENT_DATE
  AND p.period_end >= CURRENT_DATE
ORDER BY w.full_name ASC;
```

**Column configuration:**

| Column | Display Name | Type |
|---|---|---|
| `full_name` | Worker | Text |
| `role` | Role | Text |
| `regular_hours` | Reg. Hours | Number |
| `overtime_hours` | OT Hours | Number |
| `gross_pay` | Gross | Currency |
| `deductions` | Deductions | Currency |
| `net_pay` | Net Pay | Currency |
| `payment_status` | Status | Text (badge) |

**Status badge colours** (Column → Cell Background):
```js
currentRow.payment_status === 'paid'
  ? "#dcfce7"
  : currentRow.payment_status === 'pending'
    ? "#fef9c3"
    : "#fee2e2"
```

---

## 7. Mobile Layout

AppSmith's responsive canvas handles stacking automatically when containers are set to fluid layout. Confirm these settings on each section container:

| Setting | Value |
|---|---|
| **Layout** | Fluid |
| **Min column width** | 320 px |
| **KPI card min-width** | 140 px (allows 2-up on small phones) |
| **Charts / Tables** | Full-width on wrap |

The activity feed and PO chart switch from side-by-side to stacked (feed on top, chart below) below 768 px. Use AppSmith's column span overrides per breakpoint in the widget's layout settings.

---

## 8. Supabase Table Dependencies

| Table | Used By |
|---|---|
| `approvals` | KPI: Pending Approvals |
| `attendance` | KPI: Active Workers Today |
| `inventory` | KPI: Low Stock Items, Stock Level Table |
| `expenses` | KPI: Monthly Expenses Total |
| `activity_log` | Site Activity Feed |
| `purchase_orders` | PO Status Chart |
| `payroll` | Payroll Summary |
| `workers` | Activity Feed, Payroll Summary |
| `suppliers` | Stock Level Table |

All queries run via the Supabase service role key stored in AppSmith's datasource configuration. Apply Row-Level Security policies per table if the app is multi-tenant.

---

## 9. Page Settings Checklist

- [ ] Page name: `Boss Dashboard`
- [ ] Set as **default page** (first after login)
- [ ] Connect all queries to the same Supabase datasource
- [ ] Set all queries to **Run on page load: Yes**
- [ ] Add a global **Refresh All** button (top-right corner) that triggers each query's `.run()` in sequence
- [ ] Enable auto-refresh on `qry_site_activity` (60 s interval via JS interval or AppSmith timer widget)
- [ ] Test mobile view using AppSmith Preview → Mobile mode before publishing
