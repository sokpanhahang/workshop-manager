# Daily Work Report Module
### AppSmith + Supabase — Carpentry Workshop

---

## Overview

This module handles daily work reporting for site workers and gives the workshop boss a live view of what every team is doing, every day. Workers fill in a short form from their phone on-site. The boss sees all reports the moment they are submitted.

---

## Part 1 — Database Design (Supabase)

### Table: `daily_reports`

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | Auto-generated primary key |
| `worker_id` | uuid | Foreign key → `workers` table |
| `site_id` | uuid | Foreign key → `sites` table |
| `report_date` | date | The date work was done |
| `start_time` | time | When the worker started on site |
| `end_time` | time | When the worker finished |
| `hours_worked` | numeric | Auto-calculated: end_time − start_time |
| `tasks_completed` | text | Free-text description of work done |
| `materials_used` | text | List of materials consumed |
| `issues_encountered` | text | Any problems, delays, or safety concerns |
| `next_steps` | text | What is planned for the next visit |
| `photo_url` | text | Optional — URL to uploaded site photo |
| `submitted_at` | timestamp | Exact moment report was submitted |
| `updated_at` | timestamp | Last edit timestamp |
| `is_final` | boolean | Locked after midnight; default false |

### Table: `workers`

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key |
| `full_name` | text | Worker's full name |
| `phone` | text | Contact number |
| `role` | text | e.g. Carpenter, Apprentice, Supervisor |

### Table: `sites`

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key |
| `site_name` | text | Display name for dropdown |
| `address` | text | Site address |
| `is_active` | boolean | Only active sites appear in the dropdown |

### Submission Rule (enforced in Supabase)

Add a **unique constraint** on `(worker_id, site_id, report_date)` so the database rejects any duplicate submission. This is the last line of defence — the app-level logic should catch it first with a friendly message.

---

## Part 2 — Worker Report Form

**Who uses it:** Every site worker, on their phone, once per working day per site.

### Fields (in order on the form)

1. **Site Name** — Dropdown list of active sites. Required. Pulls from the `sites` table.
2. **Report Date** — Defaults to today's date automatically. Worker can adjust if submitting late (same day only). Required.
3. **Start Time** — Time picker. Required.
4. **End Time** — Time picker. Required. Must be later than start time.
5. **Hours Worked** — Read-only display. Calculates automatically as soon as start and end times are entered. Formula: `end_time − start_time`, shown as decimal hours (e.g. 7.5 hours).
6. **Tasks Completed** — Large text area. Prompt text: *"What did you get done today? Be specific — e.g. fitted door frames in units 3 and 4, sanded and stained kitchen cabinets."* Required.
7. **Materials Used** — Large text area. Prompt text: *"List materials used — e.g. 20 × 90mm screws, 3 sheets 18mm plywood, 1L timber stain."* Optional but encouraged.
8. **Issues or Problems** — Large text area. Prompt text: *"Any problems, delays, or safety concerns? Leave blank if none."* Optional.
9. **Next Steps Planned** — Large text area. Prompt text: *"What needs to happen on your next visit to this site?"* Optional.
10. **Site Photo** — File upload widget. Accepts JPG/PNG only. Max 5 MB. Optional. Uploaded to Supabase Storage; URL saved to `photo_url`.

### Submission Behaviour

- On **Submit**, the app first checks whether a report already exists for this worker + site + date.
  - If yes: show a message — *"You already have a report for this site today. Scroll down to edit it."*
  - If no: insert new row.
- After midnight, the `is_final` flag is set to `true` and the report becomes read-only. No further edits allowed.
- Workers see a green confirmation banner after successful submission: *"Report submitted. Thank you."*

---

## Part 3 — Boss Live Dashboard

**Who uses it:** The workshop boss or manager, on a desktop browser.

### Today's Feed

- Shows every report submitted today, across all sites, in reverse chronological order (most recent first).
- Each row displays: Worker Name, Site, Hours Worked, Submitted At, and a **View** button to open the full report.
- Refreshes automatically every 60 seconds (or manually with a Refresh button).

### Filters

Three filter controls at the top of the page:

| Filter | Type |
|---|---|
| Worker | Dropdown — all active workers |
| Site | Dropdown — all active sites |
| Date | Date picker — defaults to today |

