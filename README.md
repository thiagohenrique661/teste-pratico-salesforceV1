# Pedido de Suporte — Salesforce Project

Projeto Salesforce para gerenciamento de **Pedidos de Suporte** com arquitetura limpa (Clean Architecture), separação de responsabilidades por camada e injeção de dependência.

---

## Arquitetura

```
┌─────────────────────────────────────────────────────┐
│                    Entry Points                      │
│  Trigger · REST Resource · Batch · Schedulable       │
│  (controllers/ · batch/)                             │
└──────────────────────┬──────────────────────────────┘
                       │  instancia
                       ▼
┌─────────────────────────────────────────────────────┐
│                  Service Layer                        │
│  Regras de negócio, validações, orquestração         │
│  (services/)                                         │
└──────────────────────┬──────────────────────────────┘
                       │  depende de interface
                       ▼
┌─────────────────────────────────────────────────────┐
│             Interfaces (contratos)                    │
│  IPedidoSuporteSelector · IInteracaoSelector         │
│  (interfaces/)                                       │
└──────────────────────┬──────────────────────────────┘
                       │  implementa
                       ▼
┌─────────────────────────────────────────────────────┐
│            Selector / Data Access Layer               │
│  SOQL centralizado, CRUD/FLS (SECURITY_ENFORCED)     │
│  (selectors/)                                        │
└─────────────────────────────────────────────────────┘
```

### Princípios

| Princípio | Como é aplicado |
|---|---|
| **Dependency Inversion** | Services e Batch dependem de interfaces (`IPedidoSuporteSelector`, `IInteracaoSelector`), não de implementações concretas |
| **Single Responsibility** | Cada camada tem uma única responsabilidade (dados, regras, orquestração) |
| **Bulkification** | Todo código Apex é bulk-safe — nenhum SOQL/DML dentro de loop |
| **CRUD/FLS** | Todas as queries usam `WITH SECURITY_ENFORCED` |
| **Testabilidade** | Construtores com DI permitem injetar mocks nos testes |

---

## Estrutura de Pastas

```
force-app/main/default/
├── classes/
│   ├── interfaces/      ← Contratos (IPedidoSuporteSelector, IInteracaoSelector)
│   ├── selectors/       ← Acesso a dados (SOQL), implementam interfaces
│   ├── services/        ← Regras de negócio e validações
│   ├── dtos/            ← Data Transfer Objects (payloads REST)
│   ├── controllers/     ← Entry points (TriggerHandler, RestResource)
│   ├── batch/           ← Batch Apex e Schedulable
│   └── tests/           ← Classes de teste (@IsTest)
├── triggers/            ← Triggers (1 por objeto, delega ao Handler)
└── objects/             ← Metadata de objetos customizados
```

---

## Objetos Customizados

| Objeto | Descrição |
|---|---|
| `PedidoSuporte__c` | Pedido de suporte do cliente |
| `Interacao__c` | Interações associadas a um pedido (Agente / Cliente) |

### Campos principais — PedidoSuporte__c

| Campo | Tipo | Descrição |
|---|---|---|
| `Status__c` | Picklist | Novo, Em Atendimento, Aguardando Cliente, Resolvido, Cancelado |
| `Prioridade__c` | Picklist | Alta, Média, Baixa |
| `Descricao__c` | Text Area | Descrição do problema |
| `Cliente__c` | Lookup(Account) | Conta do cliente |
| `UltimaInteracao__c` | DateTime | Data/hora da última interação |

---

## Funcionalidades

### 1. Validação na Trigger (before update)

**Classe:** `PedidoSuporteService`

- **Alta prioridade → Resolvido:** Só permite se houver pelo menos uma `Interacao__c` do tipo `Agente`.
- **Resolvido → Cancelado:** Bloqueia — não é permitido cancelar um pedido já resolvido.

**Fluxo:**
```
PedidoSuporteTrigger → PedidoSuporteTriggerHandler → PedidoSuporteService
                                                         ↓
                                                    IInteracaoSelector
                                                         ↓
                                                    InteracaoSelector (SOQL)
```

### 2. API REST — Criar Pedido

**Endpoint:** `POST /services/apexrest/pedidos-suporte`

**Payload:**
```json
{
    "clienteId":  "001XXXXXXXXXXXX",
    "descricao":  "Problema no sistema",
    "prioridade": "Alta"
}
```

**Respostas:**
| HTTP | Body |
|---|---|
| 201 | `{ "pedidoId": "a01XXXXXXXXXXXX" }` |
| 400 | `{ "erro": "mensagem de validação" }` |
| 500 | `{ "erro": "Erro interno. Tente novamente mais tarde." }` |

**Fluxo:**
```
PedidoSuporteRestResource → PedidoSuporteRestService → insert PedidoSuporte__c
                                ↓
                         PedidoSuporteRestDTO (payload / exceções)
```

### 3. Batch — Inatividade de Pedidos

**Classe:** `PedidoSuporteInativoBatch`

Identifica pedidos sem interação há mais de **3 dias**, atualiza status para `"Aguardando Cliente"` e envia e-mail de notificação ao cliente.

**Agendamento (executar todo dia às 02:00):**
```apex
String cron = '0 0 2 * * ?';
System.schedule(
    'Pedido Suporte - Inatividade Diária',
    cron,
    new PedidoSuporteInativoSchedulable()
);
```

**Execução manual:**
```apex
Database.executeBatch(new PedidoSuporteInativoBatch(), 200);
```

**Fluxo:**
```
PedidoSuporteInativoSchedulable → PedidoSuporteInativoBatch
                                       ↓
                                  IPedidoSuporteSelector
                                       ↓
                                  PedidoSuporteSelector (SOQL)
```

---

## Injeção de Dependência

Os Services e o Batch recebem dependências via construtor:

```apex
// Construtor padrão (produção) — injeta implementação concreta
public PedidoSuporteService() {
    this.interacaoSelector = new InteracaoSelector();
}

// Construtor para testes — injeta mock
@TestVisible
private PedidoSuporteService(IInteracaoSelector interacaoSelector) {
    this.interacaoSelector = interacaoSelector;
}
```

---

## Testes

| Classe de Teste | Cobre |
|---|---|
| `PedidoSuporteTriggerTest` | Validações da trigger (7 cenários incl. bulk) |
| `PedidoSuporteRestResourceTest` | Endpoint REST (5 cenários de payload) |
| `PedidoSuporteInativoBatchTest` | Batch + Schedulable (6 cenários incl. bulk) |

**Via SF CLI:**
```bash
sf apex run test --test-level RunLocalTests --result-format human
```

---

## Pré-requisitos

- Salesforce CLI (sf) v2+
- Node.js 18+ (para LWC jest)
- VS Code + Salesforce Extension Pack

## Setup Local

```bash
# Clonar o projeto
git clone <repo-url>
cd salesforce

# Instalar dependências Node (jest, eslint, prettier)
npm install

# Criar scratch org
sf org create scratch -f config/project-scratch-def.json -a pedido-suporte -d 30

# Deploy para scratch org
sf project deploy start

# Rodar testes
sf apex run test --test-level RunLocalTests
```
