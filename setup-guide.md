# Carpentry Workshop Management System
## Complete Setup Guide

**Version 1.0 — November 2026**
*Written for someone with no coding experience. Follow each step in order.*

---

## Before You Begin

This guide will walk you through setting up your complete workshop management system from scratch. By the end, you will have:

- A live database on Supabase storing all your workshop data
- A working web and mobile app on AppSmith for your team to use
- Five modules ready to go: Purchase Orders, Stock Management, Daily Reports, Accounting, and the Boss Dashboard

**What you need before starting:**

- A computer with a web browser (Chrome or Firefox recommended)
- An email address (used to create your accounts)
- A Gmail account for sending system email notifications
- About 2–3 hours of focused setup time
- The `schema.sql` file (included in your system files)

**The five module spec files** (you will refer to these in Section 5):
- `order-module.md` — Purchase Order & Approval Module
- `stock-module.md` — Stock & Inventory Module
- `daily-report-module.md` — Daily Work Report Module
- `accounting-module.md` — Accounting Module
- `dashboard-spec.md` — Boss Dashboard

---

> **TIP — Save as you go:** After completing each section, write down any passwords or keys in a secure place (a password manager, or a printed note kept safely). You will need them again later.

---

## Table of Contents

1. [Create Your Supabase Project & Set Up the Database](#section-1)
2. [Configure Gmail for Email Notifications](#section-2)
3. [Create Your AppSmith Account & New App](#section-3)
4. [Connect AppSmith to Supabase](#section-4)
5. [Build Each Module Page](#section-5)
6. [Invite Users & Assign Roles](#section-6)
7. [Worker Mobile Setup — Add to Home Screen](#section-7)

---

<a name="section-1"></a>
## Section 1: Create Your Supabase Project & Set Up the Database

Supabase is the system that stores all your workshop data — purchase requests, stock levels, work reports, payroll records, and more. Think of it as your database, hosted securely in the cloud.

### Step 1 — Create a Supabase Account

1. Open your browser and go to **https://supabase.com**
2. Click the **Start your project** button
3. Click **Sign up** and create an account using your email address
4. Check your email for a confirmation link and click it to verify your account
5. Once verified, you will be taken to your Supabase dashboard

### Step 2 — Create a New Project

1. On your Supabase dashboard, click **New project**
2. If asked, create or select an **Organisation** — you can name it after your workshop
3. Fill in the project details:
   - **Name:** `carpentry-workshop` (or your preferred name)
   - **Database Password:** Choose a strong password and write it down — you will need it
   - **Region:** Choose the region closest to your location (e.g. Southeast Asia, Europe, US)
4. Click **Create new project**
5. Wait for the project to finish setting up — this takes about 1–2 minutes. You will see a progress bar.

> **TIP:** The database password you set here is different from your Supabase account password. Keep both safe.

### Step 3 — Run the Database Schema

The `schema.sql` file creates all the tables and rules your system needs. This is a one-time step.

1. In your Supabase project, look at the left-hand menu and click **SQL Editor**
2. You will see a text area where you can type or paste SQL commands
3. Open the `schema.sql` file on your computer:
   - Right-click on `schema.sql` → Open with Notepad (Windows) or TextEdit (Mac)
   - Select all the text inside (`Ctrl+A` on Windows, `Cmd+A` on Mac)
   - Copy it (`Ctrl+C` / `Cmd+C`)
4. Click inside the SQL Editor text area in Supabase and paste the text (`Ctrl+V` / `Cmd+V`)
5. Click the green **Run** button (or press `Ctrl+Enter` / `Cmd+Enter`)
6. Wait a few seconds. You should see a message at the bottom: **"Success. No rows returned"** — this is correct.

> **WARNING:** If you see a red error message, check that you copied the entire contents of `schema.sql` and that there is no extra text at the top or bottom. Do not run it twice — contact your developer if you see errors.

### Step 4 — Confirm the Tables Were Created

1. In the left-hand menu, click **Table Editor**
2. You should now see a list of tables on the left side, including:
   - `purchase_requests`
   - `items`
   - `stock_requests`
   - `stock_movements`
   - `daily_reports`
   - `workers`
   - `sites`
   - `supplier_invoices`
   - `expenses`
   - `payroll`
   - And several others

If you can see these tables, your database is set up correctly. Move on to Section 2.

### Step 5 — Create a Storage Bucket for File Uploads

Your system allows users to upload files (invoice PDFs, site photos, purchase request attachments). These are stored in Supabase Storage.

1. In the left-hand menu, click **Storage**
2. Click **New bucket**
3. Create these three buckets, one at a time:
   - **Name:** `purchase-attachments` | Visibility: **Private**
   - **Name:** `invoice-attachments` | Visibility: **Private**
   - **Name:** `site-photos` | Visibility: **Private**
4. For each bucket: type the name, leave other settings as default, and click **Save**

---

<a name="section-2"></a>
## Section 2: Configure Gmail SMTP for Email Notifications

The system sends automatic emails when purchase requests are submitted, approved, rejected, and so on. To do this, it uses a Gmail account as the sender.

> **TIP:** Use a dedicated Gmail account for the workshop system — something like `workshop.notifications@gmail.com` — rather than your personal email.

### Step 1 — Prepare Your Gmail Account

1. Log in to the Gmail account you want to use for notifications
2. Click your **profile picture** (top right) → **Manage your Google Account**
3. Click the **Security** tab at the top
4. Scroll down to find **2-Step Verification** and turn it **ON** if it isn't already
   - Follow the prompts to set up 2-step verification (usually involves your phone)
   - Complete the setup and return to the Security tab

### Step 2 — Create an App Password

An App Password is a special 16-character code that lets Supabase send emails through your Gmail account without needing your real Gmail password.

1. On the Security tab (from Step 1 above), scroll down to find **App Passwords**
   - If you don't see it, type "App Passwords" in the Google Account search bar
2. Click **App Passwords**
3. If asked, enter your Google account password to confirm
4. In the "Select app" dropdown, choose **Mail**
5. In the "Select device" dropdown, choose **Other (custom name)**
6. Type **Supabase** as the name and click **Generate**
7. A box will appear showing a 16-character password (like `abcd efgh ijkl mnop`)
8. **Copy this password now** and save it somewhere safe — you will only see it once

### Step 3 — Add the Gmail SMTP Settings to Supabase

1. Go back to your Supabase project dashboard
2. In the left-hand menu, click **Settings** (the cog icon at the bottom)
3. Click **Authentication** in the Settings submenu
4. Scroll down to find the **SMTP Settings** section
5. Turn on the **Enable Custom SMTP** toggle
6. Fill in the fields:
   - **Sender name:** `Workshop System`
   - **Sender email:** your Gmail address (e.g. `workshop.notifications@gmail.com`)
   - **Host:** `smtp.gmail.com`
   - **Port number:** `587`
   - **Username:** your Gmail address (same as sender email)
   - **Password:** the 16-character App Password from Step 2
7. Click **Save**

> **TIP:** To test that emails are working, go to Authentication → Users → Invite user and send an invite to yourself. If you receive the invite email, your SMTP is set up correctly.

---

<a name="section-3"></a>
## Section 3: Create Your AppSmith Account & New App

AppSmith is the tool you use to build the screens — the forms, tables, dashboards, and buttons — that your team will interact with every day.

### Step 1 — Create an AppSmith Account

1. Open your browser and go to **https://app.appsmith.com**
2. Click **Sign up** and create an account using your email address
3. Confirm your email if prompted
4. You will be taken to the AppSmith workspace

### Step 2 — Create a New Application

1. On the AppSmith workspace dashboard, click **Create new** → **Application**
2. Give your application a name: **Carpentry Workshop System**
3. Click **Create**
4. You will be taken into the AppSmith editor — a visual screen builder

### Step 3 — Understand the AppSmith Editor

Take a moment to get familiar with the layout:

- **Left panel:** Shows the pages in your app and the widgets placed on the current page
- **Centre canvas:** The main area where you place and arrange widgets (buttons, tables, forms, etc.)
- **Right panel:** Settings for the currently selected widget
- **Top bar:** Contains the page name, deploy button, and preview button

You will build one page per module (5 modules = 5+ pages in your app).

> **TIP:** You can preview how your app looks at any time by clicking the **eye icon** (Preview) in the top right corner.

---

<a name="section-4"></a>
## Section 4: Connect AppSmith to Supabase

Before you can build any pages, you need to connect AppSmith to your Supabase database. This is called adding a **datasource**.

### Step 1 — Find Your Supabase Connection Details

You need two things from Supabase: your **database connection string** and your **service role key**.

**To find your database connection string:**

1. In Supabase, go to **Settings → Database**
2. Scroll down to **Connection string**
3. Select the **URI** tab
4. Copy the connection string — it looks like: `postgresql://postgres:[YOUR-PASSWORD]@db.xxxx.supabase.co:5432/postgres`
5. Replace `[YOUR-PASSWORD]` with the database password you created in Section 1, Step 2

**To find your service role key:**

1. In Supabase, go to **Settings → API**
2. Find the **Service role** key (under "Project API keys")
3. Click the eye icon to reveal it, then copy and save it
4. Also copy the **Project URL** shown at the top of this page (it looks like `https://xxxx.supabase.co`)

> **WARNING:** Keep your service role key completely private. Anyone who has it has full access to your database. Never share it in emails or chat messages.

### Step 2 — Add the Datasource in AppSmith

1. In the AppSmith editor, look at the left panel and click **Datasources** (the database icon)
2. Click **+ Add new datasource**
3. From the list of database types, choose **PostgreSQL**
4. Fill in the connection details:
   - **Datasource name:** `Supabase Workshop DB`
   - **Host:** Copy the host portion from your connection string (the part after `@` and before `:5432`) — it looks like `db.xxxx.supabase.co`
   - **Port:** `5432`
   - **Database name:** `postgres`
   - **Username:** `postgres`
   - **Password:** your database password from Section 1
5. Click **Test** to verify the connection — you should see a green **Connection successful** message
6. Click **Save**

Your AppSmith app is now connected to your Supabase database. Every page you build will read from and write to this database.

---

<a name="section-5"></a>
## Section 5: Build Each Module Page

This section guides you through creating each of the five modules. Each module has its own page (or set of pages) in your AppSmith app.

For detailed instructions on exactly which widgets to place and how to write each database query, refer to the corresponding module specification file. The steps below tell you how to create each page and what to build on it.

---

### Module 1: Boss Dashboard

**Reference file:** `dashboard-spec.md`
**Who uses it:** The Boss — this is the first screen seen after login
**Purpose:** At-a-glance view of the entire workshop: pending approvals, active workers, low stock alerts, and monthly expenses

#### Creating the Dashboard Page

1. In the AppSmith editor, the first page already exists. Click on it in the left panel and rename it **Boss Dashboard**
2. Right-click the page name → **Set as home page** so the boss sees it first after logging in

#### What to Build on This Page

Following the layout in `dashboard-spec.md`, your dashboard has four sections:

**Row 1 — Four KPI Cards (Stat Box widgets)**

Place four Stat Box widgets across the top of the page:

| Card | What it shows | Colour behaviour |
|------|--------------|-----------------|
| Pending Approvals | Number of purchase requests awaiting a decision | Amber if greater than 0, green if 0 |
| Active Workers Today | Number of workers who have submitted a report today | Neutral (always shows) |
| Low Stock Items | Number of items below their reorder level | Red if greater than 0, green if 0 |
| Monthly Expenses Total | Sum of all expenses this calendar month | Neutral |

For each Stat Box: add the widget, give it a label, then connect it to the matching query from `dashboard-spec.md` (Section 2 of that file).

**Row 2 — Activity Feed + Purchase Order Chart (side by side)**

- Left: A **List widget** showing today's site reports in reverse chronological order. Auto-refreshes every 60 seconds.
- Right: A **Chart widget** (Doughnut/Pie type) showing purchase order counts by status (Pending, Approved, Ordered, Received)

**Row 3 — Stock Level Table**

A **Table widget** showing all stock items. Rows where the current quantity is at or below the reorder level are highlighted in red.

**Row 4 — Payroll Summary**

A **Table widget** showing current-period payroll for all workers, with gross pay and payment status.

> **TIP:** Set all queries on this page to **Run on page load: Yes** so the data is fresh every time the boss opens the dashboard. Find this option in each query's settings.

---

### Module 2: Purchase Order & Approval Module

**Reference file:** `order-module.md`
**Who uses it:** Workers (submit requests), Purchasing Officers (review), Boss (approve or reject)
**Purpose:** Manages the full lifecycle of a purchase request — from submission to delivery

#### Creating the Pages

In AppSmith, click **+** next to Pages in the left panel to add new pages. Create the following four pages:

**Page: Purchase Request Form**

1. Add a new page and name it **New Purchase Request**
2. This page is for Workers to fill in when they need something bought
3. Add the widgets listed in Section 8 of `order-module.md` (Page 1)
4. The form has fields for: Item Name, Quantity, Unit, Estimated Cost, Urgency, Work Site, Delivery Date, and an optional file attachment
5. Two buttons at the bottom: **Save as Draft** and **Submit Request**
6. Connect the Save Draft button to an INSERT query on the `purchase_requests` table with status = `draft`
7. Connect the Submit button to an UPDATE query changing the status to `submitted`

**Page: Purchasing Review**

1. Add a new page and name it **Purchasing Review**
2. This page is for Purchasing Officers only
3. Add a Table widget showing all requests with status `submitted` or `purchasing_review`
4. Clicking a row opens a detail panel showing all request fields (read-only) plus the officer's notes area
5. Two action buttons: **Forward to Boss** and **Reject Request**
6. The Reject button must prompt for a rejection reason before confirming

**Page: Boss Approval**

1. Add a new page and name it **Boss Approval**
2. This page is for the Boss only
3. Add a Table widget showing all requests with status `boss_review`
4. Clicking a row shows full request details plus the officer's notes
5. Two buttons: **Approve** (green) and **Reject** (red)
6. The Reject button reveals a text field for the rejection reason — this field must not be left empty before the rejection can be saved

**Page: Order Status Tracker**

1. Add a new page and name it **Order Tracker**
2. This page is for everyone — Workers see their own requests; Officers and Boss see all
3. Add search and filter controls at the top (by Request ID, Status, Date)
4. Add a Table widget with colour-coded status badges
5. Clicking a row shows the full request detail and an activity timeline (pulled from `purchase_request_logs`)

> **TIP:** Colour-code the status badges so the current state is instantly visible: grey = draft, blue = submitted, yellow = reviewing, orange = boss review, green = approved, red = rejected, purple = ordered, teal = received.

---

### Module 3: Stock & Inventory Module

**Reference file:** `stock-module.md`
**Who uses it:** Workers (submit stock requests), Stock Manager (review and approve)
**Purpose:** Tracks all materials in the workshop — quantities, movements, low-stock alerts

#### Creating the Pages

Create the following pages:

**Page: Stock Catalog**

1. Add a new page and name it **Stock Catalog**
2. This is the master list of all inventory items — primarily used by the Stock Manager
3. Add a Table widget showing all active items: Name, Category, Unit, Current Quantity, Reorder Level, Location
4. Rows where `current_quantity` is at or below `reorder_level` are highlighted in amber
5. Add an **Add Item** button (opens a form modal for creating new items)
6. Add a **Record Stock-In** button (opens a form modal for recording received deliveries)
7. Add search and category filter controls at the top

**Page: Stock Request Form (Mobile-Friendly)**

1. Add a new page and name it **Stock Request**
2. This is used by Workers on their phones — design it for mobile
3. Set the page to a **single-column layout** (no side-by-side fields)
4. Fields: Item (dropdown of active items), Quantity, Purpose, Site/Project
5. A large, full-width **Submit Request** button
6. Below the form, show the worker's last 10 requests with their status

**Page: Stock Manager Review**

1. Add a new page and name it **Stock Review**
2. The Stock Manager uses this to process pending stock requests
3. Add a Table widget showing pending requests
4. Clicking a row opens a review panel showing: the item's current stock level (live), the quantity requested, and an editable "Quantity to Issue" field
5. Two buttons: **Approve & Issue** and **Reject**
6. If the quantity to issue exceeds current stock, show a red warning and disable the Approve button

**Page: Stock Movement History**

1. Add a new page and name it **Stock History**
2. A read-only audit log of every stock movement (in, out, adjustment)
3. Add filter controls: Item, Movement Type, Date Range, User
4. Add an **Export to CSV** button
5. The Stock Manager can also record manual adjustments from this page

---

### Module 4: Daily Work Report Module

**Reference file:** `daily-report-module.md`
**Who uses it:** Workers (submit daily reports from phone), Boss (live feed on desktop)
**Purpose:** Workers report their daily activity on-site; Boss sees everything in real time

#### Creating the Pages

Create the following pages:

**Page: Daily Report Form (Mobile)**

1. Add a new page and name it **Daily Report**
2. Set the canvas width to **Mobile** (375px) in AppSmith page settings
3. Use a single-column layout — no side-by-side fields
4. Fields (top to bottom):
   - Site Name (dropdown of active sites)
   - Report Date (defaults to today)
   - Start Time (time picker)
   - End Time (time picker)
   - Hours Worked (read-only — calculated automatically from start and end times)
   - Tasks Completed (large text area)
   - Materials Used (large text area)
   - Issues or Problems (large text area)
   - Next Steps Planned (large text area)
   - Site Photo (file upload — optional, JPG/PNG only)
5. A large, full-width **Submit Report** button
6. Before submitting, the system checks whether the worker has already submitted a report for this site today. If so, it shows a friendly message and scrolls down to let them edit it instead.

> **TIP:** Set all input fields to a minimum height of 48px and minimum font size of 16px. This prevents mobile browsers from zooming in when the user taps a field.

**Page: Boss Live Feed (Desktop)**

1. Add a new page and name it **Today's Reports**
2. Set the canvas to **Desktop** (1280px)
3. Layout: filters bar across the top, reports table on the left, "Missing Reports" panel on the right
4. Filters: Worker (dropdown), Site (dropdown), Date (defaults to today)
5. The reports table shows: Worker Name, Site, Hours Worked, Time Submitted, and a View button
6. The **Missing Reports** panel lists all active workers who have NOT submitted a report today — this helps the boss spot absences or connectivity problems
7. Add a Refresh button, and set the reports table to auto-refresh every 60 seconds

**Page: Worker History**

1. Add a new page and name it **My Reports**
2. Mobile canvas (375px)
3. Shows each worker their own reports from the last 30 days as a card list
4. Each card shows: Date, Site, Hours, task preview
5. If a report is from today and has not yet been finalised, an **Edit** button appears. Yesterday's reports are locked and show only a **View** button.

**Page: Weekly Hours Summary**

1. Add a new page and name it **Weekly Hours**
2. Desktop canvas
3. Shows a table with one row per worker: Mon–Sun daily hours plus a weekly total
4. A week selector lets the boss choose any past week
5. A **Download CSV** button exports the table for payroll processing

---

### Module 5: Accounting Module

**Reference file:** `accounting-module.md`
**Who uses it:** Accountant (all pages), Boss/Site Manager (view only on cost/expense pages)
**Purpose:** Tracks supplier invoices, project expenses, payroll, cost per site, and monthly profit & loss

#### Creating the Pages

Create the following pages:

**Page: Invoices**

1. Add a new page and name it **Invoices**
2. Add a Table widget showing all supplier invoices: Invoice Number, Supplier, Amount, Due Date, Status
3. Overdue invoices (past due date, not yet paid) are highlighted in red
4. Add filter controls: Status (All / Unpaid / Paid / Overdue), and a search bar for supplier name or invoice number
5. Add an **+ Add Invoice** button that opens a form modal with fields for: Invoice Number, Supplier, Amount, Due Date, PO reference, Notes, and a file upload for the invoice document
6. Add a **Mark Paid** action button on each table row
7. Add an **Export to CSV** button

**Page: Expenses**

1. Add a new page and name it **Expenses**
2. Add a Table widget showing all expenses: Date, Category, Description, Amount, Site
3. Add filter controls: Site (dropdown), Category (dropdown), Date Range
4. Running total figures below the table (one per category)
5. Add an **+ Add Expense** button that opens a form modal with fields for: Date, Category, Description, Amount, Site, and optional PO reference
6. Add an **Export to CSV** button

**Page: Payroll Calculator**

1. Add a new page and name it **Payroll**
2. Add a Month selector dropdown at the top (last 24 months)
3. Add a **Generate Payroll** button — when clicked, it reads all daily report hours for that month and calculates each worker's gross pay (Hours × Hourly Rate)
4. Results appear in a Table widget: Worker Name, Total Hours, Hourly Rate, Gross Pay, Status
5. Add a **Confirm & Lock** button to finalise the month's figures
6. Add a **Mark Paid** action on each row, with a date field for when payment was made
7. Add a total gross pay figure at the bottom
8. Add an **Export to CSV** button

**Page: Cost per Site**

1. Add a new page and name it **Cost per Site**
2. Add a Site dropdown at the top
3. Show a running total (all expenses for that site, from start to present)
4. Show a monthly breakdown table: Month, Materials, Labour, Transport, Misc, Total
5. Show a bar chart of monthly costs by category
6. Add an **Export to CSV** button

**Page: Monthly Summary**

1. Add a new page and name it **Monthly Summary**
2. Add a Month selector at the top
3. Show a Net Position card at the top (green if positive, red if negative)
4. Show a summary table with rows for: Total Income, Total Expenses, Total Payroll, Total Cost, Net Position — with a comparison to the previous month
5. Add an **Export to CSV** button

---

<a name="section-6"></a>
## Section 6: Invite Users & Assign Roles

Your system has five roles. Each person on your team is assigned exactly one role. The role controls what they can see and do.

### The Five Roles

| Role | Who it's for | What they can do |
|------|-------------|-----------------|
| **Boss** | Owner or general manager | Full access to everything |
| **Worker** | Frontline staff | Submit purchase requests, daily reports, stock requests |
| **Purchasing Officer** | Procurement team member | Review and forward purchase requests, place orders, mark received |
| **Accountant** | Finance staff | Manage invoices, expenses, payroll, and financial reports |
| **Stock Manager** | Inventory team member | Manage stock catalog, review stock requests, record stock in/out |

### How to Invite a New User

**In Supabase:**

1. Go to your Supabase project at **https://app.supabase.com**
2. In the left-hand menu, click **Authentication**
3. Click the **Users** tab
4. Click the **Invite user** button (top right)
5. Type in the person's email address and click **Send invite**
6. The person will receive an email with a link to set their password

**To assign their role (after they accept the invite):**

1. In the Users list, find the person who just accepted (they will show as "Active")
2. Click their name to open their profile
3. Find the **App Metadata** section
4. Click **Edit** and add the following, replacing `worker` with their actual role:
   ```
   { "role": "worker" }
   ```
5. The role names to use are (copy exactly, including lowercase):
   - `boss`
   - `worker`
   - `purchasing_officer`
   - `accountant`
   - `stock_manager`
6. Click **Save**

> **TIP:** Always confirm with the new user that they can log in and see the right sections. If something looks wrong, check that the role name in their metadata matches the list above exactly.

### How to Invite Users in AppSmith

Your team will access the system through AppSmith, so they also need access to the AppSmith app.

1. In AppSmith, click **Share** (top right of the editor)
2. Enter the team member's email address
3. Choose their permission level:
   - **Editor** — for yourself or any administrator who needs to change the app
   - **Viewer** — for everyone else (workers, boss, accountant, etc.)
4. Click **Invite**
5. They will receive an email inviting them to access the app

### Changing or Removing a User's Role

**To change a role:** Follow the same steps above — open their user profile in Supabase and edit the `role` field in App Metadata.

**To remove a user:** In Supabase → Authentication → Users, find the user and click the three-dot menu → **Delete user**. This immediately removes their access.

> **TIP:** Review your user list every few months. Remove accounts for anyone who has left the team.

---

<a name="section-7"></a>
## Section 7: Worker Mobile Setup — Add to Home Screen

Workers will use the system from their phones on-site. The quickest way to access it is to add the app to the home screen, so it opens like a regular app with one tap.

### Step 1 — Publish Your AppSmith App

Before workers can access the app on their phones, you need to publish it.

1. In the AppSmith editor, click the **Deploy** button (top right)
2. After publishing, AppSmith will show you a **live URL** — it looks like `https://app.appsmith.com/app/carpentry-workshop-system/page1-xxxxxx`
3. Copy this URL and share it with your team (via SMS, WhatsApp, or email)

### Step 2 — Workers Add the App to Their Home Screen

**On iPhone (Safari browser):**

1. Open **Safari** (not Chrome — this feature only works in Safari on iPhone)
2. Go to the app URL you shared
3. Log in with their email and password
4. Tap the **Share** button at the bottom of the screen (the box with an arrow pointing up)
5. Scroll down in the share menu and tap **Add to Home Screen**
6. Give the shortcut a name (e.g. "Workshop") and tap **Add**
7. The icon now appears on their home screen

**On Android (Chrome browser):**

1. Open **Chrome**
2. Go to the app URL you shared
3. Log in with their email and password
4. Tap the **three-dot menu** (top right of Chrome)
5. Tap **Add to Home screen**
6. Give the shortcut a name and tap **Add**
7. The icon now appears on their home screen

> **TIP:** Test this on one phone first before rolling it out to the whole team. Have one worker go through the steps and confirm that the Daily Report Form loads correctly on their device.

### Step 3 — Confirm Mobile Access Works

After workers have added the app to their home screen, verify the following:

- [ ] The app opens without asking for a URL
- [ ] They can log in with their email and password
- [ ] The Daily Report Form is easy to read and fill in (large text, big buttons)
- [ ] They can submit a report and see a confirmation message
- [ ] The site photo upload works from their phone's camera roll
- [ ] There is no horizontal scrolling (everything fits on the screen without scrolling sideways)

If any of these fail, refer to Part 7 of `daily-report-module.md` (Mobile-Friendliness Checklist) for troubleshooting guidance.

---

## Final Checklist

Work through this list to confirm everything is set up before you go live.

### Database (Supabase)
- [ ] Project created and database password saved
- [ ] `schema.sql` run successfully — all tables visible in Table Editor
- [ ] Three storage buckets created: `purchase-attachments`, `invoice-attachments`, `site-photos`
- [ ] Gmail SMTP configured and tested (invite email received)

### AppSmith App
- [ ] AppSmith account created
- [ ] New application created: "Carpentry Workshop System"
- [ ] Supabase datasource connected and tested (green success message)
- [ ] All module pages built and working:
  - [ ] Boss Dashboard
  - [ ] Purchase Request Form, Purchasing Review, Boss Approval, Order Tracker
  - [ ] Stock Catalog, Stock Request Form, Stock Review, Stock History
  - [ ] Daily Report Form, Boss Live Feed, Worker History, Weekly Hours
  - [ ] Invoices, Expenses, Payroll, Cost per Site, Monthly Summary

### Users & Roles
- [ ] All team members invited via Supabase
- [ ] Each user's role assigned in App Metadata
- [ ] All team members invited to the AppSmith app
- [ ] Each user has logged in and confirmed their access is correct

### Mobile Setup
- [ ] App URL shared with all workers
- [ ] At least one worker has added the app to their home screen and tested it
- [ ] Daily Report Form tested on a real phone

---

## Getting Help

**Supabase documentation:** https://supabase.com/docs
**AppSmith documentation:** https://docs.appsmith.com

If something doesn't work as expected:

1. Re-read the relevant step carefully
2. Check that all saved credentials (passwords, keys) match what you entered
3. For database errors, check the **Logs** section in Supabase (left-hand menu → Logs)
4. For AppSmith connection errors, re-test the datasource connection (Datasources → your datasource → Test)

---

*Carpentry Workshop Management System — Setup Guide v1.0*
*Refer to the module spec files for detailed widget-by-widget build instructions.*
