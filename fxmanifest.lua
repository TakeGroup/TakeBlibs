fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'TakeBlibs'
author 'TakeBlibs'
description 'TakeBlibs - Blip-Menü im TakeAdmin-Stil mit ESX-Support'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/utils.lua',
    'client/menu.lua',
    'client/blips.lua',
    'client/menus.lua',
    'client/main.lua'
}

server_scripts {
    'server/sv_config.lua',
    'server/utils.lua',
    'server/storage.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/*.png',
    'html/fonts/*.woff2'
}

-- Für FiveM Asset Escrow: diese Dateien bleiben lesbar und bearbeitbar
escrow_ignore {
    'config.lua',
    'server/sv_config.lua'
}
