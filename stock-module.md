# Stock & Inventory Module Specification
### Carpentry Workshop — AppSmith + Supabase

---

## Overview

This module manages all stock and inventory operations for the carpentry workshop. It covers how materials are catalogued, requested by workers, issued by the Stock Manager, received from suppliers, and tracked over time. It is built on AppSmith (the front-end interface) connected to Supabase (the database).

---

## 1. Item Catalog

The Item Catalog is the master list of every material or supply the workshop uses.

### Fields per Item

| Field | Description |
|---|---|
| **Name** | Full descriptive name of the item (e.g., "Mahogany Timber 2x4", "Wood Glue") |
| **Category** | Grouping such as Timber, Hardware, Adhesives, Finishing, Safety, Consumables |
| **Unit** | How the item is measured: `pcs` (pieces), `kg` (kilograms), `m` (metres), `litre` |
| **Current Quantity** | The live quantity in stock, automatically updated with every in/out movement |
| **Reorder Level** | The minimum quantity at which a low-stock alert is triggered |
| **Storage Location** | Where the item is physically stored (e.g., "Rack A3", "Chemical Cabinet") |
| **Notes** | Any special handling instructions, supplier preferences, or remarks |

### Database Table: `items`

```
items
─────────────────────────────────────────────────────
id               UUID, primary key, auto-generated
name             Text, required, unique
category         Text, required
unit             Text, required (enum: pcs / kg / m / litre)
current_quantity Numeric, default 0
reorder_level    Numeric, required
storage_location Text
notes            Text
archived         Boolean, default false
created_at       Timestamp, auto
updated_at       Timestamp, auto
```

### Rules
- Current quantity is **never edited directly**. It changes only through stock-in and stock-out transactions.
- Only the Stock Manager can add, edit, or archive items.
- Archived items are hidden from request forms but retained in movement history.

---

## 2. Stock Request Workflow

Workers submit a request when they need materials for a job. The Stock Manager reviews, approves, and issues the items.

### Step-by-Step Flow

**Step 1 — Worker Submits Request**

The worker opens the Stock Request Form on their phone or tablet. They fill in:

- Item (selected from the active catalog)
- Quantity needed
- Purpose (what the material is for)
- Site / Project (which job or location it is going to)

They tap **Submit Request**. The request is saved with status `Pending`.

**Step 2 — Stock Manager Reviews**

The Stock Manager sees all pending requests on the Review page. For each request they can:

- **Approve & Issue** — confirms the quantity is available and issues the stock. The current quantity in the catalog is automatically reduced by the issued amount.
- **Partial Issue** — approves a smaller quantity than requested (enters the actual quantity to issue). The discrepancy is noted.
- **Reject** — declines the request with a mandatory reason.

**Step 3 — Automatic Deduction**

On approval, the system:
1. Inserts a record into `stock_movements` (type: `out`, quantity: negative).
2. A database trigger auto-subtracts the quantity from `current_quantity` in the `items` table.
3. Updates the request status to `Approved`, `Partial`, or `Rejected`.

### Database Table: `stock_requests`

```
stock_requests
─────────────────────────────────────────────────────
id                 UUID, primary key
item_id            UUID, foreign key → items.id
requested_by       UUID, foreign key → users.id
quantity_requested Numeric
quantity_issued    Numeric (filled on approval)
purpose            Text
site               Text
status             Text (Pending / Approved / Partial / Rejected)
reviewed_by        UUID, foreign key → users.id
reviewed_at        Timestamp
rejection_reason   Text
created_at         Timestamp, auto
```

### Rules
- A request cannot be approved if the quantity to issue exceeds `current_quantity`. The system shows a live warning.
- Workers can only view their own requests. The Stock Manager sees all.
- Approved requests cannot be edited. Errors are corrected via a stock adjustment.

---

## 3. Stock-In Process

This covers how the Stock Manager records materials received — whether from a formal purchase order or a direct delivery.

### Step-by-Step Flow

**Step 1 — Open Stock-In Form**

The Stock Manager navigates to the Stock Catalog page and clicks **Record Stock-In**.

**Step 2 — Fill in Details**

- Item (selected from catalog)
- Quantity received
- Source (supplier name or delivery note reference)
- Purchase Order number (optional)
- Date received (defaults to today, can be backdated)
- Notes (e.g., "partial delivery, remainder expected next week")

**Step 3 — Save**

On saving, the system:
1. Inserts a record into `stock_movements` (type: `in`, quantity: positive).
2. The database trigger auto-adds the quantity to `current_quantity` in the `items` table.

### Rules
- Only the Stock Manager can record stock-in.
- Zero or negative quantities are blocked by the form.
- The PO reference links this receipt to the Purchase Order module if used together.

