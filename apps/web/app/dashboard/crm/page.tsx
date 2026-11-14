import { requireRole } from '@/lib/auth/server';
import { createServerClientInstance } from '@/lib/supabase/server';

export const dynamic = 'force-dynamic';

export default async function CrmPage() {
  const membership = await requireRole(['manager', 'sales']);
  const supabase = createServerClientInstance();
  const [{ data: stages, error: stagesError }, { count: totalLeads }, { count: dormantLeads }] = await Promise.all([
    supabase.from('kanban_stages').select('id, name, stage_key, position, sla_hours').eq('organization_id', membership.organization_id).eq('is_active', true).order('position'),
    supabase.from('leads').select('id', { count: 'exact', head: true }).eq('organization_id', membership.organization_id),
    supabase.from('leads').select('id', { count: 'exact', head: true }).eq('organization_id', membership.organization_id).eq('status', 'dormant')
  ]);
  const stageCounts = await Promise.all((stages ?? []).map(async (stage) => {
    const { count } = await supabase.from('leads').select('id', { count: 'exact', head: true }).eq('organization_id', membership.organization_id).eq('stage_id', stage.id);
    return { ...stage, count: count ?? 0 };
  }));

  return (
    <div className="page-stack">
      <div className="page-heading"><div><p className="eyebrow">Comercial</p><h1>CRM de leads</h1><p className="muted">Funil comercial e acompanhamento de SLA.</p></div><a className="button-primary" href="/dashboard/crm/leads">Cadastrar lead</a></div>
      {(stagesError) && <section className="notice" role="alert"><strong>Não foi possível carregar o CRM.</strong><p>Verifique se as migrações do Supabase foram aplicadas.</p></section>}
      <div className="metric-grid" aria-label="Indicadores comerciais">
        <section className="metric-card"><span>Total de leads</span><strong>{totalLeads ?? 0}</strong><small>Na sua organização</small></section>
        <section className="metric-card"><span>Leads dormentes</span><strong>{dormantLeads ?? 0}</strong><small>Precisam de acompanhamento</small></section>
      </div>
      <section className="panel"><div className="panel-heading"><div><h2>Pipeline</h2><p className="muted">Leads por etapa</p></div></div>
        {stageCounts.length ? <div className="pipeline-grid">{stageCounts.map((stage) => <article className="pipeline-column" key={stage.id}><div className="pipeline-title"><h3>{stage.name}</h3><span>{stage.count}</span></div><small>SLA: {stage.sla_hours == null ? '—' : `${stage.sla_hours}h`}</small></article>)}</div> : <div className="empty-state"><h3>Nenhuma etapa configurada</h3><p>Execute as migrações do CRM para criar as etapas iniciais.</p></div>}
      </section>
    </div>
  );
}
