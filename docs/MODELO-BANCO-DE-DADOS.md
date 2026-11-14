# Modelo de Banco de Dados — LingoPro SaaS

**Versão:** 1.0  
**Status:** Proposta para revisão; não é ainda uma migração executável  
**Base:** [PRD](./PRD.md) · [Especificação Técnica](./ESPECIFICACAO-TECNICA.md) · [Arquitetura](./ARQUITETURA.md)

## 1. Decisões do modelo

- O desenho suporta multi-tenancy desde o início: toda entidade de negócio pertence a `organization_id`.
- Supabase Auth é a fonte de identidade; `profiles` guarda dados de aplicação e `organization_memberships` liga usuários a organizações e papéis.
- Papéis são por organização, permitindo que uma pessoa tenha papéis diferentes em organizações distintas.
- Matrícula pedagógica é independente da conversão no CRM. Um lead marcado como matriculado não concede acesso a cursos automaticamente sem uma matrícula explícita.
- IDs são UUID; timestamps são `timestamptz` em UTC. Datas exibidas usam o fuso configurado pela organização.
- Exclusões de dados de negócio devem ser preferencialmente lógicas ou seguir política de retenção aprovada; não apagar histórico comercial/auditoria em cascata inadvertidamente.

## 2. Diagrama lógico

```text
auth.users ──1:1── profiles
                   │
                   └──< organization_memberships >── organizations
                                                        ├──< kanban_stages
                                                        ├──< leads ──< lead_interactions
                                                        │          └──< lead_stage_history
                                                        └──< courses ──< course_modules ──< lessons
                                                                    ├──< enrollments >── profiles
                                                                    ├──< course_teachers >── profiles
                                                                    └──< live_sessions ──0..1── lesson
lessons ──< lesson_assets
lessons ──< assessments ──< assessment_attempts
lessons ──< satisfaction_responses
organizations ──< integration_events / audit_log
```

## 3. Tabelas e campos

Tipos e nomes são sugeridos; detalhes de índices e constraints devem ser revisados com as regras finais de negócio.

### Identidade e organização

| Tabela | Campos principais | Regras |
|---|---|---|
| `organizations` | `id`, `name`, `slug`, `timezone`, `created_at` | `slug` único; timezone IANA; configuração da escola/tenant |
| `profiles` | `id` (= `auth.users.id`), `display_name`, `email`, `phone`, `created_at`, `updated_at` | Não guardar senha; e-mail sincronizado/controlado pelo fluxo de Auth |
| `organization_memberships` | `id`, `organization_id`, `user_id`, `role`, `status`, `created_at` | `role`: `manager`, `teacher`, `student`, `sales`; único por organização/usuário |

### CRM

| Tabela | Campos principais | Regras |
|---|---|---|
| `kanban_stages` | `id`, `organization_id`, `name`, `stage_key`, `position`, `sla_hours`, `is_terminal`, `is_active` | `stage_key` estável; etapa final perdida exige motivo; não reutilizar chave removida |
| `leads` | `id`, `organization_id`, `stage_id`, `owner_user_id`, `student_name`, `student_age`, `course_interest`, `guardian_name`, `phone_e164`, `email`, `source`, `loss_reason`, `created_at`, `updated_at`, `last_interaction_at`, `last_moved_at`, `dormant_at` | Responsável obrigatório; telefone normalizado; motivo obrigatório em etapa perdida; `dormant_at` mantido por job ou derivado |
| `lead_stage_history` | `id`, `organization_id`, `lead_id`, `from_stage_id`, `to_stage_id`, `changed_by`, `changed_at`, `note` | Append-only para usuário comum; usado para SLA e conversão |
| `lead_interactions` | `id`, `organization_id`, `lead_id`, `created_by`, `channel`, `direction`, `body`, `provider_message_id`, `occurred_at`, `created_at` | Mensagens recebidas têm conteúdo somente leitura no CRM; `provider_message_id` deduplicado por organização |

