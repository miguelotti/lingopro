# Backlog de Produto — LingoPro SaaS

**Versão:** 1.0  
**Status:** Draft para refinamento  
**Base:** [PRD](./PRD.md) e [Especificação Técnica](./ESPECIFICACAO-TECNICA.md)

## Convenções

- Prioridade: **P0** bloqueia MVP; **P1** importante após fundação; **P2** melhoria.
- Estimativa: T-shirt (S/M/L/XL), a refinar pela equipe.
- Critérios de aceite são observáveis; regras pendentes do PRD ficam marcadas para decisão.
- Histórias devem ser divididas em tarefas técnicas no planejamento da sprint.

## Épico 0 — Fundação e segurança

### US-001 — Inicializar aplicação e ambientes
**Como** equipe de desenvolvimento, **quero** configurar Next.js, Supabase e ambientes separados, **para** entregar mudanças reproduzíveis sem misturar dados de teste e produção.  
**Prioridade:** P0 · **Estimativa:** M

- Dado o repositório, quando o projeto é executado localmente, então configuração e instruções permitem iniciar a aplicação.
- Migrações de banco são versionadas e executáveis em ambiente limpo.
- Segredos ficam fora do código e há arquivo de exemplo sem valores secretos.

### US-002 — Acessar com perfil e sessão segura
**Como** usuário, **quero** autenticar por e-mail/senha, **para** acessar apenas as funções do meu perfil.  
**Prioridade:** P0 · **Estimativa:** M

- Sessão expirada exige nova autenticação.
- Rotas protegidas verificam autenticação no servidor.
- Google OAuth para professores/gestores fica condicionado à configuração e validação de escopos.

### US-003 — Isolar dados e permissões
**Como** gestor, **quero** que os dados sejam separados por organização e papel, **para** proteger informações de alunos e leads.  
**Prioridade:** P0 · **Estimativa:** L

- Usuário não lê ou altera registros fora de seu escopo, inclusive por chamada direta ao banco/API.
- Testes cobrem aluno, professor, comercial e gestor.
- Operações administrativas privilegiadas são auditáveis.

## Épico 1 — CRM e leads

### US-010 — Criar e atribuir lead manualmente
**Como** atendente comercial, **quero** cadastrar um lead e atribuir um responsável, **para** iniciar o acompanhamento.  
**Prioridade:** P0 · **Estimativa:** M

- Campos obrigatórios do PRD são validados.
- Todo lead salvo tem responsável e timestamps de criação/movimentação.
- Duplicidade por telefone apresenta opção de associar/atualizar, sem criar registro silenciosamente.

### US-011 — Visualizar pipeline Kanban
**Como** atendente, **quero** visualizar leads por etapa, **para** priorizar os próximos contatos.  
**Prioridade:** P0 · **Estimativa:** M

- Etapas aparecem na ordem configurada, com contagem de cards.
- Card mostra responsável, etapa, última movimentação e indicador de SLA.
- Filtros por responsável, origem e período funcionam.

### US-012 — Mover lead com validação
**Como** atendente, **quero** mover um lead no funil, **para** refletir o progresso comercial.  
**Prioridade:** P0 · **Estimativa:** M

- Campos obrigatórios da etapa são validados antes da mudança.
- Mudança registra usuário, data/hora, origem e etapa anterior/nova.
- Movimento para Perdido exige motivo categorizado.

### US-013 — Consultar histórico do lead
**Como** atendente, **quero** ver interações e mudanças de etapa, **para** dar continuidade ao atendimento.  
**Prioridade:** P0 · **Estimativa:** M

- Linha do tempo apresenta anotações e mudanças ordenadas por data.
- Anotações manuais identificam autor e horário.
- Mensagens de integração são somente leitura.

### US-014 — Sinalizar SLA e leads dormentes
**Como** gestor, **quero** identificar leads fora do SLA ou sem interação há 30 dias, **para** evitar perda de oportunidades.  
**Prioridade:** P0 · **Estimativa:** M

- Indicador usa o SLA configurado para a etapa.
- Lead sem interação pelo período definido é sinalizado como Dormente por processo idempotente.
- Visão de gestão permite filtrar atrasos e dormência.

### US-015 — Receber leads do WhatsApp
**Como** atendente, **quero** que mensagens recebidas sejam associadas ou criem leads, **para** reduzir cadastro manual.  
**Prioridade:** P1 · **Estimativa:** L

- Webhook verifica autenticidade e deduplica eventos.
- Número conhecido associa mensagem ao lead correspondente.
- Número novo cria lead e aplica regra de atribuição configurada.
- Falhas ficam registradas e podem ser reprocessadas sem duplicação.

## Épico 2 — LMS

### US-020 — Navegar catálogo de cursos
**Como** aluno, **quero** ver os cursos em que estou matriculado, **para** encontrar aulas e materiais.  
**Prioridade:** P0 · **Estimativa:** M

- Catálogo organiza cursos, módulos e aulas com descrição, duração e professor.
- Conteúdo de curso sem matrícula ativa não aparece nem pode ser acessado por URL direta.

### US-021 — Gerenciar conteúdo do curso
**Como** professor, **quero** criar e editar aulas dos cursos sob minha responsabilidade, **para** manter materiais atualizados.  
**Prioridade:** P0 · **Estimativa:** L

- Professor só altera cursos vinculados.
- Aula aceita metadados e tipos de conteúdo definidos no PRD.
- Publicação valida campos e permissões.

