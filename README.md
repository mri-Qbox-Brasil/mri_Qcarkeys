# mri_Qcarkeys 🔑

Sistema completo de gerenciamento de chaves veiculares para FiveM com chaves permanentes/temporárias, lockpick, hotwiring, carjacking e key stacking. Baseado no **mm_carkeys** do Master Mind.

## Principais recursos

- 🔑 **Chaves permanentes e temporárias** — Sistema dual de chaves com itens de inventário.
- 🔒 **Trancar/destrancar com animação** — Key fob animation + sons de lock/unlock.
- 🔧 **Hotwiring** — Minigame de ligação direta com chance escalada por nível de reputação.
- 🪛 **Lockpick de porta e motor** — Suporte a ox_lib skill check ou minigame alternativo.
- 🚗 **Carjacking** — Roubo de veículos de NPCs com chance baseada na arma utilizada.
- 📦 **Key stacking** — Consolidar todas as chaves em um único `keybag`.
- 🎒 **Key grabbing** — Pegar chaves de NPCs vivos ou mortos em veículos.
- 🌐 **Multi-framework** — Compatível com QBCore, QBX, ESX e ox_core.
- 📦 **Multi-inventory** — Compatível com ox_inventory, qb-inventory, ps-inventory, mm_inventory, qs-inventory.

## Instalação rápida

