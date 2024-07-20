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
                writeBoonRarity(info)
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

    if rom.ImGui.CollapsingHeader("Create or Update Profiles") then
        rom.ImGui.TextWrapped("Create a new profile, or load an existing profile to update it here.")
        text, selected = rom.ImGui.InputText("Name##saveName", SaveName, 50)
        if selected then SaveName = text end
        text, selected = rom.ImGui.InputTextMultiline("Description##saveDesc", SaveDesc, 500, 0, 75)
        if selected then SaveDesc = text end

        local saveButtonText = "Create"
        if Save[SaveName] ~= nil then saveButtonText = "Update" end
        saveButtonText = saveButtonText .. " Profile: " .. SaveName .. "##save"
        local save = rom.ImGui.Button(saveButtonText)


        if save then
            -- until inputs work, hard-code the save name
            saveLoadout(SaveName, SaveDesc)
        end
    end

    if Save ~= nil then
        rom.ImGui.Spacing()

        local saveKeys = {}
        for key in pairs(Save) do
            table.insert(saveKeys, tostring(key))
        end
        table.sort(saveKeys)

        rom.ImGui.Text("Saved Profiles")
        local saveCount = 0
        for _, name in pairs(saveKeys) do
            local boonList = Save[name].ActiveBoons
            saveCount = saveCount + 1
            local indent = 38
            if rom.ImGui.CollapsingHeader(tostring(name)) then
                rom.ImGui.TextWrapped(Save[name].Description)
                rom.ImGui.Indent(indent)
                local banCount, allowCount = getBanCounts(tostring(name), godNames)
                rom.ImGui.PushStyleColor(rom.ImGuiCol.Header, 0.09, 0, 0, 1)
                rom.ImGui.PushStyleColor(rom.ImGuiCol.HeaderHovered, 0.18, 0, 0, 1)
                rom.ImGui.PushStyleColor(rom.ImGuiCol.HeaderActive, 0.33, 0, 0, 1)
                if rom.ImGui.CollapsingHeader(banCount .. " banned###ban" .. tostring(name)) then
                    rom.ImGui.Indent(indent)
                    for _, godName in pairs(godNames) do
                        local godColor = GodData[godName].Color
                        rom.ImGui.TextColored(godColor[1], godColor[2], godColor[3], 1, godName)
                        for i, boon in pairs(BoonData[godName]) do
                            if boonList[godName][boon.Key] == false then
                                local boonName = boon.Name
                                rom.ImGui.BulletText(boonName)
                                writeBoonRarity(BoonData[boon.Key])
                            end
                        end
                    end
                    rom.ImGui.Unindent(indent)
                end
                rom.ImGui.PopStyleColor(3)

                rom.ImGui.PushStyleColor(rom.ImGuiCol.Header, 0, 0, 0.09, 1)
                rom.ImGui.PushStyleColor(rom.ImGuiCol.HeaderHovered, 0, 0, 0.18, 1)
                rom.ImGui.PushStyleColor(rom.ImGuiCol.HeaderActive, 0, 0, 0.33, 1)
                if rom.ImGui.CollapsingHeader(allowCount .. " allowed###allow" .. tostring(name)) then
                    rom.ImGui.Indent(indent)
                    for _, godName in pairs(godNames) do
                        local godColor = GodData[godName].Color
                        rom.ImGui.TextColored(godColor[1], godColor[2], godColor[3], 1, godName)
                        for i, boon in pairs(BoonData[godName]) do
                            if boonList[godName][boon.Key] == true then
                                local boonName = boon.Name
                                rom.ImGui.BulletText(boonName)
                                writeBoonRarity(BoonData[boon.Key])
                            end
                        end
                    end
                    rom.ImGui.Unindent(indent)
                end

                rom.ImGui.Unindent(indent)
                rom.ImGui.PopStyleColor(3)

                rom.ImGui.Spacing()

                local load = rom.ImGui.Button("Load " .. name)

                if load then
                    loadLoadout(name)
                end

                rom.ImGui.SameLine()

                x, y = rom.ImGui.GetContentRegionAvail()
                rom.ImGui.SetCursorPosX(rom.ImGui.GetCursorPosX() + x - 60)
                rom.ImGui.PushStyleColor(rom.ImGuiCol.Button, 0.35, 0, 0, 1)
                rom.ImGui.PushStyleColor(rom.ImGuiCol.ButtonHovered, 0.45, 0, 0, 1)
                rom.ImGui.PushStyleColor(rom.ImGuiCol.ButtonActive, 0.65, 0, 0, 1)
                local delete = rom.ImGui.Button("Delete", 60, 0)
                rom.ImGui.PopStyleColor(3)

                if delete then
                    deleteLoadout(name)
                end
            end
            rom.ImGui.Spacing()
        end
        if saveCount == 0 then
            rom.ImGui.Text("No saved profiles. Try creating one!")
        end
    end
end

function writeBoonRarity(info)
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
end
