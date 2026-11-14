# Estrutura do monorepo LingoPro

## Visão geral

O monorepo foi organizado para separar responsabilidades de produto e infraestrutura:

```text
lingopro/
├── apps/
│   └── web/
│       ├── app/
│       ├── components/
│       ├── lib/
│       ├── public/
│       └── package.json
├── packages/
│   └── ui/
│       └── src/
├── docs/
│   ├── PRD.md
│   ├── ESPECIFICACAO-TECNICA.md
│   ├── BACKLOG.md
│   ├── ROADMAP.md
│   ├── ARQUITETURA.md
│   ├── MODELO-BANCO-DE-DADOS.md
│   ├── ARQUITETURA-INTEGRACOES.md
│   └── ESTRUTURA-MONOREPO.md
├── package.json
├── turbo.json
├── .gitignore
└── README.md
```

## apps/web

Responsável pelo frontend principal do LingoPro:

- CRM de leads
- LMS estilo Netflix
- Dashboard administrativo
- autenticação e rotas protegidas

## packages/ui

Contém componentes compartilhados entre apps do monorepo, como:

- cards
- layouts
- formulários
- badging e indicadores de SLA

## docs

Armazena a documentação de produto, arquitetura e operação.

## Próximo nível

Depois desse scaffold, os próximos passos práticos são:

1. configurar Supabase e autenticação
2. criar as telas base do CRM e LMS
3. preparar rotas e guardas por perfil
4. implementar integração do WhatsApp e dos jobs de sincronização
