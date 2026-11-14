# Especificação Técnica — LingoPro SaaS

**Versão:** 1.0  
**Status:** Draft para validação  
**Base:** [PRD](./PRD.md)

## 1. Objetivo e princípios

Este documento traduz os requisitos do PRD em componentes, contratos e critérios técnicos para implementação. Decisões que dependem de credenciais, quotas ou validação de negócio estão marcadas como **a confirmar**.

Princípios:

- Isolar dados por organização/tenant e aplicar autorização no servidor e no banco.
- Tratar webhooks e tarefas de integração como operações idempotentes, rastreáveis e com retentativas.
- Não expor chaves de serviço ou tokens de terceiros ao navegador.
- Separar gravação, publicação de vídeo e disponibilidade do conteúdo no LMS.
- Registrar eventos relevantes para auditoria e suporte, evitando armazenar dados pessoais desnecessários.

## 2. Componentes e responsabilidades

| Componente | Responsabilidade |
|---|---|
| Next.js (Vercel) | Interface dos perfis, páginas protegidas, validação de formulários e chamadas ao backend |
| Supabase Auth | Identidade, sessão e autenticação por e-mail/senha ou Google OAuth |
| PostgreSQL/Supabase | Dados transacionais, políticas RLS, relatórios operacionais |
| Supabase Storage | PDFs, exercícios e arquivos temporários autorizados |
| Edge Functions | Webhooks, operações privilegiadas e orquestração de integrações |
| Worker agendado | SLA/dormentes, sincronização de gravações e retentativas; mecanismo de agendamento a confirmar |
| Meta Cloud API | Entrada de mensagens WhatsApp por webhook |
| Google Meet/Drive | Salas, eventos de gravação e armazenamento temporário |
| YouTube Data API | Upload e publicação como não listado |

## 3. Modelo de domínio

Entidades mínimas sugeridas:

- `organizations`: tenant e configurações gerais.
- `profiles`: dados de usuário vinculados a `auth.users`; papel: gestor, professor, aluno ou comercial.
- `courses`, `course_enrollments`, `course_teachers`: catálogo, matrículas e vínculos de responsabilidade.
- `modules`, `lessons`, `lesson_assets`: estrutura curricular, conteúdo e estado de publicação.
- `live_sessions`: turma, sala Meet, horários e estado da gravação.
- `assessments`, `questions`, `assessment_attempts`, `answers`: testes e resultados.
- `surveys`, `survey_responses`: satisfação pós-aula e periódica.
- `leads`, `lead_stage_history`, `lead_interactions`: dados comerciais, mudanças de etapa e histórico.
- `kanban_stages`: etapas configuráveis e SLAs.
- `integration_events`: eventos de webhook e tarefas, com estado, tentativas e erro sanitizado.
- `audit_log`: ações administrativas e alterações relevantes.

Tabelas de negócio devem conter `organization_id`, timestamps e, quando aplicável, `created_by`. Usar UUIDs como identificadores públicos. Definir regras de retenção para mensagens, gravações temporárias e auditoria antes do lançamento.

## 4. Autorização e segurança

- Ativar RLS em todas as tabelas acessíveis pelo cliente.
- Aluno: leitura de cursos/aulas publicados apenas quando houver matrícula ativa; escrita apenas em tentativas e pesquisas próprias.
- Professor: leitura e edição de conteúdo somente em cursos vinculados; sem gerenciamento de perfis de gestor.
- Comercial: acesso aos leads da organização e atualização conforme permissões; acesso pedagógico não concedido por padrão.
- Gestor: administração conforme organização. Operações privilegiadas usam funções de servidor e validação explícita.
- O papel não deve ser confiado a metadados editáveis pelo próprio usuário; validar permissões com dados controlados pelo servidor.
- Validar assinatura/token dos webhooks, limitar tamanho e tipo de payload, aplicar rate limiting e proteger contra repetição de eventos.
- Guardar segredos em variáveis seguras da plataforma; nunca em código, logs ou bundles do navegador.
- Documentar consentimento, base legal, acesso e retenção de dados pessoais conforme LGPD antes de produção.

## 5. Fluxos funcionais e estados

### CRM

Estados iniciais configuráveis: `novo`, `contato_realizado`, `reuniao_agendada`, `proposta_enviada`, `matricula_em_andamento`, `matriculado`, `perdido`. A configuração de transições permitidas e campos obrigatórios por etapa deve ser administrável e auditada.

Ao mover um lead:

1. Validar organização, permissão, etapa de destino e campos requeridos.
2. Exigir motivo categorizado se o destino for `perdido`.
3. Atualizar etapa e `last_moved_at` em transação.
4. Inserir evento em `lead_stage_history`.
5. Atualizar métricas e sinalizações sem bloquear a operação caso um relatório assíncrono falhe.

