# mri_Qcarkeys - Manual Funcional

Sistema completo de gerenciamento de chaves veiculares para FiveM com chaves permanentes/temporárias, lockpick, hotwiring, carjacking e key stacking.

## O que o recurso faz

O mri_Qcarkeys gerencia todo o sistema de chaves de veículos, permitindo que jogadores tenham chaves permanentes (itens no inventário) e temporárias (armazenadas no estado da entidade), com suporte a trancar/destrancar veículos com animação e sons, hotwiring com minigame, lockpick de portas e motor, roubo de veículos (carjacking) e consolidação de chaves em um keybag.

## Funcionalidades principais

- **Chaves permanentes e temporárias**: Sistema dual de chaves com itens de inventário
- **Trancar/destrancar com animação**: Key fob animation + sons de lock/unlock
- **Hotwiring**: Minigame de ligação direta com chance escalada por nível de reputação
- **Lockpick de porta e motor**: Suporte a ox_lib skill check ou minigame alternativo
- **Carjacking**: Roubo de veículos de NPCs com chance baseada na arma utilizada
- **Key stacking**: Consolidar todas as chaves em um único `keybag`
- **Key grabbing**: Pegar chaves de NPCs vivos ou mortos em veículos
- **Multi-framework**: Compatível com QBCore, QBX, ESX e ox_core
- **Multi-inventory**: Compatível com ox_inventory, qb-inventory, ps-inventory, mm_inventory, qs-inventory

## Como funciona

1. Jogador recebe chave permanente (item) ou temporária (estado da entidade)
2. Ao se aproximar de um veículo, o sistema verifica se possui chave
3. Tecla L tranca/destranca o veículo com animação e som
4. Tecla Z liga/desliga o motor (se tiver chave)
5. Sem chave, tecla H inicia hotwiring (minigame)
6. Lockpick e carjacking disponíveis conforme configuração

## Configurações disponíveis (shared/shared.lua)

### Opções gerais
| Opção | Padrão | Descrição |
|-------|---------|-----------|
| `LockNPCVehicle` | `false` | Trancar todos os veículos NPCs quando o jogador se aproxima |
| `playerDraggable` | `true` | Permitir que jogadores arrastem outros jogadores |
| `toggleLightsOnlyRemote` | `true` | Alternar luzes apenas quando fora do veículo |
| `keepVehicleEngineOn` | `true` | Manter motor ligado ao sair do veículo |
| `keepKeysInVehicle` | `true` | Chaves ficam no veículo; motor não liga sem elas |

### Carjacking (steal)
| Opção | Padrão | Descrição |
|-------|---------|-----------|
| `steal.available` | `true` | Habilitar carjacking |
| `steal.getKey` | `"permanent"` | Tipo de chave recebida: `"permanent"`, `"temporary"`, `"none"` |
| `steal.chance` | Por arma | Chance de sucesso por categoria de arma (hash) |

### Lockpick (lockpick)
| Opção | Padrão | Descrição |
|-------|---------|-----------|
| `lockpick.minigameScript` | `"ox_lib"` | `"ox_lib"` ou `"inside-lockpicking"` |
| `lockpick.breakChance` | `0.5` | Chance do lockpick quebrar (normal) |
| `lockpick.advancedBreakChance` | `0.1` | Chance do lockpick quebrar (avançado) |

### Hotwiring (hotwire)
| Opção | Padrão | Descrição |
|-------|---------|-----------|
| `hotwire.available` | `true` | Habilitar hotwiring |
| `hotwire.chance` | `0.1` | Chance base de sucesso (escalada por nível cw-rep) |

### Key Grabbing (grab)
| Opção | Padrão | Descrição |
|-------|---------|-----------|
| `grab.alive` | `true` | Permitir pegar chaves de NPCs vivos |
| `grab.leaveKeysOnVehicle` | `true` | Deixar chaves no veículo ao pegar |

### Classes e armas bloqueadas
- `blacklistedClasses`: 13-16, 21 (bicicletas, barcos, helicópteros, aviões, trens)
- `BlackListedWeapon`: 28 armas corpo a corpo/arremessáveis que não podem fazer carjacking

## Controles

| Tecla | Ação |
|-------|------|
| **L** | Trancar/destrancar veículo (`togglelocks`) |
| **Z** | Ligar/desligar motor (`mri:engine`) |
| **H** | Hotwiring (quando dentro de veículo sem chave) |

## Comandos

| Comando | Restrito | Descrição |
|---------|----------|-----------|
| `/givetempkeys [target] [plate]` | `group.admin` | Dar chaves temporárias |
| `/removetempkeys [target] [plate]` | `group.admin` | Remover chaves temporárias |
| `/givekeys` | police/cardealer/admin | Dar chave permanente do veículo atual |
| `/removekeys` | police/cardealer/admin | Remover chave permanente do veículo atual |
| `/stackkeys` | Não | Consolidar todas as chaves em um keybag |
| `/unstackkeys` | Não | Separar keybag em chaves individuais |

