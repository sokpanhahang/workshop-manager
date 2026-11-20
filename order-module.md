# Purchase Order & Approval Module
### System Specification — Carpentry Workshop
**Platform:** AppSmith (frontend) + Supabase (database + auth + edge functions)
**Version:** 1.0 | Last updated: November 2026

---

## Table of Contents
1. Overview
2. User Roles
3. Purchase Request Form Fields
4. Approval Workflow — 7 States
5. Role Responsibilities at Each Stage
6. Email Notifications via Gmail SMTP
7. Audit Trail
8. AppSmith Page-by-Page Build Instructions
9. Database Schema Reference

---

## 1. Overview

This module handles everything from the moment a workshop worker decides they need to buy something, to the moment that item arrives on-site. It replaces verbal requests and paper forms with a tracked, auditable digital workflow.

**Core flow in plain language:**
> Worker fills out a request → Purchasing Officer checks it → Boss approves or rejects → Purchasing Officer places the order → Someone marks it received.

Every step is logged. Every decision is recorded. Everyone involved gets an email.

---

## 2. User Roles

| Role | Who They Are | What They Can Do |
|------|-------------|-----------------|
| **Worker** | Any workshop staff member | Submit purchase requests, track their own orders |
| **Purchasing Officer** | Procurement team member | Review requests, forward to Boss, place orders, mark received |
| **Boss** | Workshop owner / manager | Approve or reject requests that come from Purchasing Review |
| **Admin** | System administrator | Full access — manage users, view all requests, override statuses |

---

## 3. Purchase Request Form Fields

These are the fields a Worker fills in when creating a new purchase request.

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| **Item Name** | Text (short) | What needs to be purchased. E.g. "Wood screws — M6 × 50mm" |
| **Quantity** | Number | How many units are needed |
| **Unit of Measure** | Dropdown | Options: pcs, kg, meters, liters, boxes, sets, rolls |
| **Estimated Unit Cost** | Currency (THB) | Rough cost per unit — doesn't need to be exact |
| **Total Estimated Cost** | Auto-calculated | Quantity × Estimated Unit Cost (read-only, computed) |
| **Urgency Level** | Dropdown | Low / Medium / High / Critical |
| **Work Site / Project** | Dropdown or Text | Which site or project this purchase is for |
| **Requested Delivery Date** | Date picker | When the item is needed by |

### Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| **Preferred Supplier** | Text | Supplier name or contact if the worker has one in mind |
| **Alternative Supplier** | Text | Backup option |
| **Notes / Justification** | Textarea | Why this is needed, any special requirements |
| **Attachment** | File upload | Photo, quote, spec sheet, or any supporting document (PDF, JPG, PNG — max 10MB) |

### Auto-filled Fields (not editable by Worker)

| Field | Value |
|-------|-------|
| **Requester Name** | Pulled from logged-in user profile |
| **Requester Email** | Pulled from logged-in user profile |
| **Request Date** | Today's date, set automatically |
| **Request ID** | Auto-generated: `PR-YYYY-NNNN` (e.g. PR-2026-0042) |
| **Status** | Set to `draft` on creation |

---

## 4. Approval Workflow — 7 States

The request moves through these states in order. Some paths branch based on decisions made.

```
┌─────────┐
│  DRAFT  │  Worker is filling in the form (not yet submitted)
└────┬────┘
     │ Worker clicks "Submit Request"
     ▼
┌───────────┐
│ SUBMITTED │  Request is in the queue, waiting for Purchasing Officer
└─────┬─────┘
      │ Purchasing Officer opens and reviews
      ▼
┌────────────────────┐
│ PURCHASING_REVIEW  │  Officer checks the request (validity, budget, supplier)
└──────────┬─────────┘
           │ Officer clicks "Forward to Boss"
           ▼
┌─────────────┐
│ BOSS_REVIEW │  Boss sees the request and decides
└──────┬──────┘
       ├──── Boss clicks "Approve" ────────────────┐
       │                                            ▼
       │                                      ┌──────────┐
       │                                      │ APPROVED │
       │                                      └────┬─────┘
       │                                           │ Purchasing Officer places the order
       │                                           ▼
       │                                      ┌─────────┐
       │                                      │ ORDERED │  PO placed with supplier
       │                                      └────┬────┘
       │                                           │ Item arrives, someone marks received
       │                                           ▼
       │                                      ┌──────────┐
       │                                      │ RECEIVED │  Workflow complete ✓
       │                                      └──────────┘
       │
       └──── Boss clicks "Reject" ─────────────────▶ ┌──────────┐
                                                      │ REJECTED │  Request closed
                                                      └──────────┘
```

