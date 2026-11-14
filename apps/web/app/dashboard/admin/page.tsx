import { requireRole } from '@/lib/auth/server';
import { createServerClientInstance } from '@/lib/supabase/server';

export const dynamic = 'force-dynamic';

export default async function AdminPage() {
  const membership = await requireRole(['manager']);
  const supabase = createServerClientInstance();
  const [{ data: stages }, { count: usersCount }] = await Promise.all([
    supabase.from('kanban_stages').select('id, name, position, sla_hours, is_active').eq('organization_id', membership.organization_id).order('position'),
    supabase.from('organization_memberships').select('id', { count: 'exact', head: true }).eq('organization_id', membership.organization_id).eq('status', 'active')
  ]);
  return (
    <div className="page-stack">
      <div className="page-heading"><div><p className="eyebrow">Configurações</p><h1>Administração</h1><p className="muted">Visão operacional da organização.</p></div></div>
      <div className="metric-grid"><section className="metric-card"><span>Usuários ativos</span><strong>{usersCount ?? '—'}</strong><small>Memberships ativas</small></section><section className="metric-card"><span>Etapas do CRM</span><strong>{stages?.filter((stage) => stage.is_active).length ?? 0}</strong><small>Ativas no pipeline</small></section></div>
      <section className="panel"><div className="panel-heading"><div><h2>Etapas do Kanban</h2><p className="muted">Configuração atual (edição será habilitada em um próximo fluxo).</p></div></div>{stages?.length ? <div className="stage-list">{stages.map((stage) => <div className="stage-row" key={stage.id}><strong>{stage.position + 1}. {stage.name}</strong><span>SLA: {stage.sla_hours == null ? '—' : `${stage.sla_hours}h`}</span><span className="status-pill">{stage.is_active ? 'Ativa' : 'Inativa'}</span></div>)}</div> : <p className="muted">Nenhuma etapa disponível. Execute a migração de CRM.</p>}</section>
      <section className="notice"><strong>Área administrativa protegida.</strong><p>O acesso exige membership ativa com papel de gestor na organização.</p></section>
    </div>
  );
}