---

## 4. Low-Stock Alert

The system automatically flags items that have fallen to or below their reorder level.

### How It Works

Whenever `current_quantity` is updated (after any stock-out or adjustment), the database checks whether `current_quantity <= reorder_level`. If true, the item is considered **low stock**.

### Where Alerts Appear

- **Dashboard panel** — a dedicated Low Stock Alert panel lists all flagged items with their current quantity, reorder level, and storage location.
- **Stock Catalog page** — flagged rows are highlighted in amber.
- **Stock Manager Review page** — when a low-stock item appears in a request, a warning is shown next to the current stock figure.

### Database View: `low_stock_items`

```sql
CREATE VIEW low_stock_items AS
SELECT
  id,
  name,
  category,
  unit,
  current_quantity,
  reorder_level,
  (reorder_level - current_quantity) AS shortfall,
  storage_location
FROM items
WHERE current_quantity <= reorder_level
  AND archived = false;
```

### Rules
- Alerts are real-time — they update the moment a stock movement is recorded.
- Alerts do not block operations. Workers can still submit requests; the manager sees the warning during review.
- The Stock Manager can mark an alert as "Noted" to suppress it temporarily until a restock is arranged.

---

## 5. Stock Movement History

Every change to stock — in, out, or manual adjustment — is logged permanently.

### What Is Logged

| Field | Description |
|---|---|
| **Item** | Which item was affected |
| **Movement Type** | `in` (received), `out` (issued), `adjustment` (manual correction) |
| **Quantity** | Amount moved — positive for in, negative for out or downward adjustment |
| **Reference** | Request ID for out movements; PO or supplier name for in; free-text reason for adjustments |
| **Performed By** | The user who recorded the movement |
| **Date & Time** | Exact timestamp |
| **Notes** | Any additional context |

### Database Table: `stock_movements`

```
stock_movements
─────────────────────────────────────────────────────
id               UUID, primary key
item_id          UUID, foreign key → items.id
movement_type    Text (in / out / adjustment)
quantity         Numeric (positive = in, negative = out)
reference        Text (request ID, PO number, or reason)
performed_by     UUID, foreign key → users.id
notes            Text
created_at       Timestamp, auto
```

### Rules
- No movement record can be edited or deleted once saved. This is the permanent audit trail.
- Adjustments require a mandatory reason and can only be made by the Stock Manager.
- The history page can be filtered by item, date range, movement type, and user.

---

## 6. AppSmith Page-by-Page Build Instructions

---

### Page 1 — Stock Catalog

**Purpose:** Master view of all inventory items. Primary tool for the Stock Manager.

**Layout:**
- Top bar: Search input + Category filter dropdown + "Add Item" button + "Record Stock-In" button
- Main area: Table of all active items — Name, Category, Unit, Current Qty, Reorder Level, Location, Status badge (Normal / Low Stock)
- Low-stock rows highlighted in amber
- Each row: Edit icon (opens item form modal), History icon (opens movement history filtered to that item)

**Widgets to place:**

| Widget | Type | Purpose |
|---|---|---|
| `Input_Search` | Text Input | Filters table by item name |
| `Select_Category` | Select | Filters table by category |
| `Table_Items` | Table | Lists all items |
| `Button_AddItem` | Button | Opens `Modal_ItemForm` |
| `Button_StockIn` | Button | Opens `Modal_StockIn` |
| `Modal_ItemForm` | Modal | Add / edit item fields |
| `Modal_StockIn` | Modal | Record stock-in form |

**Queries:**

- `getItems` — `SELECT * FROM items WHERE archived = false ORDER BY name`
- `createItem` — `INSERT INTO items (name, category, unit, reorder_level, storage_location, notes) VALUES (...)`
- `updateItem` — `UPDATE items SET name = ..., ... WHERE id = {{Table_Items.selectedRow.id}}`
- `archiveItem` — `UPDATE items SET archived = true WHERE id = {{Table_Items.selectedRow.id}}`
- `recordStockIn` — `INSERT INTO stock_movements (item_id, movement_type, quantity, reference, performed_by, notes) VALUES (...)`

---

### Page 2 — Stock Request Form (Mobile-Friendly)

**Purpose:** Workers submit material requests from their phone or tablet on-site.

**Layout — single column, top to bottom:**

1. **Item** — Dropdown (active items only, shows name + unit)
2. **Unit** — Read-only text, auto-filled from selected item
3. **Quantity Needed** — Number input (minimum 0.01)
4. **Purpose** — Text input ("What is this material for?")
5. **Site / Project** — Dropdown of active sites, or free-text fallback
6. **Submit** — Full-width button, prominent colour
7. **My Recent Requests** — Compact list below the form: last 10 requests with item name, qty, date, status badge

