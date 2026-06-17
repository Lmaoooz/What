if game.PlaceId ~= 91255392593879 and game.PlaceId ~= 3004286001 and game.PlaceId ~= 71132543521245 then return end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StatsService = game:GetService("Stats")

local localPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() or Players.LocalPlayer
local username = localPlayer.Name
local folderPath = "WnZHUB/AnimeSquadron"
local filePath = folderPath .. "/" .. username .. "_settings.json"

if makefolder then
    pcall(makefolder, "WnZHUB")
    pcall(makefolder, "WnZHUB/AnimeSquadron")
end

local totalRareDrops = 0

local Options = {
    GameSpeed = "2",
    RestartWave = "1",
    AutoRestart = false,
    AutoStart = false,
    AutoReplay = false,
    AutoNext = false,
    AutoLeave = false,
    AutoRejoin = true,
    Map = "No worlds found",
    Act = "1",
    Difficulty = "Normal",
    Mode = "Story",
    JoinToggle = false,
    Webhook = "",
    EnableWebhook = false,
    UIScale = 1.0,
    BoostFPS = false,
    HideUser = false
}

local function saveSettings()
    if writefile then
        local success, json = pcall(HttpService.JSONEncode, HttpService, Options)
        if success then
            pcall(writefile, filePath, json)
        end
    end
end

local function loadSettings()
    if readfile and isfile and isfile(filePath) then
        local success, content = pcall(readfile, filePath)
        if success and content then
            local decodeSuccess, decoded = pcall(HttpService.JSONDecode, HttpService, content)
            if decodeSuccess and type(decoded) == "table" then
                for k, v in pairs(decoded) do
                    Options[k] = v
                end
            end
        end
    end
end

local worldNames = {}
local worldsFolder = ReplicatedStorage:FindFirstChild("Worlds")
if worldsFolder then
    for _, child in ipairs(worldsFolder:GetChildren()) do
        table.insert(worldNames, child.Name)
    end
end
if #worldNames == 0 then worldNames = {"No worlds found"} end

Options.Map = worldNames[1]
loadSettings()

local boostConnection = nil
local worldConnection = nil

local function optimizeObject(descendant)
    pcall(function()
        if descendant:IsA("Decal") or descendant:IsA("Texture") or descendant:IsA("SurfaceAppearance") then
            descendant:Destroy()
        elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") or descendant:IsA("Smoke") or descendant:IsA("Fire") or descendant:IsA("Sparkles") then
            descendant.Enabled = false
        elseif descendant:IsA("MeshPart") then
            descendant.TextureID = ""
        elseif descendant:IsA("BasePart") and not descendant:IsA("MeshPart") then
            descendant.Material = Enum.Material.SmoothPlastic
        end
    end)
end

local function toggleFPSBoost(enable)
    Options.BoostFPS = enable
    saveSettings()

    if enable then
        for _, descendant in ipairs(workspace:GetDescendants()) do
            optimizeObject(descendant)
        end

        local worldFolder = workspace:FindFirstChild("World")
        if worldFolder and not worldConnection then
            worldConnection = worldFolder.ChildAdded:Connect(function(child)
                task.wait(0.2)
                if Options.BoostFPS then
                    for _, descendant in ipairs(child:GetDescendants()) do
                        optimizeObject(descendant)
                    end
                end
            end)
        end

        if not boostConnection then
            boostConnection = workspace.DescendantAdded:Connect(function(descendant)
                if Options.BoostFPS then
                    optimizeObject(descendant)
                end
            end)
        end
    else
        if worldConnection then worldConnection:Disconnect() worldConnection = nil end
        if boostConnection then boostConnection:Disconnect() boostConnection = nil end
    end
end

local function getRemotes()
    return ReplicatedStorage:FindFirstChild("Remotes")
end

local function getEndScreen()
    local lp = Players.LocalPlayer
    local pg = lp and lp:FindFirstChild("PlayerGui")
    local menus = pg and pg:FindFirstChild("Menus")
    return menus and menus:FindFirstChild("EndScreen")
end

