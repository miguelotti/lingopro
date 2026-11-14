# Arquitetura — LingoPro SaaS

**Versão:** 1.0  
**Status:** Proposta para MVP  
**Base:** [PRD](./PRD.md) · [Especificação Técnica](./ESPECIFICACAO-TECNICA.md)

## 1. Visão lógica

```text
Navegador
   │ HTTPS / sessão Supabase Auth
   ▼
Next.js (Vercel) ───────► Supabase Auth
   │                         │ identidade
   │ chamadas autenticadas   ▼
   ├────────────────────► PostgreSQL (RLS)
   ├────────────────────► Supabase Storage (arquivos privados)
   └────────────────────► Route Handlers / Edge Functions
                                  │
                       ┌──────────┼───────────┐
                       ▼          ▼           ▼
                 Meta Webhook  Google APIs  YouTube API
                       │          │           │
                       └──── eventos/tarefas ┘
                                  ▼
                     integration_events / jobs
```

As chamadas privilegiadas e credenciais de integração permanecem no servidor. O diagrama é lógico; o mecanismo específico de fila/agendamento ainda precisa ser selecionado e validado.

## 2. Camadas

### Apresentação — Next.js

- Áreas autenticadas de CRM, LMS e gestão.
- Componentes adaptados a papéis, sem tratar ocultação de interface como controle de autorização.
- Validação de entrada no cliente para usabilidade e novamente no servidor para integridade.

### Aplicação — Route Handlers e Edge Functions

- Regras de negócio, integração externa, validação de permissões e sanitização de respostas.
- Operações com credencial administrativa apenas em código de servidor confiável.
- Webhooks isolados de rotas de usuário, com autenticação própria, idempotência e limite de payload.

### Dados — Supabase/PostgreSQL

- Entidades transacionais e histórico de eventos.
- RLS aplicada nas tabelas expostas ao cliente.
- Migrações versionadas; índices definidos para tenant, status, datas e relações consultadas.
- Views ou consultas agregadas para dashboards, sem contornar as regras de acesso.

### Arquivos — Storage, Drive e YouTube

- Storage privado para documentos e materiais pedagógicos.
- Google Drive como armazenamento temporário de gravações, conforme política de retenção.
- YouTube não listado como destino de vídeos; o link não substitui autorização do LMS, pois pode ser compartilhado.
- URLs assinadas de curta duração para ativos privados quando aplicável.

## 3. Domínios e limites

1. **Identidade e organização:** usuários, papéis, tenant e auditoria.
2. **Comercial:** lead, responsável, interação, etapa e SLA.
3. **Pedagógico:** curso, matrícula, conteúdo, avaliação e progresso.
4. **Aulas ao vivo:** turma, sala, gravação e associação à aula.
5. **Satisfação:** formulários, respostas e indicadores agregados.
6. **Integrações:** tokens, webhooks, fila, estado, retentativa e alertas.

Os domínios compartilham identidade e organização, mas mantêm permissões e ciclo de vida próprios. Não se deve usar estado do CRM como prova de matrícula no LMS; matrícula pedagógica deve ser entidade explícita.

## 4. Modelo de dados (alto nível)

```text
organizations 1─N profiles
organizations 1─N leads 1─N lead_interactions
leads 1─N lead_stage_history
organizations 1─N courses 1─N modules 1─N lessons
profiles N─M courses (course_enrollments / course_teachers)
lessons 1─N lesson_assets
courses 1─N live_sessions; live_sessions 0..1─1 lesson
lessons 1─N assessments; assessments 1─N assessment_attempts
lessons 1─N survey_responses; profiles 1─N survey_responses
integration_events N─1 organizations
```

Relacionamentos e cardinalidades finais dependem de como LingoPro representa turmas, cursos e matrículas. Todos os registros de negócio devem ser associados a tenant e sujeitos a políticas explícitas.

## 5. Fluxos arquiteturais

### 5.1 Lead manual e movimentação

1. Usuário autenticado envia dados ao backend.
2. Backend valida papel, organização e campos.
3. Transação grava lead ou etapa e histórico.
4. Dashboard consulta agregações autorizadas.

### 5.2 Webhook WhatsApp

1. Endpoint verifica autenticidade conforme protocolo Meta e extrai evento.
2. Registra identificador único para deduplicação.
3. Normaliza telefone e associa ao lead ou cria novo.
4. Armazena mensagem conforme política de retenção e cria interação somente leitura.
5. Erros transitórios são reprocessáveis; payload sensível não é copiado para logs.

### 5.3 Acesso a conteúdo

1. Sessão autenticada solicita aula.
2. Backend e RLS verificam organização, matrícula ativa e estado publicado.
3. Dados da aula são retornados; arquivos recebem URL temporária autorizada.
4. Progresso é gravado com identidade do aluno e evento mínimo necessário.

### 5.4 Gravação para vídeo publicado

1. Job identifica gravação associada à turma/aula e registra estado.
2. Worker valida metadados e disponibilidade do arquivo.
3. Upload resumível é enviado ao YouTube e seu identificador é persistido.
4. Aplicação valida resultado e publica associação da aula.
5. Após confirmação, remoção da origem no Drive é agendada segundo retenção aprovada.
6. Falhas registram tentativa e agendam backoff; após três tentativas, alertam gestor.

## 6. Segurança, privacidade e continuidade

- RLS deny-by-default e testes automatizados para cada papel, inclusive acessos diretos.
- OAuth com escopos mínimos, armazenamento seguro e renovação/revogação controlada de tokens.
- Proteção contra replay e duplicação em webhooks; validação de assinatura segundo documentação oficial do provedor.
- HTTPS, cabeçalhos seguros, proteção contra abuso e tratamento uniforme de erros.
- Segredos em ambiente seguro; rotação documentada; logs sem tokens, links assinados ou conteúdo sensível.
- Política de retenção e exclusão para leads, mensagens, tentativas de avaliação, gravações e pesquisas.
- Backups e restauração testados; procedimento de incidente, auditoria e atendimento a solicitações de titulares.
- Revisão de LGPD e consentimento para gravação de aulas e tratamento de comentários antes de produção.

## 7. Operação e observabilidade

- Correlation ID propagado entre requisição, evento e job.
- Painel operacional: saúde de webhooks, fila de tarefas, idade do upload pendente, número de tentativas e falhas.
- Alertas acionáveis com responsável, severidade e instrução de recuperação.
- Ambientes separados e dados sintéticos em desenvolvimento/teste.
- Mudanças de schema compatíveis por etapas (expandir, migrar, contrair) quando houver dados de produção.

## 8. Decisões arquiteturais pendentes

- Estratégia de tenant: uma organização inicial ou SaaS multi-tenant desde o começo.
- Onde executar jobs, filas e cron com garantias de entrega e retentativa.
- Integração Google: APIs, escopos e caminho suportado para descobrir gravações.
- Associação estável entre Meet, Drive, turma, aula e vídeo.
- Armazenamento e retenção de mensagens WhatsApp e dados de pesquisa.
- Modelo de métricas e limites de volume para dashboards.
- Política de URL do YouTube: não listado não fornece controle de acesso; avaliar necessidade futura de streaming protegido.

## 9. ADRs sugeridos

Antes da implementação de integrações e escala, registrar decisões curtas em `docs/adr/`:

- ADR-001: modelo multi-tenant e RLS.
- ADR-002: execução de jobs e retentativas.
- ADR-003: identidade, papéis e fluxo de convite.
- ADR-004: gravação, publicação e retenção de vídeo.
- ADR-005: fórmulas de métricas e eventos de progresso.
