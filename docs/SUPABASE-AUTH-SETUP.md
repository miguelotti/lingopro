# Supabase Auth setup

Este documento resume a configuração mínima para autenticação do LingoPro com Supabase no monorepo.

## 1. Variáveis de ambiente

Copie o arquivo `.env.example` para `.env.local` e substitua os valores reais:

```bash
cp .env.example .env.local
```

Use os valores obtidos no painel do Supabase:

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`

## 2. Estrutura adicionada

- `apps/web/lib/supabase/client.ts`
- `apps/web/lib/supabase/server.ts`
- `apps/web/middleware.ts`
- `apps/web/app/login/page.tsx`
- `apps/web/app/dashboard/page.tsx`
- `apps/web/app/auth/callback/route.ts`

## 3. Fluxo ativo

- login por e-mail/senha na rota `/login`
- rota `/dashboard` protegida por middleware
- callback de autenticação para OAuth/email magic link

## 4. Próximo passo

Antes de rodar o app, configure no Supabase:

- Auth > Providers > E-mail
- Auth > URL redirect > `http://localhost:3000/auth/callback`
- criar usuários e validar login em ambiente local

## 5. Observações

Este é o scaffold inicial de autenticação. O próximo passo é implementar papéis (`manager`, `teacher`, `student`, `sales`) e regras de autorização no banco por organização.