**State summary table:**

| State | Meaning | Who Acts Next |
|-------|---------|---------------|
| `draft` | Being filled in, not submitted | Worker |
| `submitted` | Sent for review, waiting in queue | Purchasing Officer |
| `purchasing_review` | Officer is reviewing it | Purchasing Officer |
| `boss_review` | Forwarded to Boss for decision | Boss |
| `approved` | Boss approved — ready to order | Purchasing Officer |
| `rejected` | Boss rejected — no purchase | Nobody (closed) |
| `ordered` | Purchasing Officer placed the PO | Purchasing Officer (on delivery) |
| `received` | Item received on-site | Workflow complete |

---

## 5. Role Responsibilities at Each Stage

### Worker
- **Creates** the purchase request (fills form, saves as draft)
- **Submits** the request when ready (moves draft → submitted)
- **Can edit** the request only while it is in `draft` state
- **Tracks** their request status at any time on the Order Status Tracker page
- **Cannot** approve, reject, or place orders

### Purchasing Officer
- **Opens** submitted requests (moves submitted → purchasing_review automatically on open)
- **Reviews** each request:
  - Is the item description clear enough?
  - Is the estimated cost reasonable?
  - Is there a known supplier?
  - Is the requested date feasible?
- **Adds notes** if needed before forwarding
- **Forwards to Boss** (moves purchasing_review → boss_review)
- **Can reject** at this stage too (moves directly to rejected) if the request is clearly invalid
- **Places the order** once approved (moves approved → ordered), entering actual supplier, actual cost, PO number
- **Marks received** when items arrive (moves ordered → received), entering receipt date and delivery confirmation

### Boss
- **Reviews** requests forwarded by the Purchasing Officer
- **Sees** item, quantity, cost estimate, urgency, work site, and Officer's notes
- **Approves** (moves boss_review → approved) or **Rejects** (moves boss_review → rejected)
- **Must add a reason** when rejecting (shown to Worker and Officer)
- **Cannot** edit the request details — decision only

---

## 6. Email Notifications via Gmail SMTP

### What Triggers an Email

| Trigger | Who Gets Notified | Email Subject |
|---------|------------------|---------------|
| Worker submits a request | Purchasing Officer(s) | New Purchase Request: [Item Name] — [Request ID] |
| Officer forwards to Boss | Boss | Action Required: Approve Purchase — [Request ID] |
| Boss approves | Worker + Purchasing Officer | ✓ Approved: [Request ID] — [Item Name] |
| Boss rejects | Worker + Purchasing Officer | ✗ Rejected: [Request ID] — [Item Name] |
| Officer places the order | Worker | Your Request Is Being Ordered — [Request ID] |
| Officer marks received | Worker + Boss | Received: [Request ID] — [Item Name] |

### Email Content Structure

Each email follows this format:

```
Subject: [Trigger-specific subject from table above]

Hi [Recipient Name],

[One-sentence status update]

Request Details:
  • Request ID:     [PR-YYYY-NNNN]
  • Item:           [Item Name]
  • Quantity:       [Quantity] [Unit]
  • Est. Cost:      [Total Estimated Cost] THB
  • Work Site:      [Work Site]
  • Urgency:        [Urgency Level]
  • Submitted by:   [Worker Name]

[Role-specific message — e.g. "Please log in to review and forward to your manager."]

[Action button / link — e.g. "View Request → https://app.yourworkshop.com/review/[ID]"]

This is an automated message from the Workshop Purchase System.
```

