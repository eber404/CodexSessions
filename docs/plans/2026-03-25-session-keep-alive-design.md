# Session Keep-Alive Configurável - Design

## Overview

Funcionalidade de keep-alive configurável pelo usuário que envia "oi" via Chat Completions API a cada 5 horas para manter sessões ativas. O usuário ativa/desativa, escolhe a primeira hora do dia, e visualiza os intervalos em uma timeline.

## Requisitos

1. **Toggle on/off** - keep-alive só funciona se usuário ativar
2. **Hora inicial configurável** - slider 0-23h para escolher primeira hora do dia
3. **Timeline visual** - mostrar intervalos de 5h ao longo do dia
4. **Funciona 24h contínuo** - ciclos de 5h ininterruptos

## Configurações (Settings)

```
┌─────────────────────────────────────┐
│ Session Keep-Alive                   │
│ ┌─────────────────────────────────┐ │
│ │ [Toggle: Ativar/Desativar]      │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Primeira hora do dia: 09:00         │
│ [0────────────●──────────23]        │
│                                     │
│ Timeline de hoje:                    │
│ │████│     │████│     │████│     │  │
│ 00   05   10   15   20   24        │
│       ▲                          ▲  │
│      [09:00]                   [04:00]│
│                                     │
│ Próximo envio: 09:00 (em 2h 30min) │
└─────────────────────────────────────┘
```

## Lógica de Intervalos

- Primeira hora define o primeiro envio do dia (ex: 09:00)
- Ciclos: 09:00, 14:00, 19:00, 00:00, 05:00, 10:00...
- Funciona 24h contínuo, reinicia no próximo dia na hora configurada

Exemplo com primeira hora 09:00:
| Intervalo | Horário |
|-----------|---------|
| 1 | 09:00 |
| 2 | 14:00 |
| 3 | 19:00 |
| 4 | 00:00 (dia seguinte) |
| 5 | 05:00 |
| 6 | 10:00 |

## Arquitetura

```
SettingsView
├── KeepAliveToggle (Toggle)
├── FirstHourSlider (Slider 0-23)
└── SessionTimelineView
    ├── Timeline blocks (blocos de 5h)
    └── NextPingIndicator

AppModel
├── keepAliveEnabled: Bool
├── firstHour: Int (0-23)
├── sessionScheduler: SessionScheduler
└── sessionKeepAlive: SessionKeepAlive?

SessionScheduler (nova)
├── calculateIntervals(firstHour: Int, count: Int) -> [Date]
├── calculateNextPing(firstHour: Int) -> Date
└── calculateTimelineBlocks(firstHour: Int) -> [TimeBlock]
```

## Componentes

### 1. SessionScheduler

**File:** `Sources/CodexUsageCore/Refresh/SessionScheduler.swift` (novo)

```swift
public struct TimeBlock: Identifiable {
    public let id = UUID()
    public let startHour: Int
    public let endHour: Int
    public let label: String
    public let isNext: Bool
}

public final class SessionScheduler {
    public func calculateIntervals(firstHour: Int, count: Int) -> [Date]
    public func calculateNextPing(firstHour: Int) -> Date
    public func calculateTimelineBlocks(firstHour: Int) -> [TimeBlock]
}
```

### 2. SessionTimelineView

**File:** `Sources/CodexUsageBar/UI/SessionTimelineView.swift` (novo)

- SwiftUI View
- Timeline 24h horizontal
- Blocos de 5h em azul
- Ponto verde no próximo intervalo
- Labels de hora embaixo

### 3. SettingsView Updates

- Adicionar `keepAliveEnabled` toggle
- Adicionar `firstHour` slider (0-23)
- Mostrar `SessionTimelineView` quando enabled
- Mostrar "Próximo envio" com countdown

### 4. SessionKeepAlive (existente, modificado)

- Adicionar `isEnabled` property
- Não dispara se `isEnabled == false`
- `start(accessToken:, firstHour:)` para sincronizar com scheduler

### 5. AppModel Updates

```swift
// Novas propriedades
@Published var keepAliveEnabled: Bool = false
@Published var firstHour: Int = 9
private var keepAliveTask: Task<Void, Never>?

// Métodos
func setKeepAliveEnabled(_ enabled: Bool)
func setFirstHour(_ hour: Int)
```

## Persistência

UserDefaults:
- `settings.keepAliveEnabled`: Bool (default: false)
- `settings.firstHour`: Int (default: 9)

## Fluxo do Usuário

1. Usuário abre Settings → toggle OFF por padrão
2. Ativa toggle → slider aparece, timeline mostra intervalos
3. Ajusta slider para 09:00 → timeline atualiza (09:00, 14:00, 19:00, 00:00, 05:00...)
4.keep-alive começa a disparar pings na hora certa
5. Desativa toggle → pings param imediatamente

## Error Handling

- Falha de rede: log apenas, não afeta UI
- Token inválido: SessionKeepAlive para, AppModel mostra erro sutil
- App em background: continua funcionando (background task)

## Testes

- `SessionSchedulerTests`: verifica cálculo de intervalos
- `SessionTimelineViewTests`: verifica renderização correta
- `SessionKeepAliveTests`: verifica comportamento com isEnabled

## Arquivos a Criar/Modificar

| Arquivo | Ação |
|---------|------|
| `Sources/CodexUsageCore/Refresh/SessionScheduler.swift` | Criar |
| `Sources/CodexUsageBar/UI/SessionTimelineView.swift` | Criar |
| `Sources/CodexUsageBar/UI/SettingsView.swift` | Modificar |
| `Sources/CodexUsageBar/App/AppModel.swift` | Modificar |
| `Tests/CodexUsageCoreTests/SessionSchedulerTests.swift` | Criar |
| `Tests/CodexUsageCoreTests/SessionTimelineViewTests.swift` | Criar |
