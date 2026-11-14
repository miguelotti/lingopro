-- CRM schema and governance for LingoPro
create extension if not exists "pgcrypto";

create table if not exists public.kanban_stages (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null,
  stage_key text not null,
  position integer not null default 0,
  sla_hours integer default 24,
  is_terminal boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, stage_key),
  unique (organization_id, position)
);

create table if not exists public.leads (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  stage_id uuid not null references public.kanban_stages(id) on delete restrict,
  owner_user_id uuid references auth.users(id) on delete set null,
  student_name text not null,
  student_age integer,
  course_interest text,
  guardian_name text,
  guardian_phone text,
  email text,
  source text not null default 'manual',
  status text not null default 'active' check (status in ('active', 'lost', 'dormant')),
  loss_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_interaction_at timestamptz,
  last_moved_at timestamptz,
  dormant_at timestamptz
);

create table if not exists public.lead_stage_history (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  lead_id uuid not null references public.leads(id) on delete cascade,
  from_stage_id uuid references public.kanban_stages(id),
  to_stage_id uuid not null references public.kanban_stages(id),
  changed_by uuid not null references auth.users(id) on delete cascade,
  changed_at timestamptz not null default now(),
  note text
);

create table if not exists public.lead_interactions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  lead_id uuid not null references public.leads(id) on delete cascade,
  created_by uuid references auth.users(id) on delete set null,
  channel text not null check (channel in ('whatsapp', 'manual', 'email', 'call')),
  direction text not null check (direction in ('inbound', 'outbound')),
  body text,
  provider_message_id text,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (organization_id, provider_message_id)
);

create index if not exists idx_kanban_stages_org_position on public.kanban_stages (organization_id, position);
create index if not exists idx_leads_org_stage on public.leads (organization_id, stage_id);
create index if not exists idx_leads_org_owner on public.leads (organization_id, owner_user_id);
create index if not exists idx_lead_interactions_lead_on_date on public.lead_interactions (lead_id, occurred_at desc);

alter table public.kanban_stages enable row level security;
alter table public.leads enable row level security;
alter table public.lead_stage_history enable row level security;
alter table public.lead_interactions enable row level security;

create policy "Managers can manage stages" on public.kanban_stages
for all
to authenticated
using (public.user_has_role_in_org(organization_id, 'manager'))
with check (public.user_has_role_in_org(organization_id, 'manager'));

create policy "Members can read stages in organization" on public.kanban_stages
for select
to authenticated
using (
  organization_id in (select organization_id from public.current_user_organization_ids())
);

create policy "Manager and sales can read leads" on public.leads
for select
to authenticated
using (
  organization_id in (select organization_id from public.current_user_organization_ids())
  and (
    public.user_has_role_in_org(organization_id, 'manager')
    or public.user_has_role_in_org(organization_id, 'sales')
    or owner_user_id = auth.uid()
  )
);

create policy "Managers and sales can manage leads" on public.leads
for insert
to authenticated
with check (
  organization_id in (select organization_id from public.current_user_organization_ids())
  and (
    public.user_has_role_in_org(organization_id, 'manager')
    or public.user_has_role_in_org(organization_id, 'sales')
  )
);

create policy "Managers and sales can update leads" on public.leads
for update
to authenticated
using (
  organization_id in (select organization_id from public.current_user_organization_ids())
  and (
    public.user_has_role_in_org(organization_id, 'manager')
    or public.user_has_role_in_org(organization_id, 'sales')
    or owner_user_id = auth.uid()
  )
)
with check (
  organization_id in (select organization_id from public.current_user_organization_ids())
  and (
    public.user_has_role_in_org(organization_id, 'manager')
    or public.user_has_role_in_org(organization_id, 'sales')
    or owner_user_id = auth.uid()
  )
);

create policy "Managers and sales can read lead history" on public.lead_stage_history
for select
to authenticated
using (
  organization_id in (select organization_id from public.current_user_organization_ids())
  and (
    public.user_has_role_in_org(organization_id, 'manager')
    or public.user_has_role_in_org(organization_id, 'sales')
    or exists (
      select 1 from public.leads l
      where l.id = lead_stage_history.lead_id
        and l.owner_user_id = auth.uid()
    )
  )
);

create policy "Managers and sales can write lead history" on public.lead_stage_history
for insert
to authenticated
with check (
  organization_id in (select organization_id from public.current_user_organization_ids())
  and (
    public.user_has_role_in_org(organization_id, 'manager')
    or public.user_has_role_in_org(organization_id, 'sales')
  )
);

create policy "Members can read lead interactions in organization" on public.lead_interactions
for select
to authenticated
using (
  organization_id in (select organization_id from public.current_user_organization_ids())
  and (
    public.user_has_role_in_org(organization_id, 'manager')
    or public.user_has_role_in_org(organization_id, 'sales')
    or exists (
      select 1 from public.leads l
      where l.id = lead_interactions.lead_id
        and l.owner_user_id = auth.uid()
    )
  )
);

create policy "Managers and sales can insert interactions" on public.lead_interactions
for insert
to authenticated
with check (
  organization_id in (select organization_id from public.current_user_organization_ids())
  and (
    public.user_has_role_in_org(organization_id, 'manager')
    or public.user_has_role_in_org(organization_id, 'sales')
  )
);

create trigger set_leads_updated_at
before update on public.leads
for each row execute procedure public.update_updated_at_column();

create trigger set_kanban_stages_updated_at
before update on public.kanban_stages
for each row execute procedure public.update_updated_at_column();

create trigger set_lead_interactions_updated_at
before update on public.lead_interactions
for each row execute procedure public.update_updated_at_column();

create trigger set_lead_stage_history_updated_at
before update on public.lead_stage_history
for each row execute procedure public.update_updated_at_column();