Valores iniciais de `stage_key`: `new`, `contacted`, `meeting_scheduled`, `proposal_sent`, `enrollment_in_progress`, `enrolled`, `lost`. Etapas e SLAs são configuráveis; não codificar dependência apenas do nome visível.

### LMS

| Tabela | Campos principais | Regras |
|---|---|---|
| `courses` | `id`, `organization_id`, `title`, `description`, `cover_asset_id`, `status`, `created_at`, `updated_at` | `status`: `draft`, `published`, `archived` |
| `course_modules` | `id`, `organization_id`, `course_id`, `title`, `position` | Ordenação única por curso |
| `lessons` | `id`, `organization_id`, `module_id`, `title`, `description`, `duration_seconds`, `position`, `status`, `published_at` | Apenas aulas publicadas e autorizadas podem ser acessadas por alunos |
| `course_enrollments` | `id`, `organization_id`, `course_id`, `student_user_id`, `status`, `enrolled_at`, `ended_at` | Status: `active`, `completed`, `cancelled`; única matrícula ativa por aluno/curso |
| `course_teachers` | `organization_id`, `course_id`, `teacher_user_id`, `created_at` | Chave única composta; define escopo de edição do professor |
| `lesson_assets` | `id`, `organization_id`, `lesson_id`, `asset_type`, `storage_path`, `youtube_video_id`, `external_url`, `status`, `metadata`, `created_at` | Tipos: `video`, `slides`, `exercise`, `attachment`; não armazenar URLs assinadas persistentes |
| `lesson_progress` | `id`, `organization_id`, `lesson_id`, `student_user_id`, `progress_seconds`, `completed_at`, `last_viewed_at` | Único por aula/aluno; eventos detalhados só se houver necessidade de produto/privacidade |
| `assessments` | `id`, `organization_id`, `lesson_id`, `title`, `status`, `settings`, `created_at` | Configurações de aprovação/tentativas ainda pendentes |
| `assessment_attempts` | `id`, `organization_id`, `assessment_id`, `student_user_id`, `started_at`, `submitted_at`, `score`, `status` | Respostas vinculadas à tentativa; registrar versão do teste antes de produção |

### Aulas ao vivo, satisfação e operações

| Tabela | Campos principais | Regras |
|---|---|---|
| `live_sessions` | `id`, `organization_id`, `course_id`, `lesson_id`, `starts_at`, `ends_at`, `meet_space_name`, `meet_url`, `recording_state`, `created_at` | Link Meet acessível apenas a participantes autorizados; associação aula/gravação rastreável |
| `satisfaction_surveys` | `id`, `organization_id`, `survey_type`, `lesson_id`, `starts_at`, `ends_at`, `status`, `schema` | Tipos `post_lesson` e `teacher_periodic`; definir escala e anonimato |
| `satisfaction_responses` | `id`, `organization_id`, `survey_id`, `respondent_user_id`, `rating`, `comment`, `submitted_at` | Unicidade por respondente/pesquisa conforme política; restringir acesso a comentários |
| `integration_events` | `id`, `organization_id`, `provider`, `event_key`, `event_type`, `status`, `attempt_count`, `next_attempt_at`, `payload_ref`, `last_error_code`, `created_at`, `updated_at` | Idempotência por provedor/chave; payload bruto minimizado e com retenção curta |
| `audit_log` | `id`, `organization_id`, `actor_user_id`, `action`, `entity_type`, `entity_id`, `metadata`, `created_at` | Append-only para clientes; metadados sem segredos/dados excessivos |

## 4. Integridade e índices

