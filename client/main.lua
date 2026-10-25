local function loadPerms()
    local p = TriggerCallback('getPerms')
    if p then Perms = p end
    return p ~= nil
end

local function openBlipMenu()
    if not loadPerms() then return Notify('Server antwortet nicht.', 'error') end
    if not Can('menu') then return Notify('Du hast keine Berechtigung für das Blip-Menü.', 'error') end
    Menu.Open(MainMenu)
end

-- Menü offen = Admin-Ansicht (alle Blips). Beim Schließen zurück zur normalen Ansicht.
Menu.onOpen = function()
    Blips.FetchAll()
end

Menu.onClose = function()
    if not Blips.adminView then Blips.Render() end
end

RegisterCommand(Config.Command, function()
    CreateThread(function()
        if Menu.open then Menu.Close() else openBlipMenu() end
    end)
end, false)
TriggerEvent('chat:addSuggestion', '/' .. Config.Command, 'Blip-Menü öffnen / schließen')

-- Rechte + Blips beim Start laden
CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do Wait(500) end
    Wait(2000)
    loadPerms()
    SendNUIMessage({ action = 'init', position = Config.MenuPosition, accent = Config.AccentColor })
    TriggerServerEvent('takeblibs:requestSync')
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    Blips.Clear()
end)
