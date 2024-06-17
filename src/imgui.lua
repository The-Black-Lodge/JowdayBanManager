---@meta _
---@diagnostic disable

rom.gui.add_imgui(function()
    if rom.ImGui.Begin("BanManager") then
        drawMenu()
        rom.ImGui.End()
    end
end)

rom.gui.add_to_menu_bar(function()
    if rom.ImGui.BeginMenu("Configure") then
        drawMenu()
        rom.ImGui.EndMenu()
    end
end)

function drawMenu()
    for god, data in pairs(Gods) do
        local godName = data.Name
        local numBoons = #data.Boons or 0
        local numTrue = 0
        for _, value in pairs(ActiveBoons[godName]) do
            if value == true then numTrue = numTrue + 1 end
        end
        local headerText = godName .. ' ' .. numTrue .. '/' .. numBoons
        local open, notCollapsed = rom.ImGui.CollapsingHeader(headerText)
        if open == true then
            for boon, info in pairs(data.Boons) do
                local isActive = ActiveBoons[godName][info.Key]
                if not isActive then rom.ImGui.PushStyleColor(rom.ImGuiCol.Text, 0.75, 0, 0, 1) end
                local value, checked = rom.ImGui.Checkbox(info.Name, isActive)
                if not isActive then rom.ImGui.PopStyleColor() end
                if checked then
                    ActiveBoons[godName][info.Key] = value
                    if value == true then
                        print('unban ' .. info.Key)
                        table.insert(game.CurrentRun.BannedTraits, info.Key)
                    else
                        print('ban ' .. info.Key)
                    end
                end
            end
            local reset = rom.ImGui.Button("Reset " .. godName)
            if reset then
                print('unban all ' .. godName)
                for key, _ in pairs(ActiveBoons[godName]) do
                    ActiveBoons[godName][key] = true
                end
            end
        end
    end

    local reset = rom.ImGui.Button("Reset All Bans")
    if reset then
        game.CurrentRun.BannedTraits = {}
        for godName, vals in pairs(ActiveBoons) do
            for key, _ in pairs(vals) do
                ActiveBoons[godName][key] = true
            end
        end
    end
end
