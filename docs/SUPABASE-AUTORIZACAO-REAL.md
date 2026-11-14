# Supabase authorization foundation

Este documento descreve a implementação real de autorização proposta para o LingoPro.

## O que foi adicionado

- `supabase/schema.sql`

A estrutura inclui:

- `organizations`
- `profiles`
- `organization_memberships`
- `audit_log`
- trigger para criar perfil automaticamente em `auth.users`
- helper functions para listar organizações e verificar papéis
- RLS com base em organização e papel

## Papel de negócio

Os papéis definidos são:

- `manager`
- `teacher`
- `student`
- `sales`

## Regra central

A fonte de verdade para autorização é `organization_memberships`, e não `user.user_metadata` ou campos livres no frontend.

## Como aplicar em Supabase

1. Abra o SQL Editor do projeto Supabase.
2. Execute o conteúdo de `supabase/schema.sql`.
3. Crie a organização inicial.
4. Insira o primeiro usuário como `manager`.
5. Valide o login e a navegação por roles no app.

## Exemplo de criação de organização

```sql
insert into public.organizations (name, slug)
values ('LingoPro', 'lingopro');
```

## Exemplo de vínculo de usuário a organização

```sql
insert into public.organization_memberships (organization_id, user_id, role)
values (
  (select id from public.organizations where slug = 'lingopro'),
  'USER_UUID_HERE',
  'manager'
);
```

## Observação

Para produção, este modelo deve ser expandido com:

- políticas de curso por matrícula
- regras do CRM por responsável e organização
- itens de dashboard com filtros por organização
- logs de auditoria para alterações de papel e permissões

A base agora está pronta para sustentar a implementação real do sistema.