local function getMatchDataAndRewards()
    local endScreen = getEndScreen()
    if not endScreen then return nil, false, "Defeat!", 0xE74C3C end
    
    local worldText, modeText, clearTimeText = "Unknown", "Unknown", "Unknown"
    local chapterText = ""
    
    pcall(function()
        local stats = endScreen:FindFirstChild("Stats")
        if stats then
            if stats:FindFirstChild("World") then worldText = stats.World.Text end
            if stats:FindFirstChild("Mode") then modeText = stats.Mode.Text end
            if stats:FindFirstChild("Chapter") then
                local rawChapter = stats.Chapter.Text
                local cleanChapter = string.gsub(rawChapter, "<[^>]+>", "")
                local actNum = string.match(cleanChapter, "Act%.%s*(%d+)") or string.match(rawChapter, "(%d+)")
                if actNum then
                    chapterText = " Act. " .. actNum
                end
            end
        end
        local left = endScreen:FindFirstChild("Left")
        if left and left:FindFirstChild("PlayTime") and left.PlayTime:FindFirstChild("Amount") then
            clearTimeText = left.PlayTime.Amount.Text
        end
    end)

    local rewards = endScreen:FindFirstChild("Rewards")
    local scrollFrame = rewards and rewards:FindFirstChild("ScrollingFrame")
    if not scrollFrame then return nil, false, "Defeat!", 0xE74C3C end

    local lines = {}
    local shouldPing = false
    local matchRareCount = 0 -- Add this line right before the items loop

    for _, item in ipairs(scrollFrame:GetChildren()) do
        if item:IsA("ImageButton") then
            local quantity = item:FindFirstChild("Quantity")
            local chance = item:FindFirstChild("Chance")
            local itemName = item:FindFirstChild("ItemName")
            local shiny = item:FindFirstChild("Shiny")

            local qText = quantity and quantity.Text or "?"
            local cText = chance and chance.Text or "?"
            local nText = itemName and itemName.Text or item.Name
            local shinyVal = shiny and shiny.Value or false
            local numChance = tonumber(string.match(cText, "([%d%.]+)"))
            
            if numChance and numChance <= 6 then 
                shouldPing = true 
                matchRareCount = matchRareCount + 1 -- Add this tracking line
            end

            table.insert(lines, qText .. " " .. cText .. " [" .. nText .. "] Shiny = " .. tostring(shinyVal))
        end
    end

    if #lines == 0 then table.insert(lines, "No rewards found") end
    
    local totalRuns = 0
    pcall(function()
        if workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Stats") and workspace.Game.Stats:FindFirstChild("Played") then
            totalRuns = workspace.Game.Stats.Played.Value
        end
    end)

    local outcomeText = "Defeat!"
    local embedColor = 0xE74C3C
    pcall(function()
        local header1 = endScreen:FindFirstChild("Header1")
        local textLabel = header1 and header1:FindFirstChild("TextLabel")
        if textLabel and textLabel.Text == "Victory!" then
            outcomeText = "Victory!"
            embedColor = 0x2ECC71
        end
    end)
    
    local formattedDescription = string.format(
        "Match Results:\nWorld: %s%s\nMode: %s\nClear Time: %s\n\nRewards:\n%s\n\nTotal Run: %d",
        worldText, chapterText, modeText, clearTimeText, table.concat(lines, "\n"), totalRuns
    )

    -- Change this final return statement to include matchRareCount:
    return formattedDescription, shouldPing, outcomeText, embedColor, matchRareCount
    end

local function httpRequest(webhookUrl, payload)
    local fn = request or http_request or (http and http.request) or nil
    if not fn then return false, "No executor post method found" end
    local success, err = pcall(fn, {
        Url = webhookUrl,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = payload
    })
    return success, err
end

local function sendWebhook(webhookUrl, title, content, color, shouldPing)
    if shouldPing then
        httpRequest(webhookUrl, HttpService:JSONEncode({ content = "@everyone" }))
        task.wait(0.1)
    end
    httpRequest(webhookUrl, HttpService:JSONEncode({
        embeds = {{ title = title, description = content, color = color }}
    }))
