begin;

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

drop policy if exists "Members can view household members" on public.household_members;
create policy "Members can view household members"
  on public.household_members for select
  using (public.is_member_of_household(household_id));

drop policy if exists "Users can create initial parent membership" on public.household_members;
create policy "Users can create initial parent membership"
  on public.household_members for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and role = 'parent'
    and not public.household_has_members(household_id)
  );

commit;
