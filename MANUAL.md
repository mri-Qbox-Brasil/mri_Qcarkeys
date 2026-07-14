# mri_Qcarkeys — Manual

Sistema de chaves veiculares com chaves permanentes (item de inventário) e temporárias (memória do servidor), trancamento remoto, ligação direta, lockpick e roubo de veículos.

---

## Sumário

1. [Dependências](#dependências)
2. [Instalação](#instalação)
3. [Itens de inventário](#itens-de-inventário)
4. [Permissões (ACE)](#permissões-ace)
5. [Configuração](#configuração)
6. [Comandos](#comandos)
7. [Teclas](#teclas)
8. [Chaves permanentes vs. temporárias](#chaves-permanentes-vs-temporárias)
9. [Integrações](#integrações)
10. [Entrypoints para outros recursos](#entrypoints-para-outros-recursos)
11. [Estrutura de arquivos](#estrutura-de-arquivos)

---

## Dependências

| Recurso | Obrigatório | Observação |
|---|---|---|
| `ox_lib` | Sim | Comandos, callbacks, progressBar, textUI, skillCheck, notificações |
| Framework | Sim | Um entre `qbx_core` (via compat `qb-core`), `qb-core`, `es_extended` ou `ox_core`. Detectado automaticamente em `shared/init.lua` |
| Inventário | Sim | Um entre `ox_inventory`, `qb-inventory`, `ps-inventory`, `mm_inventory` ou `qs-inventory`. Detectado automaticamente em `shared/init.lua` |
| `cw-rep` | Sim (se usar hotwire/lockpick) | `getCurrentLevel` e `updateSkill` são chamados sem guarda em `hotwire.lua` e `lockpick.lua` |
| `InteractSound` | Não | Som de trancar/destrancar (`InteractSound_SV:PlayWithinDistance`) |
| `hud` (QBCore/Qbox) | Não | Ganho de estresse (`hud:server:GainStress`) em roubo, hotwire e lockpick |
| `rep-enginewire` | Não | Minigame extra de ligação direta. Só é usado se o recurso estiver iniciado |
| `inside-lockpicking` | Não | Minigame alternativo de lockpick (`lockpick.minigameScript`) |

Se nenhum framework ou nenhum inventário for detectado, `Shared.Ready` fica `false` e o recurso não registra nada no client.

---

## Instalação

1. Copie a pasta `mri_Qcarkeys` para `resources/`.
2. Adicione ao `server.cfg`:
   ```
   ensure mri_Qcarkeys
   ```
3. Cadastre os itens `vehiclekey`, `keybag`, `lockpick` e `advancedlockpick` no seu inventário (veja [Itens de inventário](#itens-de-inventário)).
4. **Remova ou desabilite o `qb-vehiclekeys`** — o `mri_Qcarkeys` já registra os eventos de compatibilidade `qb-vehiclekeys:server:AcquireVehicleKeys` e `qb-vehiclekeys:client:AddKeys`, e os dois recursos rodando juntos duplicam as chaves.
5. Se você **não** usa `ox_core`, mantenha as linhas `'@ox_core/imports/*.lua'` comentadas no `fxmanifest.lua` (é o padrão do repo) para evitar warning no startup.

---

## Itens de inventário

O recurso não cria itens; ele espera que estes nomes existam no seu inventário.

| Item | Uso | Metadata gravada pelo recurso |
|---|---|---|
| `vehiclekey` | Chave permanente de um veículo | `plate` (placa sem caracteres especiais, maiúscula) e `label` (`CHAVE-<placa>`) |
| `keybag` | Chaveiro que consolida várias chaves | `plates` (lista de `{plate, label}`) e `platestxt` (placas concatenadas) |
| `lockpick` | Consumido ao arrombar porta/ignição | — |
| `advancedlockpick` | Igual ao `lockpick`, com chance de quebra menor | — |

O item de lockpick precisa disparar o evento client `lockpicks:UseLockpick(isAdvanced)` quando usado — é assim que o minigame é iniciado.

---

## Permissões (ACE)

Os comandos `/givetempkeys` e `/removetempkeys` são registrados com `lib.addCommand(..., restricted = 'group.admin')`, o que cria as ACEs `command.givetempkeys` e `command.removetempkeys`.

```
add_ace group.admin command.givetempkeys allow
add_ace group.admin command.removetempkeys allow
```

Os comandos `/givekeys` e `/removekeys` não usam `restricted`: o gate é feito dentro do handler, que aceita o job `police`, o job `cardealer` **ou** a ACE `admin`.

```
add_ace group.admin admin allow
```

---

## Configuração

Arquivo: `shared/shared.lua`.

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `LockNPCVehicle` | bool | Sim | Tranca o veículo do NPC e faz o motorista fugir quando o jogador tenta entrar |
| `playerDraggable` | bool | Sim | Permite que jogadores sejam arrancados do banco por outros jogadores |
| `toggleLightsOnlyRemote` | bool | Sim | Pisca os faróis apenas quando o trancamento é feito fora do veículo |
| `keepVehicleEngineOn` | bool | Sim | Mantém o motor ligado ao sair do veículo |
| `keepKeysInVehicle` | bool | Sim | Ativa o modelo "chave no contato": ligar o motor converte a chave permanente em temporária e seta o entity state `keysIn` |
| `autoStartOnThrottle` | bool | Sim | Liga o motor ao pisar no acelerador/ré (controles 71 e 72) se o jogador tiver a chave, sem precisar do `Z` |
| `steal.available` | bool | Sim | Habilita o roubo de veículo (carjacking) mirando em NPC motorista |
| `steal.getKey` | string | Sim | Chave recebida ao concluir o roubo: `"permanent"`, `"temporary"` ou `"none"` |
| `steal.label` | string | Sim | Texto da progressBar do roubo |
| `steal.minTime` / `steal.maxTime` | ms | Sim | Faixa aleatória da duração do roubo |
| `steal.stressIncrease` | number | Sim | Estresse ganho ao roubar |
| `steal.chance` | tabela | Sim | Chance de sucesso por grupo de arma. Chave = hash do `GetWeapontypeGroup` em string; valor = 0.0 a 1.0. Grupo não listado usa 0.5 |
| `lockpick.minigameScript` | string | Sim | `"ox_lib"` (usa `lib.skillCheck('easy')`) ou `"inside-lockpicking"` |
| `lockpick.stressIncrease` | number | Sim | Estresse ganho por tentativa de lockpick |
| `lockpick.breakChance` | number | Sim | Chance (0.0–1.0) do `lockpick` quebrar por tentativa |
| `lockpick.advancedBreakChance` | number | Sim | Chance do `advancedlockpick` quebrar por tentativa |
| `blacklistedClasses` | tabela | Sim | Classes de veículo ignoradas pelo sistema (padrão: 13 bicicletas, 14 barcos, 15 helicópteros, 16 aviões, 21 trens) |
| `grab.alive` | bool | Sim | Permite arrancar a chave de um NPC vivo. Com `false`, só de motorista morto |
| `grab.leaveKeysOnVehicle` | bool | Sim | Concede chave temporária ao concluir o grab |
| `grab.label` | string | Sim | Texto da progressBar do grab |
| `grab.minTime` / `grab.maxTime` | ms | Sim | Faixa aleatória da duração do grab |
| `hotwire.available` | bool | Sim | Habilita a ligação direta (textUI + tecla `H`) quando o jogador está no banco do motorista sem chave |
| `hotwire.label` | string | Sim | Texto da progressBar da ligação direta |
| `hotwire.chance` | number | Sim | Chance base de sucesso. É multiplicada pelo nível `hotwiring` do `cw-rep` (limitado a 8) |
| `hotwire.minTime` / `hotwire.maxTime` | ms | Sim | Faixa aleatória da duração da ligação direta (também é o tempo de alarme do veículo) |
| `hotwire.stressIncrease` | number | Sim | Estresse ganho na ligação direta |
| `BlackListedWeapon` | lista | Sim | Armas que não permitem carjacking (corpo a corpo, arremessáveis, itens) |

---

## Comandos

| Comando | Permissão | Descrição |
|---|---|---|
| `/givetempkeys [target] [plate]` | ACE `command.givetempkeys` | Dá chave temporária. Sem `target`, usa quem executou; sem `plate`, usa a placa do veículo em que o alvo está |
| `/removetempkeys [target] [plate]` | ACE `command.removetempkeys` | Remove a chave temporária. Mesmos defaults do comando acima |
| `/givekeys` | Job `police`, job `cardealer` ou ACE `admin` | Abre uma progressBar de 5 s e entrega o item `vehiclekey` do veículo em que o jogador está |
| `/removekeys` | Job `police`, job `cardealer` ou ACE `admin` | Remove o item `vehiclekey` do veículo em que o jogador está |
| `/stackkeys` | Todos | Junta todos os `vehiclekey` do inventário em um `keybag` |
| `/unstackkeys` | Todos | Desfaz o `keybag`, devolvendo um `vehiclekey` por placa |

---

## Teclas

| Tecla | Comando | Ação |
|---|---|---|
| `L` | `togglelocks` | Tranca/destranca o veículo atual ou o mais próximo em 5 m, se o jogador tiver a chave. Toca a animação do chaveiro e o som do `InteractSound` |
| `Z` | `mri:engine` | Liga/desliga o motor no banco do motorista |
| `H` | — (`IsControlJustPressed` 74) | Inicia a ligação direta quando está no banco do motorista sem chave e `hotwire.available` é `true` |

`L` e `Z` são registrados via `RegisterKeyMapping` e podem ser reconfigurados pelo jogador nas Configurações do FiveM.

---

## Chaves permanentes vs. temporárias

- **Permanente** — é o item `vehiclekey` (ou uma placa dentro do `keybag`). Persiste no inventário, sobrevive a logout e é verificada lendo o inventário do jogador.
- **Temporária** — vive na tabela `VehicleList[citizenid]` em memória no servidor (`server/server.lua`). É perdida no restart do recurso. É o que o hotwire, o lockpick de ignição e o grab concedem.

Com `keepKeysInVehicle = true`:
- Ligar o motor seta o entity state `keysIn` no veículo, remove o item `vehiclekey` e concede chave temporária — a chave "fica no contato".
- Desligar o motor limpa `keysIn` e devolve o item `vehiclekey`.
- Uma thread verifica `keysIn` a cada 1 s: sem esse state, o motor é desligado à força.

---

## Integrações

### cw-rep

O nível de habilidade escala as ações de crime. Na ligação direta, a chance de sucesso é `hotwire.chance * nível` (nível `hotwiring`, teto 8); em caso de sucesso, `updateSkill("hotwiring", 1)` é chamado. No lockpick de porta bem-sucedido, `updateSkill("lockpicking", 1)`.

### rep-enginewire

Se o recurso estiver iniciado, `exports["rep-enginewire"]:MiniGame()` roda junto com a progressBar da ligação direta e o resultado dele passa a valer como condição adicional de sucesso.

### inside-lockpicking

Com `lockpick.minigameScript = "inside-lockpicking"`, o minigame do `ox_lib` é substituído por `exports['inside-lockpicking']:StartLockPicking({ difficulty = 'easy', requiredAmount = 2 })`.

### InteractSound

O som de trancar é enviado com `TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 5, "lock", 0.3)`. Sem o recurso, o restante continua funcionando sem som.

---

## Entrypoints para outros recursos

### Exports de servidor

```lua
exports['mri_Qcarkeys']:GiveTempKeys(src, plate)          -- concede chave temporária
exports['mri_Qcarkeys']:RemoveTempKeys(src, plate)        -- remove chave temporária
exports['mri_Qcarkeys']:GiveKeyItem(src, plate, netId)    -- entrega o item vehiclekey
exports['mri_Qcarkeys']:RemoveKeyItem(src, plate)         -- remove o item vehiclekey
exports['mri_Qcarkeys']:HaveTemporaryKey(src, plate)      --> boolean (callback ao client)
exports['mri_Qcarkeys']:HavePermanentKey(src, plate)      --> boolean (callback ao client)
```

### Exports de client

```lua
exports.mri_Qcarkeys:GiveTempKeys(plate)
exports.mri_Qcarkeys:RemoveTempKeys(plate)
exports.mri_Qcarkeys:GiveKeyItem(plate)
exports.mri_Qcarkeys:RemoveKeyItem(plate)
exports.mri_Qcarkeys:HaveTemporaryKey(plate)   --> boolean
exports.mri_Qcarkeys:HavePermanentKey(plate)   --> boolean
```

### Eventos de servidor

```lua
TriggerServerEvent('mm_carkeys:server:acquirevehiclekeys', plate)     -- entrega item vehiclekey
TriggerServerEvent('mm_carkeys:server:removevehiclekeys', plate)      -- remove item vehiclekey
TriggerServerEvent('mm_carkeys:server:acquiretempvehiclekeys', plate)
TriggerServerEvent('mm_carkeys:server:removetempvehiclekeys', plate)
TriggerServerEvent('mm_carkeys:server:setVehLockState', vehNetId, state) -- state: 1 destrancado, 2 trancado
TriggerServerEvent('mm_carkeys:server:stackkeys')
TriggerServerEvent('mm_carkeys:server:unstackkeys')
TriggerServerEvent('mm_carkeys:server:removelockpick', 'lockpick')
```

### Eventos de client

```lua
TriggerClientEvent('mm_carkeys:client:addtempkeys', src, plate)
TriggerClientEvent('mm_carkeys:client:removetempkeys', src, plate)
TriggerClientEvent('mm_carkeys:client:setplayerkey', src, plate, netId)
TriggerClientEvent('mm_carkeys:client:removeplayerkey', src, plate)
TriggerClientEvent('mm_carkeys:client:givekeyitem', src)   -- progressBar + entrega a chave do veículo atual
TriggerClientEvent('mm_carkeys:client:removekeyitem', src)
TriggerClientEvent('mm_carkeys:client:stackkeys', src)
TriggerClientEvent('mm_carkeys:client:unstackkeys', src)

TriggerEvent('lockpicks:UseLockpick', isAdvanced)  -- client; dispare no "use" do item de lockpick
```

### Compatibilidade com o `qb-vehiclekeys`

Os dois eventos abaixo são aceitos para não quebrar recursos antigos:

```lua
TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)  -- entrega item vehiclekey
TriggerEvent('qb-vehiclekeys:client:AddKeys', plate)                   -- concede chave temporária
```

### Callbacks

```lua
lib.callback.await('mm_carkeys:server:getvehiclekeys', false)     -- lista de placas com chave temporária
lib.callback.await('mm_carkeys:client:getplate', src)             -- placa do veículo em que o jogador está
lib.callback.await('mm_carkeys:client:havekey', src, type, plate) -- type: 'temp' ou 'perma'
```

---

## Estrutura de arquivos

```
mri_Qcarkeys/
├── shared/
│   ├── shared.lua        — toda a configuração (tabela Shared)
│   └── init.lua          — autodetecção de framework e inventário
├── bridge/
│   ├── framework/
│   │   ├── qb.lua        — bridge QBCore (client)
│   │   ├── qbox.lua      — bridge Qbox (client)
│   │   ├── esx.lua       — bridge ESX (client)
│   │   └── ox.lua        — bridge ox_core (client)
│   └── inventory/
│       └── client.lua    — leitura dos itens do jogador por inventário
├── client/
│   ├── init.lua          — loop principal, caches (vehicle/seat/weapon), exports de client
│   ├── interface.lua     — estado compartilhado do client (chaves, veículo atual, flags)
│   └── modules/
│       ├── keys.lua      — trancar/destrancar, motor, keysIn, comandos e keybinds
│       ├── hotwire.lua   — ligação direta com cw-rep e rep-enginewire
│       ├── lockpick.lua  — lockpick de porta e de ignição, quebra do item
│       ├── steal.lua     — carjacking e grab de chave de NPC
│       └── utils.lua     — helpers (normalização de placa, peds no veículo, arma bloqueada)
├── server/
│   ├── server.lua        — chaves temporárias em memória, itens, exports e eventos
│   ├── commands.lua      — comandos de chave
│   └── bridge.lua        — bridge de framework e inventário (server)
└── fxmanifest.lua
```