end

WindUI:AddTheme({
    Name = "AnimeSquadronTheme",
    Accent = "#FF007F",
    Dialog = "#160513",
    Outline = "#360E2E",
    Text = "#FFFFFF",
    Placeholder = "#A66D9B",
    Background = "#0D020B",
    Button = "#24091F",
    Icon = "#FF007F"
})

local Window = WindUI:CreateWindow({
	Title = "Anime Squadron | WnZ Hub",
	Folder = "WnZHUB_AnimeSquadron",
	Icon = "rbxassetid://108642426877651",
	Theme = "AnimeSquadronTheme",
	NewElements = true,
	HideSearchBar = false,
	OpenButton = {
		Title = "Open | WnZ Hub",
		CornerRadius = UDim.new(1, 0),
		StrokeThickness = 3,
		Enabled = true,
		Draggable = true,
		OnlyMobile = false,
		Scale = 1,
		Color = ColorSequence.new(
			Color3.fromHex("#FF007F"),
			Color3.fromHex("#160513")
		)
	},
	Topbar = {
		Height = 44,
		ButtonsType = "Default"
	}
})

local StatsTab = Window:Tab({ Title = "Statistics", Icon = "solar:chart-bold", Border = true })
local StatsParagraph = StatsTab:Paragraph({
    Title = "Stats:",
    Desc = "Frame Per Second / FPS: 0\nPing: 0 ms\nTotal Run: 0"
})

local MainTab
do
    MainTab = Window:Tab({ Title = "Main", Icon = "solar:home-2-bold", Border = true })
    
    local speedValues = {"1", "2", "3"}
    MainTab:Dropdown({
        Title = "Select Game Speed",
        Values = speedValues,
        Value = table.find(speedValues, Options.GameSpeed) or 2,
        Callback = function(v) Options.GameSpeed = v saveSettings() end
    })

    MainTab:Input({
        Title = "Auto Restart At Wave",
        Placeholder = "Enter wave number...",
        Value = Options.RestartWave,
        Callback = function(v) Options.RestartWave = v saveSettings() end
    })

    MainTab:Toggle({ 
        Title = "Auto Restart", 
        Value = Options.AutoRestart, 
        Callback = function(v) Options.AutoRestart = v saveSettings() end 
    })
    
    MainTab:Space()
    
    MainTab:Toggle({ Title = "Auto Start", Value = Options.AutoStart, Callback = function(v) Options.AutoStart = v saveSettings() end })
    MainTab:Toggle({ Title = "Auto Replay", Value = Options.AutoReplay, Callback = function(v) Options.AutoReplay = v saveSettings() end })
    MainTab:Toggle({ Title = "Auto Next", Value = Options.AutoNext, Callback = function(v) Options.AutoNext = v saveSettings() end })
    MainTab:Toggle({ Title = "Auto Leave", Value = Options.AutoLeave, Callback = function(v) Options.AutoLeave = v saveSettings() end })
end

do
    local JoinerTab = Window:Tab({ Title = "Joiner", Icon = "solar:square-transfer-horizontal-bold", Border = true })
    
    JoinerTab:Dropdown({
        Title = "Select Map",
        Values = worldNames,
        Value = table.find(worldNames, Options.Map) or 1,
        Callback = function(v) Options.Map = v saveSettings() end
    })
    
    local actValues = {} for i = 1, 10 do table.insert(actValues, tostring(i)) end
    JoinerTab:Dropdown({
        Title = "Select Act",
        Values = actValues,
        Value = table.find(actValues, Options.Act) or 1,
        Callback = function(v) Options.Act = v saveSettings() end
    })
    
    JoinerTab:Dropdown({
        Title = "Select Difficulty",
        Values = {"Normal", "Hard"},
        Value = table.find({"Normal", "Hard"}, Options.Difficulty) or 1,
        Callback = function(v) Options.Difficulty = v saveSettings() end
    })
    
    local modeValues = {"Story", "Squadron", "Raid", "Infinite"}
    JoinerTab:Dropdown({
        Title = "Select Mode",
        Values = modeValues,
        Value = table.find(modeValues, Options.Mode) or 1,
        Callback = function(v) Options.Mode = v saveSettings() end
    })
    
    JoinerTab:Space()
    JoinerTab:Toggle({ Title = "Join Map", Value = Options.JoinToggle, Callback = function(v) Options.JoinToggle = v saveSettings() end })
