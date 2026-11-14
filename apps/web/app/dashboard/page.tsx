import { requireRole } from '@/lib/auth/server';
import { ROLE_LABELS } from '@/lib/auth/roles';

export default async function DashboardPage() {
  const membership = await requireRole(['manager', 'teacher', 'student', 'sales']);
  return (
    <div className="page-stack">
      <div className="page-heading">
        <div><p className="eyebrow">Visão geral</p><h1>Olá, {ROLE_LABELS[membership.role]}</h1></div>
        <span className="muted">Painel LingoPro</span>
      </div>
      <section className="notice" role="status">
        <strong>Base do painel pronta.</strong>
        <p>Os indicadores serão exibidos quando CRM, LMS e eventos de atividade estiverem conectados ao banco.</p>
      </section>
      <div className="card-grid">
        <a className="module-card" href={membership.role === 'sales' || membership.role === 'manager' ? '/dashboard/crm' : '/dashboard/lms'}>
          <span className="card-icon" aria-hidden="true">01</span><h2>{membership.role === 'sales' ? 'CRM' : membership.role === 'manager' ? 'CRM e Comercial' : 'LMS'}</h2>
          <p>{membership.role === 'sales' ? 'Acompanhe leads e etapas do funil.' : membership.role === 'manager' ? 'Acesse o funil e os indicadores comerciais.' : 'Acesse cursos, aulas e materiais.'}</p><span className="card-link">Abrir módulo →</span>
        </a>
        {membership.role === 'manager' && <a className="module-card" href="/dashboard/admin"><span className="card-icon" aria-hidden="true">02</span><h2>Administração</h2><p>Área de usuários, organização e configurações.</p><span className="card-link">Abrir administração →</span></a>}
        {(membership.role === 'teacher' || membership.role === 'student' || membership.role === 'manager') && <a className="module-card" href="/dashboard/lms"><span className="card-icon" aria-hidden="true">03</span><h2>LMS</h2><p>Cursos, conteúdos e acompanhamento pedagógico.</p><span className="card-link">Abrir LMS →</span></a>}
      </div>
    </div>
  );
}
