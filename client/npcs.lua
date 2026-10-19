-- spz-minigames — minigame NPCs
--
-- One ped per game (Config.Npcs) with a blip, a floating marker in the game's
-- accent colour and a zone: walk into it and the hub opens on that game.

local byId = {}
for _, g in ipairs(Config.Games) do byId[g.id] = g end

local spawned = {}   -- { ped, blip, def, game, pos }

local function hexRgb(hex)
    hex = tostring(hex or "#ffffff"):gsub("#", "")
    return tonumber(hex:sub(1, 2), 16) or 255, tonumber(hex:sub(3, 4), 16) or 255, tonumber(hex:sub(5, 6), 16) or 255
end

-- Floating label over a ped: game title in its accent colour, a hint under it.
-- Anchored with SetDrawOrigin (the game projects it), so it stays glued to the
-- ped; shrinks a little with distance.
local function drawLabel(pos, title, hint, r, g, b, dist)
    local k = math.max(0.6, 1.1 - dist / 45.0)
    local function line(text, y, size, cr, cg, cb)
        SetTextScale(size * k, size * k)
        SetTextFont(4)
        SetTextProportional(true)
        SetTextColour(cr, cg, cb, 245)
        SetTextOutline()
        SetTextCentre(true)
        SetTextEntry("STRING")
        AddTextComponentString(text)
        SetDrawOrigin(pos.x, pos.y, pos.z, 0)
        DrawText(0.0, y)
        ClearDrawOrigin()
    end
    line(title:upper(), -0.032 * k, 0.62, r, g, b)
    line(hint, 0.004 * k, 0.36, 240, 240, 240)
end

-- The hub key as the player has it bound (Config.Key by default), re-read
-- every few seconds so a rebind shows up.
local keyCache, keyAt = Config.Key or "F7", 0
local function hubKey()
    if GetGameTimer() - keyAt > 3000 then
        keyAt = GetGameTimer()
        local ok, k = pcall(function() return exports["spz-core"]:KeyFor(Config.KeyCommand, Config.Key) end)
        if ok and k and k ~= "" then keyCache = k end
    end
    return keyCache
end

local function groundZ(c)
    for _ = 1, 20 do
        local ok, z = GetGroundZFor_3dCoord(c.x, c.y, c.z + 2.0, false)
        if ok then return z end
        Wait(50)
    end
    return c.z - 1.0
end

local function spawnNpc(def)
    local g = byId[def.game]
    if not g then return end
    local model = joaat(def.model or "a_m_y_hipster_01")
    if not lib.requestModel(model, 5000) then return end

    RequestCollisionAtCoord(def.coords.x, def.coords.y, def.coords.z)
    local z = groundZ(def.coords)
    local ped = CreatePed(4, model, def.coords.x, def.coords.y, z, def.coords.w, false, true)
    SetModelAsNoLongerNeeded(model)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)

    local blip = AddBlipForEntity(ped)
    SetBlipSprite(blip, 304)
    SetBlipScale(blip, 0.75)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(g.title)
    EndTextCommandSetBlipName(blip)

    spawned[#spawned + 1] = { ped = ped, blip = blip, game = g, pos = vector3(def.coords.x, def.coords.y, z) }
end

local function cleanup()
    for _, n in ipairs(spawned) do
        if DoesBlipExist(n.blip) then RemoveBlip(n.blip) end
        if DoesEntityExist(n.ped) then DeletePed(n.ped) end
    end
    spawned = {}
end

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do Wait(500) end
    for _, def in ipairs(Config.Npcs or {}) do spawnNpc(def) end

    -- The zone fires once on entry; you have to step out of it before it can
    -- open again, so closing the hub while standing there doesn't reopen it.
    local inside = nil
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local me = GetEntityCoords(ped)
        local near = nil

        -- Hidden inside minigames / races.
        local st = LocalPlayer.state
        local busy = st.inMinigame or st.inRace

        for _, n in ipairs(spawned) do
            local d = #(me - n.pos)
            if d < 40.0 and not busy then
                sleep = 0
                local r, g, b = hexRgb(n.game.accent)
                -- title + hint above the chevron
                drawLabel(vector3(n.pos.x, n.pos.y, n.pos.z + 2.75), n.game.title,
                    ("Press %s - Join Minigames"):format(hubKey()), r, g, b, d)
                -- bobbing chevron over the head + ring at the feet
                DrawMarker(2, n.pos.x, n.pos.y, n.pos.z + 2.25, 0, 0, 0, 180.0, 0, 0, 0.35, 0.35, 0.35,
                    r, g, b, 210, true, true, 2, false, nil, nil, false)
                -- the ring on the ground IS the trigger zone
                local dia = Config.NpcDistance * 2.0
                DrawMarker(25, n.pos.x, n.pos.y, n.pos.z + 0.02, 0, 0, 0, 0, 0, 0, dia, dia, 1.0,
                    r, g, b, 140, false, false, 2, false, nil, nil, false)
                -- nearest NPC wins if two zones overlap
                if d < Config.NpcDistance and not IsPedInAnyVehicle(ped, false)
                    and (not near or d < near.d) then
                    near = n; near.d = d
                end
            end
        end

        if near ~= inside then
            inside = near
            if near then exports[GetCurrentResourceName()]:OpenHub(near.game.id) end
        end
        Wait(sleep)
    end
end)

AddEventHandler("onResourceStop", function(res)
    if res == GetCurrentResourceName() then cleanup() end
end)
