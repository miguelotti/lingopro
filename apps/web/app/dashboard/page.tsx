import { requireRole } from '@/lib/auth/server';
import { ROLE_LABELS } from '@/lib/auth/roles';
import { createServerClientInstance } from '@/lib/supabase/server';

export const dynamic = 'force-dynamic';

export default async function DashboardPage() {
  const membership = await requireRole(['manager', 'teacher', 'student', 'sales']);
  const supabase = createServerClientInstance();
  const isCommercial = membership.role === 'manager' || membership.role === 'sales';
  const isPedagogical = membership.role === 'manager' || membership.role === 'teacher' || membership.role === 'student';

  const [leadResult, courseResult] = await Promise.all([
    isCommercial ? supabase.from('leads').select('id', { count: 'exact', head: true }).eq('organization_id', membership.organization_id) : Promise.resolve({ count: null, error: null }),
    isPedagogical ? supabase.from('courses').select('id', { count: 'exact', head: true }).eq('organization_id', membership.organization_id) : Promise.resolve({ count: null, error: null })
  ]);

  return (
    <div className="page-stack">
      <div className="page-heading"><div><p className="eyebrow">Visão geral</p><h1>Olá, {ROLE_LABELS[membership.role]}</h1></div><span className="muted">Painel LingoPro</span></div>
      <div className="metric-grid">
        {isCommercial && <section className="metric-card"><span>Leads</span><strong>{leadResult.count ?? '—'}</strong><small>Na sua organização</small></section>}
        {isPedagogical && <section className="metric-card"><span>Cursos acessíveis</span><strong>{courseResult.count ?? '—'}</strong><small>Conforme suas matrículas e vínculos</small></section>}
      </div>
      <div className="card-grid">
        {(membership.role === 'sales' || membership.role === 'manager') && <a className="module-card" href="/dashboard/crm"><span className="card-icon">01</span><h2>CRM</h2><p>Acompanhe leads, etapas do funil e SLA.</p><span className="card-link">Abrir CRM →</span></a>}
        {(membership.role === 'teacher' || membership.role === 'student' || membership.role === 'manager') && <a className="module-card" href="/dashboard/lms"><span className="card-icon">02</span><h2>LMS</h2><p>Acesse cursos, aulas e materiais pedagógicos.</p><span className="card-link">Abrir LMS →</span></a>}
        {membership.role === 'manager' && <a className="module-card" href="/dashboard/admin"><span className="card-icon">03</span><h2>Administração</h2><p>Gerencie etapas e operação da organização.</p><span className="card-link">Abrir administração →</span></a>}
      </div>
    </div>
  );
}
