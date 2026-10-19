-- spz-minigames — client
--
-- The hub is a thin NUI over the lobby APIs every minigame already has.
-- While it is open it polls each started game's state and pushes one
-- snapshot to the page; every button maps to a callback/event/command the
-- game itself registered, so the per-game ox_lib menus keep working too.

local open = false
local byId = {}
for _, g in ipairs(Config.Games) do byId[g.id] = g end

local function started(g) return GetResourceState(g.resource) == "started" end

local function notify(msg, t) lib.notify({ title = "Minigames", description = msg, type = t or "inform" }) end

-- ── State ────────────────────────────────────────────────────────────────────

local function await(name, ...)
    local ok, a, b = pcall(lib.callback.await, name, false, ...)
    if not ok then return nil end
    return a, b
end

local function snapshotOf(g)
    local s = {
        id = g.id, title = g.title, icon = g.icon, accent = g.accent, blurb = g.blurb,
        kind = g.kind, teams = g.teams, practice = g.practice, hasStart = g.start ~= nil, modes = g.modes,
        online = started(g),
    }
    if not s.online then return s end

    if g.kind == "lobby" then
        s.lobby = await(g.ev .. "lobbyState")
    else
        local st = await("spz-pursuit:state")
        if st then
            s.room = st.room
            s.rooms = st.invites or {}
        end
    end
    return s
end

local function snapshot()
    local list = {}
    for i, g in ipairs(Config.Games) do list[i] = snapshotOf(g) end
    return list
end

local function push()
    SendNUIMessage({ action = "state", games = snapshot() })
end

-- ── Open / close ─────────────────────────────────────────────────────────────

local function setOpen(v, select)
    open = v
    SetNuiFocus(v, v)
    SendNUIMessage({ action = v and "open" or "close", select = select })
    if not v then return end
    push()
    CreateThread(function()
        while open do
            Wait(Config.PollMs)
            if open then push() end
        end
    end)
end

-- `select` (optional) is a Config.Games id to show first, e.g. from an NPC.
local function openHub(select)
    if open then return end
    if IsPauseMenuActive() then return end
    setOpen(true, type(select) == "string" and byId[select] and select or nil)
end

RegisterCommand(Config.Command, function() openHub() end, false)     -- typed: /minigames
RegisterCommand(Config.KeyCommand, function() openHub() end, false)  -- the key
RegisterKeyMapping(Config.KeyCommand, "Open the minigame hub", "keyboard", Config.Key)
exports("HubKey", function()
    local ok, k = pcall(function() return exports["spz-core"]:KeyFor(Config.KeyCommand, Config.Key) end)
    return (ok and k and k ~= "") and k or Config.Key
end)
exports("OpenHub", openHub)

-- Post-match spawn shared by every minigame (they fall back to where the
-- player stood if this resource is not running).
exports("ReturnPoint", function() return Config.ReturnSpawn end)

-- Hand the screen over to a game's own menu (car pickers, tuner, …).
local function handOff(command)
    setOpen(false)
    SetTimeout(150, function() ExecuteCommand(command) end)
end

-- ── NUI callbacks ────────────────────────────────────────────────────────────

RegisterNUICallback("close", function(_, cb) setOpen(false); cb(1) end)

-- spz-tutorial closes whatever it opened when the tour moves on.
AddEventHandler("spz-tutorial:closeUI", function() if open then setOpen(false) end end)


RegisterNUICallback("refresh", function(_, cb) cb(1); push() end)

RegisterNUICallback("online", function(data, cb)
    local g = byId[data.id]
    if not g or not started(g) then return cb({}) end
    local list
    if g.kind == "lobby" then
        list = await(g.ev .. "online") or {}
    else
        list = {}
        for _, p in ipairs(await("spz-pursuit:onlinePlayers") or {}) do
            list[#list + 1] = { source = p.src, name = p.name, busy = p.busy }
        end
    end
    cb(list)
end)

RegisterNUICallback("action", function(data, cb)
    cb(1)
    local g = byId[data.id]
    if not g then return end
    if not started(g) then return notify(g.title .. " is offline.", "error") end
    local a = data.action

    if a == "menu" then return handOff(g.menu) end

    if g.kind == "lobby" then
        local function call(name, ...)
            -- The game notifies the player itself; we only need the round trip.
            await(g.ev .. name, ...)
        end
        if a == "quick" then call("joinToggle")
        elseif a == "create" then
            call("createRoom", {
                name = data.name, private = data.private == true,
                max = tonumber(data.max), team = data.team, mode = data.mode,
            })
        elseif a == "joinRoom" then call("joinRoom", tonumber(data.room))
        elseif a == "leave" then call("leaveRoom")
        elseif a == "team" and g.teams then call("joinToggle", data.team)
        elseif a == "start" then call("startRoom")
        elseif a == "kick" then call("kick", tonumber(data.target))
        elseif a == "invite" then
            TriggerServerEvent(g.ev .. "invite", tonumber(data.target))
        elseif a == "practice" and g.practice then
            setOpen(false)
            await(g.ev .. "practice")
            return
        end
    else
        local function call(name, ...)
            local ok, msg = await("spz-pursuit:" .. name, ...)
            if not ok and msg then notify(msg, "error") end
            if ok and type(msg) == "string" then notify(msg, "success") end
            return ok
        end
        if a == "quick" then call("quickJoin")
        elseif a == "create" then call("create")
        elseif a == "joinRoom" then call("join", tonumber(data.room))
        elseif a == "leave" then call("leave")
        elseif a == "ready" then call("ready")
        elseif a == "start" then call("start")
        elseif a == "invite" then call("invite", tonumber(data.target))
        end
    end

    Wait(200)
    if open then push() end
end)

-- A round starting teleports the player away — never leave the hub stuck open.
for _, g in ipairs(Config.Games) do
    if g.kind == "lobby" then
        RegisterNetEvent(g.ev .. "start", function() if open then setOpen(false) end end)
        RegisterNetEvent(g.ev .. "joined", function() if open then setOpen(false) end end)
    else
        RegisterNetEvent("spz-pursuit:begin", function() if open then setOpen(false) end end)
    end
end

AddEventHandler("onResourceStop", function(res)
    if res == GetCurrentResourceName() and open then SetNuiFocus(false, false) end
end)

-- Server theme → the hub + HUD page (spz-core re-broadcasts it, so a page that
-- loaded late still gets it).
local function pushTheme(theme)
    if theme and next(theme) then SendNUIMessage({ action = "theme", theme = theme }) end
end
AddEventHandler("SPZ:themeUpdated", pushTheme)
CreateThread(function()
    Wait(2000)
    local ok, theme = pcall(function() return exports["spz-core"]:GetTheme() end)
    if ok then pushTheme(theme) end
end)

-- F8 check: which key the hub is on for this player (and that this version is live).
RegisterCommand("mgkey", function()
    local k = exports[GetCurrentResourceName()]:HubKey()
    print(("[spz-minigames] hub key: %s (mapping command %s, default %s)"):format(k, Config.KeyCommand, Config.Key))
end, false)
