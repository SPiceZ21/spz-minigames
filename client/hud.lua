-- spz-minigames — shared in-game HUD
--
-- Every minigame draws its HUD through these exports instead of GTA text, so
-- they all share the hub's look. The calling resource is the owner: its title,
-- icon and accent come from Config.Games / Config.HudExtra automatically, and
-- its HUD is cleared if it stops.
--
--   exports["spz-minigames"]:Hud({
--       chips  = { "3 / 8 ALIVE", { text = "WAVE 2", hot = true } },
--       status = { label = "FUSE", value = "12.4", color = "bad", sub = "…" },
--       alert  = "YOU HAVE THE BOMB — RAM SOMEONE!",     -- pulsing red pill
--       hint   = { text = "…", color = "ok" },           -- or a plain string
--       bar    = { label = "CAR", pct = 0.8 },           -- colour auto by pct unless given
--       foot   = { text = "JUMP READY", cmd = "+cr_jump", default = "E", color = "ok" },
--       keys   = { { cmd = "+cr_jump", default = "E", label = "Jump", hot = true },
--                  { control = 22, default = "SPACE", label = "Handbrake" } },   -- live bindings
--       board  = { title = "Standings", note = "Round 2", numbered = true,
--                  rows = { { src = 3, name = "Ace", value = "2 W", sub = "4 waves",
--                             icon = "bomb", color = "bad", valueColor = "ok", out = false, sep = false } } },
--   })                                       -- a row whose src is this player is highlighted                                       -- Hud(nil) / Hud(false) hides it
--   exports["spz-minigames"]:Flash("3", color?, ms?)     -- big centre pop
--   exports["spz-minigames"]:Shard(title, sub?, color?, ms?)   -- result card
--
-- Colours: "ok" | "bad" | "warn" | "dim" | "accent", "#hex", or { r, g, b }.
-- Hud() is cheap to call every tick: identical payloads are not resent.

local owner, last = nil, nil

local function liveKey(cmd, default, pad)
    local ok, k = pcall(function() return exports["spz-core"]:KeyFor(cmd, default, pad) end)
    return (ok and k) or default or "?"
end
local function liveControl(control, default, pad)
    local ok, k = pcall(function() return exports["spz-core"]:KeyForControl(control, default, pad) end)
    return (ok and k) or default or "?"
end

local function lookOf(res)
    for _, g in ipairs(Config.Games) do
        if g.resource == res then return g end
    end
    return Config.HudExtra[res] or {}
end

local function Hud(d)
    local res = GetInvokingResource() or GetCurrentResourceName()
    if not d then
        if owner == res then
            owner, last = nil, nil
            SendNUIMessage({ hud = "set", d = false })
        end
        return
    end
    if d.board and d.board.rows then
        local me = GetPlayerServerId(PlayerId())
        local rows = {}
        for i, row in ipairs(d.board.rows) do
            local r = {}
            for k, v in pairs(row) do r[k] = v end
            r.me, r.src = row.src == me, nil
            rows[i] = r
        end
        d.board = { title = d.board.title, note = d.board.note, numbered = d.board.numbered, rows = rows }
    end
    -- Key hints: { cmd = "+cr_jump", default = "E", pad = "RLEFT_INDEX", label = "Jump", hot = true }
    -- `pad` = the controller button; shown instead while a gamepad is in use.
    -- (or control = <GTA control id>). The key shown is the player's LIVE
    -- binding (spz-core KeyFor), so a rebind in Settings shows up here too.
    if d.keys or (d.foot and (d.foot.cmd or d.foot.control)) then
        local function resolve(k)
            if k.cmd then return liveKey(k.cmd, k.default, k.pad) end
            if k.control then return liveControl(k.control, k.default, k.pad) end
            return k.key or k.default
        end
        if d.keys then
            local list = {}
            for i, k in ipairs(d.keys) do
                list[i] = { key = resolve(k), label = k.label, hot = k.hot, dim = k.dim }
            end
            d.keys = list
        end
        if d.foot and (d.foot.cmd or d.foot.control) then
            d.foot = { text = d.foot.text, color = d.foot.color, key = resolve(d.foot) }
        end
    end
    local look = lookOf(res)
    d.title = d.title or look.title
    d.icon = d.icon or look.icon
    d.accent = d.accent or look.accent
    local enc = json.encode(d)
    if owner == res and enc == last then return end
    owner, last = res, enc
    SendNUIMessage({ hud = "set", d = d })
end

local function Flash(text, color, ms)
    SendNUIMessage({ hud = "flash", d = { text = tostring(text), color = color, ms = ms } })
end

local function Shard(title, sub, color, ms)
    local look = lookOf(GetInvokingResource() or "")
    SendNUIMessage({ hud = "shard", d = { kicker = look.title, title = title, sub = sub, color = color, ms = ms } })
end

exports("Hud", Hud)
exports("Flash", Flash)
exports("Shard", Shard)

AddEventHandler("onResourceStop", function(res)
    if res == owner then
        owner, last = nil, nil
        SendNUIMessage({ hud = "clear" })
    end
end)