Filters combine (AND logic). Clearing all filters shows the full day's reports.

### Who Has NOT Submitted Today (Attendance Tracker)

Below the reports feed, a separate panel titled **"Missing Reports"** lists every active worker who has not submitted any report today. This is not punitive — it helps the boss spot absences, illness, or connectivity problems early.

Logic: Pull all active workers → cross-reference with today's submitted `worker_id` values → show the difference.

Each missing entry shows the worker's name and their usual sites (from recent history), so the boss knows who to call.

---

## Part 4 — Worker's Own History

**Who uses it:** Each worker, on their phone or desktop.

- Shows the worker's own submitted reports from the **last 30 days**.
- Sorted by date, most recent first.
- Each row: Date, Site, Hours Worked, a summary of tasks (first 100 characters), and a **View** button.
- Workers can open any report and read the full detail.
- If a report is not yet final (before midnight), there is an **Edit** button on the detail view.
- Workers cannot see other workers' reports.

---

## Part 5 — Weekly Hours Summary (Payroll View)

**Who uses it:** The boss, once a week.

- Shows a table with one row per worker.
- Columns: Worker Name, Mon, Tue, Wed, Thu, Fri, Sat, Sun, **Total Hours**.
- Date range selector defaults to the current working week (Monday to Sunday).
- Hours are summed from `hours_worked` in the `daily_reports` table.
- A **Download CSV** button exports the table for the payroll system.
- Blank cells mean no report submitted for that day — boss can distinguish zero hours from no submission.

---

## Part 6 — AppSmith Build Instructions

### General Setup Notes