A classificação `dormente` deve ser derivada de ausência de interação por 30 dias, usando configuração de timezone organizacional e job idempotente. SLA por etapa deve usar o tempo desde a última entrada naquela etapa; limiares amarelo/vermelho são configuráveis (a confirmar).

### WhatsApp

O endpoint de webhook verifica a requisição, registra identificador do evento e processa de forma idempotente. Normaliza telefone em formato internacional. Número desconhecido cria lead em estado `novo`, com origem WhatsApp e atribuição conforme regra configurável; a regra de distribuição/usuário padrão é **a confirmar**. Número existente associa a interação ao lead. Conteúdo é somente leitura no CRM, conforme PRD.

### LMS e avaliações

A publicação de aula exige curso, módulo e permissões válidos. O acesso ao ativo deve passar por verificação de matrícula; para arquivos privados, emitir URL assinada de curta duração. Registrar progresso com eventos mínimos para calcular conclusão e retenção. Regras de aprovação, tentativas e pontuação de questões dissertativas precisam ser definidas antes de implementar avaliações.

### Meet, Drive e YouTube

Estados sugeridos: `scheduled` → `recording_expected` → `recording_found` → `upload_pending` → `uploading` → `published` → `source_cleanup_pending` → `complete`; falhas ficam em `retry_wait` ou `failed` com estado recuperável.

A automação deve associar gravação à turma/aula por identificador e metadados confiáveis, realizar upload resumível quando disponível, gravar o ID do vídeo e só então publicar o link no LMS. Excluir a origem do Drive apenas após confirmação do upload e verificação do ativo publicado. Aplicar backoff exponencial com limite de três tentativas conforme PRD, alertando gestor quando esgotado. Idempotência evita vídeos duplicados após repetição de job.

**Dependência a validar:** permissões e disponibilidade das APIs do Meet/Drive, política de gravação e consentimento, fluxo de exportação do arquivo e quotas da YouTube Data API. O PRD cita Meet REST API; confirmar endpoints e escopos efetivamente disponíveis para o tipo de conta antes de fechar a integração.

## 6. Interfaces/API sugeridas

Implementar operações via Server Actions/Route Handlers ou Edge Functions, escolhendo um padrão único. Exemplos conceituais:

- `POST /api/leads` — criar lead.
- `PATCH /api/leads/{id}/stage` — validar e registrar mudança de etapa.
- `POST /api/webhooks/whatsapp` — receber eventos Meta.
- `GET /api/courses/{id}/lessons` — catálogo filtrado por autorização.
- `POST /api/lessons/{id}/progress` — registrar progresso autenticado.
- `POST /api/surveys/{id}/responses` — responder pesquisa.
- `POST /api/integrations/recordings/sync` — operação interna protegida para sincronização.

Respostas devem usar códigos HTTP consistentes, mensagens sem dados sensíveis e identificador de correlação. Contratos detalhados devem ser definidos em OpenAPI ou schemas tipados compartilhados.

## 7. Observabilidade e qualidade

- Logs estruturados com `request_id`, organização, tipo de evento e resultado; omitir tokens e conteúdo pessoal.
- Métricas: falhas/latência de webhook, leads sem responsável, atraso de SLA, fila de uploads, retentativas e erros de autorização.
- Alertas para webhook indisponível, falhas de integração repetidas e uploads pendentes acima do limite operacional.
- Testes unitários de regras; integração para RLS e webhooks; E2E para jornadas por perfil; teste de restauração de backup.
- Ambientes separados de desenvolvimento, staging e produção; migrações versionadas e estratégia de rollback.

## 8. Critérios de aceite técnico para MVP

- RLS e testes verificam isolamento entre organizações e papéis.
- Mudanças de etapa e motivo de perda são validados no servidor e auditados.
- Webhook duplicado não duplica mensagens nem leads.
- Conteúdo do LMS não pode ser lido sem matrícula autorizada.
- Estados de gravação/upload são recuperáveis e visíveis no dashboard.
- Segredos não aparecem no cliente ou nos logs; erros e retentativas são monitoráveis.
- Dashboards exibem definições de métricas documentadas e resultados conciliáveis com os dados de origem.

## 9. Decisões pendentes

1. Tenant único LingoPro ou produto multi-organização desde o MVP.
2. Regra de distribuição e responsável padrão para leads recebidos.
3. Limiares de SLA e calendário/fuso horário.
4. Regras de conclusão de curso, aprovação e tentativas de testes.
5. Fonte de verdade para turmas, agenda e associação de gravação à aula.
6. Escopos e fluxo OAuth Google/YouTube, quotas e estratégia de renovação de tokens.
7. Retenção de mensagens, arquivos, pesquisas e auditoria; consentimento aplicável.
8. Provedor e mecanismo de jobs agendados, alertas e suporte operacional.
