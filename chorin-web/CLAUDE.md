# Chorin' — Development Guide

## Overview

Chorin' is a chore-tracking web app built with Next.js 16 (App Router), Supabase (Postgres + Auth + Realtime), and Tailwind CSS. It supports two user roles (parent and child) across separate accounts sharing the same household data.

## Architecture

- **Next.js 16 App Router** — all pages under `app/`, uses the new `proxy.ts` instead of `middleware.ts` for route handling
- **Supabase** — handles auth, database (Postgres), row-level security, and real-time subscriptions
- **Client components** — all pages are `"use client"` since they need Supabase real-time subscriptions and interactive state
- **Server component** — only `app/page.tsx` (landing redirect) runs server-side

## Key Patterns

### Database Access
- All queries use the Supabase JS client (`.from().select().eq()`, etc.) — never raw SQL
- Queries are parameterized by default (no SQL injection risk)
- Row Level Security (RLS) enforces that users can only access their own household's data
- The `household_members` table uses a `security definer` function (`get_my_household_ids()`) to avoid recursive RLS policies

### Authentication Flow
1. `proxy.ts` checks auth on every request, redirects unauthenticated users to `/login`
2. `app/page.tsx` redirects authenticated users to `/chores` or `/onboarding` based on household membership
3. Supabase Auth handles email/password signup and login

### Weekly Logic
- Weeks run Monday → Sunday
- No cron jobs or background tasks — weekly "reset" is purely query-based (filter completions by date)
- `lib/week-helpers.ts` contains all date boundary calculations
- `chore_completions.earned_amount` snapshots the chore value at completion time so historical earnings are preserved when chore values change

### Multi-User Sharing
- Parent creates a household → gets a 6-character invite code
- Child signs up and enters the code to join
- Both see the same chores and completions via RLS policies
- Real-time subscriptions on `chore_completions` and `chores` tables keep both users in sync

## Environment Variables

```
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

## Commands

```bash
npm run dev      # Start dev server (http://localhost:3000)
npm run build    # Production build
npm run start    # Start production server
npm run lint     # Run ESLint
```

## File Conventions

- **Pages**: `app/[route]/page.tsx` — client components with `"use client"`
- **Components**: `components/[Name].tsx` — reusable UI components
- **Lib**: `lib/` — utilities, types, Supabase client helpers
- **Styling**: Tailwind CSS with dark mode (gray-950/900/800 palette, green-400 for money, blue-600 for actions)
- **Logo**: Uses Pacifico font with a brown rope-style gradient (`.rope-text` class in `globals.css`)

## Input Validation

- Invite codes: stripped to alphanumeric, must be exactly 6 characters
- Chore names: trimmed, max 100 characters
- Chore values: must be $0.01–$999.99
- Household names: trimmed, max 50 characters

## Database Schema

See `supabase/schema.sql` for the full schema including tables, indexes, RLS policies, and real-time configuration. The recursive RLS fix (`get_my_household_ids()` function) must be applied separately — see README.md step 4.

## Recent Security Hardening (2026-02-23)

- Removed broad household read access by deleting policy `"Anyone can look up by invite code"` (`USING (true)`).
- Added secure invite lookup RPC: `public.lookup_household_by_invite_code(p_invite_code text)` with `security definer`, input sanitization, and `authenticated` execute permission only.
- Updated onboarding join flow to call RPC instead of direct `households` select:
  - `app/onboarding/page.tsx` now uses `supabase.rpc("lookup_household_by_invite_code", ...)`.
- Hardened membership inserts:
  - `"Users can join households"` now enforces `user_id = auth.uid()` and `role = 'child'`.
  - Added `"Users can create initial parent membership"` to allow only the first membership row in a household to be a parent self-insert.
- Hardened ownership checks in write policies:
  - `chore_completions` inserts/deletes now require `user_id = auth.uid()`.
  - `savings_goals` inserts/updates now require `user_id = auth.uid()` and household membership.
  - `savings_contributions` inserts/deletes now require `user_id = auth.uid()`.
- Added `WITH CHECK` protections for update policies on `chores` and `savings_goals` to prevent cross-household reassignment.
- Changed completion uniqueness to per-user-per-day:
  - from `unique (chore_id, date)` to `unique (chore_id, user_id, date)`.
- Added migration for existing databases:
  - `supabase/migrations/20260223103500_harden_rls_and_membership.sql`
  - Includes policy rebuilds, RPC creation/grants, and safe constraint migration.
