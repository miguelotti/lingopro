# Arquitetura de Integrações — LingoPro SaaS

**Versão:** 1.0  
**Status:** proposta técnica para MVP  
**Base:** [PRD](./PRD.md), [Especificação Técnica](./ESPECIFICACAO-TECNICA.md), [Modelo de Banco de Dados](./MODELO-BANCO-DE-DADOS.md)

## 1. Objetivo

Definir como a plataforma conecta:

- WhatsApp (Meta Cloud API e webhook)
- Google Meet e Google Drive
- YouTube Data API
- módulos internos de CRM, LMS e dashboards

O objetivo principal é manter o fluxo confiável, rastreável e idempotente, mesmo quando integrações externas falham ou repetem eventos.

## 2. Princípios de arquitetura

- Toda integração externa fica em camada de servidor; o navegador nunca recebe chaves ou tokens sensíveis.
- Webhooks e jobs são idempotentes por `provider_event_id` ou `message_id`.
- Cada operação externa gera um `integration_event` para auditoria e retry.
- Estado da operação é representado explicitamente (`queued`, `processing`, `success`, `retry_wait`, `failed`, `cancelled`).
- Operações críticas são realizadas em transação interna e em retrabalho seguro: não publicar nenhum vídeo, link ou acesso antes da confirmação de upload.
- Logs têm `correlation_id` e não armazenam segredos nem payloads completos em texto sem controle.

## 3. Visão geral da composição

```text
Client (Next.js)
   │
   ▼
App API / Server Actions / Edge Functions
   │
   ├── CRM Module
   │      ├─ lead lifecycle
   │      ├─ interactions
   │      └─ SLA / dormancy
   │
   ├── LMS Module
   │      ├─ course / enrollment
   │      ├─ lesson / progress
   │      └─ surveys
   │
   ├── Integration Orchestrator
   │      ├─ WhatsApp webhook handler
   │      ├─ Meet/Drive sync worker
   │      ├─ YouTube uploader worker
   │      └─ retry scheduler
   │
   ├── Supabase/PostgreSQL
   │      ├─ leads
   │      ├─ lessons / progress
   │      ├─ live_sessions
   │      ├─ integration_events
   │      └─ audit_log
   │
   └── External providers
          ├─ Meta Cloud API / Webhook
          ├─ Google Meet API
          ├─ Google Drive API
          └─ YouTube Data API v3
```

## 4. Padrão de integração por provedor

### 4.1 Modelo comum

Cada integração implementa os mesmos blocos:

- `ingest`: recebe evento ou solicita operação externa
- `normalize`: transforma payload do provedor em modelo interno
- `validate`: checa organização, papel, status e regras de negócio
- `persist`: grava estado e metadados em `integration_events`
- `dispatch`: chama provider via servidor
- `ack`: atualiza status e libera dependências internas
- `retry`: reprocessa com backoff e limite configurado

### 4.2 Tabela central de eventos

A tabela `integration_events` deve conter pelo menos:

- `id`
- `organization_id`
- `provider` (`whatsapp`, `google_meet`, `google_drive`, `youtube`)
- `event_key` (ID do provedor ou chave de operação)
- `event_type` (`webhook`, `sync`, `upload`, `publish`)
- `status` (`queued`, `processing`, `success`, `retry_wait`, `failed`, `cancelled`)
- `attempt_count`
- `next_attempt_at`
- `payload_ref` ou `payload_summary`
- `response_ref`
- `last_error_code`
- `created_at`, `updated_at`

Regras:

- `provider + event_key` deve ser único para eventos deduplicáveis.
- `attempt_count` limita retries por job.
- `last_error_code` deve ser sanitizado: nunca armazenar token, segredo, conteúdo bruto de conversas sem necessidade.

## 5. Integração WhatsApp (Meta)

### 5.1 Objetivo

Receber mensagens de WhatsApp, criar ou associar leads e registrar o histórico de interações no CRM sem que o atendente precise cadastrar manualmente.

### 5.2 Fluxo

1. Meta envia `POST /api/webhooks/whatsapp` com evento do WhatsApp.
2. API interna verifica assinatura HMAC (ou mecanismo oficial do provedor) e valida `hub.mode` / `verify token` conforme documentação.
3. O sistema grava o evento em `integration_events` com status `processing`.
4. O handler normaliza o número de telefone (`E.164`) e identifica o lead.
5. Se o número já existe e pertence à organização, associa a mensagem ao lead.
6. Se o número não existe, cria um lead em `stage = new` e origem `whatsapp`. O esquema de atribuição do responsável é configurado pela organização.
7. A mensagem é persistida em `lead_interactions` com `channel = whatsapp`, `direction = inbound`, `provider_message_id` e `body` sanitizado.
8. O sistema retorna `200 OK` ao provedor para confirmar o processamento e evita reprocessar eventos duplicados.

