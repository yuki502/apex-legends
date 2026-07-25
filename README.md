# APEX LEGENDS — Space Shooter

[![LÖVE](https://img.shields.io/badge/LÖVE-11.x-EA316E?logo=lua)](https://love2d.org/)
[![Lua](https://img.shields.io/badge/Lua-5.1-2C2D72?logo=lua)](https://www.lua.org/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

> **BETA** — This game is in active development. Features may change, and feedback is welcome!

A 2D space shooter built with [LÖVE](https://love2d.org/) (Lua 5.1). Fight waves of enemies, battle bosses, collect components, and build your ultimate ship in the hangar.

---

## Quick Start

```bash
# Run directly from source
cd apex-legends && love .

# Or run from the .love archive
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
- **Screen adaptation** — Virtual viewport with uniform scaling + letterbox bars. Design resolution 700×400 scales to any window size. Input coordinates are automatically transformed.
- **Logging** — Session-based logging with rotation, configurable levels (DEBUG/INFO/WARN/ERROR), automatic file storage in `logs/`.
- **Developer mode** — Overlay with FPS, frame time, memory, entity count. Hitbox rendering, game speed control (F5/F6). Activated via F8 or settings.

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

### Run directly from source

```bash
cd apex-legends
love .
```

---

## Controls

### Game Controls

| Action | Keyboard | Touch |
|---|---|---|
| Move | WASD / Arrow keys | Left joystick area |
| Shoot | Space / Z | Right fire button |
| Dodge | Left Shift | Double-tap joystick |
| Pause | Escape / P | — |
| Consumable | 1-4 keys | Item buttons |

### Developer Mode (F8 to toggle)

| Action | Key | Description |
|---|---|---|
| Toggle overlay | F3 | Show/hide stats overlay |
| Hitboxes | F4 | Toggle hitbox rendering |
| Pause (dev) | F5 | Pause game (dev mode only) |
| Game speed | F6 | Toggle 2× / 1× speed |
| Toggle dev mode | F8 | Enable/disable developer mode |

---

## Project Structure

```
apex-legends/
├── main.lua                  # Entry point — LOVE callbacks, lifecycle, logging
├── conf.lua                  # Window configuration (1400×800, resizable, landscape)
├── LICENSE
├── README.md
├── .gitignore
├── lib/                      # Third-party libraries
│   ├── classic.lua           # OOP (rxi/classic)
│   ├── flux.lua              # Tweens (rxi/flux)
│   └── lume.lua              # Utilities (rxi/lume)
├── assets/
│   └── audio/                # Game audio files (.ogg, .mp3)
├── src/                      # Source code (43 modules)
│   ├── game.lua              # Main state machine and orchestrator
│   ├── managers/             # Game management systems
│   │   ├── boss_manager.lua      # Boss spawn templates
│   │   ├── consumable_manager.lua# Consumable items store
│   │   ├── currency_manager.lua  # Persistent currency
│   │   ├── settings_manager.lua  # Settings persistence
│   │   ├── shop_manager.lua      # In-game shop with 3 tabs
│   │   ├── spawn_manager.lua     # Enemy/boss spawning + shooting
│   │   ├── super_boss_manager.lua# Multi-phase super bosses
│   │   ├── upgrade_manager.lua   # Permanent upgrades store
│   │   └── wave_manager.lua      # Wave progression logic
│   ├── systems/              # Core game logic systems
│   │   ├── collision.lua         # Hit detection, damage, powerup collection
│   │   ├── entity_list.lua       # Generic list with swap-remove pattern
│   │   ├── entity_pool.lua       # Object pool for entity reuse
│   │   ├── input.lua             # Keyboard + touch input handling
│   │   ├── lifecycle.lua         # App focus, visibility, quit handling
│   │   ├── shake.lua             # Screen shake effect
│   │   ├── state.lua             # Game state transitions
│   │   └── synergy_system.lua    # 14+ component synergies
│   ├── entities/             # Game entities
│   │   ├── boss.lua              # Boss entity
│   │   ├── bullet.lua            # Player and enemy projectiles
│   │   ├── enemy.lua             # Enemy entity — behaviors, shooting
│   │   ├── player.lua            # Player ship — stats, rendering, dodge
│   │   └── powerup.lua           # In-game powerups
│   ├── ui/                   # User interface screens
│   │   ├── customize.lua         # Ship selection screen
│   │   ├── hangar.lua            # Component installation UI
│   │   ├── hud.lua               # Heads-up display
│   │   ├── loading.lua           # Loading screen
│   │   ├── menus.lua             # Main menu
│   │   └── touch_controls.lua    # Virtual joystick/buttons
│   ├── graphics/             # Rendering and visual effects
│   │   ├── background.lua        # 4-layer parallax starfield
│   │   ├── effects.lua           # Particle systems, floating text
│   │   ├── post_shader.lua       # Post-processing shader manager
│   │   ├── screen.lua            # Virtual viewport + uniform scaling + letterbox
│   │   └── shaders.lua           # GLSL shader programs
│   ├── data/                 # Data and configuration definitions
│   │   ├── component_defs.lua    # 42 component definitions in 8 categories
│   │   ├── constants.lua         # Centralized game constants (50+ values)
│   │   ├── enemy_types.lua       # 10 enemy type definitions
│   │   └── ship_designs.lua      # Ship visual designs
│   └── utils/                # Utility modules
│       ├── audio.lua             # Sound effects and music
│       ├── dev_mode.lua          # Developer overlay and debugging tools
│       ├── inventory.lua         # Component inventory + slot system
│       ├── logger.lua            # Session logging with rotation
│       └── solar_system.lua      # Procedural solar systems
├── tests/                    # Test infrastructure
│   ├── test_runner.lua           # Minimal test framework
│   ├── unit/
│   │   ├── test_constants.lua    # Constants module tests
│   │   ├── test_synergies.lua    # Synergy system tests
│   │   └── test_benchmarks.lua   # Performance benchmarks
│   └── sandbox/
│       ├── sandbox.lua           # Interactive testing environment
│       └── test_components.lua   # Component system tests
```

---

## Architecture Overview

### Game Loop

```
love.load()
  ├─ Screen.init()              # Virtual viewport setup
  ├─ SettingsManager.init()     # Load settings (idempotent)
  ├─ DevMode.init()             # Developer tools
  ├─ Logger.new()               # Logging system
  └─ Game:new()                 # Initializes all managers, loads saves

love.update(dt)
  ├─ DevMode.update(dt)         # FPS, memory stats, key bindings
  ├─ DevMode.pause check        # Skip game update if dev-paused
  ├─ Game speed multiplier      # dt adjusted by DevMode.getGameSpeed()
  └─ Game:update(dt)
       ├─ State: menu → customize → playing → shop → hangar → playing
       ├─ WaveManager: progression, countdown, boss triggers
       ├─ Player: movement, shooting, dodge, powerups
       ├─ SpawnManager: enemy spawning, enemy shooting, boss updates
       └─ Collision: bullet-enemy, bullet-boss, enemy-player, powerups

love.draw()
  ├─ Screen.drawLetterbox()     # Letterbox bars
  ├─ Screen.apply()             # Push + scale to virtual viewport
  ├─ Game:draw()
  │    ├─ Background (4-layer parallax)
  │    ├─ Shader (post-processing lights, uses virtual dims)
  │    ├─ Entities (bullets, enemies, boss, player) + hitboxes if dev mode
  │    ├─ Shader removed
  │    ├─ UI (HUD, controls, game over, pause)
  │    └─ State-specific overlays (menu, shop, hangar)
  ├─ DevMode.draw()             # Stats overlay
  └─ Screen.clear()             # Pop transform

love.focus(f)     → Lifecycle.onFocus(f)    # Auto-pause on focus loss
love.visible(v)   → Lifecycle.onVisible(v)  # Auto-pause on hidden
love.quit()       → Lifecycle.quit()         # Save data on exit
love.resize(w,h)  → Screen.update()          # Recalculate viewport
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

### Screen Adaptation

The game uses a **virtual viewport** system (`src/graphics/screen.lua`) to render at a fixed design resolution (700×400) that scales uniformly to any window size:

- **Uniform scaling** — Aspect ratio is preserved; extra space is filled with letterbox bars
- **Input transformation** — All touch/mouse coordinates are converted from screen space to virtual space before reaching game logic
- **Font scaling** — `Screen.fontSize()` returns proportionally scaled font sizes for crisp text at any resolution
- **Resize handling** — `love.resize()` triggers `Screen.update()`, which recalculates scale and offsets on the fly
- **Shader alignment** — Post-processing coordinates use virtual dimensions so effects stay aligned with game entities

---

### Constants Module

All magic numbers are centralized in `src/data/constants.lua` (50+ values):

- Display: `DESIGN_W`, `DESIGN_H`
- Player: `PLAYER_SPEED`, `PLAYER_MAX_HP`, `PLAYER_DODGE_DURATION`
- Combat: `COMBO_THRESHOLD_MED`, `BOSS_WAVE_INTERVAL`, `ENEMY_HP_SCALE`
- Economy: `COIN_KILL_BASE`, `UPGRADE_BASE_COST`, `SHOP_RARITY_PRICE_MULT`
- Persistence: `SAVE_CURRENCY`, `SAVE_HIGHSCORE`, `SAVE_SETTINGS`

---

### Logging System

`src/utils/logger.lua` provides session-based logging:

- **4 levels**: DEBUG (1), INFO (2), WARN (3), ERROR (4)
- **Buffered writes**: 4KB buffer, auto-flush to prevent I/O per-frame
- **Log rotation**: Max 5 files, 256KB each, auto-deletes oldest
- **Session tracking**: Each session gets a timestamped file in `logs/`
- **API**: `Logger:info("message")`, `Logger:debug(...)`, `Logger:error(...)`
- **Configuration**: `Logger.configure({minLevel=2, toFile=true})`

---

### App Lifecycle

`src/systems/lifecycle.lua` handles focus and visibility events:

- **Focus loss** → Auto-pauses game (preserves pause state)
- **Focus restore** → Restores game state
- **Visibility hidden** → Pauses if playing
- **Quit** → Saves all data (currency, settings)
- **Low memory** → Triggers garbage collection

---

### Developer Mode

`src/utils/dev_mode.lua` provides debugging tools without affecting production performance:

**Overlay (F3):**
- FPS counter
- Frame time (ms)
- Memory usage (KB)
- Entity/bullet/enemy/powerup counts

**Tools:**
- **Hitbox rendering (F4)** — Draw collision circles on all entities
- **Pause (F5)** — Freeze game update, continue rendering
- **Game speed (F6)** — Toggle 2× / 1× speed
- **Frame step** — Advance one frame at a time when paused

**Activation:**
- Toggle via F8
- Or enable in `settings.dat` with `devMode=true`

When disabled, `DevMode.update()` returns immediately — zero overhead.

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
| `settings.dat` | Volume, handedness, devMode, logToFile |
| `upgrades.dat` | Permanent upgrade levels |
| `inventory.dat` | (planned) Saved component inventory |

---

## Testing

Tests are located in `tests/` with a minimal test runner:

```bash
# Run tests from command line (requires love in PATH)
love . --test

# Or load specific test file in sandbox mode
love . --sandbox
```

### Test Structure

| Directory | Purpose |
|---|---|
| `tests/unit/` | Unit tests for individual modules |
| `tests/sandbox/` | Interactive testing without full game |
| `tests/test_runner.lua` | Minimal `describe/it/assert` framework |

### Test Files

| File | Tests |
|---|---|
| `test_constants.lua` | Constants module values and types |
| `test_synergies.lua` | Synergy detection (Arsenal, Fortress, Speed Demon) |
| `test_benchmarks.lua` | Table creation vs reuse, string concat methods |
| `test_components.lua` | Component slot queries, random selection |
| `sandbox.lua` | Interactive UI for selecting and running sandbox tests |

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
| Screen adaptation (resizable, uniform scaling) | ✅ |
| Logging system with rotation | ✅ |
| Developer mode (overlay, hitboxes, speed) | ✅ |
| App lifecycle handling (focus, visibility, quit) | ✅ |
| Centralized constants module | ✅ |
| Test infrastructure | ✅ |

---

## Credits

- **Audio**: "The Long Road Home" and "Waiting for the New Day" by [Rolemusic](https://freemusicarchive.org/music/rolemusic) (CC BY 4.0)
- **Libraries**: [classic](https://github.com/rxi/classic), [lume](https://github.com/rxi/lume), [flux](https://github.com/rxi/flux) by rxi
- **Built with**: [LÖVE](https://love2d.org/) game framework

---

## Support

If you enjoy the game, there are two ways to support the project:

- **Contribute code** — Open issues, suggest features, or submit pull requests. All contributions are welcome!
- **Buy on itch.io** — A polished release will be available on [itch.io](https://itch.io) once ready. Stay tuned.

---

## License

MIT License — see [LICENSE](LICENSE) file.