### How to Configure Gmail SMTP in Supabase

**Step 1 — Prepare your Gmail account**
1. Use a dedicated Gmail account for the workshop system (e.g. `workshop-noreply@gmail.com`)
2. In that Gmail account, go to: Google Account → Security → 2-Step Verification → turn ON
3. After enabling 2FA, go to: Google Account → Security → App Passwords
4. Create a new App Password: select "Mail" and "Other (custom name)" → type "Supabase"
5. Copy the 16-character password that appears (you won't see it again)

**Step 2 — Configure SMTP in Supabase**
1. Go to your Supabase project → Settings → Authentication → SMTP Settings
2. Fill in:
   - **SMTP Host:** `smtp.gmail.com`
   - **SMTP Port:** `587`
   - **SMTP User:** your Gmail address (e.g. `workshop-noreply@gmail.com`)
   - **SMTP Password:** the 16-character App Password from Step 1
   - **Sender Name:** `Workshop Purchase System`
   - **Sender Email:** your Gmail address
3. Enable "Custom SMTP" toggle
4. Click Save

**Step 3 — Send emails from Edge Functions**
Emails triggered by status changes are sent using Supabase Edge Functions. Each function:
- Listens for a database event (e.g. status changes to `boss_review`)
- Looks up the relevant email addresses from the users table
- Builds the email body using a template
- Sends via the configured SMTP settings

Edge functions live under `supabase/functions/` and are deployed via the Supabase CLI. One function per trigger event is clearest (e.g. `notify-submitted`, `notify-boss-review`, `notify-approved`, etc.).

---

## 7. Audit Trail

Every status change is recorded in a separate `purchase_request_logs` table. This cannot be edited or deleted by any user role — it is append-only.

### What Gets Logged

Every time a request's status changes, a log entry is created containing:

| Field | Description |
|-------|-------------|
| `log_id` | Auto-generated unique ID |
| `request_id` | Which purchase request this log entry belongs to |
| `action` | What happened (e.g. "submitted", "forwarded_to_boss", "approved", "ordered") |
| `from_status` | The status before the change |
| `to_status` | The status after the change |
| `performed_by` | User ID of who made the change |
| `performed_by_name` | Display name at time of action (stored for readability) |
| `performed_by_role` | Role at time of action (Worker / Purchasing Officer / Boss) |
| `notes` | Any comment added at this step (e.g. rejection reason, supplier info) |
| `timestamp` | Exact date and time (UTC), stored automatically |

### How This Works in Practice

- When the Boss clicks "Reject" and types a reason, the system writes a log entry with `action = "rejected"`, `notes = "reason typed by boss"`, and `performed_by = boss user ID`.
- When the Purchasing Officer marks an item received, a log entry is written with the delivery confirmation info.
- The Worker can see a simplified timeline of their request on the Order Status Tracker page, pulling from these logs.
- The Admin can see the full log for any request at any time.

### Why This Matters

- **Disputes:** If someone questions a decision, the log shows who did what and when.
- **Accountability:** Every approval and rejection is tied to a named person.
- **Reporting:** Management can review all activity over a time period.

---

## 8. AppSmith Page-by-Page Build Instructions

AppSmith is a low-code tool where you build pages by dragging and connecting widgets to your Supabase database. Below are the four pages to build, what goes on each one, and how to connect them.

---

### Page 1: Purchase Request Form

**Who uses it:** Workers (and anyone creating a new request)

**What it does:** Displays the form for a new purchase request. Saves as draft first, then submits.

**Widgets to add:**

| Widget | Purpose |
|--------|---------|
| Text widget (heading) | "New Purchase Request" |
| Input (Text) | Item Name |
| Input (Number) | Quantity |
| Select (Dropdown) | Unit of Measure — options: pcs, kg, meters, liters, boxes, sets, rolls |
| Input (Currency) | Estimated Unit Cost (THB) |
| Text widget | Total Estimated Cost (auto-display: Quantity × Unit Cost) |
| Select (Dropdown) | Urgency Level — Low / Medium / High / Critical |
| Input (Text) or Select | Work Site / Project |
| Date Picker | Requested Delivery Date |
| Input (Text) | Preferred Supplier (optional) |
| Input (Text) | Alternative Supplier (optional) |
| Text Area | Notes / Justification (optional) |
| File Picker | Attachment — allow PDF, JPG, PNG |
| Button | "Save as Draft" |
| Button | "Submit Request" |

**Connections to Supabase:**

- "Save as Draft" button → runs an INSERT query to `purchase_requests` table with `status = 'draft'`
- "Submit Request" button → runs an UPDATE query to set `status = 'submitted'` and `submitted_at = now()`; also inserts a row into `purchase_request_logs`
- File attachment → uploaded to Supabase Storage bucket `purchase-attachments`, and the returned file URL is saved in the request record

**Access control:** Any logged-in user can reach this page. Workers only see their own drafts when they return to it.

---

### Page 2: Purchasing Review Page

**Who uses it:** Purchasing Officers only

**What it does:** Shows all requests in `submitted` or `purchasing_review` status. Lets the Officer review each one and either forward to the Boss or reject.

**Widgets to add:**

| Widget | Purpose |
|--------|---------|
| Table widget | List of pending requests — columns: Request ID, Item, Requester, Urgency, Estimated Cost, Date Submitted, Status |
| Table row click | Opens a detail panel (or navigates to a detail view) for the selected request |
| Detail panel — All form fields (read-only) | Show everything the Worker entered |
| Detail panel — Attachment preview | Link to open the uploaded file |
| Detail panel — Officer Notes (Text Area) | Officer can add notes before forwarding |
| Detail panel — Actual Supplier (Input) | Officer can fill in confirmed supplier |
| Button | "Forward to Boss" |
| Button | "Reject Request" (requires a rejection reason) |

**Connections to Supabase:**

- Table → SELECT from `purchase_requests` WHERE `status IN ('submitted', 'purchasing_review')` AND ordered by `submitted_at ASC` (oldest first)
- Opening a request → UPDATE `status = 'purchasing_review'` if it was `submitted`; insert log entry
- "Forward to Boss" button → UPDATE `status = 'boss_review'`; insert log entry with officer notes; trigger `notify-boss-review` edge function
- "Reject Request" button → shows a modal requiring a rejection reason → UPDATE `status = 'rejected'`; insert log entry; trigger `notify-rejected` edge function

**Access control:** This page is restricted to users with the `purchasing_officer` or `admin` role. Workers who navigate here see a "You do not have access" message.

---

### Page 3: Boss Approval Page

**Who uses it:** Boss (and Admin)

**What it does:** Shows all requests waiting for boss decision (`boss_review` status). Boss reads the full request and approves or rejects.

**Widgets to add:**

| Widget | Purpose |
|--------|---------|
| Table widget | List of requests in `boss_review` — columns: Request ID, Item, Requester, Urgency, Total Cost, Work Site, Date Forwarded |
| Detail view — Full request details (read-only) | Everything the Worker entered |
| Detail view — Officer Notes (read-only) | What the Purchasing Officer noted before forwarding |
| Detail view — Attachment link | View supporting documents |
| Detail view — Rejection Reason (Text Area) | Required if rejecting — hidden until Boss clicks Reject |
| Button | "Approve" (green) |
| Button | "Reject" (red) — reveals the rejection reason field first |

**Connections to Supabase:**

- Table → SELECT from `purchase_requests` WHERE `status = 'boss_review'` ordered by urgency DESC, then date ASC
- "Approve" button → UPDATE `status = 'approved'`; insert log entry; trigger `notify-approved` edge function
- "Reject" button → validates rejection reason is not empty → UPDATE `status = 'rejected'`, save rejection reason; insert log entry; trigger `notify-rejected` edge function

**Access control:** Restricted to users with the `boss` or `admin` role.

---

### Page 4: Order Status Tracker

**Who uses it:** All users — Workers track their own requests, Officers and Boss see everything

**What it does:** A single page where anyone can see the status of purchase requests. Workers see only their own. Officers and Boss see all.

**Widgets to add:**

| Widget | Purpose |
|--------|---------|
| Search / Filter bar | Filter by Request ID, Item Name, Status, Date Range, Urgency |
| Table widget | All relevant requests — columns: Request ID, Item, Quantity, Total Cost, Work Site, Status, Last Updated |
| Status badge (colored label) | Color-coded: draft (grey), submitted (blue), purchasing_review (yellow), boss_review (orange), approved (green), rejected (red), ordered (purple), received (teal) |
| Row click → Detail view — Full request details | Read-only view of all fields |
| Row click → Detail view — Activity Timeline | Vertical list of log entries from `purchase_request_logs` — shows who did what and when, in plain language |
| Row click → Detail view — Attachment link | View supporting documents |
| (Officers only — if status = approved) Actual Cost Input | Final cost when placing the order |
| (Officers only — if status = approved) PO Number Input | Purchase order reference number |
| (Officers only — if status = approved) Order Date Picker | When the order was placed |
| (Officers only — if status = approved) Button | "Mark as Ordered" |
| (Officers only — if status = ordered) Received Date Picker | When the items arrived |
| (Officers only — if status = ordered) Delivery Notes Textarea | Condition of delivery, any issues |
| (Officers only — if status = ordered) Button | "Mark as Received" |

**Connections to Supabase:**

- Table → SELECT from `purchase_requests`. If user role = `worker`, add WHERE `created_by = current_user_id`. Otherwise return all.
- Activity timeline → SELECT from `purchase_request_logs` WHERE `request_id = selected_id` ORDER BY `timestamp ASC`
- "Mark as Ordered" button → UPDATE `status = 'ordered'`, save actual cost, PO number, order date; insert log entry; trigger `notify-ordered` edge function
- "Mark as Received" button → UPDATE `status = 'received'`, save received date and notes; insert log entry; trigger `notify-received` edge function

---

## 9. Database Schema Reference

### Table: `purchase_requests`

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | Primary key, auto-generated |
| `request_code` | Text | PR-YYYY-NNNN format, generated by trigger |
| `created_by` | UUID | Foreign key → auth.users |
| `requester_name` | Text | Stored at time of submission |
| `requester_email` | Text | Stored at time of submission |
| `item_name` | Text | Required |
| `quantity` | Numeric | Required |
| `unit` | Text | Required |
| `estimated_unit_cost` | Numeric | Required |
| `total_estimated_cost` | Numeric | Computed column |
| `urgency` | Text | low / medium / high / critical |
| `work_site` | Text | Required |
| `requested_delivery_date` | Date | Required |
| `preferred_supplier` | Text | Optional |
| `alternative_supplier` | Text | Optional |
| `notes` | Text | Optional |
| `attachment_url` | Text | URL to file in Supabase Storage |
| `status` | Text | Current workflow state |
| `officer_notes` | Text | Added during purchasing_review |
| `actual_supplier` | Text | Filled when order is placed |
| `actual_cost` | Numeric | Filled when order is placed |
| `po_number` | Text | Filled when order is placed |
| `order_date` | Date | Filled when order is placed |
| `received_date` | Date | Filled when marked received |
| `delivery_notes` | Text | Filled when marked received |
| `rejection_reason` | Text | Filled when rejected |
| `created_at` | Timestamptz | Auto-set |
| `updated_at` | Timestamptz | Auto-updated |

### Table: `purchase_request_logs`

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | Primary key |
| `request_id` | UUID | Foreign key → purchase_requests.id |
| `action` | Text | Human-readable action name |
| `from_status` | Text | Status before change |
| `to_status` | Text | Status after change |
| `performed_by` | UUID | Foreign key → auth.users |
| `performed_by_name` | Text | Stored at time of action |
| `performed_by_role` | Text | Stored at time of action |
| `notes` | Text | Optional comment at this step |
| `timestamp` | Timestamptz | Auto-set, cannot be changed |

---

*End of specification. Build pages in the order listed: Request Form → Purchasing Review → Boss Approval → Status Tracker. Configure SMTP before testing any email notifications.*