## Eventos

### Client → Server
| Evento | Descrição |
|--------|-----------|
| `mm_carkeys:server:setVehLockState` | Definir estado de trancamento do veículo |
| `mm_carkeys:server:acquiretempvehiclekeys` | Requisitar chaves temporárias |
| `mm_carkeys:server:removetempvehiclekeys` | Remover chaves temporárias |
| `mm_carkeys:server:acquirevehiclekeys` | Requisitar chave permanente |
| `mm_carkeys:server:removevehiclekeys` | Remover chave permanente |
| `mm_carkeys:server:stackkeys` | Stack de chaves em keybag |
| `mm_carkeys:server:unstackkeys` | Unstack keybag em chaves individuais |

### Server → Client
| Evento | Descrição |
|--------|-----------|
| `mm_carkeys:client:addtempkeys` | Adicionar chave temporária na lista do cliente |
| `mm_carkeys:client:removetempkeys` | Remover chave temporária da lista do cliente |
| `mm_carkeys:client:setplayerkey` | Definir chave permanente |
| `mm_carkeys:client:removeplayerkey` | Remover chave permanente |
| `mm_carkeys:client:givekeyitem` | Progress bar de dar chave |
| `mm_carkeys:client:stackkeys` | Progress bar de stack |
| `mm_carkeys:client:unstackkeys` | Progress bar de unstack |

## Exports

### Client
| Export | Parâmetros | Retorno | Descrição |
|--------|------------|---------|-----------|
| `GiveTempKeys` | `(plate)` | - | Dar chave temporária para uma placa |
| `RemoveTempKeys` | `(plate)` | - | Remover chave temporária para uma placa |
| `GiveKeyItem` | `(plate)` | - | Dar item de chave permanente |
| `RemoveKeyItem` | `(plate)` | - | Remover item de chave permanente |
| `HaveTemporaryKey` | `(plate)` | boolean | Verifica se tem chave temporária |
| `HavePermanentKey` | `(plate)` | boolean | Verifica se tem chave permanente |

### Server
| Export | Parâmetros | Retorno | Descrição |
|--------|------------|---------|-----------|
| `GiveTempKeys` | `(src, plate)` | - | Dar chave temporária ao jogador |
| `RemoveTempKeys` | `(src, plate)` | - | Remover chave temporária do jogador |
| `GiveKeyItem` | `(src, plate, netId)` | - | Dar item de chave permanente |
| `RemoveKeyItem` | `(src, plate)` | - | Remover item de chave permanente |
| `HaveTemporaryKey` | `(src, plate)` | boolean | Verifica via callback |
| `HavePermanentKey` | `(src, plate)` | boolean | Verifica via callback |

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

## Integração com outros recursos MRI

### Obrigatórias
- `ox_lib` — UI, menus, progress bars, notificações

### Opcionais (auto-detected)
- **Frameworks**: `qb-core`, `qbx_core`, `es_extended`, `ox_core`
- **Inventories**: `ox_inventory`, `qb-inventory`, `ps-inventory`, `mm_inventory`, `qs-inventory`
- `rep-enginewire` — Minigame alternativo de hotwiring
- `inside-lockpicking` — Minigame alternativo de lockpick
- `cw-rep` — Sistema de reputação/habilidade para hotwiring e lockpick
- `InteractSound` — Sons de lock/unlock

## Exemplos práticos

### Dar chave permanente via export server
```lua
exports['mri_Qcarkeys']:GiveKeyItem(source, 'ABC1234', vehicleNetId)
```

### Verificar se jogador tem chave temporária
```lua
local hasKey = exports['mri_Qcarkeys']:HaveTemporaryKey('ABC1234')
if hasKey then
    -- jogador tem chave temporária
end
```

### Dar chaves temporárias via comando admin
```lua
TriggerEvent('mm_carkeys:server:acquiretempvehiclekeys', source, 'ABC1234')
```

### Configurar chance de hotwiring com cw-rep
A chance de hotwiring é escalada pelo nível de reputação no `cw-rep` (níveis 1-8), começando em `Config.hotwire.chance` (10% padrão).

## Solução de problemas

- **Chaves não funcionam**: Verifique se o framework e inventory estão sendo detectados corretamente
- **Motor não liga**: Com `keepKeysInVehicle = true`, o veículo verifica o entity state `keysIn`
- **Hotwiring não dispara**: Verifique se `Config.hotwire.available = true` e jogador não tem chave
- **Lockpick quebra sempre**: Ajuste `Config.lockpick.breakChance` e `advancedBreakChance`
- **Carjacking cooldown**: Há cooldown de 5 segundos entre tentativas
- **Stacking converte tudo**: O stacking converte todos os itens `vehiclekey` em um único `keybag` com metadata de placas
- **NPCs fogem**: NPCs ocupantes fogem quando um carjacking é bem-sucedido
- **Desligar motor consome chave**: Com `keepKeysInVehicle = true`, desligar consome a chave permanente e concede temporária