- Usar constraints compostas para impedir referências cruzadas entre tenants. Exemplo conceitual: `leads` tem `UNIQUE (organization_id, id)` e `FOREIGN KEY (organization_id, stage_id) REFERENCES kanban_stages (organization_id, id)`.
- Aplicar o mesmo padrão a módulo/aula/curso, interações/lead, matrícula/curso e eventos/organização. Não depender apenas de checagem no frontend.
- Índices recomendados: `(organization_id, stage_id, last_moved_at)` em leads; `(organization_id, owner_user_id, stage_id)`; telefone normalizado com estratégia de deduplicação acordada; `(organization_id, lead_id, occurred_at DESC)` em interações; `(organization_id, course_id, status)` em matrículas; chaves de deduplicação em integrações.
- Índices únicos parciais devem cobrir matrícula ativa e eventos ainda não consumidos, conforme versão PostgreSQL/Supabase usada.
- Criar índices nos campos de relacionamento usados por políticas RLS; medir consultas dos dashboards antes de adicionar agregações/materialized views.
- NPS: armazenar respostas individuais com escala definida e calcular promotores/detratores em consulta agregada; não armazenar somente um NPS agregado sem fonte auditável.

## 5. RLS e matriz de acesso

Ativar RLS em todas as tabelas acessíveis pelo cliente e negar por padrão. Funções auxiliares de autorização precisam ser `SECURITY DEFINER` somente se necessário, com `search_path` fixo, permissões mínimas e testes contra recursão.

| Perfil | Acesso esperado |
|---|---|
| Gestor | Dados da organização e administração, conforme escopo; escrita auditada |
| Comercial | Leads e interações da organização; sem acesso automático a dados pedagógicos |
| Professor | Cursos associados, aulas e avaliações desses cursos; sem administração de usuários |
| Aluno | Cursos com matrícula ativa, aulas publicadas e dados próprios de progresso/tentativas/respostas |
| Serviço de integração | Apenas operação necessária; credencial nunca disponível ao cliente; auditar ações |

Em políticas, validar membership ativo e `organization_id` do registro. Para tabelas de vínculo, verificar acesso ao pai. Esconder uma rota ou botão não constitui autorização. Nunca permitir ao usuário elevar seu próprio papel editando `profiles` ou metadata controlável pelo cliente.

## 6. Regras transacionais

### Mudança de etapa do lead

Em uma transação: validar membership, garantir que a etapa pertence à mesma organização e está ativa, validar campos requeridos, exigir `loss_reason` para `lost`, atualizar lead e inserir histórico. Uma falha deve reverter ambas as gravações.

### Criação de lead por webhook

Deduplicar pelo ID de mensagem do provedor. Normalizar telefone. A regra para múltiplos leads com mesmo telefone e atribuição padrão precisa ser decidida. A criação do lead e da interação deve ser atômica ou recuperável por idempotência.

### Publicação de aula/vídeo

Manter estado do ativo separado do estado da aula. Só tornar vídeo disponível após upload confirmado e associação válida. Excluir gravação fonte depois do aceite do upload e política de retenção.

## 7. Decisões a aprovar antes da migração

1. Multi-tenant efetivo ou organização única inicialmente; o desenho proposto suporta ambos.
2. Se telefone/e-mail de responsável podem estar duplicados e quais campos são obrigatórios por etapa.
3. Se uma pessoa pode ser simultaneamente aluno, professor e/ou comercial na mesma organização.
4. Se há turmas/semestres além de cursos; provável entidade `cohorts` caso horário e matrícula sejam por turma.
5. Definição de progresso e conclusão, tentativas/nota, escala de satisfação e anonimato.
6. Política de retenção, exclusão, consentimento e auditoria segundo LGPD.
7. Se mensagens WhatsApp serão armazenadas integralmente ou apenas metadados e referência ao provedor.
8. Regras para reatribuição, merge e deduplicação de leads.

## 8. Próxima etapa de implementação

Após validar decisões pendentes: transformar o modelo em migrações SQL versionadas, implementar RLS junto com os testes de acesso, e validar consultas/índices em staging com dados sintéticos. Este documento não substitui revisão de segurança nem política de privacidade.
