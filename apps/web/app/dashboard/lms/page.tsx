import { requireRole } from '@/lib/auth/server';
import { createServerClientInstance } from '@/lib/supabase/server';

export const dynamic = 'force-dynamic';

export default async function LmsPage() {
  const membership = await requireRole(['manager', 'teacher', 'student']);
  const supabase = createServerClientInstance();
  const { data: courses, error } = await supabase
    .from('courses')
    .select('id, title, description, status, updated_at')
    .eq('organization_id', membership.organization_id)
    .order('updated_at', { ascending: false })
    .limit(100);
  const courseIds = (courses ?? []).map((course) => course.id);
  const { data: enrollments } = membership.role === 'manager' || membership.role === 'teacher'
    ? await supabase.from('course_enrollments').select('course_id').eq('organization_id', membership.organization_id).eq('status', 'active').in('course_id', courseIds.length ? courseIds : ['00000000-0000-0000-0000-000000000000'])
    : { data: [] as { course_id: string }[] };
  const enrollmentCounts = new Map<string, number>();
  (enrollments ?? []).forEach((row) => enrollmentCounts.set(row.course_id, (enrollmentCounts.get(row.course_id) ?? 0) + 1));

  return (
    <div className="page-stack">
      <div className="page-heading"><div><p className="eyebrow">Aprendizagem</p><h1>{membership.role === 'student' ? 'Meus cursos' : 'Cursos'}</h1><p className="muted">Catálogo organizado por curso, módulo e aula.</p></div></div>
      <section className="panel"><div className="panel-heading"><div><h2>{membership.role === 'student' ? 'Cursos matriculados' : 'Cursos disponíveis'}</h2><p className="muted">Acesso controlado por matrícula e vínculo docente.</p></div></div>
        {error ? <p className="form-message error" role="alert">Não foi possível carregar cursos. Confira as migrações e memberships.</p> : !courses?.length ? <div className="empty-state"><span className="empty-icon">▶</span><h3>Nenhum curso disponível</h3><p>Cursos publicados e vinculados aparecerão aqui.</p></div> : <div className="course-grid">{courses.map((course) => <article className="course-card" key={course.id}><div className="course-cover"><span>{course.status === 'published' ? 'CURSO' : 'RASCUNHO'}</span></div><div className="course-body"><h2>{course.title}</h2><p>{course.description || 'Sem descrição.'}</p><div className="course-meta"><span className="status-pill">{course.status}</span>{membership.role !== 'student' && <small>{enrollmentCounts.get(course.id) ?? 0} matrículas ativas</small>}</div></div></article>)}</div>}
      </section>
    </div>
  );
}
