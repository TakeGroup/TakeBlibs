-- Speicherung der Blips. Jede Änderung wird SOFORT gespeichert, und zwar doppelt:
--   1. KVP (interner FiveM-Server-Speicher): bleibt bei Neustarts UND beim Neu-Kopieren des Ordners erhalten
--   2. MySQL (oxmysql), falls vorhanden
-- Zusätzlich wird data/blips.json als lesbare Sicherung geschrieben.
-- Beim Start wird geladen: MySQL -> KVP -> data/blips.json (die erste Quelle mit Blips gewinnt).

Blips = {}        -- [id] = blip
BlipsReady = false

local KVP_KEY = 'takeblibs:blips'
local useSQL = false

local function list()
    local out = {}
    for _, b in pairs(Blips) do out[#out + 1] = b end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end

local function decodeList(raw, source)
    if not raw or raw == '' then return nil end
    local ok, data = pcall(json.decode, raw)
    if ok and type(data) == 'table' then return data end
    print(('^1[TakeBlibs] %s ist beschädigt - wird ignoriert.^0'):format(source))
    return nil
end

local function sqlAwait(query, params)
    local p = promise.new()
    exports.oxmysql:query(query, params or {}, function(result) p:resolve(result or {}) end)
    return Citizen.Await(p)
end

local function sqlAsync(query, params)
    exports.oxmysql:query(query, params or {}, function(result)
        if result == nil then print('^1[TakeBlibs] MySQL-Fehler beim Speichern - Blips sind trotzdem im KVP gesichert.^0') end
    end)
end

-- Kompletter Stand in KVP + JSON (wenige KB, daher immer komplett)
local function saveLocal()
    local raw = json.encode(list())
    SetResourceKvp(KVP_KEY, raw)
    SaveResourceFile(RESOURCE, 'data/blips.json', json.encode(list(), { indent = true }), -1)
end

function NextBlipId()
    local max = GetResourceKvpInt('takeblibs:lastId')
    for id in pairs(Blips) do if id > max then max = id end end
    SetResourceKvpInt('takeblibs:lastId', max + 1)
    return max + 1
end

function SaveBlip(blip)
    saveLocal()
    if useSQL then
        sqlAsync('REPLACE INTO `takeblibs_blips` (`id`, `data`) VALUES (?, ?)', { blip.id, json.encode(blip) })
    end
end

function DeleteBlipData(id)
    saveLocal()
    if useSQL then
        sqlAsync('DELETE FROM `takeblibs_blips` WHERE `id` = ?', { id })
    end
end

local function addAll(entries)
    local n = 0
    for _, b in ipairs(entries or {}) do
        if type(b) == 'table' and tonumber(b.id) then
            b.id = math.floor(tonumber(b.id))
            Blips[b.id] = b
            n = n + 1
        end
    end
    return n
end

CreateThread(function()
    local state = GetResourceState('oxmysql')
    if Config.Storage ~= 'json' and state ~= 'missing' and state ~= 'unknown' then
        local timeout = GetGameTimer() + 20000
        while GetResourceState('oxmysql') ~= 'started' and GetGameTimer() < timeout do Wait(100) end
        useSQL = GetResourceState('oxmysql') == 'started'
    end

    if Config.Storage == 'mysql' and not useSQL then
        print('^1[TakeBlibs] Config.Storage = "mysql", aber oxmysql läuft nicht! Blips werden im KVP gespeichert.^0')
    end

    local source = nil

    if useSQL then
        sqlAwait([[
            CREATE TABLE IF NOT EXISTS `takeblibs_blips` (
                `id` INT NOT NULL PRIMARY KEY,
                `data` LONGTEXT NOT NULL
            )
        ]])
        local rows = {}
        for _, row in ipairs(sqlAwait('SELECT * FROM `takeblibs_blips`')) do
            local ok, b = pcall(json.decode, row.data)
            if ok and type(b) == 'table' then
                b.id = row.id
                rows[#rows + 1] = b
            end
        end
        if addAll(rows) > 0 then source = 'MySQL' end
    end

    -- KVP gilt, sobald es existiert (auch leer = alle Blips wurden gelöscht -> alte JSON nicht zurückholen)
    local kvp = GetResourceKvpString(KVP_KEY)
    if not source and kvp then
        addAll(decodeList(kvp, 'KVP-Speicher'))
        source = 'KVP'
    end

    if not source and addAll(decodeList(LoadResourceFile(RESOURCE, 'data/blips.json'), 'data/blips.json')) > 0 then
        source = 'data/blips.json'
    end

    -- Geladene Blips überall ablegen (z. B. KVP -> MySQL, wenn MySQL neu dazukam)
    if source then
        saveLocal()
        if useSQL and source ~= 'MySQL' then
            for _, b in pairs(Blips) do SaveBlip(b) end
        end
    end

    print(('^2[TakeBlibs] %d Blip(s) geladen aus %s. Speichern: %s^0'):format(
        #list(), source or '- (noch keine Blips)', useSQL and 'MySQL + KVP' or 'KVP'))

    BlipsReady = true
    SyncAll()
end)

-- Beim Stoppen noch einmal alles sichern
AddEventHandler('onResourceStop', function(res)
    if res == RESOURCE and BlipsReady then
        SetResourceKvp(KVP_KEY, json.encode(list()))
    end
end)