end

do
    local MiscTab = Window:Tab({ Title = "Misc", Icon = "solar:info-square-bold", Border = true })
    
    MiscTab:Toggle({ Title = "Boost FPS", Value = Options.BoostFPS, Callback = function(v) toggleFPSBoost(v) end })
    MiscTab:Toggle({ Title = "Auto Rejoin", Value = Options.AutoRejoin, Callback = function(v) Options.AutoRejoin = v saveSettings() end })
    MiscTab:Toggle({ Title = "Hide User", Value = Options.HideUser, 
        Callback = function(v) Options.HideUser = v saveSettings() end })
    
    MiscTab:Space()
    MiscTab:Slider({
        Title = "Change UI Size",
        Step = 0.1,
        Value = { Min = 0.7, Max = 1.0, Default = Options.UIScale },
        Callback = function(v)
            Options.UIScale = v saveSettings()
            Window:SetUIScale(v)
        end
    })
end

do
    local WebhookTab = Window:Tab({ Title = "Webhook", Icon = "solar:file-text-bold", Border = true })
    
    WebhookTab:Input({
        Title = "Webhook URL",
        Placeholder = "https://discord.com/api/webhooks/...",
        Value = Options.Webhook,
        Callback = function(v) Options.Webhook = v saveSettings() end
    })
    
    WebhookTab:Toggle({ Title = "Enable Webhook", Value = Options.EnableWebhook, Callback = function(v) Options.EnableWebhook = v saveSettings() end })
    
    WebhookTab:Space()
    WebhookTab:Button({
		Title = "Test Webhook",
		Callback = function()
			local url = Options.Webhook or ""
			if url == "" then
				WindUI:Notify({ Title = "Webhook Error", Content = "Please enter a URL first." })
				return
			end
			local success, err = httpRequest(url, HttpService:JSONEncode({ content = "Hi - WnZ" }))
			if success then
				WindUI:Notify({ Title = "Webhook success", Content = "Sent Message!" })
			else
				WindUI:Notify({ Title = "Webhook Failed", Content = tostring(err) })
			end
		end,
	})
end

task.spawn(function()
    Window:SetUIScale(Options.UIScale)
    if Options.BoostFPS then toggleFPSBoost(true) end
    if StatsTab then
        StatsTab:Select()
    end
end)

GuiService.ErrorMessageChanged:Connect(function()
    if Options.AutoRejoin then
        while game.PlaceId ~= 71132543521245 do
            pcall(function() TeleportService:Teleport(71132543521245, Players.LocalPlayer) end)
            task.wait(1)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.1)
        if Options.AutoRestart then
            pcall(function()
                local gameFolder = workspace:FindFirstChild("Game")
                local waveObj = gameFolder and gameFolder:FindFirstChild("Wave")
                local targetWave = tonumber(Options.RestartWave)
                if waveObj and targetWave and waveObj.Value >= targetWave then
                    local r = getRemotes()
                    if r and r:FindFirstChild("Game") and r.Game:FindFirstChild("replay") then
                        r.Game.replay:FireServer()
                        task.wait(2)
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(60)
        pcall(function()
            local r = getRemotes()
            if r and r:FindFirstChild("Players") and r.Players:FindFirstChild("prevent_afk") then
                r.Players.prevent_afk:FireServer()
            end
        end)
    end
end)

task.spawn(function()
    while true do
        task.wait(0.1)
        if Options.AutoStart then
            pcall(function()
                local r = getRemotes()
                if r and r:FindFirstChild("Players") and r.Players:FindFirstChild("start") then r.Players.start:FireServer() end
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            local r = getRemotes()
            local selectedSpeed = tonumber(Options.GameSpeed) or 1
            if r and r:FindFirstChild("Game") and r.Game:FindFirstChild("change_speed") then r.Game.change_speed:InvokeServer(selectedSpeed) end
        end)
    end
end)