**Widgets:**

| Widget | Type | Purpose |
|---|---|---|
| `Select_Item` | Select | Picks item from active catalog |
| `Text_Unit` | Text | Shows unit of selected item |
| `Input_Quantity` | Number Input | Quantity the worker needs |
| `Input_Purpose` | Text Input | Reason / task description |
| `Select_Site` | Select | Active site list |
| `Button_Submit` | Button | Submits the request, resets form |
| `List_MyRequests` | List | Worker's recent requests |

**Queries:**

- `getActiveItems` — `SELECT id, name, unit FROM items WHERE archived = false ORDER BY name`
- `submitRequest` — `INSERT INTO stock_requests (item_id, requested_by, quantity_requested, purpose, site, status, created_at) VALUES (..., 'Pending', NOW())`
- `getMyRequests` — `SELECT sr.*, i.name AS item_name FROM stock_requests sr JOIN items i ON sr.item_id = i.id WHERE sr.requested_by = '{{appsmith.user.email}}' ORDER BY created_at DESC LIMIT 10`

**Mobile design tips:**
- Set page max-width to 480px
- Use minimum 15px font size throughout
- Keep all inputs full-width, no side-by-side fields
- Use a large, high-contrast Submit button (at least 48px tall)

---

### Page 3 — Stock Manager Review Page

**Purpose:** The Stock Manager reviews pending requests and approves, partially issues, or rejects them.

**Layout:**
- Top: Filter tabs — All / Pending / Approved / Partial / Rejected — plus a date range picker
- Main table: Date Submitted, Worker, Item, Qty Requested, Purpose, Site, Status badge
- Clicking any row opens a **Review Panel** (slide-out drawer or modal) with:
  - Item name + current stock level (live, in bold) + reorder level
  - Quantity requested
  - Quantity to Issue — editable number field (defaults to requested quantity)
  - Approve & Issue button (green)
  - Reject button (red) — clicking prompts for a rejection reason before confirming

**Widgets:**

| Widget | Type | Purpose |
|---|---|---|
| `Tabs_Status` | Tab | Filter by request status |
| `DatePicker_From / To` | Date Picker | Filter by submission date |
| `Table_Requests` | Table | All requests matching filters |
| `Text_CurrentStock` | Text | Live stock level for selected item |
| `Input_IssuedQty` | Number Input | Quantity the manager will issue |
| `Button_Approve` | Button | Approves and deducts stock |
| `Button_Reject` | Button | Rejects with reason |
| `Input_RejectReason` | Text Input | Appears only when rejecting |

**Queries:**

- `getRequests` — joins `stock_requests`, `items`, `users`; filtered by status and date
- `getLiveStock` — `SELECT current_quantity FROM items WHERE id = '{{Table_Requests.selectedRow.item_id}}'`
- `approveRequest` — updates `stock_requests` (status, quantity_issued, reviewed_by, reviewed_at); inserts into `stock_movements` (type: `out`, negative quantity)
- `rejectRequest` — updates `stock_requests` (status: `Rejected`, rejection_reason, reviewed_by, reviewed_at)

**Validation rules (enforced in AppSmith before the query runs):**
- If `Input_IssuedQty.value > Text_CurrentStock.text`: show inline red warning "Insufficient stock — available: X". Disable Approve button.
- If `Input_IssuedQty.value <= 0`: disable Approve button.
- Rejection reason must not be empty before the reject query fires.

---

### Page 4 — Stock Movement History

**Purpose:** Complete audit log of every stock movement. Read-only except for the Stock Manager's adjustment function.

**Layout:**
- Top: Filters — Item (dropdown), Movement Type (All / In / Out / Adjustment), Date From, Date To, Performed By (user dropdown)
- Top right: Export to CSV button
- Main table: Date/Time, Item, Type badge, Quantity (colour-coded: green for in, red for out), Reference, Performed By, Notes
- Bottom (Stock Manager only): "Record Adjustment" button

**Widgets:**

| Widget | Type | Purpose |
|---|---|---|
| `Select_FilterItem` | Select | Filter by item |
| `Select_FilterType` | Select | Filter by movement type |
| `DatePicker_From / To` | Date Picker | Date range filter |
| `Select_FilterUser` | Select | Filter by who made the movement |
| `Button_Export` | Button | Downloads table as CSV |
| `Table_History` | Table | Movement log |
| `Button_Adjust` | Button | Opens adjustment modal (manager only) |
| `Modal_Adjustment` | Modal | Fields: Item, Quantity (±), Reason |

**Queries:**

