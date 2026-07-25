-- constants.lua
-- Centraliza todos los valores mágicos del juego en un solo archivo.
-- Evita números hardcodeados dispersos en el código fuente.
-- Todos los valores aquí son modificables sin tocar la lógica del juego.

local Constants = {}

-- ═══════════════════════════════════════════════════════
-- DISEÑO / PANTALLA
-- ═══════════════════════════════════════════════════════

--- Resolución virtual de diseño (viewport interno).
--- El juego renderiza a 700×400 y se escala a cualquier tamaño de ventana.
Constants.DESIGN_W = 700
Constants.DESIGN_H = 400

-- ═══════════════════════════════════════════════════════
-- JUGADOR
-- ═══════════════════════════════════════════════════════

--- Velocidad base de movimiento del jugador (píxeles/segundo).
Constants.PLAYER_SPEED = 400

--- Puntos de vida máximos iniciales.
Constants.PLAYER_MAX_HP = 100

--- Velocidad del dodge (dash) al presionar Shift.
Constants.PLAYER_DODGE_SPEED = 600

--- Duración del dodge en segundos.
Constants.PLAYER_DODGE_DURATION = 0.2

--- Cooldown entre dodges en segundos.
Constants.PLAYER_DODGE_COOLDOWN = 0.8

--- Intervalo mínimo entre disparos en segundos.
Constants.PLAYER_SHOOT_COOLDOWN = 0.15

--- Duración de la invencibilidad tras recibir daño.
Constants.PLAYER_INVINCIBLE_DURATION = 1.0

--- Duración del flash visual al recibir daño.
Constants.PLAYER_HIT_FLASH_DURATION = 0.1

--- Rango base del imán para recoger powerups.
Constants.PLAYER_MAGNET_RANGE = 50

-- ═══════════════════════════════════════════════════════
-- BALAS
-- ═══════════════════════════════════════════════════════

--- Velocidad base de las balas del jugador.
Constants.BULLET_SPEED = 600

--- Daño base de una bala del jugador.
Constants.BULLET_DAMAGE = 1

--- Radio de colisión de las balas del jugador.
Constants.BULLET_RADIUS = 4

--- Velocidad base de las balas enemigas.
Constants.ENEMY_BULLET_SPEED = 250

--- Daño base de las balas enemigas.
Constants.ENEMY_BULLET_DAMAGE = 10

-- ═══════════════════════════════════════════════════════
-- ENEMIGOS
-- ═══════════════════════════════════════════════════════

--- Puntos de vida base de los enemigos (se escala por ola).
Constants.ENEMY_HP_BASE = 20

--- Daño base al contacto con enemigos.
Constants.ENEMY_DAMAGE_BASE = 10

--- Multiplicador de HP por ola (1.06 = +6% por ola).
Constants.ENEMY_HP_SCALE = 1.06

--- Multiplicador de daño por ola (1.04 = +4% por ola).
Constants.ENEMY_DMG_SCALE = 1.04

--- Multiplicador de velocidad por ola (1.02 = +2% por ola).
Constants.ENEMY_SPD_SCALE = 1.02

--- Velocidad base de movimiento de enemigos.
Constants.ENEMY_SPEED_BASE = 100

-- ═══════════════════════════════════════════════════════
-- GENERACIÓN / OLAS
-- ═══════════════════════════════════════════════════════

--- Intervalo base entre spawns de enemigos (segundos).
Constants.SPAWN_INTERVAL_BASE = 1.2

--- Número base de enemigos por ola.
Constants.WAVE_ENEMIES_BASE = 10

--- Enemigos adicionales por ola.
Constants.WAVE_ENEMIES_SCALE = 2

-- ═══════════════════════════════════════════════════════
-- COMBATE / COMBO
-- ═══════════════════════════════════════════════════════

--- Color del texto de combo a nivel medio (amarillo).
Constants.COMBO_COLOR_LOW = {1.0, 0.8, 0.2}

--- Color del texto de combo a nivel alto (magenta).
Constants.COMBO_COLOR_HIGH = {1.0, 0.2, 0.8}

--- Número de kills para activar combo medio (texto amarillo).
Constants.COMBO_THRESHOLD_MED = 5

--- Número de kills para activar combo alto (texto magenta).
Constants.COMBO_THRESHOLD_HIGH = 10

