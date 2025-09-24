---@meta _
---@diagnostic disable

local mods = rom.mods

---@module 'SGG_Modding-ENVY-auto'
mods['SGG_Modding-ENVY'].auto()

rom = rom

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
    GodData = {}
    ActiveBoons = {}
    BoonData = {}
    Save = {}
    SaveName = "Name"
    SaveDesc = "My bans"

    game.OnAnyLoad {function()
        processBans()
    end}
end

local function on_reload()
    import 'func.lua'
    import 'imgui.lua'

    populateBoons()
end

local loader = reload.auto_single()

modutil.once_loaded.game(function()
    loader.load(on_ready, on_reload)
end)

modutil.once_loaded.save(function()
    if config.enabled == false then return end

    processBans()

    local namespace = _PLUGIN.guid
    if modutil.mod.Mod.Data[namespace] == nil then
        modutil.mod.Mod.Data[namespace] = {}
    end

    Save = modutil.mod.Mod.Data[namespace]
    
    -- Validate all saved profiles for compatibility issues
    validateAllSavedProfiles()
end)
