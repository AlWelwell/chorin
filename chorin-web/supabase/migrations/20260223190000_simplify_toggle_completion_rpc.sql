begin;

-- Savings tables now exist in all environments, so keep this path static.
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

  insert into public.savings_contributions (
    goal_id,
    user_id,
    amount,
    source,
    completion_id
  )
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

commit;
