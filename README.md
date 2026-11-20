# 🪵 Carpentry Workshop Management System

**Deployment: GitHub Pages + Supabase**
*No server. No install. Free hosting. Works on mobile and desktop.*

---

## Files in This Package

| File | Purpose |
|------|---------|
| `config.js` | ⚙️ **Edit this first** — your Supabase keys go here |
| `login.html` | Login page (email + password) |
| `index.html` | Main app (tabs, role-based navigation) |
| `modules/orders.js` | Purchase Order module |
| `modules/stock.js` | Stock & Inventory module |
| `modules/daily-report.js` | Daily Work Report module |
| `modules/accounting.js` | Accounting, Invoices & Payroll |
| `modules/dashboard.js` | Boss Dashboard |
| `schema.sql` | Database schema — run once in Supabase |

---

## Deployment — 5 Steps

### Step 1 — Set Up Supabase (Database)

1. Go to [https://supabase.com](https://supabase.com) and create a free account
2. Click **New Project**, give it a name (e.g. "workshop"), choose a region
3. Wait 1–2 minutes for the project to be ready
4. In your project, click **SQL Editor** (left sidebar)
5. Click **New Query**, then copy and paste the entire contents of `schema.sql`
6. Click **Run** — you should see "Success"
7. Go to **Project Settings → API**
8. Copy your **Project URL** (looks like `https://xxxx.supabase.co`)
9. Copy your **anon public** key (long string starting with `eyJ…`)

---

### Step 2 — Edit config.js

Open `config.js` in any text editor (Notepad on Windows, TextEdit on Mac).

Replace the two placeholder values:

```js
const SUPABASE_URL  = "https://YOUR_PROJECT_ID.supabase.co";   // ← paste Project URL
const SUPABASE_ANON = "YOUR_ANON_PUBLIC_KEY_HERE";              // ← paste anon key
```

Save the file.

---

### Step 3 — Upload to GitHub

1. Go to [https://github.com](https://github.com) — create a free account if needed
2. Click the **+** button (top right) → **New repository**
3. Name it: `workshop-manager` (or any name)
4. Set to **Public**
5. Click **Create repository**
6. On the next screen, click **uploading an existing file**
7. Drag and drop **all files and the `modules/` folder** into the upload area
8. Click **Commit changes**

---

### Step 4 — Enable GitHub Pages

1. In your GitHub repository, click **Settings** (top tab)
2. Scroll down to **Pages** (left sidebar)
3. Under **Source**, select **Deploy from a branch**
4. Under **Branch**, select `main` and folder `/` (root)
5. Click **Save**
6. Wait 1–2 minutes, then refresh the Settings → Pages page
7. You will see: **Your site is live at `https://your-username.github.io/workshop-manager/`**

---

### Step 5 — Add Your First User (Boss)

1. In Supabase, go to **Authentication → Users** (left sidebar)
2. Click **Invite user** (or **Add user**)
3. Enter the boss email address and set a password
4. Click **SQL Editor** → **New Query** and run this (replace the values):

```sql
INSERT INTO public.profiles (id, full_name, role)
SELECT id, 'Your Name Here', 'boss'
FROM auth.users
WHERE email = 'boss@youremail.com';
```

5. Click **Run**
6. Open your app URL in a browser → log in with that email and password

---

## Adding More Users

For each new team member:

1. In Supabase → **Authentication → Users** → **Add user**
2. Enter their email and a temporary password
3. Run this SQL to assign their role:

```sql
INSERT INTO public.profiles (id, full_name, role)
SELECT id, 'Full Name', 'worker'   -- change role: worker / purchasing / accountant / stock_manager / boss
FROM auth.users
WHERE email = 'worker@email.com';
```

**Available roles:**
- `boss` — full access, dashboard
- `worker` — daily reports, stock requests
- `purchasing` — purchase orders
- `accountant` — accounting, invoices, payroll
- `stock_manager` — stock inventory management

---

## Mobile Setup (Workers on Phone)

Workers can use the app as a mobile app without installing anything:

**iPhone / iPad:**
1. Open the app URL in Safari
2. Tap the Share button (box with arrow)
3. Tap **Add to Home Screen**
4. Tap **Add**

**Android:**
1. Open the app URL in Chrome
2. Tap the three dots menu (top right)
3. Tap **Add to Home Screen**
4. Tap **Add**

---

## Troubleshooting

| Problem | Solution |
|---------|---------|
| "Error: Invalid API key" | Check config.js — make sure you pasted the anon key (not the service_role key) |
| Login works but app is blank | Your profile row is missing — run the INSERT SQL from Step 5 |
| Changes don't appear after editing | GitHub Pages can take 1–2 min to update. Hard refresh (Ctrl+Shift+R) |
| "Failed to fetch" error | Check your Supabase Project URL in config.js |
| Worker can't see their tab | Check their role in the profiles table matches exactly: `worker`, `boss`, etc. |

---

## Your App URL

After Step 4, your app is live at:

```
https://YOUR-GITHUB-USERNAME.github.io/workshop-manager/login.html
```

Share this link with your team.

---

*Built with Supabase + GitHub Pages. No server required.*
