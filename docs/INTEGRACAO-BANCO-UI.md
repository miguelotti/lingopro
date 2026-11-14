# Integração inicial do banco com a UI

## Entregue

- CRM agora consulta etapas, contagens por etapa, total/dormentes e até 100 leads recentes via cliente Supabase autenticado.
- Formulário cria lead usando RPC transacional `create_lead_with_history`, atribui ao usuário autenticado e grava a etapa inicial no histórico.
- LMS lista cursos permitidos pela RLS e, para gestor/professor, mostra contagem de matrículas ativas.
- Painel exibe métricas de CRM/LMS autorizadas ao papel e à organização.
- Administração mostra contagem de memberships ativas e etapas do Kanban.
- RLS do LMS foi apertada: aluno precisa de matrícula ativa em curso publicado; professor precisa vínculo ao curso; gestor mantém visão administrativa.
- Migração cria etapas padrão para organizações existentes e para novas organizações.

## Aplicação

Aplicar migrações em ordem na instância Supabase:

1. schema base de organização/membership
2. migração de RPC/RLS para memberships
3. `20261114001000_crm_schema.sql`
4. `20261114002000_lms_schema.sql`
5. `20261114003000_secure_lms_and_crm_ui.sql`

As migrações devem ser testadas em staging antes de produção. O arquivo SQL existente `supabase/schema.sql` é uma referência inicial; o fluxo recomendado daqui em diante é `supabase/migrations/`.

## Limites atuais

- Leads: listagem recente e criação; edição, mudança de etapa, busca e paginação ainda não implementadas.
- LMS: leitura do catálogo autorizado; criação/edição de cursos, módulos e aulas ainda não implementadas.
- Métricas do painel são contagens simples, não substituem fórmulas completas de conversão, SLA, progresso ou retenção.
- O formulário usa o responsável autenticado como owner inicial.
- Não foi possível executar build/testes no ambiente deste commit; validar localmente com dependências e projeto Supabase de staging.
