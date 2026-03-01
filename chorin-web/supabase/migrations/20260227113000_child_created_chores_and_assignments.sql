begin;

-- Chore ownership + validation metadata.
alter table public.chores
  add column if not exists created_by_user_id uuid references auth.users(id) on delete set null;

alter table public.chores
  add column if not exists validation_status text not null default 'pending';

alter table public.chores
  add column if not exists validated_by_user_id uuid references auth.users(id) on delete set null;

alter table public.chores
  add column if not exists validated_at timestamptz;

do $$
begin
  if not exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'chores'
      and c.conname = 'chores_validation_status_check'
  ) then
    alter table public.chores
      add constraint chores_validation_status_check
      check (validation_status in ('pending', 'valid', 'invalid')) not valid;
  end if;
end
$$;

alter table public.chores
  validate constraint chores_validation_status_check;

-- Assignment model.
create table if not exists public.chore_assignments (
  id uuid primary key default gen_random_uuid(),
  chore_id uuid not null references public.chores(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (chore_id, user_id)
);

do $$
begin
  if not exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'chore_assignments'
      and c.conname = 'chore_assignments_chore_id_user_id_key'
  ) then
    alter table public.chore_assignments
      add constraint chore_assignments_chore_id_user_id_key
      unique (chore_id, user_id);
  end if;
end
$$;

create index if not exists idx_chore_assignments_chore on public.chore_assignments(chore_id);
create index if not exists idx_chore_assignments_user on public.chore_assignments(user_id);

alter table public.chore_assignments enable row level security;

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

drop trigger if exists apply_chore_validation_audit on public.chores;
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

drop trigger if exists set_chore_created_by_default on public.chores;
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

drop trigger if exists auto_assign_child_created_chore on public.chores;
create trigger auto_assign_child_created_chore
after insert on public.chores
for each row
execute function public.auto_assign_child_created_chore();

-- Chores RLS: allow both parent and child creation flows.
drop policy if exists "Members can create chores" on public.chores;
drop policy if exists "Parents can create chores" on public.chores;
create policy "Parents can create chores"
  on public.chores for insert
  to authenticated
  with check (
    household_id in (
      select hm.household_id
      from public.household_members hm
      where hm.user_id = auth.uid()
        and hm.role = 'parent'
    )
    and (
      created_by_user_id is null
      or created_by_user_id in (
        select hm.user_id
        from public.household_members hm
        where hm.household_id = chores.household_id
      )
    )
  );

drop policy if exists "Children can create chores" on public.chores;
create policy "Children can create chores"
  on public.chores for insert
  to authenticated
  with check (
    household_id in (
      select hm.household_id
      from public.household_members hm
      where hm.user_id = auth.uid()
        and hm.role = 'child'
    )
    and coalesce(created_by_user_id, auth.uid()) = auth.uid()
    and validation_status = 'pending'
    and validated_by_user_id is null
    and validated_at is null
  );

drop policy if exists "Members can update chores" on public.chores;
drop policy if exists "Parents can update chores" on public.chores;
create policy "Parents can update chores"
  on public.chores for update
  using (
    household_id in (
      select hm.household_id
      from public.household_members hm
      where hm.user_id = auth.uid()
        and hm.role = 'parent'
    )
  )
  with check (
    household_id in (
      select hm.household_id
      from public.household_members hm
      where hm.user_id = auth.uid()
        and hm.role = 'parent'
    )
  );

-- Chore assignment RLS: members can read, parents manage.
drop policy if exists "Members can view chore assignments" on public.chore_assignments;
create policy "Members can view chore assignments"
  on public.chore_assignments for select
  using (
    chore_id in (
      select c.id
      from public.chores c
      where c.household_id in (
        select hm.household_id
        from public.household_members hm
        where hm.user_id = auth.uid()
      )
    )
  );

drop policy if exists "Parents can create chore assignments" on public.chore_assignments;
create policy "Parents can create chore assignments"
  on public.chore_assignments for insert
  to authenticated
  with check (
    chore_id in (
      select c.id
      from public.chores c
      join public.household_members hm_parent
        on hm_parent.household_id = c.household_id
      where hm_parent.user_id = auth.uid()
        and hm_parent.role = 'parent'
    )
    and exists (
      select 1
      from public.household_members hm_child
      join public.chores c
        on c.household_id = hm_child.household_id
      where c.id = chore_assignments.chore_id
        and hm_child.user_id = chore_assignments.user_id
        and hm_child.role = 'child'
    )
  );

drop policy if exists "Parents can delete chore assignments" on public.chore_assignments;
create policy "Parents can delete chore assignments"
  on public.chore_assignments for delete
  using (
    exists (
      select 1
      from public.chores c
      join public.household_members hm_parent
        on hm_parent.household_id = c.household_id
      where c.id = chore_assignments.chore_id
        and hm_parent.user_id = auth.uid()
        and hm_parent.role = 'parent'
    )
  );

-- Backfill creator and assignments for existing data.
update public.chores c
set created_by_user_id = (
  select hm.user_id
  from public.household_members hm
  where hm.household_id = c.household_id
  order by case hm.role when 'parent' then 0 else 1 end, hm.created_at
  limit 1
)
where c.created_by_user_id is null;

insert into public.chore_assignments (chore_id, user_id)
select c.id, hm.user_id
from public.chores c
join public.household_members hm
  on hm.household_id = c.household_id
where c.is_active = true
  and hm.role = 'child'
on conflict (chore_id, user_id) do nothing;

do $$
begin
  if exists (
    select 1
    from pg_publication p
    where p.pubname = 'supabase_realtime'
  ) and not exists (
    select 1
    from pg_publication_tables pt
    where pt.pubname = 'supabase_realtime'
      and pt.schemaname = 'public'
      and pt.tablename = 'chore_assignments'
  ) then
    alter publication supabase_realtime add table public.chore_assignments;
  end if;
end
$$;

commit;
