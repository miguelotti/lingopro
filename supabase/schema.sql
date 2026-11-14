-- =====================================================
-- LingoPro Supabase Schema
-- Role-based authorization by organization and profile.
-- =====================================================

create extension if not exists "pgcrypto";

-- Organizations / tenants
create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  timezone text not null default 'America/Sao_Paulo',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Public profile for authenticated users.
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  email text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Organization membership is the source of truth for app roles.
create table if not exists public.organization_memberships (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('manager', 'teacher', 'student', 'sales')),
  status text not null default 'active' check (status in ('active', 'invited', 'disabled')),
  invited_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, user_id)
);

-- Optional: track audit events for privileged changes.
create table if not exists public.audit_log (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  actor_user_id uuid not null references auth.users(id) on delete cascade,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- ==========================
-- Helper functions for access
-- ==========================

create or replace function public.current_user_organization_ids()
returns setof uuid
language sql
security definer
set search_path = public
as $$
  select organization_id
  from public.organization_memberships
  where user_id = auth.uid()
    and status = 'active';
$$;

create or replace function public.user_has_role_in_org(p_org_id uuid, p_role text)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.organization_memberships
    where user_id = auth.uid()
      and organization_id = p_org_id
      and status = 'active'
      and role = p_role
  );
$$;

-- ==========================
-- Trigger to auto-create profile
-- ==========================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1)),
    new.email
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

create or replace trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- ==========================
-- Update timestamp trigger
-- ==========================

create or replace function public.update_updated_at_column()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger organizations_updated_at
before update on public.organizations
for each row execute procedure public.update_updated_at_column();

create trigger profiles_updated_at
before update on public.profiles
for each row execute procedure public.update_updated_at_column();

create trigger memberships_updated_at
before update on public.organization_memberships
for each row execute procedure public.update_updated_at_column();

-- ==========================
-- Row Level Security
-- ==========================

alter table public.organizations enable row level security;
alter table public.profiles enable row level security;
alter table public.organization_memberships enable row level security;
alter table public.audit_log enable row level security;

-- Organizations: members can view organization they belong to.
create policy "Organizations visible to members"
on public.organizations
for select
using (
  exists (
    select 1
    from public.organization_memberships om
    where om.organization_id = organizations.id
      and om.user_id = auth.uid()
      and om.status = 'active'
  )
);

create policy "Managers can update organization"
on public.organizations
for update
using (
  public.user_has_role_in_org(organizations.id, 'manager')
)
with check (
  public.user_has_role_in_org(organizations.id, 'manager')
);

-- Profiles: users can read their own profile and profiles in same org.
create policy "Users can view own profile"
on public.profiles
for select
using (auth.uid() = id);

create policy "Users can view profiles in same organization"
on public.profiles
for select
using (
  exists (
    select 1
    from public.organization_memberships om_self
    where om_self.user_id = auth.uid()
      and om_self.status = 'active'
      and exists (
        select 1
        from public.organization_memberships om_target
        where om_target.user_id = profiles.id
          and om_target.status = 'active'
          and om_target.organization_id = om_self.organization_id
      )
  )
);

create policy "Users can update own profile"
on public.profiles
for update
using (auth.uid() = id)
with check (auth.uid() = id);

create policy "Users can insert own profile"
on public.profiles
for insert
with check (auth.uid() = id);

-- Memberships: members can view memberships in same org.
create policy "Members can view memberships in same org"
on public.organization_memberships
for select
using (
  exists (
    select 1
    from public.organization_memberships om
    where om.user_id = auth.uid()
      and om.organization_id = organization_memberships.organization_id
      and om.status = 'active'
  )
);

create policy "Managers can manage memberships in organization"
on public.organization_memberships
for insert
with check (
  public.user_has_role_in_org(organization_id, 'manager')
);

create policy "Managers can update memberships in organization"
on public.organization_memberships
for update
using (
  public.user_has_role_in_org(organization_id, 'manager')
)
with check (
  public.user_has_role_in_org(organization_id, 'manager')
);

create policy "Managers can delete memberships in organization"
on public.organization_memberships
for delete
using (
  public.user_has_role_in_org(organization_id, 'manager')
);

-- Audit log: only managers can read and write in their org.
create policy "Managers can read audit log"
on public.audit_log
for select
using (
  public.user_has_role_in_org(organization_id, 'manager')
);

create policy "Managers can insert audit log"
on public.audit_log
for insert
with check (
  public.user_has_role_in_org(organization_id, 'manager')
);

-- ==========================
-- Example seed data
-- ==========================
-- Only run this in local/staging if needed.
--
-- insert into public.organizations (name, slug)
-- values ('LingoPro', 'lingopro');
--
-- insert into public.organization_memberships (organization_id, user_id, role)
-- values (
--   (select id from public.organizations where slug = 'lingopro'),
--   'user-uuid-here',
--   'manager'
-- );

-- =====================================================
-- End of schema
-- =====================================================
