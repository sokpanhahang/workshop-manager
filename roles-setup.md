# User Roles & Authentication Setup Guide
### Supabase Configuration for Your Team

---

## Overview

This guide explains how to set up five user roles in your Supabase-powered system, invite team members, and control who can see or change what. No technical background is required to follow these steps.

The five roles are:

| Role | Who it's for |
|------|--------------|
| **Boss** | Owner or general manager — full visibility across the business |
| **Worker** | Frontline staff — limited to what they need to do their job |
| **Purchasing Officer** | Handles supplier orders and procurement |
| **Accountant** | Manages financial records and reporting |
| **Stock Manager** | Oversees inventory and stock levels |

---

## Section 1: What Each Role Can Access

### Boss
The Boss role has the broadest access. This is intended for the owner or most senior manager.

**Can access:**
- All sales records and revenue reports
- All employee activity and user accounts
- All financial data and accounting records
- All purchase orders and supplier information
- All stock and inventory data
- System settings and user management

**Cannot do:**
- Nothing is restricted — this role has full read and write access across all areas

> **Note:** Assign this role sparingly. Only one or two people should hold Boss access.

---

### Worker
Workers are frontline staff who need just enough access to complete their daily tasks.

**Can access:**
- Their own profile and assigned tasks
- Products and items they are authorised to view or update (e.g. marking a job as done)
- Basic stock availability (read-only — they can see levels, not change them)

**Cannot access:**
- Financial records or pricing details
- Other users' data or activity
- Purchase orders or supplier contacts
- Accounting reports
- System settings or user management

---

### Purchasing Officer
This role is for the person responsible for ordering stock and managing supplier relationships.

**Can access:**
- All purchase orders (create, view, edit, submit)
- Supplier contact information and pricing
- Current stock levels (read-only — to know what to order)
- Their own profile

**Cannot access:**
- Payroll or salary information
- General financial reports or accounting data
- Other users' records
- System settings or user management

---

### Accountant
The Accountant role is focused entirely on financial data. They can see the numbers but cannot change operations.

**Can access:**
- All financial records (invoices, expenses, payments)
- Sales and revenue reports
- Purchase order totals and summaries
- Their own profile

**Cannot access:**
- Detailed operational records (e.g. individual job logs or worker activity)
- Supplier contacts or the ability to create purchase orders
- Stock management functions
- System settings or user management

---

### Stock Manager
The Stock Manager owns the inventory. They track what comes in, what goes out, and what needs replenishing.

**Can access:**
- Full stock and inventory records (create, view, edit, adjust)
- Stock movement history
- Purchase order summaries (read-only — to reconcile deliveries)
- Their own profile

**Cannot access:**
- Financial records or pricing beyond what appears on purchase orders
- Employee records or payroll
- Sales reports
- System settings or user management

---

## Section 2: Quick-Reference Permissions Table

The table below gives a snapshot of access across all five roles.

| Area | Boss | Worker | Purchasing | Accountant | Stock Manager |
|------|:----:|:------:|:----------:|:----------:|:-------------:|
| All financial records | ✅ | ❌ | ❌ | ✅ | ❌ |
| Sales reports | ✅ | ❌ | ❌ | ✅ | ❌ |
| Purchase orders (create/edit) | ✅ | ❌ | ✅ | ❌ | ❌ |
| Purchase order totals (view only) | ✅ | ❌ | ✅ | ✅ | ✅ |
| Stock levels (view only) | ✅ | ✅ | ✅ | ❌ | ✅ |
| Stock management (full edit) | ✅ | ❌ | ❌ | ❌ | ✅ |
| Supplier contacts | ✅ | ❌ | ✅ | ❌ | ❌ |
| Employee/user records | ✅ | ❌ | ❌ | ❌ | ❌ |
| System settings | ✅ | ❌ | ❌ | ❌ | ❌ |
| Own profile | ✅ | ✅ | ✅ | ✅ | ✅ |

**Key:** ✅ = Full access &nbsp;&nbsp; ❌ = No access

---

## Section 3: How to Invite Users (Supabase Dashboard)

Follow these steps to add a new team member. You will need Boss-level access or Supabase project admin rights to do this.

### Step-by-Step: Inviting a New User

