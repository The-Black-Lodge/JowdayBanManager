---@meta _
---@diagnostic disable

---@diagnostic disable-next-line: undefined-global
local mods = rom.mods

---@module 'SGG_Modding-ENVY-auto'
mods['SGG_Modding-ENVY'].auto()

---@diagnostic disable: lowercase-global

---@diagnostic disable-next-line: undefined-global
rom = rom
---@diagnostic disable-next-line: undefined-global
_PLUGIN = PLUGIN

---@module 'SGG_Modding-Hades2GameDef-Globals'
game = rom.game

---@module 'SGG_Modding-ModUtil'
modutil = mods['SGG_Modding-ModUtil']

---@module 'SGG_Modding-Chalk'
chalk = mods["SGG_Modding-Chalk"]
---@module 'SGG_Modding-ReLoad'
reload = mods['SGG_Modding-ReLoad']

---@module 'config'
config = chalk.auto()
public.config = config

local function on_ready()
    if config.enabled == false then return end

    Gods = {}
    ActiveBoons = {}
    for upgradeName, upgradeData in pairs(game.LootData) do
        if upgradeData.GodLoot == true and upgradeData.PriorityUpgrades ~= nil and upgradeData.Traits ~= nil then
            local godName = game.GetDisplayName({ Text = upgradeName })
            ActiveBoons[godName] = {}
            local boons = {}
            for i, v in pairs(upgradeData.PriorityUpgrades) do
                local boon = { Name = game.GetDisplayName({ Text = v }), Key = v }
                table.insert(boons, boon)
                ActiveBoons[godName][v] = true
            end
            for i, v in pairs(upgradeData.Traits) do
                local boon = { Name = game.GetDisplayName({ Text = v }), Key = v }
                table.insert(boons, boon)
                ActiveBoons[godName][v] = true
            end

            Gods[upgradeName] = { Name = godName, Boons = boons }
        end
    end
end

local function on_reload()
    import 'imgui.lua'
end


local loader = reload.auto_single()

modutil.once_loaded.game(function()
    loader.load(on_ready, on_reload)
end)