### 5.3 Regras de deduplicação

- Usar `provider_message_id` ou ID do webhook do Meta como chave de deduplicação.
- Se o mesmo evento chegar duas vezes, o sistema deve ignorar o segundo e manter o primeiro.
- Caso o webhook se repita com diferença de payload, registrar em `integration_events` como `duplicate_detected`, sem criar comunicação extra.

### 5.4 Estado de lead e captura de contato

- Lead novo: `new`
- Mensagem recebida: `contacted` ao primeiro contato registrado e atribuído
- Respostas automáticas ou mensagens de follow-up devem ser separadas de `lead_interactions` e não devem alterar o estado sem aprovação do atendente.
- O status `dormant` fica calculado por job de SLA, não por webhook. O webhook não deve mover etapa por conta de novas mensagens sem regra explícita.

### 5.5 Segurança e controles

- Validar assinatura do webhook antes de qualquer escrita.
- Rate limiter por organização e por telefone.
- Limitar o tamanho de mensagens/arquivos e aplicar remoção de links por política de privacidade quando necessário.
- Nunca expor o conteúdo de mensagens em dashboards públicos ou para usuários sem acesso ao lead.

## 6. Integração Google Meet / Google Drive

### 6.1 Objetivo

Criar ou associar sala de aula à turma e processar gravações em sequência: `recording` → `drive` → `youtube` → `lms publication`.

### 6.2 Fluxo de criação da sala

1. Rotina interna cria/reconciliia uma sessão ao vivo vinculada à aula e à turma.
2. O backend chama Google Meet API para criar o espaço da reunião.
3. O sistema persiste `live_sessions` com:
   - `meet_space_name`
   - `meet_url`
   - `recording_state` inicial (`not_started`)
   - `status` (`scheduled`)
4. O link é exibido apenas para professores/alunos autorizados.

### 6.3 Fluxo de gravação

1. Quando a aula termina, o Google Drive recebe o arquivo de gravação.
2. Um worker de sincronização consulta a pasta de gravações da organização.
3. O sistema compara o nome/metadata do arquivo com `live_session_id` ou um identificador do evento do Meet.
4. Caso encontrado, atualiza `live_sessions.recording_state = detected` ou `recording_found`.
5. O arquivo é copiado para a fila de upload e um `integration_event` com `provider = google_drive` e `event_type = sync` é criado.
6. O arquivo temporário permanece em Drive até o upload para YouTube ser validado e a política de retenção permitir remoção.

### 6.4 Armazenamento temporário

- O Drive serve como buffer operacional, não como fonte final de navegação do LMS.
- O arquivo deve ser removido apenas após confirmação do upload e publicação do link no LMS.
- Princípio: “gravação local só é removida quando a publicação final estiver validada.”

### 6.5 Retry e observabilidade

- Se a gravação não aparecer em até N minutos, agendar retry com backoff.
- Se depois de 3 tentativas o arquivo não for encontrado, marcar `recording_state = failed` e notificar gestor.
- `audit_log` registra falha, owner e tentativa do job sem expor dados sensíveis.

## 7. Integração YouTube Data API

### 7.1 Objetivo

Publicar a gravação da aula em vídeo unlisted e associar o link ao material da aula no LMS sem expor o vídeo publicamente.

### 7.2 Fluxo

1. O worker de upload verifica se existe gravação pronta em Drive.
2. Cria o upload via YouTube Data API v3 com `privacyStatus: unlisted`.
3. Em caso de sucesso, grava no banco:
   - `lesson_assets.youtube_video_id`
   - `lesson_assets.status = published`
   - `live_sessions.youtube_video_id`
   - `live_sessions.recording_state = published`
4. Só após isso a aula pode ficar visível no LMS como material de vídeo.
5. O link do YouTube é exibido ao aluno somente com acesso autorizado no LMS.

### 7.3 Regras de envio

- O upload deve ser idempotente: o mesmo arquivo não deve ser enviado duas vezes para o mesmo `live_session_id`.
- Em caso de falha de rede, o worker reenvia com backoff.
- Em caso de falha persistente após três tentativas, registrar na fila de incidentes e notificar gestor.
- O `youtube_video_id` deve ser persistido antes de marcar o arquivo como concluído.