-- ═══════════════════════════════════════════════════════
-- INTERFAZ / BOTONES
-- ═══════════════════════════════════════════════════════

--- Offset X del botón de disparo desde el borde derecho.
Constants.FIRE_BTN_X_OFFSET = 60

--- Radio del botón de disparo (touch).
Constants.FIRE_BTN_RADIUS = 40

--- Radio al cuadrado del botón de disparo (para dist²).
Constants.FIRE_BTN_RADIUS_SQ = 2500

-- ═══════════════════════════════════════════════════════
-- TIENDA
-- ═══════════════════════════════════════════════════════

--- Precio base de los componentes en la tienda.
Constants.SHOP_COMPONENT_BASE_PRICE = 10

--- Multiplicador de precio por rareza del componente.
Constants.SHOP_RARITY_PRICE_MULT = 15

--- Número base de drops de componentes por visita a la tienda.
Constants.SHOP_DROP_BASE = 2

--- Cada cuántas olas aparecen más drops en la tienda.
Constants.SHOP_DROP_WAVE_INTERVAL = 5

-- ═══════════════════════════════════════════════════════
-- HUD
-- ═══════════════════════════════════════════════════════

--- Espaciado del HUD desde los bordes.
Constants.HUD_PADDING = 10

--- Ancho de las barras de vida/escudo.
Constants.HUD_BAR_W = 120

--- Alto de las barras de vida/escudo.
Constants.HUD_BAR_H = 8

--- Tamaño de los íconos del HUD.
Constants.HUD_ICON_SIZE = 16

-- ═══════════════════════════════════════════════════════
-- MENÚS
-- ═══════════════════════════════════════════════════════

--- Velocidad de la animación de fade-out del menú principal.
Constants.MENU_FADE_SPEED = 2.5

-- ═══════════════════════════════════════════════════════
-- OLAS / JEFES
-- ═══════════════════════════════════════════════════════

--- Cada cuántas olas aparece un jefe.
Constants.BOSS_WAVE_INTERVAL = 10

--- Cada cuántas olas se accede a la tienda.
Constants.SHOP_WAVE_INTERVAL = 10

--- Cada cuántas olas se accede al hangar.
Constants.HANGAR_WAVE_INTERVAL = 5

-- ═══════════════════════════════════════════════════════
-- PERSISTENCIA / GUARDADO
-- ═══════════════════════════════════════════════════════

--- Nombre del archivo de monedas guardadas.
Constants.SAVE_CURRENCY = "currency.dat"

--- Nombre del archivo de high score.
Constants.SAVE_HIGHSCORE = "highscore.dat"

--- Nombre del archivo de configuración.
Constants.SAVE_SETTINGS = "settings.dat"

--- Nombre del archivo de mejoras permanentes.
Constants.SAVE_UPGRADES = "upgrades.dat"

--- Nombre del archivo de inventario (planificado).
Constants.SAVE_INVENTORY = "inventory.dat"

-- ═══════════════════════════════════════════════════════
-- ECONOMÍA
-- ═══════════════════════════════════════════════════════

--- Monedas base por kill de enemigo normal.
Constants.COIN_KILL_BASE = 10

--- Monedas por derrotar un jefe.
Constants.COIN_BOSS_KILL = 100

-- ═══════════════════════════════════════════════════════
-- MEJORAS PERMANENTES
-- ═══════════════════════════════════════════════════════

--- Nivel máximo de cada mejora.
Constants.UPGRADE_MAX_LEVEL = 20

--- Costo base de las mejoras.
Constants.UPGRADE_BASE_COST = 50

--- Multiplicador de costo por nivel de mejora.
Constants.UPGRADE_COST_SCALE = 1.5

-- ═══════════════════════════════════════════════════════
-- MODIFICADORES DE COMBATE
-- ═══════════════════════════════════════════════════════

--- Multiplicador de velocidad durante el dodge.
Constants.DODGE_SPEED_MULT = 1.5

--- Rango base del imán para recoger powerups.
Constants.MAGNET_RANGE_BASE = 50

--- Curación base por lifesteal (0 = sin lifesteal).
Constants.LIFESTEAL_BASE = 0

--- Multiplicador de daño crítico.
Constants.CRIT_MULTIPLIER = 2.0

return Constants
