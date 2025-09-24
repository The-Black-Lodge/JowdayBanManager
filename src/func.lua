---@meta _
---@diagnostic disable

function reconcileSavedData(savedActiveBoons)
    local reconciledData = {}
    local changes = {
        missingBoons = {},
        newBoons = {},
        missingGods = {},
        newGods = {}
    }
    
    -- Process each god in the current ActiveBoons structure
    for currentGodName, currentBoons in pairs(ActiveBoons) do
        reconciledData[currentGodName] = {}
        
        -- Check if this god exists in saved data
        local savedBoons = savedActiveBoons[currentGodName]
        if not savedBoons then
            -- New god not in saved data - default all boons to active (not banned)
            for boonKey, _ in pairs(currentBoons) do
                reconciledData[currentGodName][boonKey] = true
                table.insert(changes.newGods, currentGodName)
            end
        else
            -- God exists in saved data - reconcile boons
            for boonKey, _ in pairs(currentBoons) do
                if savedBoons[boonKey] ~= nil then
                    -- Boon exists in both - use saved value
                    reconciledData[currentGodName][boonKey] = savedBoons[boonKey]
                else
                    -- New boon not in saved data - default to active (not banned)
                    reconciledData[currentGodName][boonKey] = true
                    table.insert(changes.newBoons, boonKey)
                end
            end
            
            -- Check for boons that exist in saved data but not in current data
            for savedBoonKey, _ in pairs(savedBoons) do
                if currentBoons[savedBoonKey] == nil then
                    -- Boon no longer exists - log it but don't include in reconciled data
                    table.insert(changes.missingBoons, savedBoonKey)
                end
            end
        end
    end
    
    -- Check for gods that exist in saved data but not in current data
    for savedGodName, _ in pairs(savedActiveBoons) do
        if ActiveBoons[savedGodName] == nil then
            table.insert(changes.missingGods, savedGodName)
        end
    end
    
    return reconciledData, changes
end

