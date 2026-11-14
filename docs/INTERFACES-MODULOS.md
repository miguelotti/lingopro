# Interfaces iniciais do produto

Este bloco implementa a estrutura de navegação e páginas iniciais para Dashboard, CRM, LMS e Administração.

## Rotas

- `/dashboard`: visão inicial conforme membership ativa
- `/dashboard/crm` e `/dashboard/crm/leads`: gestor e comercial
- `/dashboard/lms` e `/dashboard/lms/classes`: gestor, professor e aluno
- `/dashboard/admin`: somente gestor

## Autorização

O papel é carregado via RPC `get_current_memberships()` a partir da tabela `organization_memberships`, não a partir de metadata controlável pelo usuário. A migração `supabase/migrations/20261114000100_membership_rpc_and_rls_fix.sql` cria a RPC e corrige políticas recursivas de leitura.

Enquanto não existir seletor de organização, o app aceita exatamente uma membership ativa; usuários com zero ou múltiplas memberships são enviados ao fluxo de login até existir uma experiência explícita de seleção.

## Estado da integração com dados

As páginas são scaffold de interface e autorização, não módulos de dados concluídos. Métricas aparecem como indisponíveis e listas mostram estados vazios; não há dados fictícios. As tabelas de leads, cursos, matrículas e aulas, seus RLS e operações de escrita ainda precisam ser implementadas antes de ativar ações.

## Próxima implementação

1. Criar migrações para CRM e LMS com chaves compostas por organização.
2. Implementar policies e testes negativos de RLS para cada perfil.
3. Conectar listagem e filtros a consultas no servidor.
4. Implementar formulários e transições via operações server-side auditadas.