### 7.4 Risco de vazamento

O vídeo unlisted não é público e não entra em busca pública, mas ainda pode ser compartilhado por link. O LMS deve ser a camada de autorização: aluno só vê a aula se estiver matriculado, e o vídeo deve estar associado ao conteúdo correto.

## 8. Sequência end-to-end do ciclo da aula

```text
Aula agendada
   │
   ▼
Create Meet session
   │
   ▼
Aula acontece
   │
   ▼
Google Drive recebe gravação
   │
   ▼
Sync worker detects recording
   │
   ▼
YouTube upload (unlisted)
   │
   ▼
Persist video_id + lesson_asset
   │
   ▼
Publish link in LMS
   │
   ▼
Remove Drive source only after confirmation
```

## 9. Orquestração e jobs

### 9.1 Serviços necessários

- `webhook-processor`: processa eventos Meta
- `google-sync-worker`: localiza e sincroniza gravações do Drive
- `youtube-uploader`: envia vídeos e acompanha conclusão
- `sla-worker`: recalcula status de lead, dormancy e alertas
- `dashboard-job`: consolida métricas e indicadores periódicos

### 9.2 Estratégia de agendamento

Pode ser implementada em qualquer mecanismo de jobs suportado por Supabase/Vercel ou ferramenta dedicada; o importante é manter:

- idempotência
- retry configurável
- persistência de estado
- observabilidade
- segurança de tokens

### 9.3 Backoff recomendado

- 1ª falha: 2 minutos
- 2ª falha: 10 minutos
- 3ª falha: 30 minutos
- após o limite: notificar gestor, manter em fila somente se ainda houver possibilidade de recuperação

## 10. Contratos de integração sugeridos

### 10.1 Webhook WhatsApp (Meta)

Payload esperado:

```json
{
  "object": "whatsapp_business_account",
  "entry": [
    {
      "changes": [
        {
          "value": {
            "messaging_product": "whatsapp",
            "metadata": {
              "display_phone_number": "123456789",
              "phone_number_id": "abc-123"
            },
            "messages": [
              {
                "from": "5511999999999",
                "id": "wamid.HBg...",
                "timestamp": "1700000000",
                "text": { "body": "Olá" }
              }
            ]
          }
        }
      ]
    }
  ]
}
```

O sistema deve transformar isso em:

- `lead_interactions` com `channel = whatsapp`, `provider_message_id = wamid...`
- `lead` já existente ou novo
- `audit_log` da criação/associação

### 10.2 Evento de gravação/YouTube

O event model interno pode seguir:

```json
{
  "organization_id": "uuid",
  "provider": "youtube",
  "event_key": "video-id-or-job-id",
  "event_type": "upload",
  "status": "processing",
  "attempt_count": 1,
  "payload_ref": "youtube-upload-ctx",
  "next_attempt_at": "2026-11-14T12:00:00Z"
}
```

## 11. Segurança e governança de dados

- Verificar assinatura/signing secret do webhook do Meta.
- Acesso a Drive e YouTube deve ser via conta de serviço/serviço com menor privilégio possível.
- Não persistir tokens ou secrets em banco sem criptografia adequada.
- Registrar apenas metadados de operação e não o conteúdo bruto quando possível.
- Revisar política de retenção para mensagens, gravações e respostas de pesquisa antes de produção.
- Garantir que os links do YouTube não sejam acessíveis sem autenticação do LMS.

## 12. Critérios de aceite para a arquitetura de integrações

- Todo evento externo é rastreável por `integration_event` e `correlation_id`.
- Webhook duplicado não cria lead, mensagem ou upload duplicado.
- `google_drive` e `youtube` são separados em estados explícitos e com retry controlado.
- Vídeo só aparece no LMS quando o upload foi confirmado e associado à aula correta.
- Acesso ao CRM e ao LMS é validado por autorização e pela matrícula/organização.
- Falhas de integração não bloqueiam o uso normal do CRM/LMS, e o sistema permite reprocessamento seguro.

## 13. Próximos passos recomendados

1. Implementar a tabela `integration_events` e os job states.
2. Codificar o webhook do WhatsApp com validação de assinatura e idempotência.
3. Validar a estratégia de descoberta de gravações no Google Drive e o mapeamento para `live_sessions`.
4. Construir o worker de upload do YouTube em modo de retry e aprovação de publicação.
5. Conectar o fluxo ao LMS somente após a validação do vídeo publicado e do link correto.

Este documento é a base para a implementação operacional das integrações e deve ser revisado com as limitações reais das APIs de produção antes da codificação final.
