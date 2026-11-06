-- client/mappins.lua — the minigame NPCs as pins for the TAB hub's map.
exports('GetMapPins', function()
    local games = {}
    for _, g in ipairs(Config.Games or {}) do games[g.id] = g end
    local pins = {}
    for i, n in ipairs(Config.Npcs or {}) do
        local g = games[n.game] or {}
        pins[#pins + 1] = {
            id = 'mg:' .. i, kind = 'minigame', label = g.title or n.game, sub = 'Minigame',
            x = n.coords.x, y = n.coords.y, z = n.coords.z, accent = g.accent,
            info = { { 'About', g.blurb or '' } },
        }
    end
    return pins
end)
