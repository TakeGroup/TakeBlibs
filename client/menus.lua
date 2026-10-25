-- Alle Menüs. Jede Funktion gibt { subtitle, items, refresh, onLeave } zurück.
-- Jeder Eintrag hat eine kurze Erklärung (desc), die unter dem Menü angezeigt wird.

local function matches(text, filter)
    if not filter or filter == '' then return true end
    return tostring(text):lower():find(filter:lower(), 1, true) ~= nil
end

local function searchButton(state)
    return Button('~b~Suchen', 'Tippe einen Namen, eine Kategorie oder eine ID ein.\nLeer lassen = alle wieder anzeigen.', function()
        state.filter = KeyboardInput('Suche (Name, Kategorie oder ID)', state.filter or '', 50)
        Menu.Refresh()
    end, (state.filter and state.filter ~= '') and state.filter or nil)
end

-- Optionsliste + Index des aktuellen Werts. Unbekannte Werte (z. B. manuell gesetzte IDs) kommen vorne dazu.
local function optionsFor(list, key, value, unknownLabel)
    local opts = {}
    for i, o in ipairs(list) do opts[i] = o end
    for i, o in ipairs(opts) do
        if o[key] == value then return opts, i end
    end
    table.insert(opts, 1, { label = unknownLabel, [key] = value })
    return opts, 1
end

local function labelOf(list, key, value, fallback)
    for _, o in ipairs(list) do
        if o[key] == value then return o.label end
    end
    return fallback
end

