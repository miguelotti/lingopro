import { requireRole } from '@/lib/auth/server';

export default async function ClassesPage() {
  const membership = await requireRole(['manager', 'teacher', 'student']);
  return (
    <div className="page-stack"><div className="page-heading"><div><p className="eyebrow">LMS / Aulas</p><h1>{membership.role === 'student' ? 'Aulas disponíveis' : 'Aulas e conteúdos'}</h1><p className="muted">Vídeos, slides, exercícios e aulas ao vivo.</p></div></div><section className="panel"><div className="empty-state"><span className="empty-icon">▷</span><h2>As aulas serão listadas aqui</h2><p>O acesso será filtrado por matrícula ativa para alunos e pelos cursos associados para professores.</p></div></section></div>
  );
}
