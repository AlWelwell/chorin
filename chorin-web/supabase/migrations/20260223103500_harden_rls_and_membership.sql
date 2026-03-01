begin;

-- Remove broad household read access.
drop policy if exists "Anyone can look up by invite code" on public.households;

-- Secure invite-code lookup for authenticated users.
create or replace function public.lookup_household_by_invite_code(p_invite_code text)
returns table (
  id uuid,
  name text,
  invite_code text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  sanitized_code text;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  sanitized_code := lower(regexp_replace(coalesce(p_invite_code, ''), '[^a-z0-9]', '', 'g'));

  if length(sanitized_code) <> 6 then
    return;
  end if;

  return query
  select h.id, h.name, h.invite_code
  from public.households h
  where h.invite_code = sanitized_code
  limit 1;
end;
$$;

revoke all on function public.lookup_household_by_invite_code(text) from public;
grant execute on function public.lookup_household_by_invite_code(text) to authenticated;

-- Join policy: self-join only as child.
drop policy if exists "Users can join households" on public.household_members;
create policy "Users can join households"
  on public.household_members for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and role = 'child'
  );

-- Household creator flow: allow first member to self-assign as parent.
drop policy if exists "Users can create initial parent membership" on public.household_members;
create policy "Users can create initial parent membership"
  on public.household_members for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and role = 'parent'
    and not exists (
      select 1
      from public.household_members hm
      where hm.household_id = household_members.household_id
    )
  );

-- Prevent cross-household reassignment via UPDATE.
drop policy if exists "Members can update chores" on public.chores;
create policy "Members can update chores"
  on public.chores for update
  using (household_id in (
    select household_id from public.household_members where user_id = auth.uid()
  ))
  with check (household_id in (
    select household_id from public.household_members where user_id = auth.uid()
  ));

-- Insert completion only for self.
drop policy if exists "Members can create completions" on public.chore_completions;
create policy "Members can create completions"
  on public.chore_completions for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and chore_id in (
      select id from public.chores where household_id in (
        select household_id from public.household_members where user_id = auth.uid()
      )
    )
  );

-- Delete completion only for self.
drop policy if exists "Members can delete completions" on public.chore_completions;
create policy "Members can delete completions"
  on public.chore_completions for delete
  using (
    user_id = auth.uid()
    and chore_id in (
      select id from public.chores where household_id in (
        select household_id from public.household_members where user_id = auth.uid()
      )
    )
  );

-- Insert goals only for self.
drop policy if exists "Members can create savings goals" on public.savings_goals;
create policy "Members can create savings goals"
  on public.savings_goals for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and household_id in (
      select household_id from public.household_members where user_id = auth.uid()
    )
  );

-- Prevent ownership/household changes on goal UPDATE.
drop policy if exists "Members can update savings goals" on public.savings_goals;
create policy "Members can update savings goals"
  on public.savings_goals for update
  using (household_id in (
    select household_id from public.household_members where user_id = auth.uid()
  ))
  with check (
    user_id = auth.uid()
    and household_id in (
      select household_id from public.household_members where user_id = auth.uid()
    )
  );

-- Insert contributions only for self.
drop policy if exists "Members can create contributions" on public.savings_contributions;
create policy "Members can create contributions"
  on public.savings_contributions for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and goal_id in (
      select id from public.savings_goals where household_id in (
        select household_id from public.household_members where user_id = auth.uid()
      )
    )
  );

-- Delete contributions only for self.
drop policy if exists "Members can delete contributions" on public.savings_contributions;
create policy "Members can delete contributions"
  on public.savings_contributions for delete
  using (
    user_id = auth.uid()
    and goal_id in (
      select id from public.savings_goals where household_id in (
        select household_id from public.household_members where user_id = auth.uid()
      )
    )
  );

-- Allow one completion per user per chore per day.
do $$
begin
  if exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'chore_completions'
      and c.conname = 'chore_completions_chore_id_date_key'
  ) then
    alter table public.chore_completions
      drop constraint chore_completions_chore_id_date_key;
  end if;

  if not exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'chore_completions'
      and c.conname = 'chore_completions_chore_id_user_id_date_key'
  ) then
    alter table public.chore_completions
      add constraint chore_completions_chore_id_user_id_date_key
      unique (chore_id, user_id, date);
  end if;
end
$$;

commit;