-- Rang-Stufen aus Config.Groups (Gruppen mit gleichem Level werden zusammengefasst)
local function rankOptions()
    local byLevel = {}
    for group, lvl in pairs(Config.Groups) do
        byLevel[lvl] = byLevel[lvl] or {}
        table.insert(byLevel[lvl], group)
    end
    local opts = {}
    for lvl, groups in pairs(byLevel) do
        table.sort(groups)
        opts[#opts + 1] = { label = ('Team ab %s'):format(table.concat(groups, ' / ')), level = lvl }
    end
    table.sort(opts, function(a, b) return a.level < b.level end)
    table.insert(opts, 1, { label = 'Alle Spieler', level = 0 })
    return opts
end

local function spriteName(b) return labelOf(Config.Sprites, 'sprite', b.sprite, 'ID ' .. b.sprite) end
local function colorName(b) return labelOf(Config.Colors, 'color', b.color, 'ID ' .. b.color) end
local function categoryName(b) return (b.category or '') ~= '' and b.category or nil end

local function visibilityText(b)
    local parts = {}
    if (b.minLevel or 0) > 0 then
        parts[#parts + 1] = labelOf(rankOptions(), 'level', b.minLevel, 'Team ab Level ' .. b.minLevel)
    end
    if b.jobs and #b.jobs > 0 then parts[#parts + 1] = 'Jobs: ' .. table.concat(b.jobs, ', ') end
    return #parts > 0 and table.concat(parts, '  •  ') or 'Alle Spieler'
end

local function distanceLabel(d)
    return d <= 0 and 'Immer (ganze Karte)' or ('ab %d m'):format(d)
end

local function blipDesc(b)
    return ('%s  •  %s  •  %s\nKategorie: %s\nSieht: %s'):format(spriteName(b), colorName(b),
        distanceLabel(Blips.DistanceOf(b)), categoryName(b) or '-', visibilityText(b))
end

local function blipRight(b)
    if not b.enabled then return '~r~Aus' end
    if (b.minLevel or 0) > 0 then return '~o~Team' end
    if b.jobs and #b.jobs > 0 then return '~b~Job' end
    return nil
end

local function myCoords()
    local c = GetEntityCoords(PlayerPedId())
    return { x = c.x, y = c.y, z = c.z }
end

local function fetchBlip(id)
    local b = TriggerCallback('getBlip', id)
    if not b then Notify('Diesen Blip gibt es nicht mehr.', 'error') end
    return b
end

-- Speichert Änderungen und baut das aktuelle Menü neu auf
local function saver(id)
    return function(changes, msg)
        local ok, err = TriggerCallback('updateBlip', id, changes)
        if not ok then return Notify(err or 'Speichern hat nicht geklappt.', 'error') end
        if msg then Notify(msg, 'success') end
        Menu.Refresh()
    end
end

local function createBlip()
    local name = KeyboardInput('Wie soll der Blip heißen? (z. B. Polizeirevier)', '', 60)
    if not name then return end
    local data = myCoords()
    data.name = name
    local id, err = TriggerCallback('createBlip', data)
    if not id then return Notify(err or 'Blip konnte nicht erstellt werden.', 'error') end
    Notify(('Blip "%s" erstellt. Jetzt kannst du Symbol, Farbe usw. einstellen.'):format(name), 'success')
    Blips.FetchAll()
    Menu.Push(BlipMenu, id)
end

-- ================================================================ Hauptmenü

function MainMenu()
    local all = Blips.all or {}
    local items = {}

    if Can('create') then
        items[#items + 1] = Button('~g~+~s~  Neuen Blip erstellen', 'Stell dich an die Stelle, wo der Blip hin soll,\nund drück Enter. Danach gibst du einen Namen ein.', createBlip)
    end

    local list = Sub('Alle Blips', 'Alle Blips auf dem Server, nach Kategorie sortiert.\nWähle einen Blip aus, um ihn zu bearbeiten.', BlipListMenu, {})
    list.right = tostring(#all)
    items[#items + 1] = list

    items[#items + 1] = Sub('Blips in meiner Nähe', ('Zeigt nur Blips im Umkreis von %d Metern,\nder nächste steht oben.'):format(Config.NearbyDistance), NearbyMenu)
    items[#items + 1] = Sub('Einstellungen', 'Was du selbst auf der Karte siehst\n(nur für dich, nicht für andere Spieler).', OptionsMenu)
    items[#items + 1] = Sub('~b~Hilfe', 'Kurz erklärt: So funktioniert das Menü.', HelpMenu)
    items[#items + 1] = Button('Menü schließen', 'Oder einfach Backspace / Rechtsklick.', function() Menu.Close() end)

    return { subtitle = ('Hauptmenü  •  %s'):format(Perms.group or ''), items = items, refresh = true }
end

-- ================================================================ Listen

function BlipListMenu(state)
    local all = Blips.FetchAll()
    local items = { searchButton(state) }
    local count, lastCat = 0, nil

    for _, b in ipairs(all) do
        if matches(b.name, state.filter) or matches(b.category or '', state.filter) or tostring(b.id) == state.filter then
            count = count + 1
            local cat = categoryName(b) or 'Ohne Kategorie'
            if cat ~= lastCat then
                items[#items + 1] = Separator(cat)
                lastCat = cat
            end
            local it = Sub(b.name, blipDesc(b), BlipMenu, b.id)
            it.right = blipRight(b)
            items[#items + 1] = it
        end
    end
    if count == 0 then
        items[#items + 1] = Button(state.filter and '~c~Nichts gefunden' or '~c~Noch keine Blips vorhanden', state.filter and 'Versuch einen anderen Suchbegriff.' or 'Erstelle im Hauptmenü deinen ersten Blip.', nil)
    end
    return { subtitle = ('Alle Blips: %d'):format(count), items = items, refresh = true }
end

function NearbyMenu()
    local all = Blips.FetchAll()
    local pos = GetEntityCoords(PlayerPedId())
    local near = {}
    for _, b in ipairs(all) do
        local d = #(pos - vector3(b.x, b.y, b.z))
        if d <= Config.NearbyDistance then near[#near + 1] = { b = b, d = d } end
    end
    table.sort(near, function(a, b) return a.d < b.d end)

    local items = {}
    for _, n in ipairs(near) do
        local it = Sub(n.b.name, blipDesc(n.b), BlipMenu, n.b.id)
        it.right = (not n.b.enabled and '~r~Aus  ~s~' or '') .. ('%d m'):format(math.floor(n.d))
        items[#items + 1] = it
    end
    if #items == 0 then items[1] = Button('~c~Keine Blips in der Nähe', 'Fahr woanders hin oder schau unter "Alle Blips".', nil) end
    return { subtitle = ('In meiner Nähe: %d'):format(#near), items = items, refresh = true }
end

-- ================================================================ Blip: Übersicht

function BlipMenu(id)
    local b = fetchBlip(id)
    if not b then return nil end
    local items = {}
    local function add(item) items[#items + 1] = item end

    local look = Sub('Aussehen', 'Name, Symbol, Farbe, Größe und Kreis\nauf der Karte ändern.', BlipLookMenu, id)
    look.right = ('%s, %s'):format(spriteName(b), colorName(b))
    add(look)

    local vis = Sub('Wer sieht den Blip?', 'Für alle, nur fürs Team oder nur für bestimmte Jobs.\nAußerdem: an/aus und ab welcher Entfernung er erscheint.', BlipVisibilityMenu, id)
    vis.right = b.enabled and (blipRight(b) or 'Alle') or '~r~Aus'
    add(vis)

    local posItem = Sub('Position', 'Hinteleportieren, Wegpunkt setzen\noder den Blip woanders hinschieben.', BlipPositionMenu, id)
    posItem.right = ('%d m entfernt'):format(math.floor(#(GetEntityCoords(PlayerPedId()) - vector3(b.x, b.y, b.z))))
    add(posItem)

    add(Separator())

    if Can('create') then
        add(Button('Kopie erstellen', 'Macht eine Kopie mit gleichen Einstellungen,\naber an DEINER aktuellen Position.', function()
            local newId, err = TriggerCallback('duplicateBlip', id, myCoords())
            if not newId then return Notify(err or 'Kopie hat nicht geklappt.', 'error') end
            Notify('Kopie erstellt. Du bearbeitest jetzt die Kopie.', 'success')
            Blips.FetchAll()
            Menu.Back()
            Menu.Push(BlipMenu, newId)
        end))
    end
    if Can('delete') then
        add(Button('~r~Blip löschen', 'Entfernt den Blip für immer.\nTipp: Unter "Wer sieht den Blip?" kannst du ihn auch nur ausschalten.', function()
            Menu.Confirm(('"%s" wirklich löschen?'):format(b.name), function()
                local ok, err = TriggerCallback('deleteBlip', id)
                if not ok then return Notify(err or 'Löschen hat nicht geklappt.', 'error') end
                Notify(b.name .. ' gelöscht.', 'success')
                Blips.FetchAll()
                Menu.BackTo(1)
            end)
        end))
    end

    add(Separator('Info'))
    add(Button('Erstellt von', ('Am %s'):format(b.created or '-'), nil, b.createdBy or '-'))
    add(Button('Blip-ID', 'Nummer des Blips (z. B. für die Suche oder tb_list).', nil, '#' .. b.id))

    return { subtitle = b.name, items = items, refresh = true }
end

-- ================================================================ Blip: Aussehen

function BlipLookMenu(id)
    local b = fetchBlip(id)
    if not b then return nil end
    local save = saver(id)
    local function preview(changes) Blips.Preview(id, changes) end
    local items = {}
    local function add(item) items[#items + 1] = item end

    if not Can('edit') then
        add(Button('Name', nil, nil, b.name))
        add(Button('Symbol', nil, nil, spriteName(b)))
        add(Button('Farbe', nil, nil, colorName(b)))
        add(Button('Größe', nil, nil, ('%.1f'):format(b.scale)))
        add(Button('Kategorie', nil, nil, categoryName(b) or '-'))
        add(Button('~c~Nur ansehen', 'Dein Rang darf Blips nicht bearbeiten.', nil))
        return { subtitle = b.name .. '  •  Aussehen', items = items }
    end

    add(Button('Name', 'So heißt der Blip auf der Karte.\nEnter = neuen Namen eintippen.', function()
        local name = KeyboardInput('Neuer Name', b.name, 60)
        if name then save({ name = name }) end
    end, b.name))

    local sprites, si = optionsFor(Config.Sprites, 'sprite', b.sprite, 'ID ' .. b.sprite)
    add(List('Symbol', 'Das Bild auf der Karte.\n←/→ = durchblättern (Karte zeigt es sofort), Enter = übernehmen.', sprites, si,
        function(_, o) save({ sprite = o.sprite }, 'Symbol gespeichert.') end,
        function(_, o) preview({ sprite = o.sprite }) end))

    local colors, ci = optionsFor(Config.Colors, 'color', b.color, 'ID ' .. b.color)
    add(List('Farbe', 'Farbe des Symbols.\n←/→ = durchblättern, Enter = übernehmen.', colors, ci,
        function(_, o) save({ color = o.color }, 'Farbe gespeichert.') end,
        function(_, o) preview({ color = o.color }) end))

    local scaleItem = Slider('Größe', ('Wie groß das Symbol ist (jetzt: %.1f).\n←/→ = kleiner/größer, Enter = übernehmen.'):format(b.scale), math.floor(b.scale * 10 + 0.5), 20,
        function(v) save({ scale = math.max(1, v) / 10 }, 'Größe gespeichert.') end)
    scaleItem.onChange = function(v)
        scaleItem.desc = ('Neue Größe: %.1f\nEnter = übernehmen.'):format(math.max(1, v) / 10)
        preview({ scale = math.max(1, v) / 10 })
    end
    add(scaleItem)

    local radii = {}
    for i, r in ipairs(Config.Radius) do radii[i] = { label = r == 0 and 'Aus' or (r .. ' m'), radius = r } end
    local radiusOpts, ri = optionsFor(radii, 'radius', b.radius or 0, (b.radius or 0) .. ' m')
    add(List('Kreis um den Blip', 'Farbiger Bereich auf der Karte, z. B. für Gebiete.\n←/→ = Größe wählen, Enter = übernehmen.', radiusOpts, ri,
        function(_, o) save({ radius = o.radius }, 'Kreis gespeichert.') end,
        function(_, o) preview({ radius = o.radius }) end))

    add(Button('Kategorie', 'Nur zum Ordnen in "Alle Blips" (z. B. Shops, Fraktionen).\nSpieler sehen das nicht. Leer lassen = keine.', function()
        local cat = KeyboardInput('Kategorie (z. B. Shops, Fraktionen)', b.category or '', 30)
        save({ category = cat or '' })
    end, categoryName(b) or '~c~Keine'))

    add(Separator('Für Profis'))

    local displays, di = optionsFor(Config.DisplayModes, 'display', b.display, 'Modus ' .. b.display)
    add(List('Wo anzeigen?', 'Große Karte (Pause-Menü), kleine Minimap unten links oder beides.\nEnter = übernehmen.', displays, di,
        function(_, o) save({ display = o.display }, 'Gespeichert.') end))

    add(Checkbox('Minimap: nur in der Nähe', 'An = auf der Minimap erst sichtbar, wenn man in der Nähe ist.\nAus = immer am Rand der Minimap sichtbar.', b.shortRange, function(s)
        save({ shortRange = s })
    end))

    add(Button('Symbol per Nummer', 'Für Symbole, die nicht in der Liste sind.\nAlle Nummern: docs.fivem.net/docs/game-references/blips', function()
        local sprite = tonumber(KeyboardInput('Symbol-Nummer (0-1000)', tostring(b.sprite), 4))
        if sprite then save({ sprite = sprite }) end
    end, tostring(b.sprite)))

    add(Button('Farbe per Nummer', 'Für Farben, die nicht in der Liste sind.\nAlle Nummern: docs.fivem.net/docs/game-references/blips', function()
        local color = tonumber(KeyboardInput('Farb-Nummer (0-85)', tostring(b.color), 2))
        if color then save({ color = color }) end
    end, tostring(b.color)))

    return {
        subtitle = b.name .. '  •  Aussehen',
        items = items,
        -- Nicht gespeicherte Vorschau verwerfen, wenn man das Menü verlässt
        onLeave = function() Blips.Render() end,
    }
end

-- ================================================================ Blip: Sichtbarkeit

function BlipVisibilityMenu(id)
    local b = fetchBlip(id)
    if not b then return nil end
    local save = saver(id)
    local items = {}
    local function add(item) items[#items + 1] = item end
    local canEdit = Can('edit')

    if canEdit then
        add(Checkbox('Blip ist an', 'Aus = niemand sieht den Blip mehr, er bleibt aber gespeichert.\nNur das Team sieht ihn noch (halb durchsichtig) im Menü.', b.enabled, function(s)
            save({ enabled = s }, s and 'Blip ist wieder an.' or 'Blip ist jetzt aus.')
        end))
    else
        add(Button('Status', nil, nil, b.enabled and '~g~An' or '~r~Aus'))
    end

    local dist = Blips.DistanceOf(b)
    if canEdit then
        local opts = {}
        for i, d in ipairs(Config.Distances) do opts[i] = { label = distanceLabel(d), distance = d } end
        local distOpts, dsi = optionsFor(opts, 'distance', dist, distanceLabel(dist))
        add(List('Nur in der Nähe zeigen', 'Der Blip erscheint erst, wenn man so nah dran ist.\n"Immer" = auf der ganzen Karte. ←/→ wählen, Enter = übernehmen.', distOpts, dsi,
            function(_, o) save({ distance = o.distance }, 'Gespeichert: ' .. o.label) end))
    else
        add(Button('Nur in der Nähe zeigen', nil, nil, distanceLabel(dist)))
    end

    add(Separator('Wer darf ihn sehen?'))

    if canEdit and Can('visibility') then
        local ranks, rki = optionsFor(rankOptions(), 'level', b.minLevel or 0, 'Team ab Level ' .. (b.minLevel or 0))
        add(List('Rang', '"Alle Spieler" = jeder sieht ihn.\n"Team ab ..." = nur diese Gruppe und höher. Enter = übernehmen.', ranks, rki,
            function(_, o) save({ minLevel = o.level }, 'Gespeichert: ' .. o.label) end))
        if Perms.esx then
            local it = Sub('Jobs', 'Nur Spieler mit diesen Jobs sehen den Blip (z. B. nur Polizei).\nKein Job ausgewählt = alle Jobs.', BlipJobsMenu, id, {})
            it.right = #(b.jobs or {}) > 0 and table.concat(b.jobs, ', ') or 'Alle'
            add(it)
        end
    else
        add(Button('Sieht', 'Ändern darf das nur ein höherer Rang.', nil, visibilityText(b)))
    end

    add(Separator())
    add(Button('~c~Zusammengefasst', 'Rang und Jobs gelten zusammen:\nMan muss BEIDES erfüllen, um den Blip zu sehen.', nil, visibilityText(b)))

    return { subtitle = b.name .. '  •  Sichtbarkeit', items = items }
end

function BlipJobsMenu(id, state)
    local b = fetchBlip(id)
    if not b then return nil end
    local jobs = TriggerCallback('getJobs') or {}

    local selected = {}
    for _, j in ipairs(b.jobs or {}) do selected[j] = true end
    local function save()
        local list = {}
        for j in pairs(selected) do list[#list + 1] = j end
        table.sort(list)
        local ok, err = TriggerCallback('updateBlip', id, { jobs = list })
        if not ok then Notify(err or 'Speichern hat nicht geklappt.', 'error') end
    end

    local items = {
        searchButton(state),
        Button('~g~Alle Jobs dürfen ihn sehen', 'Entfernt alle Häkchen unten.', function()
            selected = {}
            save()
            Notify('Jetzt sehen ihn wieder alle Jobs.', 'success')
            Menu.Refresh()
        end),
        Separator('Häkchen = darf sehen'),
    }
    for _, job in ipairs(jobs) do
        if matches(job.label, state.filter) or matches(job.name, state.filter) then
            items[#items + 1] = Checkbox(job.label, ('Enter = an/aus. Wird sofort gespeichert.\n(Job-Name: %s)'):format(job.name), selected[job.name], function(s)
                selected[job.name] = s or nil
                save()
            end)
        end
    end
    if #jobs == 0 then items[#items + 1] = Button('~c~Keine Jobs gefunden', 'ESX hat keine Jobs geliefert.', nil) end

    return { subtitle = b.name .. '  •  Jobs', items = items }
end

-- ================================================================ Blip: Position

function BlipPositionMenu(id)
    local b = fetchBlip(id)
    if not b then return nil end
    local save = saver(id)
    local items = {}
    local function add(item) items[#items + 1] = item end
    local coordsText = ('%.1f, %.1f, %.1f'):format(b.x, b.y, b.z)

    if Can('teleport') then
        add(Button('Hinteleportieren', 'Bringt dich sofort zum Blip.', function()
            TeleportTo(vector3(b.x, b.y, b.z), b.z == 0.0)
        end))
    end
    add(Button('Wegpunkt setzen', 'Setzt ein Navi-Ziel zum Blip (lila Linie auf der Karte).', function()
        SetNewWaypoint(b.x, b.y)
        Notify('Wegpunkt gesetzt.', 'success')
    end))

    if Can('edit') then
        add(Separator('Blip verschieben'))
        add(Button('Hierher verschieben', 'Der Blip springt an die Stelle, wo du gerade stehst.', function()
            Menu.Confirm(('"%s" hierher verschieben?'):format(b.name), function()
                save(myCoords(), 'Blip verschoben.')
            end)
        end))
        add(Button('Zum Wegpunkt verschieben', 'Setz zuerst einen Wegpunkt auf der Karte (Rechtsklick),\ndann hier Enter.', function()
            local wp = GetFirstBlipInfoId(8)
            if not DoesBlipExist(wp) then return Notify('Du hast keinen Wegpunkt gesetzt.', 'error') end
            local c = GetBlipInfoIdCoord(wp)
            save({ x = c.x, y = c.y, z = 0.0 }, 'Blip zum Wegpunkt verschoben.')
        end))
    end

    add(Separator())
    add(Button('Koordinaten kopieren', 'Kopiert die Position als vector3,\nz. B. zum Einfügen in ein Script.', function()
        CopyToClipboard(('vector3(%.2f, %.2f, %.2f)'):format(b.x, b.y, b.z))
    end, coordsText))

    return { subtitle = b.name .. '  •  Position', items = items }
end

-- ================================================================ Einstellungen

function OptionsMenu()
    local items = {
        Checkbox('Alle Blips immer zeigen', 'Normal siehst du versteckte und weit entfernte Blips nur bei offenem Menü.\nAn = auch nach dem Schließen. Nur für dich.', Blips.adminView, function(s)
            Blips.adminView = s
        end),
        Checkbox('Nummern auf der Karte', 'Zeigt "#ID" vor jedem Blip-Namen auf der Karte.\nPraktisch zum Wiederfinden. Nur für dich.', Blips.showIds, function(s)
            Blips.showIds = s
            Blips.Render()
        end),
        Button('Blips neu laden', 'Falls etwas auf der Karte komisch aussieht:\nholt alle Blips frisch vom Server.', function()
            Blips.FetchAll()
            TriggerServerEvent('takeblibs:requestSync')
            Notify('Blips neu geladen.', 'success')
        end),
    }
    if Can('resync') then
        items[#items + 1] = Button('Blips an alle neu senden', 'Schickt die Blips nochmal an ALLE Spieler.\nNur nötig, wenn bei anderen etwas fehlt.', function()
            if TriggerCallback('resync') then Notify('Blips an alle Spieler gesendet.', 'success') end
        end)
    end
    items[#items + 1] = Separator('Info')
    items[#items + 1] = Button('Blips auf dem Server', nil, nil, tostring(#(Blips.all or {})))
    items[#items + 1] = Sub('Meine Rechte', 'Was du mit deinem Rang machen darfst.', RightsMenu)
    return { subtitle = 'Einstellungen', items = items }
end

local RIGHTS = {
    { perm = 'menu',       label = 'Menü öffnen & Blips ansehen' },
    { perm = 'teleport',   label = 'Zu Blips teleportieren' },
    { perm = 'create',     label = 'Blips erstellen & kopieren' },
    { perm = 'edit',       label = 'Blips bearbeiten' },
    { perm = 'visibility', label = 'Einstellen, wer Blips sieht' },
    { perm = 'delete',     label = 'Blips löschen' },
    { perm = 'resync',     label = 'Blips an alle neu senden' },
}

function RightsMenu()
    local items = {
        Button('Deine Gruppe', 'Kommt aus ESX (oder ACE) und Config.Groups.', nil, ('%s (Level %d)'):format(Perms.group or '-', Perms.level or 0)),
        Separator('Darfst du ...'),
    }
    for _, r in ipairs(RIGHTS) do
        local need = Config.Permissions[r.perm] or 0
        items[#items + 1] = Button(r.label, ('Braucht Level %d oder höher.'):format(need), nil, Can(r.perm) and '~g~Ja' or '~r~Nein')
    end
    return { subtitle = 'Meine Rechte', items = items }
end

-- ================================================================ Hilfe

local HELP = {
    { 'Steuerung', '↑/↓ = auswählen  •  Enter = öffnen / bestätigen\n←/→ = Wert ändern  •  Backspace = zurück' },
    { 'Blip erstellen', 'Stell dich an den Ort, wähle "Neuen Blip erstellen" und gib einen Namen ein.\nDanach stellst du Symbol, Farbe usw. ein.' },
    { 'Vorschau & Speichern', 'Bei Symbol, Farbe, Größe und Kreis siehst du mit ←/→ sofort die Vorschau.\nErst Enter speichert für alle!' },
    { 'Wer sieht den Blip?', 'Rang = nur Team ab einer Gruppe.  Jobs = nur bestimmte Jobs.\nAndere Spieler bekommen den Blip gar nicht erst.' },
    { 'Blip an/aus', 'Ausgeschaltete Blips sind für Spieler weg, aber nicht gelöscht.\nDas Team sieht sie im Menü halb durchsichtig.' },
    { 'Nur in der Nähe', 'Blips erscheinen erst, wenn man nah genug dran ist (Standard: 300 m).\nEinstellbar pro Blip unter "Wer sieht den Blip?". Bei offenem Menü siehst du alle.' },
    { 'Kategorien', 'Nur zum Ordnen der Liste "Alle Blips".\nSpieler sehen die Kategorie nicht.' },
    { 'Rechte', 'Was du darfst, hängt von deiner Gruppe ab.\nSchau unter Einstellungen > Meine Rechte.' },
}

function HelpMenu()
    local items = {}
    for _, h in ipairs(HELP) do
        items[#items + 1] = Button(h[1], h[2], nil)
    end
    return { subtitle = 'Hilfe  •  Eintrag auswählen und unten lesen', items = items }
end
