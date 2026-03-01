-- Chorin' Database Schema
-- Run this in the Supabase SQL Editor to set up your database

-- ============================================
-- TABLES
-- ============================================

create table households (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  invite_code text unique not null default substr(md5(random()::text), 1, 6),
  created_at timestamptz not null default now()
);

create table household_members (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('parent', 'child')),
  created_at timestamptz not null default now(),
  unique (household_id, user_id)
);

create table chores (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  created_by_user_id uuid references auth.users(id) on delete set null,
  name text not null,
  value numeric(10,2) not null default 0,
  icon text not null default '✅',
  validation_status text not null default 'pending' check (validation_status in ('pending', 'valid', 'invalid')),
  validated_by_user_id uuid references auth.users(id) on delete set null,
  validated_at timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table chore_assignments (
  id uuid primary key default gen_random_uuid(),
  chore_id uuid not null references chores(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (chore_id, user_id)
);

create table chore_completions (
  id uuid primary key default gen_random_uuid(),
  chore_id uuid not null references chores(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  date date not null default current_date,
  earned_amount numeric(10,2) not null check (earned_amount > 0),
  created_at timestamptz not null default now(),
  unique (chore_id, user_id, date)
);

-- ============================================
-- INDEXES
-- ============================================

create index idx_household_members_user on household_members(user_id);
create index idx_household_members_household on household_members(household_id);
create index idx_chores_household on chores(household_id);
create index idx_chore_assignments_chore on chore_assignments(chore_id);
create index idx_chore_assignments_user on chore_assignments(user_id);
create index idx_chore_completions_chore on chore_completions(chore_id);
create index idx_chore_completions_date on chore_completions(date);
create index idx_households_invite_code on households(invite_code);

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

alter table households enable row level security;
alter table household_members enable row level security;
alter table chores enable row level security;
alter table chore_assignments enable row level security;
alter table chore_completions enable row level security;

-- Households: members can read their own household
create policy "Members can view their household"
  on households for select
  using (id in (
    select household_id from household_members where user_id = auth.uid()
  ));

-- Households: anyone authenticated can insert (for creating new ones)
create policy "Authenticated users can create households"
  on households for insert
  to authenticated
  with check (true);

-- Invite-code lookup should be done through a dedicated RPC, not broad table select.
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

-- Atomic household creation + initial parent membership
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
  v_household households%rowtype;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  v_name := left(trim(coalesce(p_household_name, '')), 50);
  if v_name = '' then
    v_name := 'My Family';
  end if;

  insert into households (name)
  values (v_name)
  returning * into v_household;

  insert into household_members (household_id, user_id, role)
  values (v_household.id, v_user_id, 'parent');

  return query
  select v_household.id, v_household.name, v_household.invite_code, v_household.created_at;
end;
$$;

revoke all on function public.create_household_with_parent(text) from public;
grant execute on function public.create_household_with_parent(text) to authenticated;

-- Atomic completion toggle + auto-savings contributions
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
  from chores c
  where c.id = p_chore_id
    and c.is_active = true
    and exists (
      select 1
      from household_members hm
      where hm.household_id = c.household_id
        and hm.user_id = v_user_id
    );

  if not found then
    raise exception 'Chore not found or access denied';
  end if;

  select cc.id
    into v_existing_completion_id
  from chore_completions cc
  where cc.chore_id = v_chore.id
    and cc.user_id = v_user_id
    and cc.date = v_effective_date
  limit 1;

  if v_existing_completion_id is not null then
    delete from chore_completions
    where id = v_existing_completion_id;

    return query select v_existing_completion_id, false;
    return;
  end if;

  insert into chore_completions (chore_id, user_id, date, earned_amount)
  values (v_chore.id, v_user_id, v_effective_date, v_chore.value)
  returning id into v_new_completion_id;

  insert into public.savings_contributions (goal_id, user_id, amount, source, completion_id)
  select
    sg.id,
    v_user_id,
    round((v_chore.value * sg.auto_percent::numeric) / 100, 2),
    'auto',
    v_new_completion_id
  from public.savings_goals sg
  where sg.household_id = v_chore.household_id
    and sg.is_active = true
    and sg.auto_percent > 0
    and round((v_chore.value * sg.auto_percent::numeric) / 100, 2) > 0;

  return query select v_new_completion_id, true;
end;
$$;

revoke all on function public.toggle_chore_completion(uuid, date) from public;
grant execute on function public.toggle_chore_completion(uuid, date) to authenticated;

-- Assignment-aware chores list for the current user and day.
create or replace function public.get_todays_chores_for_current_user(
  p_date date default current_date
)
returns table (
  id uuid,
  household_id uuid,
  created_by_user_id uuid,
  name text,
  value numeric(10,2),
  icon text,
  validation_status text,
  validated_by_user_id uuid,
  validated_at timestamptz,
  is_active boolean,
  created_at timestamptz,
  completed_today boolean,
  today_completion_id uuid
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_household_id uuid;
  v_role text;
  v_effective_date date := coalesce(p_date, current_date);
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select hm.household_id, hm.role
    into v_household_id, v_role
  from public.household_members hm
  where hm.user_id = v_user_id
  limit 1;

  if not found then
    return;
  end if;

  return query
  select
    c.id,
    c.household_id,
    c.created_by_user_id,
    c.name,
    c.value,
    c.icon,
    c.validation_status,
    c.validated_by_user_id,
    c.validated_at,
    c.is_active,
    c.created_at,
    (cc.id is not null) as completed_today,
    cc.id as today_completion_id
  from public.chores c
  left join public.chore_completions cc
    on cc.chore_id = c.id
   and cc.user_id = v_user_id
   and cc.date = v_effective_date
  where c.household_id = v_household_id
    and c.is_active = true
    and (
      v_role = 'parent'
      or exists (
        select 1
        from public.chore_assignments ca
        where ca.chore_id = c.id
          and ca.user_id = v_user_id
      )
    )
  order by c.created_at asc;
end;
$$;

revoke all on function public.get_todays_chores_for_current_user(date) from public;
grant execute on function public.get_todays_chores_for_current_user(date) to authenticated;

-- Keep audit fields consistent when validation status changes.
create or replace function public.apply_chore_validation_audit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.validation_status is distinct from old.validation_status then
    if new.validation_status = 'pending' then
      new.validated_by_user_id := null;
      new.validated_at := null;
    else
      new.validated_by_user_id := coalesce(auth.uid(), new.validated_by_user_id);
      new.validated_at := now();
    end if;
  end if;

  return new;
end;
$$;

create trigger apply_chore_validation_audit
before update on public.chores
for each row
execute function public.apply_chore_validation_audit();

-- Ensure creator is always tracked when inserting chores.
create or replace function public.set_chore_created_by_default()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.created_by_user_id is null then
    new.created_by_user_id := auth.uid();
  end if;

  return new;
end;
$$;

create trigger set_chore_created_by_default
before insert on public.chores
for each row
execute function public.set_chore_created_by_default();

-- Auto-assign child-created chores to the creating child.
create or replace function public.auto_assign_child_created_chore()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.created_by_user_id is null then
    return new;
  end if;

  if exists (
    select 1
    from public.household_members hm
    where hm.household_id = new.household_id
      and hm.user_id = new.created_by_user_id
      and hm.role = 'child'
  ) then
    insert into public.chore_assignments (chore_id, user_id)
    values (new.id, new.created_by_user_id)
    on conflict (chore_id, user_id) do nothing;
  end if;

  return new;
end;
$$;

create trigger auto_assign_child_created_chore
after insert on public.chores
for each row
execute function public.auto_assign_child_created_chore();

-- SECURITY DEFINER helpers to avoid recursive RLS on household_members policies.
create or replace function public.is_member_of_household(p_household_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.household_members hm
    where hm.household_id = p_household_id
      and hm.user_id = auth.uid()
  );
$$;

create or replace function public.household_has_members(p_household_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.household_members hm
    where hm.household_id = p_household_id
  );
$$;

revoke all on function public.is_member_of_household(uuid) from public;
grant execute on function public.is_member_of_household(uuid) to authenticated;

revoke all on function public.household_has_members(uuid) from public;
grant execute on function public.household_has_members(uuid) to authenticated;

-- Household members: members can read their household's members
create policy "Members can view household members"
  on household_members for select
  using (public.is_member_of_household(household_id));

-- Household members: authenticated users can insert themselves
create policy "Users can join households"
  on household_members for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and role = 'child'
  );

-- Household creators can add themselves as the first parent member
create policy "Users can create initial parent membership"
  on household_members for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and role = 'parent'
    and not public.household_has_members(household_id)
  );

-- Chores: members can read their household's chores
create policy "Members can view chores"
  on chores for select
  using (household_id in (
    select household_id from household_members where user_id = auth.uid()
  ));

-- Chores: parents can insert chores to their household
create policy "Parents can create chores"
  on chores for insert
  to authenticated
  with check (
    household_id in (
      select household_id
      from household_members
      where user_id = auth.uid()
        and role = 'parent'
    )
    and (
      created_by_user_id is null
      or created_by_user_id in (
        select hm.user_id
        from household_members hm
        where hm.household_id = chores.household_id
      )
    )
  );

-- Chores: children can create chores for themselves in their household
create policy "Children can create chores"
  on chores for insert
  to authenticated
  with check (
    household_id in (
      select household_id
      from household_members
      where user_id = auth.uid()
        and role = 'child'
    )
    and coalesce(created_by_user_id, auth.uid()) = auth.uid()
    and validation_status = 'pending'
    and validated_by_user_id is null
    and validated_at is null
  );

-- Chores: parents can update chores in their household (including validation)
create policy "Parents can update chores"
  on chores for update
  using (household_id in (
    select household_id
    from household_members
    where user_id = auth.uid()
      and role = 'parent'
  ))
  with check (household_id in (
    select household_id
    from household_members
    where user_id = auth.uid()
      and role = 'parent'
  ));

-- Chore assignments: members can read assignment rows in their household
create policy "Members can view chore assignments"
  on chore_assignments for select
  using (chore_id in (
    select c.id
    from chores c
    where c.household_id in (
      select household_id from household_members where user_id = auth.uid()
    )
  ));

-- Chore assignments: only parents can assign children
create policy "Parents can create chore assignments"
  on chore_assignments for insert
  to authenticated
  with check (
    chore_id in (
      select c.id
      from chores c
      join household_members hm_parent
        on hm_parent.household_id = c.household_id
      where hm_parent.user_id = auth.uid()
        and hm_parent.role = 'parent'
    )
    and exists (
      select 1
      from household_members hm_child
      join chores c
        on c.household_id = hm_child.household_id
      where c.id = chore_assignments.chore_id
        and hm_child.user_id = chore_assignments.user_id
        and hm_child.role = 'child'
    )
  );

-- Chore assignments: only parents can unassign children
create policy "Parents can delete chore assignments"
  on chore_assignments for delete
  using (
    exists (
      select 1
      from chores c
      join household_members hm_parent
        on hm_parent.household_id = c.household_id
      where c.id = chore_assignments.chore_id
        and hm_parent.user_id = auth.uid()
        and hm_parent.role = 'parent'
    )
  );

-- Completions: members can read completions for their household's chores
create policy "Members can view completions"
  on chore_completions for select
  using (chore_id in (
    select id from chores where household_id in (
      select household_id from household_members where user_id = auth.uid()
    )
  ));

-- Completions: members can insert completions
create policy "Members can create completions"
  on chore_completions for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and chore_id in (
      select id from chores where household_id in (
        select household_id from household_members where user_id = auth.uid()
      )
    )
  );

-- Completions: members can delete their own completions
create policy "Members can delete completions"
  on chore_completions for delete
  using (
    user_id = auth.uid()
    and chore_id in (
      select id from chores where household_id in (
        select household_id from household_members where user_id = auth.uid()
      )
    )
  );

-- ============================================
-- ENABLE REALTIME
-- ============================================

alter publication supabase_realtime add table chore_completions;
alter publication supabase_realtime add table chores;
alter publication supabase_realtime add table chore_assignments;

-- ============================================
-- SAVINGS GOALS
-- ============================================

create table savings_goals (
  id            uuid primary key default gen_random_uuid(),
  household_id  uuid not null references households(id) on delete cascade,
  user_id       uuid not null references auth.users(id) on delete cascade,
  name          text not null,
  target_amount numeric(10,2) not null,
  icon          text not null default '🎯',
  auto_percent  integer not null default 0 check (auto_percent >= 0 and auto_percent <= 100),
  is_active     boolean not null default true,
  created_at    timestamptz not null default now()
);

create table savings_contributions (
  id            uuid primary key default gen_random_uuid(),
  goal_id       uuid not null references savings_goals(id) on delete cascade,
  user_id       uuid not null references auth.users(id) on delete cascade,
  amount        numeric(10,2) not null check (amount > 0),
  source        text not null check (source in ('auto', 'manual')),
  completion_id uuid references chore_completions(id) on delete cascade,
  created_at    timestamptz not null default now()
);

create index idx_savings_goals_household on savings_goals(household_id);
create index idx_savings_contributions_goal on savings_contributions(goal_id);
create index idx_savings_contributions_completion on savings_contributions(completion_id);

alter table savings_goals enable row level security;
alter table savings_contributions enable row level security;

create policy "Members can view savings goals"
  on savings_goals for select
  using (household_id in (
    select household_id from household_members where user_id = auth.uid()
  ));

create policy "Members can create savings goals"
  on savings_goals for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and household_id in (
      select household_id from household_members where user_id = auth.uid()
    )
  );

create policy "Members can update savings goals"
  on savings_goals for update
  using (household_id in (
    select household_id from household_members where user_id = auth.uid()
  ))
  with check (
    user_id = auth.uid()
    and household_id in (
      select household_id from household_members where user_id = auth.uid()
    )
  ));

create policy "Members can view contributions"
  on savings_contributions for select
  using (goal_id in (
    select id from savings_goals where household_id in (
      select household_id from household_members where user_id = auth.uid()
    )
  ));

create policy "Members can create contributions"
  on savings_contributions for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and goal_id in (
      select id from savings_goals where household_id in (
        select household_id from household_members where user_id = auth.uid()
      )
    )
  );

create policy "Members can delete contributions"
  on savings_contributions for delete
  using (
    user_id = auth.uid()
    and goal_id in (
      select id from savings_goals where household_id in (
        select household_id from household_members where user_id = auth.uid()
      )
    )
  );

alter publication supabase_realtime add table savings_goals;
alter publication supabase_realtime add table savings_contributions;
