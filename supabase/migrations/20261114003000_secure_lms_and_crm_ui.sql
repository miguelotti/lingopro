-- Seed default CRM stages and provide an atomic lead-creation RPC.
create or replace function public.seed_default_kanban_stages()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.kanban_stages (organization_id, name, stage_key, position, sla_hours, is_terminal)
  values
    (new.id, 'Novo Lead', 'new', 0, 2, false),
    (new.id, 'Contato Realizado', 'contacted', 1, 24, false),
    (new.id, 'Visita/Reunião Agendada', 'meeting_scheduled', 2, 72, false),
    (new.id, 'Proposta Enviada', 'proposal_sent', 3, 72, false),
    (new.id, 'Matrícula em Andamento', 'enrollment_in_progress', 4, 168, false),
    (new.id, 'Matriculado', 'enrolled', 5, null, true),
    (new.id, 'Perdido', 'lost', 6, null, true)
  on conflict (organization_id, stage_key) do nothing;
  return new;
end;
$$;

drop trigger if exists organizations_seed_kanban_stages on public.organizations;
create trigger organizations_seed_kanban_stages
after insert on public.organizations
for each row execute procedure public.seed_default_kanban_stages();

-- Also seed organizations created before this migration.
insert into public.kanban_stages (organization_id, name, stage_key, position, sla_hours, is_terminal)
select o.id, s.name, s.stage_key, s.position, s.sla_hours, s.is_terminal
from public.organizations o
cross join (values
  ('Novo Lead', 'new', 0, 2, false),
  ('Contato Realizado', 'contacted', 1, 24, false),
  ('Visita/Reunião Agendada', 'meeting_scheduled', 2, 72, false),
  ('Proposta Enviada', 'proposal_sent', 3, 72, false),
  ('Matrícula em Andamento', 'enrollment_in_progress', 4, 168, false),
  ('Matriculado', 'enrolled', 5, null::integer, true),
  ('Perdido', 'lost', 6, null::integer, true)
) as s(name, stage_key, position, sla_hours, is_terminal)
on conflict (organization_id, stage_key) do nothing;

create or replace function public.create_lead_with_history(
  p_organization_id uuid,
  p_stage_id uuid,
  p_student_name text,
  p_student_age integer,
  p_course_interest text,
  p_guardian_name text,
  p_guardian_phone text,
  p_email text,
  p_source text
)
returns uuid
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_lead_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;
  if not (public.user_has_role_in_org(p_organization_id, 'manager') or public.user_has_role_in_org(p_organization_id, 'sales')) then
    raise exception 'Not authorized to create leads' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.kanban_stages s
    where s.id = p_stage_id and s.organization_id = p_organization_id
      and s.stage_key = 'new' and s.is_active
  ) then
    raise exception 'A valid new-lead stage is required' using errcode = '22023';
  end if;
  if nullif(trim(p_student_name), '') is null or nullif(trim(p_guardian_phone), '') is null then
    raise exception 'Student name and guardian phone are required' using errcode = '22023';
  end if;

  insert into public.leads (
    organization_id, stage_id, owner_user_id, student_name, student_age,
    course_interest, guardian_name, guardian_phone, email, source,
    last_moved_at, last_interaction_at
  ) values (
    p_organization_id, p_stage_id, auth.uid(), trim(p_student_name), p_student_age,
    nullif(trim(p_course_interest), ''), nullif(trim(p_guardian_name), ''),
    trim(p_guardian_phone), nullif(trim(p_email), ''), coalesce(nullif(trim(p_source), ''), 'manual'),
    now(), now()
  ) returning id into v_lead_id;

  insert into public.lead_stage_history (
    organization_id, lead_id, from_stage_id, to_stage_id, changed_by, note
  ) values (p_organization_id, v_lead_id, null, p_stage_id, auth.uid(), 'Lead criado');

  return v_lead_id;
end;
$$;

revoke all on function public.create_lead_with_history(uuid, uuid, text, integer, text, text, text, text, text) from public;
grant execute on function public.create_lead_with_history(uuid, uuid, text, integer, text, text, text, text, text) to authenticated;

-- The prior trigger referenced a column that does not exist on stage history.
drop trigger if exists set_lead_stage_history_updated_at on public.lead_stage_history;

-- Restrict LMS reads by publication, enrollment, and teacher assignment.
create or replace function public.user_can_access_course(p_organization_id uuid, p_course_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.courses c
    where c.id = p_course_id and c.organization_id = p_organization_id
      and (
        public.user_has_role_in_org(p_organization_id, 'manager')
        or exists (
          select 1 from public.course_teachers ct
          where ct.organization_id = p_organization_id and ct.course_id = c.id
            and ct.teacher_user_id = auth.uid()
            and public.user_has_role_in_org(p_organization_id, 'teacher')
        )
        or (c.status = 'published' and exists (
          select 1 from public.course_enrollments ce
          where ce.organization_id = p_organization_id and ce.course_id = c.id
            and ce.student_user_id = auth.uid() and ce.status = 'active'
            and public.user_has_role_in_org(p_organization_id, 'student')
        ))
      )
  );
