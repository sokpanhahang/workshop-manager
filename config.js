// ============================================================
// CARPENTRY WORKSHOP MANAGEMENT SYSTEM
// Configuration File — Edit this file before deploying
// ============================================================
//
// STEP 1: Go to https://supabase.com and open your project
// STEP 2: Click "Project Settings" → "API"
// STEP 3: Copy "Project URL" and paste below
// STEP 4: Copy "anon public" key and paste below
//
// ============================================================

const SUPABASE_URL  = "https://wudkpwrbxyyvanpkbdtw.supabase.co/rest/v1/";   // ← paste your Project URL here
const SUPABASE_ANON = "sb_publishable_BryT_Isaxm60ri6ecJ5QTQ_RN4nTVQl";              // ← paste your anon public key here

// ============================================================
// DO NOT EDIT BELOW THIS LINE
// ============================================================

const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON);
