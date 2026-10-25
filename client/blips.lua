-- Zeichnet die Blips auf der Karte.
-- Normal: nur die Blips, die der Server für diesen Spieler freigibt (Job / Rang),
-- und nur, wenn man nah genug dran ist (Entfernung pro Blip, 0 = immer).
-- Admin-Ansicht (Menü offen oder dauerhaft an): ALLE Blips, deaktivierte halb durchsichtig.

Blips = {
    list = {},        -- vom Server gefiltert
    all = nil,        -- komplette Liste (nur Team)
    handles = {},     -- [id] = { main, radius }
    adminView = false,
    showIds = false,
}

local function adminActive()
    return (Menu.open or Blips.adminView) and Blips.all ~= nil
end

local function removeHandles(id)
    local h = Blips.handles[id]
    if not h then return end
    if h.main and DoesBlipExist(h.main) then RemoveBlip(h.main) end
    if h.radius and DoesBlipExist(h.radius) then RemoveBlip(h.radius) end
    Blips.handles[id] = nil
end

local function draw(b)
    removeHandles(b.id)
    local dim = b.enabled == false
    local h = {}

    if (b.radius or 0) > 0 then
        h.radius = AddBlipForRadius(b.x + 0.0, b.y + 0.0, b.z + 0.0, b.radius + 0.0)
        SetBlipColour(h.radius, b.color)
        SetBlipAlpha(h.radius, dim and math.floor(Config.RadiusAlpha / 2) or Config.RadiusAlpha)
    end

    local blip = AddBlipForCoord(b.x + 0.0, b.y + 0.0, b.z + 0.0)
    SetBlipSprite(blip, b.sprite)
    SetBlipDisplay(blip, b.display)
    SetBlipScale(blip, b.scale + 0.0)
    SetBlipColour(blip, b.color)
    SetBlipAsShortRange(blip, b.shortRange == true)
    if dim then SetBlipAlpha(blip, 110) end

    local name = b.name
    if Blips.showIds and adminActive() then name = ('#%d %s'):format(b.id, name) end
    if dim then name = name .. ' (aus)' end
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(name)
    EndTextCommandSetBlipName(blip)

    h.main = blip
    Blips.handles[b.id] = h
end

function Blips.Current()
    return adminActive() and Blips.all or Blips.list
end

function Blips.Render()
    for id in pairs(Blips.handles) do removeHandles(id) end
    local pos = GetEntityCoords(PlayerPedId())
    for _, b in ipairs(Blips.Current()) do
        if Blips.InRange(b, pos) then draw(b) end
    end
end

-- Entfernung, ab der ein Blip erscheint (0 = immer, ganze Karte)
function Blips.DistanceOf(b)
    return tonumber(b.distance) or Config.Defaults.distance or 0
end

-- Admin-Ansicht zeigt alles, damit man Blips im Menü auch findet
function Blips.InRange(b, pos)
    if adminActive() then return true end
    local d = Blips.DistanceOf(b)
    if d <= 0 then return true end
    return #(pos - vector3(b.x, b.y, b.z)) <= d
end

-- Blips ein-/ausblenden, wenn man näher kommt oder sich entfernt
CreateThread(function()
    while true do
        Wait(1000)
        local pos = GetEntityCoords(PlayerPedId())
        for _, b in ipairs(Blips.Current()) do
            local want = Blips.InRange(b, pos)
            if want and not Blips.handles[b.id] then
                draw(b)
            elseif not want and Blips.handles[b.id] then
                removeHandles(b.id)
            end
        end
    end
end)

-- Volle Liste vom Server holen (nur Team) und neu zeichnen
function Blips.FetchAll()
    Blips.all = TriggerCallback('getAll') or {}
    Blips.Render()
    return Blips.all
end

-- Vorschau eines Blips mit geänderten Werten (nur lokal, bis gespeichert wird)
function Blips.Preview(id, changes)
    for _, b in ipairs(Blips.Current()) do
        if b.id == id then
            local copy = {}
            for k, v in pairs(b) do copy[k] = v end
            for k, v in pairs(changes) do copy[k] = v end
            draw(copy)
            return
        end
    end
end

function Blips.Clear()
    for id in pairs(Blips.handles) do removeHandles(id) end
end

RegisterNetEvent('takeblibs:sync', function(list)
    Blips.list = type(list) == 'table' and list or {}
    if Menu.open or Blips.adminView then
        CreateThread(Blips.FetchAll)
    else
        Blips.Render()
    end
end)