task.spawn(function()
    while true do
        task.wait(0.1)
        if Options.JoinToggle then
            pcall(function()
                local r = getRemotes()
                if not r then return end
                r.Play.create_room:InvokeServer({
                    ["difficulty"]   = Options.Difficulty or "Normal",
                    ["act"]          = tonumber(Options.Act) or 1,
                    ["boosted"]      = true,
                    ["mode"]         = Options.Mode or "Story",
                    ["only_friends"] = false,
                    ["world"]        = Options.Map or worldNames[1]
                })
            end)
            task.wait(0.1)
            pcall(function()
                local r = getRemotes()
                if r then r.Play.start:InvokeServer() end
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait()
        
        local char = localPlayer.Character
        if char then
            -- 1. TextLabel Customizations (RGB, Gradient, Text changes)
            pcall(function()
                local head = char:FindFirstChild("Head")
                local container = head and head:FindFirstChild("Player")
                
                if container then
                    -- Level Amount (Set to 67 + Rainbow RGB)
                    if container:FindFirstChild("level") and container.level:FindFirstChild("amount") then
                        local lvlAmt = container.level.amount
                        lvlAmt.Text = "67"
                        lvlAmt.TextColor3 = Color3.fromHSV(tick() % 5 / 5, 1, 1)
                    end
                    
                    -- Name (Set to WnZHUB + Magenta/Black Gradient)
                    if container:FindFirstChild("name") then
                        local nameLabel = container.name
                        nameLabel.Text = "WnZHUB"
                        
                        local gradient = nameLabel:FindFirstChildOfClass("UIGradient")
                        if not gradient then
                            gradient = Instance.new("UIGradient")
                            gradient.Parent = nameLabel
                        end
                        gradient.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 255)), -- Magenta
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))      -- Black
                        })
                    end
                    
                    -- Title (Set to custom text)
                    if container:FindFirstChild("title") then
                        container.title.Text = "The Most Lazy Player"
                    end
                end
            end)
            
            pcall(function()
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") or part:IsA("Decal") then
                        if part:IsDescendantOf(char:FindFirstChild("Head")) and (part.Parent.Name == "Player" or part.Name == "Player") then
                            continue
                        end
                        
                        if Options.HideUser then
                            if not part:GetAttribute("OldTrans") then
                                part:SetAttribute("OldTrans", part.Transparency)
                            end
                            part.Transparency = 1
                        else
                            if part:GetAttribute("OldTrans") then
                                part.Transparency = part:GetAttribute("OldTrans")
                                part:SetAttribute("OldTrans", nil)
                            end
                        end
                    end
                end

                local playerGui = localPlayer:FindFirstChild("PlayerGui")
                local hotbar = playerGui and playerGui:FindFirstChild("Hotbar")
                local bottomUI = hotbar and hotbar:FindFirstChild("BottomUI")
                
                if bottomUI then
                    bottomUI.Visible = not Options.HideUser
               end
            end)
           end
         end
       end)

