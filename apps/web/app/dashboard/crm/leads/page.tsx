import { requireRole } from '@/lib/auth/server';
import { createServerClientInstance } from '@/lib/supabase/server';
import { LeadForm } from './lead-form';

export const dynamic = 'force-dynamic';

export default async function LeadsPage() {
  const membership = await requireRole(['manager', 'sales']);
  const supabase = createServerClientInstance();
  const { data: leads, error } = await supabase
    .from('leads')
    .select('id, student_name, guardian_name, guardian_phone, email, source, status, last_moved_at, kanban_stages(name)')
    .eq('organization_id', membership.organization_id)
    .order('created_at', { ascending: false })
    .limit(100);

  return (
    <div className="page-stack">
      <div className="page-heading"><div><p className="eyebrow">CRM / Comercial</p><h1>Leads</h1><p className="muted">Leads recentes da sua organização.</p></div></div>
      <section className="panel">
        <h2>Cadastrar lead</h2>
        <LeadForm />
      </section>
      <section className="panel">
        <div className="panel-heading"><div><h2>Leads recentes</h2><p className="muted">Máximo de 100 registros recentes.</p></div></div>
        {error ? <p className="form-message error" role="alert">Não foi possível carregar os leads. Confira se as migrações foram aplicadas.</p> : !leads?.length ? <div className="empty-state"><span className="empty-icon">⌕</span><h2>Nenhum lead cadastrado</h2><p>Use o formulário acima para registrar o primeiro lead.</p></div> : (
          <div className="table-wrap"><table><thead><tr><th>Aluno</th><th>Responsável</th><th>Contato</th><th>Etapa</th><th>Origem</th><th>Status</th></tr></thead><tbody>
            {leads.map((lead: any) => <tr key={lead.id}><td><strong>{lead.student_name}</strong></td><td>{lead.guardian_name || '—'}</td><td>{lead.guardian_phone}{lead.email && <small className="table-subline">{lead.email}</small>}</td><td>{lead.kanban_stages?.name || '—'}</td><td>{lead.source}</td><td><span className="status-pill">{lead.status}</span></td></tr>)}
          </tbody></table></div>
        )}
      </section>
    </div>
  );
}
