# Roadmap — LingoPro SaaS

**Versão:** 1.0  
**Status:** Proposta; sequência por dependências, sem compromisso de datas  
**Base:** [PRD](./PRD.md) · [Backlog](./BACKLOG.md)

## Direção

Entregar primeiro uma base segura e os fluxos de uso diário que não dependem de aprovações externas. Em seguida, validar LMS, integração e indicadores em incrementos. As etapas são gates de capacidade e aceite; duração e tamanho da equipe devem ser estimados após refinamento do backlog.

## Fase 0 — Descoberta e decisões

**Objetivo:** reduzir riscos de escopo e integração antes de construir automações dependentes de terceiros.

- Validar perfis, tenant, fluxo de matrícula e responsáveis comerciais.
- Definir fórmulas de conversão, SLA, conclusão de curso, aprovação e pesquisas.
- Prototipar navegação CRM/LMS com representantes dos quatro perfis.
- Confirmar acesso, escopos, quotas, consentimentos e limitações das APIs Meta, Google e YouTube.
- Aprovar política de privacidade, retenção, backup e resposta a incidentes.

**Gate de saída:** decisões críticas registradas; riscos de API e permissões testados em ambiente de desenvolvimento.

## Fase 1 — Fundação e segurança

**Objetivo:** preparar uma aplicação implantável e proteger dados por papel.

- Repositório e ambientes de desenvolvimento/staging/produção.
- Next.js, Supabase Auth, migrações e estrutura inicial.
- Perfis e políticas RLS testadas; logs e auditoria básicos.
- Pipeline de validação, testes e estratégia de rollback.

**Gate de saída:** testes demonstram isolamento de dados e as jornadas de autenticação funcionam em staging.

## Fase 2 — MVP Comercial

**Objetivo:** substituir planilhas no acompanhamento do funil.

- Cadastro manual e atribuição obrigatória de leads.
- Kanban, detalhes e histórico de interações/anotações.
- Transições validadas, motivo de perda e histórico de etapas.
- Sinalizadores de SLA e dormência; filtros operacionais.
- Dashboard comercial mínimo com definições documentadas.

**Gate de saída:** equipe comercial completa o fluxo de lead até matriculado/perdido; dados e métricas são conciliados com amostra real.

## Fase 3 — MVP Pedagógico

**Objetivo:** centralizar catálogo e materiais com acesso controlado.

- Cursos, módulos, aulas e vínculos de professores/alunos.
- Publicação de conteúdo, slides e materiais privados.
- Catálogo do aluno e controle de matrícula.
- Progresso básico e testes objetivos, conforme regras aprovadas.
- Gestão de usuários e conteúdo por papel.

**Gate de saída:** aluno não matriculado não consegue acessar conteúdo; professor só edita seus cursos; jornada de aula é validada por usuários piloto.

## Fase 4 — Integrações e experiência ao vivo

**Objetivo:** automatizar entrada de leads e o ciclo da aula online, começando por integrações com maior viabilidade.

- Webhook WhatsApp: validação, deduplicação, associação e criação de leads.
- Botão e vinculação de sala Meet para turma.
- Sincronização de gravações Google Drive, fila observável e retentativas.
- Upload para YouTube como não listado; publicação no LMS após confirmação.
- Remoção da gravação de origem somente após verificação e política aprovada.

**Gate de saída:** testes de ponta a ponta e recuperação de falha demonstram que eventos duplicados não duplicam leads/vídeos e que nenhum vídeo é publicado antes da confirmação.

## Fase 5 — Satisfação e dashboards ampliados

**Objetivo:** fechar o ciclo de feedback e dar visibilidade gerencial.

- Pesquisa pós-aula e pesquisa periódica de professores.
- Painel pedagógico, satisfação e operacional.
- Comentários recentes com controles de acesso apropriados.
- Ajustes de performance, acessibilidade e experiência com base no piloto.

**Gate de saída:** fórmulas e filtros dos indicadores aprovados; privacidade e acesso a respostas verificados.

## Fase 6 — Lançamento e melhoria contínua

**Objetivo:** operar produção com suporte e controle de risco.

- Testes de carga proporcionais ao uso esperado, auditoria de permissões e revisão de segurança.
- Exercício de backup/restauração e runbooks.
- Treinamento de gestores, comercial e professores.
- Lançamento gradual, monitoramento de métricas de sucesso do PRD e plano de reversão.

**Gate de saída:** responsáveis de negócio e tecnologia aprovam critérios de lançamento e há canal para suporte/incidentes.

## Indicadores de acompanhamento

- Lead → matrícula por origem e período.
- Tempo até primeiro contato e percentual de leads dentro do SLA.
- Leads sem responsável e leads dormentes.
- Matrículas ativas, progresso e retenção de alunos.
- Aulas ao vivo realizadas, vídeos pendentes e falhas de integração.
- Participação e resultados das pesquisas, com regras de privacidade.

## Dependências e riscos de calendário

- Aprovação e configuração de contas Meta, Google e YouTube podem alterar a ordem e duração da Fase 4.
- Quotas do YouTube e disponibilidade de gravações podem exigir processamento assíncrono e operação manual de contingência.
- Definições pendentes de tenant, matrícula e métricas afetam schema, políticas e relatórios; resolver na Fase 0.
- Dimensionamento de equipe, disponibilidade de stakeholders e migração de dados não foram informados; não há estimativas de calendário neste roadmap.