- `getMovements` — `SELECT sm.created_at, i.name, sm.movement_type, sm.quantity, sm.reference, u.name AS user_name, sm.notes FROM stock_movements sm JOIN items i ON sm.item_id = i.id JOIN auth.users u ON sm.performed_by = u.id WHERE [filters] ORDER BY sm.created_at DESC`
- `recordAdjustment` — `INSERT INTO stock_movements (item_id, movement_type, quantity, reference, performed_by, notes, created_at) VALUES (..., 'adjustment', ..., NOW())`

**Rules:**
- Workers see only movements related to their own requests. Apply AppSmith page-level access control to hide this page or restrict the query using `appsmith.user`.
- The adjustment form requires a reason before saving. Positive quantity = stock added; negative = stock removed.

---

### Page 5 — Dashboard (Boss / Stock Manager View)

**Purpose:** At-a-glance overview for the Stock Manager and Boss, showing what needs attention right now.

**Layout:**

**Row 1 — Summary Cards (4 KPI stats):**
- Total Active Items
- Items Low on Stock (count, links to low-stock table)
- Pending Requests (count, links to Review page)
- Stock-In Movements This Week (count)

**Row 2 — Low Stock Alert Panel:**
- Table: Name, Category, Current Qty, Reorder Level, Shortfall, Location
- Each row: quick "Record Stock-In" button
- Empty state message if no items are low

**Row 3 — Recent Pending Requests:**
- Compact list of the 5 most recent pending requests: Worker, Item, Qty, Site, Time Submitted
- "Go to Review" button linking to Page 3

**Widgets:**

| Widget | Type | Purpose |
|---|---|---|
| `Stat_TotalItems` | Stat Box | Count of active items |
| `Stat_LowStock` | Stat Box | Count of low-stock items |
| `Stat_PendingRequests` | Stat Box | Count of pending requests |
| `Stat_StockInThisWeek` | Stat Box | Stock-in entries this week |
| `Table_LowStock` | Table | Flagged items from `low_stock_items` view |
| `List_PendingRequests` | List | Recent pending requests |
| `Button_GoToReview` | Button | Navigates to Page 3 |

**Queries:**

- `getLowStockItems` — `SELECT * FROM low_stock_items ORDER BY shortfall DESC`
- `getRecentPending` — `SELECT sr.*, i.name FROM stock_requests sr JOIN items i ON sr.item_id = i.id WHERE sr.status = 'Pending' ORDER BY sr.created_at DESC LIMIT 5`
- `getSummaryStats` — four separate count queries run in parallel on page load

---

## 7. User Roles & Access Summary

| Feature | Worker | Stock Manager |
|---|---|---|
| View Item Catalog | Read-only | Full access |
| Add / Edit / Archive Items | No | Yes |
| Submit Stock Request | Yes | Yes |
| Approve / Reject Requests | No | Yes |
| Record Stock-In | No | Yes |
| Record Stock Adjustments | No | Yes |
| View Movement History | Own activity only | All activity |
| View Low-Stock Alerts | No | Yes |
| Export History to CSV | No | Yes |
| Access Dashboard | No | Yes |

---

## 8. Supabase Setup Checklist

- [ ] Create table: `items`
- [ ] Create table: `stock_requests`
- [ ] Create table: `stock_movements`
- [ ] Create view: `low_stock_items`
- [ ] Enable Row Level Security (RLS) on all three tables
- [ ] RLS policy: workers can INSERT into `stock_requests` and SELECT their own rows only
- [ ] RLS policy: Stock Manager has full SELECT, INSERT, UPDATE on all tables
- [ ] RLS policy: `stock_movements` — no one can UPDATE or DELETE (append-only)
- [ ] Link `performed_by` and `requested_by` columns to `auth.users.id`
- [ ] Add database trigger to auto-update `current_quantity` on `stock_movements` insert

---

## 9. Database Trigger — Auto-Update Quantity

Use a Supabase trigger so AppSmith only needs to insert a movement record. The quantity update happens automatically and cannot be bypassed.

```sql
CREATE OR REPLACE FUNCTION update_item_quantity()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE items
  SET
    current_quantity = current_quantity + NEW.quantity,
    updated_at = NOW()
  WHERE id = NEW.item_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_stock_movement
AFTER INSERT ON stock_movements
FOR EACH ROW
EXECUTE FUNCTION update_item_quantity();
```

**Convention:**
- Stock-in entries: **positive** quantity (e.g., `+50`)
- Stock-out entries: **negative** quantity (e.g., `-10`)
- Adjustments: positive or negative depending on direction

This means every quantity change — regardless of source — flows through `stock_movements`, giving you a complete and tamper-proof audit trail.

---

*End of Specification*
