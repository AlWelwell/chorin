begin;

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

commit;
