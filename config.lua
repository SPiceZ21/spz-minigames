Config = {}

Config.Command = "minigames"     -- opens the hub
Config.Key     = "F7"            -- default key (players can rebind in GTA settings). Registry: Docs/keybinds.md
-- The key mapping lives on its own command so a default change reaches EVERY
-- player: FiveM keeps each player's old binding per command name forever.
Config.KeyCommand = "minigames_hub"
Config.PollMs  = 1500            -- refresh rate of lobby state while the hub is open

-- Where every minigame drops players when the match ends (x, y, z, heading).
-- Placeholder: Legion Square — swap in the DK garage coords.
Config.ReturnSpawn = vec4(195.17, -933.77, 29.7, 144.5)

-- kind = "lobby":   the shared SPiceZ rooms API
--                   (<ev>lobbyState / joinToggle / createRoom / joinRoom / leaveRoom /
--                    startRoom / kick / online callbacks, <ev>invite event)
-- kind = "pursuit": spz-pursuit rooms API
Config.Games = {
  {
    id = "colorrush", resource = "spz-colorrush", kind = "lobby", ev = "spz-colorrush:",
    title = "Color Rush", icon = "palette", accent = "#a855f7",
    blurb = "A colour is called — rush to it before the rest of the grid drops away. Last one standing wins.",
    start = "crstart", menu = "colorrushmenu",
  },
  {
    id = "cyclone", resource = "spz-cyclone", kind = "lobby", ev = "spz-cyclone:",
    title = "Cyclone", icon = "tornado", accent = "#38bdf8",
    blurb = "A cyclone roams the deck — get caught and it lifts you up and throws you off. Last car standing wins.",
    start = "cystart", menu = "cyclonemenu",
  },
  {
    id = "pursuit", resource = "spz-pursuit", kind = "pursuit",
    title = "Hot Pursuit", icon = "car-on", accent = "#3b82f6",
    blurb = "One robber breaks out of Pacific Standard, the cops (and a PD chopper) hunt them down.",
    menu = "pursuitmenu",
  },
  {
    id = "rocketleague", resource = "spz-rocketleague", kind = "lobby", ev = "spz-rl:",
    title = "Rocket League", icon = "futbol", accent = "#ff6200",
    blurb = "Car soccer in a floating arena — boost, jump, dodge and ride the walls.",
    start = "rlstart", menu = "rocketleaguemenu", teams = true, practice = true,
  },
  {
    id = "bomb", resource = "spz-bomb", kind = "lobby", ev = "spz-bomb:",
    title = "Bomb Tag", icon = "bomb", accent = "#ef4444",
    blurb = "Ram another car to pass the bomb. Don't be holding it when the fuse runs out.",
    start = "btstart", menu = "bombtagmenu",
  },
  {
    id = "demolition", resource = "spz-demolition", kind = "lobby", ev = "spz-demolition:",
    title = "Demolition", icon = "car-burst", accent = "#f5b942",
    blurb = "Destruction derby in the bowl — real damage, last car running wins.",
    start = "dmstart", menu = "demolitionmenu",
  },
}

-- In-game HUD look for games that use the shared HUD (client/hud.lua) but are
-- not in the hub list above. Hub games reuse their Config.Games title/icon/accent.
Config.HudExtra = {
  ["spz-hideseek"] = { title = "RC Hide & Seek", icon = "user-secret", accent = "#22c55e" },
}

-- Minigame NPCs: walk up, press E, the hub opens on that game.
-- coords = x, y, z (ground is found automatically), heading.
Config.NpcDistance = 3.5      -- walk within this radius and the hub opens on that game
                              -- (NPCs stand ~4.5 m apart, so keep this under ~4)
Config.Npcs = {
  { game = "colorrush",    model = "a_m_y_hipster_01",  coords = vec4(178.0, -940.0, 30.1, 320.0) },
  { game = "pursuit",      model = "s_m_y_cop_01",      coords = vec4(182.5, -944.0, 30.1, 320.0) },
  { game = "rocketleague", model = "a_m_y_beach_01",    coords = vec4(187.0, -948.0, 30.1, 320.0) },
  { game = "bomb",         model = "s_m_y_ammucity_01", coords = vec4(191.5, -952.0, 30.1, 320.0) },
  { game = "demolition",   model = "s_m_m_autoshop_01", coords = vec4(196.0, -956.0, 30.1, 320.0) },
  { game = "cyclone",      model = "s_m_y_construct_01", coords = vec4(200.5, -960.0, 30.1, 320.0) },
}
