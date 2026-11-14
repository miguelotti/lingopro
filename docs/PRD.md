# LingoPro SaaS — Pacote de Entrega Técnica

## Arquivo 1 — PRD (Product Requirements Document)

**Produto:** LingoPro SaaS  
**Versão:** 1.0  
**Status:** Draft para desenvolvimento  
**Data:** 2026-11-12

### 1. Visão Geral e Objetivo

**Missão:** Unificar a operação comercial e pedagógica da LingoPro em uma única plataforma SaaS, eliminando a fragmentação entre ferramentas de captação de alunos e ambientes de aprendizagem.

**Problema:** A escola gerencia leads em planilhas e WhatsApp, perde prazos de follow-up e não tem visibilidade do funil. No pedagógico, alunos e professores dependem de links dispersos e não há repositório central de aulas, slides e testes. A gestão não consegue medir conversão nem satisfação em tempo real.

**Público-alvo:** Gestores da LingoPro, equipe comercial (responsáveis pelo atendimento aos leads), professores e alunos.

**Métricas de sucesso:**

- Taxa de conversão Lead → Matrícula (meta: +20% em 6 meses).
- Tempo médio de primeiro contato com lead (meta: < 2 horas).
- Aderência ao SLA por etapa do Kanban (meta: > 90%).
- NPS de alunos e professores (meta: > 50).
- Taxa de retenção de alunos ativos no LMS (meta: > 85% ao mês).

### 2. Escopo Funcional

#### 2.1 Módulo CRM — Kanban de Leads

**Colunas do funil (etapas):**

- Novo Lead — entrada manual ou via WhatsApp API.
- Contato Realizado — primeiro contato efetuado; registrar data/hora e responsável.
- Visita/Reunião Agendada — agendamento de visita ou reunião online.
- Proposta Enviada — envio de condições comerciais.
- Matrícula em Andamento — documentação e pagamento.
- Matriculado — conversão concluída.
- Perdido — com motivo categorizado (preço, localização, concorrente, turno, desistência).

**Card do Lead (informações obrigatórias):**

- Nome do lead (aluno), idade, série/curso de interesse.
- Nome do responsável, telefone (WhatsApp), e-mail.
- Origem do lead (indicação, Instagram, site, WhatsApp, etc.).
- Responsável pelo atendimento (usuário do sistema).
- Timestamp de entrada e de última movimentação.
- Histórico de interações (mensagens WhatsApp capturadas + anotações manuais).
- SLA da etapa: indicador visual (verde/amarelo/vermelho) baseado no tempo parado.

**Integração WhatsApp (API):**

- Recebimento de mensagens via webhook da API oficial (Meta).
- Criação automática de card quando mensagem chega de número não cadastrado.
- Associação de conversa existente ao card do lead pelo número de telefone.
- Registro do conteúdo das mensagens no histórico do card (somente leitura para o atendente no CRM).

**Regras de negócio:**

- Todo lead deve ter um responsável atribuído.
- Card não pode avançar de etapa sem preenchimento dos campos obrigatórios da etapa.
- Lead sem interação por 30 dias é sinalizado como “Dormente” automaticamente.
- Motivo de perda é obrigatório ao mover para “Perdido”.

#### 2.2 Módulo LMS — Estilo Netflix

**Perfis de acesso:**

- **Aluno:** visualiza aulas, slides, testes e exercícios; acessa sala de aula online; responde pesquisas de satisfação.
- **Professor:** cria e gerencia conteúdo (aulas, slides, testes); acessa sala de aula online; responde pesquisas de satisfação.
- **Gestor:** acesso administrativo total; gerencia usuários, permissões e dashboards.

**Funcionalidades do LMS:**

- Catálogo de aulas: organização por curso, módulo e aula; capa visual, descrição, duração e professor responsável.
- Tipos de conteúdo: vídeo (YouTube unlisted), slides (PDF/visualização), testes (múltipla escolha e dissertativo), exercícios (arquivo ou interativo).
- Sala de aula online (Google Meet): botão “Entrar na Sala” que abre o Google Meeting da turma. Aulas são gravadas automaticamente (via configuração do Meet) e, após o término, o sistema aciona o upload para o YouTube da LingoPro em modo unlisted (acesso somente por link). O link do vídeo é então associado à aula correspondente no LMS.
- Pesquisa de satisfação: formulário pós-aula (aluno) e formulário periódico (professor), com escala Likert e campo aberto. Resultados alimentam o dashboard.

**Regras de negócio:**

- Vídeos de aulas só ficam disponíveis no LMS após o upload ao YouTube e associação do link.
- Aluno só vê conteúdo de cursos nos quais está matriculado.
- Professor só edita conteúdo dos cursos sob sua responsabilidade.
- Gravações do Meet são armazenadas temporariamente no Google Drive da LingoPro até o upload; após confirmação, o arquivo local é removido.

#### 2.3 Módulo Administração e Dashboards

**Dashboards obrigatórios:**

- **Comercial:** leads por etapa, taxa de conversão por origem, tempo médio de ciclo, aderência ao SLA, matrículas por período.
- **Pedagógico:** aulas assistidas por aluno, taxa de conclusão de cursos, notas médias em testes, aulas ao vivo realizadas vs. planejadas.
- **Satisfação:** NPS de alunos e professores, distribuição de notas, comentários recentes.
- **Operacional:** usuários ativos, acessos ao LMS, uploads pendentes de vídeo.

**Administração:**

- CRUD de usuários (alunos, professores, gestores).
- Definição de permissões por perfil.
- Configuração de etapas do Kanban (nomes e SLAs).
- Configuração de integrações (WhatsApp API, Google Meet, YouTube).

### 3. Requisitos Técnicos

| Item | Especificação |
|---|---|
| Frontend | Next.js (React) hospedado na Vercel |
| Backend/DB | Supabase (PostgreSQL + Auth + Storage + Edge Functions) |
| Repositório | GitHub (monorepo) |
| WhatsApp | API oficial Meta (Cloud API) com webhook |
| Google Meet | Google Meet REST API para criação de espaços e recuperação de gravações |
| YouTube | YouTube Data API v3 — upload com privacyStatus: unlisted |
| Autenticação | Supabase Auth (e-mail/senha + OAuth Google para professores/gestores) |

### 4. Fora de Escopo (v1)

- Aplicativo mobile nativo.
- Integração com sistemas acadêmicos externos (notas, boletim).
- Chat interno entre alunos e professores (além da sala Meet).
- Pagamento online de matrícula (gateway).

### 5. Riscos e Mitigações

| Risco | Mitigação |
|---|---|
| Quota da YouTube API para uploads | Solicitar aumento de quota; upload em lote fora do horário de pico |
| Gravações do Meet não disponíveis imediatamente | Retry com backoff; notificar gestor se falhar após 3 tentativas |
| Dependência da API do WhatsApp (Meta) | Fallback para entrada manual de leads; monitoramento de webhook |
| Vazamento de links de vídeos unlisted | Controle de acesso no LMS; links não são indexados, mas podem ser compartilhados — aceito no v1 |
