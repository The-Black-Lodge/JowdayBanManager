---@meta _
---@diagnostic disable

function populateBoons()
    for upgradeName, upgradeData in pairs(game.LootData) do
        if upgradeData.GodLoot == true and upgradeData.PriorityUpgrades ~= nil and upgradeData.Traits ~= nil then
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
                elseif game.TraitData[v].RarityLevels.Legendary ~= nil then
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
    ActiveBoons = game.DeepCopyTable(Save[name].ActiveBoons)
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
    elseif name == 'Demeter' then
        inGameColor = game.Color.DemeterDamage
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
    end
    color[1] = inGameColor[1] / 255
    color[2] = inGameColor[2] / 255
    color[3] = inGameColor[3] / 255
    color[4] = inGameColor[4] / 255
    return color
end
