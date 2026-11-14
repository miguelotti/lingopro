import { requireRole } from '@/lib/auth/server';

export default async function LmsPage() {
  const membership = await requireRole(['manager', 'teacher', 'student']);
  const isEditor = membership.role === 'manager' || membership.role === 'teacher';
  return (
    <div className="page-stack">
      <div className="page-heading"><div><p className="eyebrow">Aprendizagem</p><h1>{membership.role === 'student' ? 'Meus cursos' : 'Gestão de cursos'}</h1><p className="muted">Catálogo organizado por curso, módulo e aula.</p></div>{isEditor && <button className="button-primary" disabled title="Criação de curso será ativada após implementação do schema LMS">Novo curso</button>}</div>
      <section className="panel"><div className="panel-heading"><div><h2>{membership.role === 'student' ? 'Cursos matriculados' : 'Cursos da organização'}</h2><p className="muted">Conteúdos visíveis conforme papel e matrícula.</p></div><a className="text-link" href="/dashboard/lms/classes">Ver aulas →</a></div><div className="empty-state"><span className="empty-icon">▶</span><h3>O catálogo será carregado aqui</h3><p>Os cursos aparecerão quando as tabelas de cursos, matrículas, módulos e aulas estiverem instaladas e protegidas por RLS.</p></div></section>
    </div>
  );
}