- Create a new AppSmith application called **Workshop Daily Reports**.
- Connect it to your Supabase project using the **PostgreSQL datasource** (use the Supabase connection string from your project's Settings → Database).
- Create four pages (described below). Set the default landing page based on the user's role (worker vs boss) using AppSmith's user/role variables.

---

### Page 1 — Worker Report Form (Mobile-First)

**Goal:** A clean, fast form a worker can complete in under two minutes while standing on-site.

#### AppSmith Setup

1. Set the page canvas width to **Mobile** (375px) in AppSmith's canvas settings.
2. Use a **single-column layout** throughout. No side-by-side fields.

#### Widgets to Add (top to bottom)

| Widget | Type | Settings |
|---|---|---|
| Page title | Text | "Daily Work Report" — large, bold |
| Site Name | Select widget | Query datasource: `SELECT id, site_name FROM sites WHERE is_active = true ORDER BY site_name` |
| Report Date | Date Picker | Default: `{{moment().format("YYYY-MM-DD")}}` |
| Start Time | Time Picker | 15-minute intervals |
| End Time | Time Picker | 15-minute intervals |
| Hours Worked | Text (read-only) | Value: `{{(TimePicker_EndTime.selectedTime - TimePicker_StartTime.selectedTime) / 3600000}}` formatted to 1 decimal |
| Tasks Completed | Text Area | Min height: 120px. Placeholder text as described in Part 2. |
| Materials Used | Text Area | Min height: 100px |
| Issues or Problems | Text Area | Min height: 100px |
| Next Steps | Text Area | Min height: 100px |
| Site Photo | File Picker | Allowed types: image/jpeg, image/png. Max size: 5 MB |
| Submit Button | Button | Full width. Label: "Submit Report". Primary colour. Large touch target (min 48px height). |

#### Touch-Friendly Settings

- Set all input widgets to **min height 48px**.
- Set font size to at least **16px** everywhere (prevents iOS from zooming in on tap).
- Add **8px spacing** between each widget for comfortable thumb navigation.
- The Submit button should be **full width** and at least **56px tall**.

#### Submit Button Logic (JS function in onClick)

```javascript
// 1. Check for duplicate
const existing = await checkDuplicate.run();
if (existing.length > 0) {
  showAlert("You already have a report for this site today.", "warning");
  return;
}

// 2. Upload photo if provided
let photoUrl = null;
if (FilePicker_Photo.files.length > 0) {
  const upload = await uploadPhoto.run();
  photoUrl = upload.url;
}

// 3. Insert report
await insertReport.run();
showAlert("Report submitted. Thank you.", "success");
navigateTo("WorkerHistory");
```

#### Queries to Create

- **`checkDuplicate`** — `SELECT id FROM daily_reports WHERE worker_id = '{{appsmith.user.id}}' AND site_id = '{{Select_Site.selectedOptionValue}}' AND report_date = '{{DatePicker_ReportDate.selectedDate}}'`
- **`insertReport`** — `INSERT INTO daily_reports (worker_id, site_id, report_date, start_time, end_time, hours_worked, tasks_completed, materials_used, issues_encountered, next_steps, photo_url, submitted_at) VALUES (...)` — map each widget value.

---

### Page 2 — Boss Live Feed (Desktop-Optimised)

**Goal:** A fast, scannable overview of everything submitted today, with quick access to full reports.

#### AppSmith Setup

1. Set canvas to **Desktop** (1280px).
2. Use a two-panel layout: **filters bar across the top**, **reports table below left**, **missing reports panel below right**.

#### Widgets to Add

| Widget | Type | Purpose |
|---|---|---|
| Page title | Text | "Today's Site Reports — [date]" |
| Worker filter | Select | All active workers + "All Workers" option |
| Site filter | Select | All active sites + "All Sites" option |
| Date filter | Date Picker | Defaults to today |
| Refresh button | Button | Re-runs the main query on click |
| Reports table | Table widget | Columns: Worker, Site, Hours, Submitted At, (View button column) |
| Missing Reports panel | List widget | Shows workers without a report today |

#### Auto-Refresh

In the **Reports Table** widget settings, enable **Server-side pagination** off, and in the page's **onLoad** event, run the main query. Add a JS interval for refresh:

```javascript
// In page onLoad (Custom JS)
setInterval(() => { fetchTodaysReports.run(); }, 60000);
```

#### Main Query: `fetchTodaysReports`

```sql
SELECT
  w.full_name AS worker_name,
  s.site_name,
  r.hours_worked,
  r.submitted_at,
  r.id
FROM daily_reports r
JOIN workers w ON r.worker_id = w.id
JOIN sites s ON r.site_id = s.id
WHERE r.report_date = {{DatePicker_Filter.selectedDate}}
  AND ({{Select_Worker.selectedOptionValue}} = 'all' OR r.worker_id = {{Select_Worker.selectedOptionValue}})
  AND ({{Select_Site.selectedOptionValue}} = 'all' OR r.site_id = {{Select_Site.selectedOptionValue}})
ORDER BY r.submitted_at DESC
```

#### Missing Reports Query: `fetchMissingWorkers`

```sql
SELECT w.full_name
FROM workers w
WHERE w.is_active = true
  AND w.id NOT IN (
    SELECT worker_id FROM daily_reports
    WHERE report_date = {{DatePicker_Filter.selectedDate}}
  )
ORDER BY w.full_name
```

#### View Full Report Modal

When the boss clicks **View** on a table row, open a Modal widget showing all fields of that report in read-only Text widgets.

---

### Page 3 — Worker History

**Goal:** Let each worker review their own past 30 days at a glance.

#### AppSmith Setup

1. Mobile canvas (375px) — workers primarily use phones.
2. Use a **List widget** (not a table) for a card-based, touch-friendly layout.

#### Widgets to Add

| Widget | Type | Purpose |
|---|---|---|
| Page title | Text | "My Reports" |
| Reports list | List widget | One card per report: Date, Site, Hours, task preview |
| View/Edit button | Button (inside list) | Opens detail view or edit form |

#### Query: `fetchMyReports`

```sql
SELECT r.id, r.report_date, s.site_name, r.hours_worked,
       LEFT(r.tasks_completed, 100) AS task_preview, r.is_final
FROM daily_reports r
JOIN sites s ON r.site_id = s.id
WHERE r.worker_id = '{{appsmith.user.id}}'
  AND r.report_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY r.report_date DESC
```

#### Edit Logic

- If `is_final = false`, show an **Edit** button that navigates to the Worker Report Form page with the report `id` as a query parameter. Pre-populate all fields from the existing record.
- If `is_final = true`, show a **View** button only. No editing allowed.

---

### Page 4 — Weekly Hours Summary

**Goal:** Give the boss a weekly hours table, ready for payroll.

#### AppSmith Setup

1. Desktop canvas (1280px).
2. Use a **Table widget** with one row per worker.

#### Widgets to Add

| Widget | Type | Purpose |
|---|---|---|
| Page title | Text | "Weekly Hours Summary" |
| Week selector | Date Picker | Picks any date in the target week; query derives Monday–Sunday range |
| Hours table | Table widget | Worker name + hours per day + total |
| Download CSV button | Button | Uses AppSmith's built-in table export or a custom JS download |

#### Query: `fetchWeeklyHours`

```sql
SELECT
  w.full_name,
  SUM(CASE WHEN EXTRACT(DOW FROM r.report_date) = 1 THEN r.hours_worked ELSE 0 END) AS mon,
  SUM(CASE WHEN EXTRACT(DOW FROM r.report_date) = 2 THEN r.hours_worked ELSE 0 END) AS tue,
  SUM(CASE WHEN EXTRACT(DOW FROM r.report_date) = 3 THEN r.hours_worked ELSE 0 END) AS wed,
  SUM(CASE WHEN EXTRACT(DOW FROM r.report_date) = 4 THEN r.hours_worked ELSE 0 END) AS thu,
  SUM(CASE WHEN EXTRACT(DOW FROM r.report_date) = 5 THEN r.hours_worked ELSE 0 END) AS fri,
  SUM(CASE WHEN EXTRACT(DOW FROM r.report_date) = 6 THEN r.hours_worked ELSE 0 END) AS sat,
  SUM(CASE WHEN EXTRACT(DOW FROM r.report_date) = 0 THEN r.hours_worked ELSE 0 END) AS sun,
  SUM(r.hours_worked) AS total_hours
FROM workers w
LEFT JOIN daily_reports r
  ON r.worker_id = w.id
  AND r.report_date BETWEEN date_trunc('week', {{DatePicker_Week.selectedDate}}::date)
                         AND date_trunc('week', {{DatePicker_Week.selectedDate}}::date) + INTERVAL '6 days'
WHERE w.is_active = true
GROUP BY w.full_name
ORDER BY w.full_name
```

#### CSV Export

Add a **Download** button with this onClick JS:

```javascript
download(WeeklyTable.tableData, "weekly_hours.csv", "text/csv");
```

---

## Part 7 — Mobile-Friendliness Checklist

Before going live, verify every item on this list:

- [ ] All tap targets (buttons, dropdowns, inputs) are at least **48 × 48px**
- [ ] Font size is **16px minimum** on all input fields
- [ ] No horizontal scrolling on 375px screen width
- [ ] The Submit button is **full width** and visually prominent
- [ ] The form loads in under **3 seconds** on a standard mobile connection
- [ ] Error messages appear **above the submit button**, not hidden below the fold
- [ ] The photo upload accepts the camera roll on iOS and Android
- [ ] Date and time pickers use **native mobile controls** where possible (AppSmith Time Picker auto-adapts)
- [ ] After submission, the worker is returned to a confirmation screen, not a blank page
- [ ] The app works on **Chrome Mobile, Safari iOS, and Samsung Internet**

---

## Part 8 — Security & Access Control

| Role | Pages Accessible | Data Visible |
|---|---|---|
| Worker | Report Form, Worker History | Own reports only |
| Boss / Manager | Live Feed, Weekly Summary, all Worker History | All reports, all workers |

Implement using AppSmith's built-in **role-based access control** or by passing `appsmith.user.email` / `appsmith.user.groups` into Supabase Row Level Security (RLS) policies.

Recommended Supabase RLS rules:
- Workers can `SELECT`, `INSERT`, `UPDATE` only rows where `worker_id = auth.uid()` and `is_final = false`.
- Managers can `SELECT` all rows.
- Nobody can `DELETE` rows (audit trail).

---

## Summary

| Component | Technology | Location |
|---|---|---|
| Database | Supabase (PostgreSQL) | Tables: daily_reports, workers, sites |
| File Storage | Supabase Storage | Bucket: site-photos |
| Front-end | AppSmith | 4 pages as described |
| Auth | AppSmith + Supabase Auth | Role-based: worker / boss |
| Mobile optimisation | AppSmith canvas settings | Mobile canvas on worker pages |

This module is self-contained and can be built independently of other workshop management features. Once the four AppSmith pages are live and connected to Supabase, workers can begin submitting reports immediately.
