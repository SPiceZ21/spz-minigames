fx_version 'cerulean'
game 'gta5'

name 'spz-minigames'
description 'SPiceZ Minigame Hub — one NUI to queue, start, invite and track Color Rush, Hot Pursuit, Rocket League, Bomb Tag and Demolition, plus the shared in-game HUD they draw with.'
version '1.0.3'
author 'SPiceZ-Core'
lua54 'yes'

shared_scripts {
  '@ox_lib/init.lua',
  'config.lua',
}

client_scripts {
    '@spz-hud/shim.lua',   -- NUI goes through spz-hud
  'client/main.lua',
  'client/hud.lua',
  'client/npcs.lua',
}

-- ui_page 'ui/index.html'  -- drawn by spz-hud now (web/public/apps/spz-minigames); uncomment + drop the shim to roll back

files {
  'ui/index.html',
  'ui/style.css',
  'ui/app.js',
  'ui/hud.css',
  'ui/hud.js',
  'ui/keyglyph.js',
  'ui/keyglyph.css',
  'ui/fonts/*.ttf',
}

-- The hub owns no game logic: it talks to each minigame through the lobby
-- callbacks/events that minigame already exposes. A game whose resource is
-- not started is shown as offline, so none of them is a hard dependency.
dependencies {
    'spz-hud',
  'ox_lib',
}
