import { requireRole } from '@/lib/auth/server';

export default async function CrmPage() {
  await requireRole(['manager', 'sales']);
  return (
    <div className="page-stack">
      <div className="page-heading"><div><p className="eyebrow">Comercial</p><h1>CRM de leads</h1><p className="muted">Funil comercial e acompanhamento de SLA.</p></div><a className="button-primary" href="/dashboard/crm/leads">Ver leads</a></div>
      <div className="metric-grid" aria-label="Indicadores comerciais">
        {['Novos leads', 'Em acompanhamento', 'Fora do SLA', 'Matrículas no período'].map((label) => <section className="metric-card" key={label}><span>{label}</span><strong>—</strong><small>Disponível após conexão dos dados</small></section>)}
      </div>
      <section className="panel"><div className="panel-heading"><div><h2>Pipeline</h2><p className="muted">Etapas configuradas do funil</p></div></div><div className="empty-state"><span className="empty-icon">▤</span><h3>O pipeline aparecerá aqui</h3><p>As etapas e os cards serão carregados do banco após a criação das tabelas de CRM.</p></div></section>
    </div>
  );
}
