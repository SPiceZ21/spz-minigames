# spz-minigames

> Minigame hub and the shared minigame HUD.

![version](https://img.shields.io/badge/version-1.0.1-ff6200) ![SPiceZ-Core](https://img.shields.io/badge/SPiceZ--Core-beta-18181b)

## Overview

One menu (`F7`, or the NPCs at the hub) to queue, create rooms, invite and start every minigame, plus the in-game HUD they all draw with.

## Features

- Hub for Color Rush, Cyclone, Bomb Tag, Demolition and Hot Pursuit
- Rooms, invites and quick join
- Shared minigame HUD

## Requirements

| Resource | Type |
|---|---|
| `ox_lib` | third-party |

## Installation

Included in the [txAdmin recipe](https://github.com/SPiceZ21/spz-txrecipe). Manual install:

1. Download `spz-minigames` from GitHub (latest release, or the repository) into your `resources` folder.
2. Add to `server.cfg`, after its requirements:

```cfg
ensure spz-minigames
```

## Configuration

- `config.lua`

See the file for every option.

## Commands

| Command | Who | Description |
|---|---|---|
| `/mgkey` | dev | Show the hub key binding |

## Key binds

Rebindable in **Settings → Key Bindings → FiveM**.

| Action | Default |
|---|---|
| Open the minigame hub | `F7` |

## Exports

| Export | Side |
|---|---|
| `Flash` | client |
| `HubKey` | client |
| `Hud` | client |
| `OpenHub` | client |
| `ReturnPoint` | client |
| `Shard` | client |

```lua
exports["spz-minigames"]:Flash(...)
```

---

Part of **SPiceZ-Core** — [documentation](https://github.com/SPiceZ21/Docs) · [all modules](https://github.com/SPiceZ21/Docs/blob/main/modules/README.md)
