# Chorin' - Development TODO

## Next Milestone (Priority): Multi-User Chores Foundation
- [x] Lock product rule: children can create chores and they auto-assign to creator
- [x] Lock product rule: parent approves chores by editing; approved chores show no extra label
- [x] Add `chore_assignments` table + indexes + RLS policies (DB schema/migration change required)
- [x] Add chore approval status fields + parent approval audit fields (DB schema/migration change required)
- [x] Update chores RLS to allow child-created chores and parent approval actions
- [x] Add DB automation so child-created chores auto-create creator assignment
- [x] Add assignment-aware chores read RPC/view for `auth.uid()` with `completed_today` and `today_completion_id`
- [x] Refactor chores page to use assignment-aware query surface (remove per-`chore_id` completion map assumptions)
- [ ] Fix child chores UI: show "+" button for child role so children can create chores
- [ ] Add parent assignment controls in chore create/edit flow (child creation + parent approval-by-edit implemented)
- [ ] Move earnings/savings weekly aggregates to SQL/RPCs
- [ ] Confirm retroactive handling policy if a previously approved chore is changed later
- [ ] Run multi-user regression matrix (parent + child browsers)

## Savings Goals (dev branch)
- [ ] Test: create goal -> set auto-save % -> complete chore -> verify auto-contribution
- [ ] Test: uncheck chore -> verify cascade deletes auto-contribution
- [ ] Test: manual contribute via "+ Add Money"
- [ ] Test: realtime sync between parent and child browsers
- [ ] Test: edit goal (name, target, auto-save %, icon)
- [ ] Test: archive goal

## Permissions & Roles
- [x] Parent-only chore management baseline exists (to be relaxed for child-created chores workflow)
- [ ] Child can create chores within household (RLS done; child "+" button not showing reliably)
- [x] Parent approval workflow for chores (approval-by-edit)
- [ ] Per-child chore assignments
- [x] DB supports per-user completion records for same chore/day
- [ ] UI/query model must show per-user completion state correctly in multi-child households

## Scheduling & Recurrence
- [ ] Chore scheduling (assign chores to specific days of the week)
- [ ] One-time / bonus chores

## Notifications & Engagement
- [ ] Push notifications / reminders
- [ ] Streaks (consecutive days/weeks of completion)
- [ ] Weekly summary notification

## Earnings & Allowance
- [ ] Payout tracking (mark earnings as "paid out")
- [ ] Sync earnings and savings goals so payout shows the difference
- [x] Allow deletion of earnings/history entries (self-owned completions)
- [ ] Earnings history beyond 7 weeks

## Household Management
- [ ] Edit household name
- [ ] Regenerate invite code
- [ ] Display names for members (instead of just role)
- [ ] Multiple children dashboard for parents
- [ ] Configurable week start day (currently hardcoded to Monday in `lib/week-helpers.ts`)

## UX Polish
- [ ] Chore reordering (drag-to-reorder)
- [ ] Chore categories / groups
- [ ] Animations / confetti on completing all daily chores
- [ ] PWA support (installable, offline)

## Scalability & Code Cleanliness

### Data Integrity & Backend Workflows
- [x] Move household create + initial parent membership into one transactional RPC (DB schema/migration change required)
- [x] Move chore completion toggle + auto-savings contribution inserts into one transactional RPC or DB trigger (DB schema/migration change required)
- [x] Enforce parent-only chore management in RLS policies (DB schema/migration change required)
- [x] Add DB constraints for money fields (`chore_completions.earned_amount > 0`, `savings_contributions.amount > 0`) (DB schema/migration change required)
- [ ] Replace invite code generation with a stronger, collision-safe generator + retry logic (DB schema/migration change required)
- [ ] Make realtime publication changes idempotent in schema/migrations (DB schema/migration change required)
- [ ] Remove the manual recursive-RLS setup step by baking final policy/function into migrations and schema source of truth (DB schema/migration change required)

### Multi-User Model
- [ ] Rework chore checklist logic so completion state is per-user and assignment-aware for multi-child households
- [ ] Add per-child assignment model and assignment-aware filters/queries (DB schema/migration change required)

### Query Performance
- [ ] Replace client-side weekly aggregations with SQL aggregates/RPCs for earnings and history
- [ ] Replace client-side savings progress summation with SQL aggregates/RPCs

### Frontend Architecture
- [ ] Extract shared auth + household bootstrap loader/hook used by chores/savings/earnings/household pages
- [ ] Stabilize React hooks/memoization patterns to clear current lint/compiler issues
- [ ] Eliminate duplicated form validation rules by centralizing shared validators/constants

### Types & Tooling
- [ ] Generate and use typed Supabase DB types instead of maintaining hand-written table interfaces
- [ ] Keep README, schema.sql, and migrations synchronized so setup docs always match real DB state
