create or replace function public.get_current_memberships()
returns table (organization_id uuid, role text, status text)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select om.organization_id, om.role, om.status
  from public.organization_memberships as om
  where om.user_id = auth.uid()
    and om.status = 'active';
$$;

revoke all on function public.get_current_memberships() from public;
grant execute on function public.get_current_memberships() to authenticated;

-- Avoid recursive RLS evaluation when policies inspect memberships.
drop policy if exists "Organizations visible to members" on public.organizations;
create policy "Organizations visible to members"
on public.organizations
for select
to authenticated
using (
  id in (select organization_id from public.current_user_organization_ids())
);

drop policy if exists "Members can view memberships in same org" on public.organization_memberships;
create policy "Members can view memberships in same org"
on public.organization_memberships
for select
to authenticated
using (
  organization_id in (select organization_id from public.current_user_organization_ids())
);
