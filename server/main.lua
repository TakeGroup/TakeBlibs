-- ================================================================ Hilfen

local VALID_DISPLAY = {}
for _, d in ipairs(Config.DisplayModes) do VALID_DISPLAY[d.display] = true end

local function num(v, min, max, default)
    v = tonumber(v)
    if not v or v ~= v then return default end
    return math.max(min, math.min(max, v))
end

local function count()
    local n = 0
    for _ in pairs(Blips) do n = n + 1 end
    return n
end

-- Übernimmt nur erlaubte Felder aus data. Gibt bei Fehler eine Meldung zurück (nichts wird geändert).
local function apply(src, blip, data)
    if type(data) ~= 'table' then return 'Ungültige Daten.' end
    if (data.jobs ~= nil or data.minLevel ~= nil) and not HasPerm(src, 'visibility') then
        return 'Keine Berechtigung für die Sichtbarkeit.'
    end
    if data.name ~= nil and Trim(data.name, 60) == '' then return 'Name darf nicht leer sein.' end

    if data.name ~= nil then blip.name = Trim(data.name, 60) end
    if data.sprite ~= nil then blip.sprite = math.floor(num(data.sprite, 0, 1000, blip.sprite)) end
    if data.color ~= nil then blip.color = math.floor(num(data.color, 0, 85, blip.color)) end
    if data.scale ~= nil then blip.scale = math.floor(num(data.scale, 0.1, 3.0, blip.scale) * 10 + 0.5) / 10 end
    if data.display ~= nil and VALID_DISPLAY[tonumber(data.display)] then blip.display = tonumber(data.display) end
    if data.shortRange ~= nil then blip.shortRange = data.shortRange == true end
    if data.enabled ~= nil then blip.enabled = data.enabled == true end
    if data.radius ~= nil then blip.radius = math.floor(num(data.radius, 0, 5000, blip.radius)) end
    if data.category ~= nil then blip.category = Trim(data.category, 30) end
    if data.distance ~= nil then blip.distance = math.floor(num(data.distance, 0, 20000, blip.distance or 0)) end
    if data.x ~= nil then
        blip.x = num(data.x, -20000, 20000, blip.x)
        blip.y = num(data.y, -20000, 20000, blip.y)
        blip.z = num(data.z, -500, 3000, blip.z)
    end
    if data.minLevel ~= nil then blip.minLevel = math.floor(num(data.minLevel, 0, 1000, 0)) end
    if data.jobs ~= nil then
        local jobs, seen = {}, {}
        for _, j in ipairs(type(data.jobs) == 'table' and data.jobs or {}) do
            j = Trim(j, 50)
            if j ~= '' and not seen[j] and #jobs < 50 then
                seen[j] = true
                jobs[#jobs + 1] = j
            end
        end
        blip.jobs = jobs
    end
end

local function describe(data)
    local parts = {}
    for k, v in pairs(data) do
        if type(v) == 'table' then v = #v > 0 and table.concat(v, ', ') or 'alle' end
        if type(v) == 'number' and v % 1 ~= 0 then v = ('%.2f'):format(v) end
        parts[#parts + 1] = k .. ': ' .. tostring(v)
    end
    table.sort(parts)
    return table.concat(parts, '\n')
end

local function full(b)
    local copy = {}
    for k, v in pairs(b) do copy[k] = v end
    copy.created = FormatTime(b.createdAt)
    return copy
end

-- ================================================================ Sync & Sichtbarkeit

local function canSee(b, level, job)
    if not b.enabled then return false end
    if (b.minLevel or 0) > 0 and level < b.minLevel then return false end
    if b.jobs and #b.jobs > 0 then
        for _, j in ipairs(b.jobs) do
            if j == job then return true end
        end
        return false
    end
    return true
end

-- Nur die Daten, die zum Zeichnen nötig sind (Jobs / Ränge bleiben auf dem Server)
local function public(b)
    return {
        id = b.id, name = b.name, sprite = b.sprite, color = b.color, scale = b.scale,
        display = b.display, shortRange = b.shortRange, radius = b.radius,
        distance = b.distance, x = b.x, y = b.y, z = b.z,
    }
end

function SyncPlayer(src)
    if not BlipsReady then return end
    src = tonumber(src)
    local level, job, list = GetLevel(src), GetJobName(src), {}
    for _, b in pairs(Blips) do
        if canSee(b, level, job) then list[#list + 1] = public(b) end
    end
    TriggerClientEvent('takeblibs:sync', src, list)
end

function SyncAll()
    for _, id in ipairs(GetPlayers()) do SyncPlayer(id) end
end

RegisterNetEvent('takeblibs:requestSync', function()
    SyncPlayer(source)
end)

AddEventHandler('esx:playerLoaded', function(src) SyncPlayer(src) end)
AddEventHandler('esx:setJob', function(src) SyncPlayer(src) end)

-- ================================================================ Callbacks

RegisterCallback('getPerms', function(src)
    local level = GetLevel(src)
    local perms = {}
    for perm, need in pairs(Config.Permissions) do
        perms[perm] = level >= need
    end
    return { level = level, group = GetGroupName(src), perms = perms, esx = ESX ~= nil }
end)

RegisterCallback('getAll', function(src)
    if not HasPerm(src, 'menu') then return {} end
    local list = {}
    for _, b in pairs(Blips) do list[#list + 1] = full(b) end
    table.sort(list, function(a, b)
        if (a.category or '') ~= (b.category or '') then
            if a.category == '' then return false end
            if b.category == '' then return true end
            return a.category:lower() < b.category:lower()
        end
        return a.name:lower() < b.name:lower()
    end)
    return list
end)

RegisterCallback('getBlip', function(src, id)
    if not HasPerm(src, 'menu') then return nil end
    local b = Blips[tonumber(id) or -1]
    return b and full(b) or nil
end)

RegisterCallback('getJobs', function(src)
    if not ESX or not HasPerm(src, 'visibility') then return {} end
    local jobs = {}
    for name, job in pairs(ESX.GetJobs()) do
        jobs[#jobs + 1] = { name = name, label = job.label or name }
    end
    table.sort(jobs, function(a, b) return a.label:lower() < b.label:lower() end)
    return jobs
end)

local function newBlip(src)
    local d = Config.Defaults
    return {
        id = NextBlipId(), name = 'Blip', sprite = d.sprite, color = d.color, scale = d.scale,
        display = d.display, shortRange = d.shortRange, radius = d.radius, category = d.category,
        distance = d.distance or 0,
        x = 0.0, y = 0.0, z = 0.0, enabled = true, jobs = {}, minLevel = 0,
        createdBy = Name(src), createdAt = os.time(),
    }
end

RegisterCallback('createBlip', function(src, data)
    if not HasPerm(src, 'create') then return nil, 'Keine Berechtigung.' end
    if not BlipsReady then return nil, 'Blips werden noch geladen.' end
    if count() >= Config.MaxBlips then return nil, ('Maximum von %d Blips erreicht.'):format(Config.MaxBlips) end
    if type(data) ~= 'table' or data.x == nil then return nil, 'Ungültige Daten.' end

    local blip = newBlip(src)
    local err = apply(src, blip, { name = data.name, x = data.x, y = data.y, z = data.z })
    if err then return nil, err end

    Blips[blip.id] = blip
    SaveBlip(blip)
    SyncAll()
    Log(src, 'Blip erstellt', ('#%d %s\nPosition: %.1f, %.1f, %.1f'):format(blip.id, blip.name, blip.x, blip.y, blip.z), 3066993)
    return blip.id
end)

RegisterCallback('duplicateBlip', function(src, id, coords)
    if not HasPerm(src, 'create') then return nil, 'Keine Berechtigung.' end
    local orig = Blips[tonumber(id) or -1]
    if not orig then return nil, 'Blip existiert nicht mehr.' end
    if count() >= Config.MaxBlips then return nil, ('Maximum von %d Blips erreicht.'):format(Config.MaxBlips) end

    local blip = newBlip(src)
    for _, k in ipairs({ 'sprite', 'color', 'scale', 'display', 'shortRange', 'radius', 'distance', 'category', 'enabled', 'minLevel', 'x', 'y', 'z' }) do
        blip[k] = orig[k]
    end
    for i, j in ipairs(orig.jobs or {}) do blip.jobs[i] = j end
    blip.name = Trim(orig.name .. ' (Kopie)', 60)
    if type(coords) == 'table' and coords.x then
        apply(src, blip, { x = coords.x, y = coords.y, z = coords.z })
    end

    Blips[blip.id] = blip
    SaveBlip(blip)
    SyncAll()
    Log(src, 'Blip dupliziert', ('#%d -> #%d %s'):format(orig.id, blip.id, blip.name), 3066993)
    return blip.id
end)

RegisterCallback('updateBlip', function(src, id, changes)
    if not HasPerm(src, 'edit') then return false, 'Keine Berechtigung.' end
    local blip = Blips[tonumber(id) or -1]
    if not blip then return false, 'Blip existiert nicht mehr.' end

    local err = apply(src, blip, changes)
    if err then return false, err end

    SaveBlip(blip)
    SyncAll()
    Log(src, 'Blip geändert', ('#%d %s\n%s'):format(blip.id, blip.name, describe(changes)))
    return true
end)

RegisterCallback('deleteBlip', function(src, id)
    if not HasPerm(src, 'delete') then return false, 'Keine Berechtigung.' end
    local blip = Blips[tonumber(id) or -1]
    if not blip then return false, 'Blip existiert nicht mehr.' end

    Blips[blip.id] = nil
    DeleteBlipData(blip.id)
    SyncAll()
    Log(src, 'Blip gelöscht', ('#%d %s\nPosition: %.1f, %.1f, %.1f'):format(blip.id, blip.name, blip.x, blip.y, blip.z), 15158332)
    return true
end)

RegisterCallback('resync', function(src)
    if not HasPerm(src, 'resync') then return false end
    SyncAll()
    Log(src, 'Sync für alle erzwungen')
    return true
end)

-- ---------------------------------------------------------------- Konsole

-- tb_resync  -> alle Spieler neu synchronisieren
RegisterCommand('tb_resync', function(src)
    if src ~= 0 and not HasPerm(src, 'resync') then return end
    SyncAll()
    Notify(src, 'Blips an alle Spieler gesendet.', 'success')
end, false)

-- tb_list [Suchbegriff]  -> listet alle Blips
RegisterCommand('tb_list', function(src, args)
    if src ~= 0 and not HasPerm(src, 'menu') then return end
    local query = table.concat(args, ' '):lower()
    local n = 0
    for _, b in pairs(Blips) do
        if query == '' or b.name:lower():find(query, 1, true) or (b.category or ''):lower():find(query, 1, true) then
            n = n + 1
            Notify(src, ('#%d  %s  |  Sprite %d  Farbe %d  |  %.1f, %.1f, %.1f%s'):format(
                b.id, b.name, b.sprite, b.color, b.x, b.y, b.z, b.enabled and '' or '  (aus)'), 'info')
        end
    end
    Notify(src, n .. ' Blip(s).', 'info')
end, false)
