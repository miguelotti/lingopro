import { requireRole } from '@/lib/auth/server';

export default async function LeadsPage() {
  await requireRole(['manager', 'sales']);
  return (
    <div className="page-stack">
      <div className="page-heading"><div><p className="eyebrow">CRM / Comercial</p><h1>Leads</h1><p className="muted">Lista e filtros do atendimento comercial.</p></div></div>
      <section className="panel">
        <div className="toolbar"><label className="search-label">Buscar lead<input type="search" placeholder="Nome, telefone ou e-mail" disabled aria-label="Busca ficará disponível quando a tabela de leads estiver conectada" /></label><label>Etapa<select disabled><option>Todas as etapas</option></select></label><button className="button-primary" disabled title="Cadastro disponível após implementação do schema CRM">Novo lead</button></div>
        <div className="empty-state"><span className="empty-icon">⌕</span><h2>Nenhum dado conectado ainda</h2><p>A interface está preparada. O próximo passo é criar as tabelas `leads`, `kanban_stages` e `lead_interactions`, com RLS e ações do servidor.</p></div>
      </section>
    </div>
  );
}
