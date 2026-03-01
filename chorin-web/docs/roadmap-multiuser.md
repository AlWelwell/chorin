# Chorin' Multi-User Roadmap

Last updated: 2026-02-27

## Objective
Deliver a correct multi-child chores model where:
- children can create chores for themselves
- child-created chores auto-assign to the creator
- parents can approve chores by editing them
- completion state is per user per day
- earnings and savings totals stay accurate and scalable

## Current Status
- Parent-only chore management baseline is in place and now needs to be relaxed for child-created chores.
- DB supports per-user completion rows for the same chore/day.
- Frontend chores checklist still assumes one completion state per chore in places.
- Weekly earnings/savings aggregation is still mostly client-side.

## Phase 0: Product Rules Lock
Goal: remove ambiguity before schema and UI changes.

Tasks
- Lock rule: child can create a chore.
- Lock rule: new child-created chore is auto-assigned to the creating child.
- Lock rule: new child-created chores show as "Pending approval" until a parent edits/approves.
- Record these rules in `TODO.md` and this roadmap.

Exit criteria
- All three decisions are explicitly documented.
- Team agrees on acceptance behavior for parent and child roles.

## Phase 1: Assignment Data Model
Goal: introduce durable assignment primitives in the DB.

Tasks
- Add `chore_assignments` table with `id`, `chore_id`, `user_id`, `created_at`.
- Add unique constraint `(chore_id, user_id)` and indexes on `chore_id`, `user_id`.
- Add chore validation fields/status model (for example `validation_status`, `validated_by_user_id`, `validated_at`).
- Add RLS policies:
  - child can create chores in their household with `created_by = auth.uid()`
  - parent can approve chores in their household
  - member read access remains household-scoped
- Add DB automation so child-created chores auto-create assignment to that child.
- Add migration/backfill strategy for existing chores.

Dependencies
- Phase 0

Exit criteria
- Child can create chores and gets auto-assigned.
- Parent can assign/unassign children.
- Parent can approve chores at any stage by editing.
- Duplicate assignments are impossible.
- Child reads are assignment-safe under RLS.

## Phase 2: Assignment-Aware Chores Query Surface
Goal: shift chores checklist truth to DB-side query logic.

Tasks
- Add RPC/view returning chores for `auth.uid()` with:
  - chore fields
  - approval status fields
  - `completed_today`
  - `today_completion_id`
- Ensure result is assignment-aware and role-safe.
- Keep compatibility with existing completion toggle RPC.

Dependencies
- Phase 1

Exit criteria
- Child only receives assigned chores.
- Parent can approve chores without breaking checklist state.
- Completion state is correct per user/day.

## Phase 3: Frontend Chores Refactor
Goal: consume assignment-aware data and expose assignment UI.

Tasks
- Update `app/chores/page.tsx` to use new chores query surface.
- Remove per-`chore_id` completion map assumptions.
- Allow child chore creation flow.
- Extend `components/ChoreForm.tsx` with:
  - parent assignment controls
  - parent approval-by-edit behavior
- Ensure realtime refresh captures chores, completions, and assignments.

Dependencies
- Phase 2

Exit criteria
- No cross-user completion bleed in chores checklist.
- Child can create chores and see them assigned immediately.
- Parent can set assignments and approve chores during create/edit.

## Phase 4: Earnings and Savings Aggregation
Goal: reduce client compute and support multi-user accuracy.

Tasks
- Add SQL/RPC aggregates for:
  - weekly earnings total
  - daily earnings breakdown
  - by-chore breakdown
  - weekly savings offset used in payout display
  - approval-aware totals (so pending chores are handled consistently)
- Update earnings pages to consume aggregate payloads.

Dependencies
- Phase 2 (and Phase 1 for assignment-aware filters)

Exit criteria
- Earnings/savings numbers match expected values in single- and multi-user flows.
- Client pages no longer perform primary aggregation via large `filter/reduce` chains.

## Phase 5: Regression Matrix and Release Readiness
Goal: validate cross-user correctness before shipping.

Tasks
- Run parent/child two-browser matrix:
  - assign/unassign chores
  - complete/uncomplete chores
  - auto-savings insert/delete cascade via completion toggles
  - manual contributions unaffected
  - delete completion permissions
  - realtime sync behavior
- Log failures and create follow-up issues.

Dependencies
- Phases 1-4

Exit criteria
- All critical scenarios pass or have approved follow-up issues.
- `TODO.md` test items are updated with outcome.

## Suggested Execution Order
1. Phase 0
2. Phase 1
3. Phase 2
4. Phase 3
5. Phase 4
6. Phase 5

## Open Decisions
- Parent completion policy: `manage-only` or `can-complete`.
- Existing chores migration default: `assign-all-current-children` or `no-default-assignment`.
