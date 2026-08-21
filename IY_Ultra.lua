-- Inf Yield Ultra: Infinite Yield + A-Z Command GUI (WindUI version)
-- Loads Infinite Yield and builds an A-Z command center using WindUI - Made By LCP Apart of the Oaken Team.

local Players = game:GetService("Players")
local TS = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer

-- ================= File Logging =================
local LOG_FILE = "IY_Ultra_Log.txt"
local function log(msg)
    local line = "[" .. os.date("%H:%M:%S") .. "] " .. msg
    print(line)
    pcall(function()
        appendfile(LOG_FILE, line .. "\n")
    end)
end
local function warnLog(msg)
    local line = "[" .. os.date("%H:%M:%S") .. "] WARNING: " .. msg
    warn(line)
    pcall(function()
        appendfile(LOG_FILE, line .. "\n")
    end)
end

-- ================= GUI Protection (our own UIs) =================
local protectedGuis = {}

local function protectGui(gui)
    if typeof(gui) == "Instance" then protectedGuis[gui] = true end
end

local function isProtected(inst)
    local cur = inst
    while cur do
        if protectedGuis[cur] then return true end
        cur = cur.Parent
    end
    return false
end

-- ================= Splash =================

task.spawn(function()
    local parentGui = CoreGui
    if type(gethui) == "function" then
        local ok, h = pcall(gethui)
        if ok and typeof(h) == "Instance" then parentGui = h end
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "LCPSplash"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999

    local label = Instance.new("TextLabel")
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.Position = UDim2.new(0.5, 0, 0.5, -20)
    label.Size = UDim2.new(1, 0, 0, 90)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBlack
    label.Text = "Made By LCP"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.TextStrokeTransparency = 0
    label.TextScaled = false
    label.TextSize = 72
    label.Parent = gui

    local subLabel = Instance.new("TextLabel")
    subLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    subLabel.Position = UDim2.new(0.5, 0, 0.5, 38)
    subLabel.Size = UDim2.new(1, 0, 0, 34)
    subLabel.BackgroundTransparency = 1
    subLabel.Font = Enum.Font.Gotham
    subLabel.Text = "Apart of the Oaken Team"
    subLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
    subLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    subLabel.TextStrokeTransparency = 0
    subLabel.TextSize = 26
    subLabel.Parent = gui

    protectGui(gui)
    gui.Parent = parentGui

    task.wait(2)
    TS:Create(label, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
    TS:Create(subLabel, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
    task.wait(0.5)
    gui:Destroy()
end)

local function getenv()
    if type(getgenv) == "function" then return getgenv() end
    return _G
end

local function httpGet(url)
    if type(syn) == "table" and type(syn.request) == "function" then
        return syn.request({ Url = url, Method = "GET" }).Body
    end
    if type(request) == "function" then
        return request({ Url = url, Method = "GET" }).Body
    end
    if type(http_request) == "function" then
        return http_request({ Url = url, Method = "GET" }).Body
    end
    if type(game) == "userdata" then
        return game:HttpGet(url, true)
    end
    return nil
end

-- ================= IY UI Suppression =================
-- Recent IY versions randomize their ScreenGui name to dodge detection.
-- Strategy: snapshot containers before IY's loadstring runs, diff after.
-- Any NEW ScreenGui = IY's UI, no matter what it's named.

local iyTrackedGuis = {}

-- Roblox's own CoreGui ScreenGuis must never be touched
local ROBLOX_COREGUI_NAMES = {
    ["DevConsoleMaster"] = true,
    ["RobloxGui"] = true,
}

local function getContainers()
    local containers = {}
    if type(get_hidden_gui) == "function" then
        local ok, h = pcall(get_hidden_gui)
        if ok and typeof(h) == "Instance" then table.insert(containers, h) end
    end
    if type(gethui) == "function" then
        local ok, h = pcall(gethui)
        if ok and typeof(h) == "Instance" then table.insert(containers, h) end
    end
    table.insert(containers, CoreGui)
    if LP then
        local pg = LP:FindFirstChild("PlayerGui")
        if pg then table.insert(containers, pg) end
    end
    return containers
end

local function suppressGui(gui, reason)
    if typeof(gui) ~= "Instance" or not gui:IsA("ScreenGui") then return end
    if isProtected(gui) then return end
    if ROBLOX_COREGUI_NAMES[gui.Name] then return end
    iyTrackedGuis[gui] = true
    -- ScreenGui has NO .Visible property — only .Enabled
    local ok, enabled = pcall(function() return gui.Enabled end)
    if ok and enabled then
        pcall(function() gui.Enabled = false end)
        warnLog("[IY GUI] Suppressed '" .. gui.Name .. "' (" .. reason .. ")")
    end
end

local reenableLogs = 0
local function hideTracked()
    for gui in pairs(iyTrackedGuis) do
        pcall(function()
            if typeof(gui) == "Instance" and gui.Parent then
                if gui.Enabled then
                    gui.Enabled = false
                    if reenableLogs < 3 then
                        reenableLogs = reenableLogs + 1
                        warnLog("[IY GUI] '" .. tostring(gui.Name) .. "' was RE-ENABLED by someone:\n" .. debug.traceback())
                    end
                end
            else
                iyTrackedGuis[gui] = nil
            end
        end)
    end
end

-- Content-based: find IY's panel via its CMDs ScrollingFrame regardless of naming
local function contentSweep()
    for _, cont in ipairs(getContainers()) do
        local okFind, cmds = pcall(function()
            return cont:FindFirstChild("CMDs", true)
        end)
        if okFind and cmds and cmds:IsA("GuiObject") then
            local root = cmds
            while root.Parent and root.Parent:IsA("GuiObject") do root = root.Parent end
            if root:IsA("ScreenGui") then
                suppressGui(root, "content:CMDs")
            end
        end
    end
end

-- Name-based sweep (cheap extra layer)
local IY_SCREEN_GUI_NAMES = {
    "IY",
    "InfiniteYield",
    "Infinite Yield",
    "InfiniteYieldGUI",
    "Infinite Yield GUI",
    "InfiniteYieldMain",
    "InfiniteYieldUI",
    "IY_UI",
    "IY_Main",
}

local function nameSweep()
    for _, cont in ipairs(getContainers()) do
        for _, gui in ipairs(cont:GetChildren()) do
            if gui:IsA("ScreenGui") then
                local lower = gui.Name:lower()
                for _, n in ipairs(IY_SCREEN_GUI_NAMES) do
                    if lower:find(n:lower(), 1, true) then
                        suppressGui(gui, "name:" .. n)
                        break
                    end
                end
            end
        end
    end
end

local function startIyWatch()
    task.spawn(function()
        while LP and LP.Parent do
            RunService.Heartbeat:Wait()
            pcall(hideTracked)
        end
    end)
    task.spawn(function()
        while LP and LP.Parent do
            task.wait(0.5)
            pcall(nameSweep)
            pcall(contentSweep)
            pcall(hideTracked)
        end
    end)
    warnLog("[IY GUI] IY UI watch active (every frame + 0.5s sweeps)")
end

-- Snapshot helpers for whitelisting our own/WindUI's guis
local function snapshotSets()
    local sets = {}
    for _, cont in ipairs(getContainers()) do
        local set = {}
        for _, c in ipairs(cont:GetChildren()) do set[c] = true end
        sets[cont] = set
    end
    return sets
end

local function protectNewSince(sets)
    for cont, b in pairs(sets) do
        if typeof(cont) == "Instance" then
            for _, c in ipairs(cont:GetChildren()) do
                if c:IsA("ScreenGui") and not b[c] then protectGui(c) end
            end
        end
    end
end

-- Event-driven catch-all: any new ScreenGui in CoreGui-type containers gets
-- suppressed instantly, regardless of name or contents.
local childWatchArmed = false
local function armChildAddedWatch()
    if childWatchArmed then return end
    childWatchArmed = true
    local pg = LP and LP:FindFirstChild("PlayerGui")
    for _, cont in ipairs(getContainers()) do
        if cont ~= pg then
            pcall(function()
                cont.ChildAdded:Connect(function(child)
                    task.defer(function()
                        if typeof(child) == "Instance" and child:IsA("ScreenGui") then
                            warnLog("[IY GUI] New ScreenGui appeared: '" .. child.Name .. "' in " .. cont.Name)
                            suppressGui(child, "childadded")
                        end
                    end)
                end)
            end)
        end
    end
    warnLog("[IY GUI] ChildAdded watchdog armed")
end

-- Ground-truth reporter: logs any non-ours ENABLED ScreenGui every 5s
task.spawn(function()
    while LP and LP.Parent do
        task.wait(5)
        pcall(function()
            local vis = {}
            for _, cont in ipairs(getContainers()) do
                for _, c in ipairs(cont:GetChildren()) do
                    if c:IsA("ScreenGui") and c.Enabled and not isProtected(c) and not ROBLOX_COREGUI_NAMES[c.Name] then
                        vis[#vis + 1] = cont.Name .. "/" .. c.Name
                    end
                end
            end
            if #vis > 0 then
                warnLog("[IY GUI] STILL VISIBLE: " .. table.concat(vis, ", "))
            end
        end)
    end
end)

-- Startup inventory so we can SEE what's actually there (goes to log file)
task.spawn(function()
    task.wait(3)
    local names = {}
    for _, cont in ipairs(getContainers()) do
        for _, c in ipairs(cont:GetChildren()) do
            if c:IsA("ScreenGui") then names[#names + 1] = cont.Name .. "/" .. c.Name end
        end
    end
    log("[IY GUI] ScreenGui inventory: " .. (#names > 0 and table.concat(names, ", ") or "(none)"))
end)

local function loadIY()
    local env = getenv()
    if env.cmds and env.execCmd then return true end
    local ok, src = pcall(httpGet, "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source")
    if ok and type(src) == "string" and #src > 100 then
        -- Snapshot BEFORE running IY's code
        local before = snapshotSets()
        local fn = loadstring(src)
        if fn then
            local ok2 = pcall(fn)
            -- Diff AFTER: any new ScreenGui is IY's UI (random name or not)
            for cont, b in pairs(before) do
                if typeof(cont) == "Instance" then
                    for _, c in ipairs(cont:GetChildren()) do
                        if c:IsA("ScreenGui") and not b[c] and not isProtected(c) then
                            warnLog("[IY GUI] Diff caught new ScreenGui '" .. c.Name .. "' in " .. cont.Name)
                            suppressGui(c, "snapshot-diff")
                        end
                    end
                end
            end
            hideTracked()
            return ok2 and getenv().cmds ~= nil
        end
    end
    return false
end

task.spawn(function()
    while not loadIY() do task.wait(1) end
    log("[IY GUI] Infinite Yield loaded — suppressing original UI")
    nameSweep()
    contentSweep()
    hideTracked()
    startIyWatch()
end)

-- ================= Command Tables =================

local NUMERIC = {
    { name = "speed",          aliases = { "ws", "walkspeed" },      min = 0,     max = 500,     def = 16,     step = 1     },
    { name = "jumppower",      aliases = { "jpower", "jp" },         min = 0,     max = 500,     def = 50,     step = 1     },
    { name = "spoofspeed",     aliases = { "spoofws" },              min = 0,     max = 500,     def = 16,     step = 1     },
    { name = "loopspeed",      aliases = { "loopws" },               min = 0,     max = 500,     def = 16,     step = 1     },
    { name = "spoofjumppower", aliases = { "spoofjp" },              min = 0,     max = 500,     def = 50,     step = 1     },
    { name = "loopjumppower",  aliases = { "loopjp" },               min = 0,     max = 500,     def = 50,     step = 1     },
    { name = "flyspeed",       aliases = {},                         min = 0,     max = 500,     def = 20,     step = 1     },
    { name = "vflyspeed",      aliases = {},                         min = 0,     max = 500,     def = 20,     step = 1     },
    { name = "cframeflyspeed", aliases = { "cflyspeed" },            min = 0,     max = 500,     def = 50,     step = 1     },
    { name = "freecamspeed",   aliases = { "fcspeed" },              min = 1,     max = 50,      def = 1,      step = 1     },
    { name = "maxzoom",        aliases = {},                         min = 1,     max = 180,     def = 70,     step = 1     },
    { name = "minzoom",        aliases = {},                         min = 1,     max = 70,      def = 1,      step = 1     },
    { name = "camdistance",    aliases = {},                         min = 0,     max = 200,     def = 8,      step = 1     },
    { name = "fov",            aliases = {},                         min = 1,     max = 180,     def = 70,     step = 1     },
    { name = "animspeed",      aliases = {},                         min = 1,     max = 10,      def = 1,      step = 1     },
    { name = "headsize",       aliases = {},                         min = 1,     max = 10,      def = 1,      step = 1     },
    { name = "hipheight",      aliases = { "hheight" },              min = 0,     max = 10,      def = 2,      step = 1     },
    { name = "gravity",        aliases = { "grav" },                 min = 0,     max = 1000,    def = 196,    step = 1     },
    { name = "volume",         aliases = { "vol" },                  min = 0,     max = 10,      def = 5,      step = 1     },
    { name = "guiscale",       aliases = {},                         min = 1,     max = 2,       def = 1,      step = 1     },
    { name = "datalimit",      aliases = {},                         min = 1,     max = 100000,  def = 10000,  step = 100   },
    { name = "brightness",     aliases = {},                         min = 0,     max = 5,       def = 1,      step = 1     },
    { name = "destroyheight",  aliases = { "dh" },                   min = 0,     max = 10000,   def = 500,    step = 100   },
    { name = "reach",          aliases = {},                         min = 0,     max = 50,      def = 5,      step = 1     },
    { name = "boxreach",       aliases = {},                         min = 0,     max = 50,      def = 5,      step = 1     },
    { name = "spamspeed",      aliases = {},                         min = 1,     max = 10,      def = 1,      step = 1     },
    { name = "tweenspeed",     aliases = { "tspeed" },               min = 1,     max = 10,      def = 1,      step = 1     },
    { name = "thru",           aliases = {},                         min = 0,     max = 1000,    def = 10,     step = 1     },
    { name = "dupetools",      aliases = { "clonetools" },           min = 1,     max = 100,     def = 1,      step = 1     },
}

local TOGGLES = {
    { on = "2022materials", off = "un2022materials" },
    { on = "alignmentkeys", off = "unalignmentkeys" },
    { on = "allowcustomanim", off = "unallowcustomanim" },
    { on = "anchor", off = "unanchor" },
    { on = "antifling", off = "unantifling" },
    { on = "antigameplaypaused", off = "unantigameplaypaused" },
    { on = "antivoid", off = "unantivoid" },
    { on = "autoclick", off = "unautoclick" },
    { on = "autojump", off = "unautojump" },
    { on = "autokeypress", off = "unautokeypress" },
    { on = "bang", off = "unbang" },
    { on = "bubblechat", off = "unbubblechat" },
    { on = "carpet", off = "uncarpet" },
    { on = "cframefly", off = "uncframefly" },
    { on = "chams", off = "nochams" },
    { on = "chatwindow", off = "unchatwindow" },
    { on = "ctrllock", off = "unctrllock" },
    { on = "dance", off = "undance" },
    { on = "edgejump", off = "unedgejump" },
    { on = "equiptools", off = "unequiptools" },
    { on = "esp", off = "noesp" },
    { on = "fling", off = "unfling" },
    { on = "float", off = "unfloat" },
    { on = "fly", off = "unfly" },
    { on = "flyfling", off = "unflyfling" },
    { on = "flyjump", off = "unflyjump" },
    { on = "freecam", off = "unfreecam" },
    { on = "freezeanims", off = "unfreezeanims" },
    { on = "friend", off = "unfriend" },
    { on = "globalshadows", off = "unglobalshadows" },
    { on = "grabtools", off = "nograbtools" },
    { on = "guidelete", off = "unguidelete" },
    { on = "hatspin", off = "unhatspin" },
    { on = "hideguis", off = "unhideguis" },
    { on = "hitboxes", off = "unhitboxes" },
    { on = "hovername", off = "unhovername" },
    { on = "infjump", off = "uninfjump" },
    { on = "instantproximityprompts", off = "uninstantproximityprompts" },
    { on = "invisibleparts", off = "uninvisibleparts" },
    { on = "keepiy", off = "unkeepiy" },
    { on = "light", off = "unlight" },
    { on = "listento", off = "unlistento" },
    { on = "locate", off = "nolocate" },
    { on = "lockws", off = "unlockws" },
    { on = "loopbring", off = "unloopbring" },
    { on = "loopfullbright", off = "unloopfullbright" },
    { on = "loopgoto", off = "unloopgoto" },
    { on = "loopnobgui", off = "unloopnobgui" },
    { on = "loopoof", off = "unloopoof" },
    { on = "loopxray", off = "unloopxray" },
    { on = "muteallvoices", off = "unmuteallvoices" },
    { on = "muteboombox", off = "unmuteboombox" },
    { on = "mutevc", off = "unmutevc" },
    { on = "nilchar", off = "unnilchar" },
    { on = "noclip", off = "unnoclip" },
    { on = "norotate", off = "unnorotate" },
    { on = "nosit", off = "unnosit" },
    { on = "orbit", off = "unorbit" },
    { on = "partesp", off = "unpartesp" },
    { on = "pmspam", off = "nopmspam" },
    { on = "reach", off = "unreach" },
    { on = "removespecifictool", off = "unremovespecifictool" },
    { on = "render", off = "norender" },
    { on = "showguis", off = "unshowguis" },
    { on = "spam", off = "nospam" },
    { on = "spasm", off = "unspasm" },
    { on = "spawnpoint", off = "nospawnpoint" },
    { on = "spin", off = "unspin" },
    { on = "staffwatch", off = "unstaffwatch" },
    { on = "stareat", off = "unstareat" },
    { on = "stun", off = "unstun" },
    { on = "swim", off = "unswim" },
    { on = "teleportwalk", off = "unteleportwalk" },
    { on = "tools", off = "notools" },
    { on = "vfly", off = "unvfly" },
    { on = "view", off = "unview" },
    { on = "walkfling", off = "unwalkfling" },
    { on = "walkto", off = "unwalkto" },
    { on = "walltp", off = "unwalltp" },
    { on = "weaken", off = "unweaken" },
    { on = "xray", off = "unxray" },
}

local numericCanonical = {}
for _, spec in ipairs(NUMERIC) do
    for _, a in ipairs(spec.aliases) do numericCanonical[a:lower()] = spec end
    numericCanonical[spec.name:lower()] = spec
end

local toggleOff = {}
local toggleOnNames = {}
for _, t in ipairs(TOGGLES) do
    toggleOff[t.on:lower()] = t.off
    toggleOnNames[t.on:lower()] = true
end

-- ================= Helpers =================

local function letterOf(name)
    local c = name:sub(1, 1):upper()
    if c:match("[A-Z]") then return c end
    return "#"
end

local function uiNotify(title, content, icon)
    pcall(function()
        local w = getgenv().WindUI
        if w and w.Notify then
            w:Notify({ Title = title, Content = content, Icon = icon or "info", Duration = 2 })
        end
    end)
end

local function findCommandEntry(cmdName)
    local c = getenv().cmds or _G.cmds
    if type(c) ~= "table" then return nil end
    local want = cmdName:lower():match("^%s*(%S+)")
    if not want then return nil end
    for _, v in ipairs(c) do
        if type(v) == "table" and type(v.NAME) == "string" then
            for word in v.NAME:lower():gmatch("[^/%s%[%]]+") do
                if word == want then return v end
            end
        end
    end
    return nil
end

local function RunCmd(str)
    str = tostring(str)
    local env = getenv()
    local fn = env.execCmd or _G.execCmd or execCmd
    if type(fn) ~= "function" then
        -- Fallback: dispatch straight into the cmds table's FUNC field
        local entry = findCommandEntry(str)
        if entry and type(entry.FUNC) == "function" then
            warnLog("[IY GUI] execCmd missing — using FUNC fallback for: " .. str)
            task.spawn(function()
                local ok, err = pcall(entry.FUNC, str:gsub("^%S+%s*", ""))
                if ok then
                    log("[IY GUI] Ran (fallback): " .. str)
                else
                    warnLog("[IY GUI] FAILED (fallback) '" .. str .. "': " .. tostring(err))
                    uiNotify("Command Failed", str, "x")
                end
            end)
            return
        end
        warnLog("[IY GUI] execCmd NOT FOUND — cannot run: " .. str)
        uiNotify("IY Not Ready", "Cannot run: " .. str, "alert-triangle")
        return
    end
    task.spawn(function()
        local ok, err = pcall(fn, str)
        if ok then
            log("[IY GUI] Ran: " .. str)
            uiNotify("Executed", str, "check")
        else
            warnLog("[IY GUI] FAILED '" .. str .. "': " .. tostring(err))
            uiNotify("Command Failed", str .. " - " .. tostring(err), "x")
        end
    end)
end

local commandMeta = {}
local function ResolveIY()
    print("[IY GUI] ResolveIY() called")
    local env = getenv()
    print("[IY GUI] getenv() = " .. type(env))
    local c = env.cmds or _G.cmds or cmds
    local CMDsTable = env.CMDs or _G.CMDs or CMDs
    print("[IY GUI] cmds type: " .. type(c) .. ", CMDs type: " .. type(CMDsTable))
    if type(CMDsTable) ~= "table" and type(c) ~= "table" then
        print("[IY GUI] ResolveIY: no cmds/CMDs table found")
        return false
    end
    commandMeta = {}
    if type(CMDsTable) == "table" then
        print("[IY GUI] Scanning CMDsTable with " .. #CMDsTable .. " entries")
        for i = 1, #CMDsTable do
            local entry = CMDsTable[i]
            if type(entry) == "table" and entry.NAME then
                local names = tostring(entry.NAME):gsub("%b[]", "")
                local parts = {}
                for seg in names:gmatch("[^/]+") do
                    local clean = seg:match("^%s*(.-)%s*$")
                    if clean and clean ~= "" then parts[#parts + 1] = clean end
                end
                local primary = parts[1] or tostring(entry.NAME)
                local aliases = {}
                for j = 2, #parts do aliases[#aliases + 1] = parts[j] end
                commandMeta[primary:lower()] = {
                    name = primary,
                    aliases = aliases,
                    desc = entry.DESC,
                }
            end
        end
    end
    if type(c) == "table" then
        print("[IY GUI] Scanning cmds table with " .. #c .. " entries")
        for _, v in pairs(c) do
            if type(v) == "table" and type(v.NAME) == "string" then
                local base = tostring(v.NAME):match("^%s*([^/%s]+)")
                if base then
                    local key = base:lower()
                    if not commandMeta[key] then
                        commandMeta[key] = {
                            name = base,
                            aliases = v.ALIAS or {},
                            desc = nil,
                        }
                    elseif not commandMeta[key].desc then
                        commandMeta[key].desc = v.DESC
                    end
                end
            end
        end
    end
    local count = 0
    for _ in pairs(commandMeta) do count = count + 1 end
    print("[IY GUI] ResolveIY: found " .. count .. " commands")
    return count > 0
end

-- ================= IY Console Removal + Credit Badge =================

local creditBadgeRefs = {}

local function updateCreditBadgeTheme()
    if not creditBadgeRefs.frame then return end
    local WindUI = getgenv().WindUI
    if not WindUI or not WindUI.GetCurrentTheme then return end
    local themeName = WindUI:GetCurrentTheme()
    local themes = WindUI:GetThemes()
    local theme = themes and themes[themeName]
    if not theme then return end

    local accent = theme.Accent
    local text = theme.Text
    local placeholder = theme.Placeholder
    local outline = theme.Outline

    if typeof(accent) == "Color3" then
        pcall(function() creditBadgeRefs.stroke.Color = accent end)
        pcall(function() creditBadgeRefs.mainLabel.TextColor3 = accent end)
        pcall(function() creditBadgeRefs.hint.TextColor3 = accent end)
    end
    if typeof(text) == "Color3" then
        pcall(function() creditBadgeRefs.subLabel.TextColor3 = text end)
    end
    if typeof(placeholder) == "Color3" then
        pcall(function() creditBadgeRefs.subLabel.TextColor3 = placeholder end)
    end
    if typeof(outline) == "Color3" then
        pcall(function() creditBadgeRefs.frame.BackgroundColor3 = outline end)
    end
end

local function ensureCreditGui()
    local parentGui = nil
    if type(gethui) == "function" then
        local ok, h = pcall(gethui)
        if ok and typeof(h) == "Instance" then parentGui = h end
    end
    if not parentGui then parentGui = game:GetService("CoreGui") end

    if parentGui:FindFirstChild("LCPCredit") then return end
    local gui = Instance.new("ScreenGui")
    gui.Name = "LCPCredit"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 98

    -- Collapsed sliver under the Roblox topbar buttons (top-left); slides out
    -- from the right on hover.
    local EXPANDED_W = 240
    local COLLAPSED_W = 18
    local H = 58

    local credit = Instance.new("Frame")
    credit.AnchorPoint = Vector2.new(0, 0)
    credit.Position = UDim2.new(0, 10, 0, 48)
    credit.Size = UDim2.new(0, COLLAPSED_W, 0, H)
    credit.BackgroundColor3 = Color3.fromRGB(23, 24, 36)
    credit.BackgroundTransparency = 0.15
    credit.BorderSizePixel = 0
    credit.ClipsDescendants = true
    Instance.new("UICorner", credit).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", credit)
    stroke.Color = Color3.fromRGB(124, 92, 255)
    stroke.Thickness = 2

    local cLabel = Instance.new("TextLabel")
    cLabel.Size = UDim2.new(0, EXPANDED_W - 8, 0, 32)
    cLabel.Position = UDim2.new(0, 4, 0, 6)
    cLabel.BackgroundTransparency = 1
    cLabel.Font = Enum.Font.GothamBold
    cLabel.Text = "Made By LCP"
    cLabel.TextColor3 = Color3.fromRGB(124, 92, 255)
    cLabel.TextSize = 22
    cLabel.Parent = credit

    local subLabel = Instance.new("TextLabel")
    subLabel.Size = UDim2.new(0, EXPANDED_W - 8, 0, 16)
    subLabel.Position = UDim2.new(0, 4, 1, -22)
    subLabel.BackgroundTransparency = 1
    subLabel.Font = Enum.Font.GothamBold
    subLabel.Text = "Apart of the Oaken Team"
    subLabel.TextColor3 = Color3.fromRGB(150, 152, 172)
    subLabel.TextSize = 12
    subLabel.Parent = credit

    local hint = Instance.new("TextLabel")
    hint.Size = UDim2.new(0, COLLAPSED_W, 1, 0)
    hint.BackgroundTransparency = 1
    hint.Font = Enum.Font.GothamBold
    hint.Text = "›"
    hint.TextColor3 = Color3.fromRGB(124, 92, 255)
    hint.TextSize = 20
    hint.ZIndex = 3
    hint.Parent = credit

    credit.MouseEnter:Connect(function()
        TS:Create(credit, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(0, EXPANDED_W, 0, H) }):Play()
        TS:Create(hint, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
    end)

    credit.MouseLeave:Connect(function()
        TS:Create(credit, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(0, COLLAPSED_W, 0, H) }):Play()
        TS:Create(hint, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
    end)

    creditBadgeRefs = {
        frame = credit,
        stroke = stroke,
        mainLabel = cLabel,
        subLabel = subLabel,
        hint = hint,
    }

    -- Apply current theme if WindUI is already loaded
    task.spawn(function()
        local waitCount = 0
        while not getgenv().WindUI and waitCount < 20 do
            task.wait(0.5)
            waitCount = waitCount + 1
        end
        updateCreditBadgeTheme()
    end)

    credit.Parent = gui
    protectGui(gui)
    gui.Parent = parentGui
end

-- ================= Main Build (WindUI) =================

task.spawn(function()
    -- Try multiple WindUI URLs (some executors block release assets).
    local WINDUI_URLS = {
        "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua",
        "https://github.com/Footagesus/WindUI/releases/download/1.6.66/main.lua",
        "https://raw.githubusercontent.com/Footagesus/WindUI/v1.6.66/dist/main.lua",
    }

    local function loadWindUI()
        for i, url in ipairs(WINDUI_URLS) do
            print("[IY GUI] Trying WindUI URL " .. i .. ": " .. url)
            local ok, result = pcall(function()
                return loadstring(game:HttpGet(url))()
            end)
            if ok and type(result) == "table" then
                print("[IY GUI] WindUI loaded from URL " .. i)
                return result
            else
                warn("[IY GUI] WindUI URL " .. i .. " failed: " .. tostring(result))
            end
        end
        return nil
    end

    print("[IY GUI] Loading WindUI...")
    local WindUI = loadWindUI()
    if not WindUI then
        warn("[IY GUI] All WindUI URLs failed — aborting UI build")
        return
    end
    getgenv().WindUI = WindUI

    -- Wait until Infinite Yield exposes a stable command list (up to 30s).
    print("[IY GUI] Waiting for IY commands...")
    local t0 = os.clock()
    local lastCount = -1
    local stableTicks = 0
    while true do
        local ok = ResolveIY()
        local count = 0
        for _ in pairs(commandMeta) do count = count + 1 end
        print(string.format("[IY GUI] commands=%d stable=%d elapsed=%.1fs ok=%s", count, stableTicks, os.clock() - t0, tostring(ok)))
        if ok and count > 0 and count == lastCount then
            stableTicks = stableTicks + 1
            if stableTicks >= 2 then break end
        else
            stableTicks = 0
        end
        lastCount = count
        if os.clock() - t0 > 30 then
            if count > 0 then
                warn("[IY GUI] Timeout reached but " .. count .. " commands found — proceeding anyway")
                break
            else
                warn("[IY GUI] Timeout reached with 0 commands — aborting UI build")
                return
            end
        end
        task.wait(1)
    end

    print("[IY GUI] Creating WindUI window...")
    local beforeWindowSets = snapshotSets()

    local window = WindUI:CreateWindow({
        Title = "Infinite Yield - A-Z Command Center",
        Author = "Made By LCP - Oaken Team",
        Folder = "InfYieldUltra",
        Icon = "terminal",
        Theme = "Dark",
        Size = UDim2.fromOffset(680, 460),
        ToggleKey = Enum.KeyCode.LeftControl,
        HideSearchBar = false,
        SideBarWidth = 190,
        Resizable = true,
    })

    if not window then
        warn("[IY GUI] CreateWindow returned nil — aborting")
        return
    end

    print("[IY GUI] Window created, calling Open()...")
    local okOpen, errOpen = pcall(function() window:Open() end)
    if not okOpen then
        warn("[IY GUI] window:Open() failed: " .. tostring(errOpen))
    else
        print("[IY GUI] Window opened successfully")
    end

    WindUI:SetNotificationLower(true)

    window:OnClose(function()
        WindUI:Notify({
            Title = "Menu Hidden",
            Content = "Press Left Ctrl to bring the menu back.",
            Icon = "eye-off",
            Duration = 4,
        })
    end)

    -- Update credit badge when theme changes
    if WindUI.OnThemeChange then
        WindUI:OnThemeChange(function()
            updateCreditBadgeTheme()
        end)
    end

    -- Tabs: Settings first, then A-Z/#.
    local letters = { "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","#" }
    local tabs = {}
    local tabCounts = {}
    for _, letter in ipairs(letters) do tabCounts[letter] = 0 end

    local keys = {}
    for k in pairs(commandMeta) do keys[#keys + 1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do
        local l = letterOf(k)
        if tabCounts[l] then tabCounts[l] = tabCounts[l] + 1 end
    end

    local settingsTab = window:Tab({ Title = "Settings", Icon = "settings" })

    window:Divider()

    for _, letter in ipairs(letters) do
        tabs[letter] = window:Tab({ Title = letter .. " (" .. tabCounts[letter] .. ")" })
    end

    -- Command elements. Sliders coalesce drag events so a command only runs
    -- once the value settles instead of firing every frame.
    for _, k in ipairs(keys) do
        local meta = commandMeta[k]
        local tab = tabs[letterOf(k)]
        if tab then
            local isToggle = toggleOnNames[k] ~= nil
            local isNumeric = numericCanonical[k] ~= nil
            if isToggle then
                local offCmd = toggleOff[k]
                tab:Toggle({
                    Title = meta.name,
                    Value = false,
                    Callback = function(state)
                        if state then
                            RunCmd(meta.name)
                        else
                            RunCmd(offCmd)
                        end
                    end,
                })
            elseif isNumeric then
                local spec = numericCanonical[k]
                local pendingValue = nil
                local scheduled = false
                tab:Slider({
                    Title = meta.name,
                    Step = spec.step,
                    Value = { Min = spec.min, Max = spec.max, Default = spec.def },
                    IsTooltip = true,
                    Callback = function(v)
                        pendingValue = v
                        if scheduled then return end
                        scheduled = true
                        task.delay(0.2, function()
                            scheduled = false
                            if pendingValue ~= nil then
                                RunCmd(meta.name .. " " .. tostring(pendingValue))
                                pendingValue = nil
                            end
                        end)
                    end,
                })
            else
                tab:Button({
                    Title = meta.name,
                    Callback = function()
                        RunCmd(meta.name)
                    end,
                })
            end
        end
    end

    -- Settings tab: theme picker + control hints.
    settingsTab:Paragraph({
        Title = "Controls",
        Desc = "Left Ctrl opens/closes this menu. Use the sidebar search bar to find commands.",
    })

    local themeNames = {}
    local themesTable = {}
    pcall(function()
        themesTable = WindUI:GetThemes() or {}
    end)
    for name in pairs(themesTable) do
        themeNames[#themeNames + 1] = tostring(name)
    end
    table.sort(themeNames)

    if #themeNames > 0 then
        settingsTab:Dropdown({
            Title = "Theme",
            Values = themeNames,
            Value = WindUI:GetCurrentTheme(),
            Callback = function(selected)
                WindUI:SetTheme(selected)
                updateCreditBadgeTheme()
            end,
        })
    end

    -- Open on the A tab.
    if tabs["A"] then
        pcall(function()
            tabs["A"]:Select()
        end)
    end

    local totalCommands = 0
    for _, c in pairs(tabCounts) do totalCommands = totalCommands + c end

    WindUI:Notify({
        Title = "IY Command Center",
        Content = "Loaded " .. tostring(totalCommands) .. " commands. Left Ctrl toggles the menu.",
        Icon = "check",
        Duration = 5,
    })

    -- Credit badge (was orphaned when hideIYConsole was removed)
    ensureCreditGui()

    -- Whitelist everything WE/WindUI created, then arm the catch-all watchdog
    protectNewSince(beforeWindowSets)
    armChildAddedWatch()
    log("[IY GUI] Build complete — ChildAdded watchdog armed")
end)
