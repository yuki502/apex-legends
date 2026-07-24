# APEX LEGENDS — Space Shooter

[![LÖVE](https://img.shields.io/badge/LÖVE-11.x-EA316E?logo=lua)](https://love2d.org/)
[![Lua](https://img.shields.io/badge/Lua-5.1-2C2D72?logo=lua)](https://www.lua.org/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Game](https://img.shields.io/badge/download-.love-blue)](apex-legends.love)

A 2D space shooter built with [LÖVE](https://love2d.org/) (Lua 5.1). Fight waves of enemies, battle bosses, collect components, and build your ultimate ship in the hangar.

---

## Quick Start

```bash
# Run directly from source
cd apex-legends && love .

# Or run from the .love archive
love apex-legends.love
```

**Prerequisites:** [LÖVE 11.x](https://love2d.org/) installed on your system.

---

## Features

- **Wave-based combat** — Enemies get tougher every wave. Boss fights every 10 waves.
- **Ship building** — Collect and install components (weapons, thrusters, cores, shields, armor, wings, engines, modules) into physical ship slots.
- **Component synergies** — 14+ synergy combinations that activate based on your build (e.g., "Plasma Overload", "Ricochet Carnage", "Vampire").
- **Dynamic stats** — Damage, fire rate, speed, crit chance, lifesteal, ricochet, and more are calculated from installed components.
- **Shop** — Buy upgrades, consumables, and components between waves.
- **Hangar** — Drag-and-drop interface to arrange components on your ship.
- **Enemy variety** — 10 enemy types with distinct behaviors (sniper, kamikaze, bomber, dasher, shielder, etc.).
- **Boss fights** — 4 boss templates + 2 super boss types with multi-phase battles.
- **Persistent upgrades** — Currency and upgrades persist between runs through save files.
- **Touch controls** — Virtual joystick, fire button, and item buttons with left/right handed mode.
- **Visual effects** — Procedural parallax starfield background, procedural solar systems, post-processing shader, particle explosions, screen shake.

---

## Technologies

| Technology | Purpose |
|---|---|
| [LÖVE 11.x](https://love2d.org/) | Game framework |
| [Lua 5.1](https://www.lua.org/) | Programming language |
| [classic](https://github.com/rxi/classic) | OOP library |
| [lume](https://github.com/rxi/lume) | Utility library |
| [flux](https://github.com/rxi/flux) | Tweening library |
| GLSL (ARBfp1) | Post-processing shader |

---

## How to Run

### Prerequisites

- [LÖVE 11.x](https://love2d.org/) installed on your system

### Option A: Run directly from source

```bash
cd apex-legends
love .
```

### Option B: Run from .love archive

```bash
# The .love file is included in this repository
love apex-legends.love
```

### Option C: Build .love archive yourself

```bash
# Requires Node.js (only for zip packaging)
node rebuild-love.js
# Output: apex-legends.love
```

---

## Controls

| Action | Keyboard | Touch |
|---|---|---|
| Move | WASD / Arrow keys | Left joystick area |
| Shoot | Space / Z | Right fire button |
| Dodge | Left Shift | Double-tap joystick |
| Pause | Escape / P | — |
| Consumable | 1-4 keys | Item buttons |

---

## Project Structure

```
apex-legends/
├── main.lua                  # Entry point — LOVE callbacks
├── conf.lua                  # Window configuration (700×400, landscape)
├── apex-legends.love         # Pre-built game archive
├── LICENSE
├── README.md
├── .gitignore
├── lib/                      # Third-party libraries
│   ├── classic.lua           # OOP (rxi/classic)
│   ├── flux.lua              # Tweens (rxi/flux)
│   └── lume.lua              # Utilities (rxi/lume)
├── assets/
│   └── audio/                # Game audio files (.ogg, .mp3)
├── src/                      # Source code (35 modules)
│   ├── game.lua              # Main state machine and orchestrator
│   ├── state.lua             # Game state transitions
│   ├── input.lua             # Keyboard + touch input handling
│   ├── collision.lua         # Hit detection, damage, powerup collection
│   ├── audio.lua             # Sound effects and music
│   ├── effects.lua           # Particle systems, floating text
│   ├── shake.lua             # Screen shake effect
│   ├── player.lua            # Player ship — stats, rendering, dodge
│   ├── enemy.lua             # Enemy entity — behaviors, shooting
│   ├── enemy_types.lua       # 10 enemy type definitions
│   ├── boss.lua              # Boss entity
│   ├── boss_manager.lua      # Boss spawn templates
│   ├── super_boss_manager.lua# Multi-phase super bosses
│   ├── bullet.lua            # Player and enemy projectiles
│   ├── powerup.lua           # In-game powerups
│   ├── wave_manager.lua      # Wave progression logic
│   ├── spawn_manager.lua     # Enemy/boss spawning + shooting
│   ├── ship_designs.lua      # Ship visual designs
│   ├── component_defs.lua    # 42 component definitions in 8 categories
│   ├── inventory.lua         # Component inventory + slot system
│   ├── synergy_system.lua    # 14+ component synergies
│   ├── currency_manager.lua  # Persistent currency
│   ├── upgrade_manager.lua   # Permanent upgrades store
│   ├── consumable_manager.lua# Consumable items store
│   ├── settings_manager.lua  # Settings persistence
│   ├── hud.lua               # Heads-up display
│   ├── menus.lua             # Main menu
│   ├── customize.lua         # Ship selection screen
│   ├── shop_manager.lua      # In-game shop with 3 tabs
│   ├── hangar.lua            # Component installation UI
│   ├── touch_controls.lua    # Virtual joystick/buttons
│   ├── background.lua        # 4-layer parallax starfield
│   ├── solar_system.lua      # Procedural solar systems
│   ├── post_shader.lua       # Post-processing shader manager
│   ├── shaders.lua           # GLSL shader programs
│   └── loading.lua           # Loading screen
```

---

## Architecture Overview

### Game Loop

```
love.load()
  └─ Game:new() → initializes all managers, loads saves

love.update(dt)
  └─ Game:update(dt)
       ├─ State: menu → customize → playing → shop → hangar → playing
       ├─ WaveManager: progression, countdown, boss triggers
       ├─ Player: movement, shooting, dodge, powerups
       ├─ SpawnManager: enemy spawning, enemy shooting, boss updates
       └─ Collision: bullet-enemy, bullet-boss, enemy-player, powerups

love.draw()
  └─ Game:draw()
       ├─ Background (4-layer parallax)
       ├─ Shader (post-processing lights)
       ├─ Entities (bullets, enemies, boss, player)
       ├─ Shader removed
       ├─ UI (HUD, controls, game over, pause)
       └─ State-specific overlays (menu, shop, hangar)
```

### State Flow

```
MENU → CUSTOMIZE → PLAYING ←→ SHOP (wave 10, 20...)
                        ↓          ↓
                     GAME OVER   HANGAR (wave 5, 15...)
                        ↓
                      MENU
```

### Component System

The ship has **11 physical slots**: weapon, thruster, core, engine, wing (×2), shield, armor, module (×3). Each slot accepts components of the matching category. Installed components:

1. Change the ship's **visual appearance** (rendered on the player model)
2. Modify **dynamic stats** (damage, fire rate, speed, HP, etc.)
3. Activate **synergies** when specific combinations are detected
4. Enable **special abilities** (homing, ricochet, beam, phase dodge, shield reflect)

---

## Key Systems

### Combat

- **Enemies**: 10 types with 9 behaviors (straight, dodge, strafe, zonal, sniper, kamikaze, tank, bomber, dash, shield)
- **Bosses**: 4 templates scaled by wave; super bosses at wave 1000 with 3 phases
- **Scaling**: HP ×1.06, damage ×1.04, speed ×1.02 per wave

### Economy

- **Coins**: Earned from kills, persist between runs via `currency.dat`
- **Shop**: Upgrade permanent stats or buy consumables. Component drops scale with wave rarity.
- **Permanent upgrades**: 8 types (maxHP, shield, damage, fireRate, moveSpeed, magnetRange, critChance, lives)

### Persistence

| File | Contents |
|---|---|
| `currency.dat` | Saved coins |
| `highscore.dat` | High score |
| `settings.dat` | Volume, handedness |
| `upgrades.dat` | Permanent upgrade levels |
| `inventory.dat` | (planned) Saved component inventory |

---

## Development Status

Active development. All core features are implemented:

| Feature | Status |
|---|---|
| Infinite wave progression | ✅ |
| 10 enemy types | ✅ |
| Boss fights every 10 waves | ✅ |
| Ship building with 42 components | ✅ |
| 14+ synergies | ✅ |
| Shop with 3 tabs | ✅ |
| Touch controls | ✅ |
| Visual effects and shaders | ✅ |
| Persistent upgrades | ✅ |

---

## Credits

- **Audio**: "The Long Road Home" and "Waiting for the New Day" by [Rolemusic](https://freemusicarchive.org/music/rolemusic) (CC BY 4.0)
- **Libraries**: [classic](https://github.com/rxi/classic), [lume](https://github.com/rxi/lume), [flux](https://github.com/rxi/flux) by rxi
- **Built with**: [LÖVE](https://love2d.org/) game framework

---

## License

MIT License — see [LICENSE](LICENSE) file.