$$;

create or replace function public.user_can_manage_course(p_organization_id uuid, p_course_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public.user_has_role_in_org(p_organization_id, 'manager')
    or (
      public.user_has_role_in_org(p_organization_id, 'teacher')
      and exists (
        select 1 from public.course_teachers ct
        where ct.organization_id = p_organization_id and ct.course_id = p_course_id
          and ct.teacher_user_id = auth.uid()
      )
    );
$$;

revoke all on function public.user_can_access_course(uuid, uuid) from public;
revoke all on function public.user_can_manage_course(uuid, uuid) from public;
grant execute on function public.user_can_access_course(uuid, uuid) to authenticated;
grant execute on function public.user_can_manage_course(uuid, uuid) to authenticated;

-- Drop broad initial LMS policies: PostgreSQL combines permissive policies with OR.
drop policy if exists "Members can read courses in organization" on public.courses;
drop policy if exists "Managers and teachers can manage courses" on public.courses;
drop policy if exists "Members can read modules for courses in org" on public.course_modules;
drop policy if exists "Managers and teachers can manage modules" on public.course_modules;
drop policy if exists "Members can read lessons in org" on public.lessons;
drop policy if exists "Managers and teachers can manage lessons" on public.lessons;
drop policy if exists "Students can read own enrollments" on public.course_enrollments;
drop policy if exists "Managers and teachers can manage enrollments" on public.course_enrollments;
drop policy if exists "Managers and teachers can read course teachers" on public.course_teachers;
drop policy if exists "Managers and teachers can manage course teachers" on public.course_teachers;
drop policy if exists "Students can read own lesson progress" on public.lesson_progress;
drop policy if exists "Students can update own lesson progress" on public.lesson_progress;
drop policy if exists "Students can update own lesson progress records" on public.lesson_progress;
drop policy if exists "Managers and teachers can read assessments in org" on public.assessments;
drop policy if exists "Managers and teachers can manage assessments" on public.assessments;
drop policy if exists "Students can read their assessment attempts" on public.assessment_attempts;
drop policy if exists "Managers and teachers can manage assessment attempts" on public.assessment_attempts;

create policy "Authorized users can read courses" on public.courses
for select to authenticated using (public.user_can_access_course(organization_id, id));
create policy "Authorized course owners can update courses" on public.courses
for update to authenticated using (public.user_can_manage_course(organization_id, id))
with check (public.user_can_manage_course(organization_id, id));
create policy "Managers can create courses" on public.courses
for insert to authenticated with check (public.user_has_role_in_org(organization_id, 'manager'));
create policy "Managers can delete courses" on public.courses
for delete to authenticated using (public.user_has_role_in_org(organization_id, 'manager'));

create policy "Authorized users can read modules" on public.course_modules
for select to authenticated using (public.user_can_access_course(organization_id, course_id));
create policy "Authorized users can manage modules" on public.course_modules
for all to authenticated using (public.user_can_manage_course(organization_id, course_id))
with check (public.user_can_manage_course(organization_id, course_id));

create policy "Authorized users can read lessons" on public.lessons
for select to authenticated using (
  exists (select 1 from public.course_modules m
    where m.id = module_id and m.organization_id = lessons.organization_id
      and public.user_can_access_course(m.organization_id, m.course_id))
  and (status = 'published' or public.user_can_manage_course(organization_id,
    (select m.course_id from public.course_modules m where m.id = module_id)))
);
create policy "Authorized users can manage lessons" on public.lessons
for all to authenticated using (
  exists (select 1 from public.course_modules m where m.id = module_id
    and m.organization_id = lessons.organization_id
    and public.user_can_manage_course(m.organization_id, m.course_id))
) with check (
  exists (select 1 from public.course_modules m where m.id = module_id
    and m.organization_id = lessons.organization_id
    and public.user_can_manage_course(m.organization_id, m.course_id))
);

create policy "Users can read permitted enrollments" on public.course_enrollments
for select to authenticated using (
  organization_id in (select organization_id from public.current_user_organization_ids())
  and (student_user_id = auth.uid() or public.user_has_role_in_org(organization_id, 'manager')
    or public.user_can_manage_course(organization_id, course_id))
);
create policy "Managers manage enrollments" on public.course_enrollments
for all to authenticated using (public.user_has_role_in_org(organization_id, 'manager'))
with check (public.user_has_role_in_org(organization_id, 'manager'));

create policy "Users can read permitted course teacher links" on public.course_teachers
for select to authenticated using (
  organization_id in (select organization_id from public.current_user_organization_ids())
  and (teacher_user_id = auth.uid() or public.user_has_role_in_org(organization_id, 'manager'))
);
create policy "Managers manage course teacher links" on public.course_teachers
for all to authenticated using (public.user_has_role_in_org(organization_id, 'manager'))
with check (public.user_has_role_in_org(organization_id, 'manager'));

create policy "Authorized users can read lesson assets" on public.lesson_assets
for select to authenticated using (
  exists (select 1 from public.lessons l join public.course_modules m on m.id = l.module_id
    where l.id = lesson_id and l.organization_id = lesson_assets.organization_id
      and public.user_can_access_course(m.organization_id, m.course_id)
      and (l.status = 'published' or public.user_can_manage_course(m.organization_id, m.course_id))
      and (lesson_assets.status = 'published' or public.user_can_manage_course(m.organization_id, m.course_id)))
);
create policy "Authorized users can manage lesson assets" on public.lesson_assets
for all to authenticated using (
  exists (select 1 from public.lessons l join public.course_modules m on m.id = l.module_id
    where l.id = lesson_id and l.organization_id = lesson_assets.organization_id
      and public.user_can_manage_course(m.organization_id, m.course_id))
) with check (
  exists (select 1 from public.lessons l join public.course_modules m on m.id = l.module_id
    where l.id = lesson_id and l.organization_id = lesson_assets.organization_id
      and public.user_can_manage_course(m.organization_id, m.course_id))
);

create policy "Users can read permitted progress" on public.lesson_progress
for select to authenticated using (
  student_user_id = auth.uid()
  or public.user_has_role_in_org(organization_id, 'manager')
  or exists (select 1 from public.lessons l join public.course_modules m on m.id = l.module_id
    where l.id = lesson_id and l.organization_id = lesson_progress.organization_id
      and public.user_can_manage_course(m.organization_id, m.course_id))
);
create policy "Enrolled students can create own progress" on public.lesson_progress
for insert to authenticated with check (
  student_user_id = auth.uid()
  and exists (select 1 from public.lessons l join public.course_modules m on m.id = l.module_id
    join public.course_enrollments ce on ce.course_id = m.course_id
    where l.id = lesson_id and l.organization_id = lesson_progress.organization_id
      and l.status = 'published' and ce.organization_id = lesson_progress.organization_id
      and ce.student_user_id = auth.uid() and ce.status = 'active'
      and public.user_has_role_in_org(lesson_progress.organization_id, 'student'))
);
create policy "Enrolled students can update own progress" on public.lesson_progress
for update to authenticated using (student_user_id = auth.uid()) with check (
  student_user_id = auth.uid()
  and exists (select 1 from public.lessons l join public.course_modules m on m.id = l.module_id
    join public.course_enrollments ce on ce.course_id = m.course_id
    where l.id = lesson_id and l.organization_id = lesson_progress.organization_id
      and ce.organization_id = lesson_progress.organization_id
      and ce.student_user_id = auth.uid() and ce.status = 'active')
);

create policy "Authorized users can read assessments" on public.assessments
for select to authenticated using (
  exists (select 1 from public.lessons l join public.course_modules m on m.id = l.module_id
    where l.id = lesson_id and l.organization_id = assessments.organization_id
      and public.user_can_access_course(m.organization_id, m.course_id)
      and (assessments.status = 'published' or public.user_can_manage_course(m.organization_id, m.course_id)))
);
create policy "Authorized users can manage assessments" on public.assessments
for all to authenticated using (
  exists (select 1 from public.lessons l join public.course_modules m on m.id = l.module_id
    where l.id = lesson_id and l.organization_id = assessments.organization_id
      and public.user_can_manage_course(m.organization_id, m.course_id))
) with check (
  exists (select 1 from public.lessons l join public.course_modules m on m.id = l.module_id
    where l.id = lesson_id and l.organization_id = assessments.organization_id
      and public.user_can_manage_course(m.organization_id, m.course_id))
);

create policy "Users can read permitted assessment attempts" on public.assessment_attempts
for select to authenticated using (
  student_user_id = auth.uid()
  or public.user_has_role_in_org(organization_id, 'manager')
  or exists (select 1 from public.assessments a join public.lessons l on l.id = a.lesson_id
    join public.course_modules m on m.id = l.module_id
    where a.id = assessment_id and a.organization_id = assessment_attempts.organization_id
      and public.user_can_manage_course(m.organization_id, m.course_id))
);
create policy "Students can create own assessment attempts" on public.assessment_attempts
for insert to authenticated with check (
  student_user_id = auth.uid()
  and status = 'in_progress' and score is null
  and exists (select 1 from public.assessments a join public.lessons l on l.id = a.lesson_id
    join public.course_modules m on m.id = l.module_id
    join public.course_enrollments ce on ce.course_id = m.course_id
    where a.id = assessment_id and a.organization_id = assessment_attempts.organization_id
      and a.status = 'published' and l.status = 'published'
      and ce.organization_id = assessment_attempts.organization_id
      and ce.student_user_id = auth.uid() and ce.status = 'active')
);
create policy "Students can submit own attempts" on public.assessment_attempts
for update to authenticated using (student_user_id = auth.uid() and status = 'in_progress')
with check (student_user_id = auth.uid() and status in ('in_progress', 'submitted') and score is null);
