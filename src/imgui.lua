---@meta _
---@diagnostic disable

rom.gui.add_imgui(function()
    if rom.ImGui.Begin("BanManager") then
        processBans()
        drawMenu()
        rom.ImGui.End()
    end
end)

rom.gui.add_to_menu_bar(function()
    if rom.ImGui.BeginMenu("Configure") then
        processBans()
        drawMenu()
        rom.ImGui.EndMenu()
    end
end)

function drawMenu()
    local godKeys = {}
    for key, _ in pairs(Gods) do
        table.insert(godKeys, key)
    end
    table.sort(godKeys)

    local godNames = {}
    for name, _ in pairs(ActiveBoons) do
        table.insert(godNames, name)
    end
    table.sort(godNames)

    for _, key in pairs(godKeys) do
        local data = Gods[key]
        local godName = data.Name
        local numBoons = #data.Boons or 0
        local numTrue = 0
        for _, value in pairs(ActiveBoons[godName]) do
            if value == true then numTrue = numTrue + 1 end
        end
        local headerText = godName .. ' ' .. numTrue .. '/' .. numBoons

        local color = getColor(godName)
        rom.ImGui.PushStyleColor(rom.ImGuiCol.Header, color[1], color[2], color[3], 0.2)
        rom.ImGui.PushStyleColor(rom.ImGuiCol.HeaderHovered, color[1], color[2], color[3], 0.5)
        rom.ImGui.PushStyleColor(rom.ImGuiCol.HeaderActive, color[1], color[2], color[3], 0.7)
        local open, notCollapsed = rom.ImGui.CollapsingHeader(headerText .. '###' .. godName)
        rom.ImGui.PopStyleColor(3)
        if open == true then
            for boon, info in pairs(data.Boons) do
                local isActive = ActiveBoons[godName][info.Key]
                if not isActive then rom.ImGui.PushStyleColor(rom.ImGuiCol.Text, 0.75, 0, 0, 1) end
                local value, checked = rom.ImGui.Checkbox(info.Name, isActive)
                if info.Duo ~= nil then
                    rom.ImGui.SameLine()
                    rom.ImGui.TextColored(0.82, 1, 0.38, 1, '(D)')
                elseif info.Legendary ~= nil then
                    rom.ImGui.SameLine()
                    rom.ImGui.TextColored(1, 0.56, 0, 1, '(L)')
                elseif info.Elemental ~= nil then
                    rom.ImGui.SameLine()
                    rom.ImGui.TextColored(1, 0.29, 1, 1, '(I)')
                end
                if not isActive then rom.ImGui.PopStyleColor() end
                if checked then
                    if value == true then
                        game.CurrentRun.BannedTraits[info.Key] = nil
                    else
                        game.CurrentRun.BannedTraits[info.Key] = true
                    end
                    ActiveBoons[godName][info.Key] = value
                end
            end
            rom.ImGui.PushStyleColor(rom.ImGuiCol.Button, color[1], color[2], color[3], 0.2)
            rom.ImGui.PushStyleColor(rom.ImGuiCol.ButtonHovered, color[1], color[2], color[3], 0.5)
            rom.ImGui.PushStyleColor(rom.ImGuiCol.ButtonActive, color[1], color[2], color[3], 0.7)
            local reset = rom.ImGui.Button("Reset " .. godName)
            rom.ImGui.PopStyleColor(3)
            if reset then
                resetBan(godName)
            end
        end
    end
    rom.ImGui.Spacing()
    local reset = rom.ImGui.Button("Reset All Bans")
    if reset then
        resetAllBans()
    end

    rom.ImGui.Spacing()
    rom.ImGui.Separator()
    rom.ImGui.Text("Profiles")

    value, pressed = rom.ImGui.RadioButton("Profile1##radio", SelectedSave, 1)
    if pressed then
        SelectedSave = value
    end
    value, pressed = rom.ImGui.RadioButton("Profile2##radio", SelectedSave, 2)
    if pressed then
        SelectedSave = value
    end
    value, pressed = rom.ImGui.RadioButton("Profile3##radio", SelectedSave, 3)
    if pressed then
        SelectedSave = value
    end

    local save = rom.ImGui.Button("Save Profile" .. SelectedSave .. "##save")


    if save then
        -- until inputs work, hard-code the save name
        saveLoadout('Profile' .. SelectedSave)
    end

    if Save ~= nil then
        rom.ImGui.Spacing()

        local saveKeys = {}
        for key in pairs(Save) do
            table.insert(saveKeys, key)
        end
        table.sort(saveKeys)

        rom.ImGui.Separator()

        rom.ImGui.Text("Saved Profiles")
        local saveCount = 0
        for _, name in pairs(saveKeys) do
            saveCount = saveCount + 1
            if rom.ImGui.CollapsingHeader(name) then
                local boonList = Save[name]
                local count = 0
                rom.ImGui.Text("Ban List")
                for _, godName in pairs(godNames) do
                    local data = boonList[godName]
                    for boon, active in pairs(data) do
                        if active == false then
                            local boonName = BoonData[boon].Name
                            local color = BoonData[boon].Color
                            rom.ImGui.PushStyleColor(rom.ImGuiCol.Text, color[1], color[2], color[3], color[4])
                            rom.ImGui.BulletText(godName .. ' > ' .. boonName)
                            rom.ImGui.PopStyleColor()
                            count = count + 1
                        end
                    end
                end
                rom.ImGui.Text(tostring(count) .. ' ban(s)')

                local load = rom.ImGui.Button("Load " .. name)

                if load then
                    loadLoadout(name)
                end

                rom.ImGui.SameLine()

                rom.ImGui.PushStyleColor(rom.ImGuiCol.Button, 0.35, 0, 0, 1)
                rom.ImGui.PushStyleColor(rom.ImGuiCol.ButtonHovered, 0.45, 0, 0, 1)
                rom.ImGui.PushStyleColor(rom.ImGuiCol.ButtonActive, 0.65, 0, 0, 1)
                local delete = rom.ImGui.Button("Delete " .. name)
                rom.ImGui.PopStyleColor(3)

                if delete then
                    deleteLoadout(name)
                end
            end
        end
        if saveCount == 0 then
            rom.ImGui.Text("No saved profiles. Try creating one!")
        end
    end
end
