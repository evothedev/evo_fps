local isMenuOpen = false

-- Store states for continuous loops (0.0 to 100.0)
local activeSettings = {
    traffic = 100.0,
    peds = 100.0,
    lod = 100.0
}

-- Command to open the menu
RegisterCommand('fps', function()
    ToggleMenu(not isMenuOpen)
end, false)

function ToggleMenu(state)
    isMenuOpen = state
    SetNuiFocus(state, state)
    SendNUIMessage({
        action = state and "open" or "close"
    })
end

-- Density & LOD Loop
-- Must run every frame when values are less than standard
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        -- Apply traffic density
        if activeSettings.traffic < 100.0 then
            local trafficMult = activeSettings.traffic / 100.0
            SetRandomVehicleDensityMultiplierThisFrame(trafficMult)
            SetParkedVehicleDensityMultiplierThisFrame(trafficMult)
            SetVehicleDensityMultiplierThisFrame(trafficMult)
        end
        
        -- Apply ped density
        if activeSettings.peds < 100.0 then
            local pedsMult = activeSettings.peds / 100.0
            SetPedDensityMultiplierThisFrame(pedsMult)
            SetScenarioPedDensityMultiplierThisFrame(pedsMult, pedsMult)
        end

        -- Apply Level of Detail (Render Distance)
        if activeSettings.lod < 100.0 then
            OverrideLodscaleThisFrame(activeSettings.lod / 100.0)
        end
    end
end)

-- NUI Callback to close the menu
RegisterNUICallback('closeMenu', function(_, cb)
    ToggleMenu(false)
    cb('ok')
end)

-- NUI Callback to apply Presets
RegisterNUICallback('applyPreset', function(data, cb)
    local level = data.level
    
    -- Reset to base before applying new
    ClearTimecycleModifier()
    ClearExtraTimecycleModifier()

    if level == "cinematic" or level == "default" then
        CascadeShadowsSetCascadeBoundsScale(1.0)
        CascadeShadowsSetDynamicDepthMode(true)
        CascadeShadowsSetEntityTrackerScale(1.0)
        SetFlashLightFadeDistance(10.0)
        SetLightsCutoffDistanceTweak(10.0)
        
        -- Reset sliders globally
        activeSettings.traffic = 100.0
        activeSettings.peds = 100.0
        activeSettings.lod = 100.0
        
    elseif level == "performance" then
        SetTimecycleModifier('yell_tunnel_nodir')
        CascadeShadowsSetCascadeBoundsScale(0.5)
        CascadeShadowsSetDynamicDepthMode(false)
        CascadeShadowsSetEntityTrackerScale(0.5)
        SetFlashLightFadeDistance(5.0)
        SetLightsCutoffDistanceTweak(5.0)
        
        activeSettings.traffic = 50.0
        activeSettings.peds = 50.0
        activeSettings.lod = 50.0
        
    elseif level == "potato" then
        SetTimecycleModifier('yell_tunnel_nodir')
        SetExtraTimecycleModifier('tunnel')
        CascadeShadowsSetCascadeBoundsScale(0.0)
        CascadeShadowsSetDynamicDepthMode(false)
        CascadeShadowsSetEntityTrackerScale(0.0)
        SetFlashLightFadeDistance(0.0)
        SetLightsCutoffDistanceTweak(0.0)
        
        activeSettings.traffic = 0.0
        activeSettings.peds = 0.0
        activeSettings.lod = 0.0
    end

    cb('ok')
end)

-- NUI Callback for boolean Toggles
RegisterNUICallback('toggleSetting', function(data, cb)
    local setting = data.setting
    local state = data.state

    if setting == "shadows" then
        if state then
            CascadeShadowsSetCascadeBoundsScale(1.0)
            CascadeShadowsSetDynamicDepthMode(true)
        else
            CascadeShadowsSetCascadeBoundsScale(0.0)
            CascadeShadowsSetDynamicDepthMode(false)
        end
    elseif setting == "lights" then
        if state then
            SetLightsCutoffDistanceTweak(10.0)
            SetFlashLightFadeDistance(10.0)
        else
            SetLightsCutoffDistanceTweak(0.0)
            SetFlashLightFadeDistance(0.0)
        end
    elseif setting == "water" then
        -- Uses a tunnel timecycle mod to kill rendering of advanced water reflections
        if state then
            ClearExtraTimecycleModifier()
        else
            SetExtraTimecycleModifier('tunnel') 
        end
    elseif setting == "fog" then
        if state then
            ClearWeatherTypePersist()
        else
            -- Forces clear skies to remove volumetric fog overhead
            SetWeatherTypePersist('EXTRASUNNY')
            SetWeatherTypeNowPersist('EXTRASUNNY')
            SetWeatherTypeNow('EXTRASUNNY')
            SetOverrideWeather('EXTRASUNNY')
        end
    end

    cb('ok')
end)

-- NUI Callback for continuous Sliders
RegisterNUICallback('updateSlider', function(data, cb)
    local setting = data.setting
    local value = tonumber(data.value) + 0.0 -- Ensure it's a float

    if setting == "traffic" then
        activeSettings.traffic = value
    elseif setting == "peds" then
        activeSettings.peds = value
    elseif setting == "lod" then
        activeSettings.lod = value
    end

    cb('ok')
end)

-- NUI Callback to clear memory / decals
RegisterNUICallback('clearVram', function(_, cb)
    ClearAllBrokenGlass()
    ClearAllHelpMessages()
    LeaderboardsReadClearAll()
    ClearBrief()
    ClearGpsFlags()
    ClearPrints()
    ClearSmallPrints()
    ClearReplayStats()
    LeaderboardsClearCacheData()
    ClearFocus()
    ClearHdArea()
    
    local ped = PlayerPedId()
    ClearPedBloodDamage(ped)
    ClearPedWetness(ped)
    ClearPedEnvDirt(ped)
    ResetPedVisibleDamage(ped)
    
    cb('ok')
end)

-- NUI Callback to Wipe Entities
RegisterNUICallback('wipeEntities', function(_, cb)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    -- Clears all un-networked or abandoned entities in a 100m radius
    ClearAreaOfVehicles(coords.x, coords.y, coords.z, 100.0, false, false, false, false, false)
    ClearAreaOfPeds(coords.x, coords.y, coords.z, 100.0, 1)
    ClearAreaOfObjects(coords.x, coords.y, coords.z, 100.0, 0)
    ClearAreaOfCops(coords.x, coords.y, coords.z, 100.0, 0)
    
    cb('ok')
end)

-- NUI Callback to Fix Invisible Players
RegisterNUICallback('fixPlayers', function(_, cb)
    -- Forces a visual sync and clears glitched tasks
    local ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    
    -- Network sync placebo trigger
    NetworkOverrideClockTime(GetClockHours(), GetClockMinutes(), GetClockSeconds())
    
    cb('ok')
end)