function logReconciliationChanges(changes, profileName)
    if #changes.missingBoons > 0 or #changes.newBoons > 0 or #changes.missingGods > 0 or #changes.newGods > 0 then
        print("BanManager: Reconciled profile '" .. profileName .. "'")
        
        if #changes.missingBoons > 0 then
            print("  - Removed " .. #changes.missingBoons .. " boons that no longer exist:")
            for _, boon in ipairs(changes.missingBoons) do
                print("    * " .. boon)
            end
        end
        
        if #changes.newBoons > 0 then
            print("  - Added " .. #changes.newBoons .. " new boons (defaulted to active):")
            for _, boon in ipairs(changes.newBoons) do
                print("    * " .. boon)
            end
        end
        
        if #changes.missingGods > 0 then
            print("  - Removed " .. #changes.missingGods .. " gods that no longer exist:")
            for _, god in ipairs(changes.missingGods) do
                print("    * " .. god)
            end
        end
        
        if #changes.newGods > 0 then
            print("  - Added " .. #changes.newGods .. " new gods (defaulted to active):")
            for _, god in ipairs(changes.newGods) do
                print("    * " .. god)
            end
        end
    end
end

function validateAllSavedProfiles()
    if Save == nil then return end
    
    local totalChanges = 0
    local profilesWithChanges = {}
    
    for profileName, profileData in pairs(Save) do
        if profileData.ActiveBoons then
            local _, changes = reconcileSavedData(profileData.ActiveBoons)
            local hasChanges = #changes.missingBoons > 0 or #changes.newBoons > 0 or #changes.missingGods > 0 or #changes.newGods > 0
            
            if hasChanges then
                totalChanges = totalChanges + 1
                table.insert(profilesWithChanges, profileName)
            end
        end
    end
    
    if totalChanges > 0 then
        print("BanManager: Found " .. totalChanges .. " saved profile(s) that need reconciliation:")
        for _, profileName in ipairs(profilesWithChanges) do
            print("  - " .. profileName)
        end
        print("BanManager: Profiles will be automatically reconciled when loaded.")
    end
end

function populateBoons()
    -- main gods + hermes
    for upgradeName, upgradeData in pairs(game.LootData) do
        if
            (upgradeData.GodLoot == true and
                upgradeData.PriorityUpgrades ~= nil and
                upgradeData.Traits ~= nil) or
            upgradeName == 'HermesUpgrade'
        then
            local godName = game.GetDisplayName({ Text = upgradeName })
            GodData[godName] = { Color = getColor(godName) }
            BoonData[godName] = {}
            ActiveBoons[godName] = {}
            local boons = {}
            for i, v in pairs(upgradeData.PriorityUpgrades) do
                local boon = { Name = game.GetDisplayName({ Text = v }), Key = v, Color = getColor(godName) }
                table.insert(boons, boon)
                ActiveBoons[godName][v] = true
                BoonData[v] = boon
                table.insert(BoonData[godName], boon)
            end
            for i, v in pairs(upgradeData.Traits) do
                local boon = { Key = v, Color = getColor(godName) }
                local boonName = game.GetDisplayName({ Text = v })
                if game.TraitData[v].IsDuoBoon then
                    boon.Duo = true
                elseif game.TraitData[v].IsElementalTrait then
                    boon.Elemental = true
                elseif game.TraitData[v].RarityLevels ~= nil and game.TraitData[v].RarityLevels.Legendary ~= nil then
                    boon.Legendary = true
                end

                boon.Name = boonName

                table.insert(boons, boon)
                ActiveBoons[godName][v] = true
                BoonData[v] = boon
                table.insert(BoonData[godName], boon)
            end

            Gods[upgradeName] = { Name = godName, Boons = boons }
        end
    end

    -- artemis
    local artemisBoons = {}
    ActiveBoons['Artemis'] = {}
    BoonData['Artemis'] = {}
    local artemisColor = getColor('Artemis')
    GodData['Artemis'] = { Color = artemisColor }
    for _, boonKey in ipairs(game.UnitSetData.NPC_Artemis.NPC_Artemis_Field_01.Traits) do
        local boon = {
            Key = boonKey,
            Color = artemisColor,
            Name = game.GetDisplayName({ Text = boonKey })
        }
        table.insert(artemisBoons, boon)
        ActiveBoons['Artemis'][boonKey] = true
        BoonData[boonKey] = boon
        table.insert(BoonData['Artemis'], boon)
    end
    Gods['ArtemisUpgrade'] = { Name = 'Artemis', Boons = artemisBoons }
    
    -- hades
    local hadesBoons = {}
    ActiveBoons['Hades'] = {}
    BoonData['Hades'] = {}
    local hadesColor = getColor('Hades')
    GodData['Hades'] = { Color = hadesColor }
    for _, boonKey in ipairs(game.UnitSetData.NPC_Hades.NPC_Hades_Field_01.Traits) do
        local boon = {
            Key = boonKey,
            Color = hadesColor,
            Name = game.GetDisplayName({ Text = boonKey })
        }
        table.insert(hadesBoons, boon)
        ActiveBoons['Hades'][boonKey] = true
        BoonData[boonKey] = boon
        table.insert(BoonData['Hades'], boon)
    end
    Gods['HadesUpgrade'] = { Name = 'Hades', Boons = hadesBoons }
    
    -- athena
    local athenaBoons = {}
    ActiveBoons['Athena'] = {}
    BoonData['Athena'] = {}
    local athenaColor = getColor('Athena')
    GodData['Athena'] = { Color = athenaColor }
    for _, boonKey in ipairs(game.UnitSetData.NPC_Athena.NPC_Athena_01.Traits) do
        local boon = {
            Key = boonKey,
            Color = athenaColor,
            Name = game.GetDisplayName({ Text = boonKey })
        }
        table.insert(athenaBoons, boon)
        ActiveBoons['Athena'][boonKey] = true
        BoonData[boonKey] = boon
        table.insert(BoonData['Athena'], boon)
    end
    Gods['AthenaUpgrade'] = { Name = 'Athena', Boons = athenaBoons }

    -- dionysus
    local dionysusBoons = {}
    ActiveBoons['Dionysus'] = {}
    BoonData['Dionysus'] = {}
    local dionysusColor = getColor('Dionysus')
    GodData['Dionysus'] = { Color = dionysusColor }
    for _, boonKey in ipairs(game.UnitSetData.NPC_Dionysus.NPC_Dionysus_01.Traits) do
        local boon = {
            Key = boonKey,
            Color = dionysusColor,
            Name = game.GetDisplayName({ Text = boonKey })
        }
        table.insert(dionysusBoons, boon)
        ActiveBoons['Dionysus'][boonKey] = true
        BoonData[boonKey] = boon
        table.insert(BoonData['Dionysus'], boon)
    end
    Gods['DionysusUpgrade'] = { Name = 'Dionysus', Boons = dionysusBoons }
end

function processBans()
    for godName, boons in pairs(ActiveBoons) do
        for boon, active in pairs(boons) do
            if game.CurrentRun.BannedTraits[boon] then
                ActiveBoons[godName][boon] = false
            end
        end
    end
end

function resetBan(godName)
    for key, _ in pairs(ActiveBoons[godName]) do
        game.CurrentRun.BannedTraits[key] = nil
        ActiveBoons[godName][key] = true
    end
end

function resetAllBans()
    game.CurrentRun.BannedTraits = {}
    for godName, vals in pairs(ActiveBoons) do
        for key, _ in pairs(vals) do
            ActiveBoons[godName][key] = true
        end
    end
end

function saveLoadout(name, description)
    local save = {
        Description = description or "",
        ActiveBoons = game.DeepCopyTable(ActiveBoons)
    }

    Save[tostring(name)] = save
    game.SaveCheckpoint({ DevSaveName = game.CreateDevSaveName(game.CurrentRun) })

    SaveName = "Name"
    SaveDesc = "My bans"
end

function loadLoadout(name)
    -- Reconcile saved data with current boon structure
    local reconciledData, changes = reconcileSavedData(Save[name].ActiveBoons)
    
    -- Log any changes that were made during reconciliation
    logReconciliationChanges(changes, name)
    
    -- Use reconciled data instead of raw saved data
    ActiveBoons = reconciledData
    
    -- Apply bans to the game
    game.CurrentRun.BannedTraits = {}
    for godName, vals in pairs(ActiveBoons) do
        for key, active in pairs(vals) do
            if active == false then
                game.CurrentRun.BannedTraits[key] = true
            end
        end
    end

    game.SaveCheckpoint({ DevSaveName = game.CreateDevSaveName(game.CurrentRun) })

    SaveName = name
    SaveDesc = Save[name].Description
end

function deleteLoadout(name)
    Save[name] = nil
    game.SaveCheckpoint({ DevSaveName = game.CreateDevSaveName(game.CurrentRun) })
end

function getBanCounts(name, godNames)
    local boonList = Save[name].ActiveBoons
    local banCount = 0
    local allowCount = 0
    local seenDuoAllow = {}
    local seenDuoBan = {}
    for k, v in pairs(BoonData) do
        if v.Duo then
            seenDuoAllow[k] = false
            seenDuoBan[k] = false
        end
    end
    for _, godName in pairs(godNames) do
        for boon, active in pairs(boonList[godName]) do
            if active == true and (seenDuoAllow[boon] == nil or seenDuoAllow[boon] == false) then
                allowCount = allowCount + 1
                seenDuoAllow[boon] = true
            end
            if active == false and (seenDuoBan[boon] == nil or seenDuoBan[boon] == false) then
                banCount = banCount + 1
                seenDuoBan[boon] = true
            end
        end
    end
    return banCount, allowCount
end

-- this is just so it'll match with the colors i picked for dps meter
function getColor(name)
    local color = {}
    local inGameColor = game.Color.Black
    if name == 'Aphrodite' then
        inGameColor = game.Color.AphroditeDamage
    elseif name == 'Apollo' then
        inGameColor = game.Color.ApolloDamageLight
    elseif name == 'Ares' then
        inGameColor = game.Color.AresDamageLight
    elseif name == 'Athena' then
        inGameColor = game.Color.AthenaDamageLight
    elseif name == 'Demeter' then
        inGameColor = game.Color.DemeterDamage
    elseif name == 'Dionysus' then
        inGameColor = game.Color.DionysusDamage
    elseif name == 'Hera' then
        inGameColor = game.Color.HeraDamage
    elseif name == 'Hestia' then
        inGameColor = game.Color.HestiaDamageLight
    elseif name == 'Hephaestus' then
        inGameColor = game.Color.HephaestusDamage
    elseif name == 'Poseidon' then
        inGameColor = game.Color.PoseidonDamage
    elseif name == 'Zeus' then
        inGameColor = game.Color.ZeusDamageLight
    elseif name == 'Hermes' then
        inGameColor = game.Color.HermesVoice
    elseif name == 'Artemis' then
        inGameColor = game.Color.ArtemisDamage
    elseif name == 'Hades' then
        inGameColor = game.Color.HadesVoice
    end
    color[1] = inGameColor[1] / 255
    color[2] = inGameColor[2] / 255
    color[3] = inGameColor[3] / 255
    color[4] = inGameColor[4] / 255
    return color
end
