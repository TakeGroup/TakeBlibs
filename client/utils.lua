Perms = { level = 0, perms = {}, esx = false }

function Can(perm)
    return Perms.perms[perm] == true
end

-- ---------------------------------------------------------------- Callbacks

local cbId, pending = 0, {}

function TriggerCallback(name, ...)
    cbId = cbId + 1
    local id = cbId
    local p = promise.new()
    pending[id] = p
    TriggerServerEvent('takeblibs:cb:request', name, id, ...)
    SetTimeout(10000, function()
        if pending[id] then
            pending[id] = nil
            p:resolve({ n = 0 })
        end
    end)
    local res = Citizen.Await(p)
    return table.unpack(res, 1, res.n)
end

RegisterNetEvent('takeblibs:cb:response', function(id, ...)
    local p = pending[id]
    if p then
        pending[id] = nil
        p:resolve(table.pack(...))
    end
end)

-- ---------------------------------------------------------------- UI

function Notify(msg, nType)
    SendNUIMessage({ action = 'notify', text = msg, type = nType or 'info' })
end

RegisterNetEvent('takeblibs:notify', function(msg, nType)
    Notify(msg, nType)
end)

function KeyboardInput(title, default, maxLen)
    AddTextEntry('TAKEBLIBS_INPUT', title)
    DisplayOnscreenKeyboard(1, 'TAKEBLIBS_INPUT', '', default or '', '', '', '', maxLen or 128)
    while UpdateOnscreenKeyboard() == 0 do
        DisableAllControlActions(0)
        Wait(0)
    end
    Menu.Cooldown()
    if UpdateOnscreenKeyboard() == 1 then
        local result = GetOnscreenKeyboardResult()
        if result and result ~= '' then return result end
    end
    return nil
end

function TeleportTo(coords, findGround)
    local ped = PlayerPedId()
    local ent = IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) or ped
    DoScreenFadeOut(200)
    while not IsScreenFadedOut() do Wait(0) end

    local x, y, z = coords.x, coords.y, coords.z
    SetEntityCoords(ent, x, y, z, false, false, false, false)
    if findGround then
        for height = 1000.0, 0.0, -25.0 do
            SetEntityCoordsNoOffset(ent, x, y, height, false, false, false)
            RequestCollisionAtCoord(x, y, height)
            Wait(20)
            local found, gz = GetGroundZFor_3dCoord(x, y, height, false)
            if found then
                z = gz + 1.0
                break
            end
        end
        SetEntityCoords(ent, x, y, z, false, false, false, false)
    else
        RequestCollisionAtCoord(x, y, z)
        local t = GetGameTimer() + 2000
        while not HasCollisionLoadedAroundEntity(ent) and GetGameTimer() < t do Wait(0) end
    end
    DoScreenFadeIn(300)
end

function CopyToClipboard(text)
    SendNUIMessage({ action = 'copy', text = text })
    Notify('In Zwischenablage kopiert: ' .. text, 'success')
end
