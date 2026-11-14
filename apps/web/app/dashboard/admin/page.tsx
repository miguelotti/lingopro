import { requireRole } from '@/lib/auth/server';

export default async function AdminPage() {
  await requireRole(['manager']);
  return (
    <div className="page-stack">
      <div className="page-heading"><div><p className="eyebrow">Configurações</p><h1>Administração</h1><p className="muted">Gestão da organização e operação da plataforma.</p></div></div>
      <div className="card-grid">
        <section className="module-card"><span className="card-icon">01</span><h2>Usuários e permissões</h2><p>Convites, perfis e memberships da organização.</p><span className="status-pill">Aguardando módulo de usuários</span></section>
        <section className="module-card"><span className="card-icon">02</span><h2>Etapas do Kanban</h2><p>Nomes, ordem e SLAs por etapa.</p><span className="status-pill">Aguardando schema CRM</span></section>
        <section className="module-card"><span className="card-icon">03</span><h2>Integrações</h2><p>Estado dos webhooks e processamento de gravações.</p><span className="status-pill">Aguardando configuração segura</span></section>
      </div>
      <section className="notice"><strong>Área administrativa protegida.</strong><p>A rota valida o papel `manager` no banco via membership ativa. As operações de escrita serão habilitadas junto com as políticas RLS específicas.</p></section>
    </div>
  );
}