### US-022 — Consultar aula e materiais
**Como** aluno matriculado, **quero** assistir ao vídeo e abrir slides/exercícios, **para** estudar em um só lugar.  
**Prioridade:** P0 · **Estimativa:** M

- Conteúdo só fica disponível após publicação e autorização.
- Arquivos privados são entregues por acesso temporário autorizado.
- Progresso de visualização é registrado conforme regra de conclusão definida.

### US-023 — Realizar testes
**Como** aluno, **quero** responder questões objetivas e dissertativas, **para** acompanhar meu aprendizado.  
**Prioridade:** P1 · **Estimativa:** L

- Tentativas são vinculadas ao aluno e à versão do teste.
- Questões objetivas são corrigidas segundo gabarito; dissertativas seguem fluxo de avaliação.
- Limite de tentativas, nota de aprovação e revisão ficam pendentes de decisão.

### US-024 — Acessar sala ao vivo
**Como** aluno ou professor autorizado, **quero** entrar na sala Meet da turma, **para** participar da aula online.  
**Prioridade:** P1 · **Estimativa:** M

- Botão aparece apenas para a turma e janela de acesso autorizadas.
- Link não é exposto a usuários sem vínculo.
- A criação/gestão automatizada da sala depende da validação de APIs e permissões.

## Épico 3 — Gravação, integrações e satisfação

### US-030 — Acompanhar gravação e upload
**Como** gestor, **quero** acompanhar o processamento das gravações, **para** saber quando a aula estará disponível.  
**Prioridade:** P1 · **Estimativa:** XL

- Estado, horário, tentativas e erro operacional sanitizado são exibidos.
- Reprocessamento não cria uploads duplicados.
- Vídeo só é publicado no LMS após confirmação do upload.
- Origem no Drive só é removida após confirmação e política aprovada.

### US-031 — Responder pesquisa pós-aula
**Como** aluno, **quero** avaliar uma aula e deixar comentário, **para** contribuir com melhorias.  
**Prioridade:** P1 · **Estimativa:** M

- Pesquisa usa escala definida e campo aberto opcional.
- Uma resposta por aluno/aula (regra a confirmar) é aplicada.
- Respostas são visíveis apenas a perfis autorizados.

### US-032 — Responder pesquisa periódica
**Como** professor, **quero** responder pesquisa periódica, **para** compartilhar feedback sobre a experiência de ensino.  
**Prioridade:** P1 · **Estimativa:** M

- Convite e período de resposta são configuráveis.
- Resultado não expõe identidade além da permissão e política aprovadas.

## Épico 4 — Administração e indicadores

### US-040 — Administrar usuários e vínculos
**Como** gestor, **quero** criar usuários e atribuir perfis, cursos e permissões, **para** controlar o acesso à plataforma.  
**Prioridade:** P0 · **Estimativa:** L

- Gestor pode criar/editar/desativar usuários conforme política.
- Atribuições a curso e organização são validadas e auditadas.
- Usuário desativado não mantém acesso por sessão nova.

### US-041 — Configurar etapas e SLA
**Como** gestor, **quero** configurar etapas, ordem e SLA, **para** adaptar o funil à operação.  
**Prioridade:** P1 · **Estimativa:** M

- Configuração não apaga histórico existente.
- Alterações ficam auditadas e têm efeito previsível sobre leads já existentes.

### US-042 — Consultar dashboards
**Como** gestor, **quero** visualizar indicadores comerciais, pedagógicos, satisfação e operação, **para** acompanhar resultados.  
**Prioridade:** P1 · **Estimativa:** L

- Cada indicador tem fórmula, janela temporal e fuso documentados.
- Filtros por período e origem são coerentes com os dados de origem.
- Comentários recentes respeitam permissões e regras de privacidade.

## Épico 5 — Confiabilidade e lançamento

### US-050 — Monitorar integrações e tarefas
**Como** administrador, **quero** identificar falhas de webhook e uploads pendentes, **para** agir antes que os dados se percam.  
**Prioridade:** P0 · **Estimativa:** M

- Eventos e retentativas são rastreáveis por identificador de correlação.
- Alertas acionam responsáveis em falhas acima do limite definido.
- Logs não incluem segredos ou dados pessoais desnecessários.

### US-051 — Validar prontidão de produção
**Como** equipe, **quero** executar testes de segurança, backup e recuperação, **para** lançar com risco controlado.  
**Prioridade:** P0 · **Estimativa:** L

- RLS, jornadas E2E críticas e recuperação de backup são validadas em staging.
- Consentimento, retenção e políticas de privacidade foram aprovados.
- Runbooks de incidentes e integração estão disponíveis.

## Sequência recomendada

1. US-001 a US-003: fundação, identidade e isolamento.
2. US-010 a US-014: CRM funcional sem dependência de integração externa.
3. US-020 a US-022 e US-040: LMS básico e administração.
4. US-015, US-023/024 e US-031/032: integrações e funcionalidades pedagógicas complementares.
5. US-030, US-041/042 e US-050/051: automação, dashboards e prontidão.

## Pendências para refinamento

Definir tenant, fórmula de conversão e retenção, critérios de conclusão, escalas de pesquisa/NPS, distribuição de leads, regras de acesso ao Meet, tentativas e aprovação de testes, limiares de SLA e requisitos de privacidade. Estimativas não são compromisso de prazo.