task.spawn(function()
    local lastTime = os.clock()
    local frameCount = 0
    local currentFps = 60

    RunService.Heartbeat:Connect(function()
        frameCount = frameCount + 1
        local currentTime = os.clock()
        if currentTime - lastTime >= 1 then
            currentFps = math.floor(frameCount / (currentTime - lastTime))
            frameCount = 0
            lastTime = currentTime
        end
    end)

    while true do
        task.wait(0.1)
        pcall(function()
            local fps = currentFps
            if fps == 0 then
                fps = math.floor(workspace:GetRealPhysicsFPS())
            end

            local ping = 0
            if StatsService and StatsService:FindFirstChild("Network") and StatsService.Network:FindFirstChild("ServerToClientPing") then
                ping = math.floor(StatsService.Network.ServerToClientPing:GetValue())
            end
            
            if ping == 0 and localPlayer then
                local networkPing = localPlayer:GetNetworkPing() * 1000
                if networkPing and networkPing > 0 then
                    ping = math.floor(networkPing)
                end
            end

            if ping == 0 and StatsService and StatsService:FindFirstChild("PerformanceStats") and StatsService.PerformanceStats:FindFirstChild("Ping") then
                ping = math.floor(StatsService.PerformanceStats.Ping:GetValue())
            end

            local totalRuns = 0
            local sessionTimeStr = "0m 0s"
            local gameFolder = workspace:FindFirstChild("Game")
            
            if gameFolder and gameFolder:FindFirstChild("Stats") then
                if gameFolder.Stats:FindFirstChild("Played") then
                    totalRuns = gameFolder.Stats.Played.Value
                end
                
                if gameFolder.Stats:FindFirstChild("Time") then
                    local totalSeconds = tonumber(gameFolder.Stats.Time.Value) or 0
                    local minutes = math.floor(totalSeconds / 60)
                    local seconds = math.floor(totalSeconds % 60)
                    sessionTimeStr = string.format("%dm %ds", minutes, seconds)
                end
            end

            local fpsColor = "#FFFF00"
            if fps >= 60 then
                fpsColor = "#00FF00"
            elseif fps <= 30 then
                fpsColor = "#FF0000"
            end

            local pingColor = "#00FF00"
            if ping >= 120 then
                pingColor = "#FF0000"
            elseif ping >= 80 then
                pingColor = "#FFFF00"
            end

            local descText = string.format(
                "Frame Per Second / FPS: <font color=\"%s\">%d</font>\nPing: <font color=\"%s\">%d ms</font>\nTotal Run: <font color=\"#FF00FF\">%d</font>\nSession Time: <font color=\"#FF00FF\">%s</font>\nTotal Rare Drop: <font color=\"#FF00FF\">%d</font>", 
                fpsColor, fps, pingColor, ping, totalRuns, sessionTimeStr, totalRareDrops)

            if StatsParagraph then
                pcall(function()
                    StatsParagraph:SetDesc(descText)
                end)

                pcall(function()
                    local function scanAndModify(t)
                        for k, v in pairs(t) do
                            if typeof(v) == "Instance" then
                                if v:IsA("TextLabel") and (string.find(v.Text, "FPS") or string.find(v.Text, "Ping") or string.find(v.Text, "Total") or string.find(v.Text, "Run") or v.Text == "0" or string.find(v.Text, "Frame")) then
                                    v.RichText = true
                                    v.Text = descText
                                end
                            elseif type(v) == "table" and v ~= t then
                                scanAndModify(v)
                            end
                        end
                    end
                    scanAndModify(StatsParagraph)
                end)
            end
        end)
    end
end)

local webhookFired, actionFired, lastVisible, visibleSince = false, false, false, 0
task.spawn(function()
    while true do
        task.wait()
        local endScreen = getEndScreen()
        local visible = endScreen ~= nil and endScreen.Visible

        if visible and not lastVisible then
            webhookFired, actionFired, visibleSince = false, false, tick()
        end

        if visible then
            if not webhookFired then
                webhookFired = true
                if Options.EnableWebhook and Options.Webhook ~= "" then
                    task.spawn(function()
                        for _ = 1, 5 do
                            -- Add matchRareCount here:
                            local descText, shouldPing, outcomeText, embedColor, matchRareCount = getMatchDataAndRewards()
                            if descText then
                                -- Add the new match drops safely to your total count:
                                totalRareDrops = totalRareDrops + (matchRareCount or 0)
                                sendWebhook(Options.Webhook, "Webhook Sent! [" .. outcomeText .. "]", descText, embedColor, shouldPing)
                                break
                            end
                            task.wait(0.1)
                        end
                    end)
                end
            end

            if not actionFired and (tick() - visibleSince) >= 0.5 then
                actionFired = true
                pcall(function()
                    local r = getRemotes()
                    if not r then return end
                    if Options.AutoReplay then r.Game.replay:FireServer()
                    elseif Options.AutoNext then r.Game.next:FireServer()
                    elseif Options.AutoLeave then r.Game.leave:FireServer() end
                end)
            end
        end
        lastVisible = visible
    end
end)
