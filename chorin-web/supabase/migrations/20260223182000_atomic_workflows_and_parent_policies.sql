begin;

-- Enforce positive money amounts for new writes.
do $$
begin
  if not exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'chore_completions'
      and c.conname = 'chore_completions_earned_amount_positive'
  ) then
    alter table public.chore_completions
      add constraint chore_completions_earned_amount_positive
      check (earned_amount > 0) not valid;
  end if;

  if to_regclass('public.savings_contributions') is not null
     and not exists (
       select 1
       from pg_constraint c
       join pg_class t on t.oid = c.conrelid
       join pg_namespace n on n.oid = t.relnamespace
       where n.nspname = 'public'
         and t.relname = 'savings_contributions'
         and c.conname = 'savings_contributions_amount_positive'
     ) then
    alter table public.savings_contributions
    add constraint savings_contributions_amount_positive
    check (amount > 0) not valid;
  end if;
end
$$;

-- Parent-only chore management.
drop policy if exists "Members can create chores" on public.chores;
drop policy if exists "Parents can create chores" on public.chores;
create policy "Parents can create chores"
  on public.chores for insert
  to authenticated
  with check (household_id in (
    select household_id
    from public.household_members
    where user_id = auth.uid()
      and role = 'parent'
  ));

drop policy if exists "Members can update chores" on public.chores;
drop policy if exists "Parents can update chores" on public.chores;
create policy "Parents can update chores"
  on public.chores for update
  using (household_id in (
    select household_id
    from public.household_members
    where user_id = auth.uid()
      and role = 'parent'
  ))
  with check (household_id in (
    select household_id
    from public.household_members
    where user_id = auth.uid()
      and role = 'parent'
  ));

-- Atomic household create + parent membership.
create or replace function public.create_household_with_parent(p_household_name text default null)
returns table (
  id uuid,
  name text,
  invite_code text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_name text;
  v_household public.households%rowtype;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  v_name := left(trim(coalesce(p_household_name, '')), 50);
  if v_name = '' then
    v_name := 'My Family';
  end if;

  insert into public.households (name)
  values (v_name)
  returning * into v_household;

  insert into public.household_members (household_id, user_id, role)
  values (v_household.id, v_user_id, 'parent');

  return query
  select v_household.id, v_household.name, v_household.invite_code, v_household.created_at;
end;
$$;

revoke all on function public.create_household_with_parent(text) from public;
grant execute on function public.create_household_with_parent(text) to authenticated;

-- Atomic completion toggle + auto-contributions.
create or replace function public.toggle_chore_completion(
  p_chore_id uuid,
  p_date date default current_date
)
returns table (
  completion_id uuid,
  is_completed boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_effective_date date := coalesce(p_date, current_date);
  v_existing_completion_id uuid;
  v_new_completion_id uuid;
  v_chore record;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select c.id, c.household_id, c.value
    into v_chore
  from public.chores c
  where c.id = p_chore_id
    and c.is_active = true
    and exists (
      select 1
      from public.household_members hm
      where hm.household_id = c.household_id
        and hm.user_id = v_user_id
    );

  if not found then
    raise exception 'Chore not found or access denied';
  end if;

  select cc.id
    into v_existing_completion_id
  from public.chore_completions cc
  where cc.chore_id = v_chore.id
    and cc.user_id = v_user_id
    and cc.date = v_effective_date
  limit 1;

  if v_existing_completion_id is not null then
    delete from public.chore_completions
    where id = v_existing_completion_id;

    return query select v_existing_completion_id, false;
    return;
  end if;

  insert into public.chore_completions (chore_id, user_id, date, earned_amount)
  values (v_chore.id, v_user_id, v_effective_date, v_chore.value)
  returning id into v_new_completion_id;

  if to_regclass('public.savings_goals') is not null
     and to_regclass('public.savings_contributions') is not null then
    execute $sql$
      insert into public.savings_contributions (
        goal_id,
        user_id,
        amount,
        source,
        completion_id
      )
      select
        sg.id,
        $1,
        round(($2 * sg.auto_percent::numeric) / 100, 2),
        'auto',
        $3
      from public.savings_goals sg
      where sg.household_id = $4
        and sg.is_active = true
        and sg.auto_percent > 0
        and round(($2 * sg.auto_percent::numeric) / 100, 2) > 0
    $sql$
    using v_user_id, v_chore.value, v_new_completion_id, v_chore.household_id;
  end if;

  return query select v_new_completion_id, true;
end;
$$;

revoke all on function public.toggle_chore_completion(uuid, date) from public;
grant execute on function public.toggle_chore_completion(uuid, date) to authenticated;

commit;
