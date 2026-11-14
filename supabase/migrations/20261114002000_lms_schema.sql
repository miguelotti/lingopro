-- LMS schema and governance for LingoPro
create extension if not exists "pgcrypto";

create table if not exists public.courses (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  title text not null,
  description text,
  cover_asset_id uuid,
  status text not null default 'draft' check (status in ('draft', 'published', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.course_modules (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  title text not null,
  position integer not null default 0,
  created_at timestamptz not null default now(),
  unique (course_id, position)
);

create table if not exists public.lessons (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  module_id uuid not null references public.course_modules(id) on delete cascade,
  title text not null,
  description text,
  duration_seconds integer,
  position integer not null default 0,
  status text not null default 'draft' check (status in ('draft', 'published', 'archived')),
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (module_id, position)
);

create table if not exists public.course_enrollments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  student_user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'active' check (status in ('active', 'completed', 'cancelled')),
  enrolled_at timestamptz not null default now(),
  ended_at timestamptz,
  unique (organization_id, course_id, student_user_id)
);

create table if not exists public.course_teachers (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  teacher_user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (organization_id, course_id, teacher_user_id)
);

create table if not exists public.lesson_assets (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  asset_type text not null check (asset_type in ('video', 'slides', 'exercise', 'attachment')),
  storage_path text,
  youtube_video_id text,
  external_url text,
  status text not null default 'draft' check (status in ('draft', 'published', 'archived')),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.lesson_progress (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  student_user_id uuid not null references auth.users(id) on delete cascade,
  progress_seconds integer not null default 0,
  completed_at timestamptz,
  last_viewed_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, lesson_id, student_user_id)
);

create table if not exists public.assessments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  title text not null,
  status text not null default 'draft' check (status in ('draft', 'published', 'archived')),
  settings jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.assessment_attempts (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  assessment_id uuid not null references public.assessments(id) on delete cascade,
  student_user_id uuid not null references auth.users(id) on delete cascade,
  started_at timestamptz not null default now(),
  submitted_at timestamptz,
  score numeric(5,2),
  status text not null default 'in_progress' check (status in ('in_progress', 'submitted', 'graded', 'failed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.satisfaction_surveys (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  survey_type text not null check (survey_type in ('post_lesson', 'teacher_periodic')),
  lesson_id uuid references public.lessons(id) on delete cascade,
  starts_at timestamptz,
  ends_at timestamptz,
  status text not null default 'draft' check (status in ('draft', 'active', 'closed')),
  schema jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.satisfaction_responses (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  survey_id uuid not null references public.satisfaction_surveys(id) on delete cascade,
  respondent_user_id uuid not null references auth.users(id) on delete cascade,
  rating integer,
  comment text,
  submitted_at timestamptz not null default now(),
  unique (survey_id, respondent_user_id)
);

create index if not exists idx_courses_org_status on public.courses (organization_id, status, updated_at desc);
create index if not exists idx_enrollments_org_course on public.course_enrollments (organization_id, course_id, status);
create index if not exists idx_lesson_assets_lesson on public.lesson_assets (lesson_id, asset_type);
create index if not exists idx_lesson_progress_student on public.lesson_progress (student_user_id, completed_at);

alter table public.courses enable row level security;
alter table public.course_modules enable row level security;
alter table public.lessons enable row level security;
alter table public.course_enrollments enable row level security;
alter table public.course_teachers enable row level security;
alter table public.lesson_assets enable row level security;
alter table public.lesson_progress enable row level security;
alter table public.assessments enable row level security;
alter table public.assessment_attempts enable row level security;
alter table public.satisfaction_surveys enable row level security;
alter table public.satisfaction_responses enable row level security;

create policy "Members can read courses in organization" on public.courses
for select
to authenticated
using (
  organization_id in (select organization_id from public.current_user_organization_ids())
);

create policy "Managers and teachers can manage courses" on public.courses
for all
to authenticated
using (
  public.user_has_role_in_org(organization_id, 'manager')
  or public.user_has_role_in_org(organization_id, 'teacher')
)
with check (
  public.user_has_role_in_org(organization_id, 'manager')
  or public.user_has_role_in_org(organization_id, 'teacher')
);

create policy "Members can read modules for courses in org" on public.course_modules
for select
to authenticated
using (
  organization_id in (select organization_id from public.current_user_organization_ids())
);

create policy "Managers and teachers can manage modules" on public.course_modules
for all
to authenticated
using (
  public.user_has_role_in_org(organization_id, 'manager')
  or public.user_has_role_in_org(organization_id, 'teacher')
)
with check (
  public.user_has_role_in_org(organization_id, 'manager')
  or public.user_has_role_in_org(organization_id, 'teacher')
);

create policy "Members can read lessons in org" on public.lessons
for select
to authenticated
using (
  organization_id in (select organization_id from public.current_user_organization_ids())
);

create policy "Managers and teachers can manage lessons" on public.lessons
for all
to authenticated
using (
  public.user_has_role_in_org(organization_id, 'manager')
  or public.user_has_role_in_org(organization_id, 'teacher')
)
with check (
  public.user_has_role_in_org(organization_id, 'manager')
  or public.user_has_role_in_org(organization_id, 'teacher')
);

create policy "Students can read own enrollments" on public.course_enrollments
for select
to authenticated
using (
  organization_id in (select organization_id from public.current_user_organization_ids())
  and (
    student_user_id = auth.uid()
    or public.user_has_role_in_org(organization_id, 'manager')
    or public.user_has_role_in_org(organization_id, 'teacher')
  )
);

create policy "Managers and teachers can manage enrollments" on public.course_enrollments
for all
to authenticated
using (
  public.user_has_role_in_org(organization_id, 'manager')
  or public.user_has_role_in_org(organization_id, 'teacher')
)
with check (
  public.user_has_role_in_org(organization_id, 'manager')
  or public.user_has_role_in_org(organization_id, 'teacher')
);

create policy "Managers and teachers can read course teachers" on public.course_teachers
for select
to authenticated
using (
  organization_id in (select organization_id from public.current_user_organization_ids())
  and (
    teacher_user_id = auth.uid()
    or public.user_has_role_in_org(organization_id, 'manager')
  )
);

create policy "Managers and teachers can manage course teachers" on public.course_teachers
for all
to authenticated
using (
  public.user_has_role_in_org(organization_id, 'manager')
  or public.user_has_role_in_org(organization_id, 'teacher')
)
with check (
  public.user_has_role_in_org(organization_id, 'manager')
  or public.user_has_role_in_org(organization_id, 'teacher')
);

create policy "Students can read own lesson progress" on public.lesson_progress
for select
to authenticated
using (
  organization_id in (select organization_id from public.current_user_organization_ids())
  and (
    student_user_id = auth.uid()
    or public.user_has_role_in_org(organization_id, 'manager')
    or public.user_has_role_in_org(organization_id, 'teacher')
  )
);

create policy "Students can update own lesson progress" on public.lesson_progress
for insert
to authenticated
with check (
  organization_id in (select organization_id from public.current_user_organization_ids())
  and student_user_id = auth.uid()
);

create policy "Students can update own lesson progress records" on public.lesson_progress
for update
to authenticated
using (
  organization_id in (select organization_id from public.current_user_organization_ids())
  and student_user_id = auth.uid()
)
with check (
  organization_id in (select organization_id from public.current_user_organization_ids())
  and student_user_id = auth.uid()
);

create policy "Managers and teachers can read assessments in org" on public.assessments
for select
to authenticated
using (
  organization_id in (select organization_id from public.current_user_organization_ids())
  and (
    public.user_has_role_in_org(organization_id, 'manager')
    or public.user_has_role_in_org(organization_id, 'teacher')
    or public.user_has_role_in_org(organization_id, 'student')
  )
);

create policy "Managers and teachers can manage assessments" on public.assessments
for all
to authenticated
using (
  public.user_has_role_in_org(organization_id, 'manager')
  or public.user_has_role_in_org(organization_id, 'teacher')
)
with check (
  public.user_has_role_in_org(organization_id, 'manager')
  or public.user_has_role_in_org(organization_id, 'teacher')
);

create policy "Students can read their assessment attempts" on public.assessment_attempts
for select
to authenticated
using (
  organization_id in (select organization_id from public.current_user_organization_ids())
  and (
    student_user_id = auth.uid()
    or public.user_has_role_in_org(organization_id, 'manager')
    or public.user_has_role_in_org(organization_id, 'teacher')
  )
);

create policy "Managers and teachers can manage assessment attempts" on public.assessment_attempts
for all
to authenticated
using (
  public.user_has_role_in_org(organization_id, 'manager')
  or public.user_has_role_in_org(organization_id, 'teacher')
)
with check (
  public.user_has_role_in_org(organization_id, 'manager')
  or public.user_has_role_in_org(organization_id, 'teacher')
);

create trigger set_courses_updated_at
before update on public.courses
for each row execute procedure public.update_updated_at_column();

create trigger set_course_modules_updated_at
before update on public.course_modules
for each row execute procedure public.update_updated_at_column();

create trigger set_lessons_updated_at
before update on public.lessons
for each row execute procedure public.update_updated_at_column();

create trigger set_lesson_assets_updated_at
before update on public.lesson_assets
for each row execute procedure public.update_updated_at_column();

create trigger set_lesson_progress_updated_at
before update on public.lesson_progress
for each row execute procedure public.update_updated_at_column();

create trigger set_assessments_updated_at
before update on public.assessments
for each row execute procedure public.update_updated_at_column();

create trigger set_assessment_attempts_updated_at
before update on public.assessment_attempts
for each row execute procedure public.update_updated_at_column();

create trigger set_surveys_updated_at
before update on public.satisfaction_surveys
for each row execute procedure public.update_updated_at_column();
