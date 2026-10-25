ESX = nil
RESOURCE = GetCurrentResourceName()

if Config.Framework == 'esx' then
    local ok, obj = pcall(function() return exports['es_extended']:getSharedObject() end)
    if ok and obj then
        ESX = obj
    else
        print('^1[TakeBlibs] es_extended nicht gefunden - starte im Standalone-Modus. Starte es_extended VOR TakeBlibs.^0')
    end
end

function GetXPlayer(src)
    if not ESX then return nil end
    return ESX.GetPlayerFromId(src)
end

function GetJobName(src)
    local xPlayer = GetXPlayer(src)
    return xPlayer and xPlayer.job and xPlayer.job.name or nil
end

-- ---------------------------------------------------------------- Rechte

function GetLevel(src)
    src = tonumber(src)
    if not src or src <= 0 then return 9999 end -- Konsole

    local level = 0
    local xPlayer = GetXPlayer(src)
    if xPlayer then
        level = Config.Groups[xPlayer.getGroup()] or 0
    end
    if Config.UseAce then
        for group, lvl in pairs(Config.Groups) do
            if lvl > level and IsPlayerAceAllowed(src, 'takeblibs.' .. group) then
                level = lvl
            end
        end
    end
    return level
end

function HasPerm(src, perm)
    local need = Config.Permissions[perm]
    if not need then return false end
    return GetLevel(src) >= need
end

function GetGroupName(src)
    local xPlayer = GetXPlayer(src)
    if xPlayer then return xPlayer.getGroup() end
    local best, bestLvl = 'user', 0
    for group, lvl in pairs(Config.Groups) do
        if lvl > bestLvl and IsPlayerAceAllowed(src, 'takeblibs.' .. group) then
            best, bestLvl = group, lvl
        end
    end
    return best
end

-- ---------------------------------------------------------------- Allgemein

function Name(src)
    if not src or src == 0 then return 'Konsole' end
    return GetPlayerName(src) or ('#' .. tostring(src))
end

function Notify(src, msg, nType)
    if src == 0 then print('[TakeBlibs] ' .. msg) return end
    TriggerClientEvent('takeblibs:notify', src, msg, nType or 'info')
end

function GetIdentifier(src, kind)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:find('^' .. kind .. ':') then return id end
    end
    return nil
end

function FormatTime(ts)
    if not ts or ts == 0 then return '-' end
    return os.date('%d.%m.%Y %H:%M', ts)
end

function Trim(s, max)
    s = tostring(s or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if max and #s > max then s = s:sub(1, max) end
    return s
end

-- ---------------------------------------------------------------- Logs

function Log(src, action, details, color)
    local adminName = Name(src)
    print(('[TakeBlibs] %s (%s) -> %s%s'):format(adminName, tostring(src), action, details and (' | ' .. details:gsub('\n', ' | ')) or ''))

    if SvConfig.Webhook == '' then return end

    local fields = {
        { name = 'Admin', value = ('%s (ID %s)\n%s'):format(adminName, tostring(src), src ~= 0 and (GetIdentifier(src, 'license') or '-') or '-'), inline = true },
    }
    if details then
        fields[#fields + 1] = { name = 'Details', value = tostring(details):sub(1, 1000), inline = false }
    end

    PerformHttpRequest(SvConfig.Webhook, function() end, 'POST', json.encode({
        username = SvConfig.WebhookName,
        embeds = { {
            title = action,
            color = color or 3447003,
            fields = fields,
            footer = { text = 'TakeBlibs • ' .. os.date('%d.%m.%Y %H:%M:%S') },
        } }
    }), { ['Content-Type'] = 'application/json' })
end

-- ---------------------------------------------------------------- Callbacks

local Callbacks = {}

function RegisterCallback(name, fn)
    Callbacks[name] = fn
end

RegisterNetEvent('takeblibs:cb:request', function(name, reqId, ...)
    local src = source
    local fn = Callbacks[name]
    if not fn then
        TriggerClientEvent('takeblibs:cb:response', src, reqId)
        return
    end
    local result = table.pack(pcall(fn, src, ...))
    if not result[1] then
        print('^1[TakeBlibs] Fehler in Callback ' .. tostring(name) .. ': ' .. tostring(result[2]) .. '^0')
        TriggerClientEvent('takeblibs:cb:response', src, reqId)
        return
    end
    TriggerClientEvent('takeblibs:cb:response', src, reqId, table.unpack(result, 2, result.n))
end)
