# Autorização por Perfil e Organização

## Objetivo

Definir a base de autorização do LingoPro por perfil e organização, antes da implementação completa do banco e das políticas RLS.

## Perfis base

Os perfis principais são:

- `manager`
- `teacher`
- `student`
- `sales`

A definição da rota e do layout do dashboard já usa esses valores como base para navegação e acesso, conforme o usuário autenticado.

## Regras de acesso sugeridas

- `manager`: acesso total à organização e administração
- `teacher`: acesso ao LMS, aulas, relatórios e conteúdo dos cursos vinculados
- `student`: acesso apenas a cursos com matrícula ativa e dados próprios
- `sales`: acesso ao CRM, leads e SLA, sem manipulação de conteúdo pedagógico

## Implementação atual

A base foi adicionada em:

- `apps/web/lib/auth/roles.ts`
- `apps/web/lib/auth/access.ts`
- `apps/web/app/dashboard/layout.tsx`

Esses pontos validam o papel do usuário via `user.user_metadata.role` ou `user.app_metadata.role` e permitem a extensão para um modelo real com tabela de memberships no banco.

## Próximo passo real de produção

Antes da implementação da autenticação completa, a solução adequada é:

1. criar a tabela `organization_memberships`
2. vincular usuário ao perfil e à organização
3. carregar esse papel do banco via Supabase RLS / Edge Function
4. remover a dependência de metadados no cliente

## Observação

Este arquivo representa a camada de autorização inicial, suficiente para orientar a estrutura do app e manter o código pronto para expansão.