1. Copie a pasta `mri_Qcarkeys` para a pasta de resources do servidor.
2. Adicione `ensure mri_Qcarkeys` no `server.cfg` (após o framework e inventory).
3. Tenha `ox_lib` instalado e disponível.
4. Adicione os itens necessários ao seu inventory (veja [Itens necessários](#itens-necessários-inventory)).

## Configuração (shared/shared.lua) ⚙️

### Opções gerais

| Opção | Padrão | Descrição |
|---|---|---|
| `LockNPCVehicle` | `false` | Trancar todos os veículos NPCs quando o jogador se aproxima. |
| `playerDraggable` | `true` | Permitir que jogadores arrastem outros jogadores. |
| `toggleLightsOnlyRemote` | `true` | Alternar luzes apenas quando fora do veículo. |
| `keepVehicleEngineOn` | `true` | Manter motor ligado ao sair do veículo. |
| `keepKeysInVehicle` | `true` | Chaves ficam no veículo; motor não liga sem elas. |

### Carjacking (`steal`)

| Opção | Padrão | Descrição |
|---|---|---|
| `steal.available` | `true` | Habilitar carjacking. |
| `steal.getKey` | `"permanent"` | Tipo de chave recebida: `"permanent"`, `"temporary"`, `"none"`. |
| `steal.chance` | Por arma | Chance de sucesso por categoria de arma (hash). |

### Lockpick (`lockpick`)

| Opção | Padrão | Descrição |
|---|---|---|
| `lockpick.minigameScript` | `"ox_lib"` | `"ox_lib"` ou `"inside-lockpicking"`. |
| `lockpick.breakChance` | `0.5` | Chance do lockpick quebrar (normal). |
| `lockpick.advancedBreakChance` | `0.1` | Chance do lockpick quebrar (avançado). |

### Hotwiring (`hotwire`)

| Opção | Padrão | Descrição |
|---|---|---|
| `hotwire.available` | `true` | Habilitar hotwiring. |
| `hotwire.chance` | `0.1` | Chance base de sucesso (escalada por nível cw-rep). |

### Key Grabbing (`grab`)

| Opção | Padrão | Descrição |
|---|---|---|
| `grab.alive` | `true` | Permitir pegar chaves de NPCs vivos. |
| `grab.leaveKeysOnVehicle` | `true` | Deixar chaves no veículo ao pegar. |

### Classes e armas bloqueadas

- `blacklistedClasses`: 13-16, 21 (bicicletas, barcos, helicópteros, aviões, trens)
- `BlackListedWeapon`: 28 armas corpo a corpo/arremessáveis que não podem fazer carjacking.

## Controles

| Tecla | Ação |
|---|---|
| **L** | Trancar/destrancar veículo (`togglelocks`). |
| **Z** | Ligar/desligar motor (`mri:engine`). |
| **H** | Hotwiring (quando dentro de veículo sem chave). |

## Comandos

| Comando | Restrito | Descrição |
|---|---|---|
| `/givetempkeys [target] [plate]` | `group.admin` | Dar chaves temporárias. |
| `/removetempkeys [target] [plate]` | `group.admin` | Remover chaves temporárias. |
| `/givekeys` | police/cardealer/admin | Dar chave permanente do veículo atual. |
| `/removekeys` | police/cardealer/admin | Remover chave permanente do veículo atual. |
| `/stackkeys` | Não | Consolidar todas as chaves em um keybag. |
| `/unstackkeys` | Não | Separar keybag em chaves individuais. |

## Exports

### Client

| Export | Parâmetros | Descrição |
|---|---|---|
| `GiveTempKeys` | `(plate)` | Dar chave temporária para uma placa. |
| `RemoveTempKeys` | `(plate)` | Remover chave temporária para uma placa. |
| `GiveKeyItem` | `(plate)` | Dar item de chave permanente. |
| `RemoveKeyItem` | `(plate)` | Remover item de chave permanente. |
| `HaveTemporaryKey` | `(plate)` | Retorna `boolean`. |
| `HavePermanentKey` | `(plate)` | Retorna `boolean`. |

### Server

| Export | Parâmetros | Descrição |
|---|---|---|
| `GiveTempKeys` | `(src, plate)` | Dar chave temporária ao jogador. |
| `RemoveTempKeys` | `(src, plate)` | Remover chave temporária do jogador. |
| `GiveKeyItem` | `(src, plate, netId)` | Dar item de chave permanente. |
| `RemoveKeyItem` | `(src, plate)` | Remover item de chave permanente. |
| `HaveTemporaryKey` | `(src, plate)` | Retorna `boolean` via callback. |
| `HavePermanentKey` | `(src, plate)` | Retorna `boolean` via callback. |

## Itens necessários (inventory)

```lua
['vehiclekey'] = {
    label = 'CHAVE',
    weight = 50,
    type = 'item',
    image = 'vehiclekey.png',
    description = 'Chave de veículo',
    client = { status = { hunger = -10000 } },
},
['keybag'] = {
    label = 'Chaveiro',
    weight = 100,
    type = 'item',
    image = 'keybag.png',
    description = 'Um chaveiro com várias chaves',
},
['lockpick'] = {
    label = 'Gazuas',
    weight = 100,
    type = 'item',
    image = 'lockpick.png',
    description = 'Gazuas para abrir fechaduras',
},
['advancedlockpick'] = {
    label = 'Gazuas Avançadas',
    weight = 150,
    type = 'item',
    image = 'advancedlockpick.png',
    description = 'Gazuas avançadas com menor chance de quebrar',
},
```

## Dependências

### Obrigatórias

- `ox_lib` — UI, menus, progress bars, notificações.

### Opcionais (auto-detected)

- **Frameworks**: `qb-core`, `qbx_core`, `es_extended`, `ox_core`
- **Inventories**: `ox_inventory`, `qb-inventory`, `ps-inventory`, `mm_inventory`, `qs-inventory`
- `rep-enginewire` — Minigame alternativo de hotwiring.
- `inside-lockpicking` — Minigame alternativo de lockpick.
- `cw-rep` — Sistema de reputação/habilidade para hotwiring e lockpick.
- `InteractSound` — Sons de lock/unlock.

## Estrutura de arquivos 📁

```
mri_Qcarkeys/
├── bridge/
│   ├── framework/
│   │   ├── esx.lua              # Integração ESX
│   │   ├── ox.lua               # Integração ox_core
│   │   ├── qb.lua               # Integração QBCore
│   │   └── qbox.lua             # Integração QBX
│   └── inventory/
│       └── client.lua           # Abstração de inventory
├── client/
│   ├── init.lua                 # Entry point: vehicle cache hooks, exports
│   ├── interface.lua            # Objeto VehicleKeys state
│   └── modules/
│       ├── keys.lua             # Gerenciamento de chaves, lock/unlock, engine
│       ├── hotwire.lua          # Minigame de hotwiring
│       ├── lockpick.lua         # Lockpick de porta e motor
│       ├── steal.lua            # Carjacking e key grabbing
│       └── utils.lua            # Helpers: weapon blacklist, ped enumeration
├── server/
│   ├── bridge.lua               # Abstração framework/inventory
│   ├── commands.lua             # Comandos admin/player
│   └── server.lua               # Lógica principal: distribuição, stacking
├── shared/
│   ├── init.lua                 # Auto-detecção de framework e inventory
│   └── shared.lua               # Configurações
├── fxmanifest.lua
└── README.md
```

## Eventos principais

### Client → Server

| Evento | Descrição |
|---|---|
| `mm_carkeys:server:setVehLockState` | Definir estado de trancamento do veículo. |
| `mm_carkeys:server:acquiretempvehiclekeys` | Requisitar chaves temporárias. |
| `mm_carkeys:server:removetempvehiclekeys` | Remover chaves temporárias. |
| `mm_carkeys:server:acquirevehiclekeys` | Requisitar chave permanente. |
| `mm_carkeys:server:removevehiclekeys` | Remover chave permanente. |
| `mm_carkeys:server:stackkeys` | Stack de chaves em keybag. |
| `mm_carkeys:server:unstackkeys` | Unstack keybag em chaves individuais. |

### Server → Client

| Evento | Descrição |
|---|---|
| `mm_carkeys:client:addtempkeys` | Adicionar chave temporária na lista do cliente. |
| `mm_carkeys:client:removetempkeys` | Remover chave temporária da lista do cliente. |
| `mm_carkeys:client:setplayerkey` | Definir chave permanente. |
| `mm_carkeys:client:removeplayerkey` | Remover chave permanente. |
| `mm_carkeys:client:givekeyitem` | Progress bar de dar chave. |
| `mm_carkeys:client:stackkeys` | Progress bar de stack. |
| `mm_carkeys:client:unstackkeys` | Progress bar de unstack. |

## Observações importantes ⚠️

- Quando `keepKeysInVehicle = true`, o veículo verifica o entity state `keysIn` antes de permitir ligar o motor. Desligar o motor consome a chave permanente e concede temporária.
- O stacking converte todos os itens `vehiclekey` em um único `keybag` com metadata de placas.
- A chance de hotwiring é escalada pelo nível de reputação no `cw-rep` (níveis 1-8).
- Carjacking tem cooldown de 5 segundos entre tentativas.
- NPCs ocupantes fogem quando um carjacking é bem-sucedido.

Contribuições e melhorias são bem-vindas — abra PRs ou issues. 🙌
