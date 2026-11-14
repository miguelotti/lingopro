# LingoPro

Monorepo inicial para a plataforma LingoPro SaaS.

## Estrutura

- `apps/web`: frontend principal em Next.js
- `packages/ui`: componentes compartilhados
- `docs`: documentação técnica do produto e arquitetura

## Primeiros passos

```bash
npm install
npm run dev
```

A aplicação principal fica em `apps/web` e usa Next.js para o front-end do CRM/LMS.

## Scripts

- `npm run dev` — inicia todos os apps em modo de desenvolvimento
- `npm run build` — build do monorepo
- `npm run lint` — lint dos pacotes
- `npm run typecheck` — checagem de tipos

## Observações

Este é o scaffold inicial do monorepo. A estrutura segue a arquitetura proposta para CRM, LMS e integração com WhatsApp / Google / YouTube.