**1. Log in to Supabase**
Go to [https://app.supabase.com](https://app.supabase.com) and sign in with your admin account.

**2. Open your project**
From the dashboard, click the name of your project to open it.

**3. Go to Authentication**
In the left-hand menu, click **Authentication**. This opens the user management section.

**4. Navigate to Users**
Click the **Users** tab at the top of the Authentication page. You will see a list of all current users.

**5. Invite a new user**
Click the **Invite user** button (top right of the Users list).

**6. Enter the user's email address**
Type in the email address of the person you want to invite. Double-check the spelling — the invite goes directly to this address.

**7. Send the invite**
Click **Send invite**. Supabase will email the new user with a link to set their password and activate their account.

**8. Assign their role**
After the user has accepted the invite and their account appears in the Users list:
- Click on their name to open their profile
- Find the **User Metadata** or **App Metadata** section
- Add their role in the metadata field — for example: `"role": "accountant"` or `"role": "stock_manager"`
- Save the changes

> **Tip:** The role names to use in the metadata field are: `boss`, `worker`, `purchasing_officer`, `accountant`, `stock_manager`. Use lowercase, no spaces.

**9. Confirm access**
Ask the new user to log in and confirm they can see what they expect — and nothing they shouldn't.

---

### Resending or Revoking Invites

- **Resend an invite:** From the Users list, find the user with a "Invited" status, click the three-dot menu beside their name, and select **Resend invite**.
- **Delete a user:** From the Users list, click the three-dot menu beside the user's name and select **Delete user**. This permanently removes their access. Use this when someone leaves the team.

---

## Section 4: How Row Level Security Works (Plain Language)

Row Level Security — often called RLS — is the system that enforces who can see which records in your database. Think of it as a set of invisible filters placed on every table of data.

### The Simple Idea

Imagine your database is a filing cabinet. Without RLS, anyone with the key to the cabinet can read every folder inside. With RLS switched on, each person only sees the folders they are allowed to open — even if they technically have a key to the cabinet.

The rules that determine which folders each person can open are called **policies**.

### How It Works in Practice

When a user logs in, Supabase knows who they are and what role they have been assigned. When that user tries to view or change a record, Supabase automatically checks the policies for that table:

- **Does this user's role allow them to read this record?** If yes, the record appears. If no, the record is invisible — as if it doesn't exist.
- **Does this user's role allow them to edit or delete this record?** Same check applies.

The user never sees an error message saying "access denied" for records they can't reach. Those records simply don't appear in their view.

### What This Means for Your Roles

- A **Worker** logging in will only ever see the data their policy allows — stock availability and their own profile. Financial data doesn't appear in their view at all.
- An **Accountant** sees all financial records but would find the stock management section empty, because their policy doesn't grant access to it.
- The **Boss** has a policy that allows full access to all records in all tables, so nothing is hidden.

### Why This Matters

RLS means that even if something goes wrong — a user ends up in the wrong part of the system, or a bug shows the wrong screen — the database itself will not serve data the user isn't permitted to see. The protection lives at the data layer, not just the interface layer.

### Policies Are Set Up Once

The specific policies that enforce these rules are configured by a developer when the system is built. Once they are in place, you don't need to manage them manually. When you assign someone the `accountant` role in their metadata (as described in Section 3), the correct policies automatically apply to their account.

If you need to change what a role can access — for example, if you want Purchasing Officers to also view sales summaries — that is a request for your developer to update the relevant policy. It does not require reinviting users or changing passwords.

---

## Section 5: Ongoing User Management

### Changing a User's Role
If someone's responsibilities change — for example, a Worker is promoted to Stock Manager — update their role in Supabase:

1. Go to **Authentication → Users** in your Supabase dashboard
2. Click the user's name
3. Edit the `role` field in their metadata to reflect the new role
4. Save — the change takes effect immediately on their next login (or current session refresh)

### Deactivating a User
If someone leaves the organisation or you need to suspend their access:

1. Go to **Authentication → Users**
2. Find the user and click the three-dot menu
3. Select **Delete user** to permanently remove access, or contact your developer to temporarily disable the account without deleting it

### Periodic Review
It is good practice to review the user list every few months and confirm that:
- Everyone on the list still works with the organisation
- Each person's role still matches their current responsibilities
- No unused accounts remain active

---

## Summary

| Task | Where to do it |
|------|----------------|
| Invite a new user | Supabase Dashboard → Authentication → Users → Invite user |
| Assign a role | Supabase Dashboard → User profile → App Metadata |
| Change a role | Same as above — edit and save |
| Remove a user | Supabase Dashboard → Users → three-dot menu → Delete |
| Update what a role can access | Contact your developer to update RLS policies |

---

*This guide is intended for non-technical administrators. For developer-level configuration of RLS policies, authentication providers, or custom role logic, refer to the technical documentation or contact your development team.*
