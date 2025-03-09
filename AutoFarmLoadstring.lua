-- RayWare Auto-Farm Loadstring
-- Created for easy deployment

-- Auto-Farm System Loadstring
local AutoFarmLoadstring = [[
-- Create module structure
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create necessary folders and remotes
local AutoFarmRemotes
if not ReplicatedStorage:FindFirstChild("AutoFarmRemotes") then
    AutoFarmRemotes = Instance.new("Folder")
    AutoFarmRemotes.Name = "AutoFarmRemotes"
    AutoFarmRemotes.Parent = ReplicatedStorage
    
    -- Create required remotes
    local checkGamepass = Instance.new("RemoteFunction")
    checkGamepass.Name = "CheckGamepassOwnership"
    checkGamepass.Parent = AutoFarmRemotes
    
    local toggleRemote = Instance.new("RemoteEvent")
    toggleRemote.Name = "ToggleAutoFarm"
    toggleRemote.Parent = AutoFarmRemotes
    
    local promptPurchase = Instance.new("RemoteEvent")
    promptPurchase.Name = "PromptGamepassPurchase"
    promptPurchase.Parent = AutoFarmRemotes
else
    AutoFarmRemotes = ReplicatedStorage.AutoFarmRemotes
end

-- UIUtils Module
local UIUtils = {}

-- Theme definition
UIUtils.Theme = {
    BackgroundColor = Color3.fromRGB(30, 30, 30),
    SecondaryBackground = Color3.fromRGB(40, 40, 40),
    AccentColor = Color3.fromRGB(0, 132, 255),
    TextColor = Color3.fromRGB(255, 255, 255),
    SubTextColor = Color3.fromRGB(180, 180, 180),
    WarningColor = Color3.fromRGB(255, 128, 0),
    SuccessColor = Color3.fromRGB(0, 200, 0),
    FontNormal = Enum.Font.SourceSans,
    FontTitles = Enum.Font.SourceSansBold,
    CornerRadius = UDim.new(0, 5)
}

-- Function to create a basic frame
function UIUtils.CreateFrame(name, size, position)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = size
    frame.Position = position
    frame.BackgroundColor3 = UIUtils.Theme.BackgroundColor
    frame.BorderSizePixel = 0
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UIUtils.Theme.CornerRadius
    corner.Parent = frame
    
    return frame
end

-- Function to create a title bar
function UIUtils.CreateTitleBar(parent, title)
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 35)
    titleBar.BackgroundColor3 = UIUtils.Theme.SecondaryBackground
    titleBar.BorderSizePixel = 0
    titleBar.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UIUtils.Theme.CornerRadius
    corner.Parent = titleBar
    
    -- Only round the top corners
    local bottomFrame = Instance.new("Frame")
    bottomFrame.Name = "BottomFrame"
    bottomFrame.Size = UDim2.new(1, 0, 0.5, 0)
    bottomFrame.Position = UDim2.new(0, 0, 0.5, 0)
    bottomFrame.BackgroundColor3 = UIUtils.Theme.SecondaryBackground
    bottomFrame.BorderSizePixel = 0
    bottomFrame.Parent = titleBar
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.Font = UIUtils.Theme.FontTitles
    titleLabel.TextSize = 16
    titleLabel.TextColor3 = UIUtils.Theme.TextColor
    titleLabel.Parent = titleBar
    
    -- Make title bar draggable
    local dragging = false
    local dragInput
    local dragStart
    local startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        parent.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = parent.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
    
    return titleBar
end

-- Function to create a scrolling frame
function UIUtils.CreateScrollingFrame(name, size, position)
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = name
    scrollFrame.Size = size
    scrollFrame.Position = position
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = UIUtils.Theme.AccentColor
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be set dynamically
    
    -- Auto-layout
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.Parent = scrollFrame
    
    -- Auto-size canvas
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 5)
    padding.PaddingBottom = UDim.new(0, 5)
    padding.PaddingLeft = UDim.new(0, 5)
    padding.PaddingRight = UDim.new(0, 5)
    padding.Parent = scrollFrame
    
    return scrollFrame
end

-- Function to create a label
function UIUtils.CreateLabel(name, text, size, position)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Text = text
    label.Size = size
    if position then
        label.Position = position
    end
    label.BackgroundTransparency = 1
    label.Font = UIUtils.Theme.FontNormal
    label.TextSize = 14
    label.TextColor3 = UIUtils.Theme.TextColor
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    return label
end

-- Function to create a button
function UIUtils.CreateButton(name, text, size, position)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Text = text
    button.Size = size
    if position then
        button.Position = position
    end
    button.BackgroundColor3 = UIUtils.Theme.SecondaryBackground
    button.BorderSizePixel = 0
    button.Font = UIUtils.Theme.FontNormal
    button.TextSize = 14
    button.TextColor3 = UIUtils.Theme.TextColor
    button.AutoButtonColor = true
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UIUtils.Theme.CornerRadius
    corner.Parent = button
    
    -- Hover effect
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = UIUtils.Theme.SecondaryBackground
    end)
    
    return button
end

-- Function to create a toggle button
function UIUtils.CreateToggle(name, text, initialState, position)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Name = name
    toggleFrame.Size = UDim2.new(1, 0, 0, 30)
    if position then
        toggleFrame.Position = position
    end
    toggleFrame.BackgroundTransparency = 1
    
    local toggleLabel = UIUtils.CreateLabel("Label", text, UDim2.new(1, -60, 1, 0))
    toggleLabel.Parent = toggleFrame
    
    local toggleBackground = Instance.new("Frame")
    toggleBackground.Name = "Background"
    toggleBackground.Size = UDim2.new(0, 50, 0, 24)
    toggleBackground.Position = UDim2.new(1, -55, 0.5, 0)
    toggleBackground.AnchorPoint = Vector2.new(0, 0.5)
    toggleBackground.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    toggleBackground.BorderSizePixel = 0
    toggleBackground.Parent = toggleFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = toggleBackground
    
    local toggleIndicator = Instance.new("Frame")
    toggleIndicator.Name = "Indicator"
    toggleIndicator.Size = UDim2.new(0, 20, 0, 20)
    toggleIndicator.Position = UDim2.new(0, 2, 0.5, 0)
    toggleIndicator.AnchorPoint = Vector2.new(0, 0.5)
    toggleIndicator.BackgroundColor3 = UIUtils.Theme.TextColor
    toggleIndicator.BorderSizePixel = 0
    toggleIndicator.Parent = toggleBackground
    
    local indicatorCorner = Instance.new("UICorner")
    indicatorCorner.CornerRadius = UDim.new(0, 10)
    indicatorCorner.Parent = toggleIndicator
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(1, 0, 1, 0)
    toggleButton.BackgroundTransparency = 1
    toggleButton.Text = ""
    toggleButton.Parent = toggleBackground
    
    -- Initialize toggle state
    local isOn = initialState or false
    
    local function updateToggleState()
        if isOn then
            toggleIndicator.Position = UDim2.new(0, 28, 0.5, 0)
            toggleBackground.BackgroundColor3 = UIUtils.Theme.AccentColor
        else
            toggleIndicator.Position = UDim2.new(0, 2, 0.5, 0)
            toggleBackground.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        end
    end
    
    -- Initial state
    updateToggleState()
    
    -- Handle clicks
    toggleButton.MouseButton1Click:Connect(function()
        isOn = not isOn
        
        -- Update visual state
        updateToggleState()
        
        -- Fire changed event
        local changedEvent = Instance.new("BoolValue")
        changedEvent.Name = name .. "Changed"
        changedEvent.Value = isOn
        changedEvent.Parent = toggleFrame
    end)
    
    -- Add functions to get/set state
    toggleFrame.GetState = function()
        return isOn
    end
    
    toggleFrame.SetState = function(newState)
        if isOn ~= newState then
            isOn = newState
            updateToggleState()
        end
    end
    
    return toggleFrame
end

-- Make UIUtils available
if not ReplicatedStorage:FindFirstChild("UIUtils") then
    local uiUtilsModule = Instance.new("ModuleScript")
    uiUtilsModule.Name = "UIUtils"
    uiUtilsModule.Source = "return " .. game:GetService("HttpService"):JSONEncode(UIUtils):gsub("\"", "\\\"")
    uiUtilsModule.Parent = ReplicatedStorage
end

-- AutoFarmModule
local AutoFarmModule = {}

-- Constants for auto-farm behavior (default values)
AutoFarmModule.DefaultSettings = {
    FloatHeight = 10,          -- Height above enemy to float
    UpdateInterval = 0.1,      -- Seconds between position updates
    MaxTargetDistance = 1000,  -- Maximum distance to consider enemies
    MinTargetDistance = 2,     -- Minimum distance to consider as "reached" target
    FlySpeed = 20,             -- Speed to move toward target
    AutoAttack = false,        -- Whether to automatically attack enemies
    AttackInterval = 1.0,      -- Seconds between auto attacks
    AutoCollectDrops = false,  -- Whether to collect drops automatically
    TargetPreference = "Closest", -- Targeting preference: "Closest", "HighestLevel", "LowestHealth"
}

-- Clone default settings to current settings
AutoFarmModule.Settings = {}
for key, value in pairs(AutoFarmModule.DefaultSettings) do
    AutoFarmModule.Settings[key] = value
end

-- Function to update settings
function AutoFarmModule.UpdateSetting(settingName, value)
    if AutoFarmModule.Settings[settingName] ~= nil then
        AutoFarmModule.Settings[settingName] = value
        return true
    end
    return false
end

-- Function to reset settings to defaults
function AutoFarmModule.ResetSettings()
    for key, value in pairs(AutoFarmModule.DefaultSettings) do
        AutoFarmModule.Settings[key] = value
    end
end

-- Enemy detection settings
AutoFarmModule.EnemySettings = {
    -- Tags or properties that identify enemies in your game
    -- These should be customized for your specific game
    PossibleTeams = {"Enemies", "Monsters"},
    PossibleFolders = {"Enemies", "NPCs", "Monsters"},
    PossibleTags = {"Enemy", "Monster", "NPC"},
}

-- Function to identify if an object is an enemy based on your game's structure
function AutoFarmModule.IsEnemy(object)
    -- Check if it's an NPC with a Humanoid
    if not object:FindFirstChild("Humanoid") then
        return false
    end
    
    -- Check if it's a character that belongs to another player
    local players = game:GetService("Players"):GetPlayers()
    for _, player in ipairs(players) do
        if player.Character == object then
            return false
        end
    end
    
    -- Check for enemy teams
    if object:FindFirstChild("Team") then
        for _, teamName in ipairs(AutoFarmModule.EnemySettings.PossibleTeams) do
            if object.Team.Value == teamName then
                return true
            end
        end
    end
    
    -- Check for enemy tags
    for _, tagName in ipairs(AutoFarmModule.EnemySettings.PossibleTags) do
        if object:FindFirstChild(tagName) then
            return true
        end
    end
    
    -- Enemies are often in specific folders
    for _, parent in ipairs(object:GetAncestors()) do
        for _, folderName in ipairs(AutoFarmModule.EnemySettings.PossibleFolders) do
            if parent.Name == folderName then
                return true
            end
        end
    end
    
    -- Additional game-specific logic can be added here
    
    return false
end

-- Function to get all enemies in the workspace
function AutoFarmModule.GetAllEnemies()
    local enemies = {}
    
    -- Look through workspace descendants
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and AutoFarmModule.IsEnemy(obj) and 
           obj:FindFirstChild("Humanoid") and obj.Humanoid.Health > 0 and
           obj:FindFirstChild("HumanoidRootPart") then
            table.insert(enemies, obj)
        end
    end
    
    return enemies
end

-- Function to get enemy information for display
function AutoFarmModule.GetEnemyInfo(enemy)
    local info = {
        Name = enemy.Name,
        Health = enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health or 0,
        MaxHealth = enemy:FindFirstChild("Humanoid") and enemy.Humanoid.MaxHealth or 0,
        Position = enemy:FindFirstChild("HumanoidRootPart") and enemy.HumanoidRootPart.Position or Vector3.new(0,0,0),
    }
    
    -- Get level if available (game-specific)
    if enemy:FindFirstChild("Level") then
        info.Level = enemy.Level.Value
    else
        info.Level = "Unknown"
    end
    
    return info
end

-- Function to calculate position above enemy
function AutoFarmModule.GetPositionAboveEnemy(enemy, height)
    height = height or AutoFarmModule.Settings.FloatHeight
    
    if not enemy or not enemy:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local rootPart = enemy.HumanoidRootPart
    local position = rootPart.Position + Vector3.new(0, height, 0)
    
    return position
end

-- Make AutoFarmModule available
if not ReplicatedStorage:FindFirstChild("AutoFarmModule") then
    local autoFarmModuleScript = Instance.new("ModuleScript")
    autoFarmModuleScript.Name = "AutoFarmModule"
    autoFarmModuleScript.Source = "return " .. game:GetService("HttpService"):JSONEncode(AutoFarmModule):gsub("\"", "\\\"")
    autoFarmModuleScript.Parent = ReplicatedStorage
end

-- LoadingScreen Module
local LoadingScreen = {}

function LoadingScreen.Show(parent)
    -- Create loading screen container
    local loadingFrame = UIUtils.CreateFrame("LoadingFrame", UDim2.new(1, 0, 1, 0), UDim2.new(0.5, 0, 0.5, 0))
    loadingFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    loadingFrame.BackgroundTransparency = 0.5
    loadingFrame.Parent = parent
    
    -- Create content frame
    local contentFrame = UIUtils.CreateFrame("Content", UDim2.new(0, 400, 0, 200), UDim2.new(0.5, 0, 0.5, 0))
    contentFrame.Parent = loadingFrame
    
    -- Title
    local titleLabel = UIUtils.CreateLabel("Title", "RayWare Auto-Farm", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 10))
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.Font = UIUtils.Theme.FontTitles
    titleLabel.TextSize = 24
    titleLabel.Parent = contentFrame
    
    -- Loading text
    local loadingText = UIUtils.CreateLabel("LoadingText", "Initializing...", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 60))
    loadingText.TextXAlignment = Enum.TextXAlignment.Center
    loadingText.TextColor3 = UIUtils.Theme.SubTextColor
    loadingText.Parent = contentFrame
    
    -- Loading bar background
    local loadingBarBg = Instance.new("Frame")
    loadingBarBg.Name = "LoadingBarBg"
    loadingBarBg.Size = UDim2.new(0.8, 0, 0, 20)
    loadingBarBg.Position = UDim2.new(0.1, 0, 0, 100)
    loadingBarBg.BackgroundColor3 = UIUtils.Theme.SecondaryBackground
    loadingBarBg.BorderSizePixel = 0
    loadingBarBg.Parent = contentFrame
    
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UIUtils.Theme.CornerRadius
    barCorner.Parent = loadingBarBg
    
    -- Loading bar fill
    local loadingBar = Instance.new("Frame")
    loadingBar.Name = "LoadingBar"
    loadingBar.Size = UDim2.new(0, 0, 1, 0)
    loadingBar.BackgroundColor3 = UIUtils.Theme.AccentColor
    loadingBar.BorderSizePixel = 0
    loadingBar.Parent = loadingBarBg
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UIUtils.Theme.CornerRadius
    fillCorner.Parent = loadingBar
    
    -- Version text
    local versionText = UIUtils.CreateLabel("VersionText", "v1.0.0", UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 160))
    versionText.TextXAlignment = Enum.TextXAlignment.Center
    versionText.TextSize = 12
    versionText.TextColor3 = UIUtils.Theme.SubTextColor
    versionText.Parent = contentFrame
    
    -- Loading messages
    local loadingMessages = {
        "Initializing auto-farm system...",
        "Loading enemy detection...",
        "Calibrating targeting system...",
        "Preparing RayWare UI...",
        "Loading settings...",
        "Establishing connectivity...",
        "Almost ready..."
    }
    
    -- Animated loading sequence
    local function runLoadingSequence()
        -- Setup initial tweens
        local function createTween(obj, props, time, easingStyle, easingDir, repeatCount)
            local tInfo = TweenInfo.new(
                time, 
                easingStyle or Enum.EasingStyle.Quad, 
                easingDir or Enum.EasingDirection.Out, 
                repeatCount or 0,
                false,
                0
            )
            return game:GetService("TweenService"):Create(obj, tInfo, props)
        end
        
        -- Pulse animation for title
        local titlePulse = createTween(titleLabel, {TextSize = 26}, 0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1)
        titlePulse:Play()
        
        -- Loading bar animation
        for i = 1, #loadingMessages do
            loadingText.Text = loadingMessages[i]
            
            local progress = i / #loadingMessages
            local barTween = createTween(loadingBar, {Size = UDim2.new(progress, 0, 1, 0)}, 0.5)
            barTween:Play()
            
            wait(0.8) -- Wait between stages
        end
        
        -- Final loading
        loadingText.Text = "Ready!"
        local finalBarTween = createTween(loadingBar, {Size = UDim2.new(1, 0, 1, 0)}, 0.3)
        finalBarTween:Play()
        
        wait(0.5)
        
        -- Fade out
        local fadeOut = createTween(loadingFrame, {BackgroundTransparency = 1}, 0.5)
        fadeOut:Play()
        
        local contentFade = createTween(contentFrame, {BackgroundTransparency = 1}, 0.5)
        contentFade:Play()
        
        -- Fade out all text elements
        for _, child in pairs(contentFrame:GetDescendants()) do
            if child:IsA("TextLabel") then
                createTween(child, {TextTransparency = 1}, 0.5):Play()
            elseif child:IsA("Frame") and not child:IsDescendantOf(loadingBar) then
                createTween(child, {BackgroundTransparency = 1}, 0.5):Play()
            end
        end
        
        wait(0.5)
        loadingFrame:Destroy()
    end
    
    -- Run the loading sequence
    spawn(runLoadingSequence)
    
    return loadingFrame
end

-- SettingsMenu Module
local SettingsMenu = {}

-- Create the settings menu
function SettingsMenu.Create(parent)
    -- Main settings frame
    local settingsFrame = UIUtils.CreateFrame("SettingsFrame", UDim2.new(1, 0, 1, 0), UDim2.new(0.5, 0, 0.5, 0))
    settingsFrame.BackgroundTransparency = 1
    settingsFrame.Visible = false
    settingsFrame.Parent = parent
    
    -- Inner settings panel
    local settingsPanel = UIUtils.CreateFrame("SettingsPanel", UDim2.new(0, 300, 0, 400), UDim2.new(0.5, 0, 0.5, 0))
    settingsPanel.Parent = settingsFrame
    
    -- Title bar
    local titleBar = UIUtils.CreateTitleBar(settingsPanel, "Auto-Farm Settings")
    
    -- Content container
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, 0, 1, -35)
    contentFrame.Position = UDim2.new(0, 0, 0, 35)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = settingsPanel
    
    local scrollFrame = UIUtils.CreateScrollingFrame("SettingsScroll", UDim2.new(1, -20, 1, -60), UDim2.new(0, 10, 0, 10))
    scrollFrame.Parent = contentFrame
    
    -- Add settings
    local settingY = 10
    local spacing = 40
    
    -- Float Height Slider
    local floatHeightLabel = UIUtils.CreateLabel("FloatHeightLabel", "Float Height", UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, settingY))
    floatHeightLabel.Font = UIUtils.Theme.FontTitles
    floatHeightLabel.Parent = scrollFrame
    
    local floatHeightValue = UIUtils.CreateLabel("FloatHeightValue", tostring(AutoFarmModule.Settings.FloatHeight), UDim2.new(0, 50, 0, 20), UDim2.new(1, -50, 0, settingY))
    floatHeightValue.TextXAlignment = Enum.TextXAlignment.Right
    floatHeightValue.Parent = scrollFrame
    
    local floatHeightSlider = Instance.new("Frame")
    floatHeightSlider.Name = "FloatHeightSlider"
    floatHeightSlider.Size = UDim2.new(1, 0, 0, 20)
    floatHeightSlider.Position = UDim2.new(0, 0, 0, settingY + 20)
    floatHeightSlider.BackgroundColor3 = UIUtils.Theme.SecondaryBackground
    floatHeightSlider.BorderSizePixel = 0
    floatHeightSlider.Parent = scrollFrame
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UIUtils.Theme.CornerRadius
    sliderCorner.Parent = floatHeightSlider
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Name = "Fill"
    sliderFill.Size = UDim2.new(AutoFarmModule.Settings.FloatHeight / 30, 0, 1, 0) -- Scale 0-30
    sliderFill.BackgroundColor3 = UIUtils.Theme.AccentColor
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = floatHeightSlider
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UIUtils.Theme.CornerRadius
    fillCorner.Parent = sliderFill
    
    local sliderButton = Instance.new("TextButton")
    sliderButton.Name = "SliderButton"
    sliderButton.Size = UDim2.new(1, 0, 1, 0)
    sliderButton.BackgroundTransparency = 1
    sliderButton.Text = ""
    sliderButton.Parent = floatHeightSlider
    
    sliderButton.MouseButton1Down:Connect(function()
        local mouse = game:GetService("Players").LocalPlayer:GetMouse()
        local sliderPosition = floatHeightSlider.AbsolutePosition
        local sliderSize = floatHeightSlider.AbsoluteSize
        
        local function updateSlider()
            local relativeX = math.clamp(mouse.X - sliderPosition.X, 0, sliderSize.X)
            local scaleX = relativeX / sliderSize.X
            sliderFill.Size = UDim2.new(scaleX, 0, 1, 0)
            
            -- Calculate float height value (min 2, max 30)
            local newHeight = math.floor(scaleX * 30) + 2
            floatHeightValue.Text = tostring(newHeight)
            AutoFarmModule.UpdateSetting("FloatHeight", newHeight)
        end
        
        local mouseMove
        mouseMove = game:GetService("UserInputService").InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                updateSlider()
            end
        end)
        
        local mouseUp
        mouseUp = game:GetService("UserInputService").InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                mouseMove:Disconnect()
                mouseUp:Disconnect()
            end
        end)
        
        updateSlider() -- Initial update
    end)
    
    settingY = settingY + spacing
    
    -- Fly Speed Slider
    local flySpeedLabel = UIUtils.CreateLabel("FlySpeedLabel", "Fly Speed", UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, settingY))
    flySpeedLabel.Font = UIUtils.Theme.FontTitles
    flySpeedLabel.Parent = scrollFrame
    
    local flySpeedValue = UIUtils.CreateLabel("FlySpeedValue", tostring(AutoFarmModule.Settings.FlySpeed), UDim2.new(0, 50, 0, 20), UDim2.new(1, -50, 0, settingY))
    flySpeedValue.TextXAlignment = Enum.TextXAlignment.Right
    flySpeedValue.Parent = scrollFrame
    
    local flySpeedSlider = Instance.new("Frame")
    flySpeedSlider.Name = "FlySpeedSlider"
    flySpeedSlider.Size = UDim2.new(1, 0, 0, 20)
    flySpeedSlider.Position = UDim2.new(0, 0, 0, settingY + 20)
    flySpeedSlider.BackgroundColor3 = UIUtils.Theme.SecondaryBackground
    flySpeedSlider.BorderSizePixel = 0
    flySpeedSlider.Parent = scrollFrame
    
    local speedSliderCorner = Instance.new("UICorner")
    speedSliderCorner.CornerRadius = UIUtils.Theme.CornerRadius
    speedSliderCorner.Parent = flySpeedSlider
    
    local speedSliderFill = Instance.new("Frame")
    speedSliderFill.Name = "Fill"
    -- Scale is 0-50 for speed
    speedSliderFill.Size = UDim2.new(AutoFarmModule.Settings.FlySpeed / 50, 0, 1, 0)
    speedSliderFill.BackgroundColor3 = UIUtils.Theme.AccentColor
    speedSliderFill.BorderSizePixel = 0
    speedSliderFill.Parent = flySpeedSlider
    
    local speedFillCorner = Instance.new("UICorner")
    speedFillCorner.CornerRadius = UIUtils.Theme.CornerRadius
    speedFillCorner.Parent = speedSliderFill
    
    local speedSliderButton = Instance.new("TextButton")
    speedSliderButton.Name = "SliderButton"
    speedSliderButton.Size = UDim2.new(1, 0, 1, 0)
    speedSliderButton.BackgroundTransparency = 1
    speedSliderButton.Text = ""
    speedSliderButton.Parent = flySpeedSlider
    
    speedSliderButton.MouseButton1Down:Connect(function()
        local mouse = game:GetService("Players").LocalPlayer:GetMouse()
        local sliderPosition = flySpeedSlider.AbsolutePosition
        local sliderSize = flySpeedSlider.AbsoluteSize
        
        local function updateSlider()
            local relativeX = math.clamp(mouse.X - sliderPosition.X, 0, sliderSize.X)
            local scaleX = relativeX / sliderSize.X
            speedSliderFill.Size = UDim2.new(scaleX, 0, 1, 0)
            
            -- Calculate speed value (min 5, max 50)
            local newSpeed = math.floor(scaleX * 45) + 5
            flySpeedValue.Text = tostring(newSpeed)
            AutoFarmModule.UpdateSetting("FlySpeed", newSpeed)
        end
        
        local mouseMove
        mouseMove = game:GetService("UserInputService").InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                updateSlider()
            end
        end)
        
        local mouseUp
        mouseUp = game:GetService("UserInputService").InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                mouseMove:Disconnect()
                mouseUp:Disconnect()
            end
        end)
        
        updateSlider() -- Initial update
    end)
    
    settingY = settingY + spacing
    
    -- Max Target Distance Slider
    local maxDistanceLabel = UIUtils.CreateLabel("MaxDistanceLabel", "Max Target Distance", UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, settingY))
    maxDistanceLabel.Font = UIUtils.Theme.FontTitles
    maxDistanceLabel.Parent = scrollFrame
    
    local maxDistanceValue = UIUtils.CreateLabel("MaxDistanceValue", tostring(AutoFarmModule.Settings.MaxTargetDistance), UDim2.new(0, 50, 0, 20), UDim2.new(1, -50, 0, settingY))
    maxDistanceValue.TextXAlignment = Enum.TextXAlignment.Right
    maxDistanceValue.Parent = scrollFrame
    
    local maxDistanceSlider = Instance.new("Frame")
    maxDistanceSlider.Name = "MaxDistanceSlider"
    maxDistanceSlider.Size = UDim2.new(1, 0, 0, 20)
    maxDistanceSlider.Position = UDim2.new(0, 0, 0, settingY + 20)
    maxDistanceSlider.BackgroundColor3 = UIUtils.Theme.SecondaryBackground
    maxDistanceSlider.BorderSizePixel = 0
    maxDistanceSlider.Parent = scrollFrame
    
    local distanceSliderCorner = Instance.new("UICorner")
    distanceSliderCorner.CornerRadius = UIUtils.Theme.CornerRadius
    distanceSliderCorner.Parent = maxDistanceSlider
    
    local distanceSliderFill = Instance.new("Frame")
    distanceSliderFill.Name = "Fill"
    -- Scale is 0-2000 for distance
    distanceSliderFill.Size = UDim2.new(AutoFarmModule.Settings.MaxTargetDistance / 2000, 0, 1, 0)
    distanceSliderFill.BackgroundColor3 = UIUtils.Theme.AccentColor
    distanceSliderFill.BorderSizePixel = 0
    distanceSliderFill.Parent = maxDistanceSlider
    
    local distanceFillCorner = Instance.new("UICorner")
    distanceFillCorner.CornerRadius = UIUtils.Theme.CornerRadius
    distanceFillCorner.Parent = distanceSliderFill
    
    local distanceSliderButton = Instance.new("TextButton")
    distanceSliderButton.Name = "SliderButton"
    distanceSliderButton.Size = UDim2.new(1, 0, 1, 0)
    distanceSliderButton.BackgroundTransparency = 1
    distanceSliderButton.Text = ""
    distanceSliderButton.Parent = maxDistanceSlider
    
    distanceSliderButton.MouseButton1Down:Connect(function()
        local mouse = game:GetService("Players").LocalPlayer:GetMouse()
        local sliderPosition = maxDistanceSlider.AbsolutePosition
        local sliderSize = maxDistanceSlider.AbsoluteSize
        
        local function updateSlider()
            local relativeX = math.clamp(mouse.X - sliderPosition.X, 0, sliderSize.X)
            local scaleX = relativeX / sliderSize.X
            distanceSliderFill.Size = UDim2.new(scaleX, 0, 1, 0)
            
            -- Calculate distance value (min 100, max 2000)
            local newDistance = math.floor(scaleX * 1900) + 100
            maxDistanceValue.Text = tostring(newDistance)
            AutoFarmModule.UpdateSetting("MaxTargetDistance", newDistance)
        end
        
        local mouseMove
        mouseMove = game:GetService("UserInputService").InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                updateSlider()
            end
        end)
        
        local mouseUp
        mouseUp = game:GetService("UserInputService").InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                mouseMove:Disconnect()
                mouseUp:Disconnect()
            end
        end)
        
        updateSlider() -- Initial update
    end)
    
    settingY = settingY + spacing
    
    -- Auto Attack Toggle
    local autoAttackToggle = UIUtils.CreateToggle(
        "AutoAttackToggle", 
        "Auto Attack Enemies", 
        AutoFarmModule.Settings.AutoAttack, 
        UDim2.new(0, 0, 0, settingY)
    )
    autoAttackToggle.Parent = scrollFrame
    
    -- Connect toggle change
    autoAttackToggle.ChildAdded:Connect(function(child)
        if child.Name == "AutoAttackToggleChanged" then
            local enabled = child:Wait()
            AutoFarmModule.UpdateSetting("AutoAttack", enabled)
        end
    end)
    
    settingY = settingY + spacing
    
    -- Auto Collect Drops Toggle
    local autoCollectToggle = UIUtils.CreateToggle(
        "AutoCollectToggle", 
        "Auto Collect Drops", 
        AutoFarmModule.Settings.AutoCollectDrops, 
        UDim2.new(0, 0, 0, settingY)
    )
    autoCollectToggle.Parent = scrollFrame
    
    -- Connect toggle change
    autoCollectToggle.ChildAdded:Connect(function(child)
        if child.Name == "AutoCollectToggleChanged" then
            local enabled = child:Wait()
            AutoFarmModule.UpdateSetting("AutoCollectDrops", enabled)
        end
    end)
    
    settingY = settingY + spacing
    
    -- Target preference dropdown
    local targetPrefLabel = UIUtils.CreateLabel("TargetPrefLabel", "Target Preference", UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, settingY))
    targetPrefLabel.Font = UIUtils.Theme.FontTitles
    targetPrefLabel.Parent = scrollFrame
    
    -- Create dropdown for target preference
    local prefOptions = {"Closest", "HighestLevel", "LowestHealth"}
    local currentPrefIndex = 1
    
    -- Find current index
    for i, option in ipairs(prefOptions) do
        if option == AutoFarmModule.Settings.TargetPreference then
            currentPrefIndex = i
            break
        end
    end
    
    local dropdown = Instance.new("Frame")
    dropdown.Name = "TargetPrefDropdown"
    dropdown.Size = UDim2.new(1, 0, 0, 35)
    dropdown.Position = UDim2.new(0, 0, 0, settingY + 25)
    dropdown.BackgroundColor3 = UIUtils.Theme.SecondaryBackground
    dropdown.BorderSizePixel = 0
    dropdown.Parent = scrollFrame
    
    local dropdownCorner = Instance.new("UICorner")
    dropdownCorner.CornerRadius = UIUtils.Theme.CornerRadius
    dropdownCorner.Parent = dropdown
    
    local selectedLabel = UIUtils.CreateLabel("SelectedOption", prefOptions[currentPrefIndex], UDim2.new(1, -40, 1, 0), UDim2.new(0, 10, 0, 0))
    selectedLabel.TextYAlignment = Enum.TextYAlignment.Center
    selectedLabel.Parent = dropdown
    
    local dropdownArrow = UIUtils.CreateLabel("DropdownArrow", "▼", UDim2.new(0, 20, 1, 0), UDim2.new(1, -30, 0, 0))
    dropdownArrow.TextYAlignment = Enum.TextYAlignment.Center
    dropdownArrow.Parent = dropdown
    
    local dropdownButton = Instance.new("TextButton")
    dropdownButton.Name = "DropdownButton"
    dropdownButton.Size = UDim2.new(1, 0, 1, 0)
    dropdownButton.BackgroundTransparency = 1
    dropdownButton.Text = ""
    dropdownButton.Parent = dropdown
    
    -- Options container
    local optionsContainer = Instance.new("Frame")
    optionsContainer.Name = "OptionsContainer"
    optionsContainer.Size = UDim2.new(1, 0, 0, #prefOptions * 35)
    optionsContainer.Position = UDim2.new(0, 0, 1, 5)
    optionsContainer.BackgroundColor3 = UIUtils.Theme.BackgroundColor
    optionsContainer.BorderSizePixel = 0
    optionsContainer.Visible = false
    optionsContainer.ZIndex = 5
    optionsContainer.Parent = dropdown
    
    local optionsCorner = Instance.new("UICorner")
    optionsCorner.CornerRadius = UIUtils.Theme.CornerRadius
    optionsCorner.Parent = optionsContainer
    
    -- Create option buttons
    for i, option in ipairs(prefOptions) do
        local optionButton = UIUtils.CreateButton("Option_" .. option, option, UDim2.new(1, 0, 0, 35), UDim2.new(0, 0, 0, (i-1) * 35))
        optionButton.ZIndex = 5
        optionButton.Parent = optionsContainer
        
        optionButton.MouseButton1Click:Connect(function()
            selectedLabel.Text = option
            optionsContainer.Visible = false
            AutoFarmModule.UpdateSetting("TargetPreference", option)
        end)
    end
    
    -- Toggle dropdown
    dropdownButton.MouseButton1Click:Connect(function()
        optionsContainer.Visible = not optionsContainer.Visible
    end)
    
    settingY = settingY + spacing + 35
    
    -- Reset settings button
    local resetButton = UIUtils.CreateButton("ResetButton", "Reset to Defaults", UDim2.new(0.8, 0, 0, 40), UDim2.new(0.5, 0, 0, settingY))
    resetButton.AnchorPoint = Vector2.new(0.5, 0)
    resetButton.Parent = scrollFrame
    
    -- Connect reset button
    resetButton.MouseButton1Click:Connect(function()
        AutoFarmModule.ResetSettings()
        
        -- Update UI elements to reflect default settings
        floatHeightValue.Text = tostring(AutoFarmModule.Settings.FloatHeight)
        sliderFill.Size = UDim2.new(AutoFarmModule.Settings.FloatHeight / 30, 0, 1, 0)
        
        flySpeedValue.Text = tostring(AutoFarmModule.Settings.FlySpeed)
        speedSliderFill.Size = UDim2.new(AutoFarmModule.Settings.FlySpeed / 50, 0, 1, 0)
        
        maxDistanceValue.Text = tostring(AutoFarmModule.Settings.MaxTargetDistance)
        distanceSliderFill.Size = UDim2.new(AutoFarmModule.Settings.MaxTargetDistance / 2000, 0, 1, 0)
        
        autoAttackToggle.SetState(AutoFarmModule.Settings.AutoAttack)
        autoCollectToggle.SetState(AutoFarmModule.Settings.AutoCollectDrops)
        
        -- Update dropdown
        selectedLabel.Text = AutoFarmModule.Settings.TargetPreference
    end)
    
    -- Close button
    local closeButton = UIUtils.CreateButton("CloseButton", "Close", UDim2.new(0.5, 0, 0, 30), UDim2.new(0.5, 0, 1, -50))
    closeButton.AnchorPoint = Vector2.new(0.5, 0)
    closeButton.Parent = contentFrame
    
    closeButton.MouseButton1Click:Connect(function()
        settingsFrame.Visible = false
    end)
    
    -- Return the settings menu object
    return {
        MainFrame = settingsFrame,
        Toggle = function() settingsFrame.Visible = not settingsFrame.Visible end
    }
end

-- Main UI setup and auto-farm logic
local function InitializeAutoFarm()
    -- UI variables
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Auto-farm state
    local isAutoFarmEnabled = false
    local selectedEnemy = nil
    local autoFarmUpdateConnection = nil
    
    -- Create main UI
    local function createMainUI()
        -- UI already created for loading screen
        
        -- Create main frame
        local mainFrame = UIUtils.CreateFrame("MainFrame", UDim2.new(0, 350, 0, 450), UDim2.new(0.85, 0, 0.5, 0))
        mainFrame.Parent = ui
        
        -- Create title bar
        local titleBar = UIUtils.CreateTitleBar(mainFrame, "RayWare Auto-Farm")
        
        -- Create content container
        local contentFrame = Instance.new("Frame")
        contentFrame.Name = "Content"
        contentFrame.Size = UDim2.new(1, 0, 1, -35)
        contentFrame.Position = UDim2.new(0, 0, 0, 35)
        contentFrame.BackgroundTransparency = 1
        contentFrame.Parent = mainFrame
        
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 10)
        padding.PaddingBottom = UDim.new(0, 10)
        padding.PaddingLeft = UDim.new(0, 10)
        padding.PaddingRight = UDim.new(0, 10)
        padding.Parent = contentFrame
        
        -- Create status section
        local statusFrame = Instance.new("Frame")
        statusFrame.Name = "StatusFrame"
        statusFrame.Size = UDim2.new(1, 0, 0, 90)
        statusFrame.BackgroundColor3 = UIUtils.Theme.SecondaryBackground
        statusFrame.BorderSizePixel = 0
        statusFrame.Parent = contentFrame
        
        local statusCorner = Instance.new("UICorner")
        statusCorner.CornerRadius = UIUtils.Theme.CornerRadius
        statusCorner.Parent = statusFrame
        
        local statusPadding = Instance.new("UIPadding")
        statusPadding.PaddingTop = UDim.new(0, 8)
        statusPadding.PaddingBottom = UDim.new(0, 8)
        statusPadding.PaddingLeft = UDim.new(0, 8)
        statusPadding.PaddingRight = UDim.new(0, 8)
        statusPadding.Parent = statusFrame
        
        local statusTitleLabel = UIUtils.CreateLabel("StatusTitle", "Auto-Farm Status", UDim2.new(1, 0, 0, 20))
        statusTitleLabel.Font = UIUtils.Theme.FontTitles
        statusTitleLabel.Parent = statusFrame
        
        local statusLabel = UIUtils.CreateLabel("StatusLabel", "Inactive", UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 25))
        statusLabel.TextColor3 = UIUtils.Theme.WarningColor
        statusLabel.Parent = statusFrame
        
        local targetLabel = UIUtils.CreateLabel("TargetLabel", "Target: None Selected", UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 50))
        targetLabel.TextColor3 = UIUtils.Theme.SubTextColor
        targetLabel.Parent = statusFrame
        
        -- Auto-farm toggle button
        local toggleFrame = Instance.new("Frame")
        toggleFrame.Name = "ToggleFrame"
        toggleFrame.Size = UDim2.new(1, 0, 0, 50)
        toggleFrame.Position = UDim2.new(0, 0, 0, 100)
        toggleFrame.BackgroundTransparency = 1
        toggleFrame.Parent = contentFrame
        
        local autoFarmToggle = UIUtils.CreateToggle("AutoFarmToggle", "Enable Auto-Farm", false)
        autoFarmToggle.Parent = toggleFrame
        
        -- Target selection section
        local targetSectionLabel = UIUtils.CreateLabel("TargetSectionLabel", "Enemy Selection", UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 160))
        targetSectionLabel.Font = UIUtils.Theme.FontTitles
        targetSectionLabel.Parent = contentFrame
        
        local targetScrollFrame = UIUtils.CreateScrollingFrame("TargetList", UDim2.new(1, 0, 0, 200), UDim2.new(0, 0, 0, 185))
        targetScrollFrame.Parent = contentFrame
        
        -- Refresh button
        local refreshButton = UIUtils.CreateButton("RefreshButton", "Refresh Enemies", UDim2.new(0.65, 0, 0, 35), UDim2.new(0, 0, 0, 395))
        refreshButton.Parent = contentFrame
        
        -- Settings button
        local settingsButton = UIUtils.CreateButton("SettingsButton", "Settings", UDim2.new(0.3, 0, 0, 35), UDim2.new(0.7, 0, 0, 395))
        settingsButton.Parent = contentFrame
        
        -- Gamepass info frame
        local gamepassInfo = Instance.new("Frame")
        gamepassInfo.Name = "GamepassInfo"
        gamepassInfo.Size = UDim2.new(1, 0, 0, 0)
        gamepassInfo.BackgroundTransparency = 1
        gamepassInfo.Parent = ui
        gamepassInfo.Visible = false
        
        -- Create a function to handle the auto-farm toggle
        local function onAutoFarmToggle(enabled)
            isAutoFarmEnabled = enabled
            
            -- Update status display
            if enabled then
                statusLabel.Text = "Active"
                statusLabel.TextColor3 = UIUtils.Theme.SuccessColor
                
                -- Check if an enemy is selected
                if selectedEnemy then
                    targetLabel.Text = "Target: " .. selectedEnemy.Name
                else
                    statusLabel.Text = "No Target Selected"
                    statusLabel.TextColor3 = UIUtils.Theme.WarningColor
                    autoFarmToggle:SetState(false)
                    isAutoFarmEnabled = false
                    return
                end
                
                -- Start auto-farm
                AutoFarmRemotes.ToggleAutoFarm:FireServer(true)
                startAutoFarm()
            else
                statusLabel.Text = "Inactive"
                statusLabel.TextColor3 = UIUtils.Theme.WarningColor
                
                -- Stop auto-farm
                AutoFarmRemotes.ToggleAutoFarm:FireServer(false)
                stopAutoFarm()
            end
        end
        
        -- Connect the toggle event
        toggleFrame.ChildAdded:Connect(function(child)
            if child.Name == "AutoFarmToggleChanged" then
                onAutoFarmToggle(child:Wait())
            end
        end)
        
        -- Function to refresh enemy list
        local function refreshEnemyList()
            -- Clear existing entries
            for _, child in pairs(targetScrollFrame:GetChildren()) do
                if child:IsA("Frame") and child.Name ~= "UIListLayout" and child.Name ~= "UIPadding" then
                    child:Destroy()
                end
            end
            
            -- Get enemies
            local enemies = AutoFarmModule.GetAllEnemies()
            
            -- Check if no enemies found
            if #enemies == 0 then
                local noEnemiesLabel = UIUtils.CreateLabel("NoEnemiesLabel", "No enemies found in workspace", UDim2.new(1, 0, 0, 30))
                noEnemiesLabel.TextColor3 = UIUtils.Theme.SubTextColor
                noEnemiesLabel.TextXAlignment = Enum.TextXAlignment.Center
                noEnemiesLabel.Parent = targetScrollFrame
                return
            end
            
            -- Add enemies to list
            for i, enemy in ipairs(enemies) do
                -- Get enemy info
                local enemyInfo = AutoFarmModule.GetEnemyInfo(enemy)
                
                -- Create target frame
                local targetFrame = Instance.new("Frame")
                targetFrame.Name = "Target_" .. enemy.Name
                targetFrame.Size = UDim2.new(1, 0, 0, 50)
                targetFrame.BackgroundColor3 = UIUtils.Theme.SecondaryBackground
                targetFrame.BorderSizePixel = 0
                targetFrame.LayoutOrder = i
                
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UIUtils.Theme.CornerRadius
                corner.Parent = targetFrame
                
                local nameLabel = UIUtils.CreateLabel("NameLabel", enemyInfo.Name, UDim2.new(1, -80, 0, 20), UDim2.new(0, 10, 0, 5))
                nameLabel.Font = UIUtils.Theme.FontTitles
                nameLabel.Parent = targetFrame
                
                local healthLabel = UIUtils.CreateLabel("HealthLabel", "HP: " .. math.floor(enemyInfo.Health) .. "/" .. math.floor(enemyInfo.MaxHealth), UDim2.new(1, -80, 0, 20), UDim2.new(0, 10, 0, 25))
                healthLabel.TextColor3 = UIUtils.Theme.SubTextColor
                healthLabel.TextSize = 12
                healthLabel.Parent = targetFrame
                
                -- Select button
                local selectButton = UIUtils.CreateButton("SelectButton", "Select", UDim2.new(0, 70, 0, 30), UDim2.new(1, -80, 0.5, 0))
                selectButton.AnchorPoint = Vector2.new(0, 0.5)
                selectButton.Parent = targetFrame
                
                -- Highlight if this is the selected enemy
                if selectedEnemy and selectedEnemy == enemy then
                    targetFrame.BackgroundColor3 = Color3.fromRGB(45, 50, 60)
                    selectButton.BackgroundColor3 = UIUtils.Theme.AccentColor
                    selectButton.Text = "Selected"
                end
                
                -- Button click handler
                selectButton.MouseButton1Click:Connect(function()
                    selectedEnemy = enemy
                    targetLabel.Text = "Target: " .. enemy.Name
                    
                    -- Update visuals
                    refreshEnemyList()
                    
                    -- If auto-farm is already active, update target
                    if isAutoFarmEnabled then
                        stopAutoFarm()
                        startAutoFarm()
                    end
                end)
                
                targetFrame.Parent = targetScrollFrame
            end
        end
        
        -- Connect refresh button
        refreshButton.MouseButton1Click:Connect(refreshEnemyList)
        
        -- Initial refresh
        refreshEnemyList()
        
        -- No gamepass verification needed, all players have access to the auto-farm feature
        -- The CheckGamepassOwnership function has been modified to always return true
        
        -- Return the UI components
        return {
            MainUI = ui,
            MainFrame = mainFrame,
            StatusLabel = statusLabel,
            TargetLabel = targetLabel,
            AutoFarmToggle = autoFarmToggle,
            RefreshEnemyList = refreshEnemyList
        }
    end
    
    -- Function to start auto-farming
    function startAutoFarm()
        if not selectedEnemy or not isAutoFarmEnabled then return end
        
        -- Clear existing connection if any
        if autoFarmUpdateConnection then
            autoFarmUpdateConnection:Disconnect()
            autoFarmUpdateConnection = nil
        end
        
        local character = player.Character
        if not character or not character:FindFirstChild("Humanoid") or not character:FindFirstChild("HumanoidRootPart") then
            return
        end
        
        -- Store original humanoid properties
        local humanoid = character:FindFirstChild("Humanoid")
        local originalWalkSpeed = humanoid.WalkSpeed
        local originalJumpPower = humanoid.JumpPower
        
        -- Set auto-farm properties
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        
        -- Auto-attack timer
        local lastAttackTime = 0
        
        -- Connection to update position
        autoFarmUpdateConnection = game:GetService("RunService").Heartbeat:Connect(function()
            if not isAutoFarmEnabled or not selectedEnemy or not selectedEnemy:FindFirstChild("HumanoidRootPart") or 
               not character or not character:FindFirstChild("Humanoid") or not character:FindFirstChild("HumanoidRootPart") then
                stopAutoFarm()
                return
            end
            
            -- Check if enemy is too far
            local enemyPos = selectedEnemy.HumanoidRootPart.Position
            local characterPos = character.HumanoidRootPart.Position
            local distanceToEnemy = (enemyPos - characterPos).Magnitude
            
            if distanceToEnemy > AutoFarmModule.Settings.MaxTargetDistance then
                -- Enemy too far, stop auto-farm
                stopAutoFarm()
                return
            end
            
            -- Calculate position above enemy
            local targetPosition = AutoFarmModule.GetPositionAboveEnemy(selectedEnemy, AutoFarmModule.Settings.FloatHeight)
            if not targetPosition then
                stopAutoFarm()
                return
            end
            
            -- Move character to position above enemy
            local moveDirection = (targetPosition - character.HumanoidRootPart.Position)
            
            if moveDirection.Magnitude > AutoFarmModule.Settings.MinTargetDistance then
                -- Not at target position yet, move towards it
                moveDirection = moveDirection.Unit * math.min(moveDirection.Magnitude, AutoFarmModule.Settings.FlySpeed * AutoFarmModule.Settings.UpdateInterval)
                character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame + moveDirection
            end
            
            -- Auto-attack functionality
            if AutoFarmModule.Settings.AutoAttack then
                local currentTime = tick()
                if currentTime - lastAttackTime >= AutoFarmModule.Settings.AttackInterval then
                    lastAttackTime = currentTime
                    
                    -- Look at the enemy
                    character.HumanoidRootPart.CFrame = CFrame.lookAt(character.HumanoidRootPart.Position, enemyPos)
                    
                    -- Simulate attack (this should be customized based on your game's combat system)
                    -- For example, using the default Roblox weapon system
                    local tool = character:FindFirstChildOfClass("Tool")
                    if tool and tool:FindFirstChild("Activate") and tool:FindFirstChild("Activate"):IsA("RemoteEvent") then
                        tool.Activate:FireServer()
                    else
                        -- If no tool found, use humanoid attack animation
                        humanoid:ChangeState(Enum.HumanoidStateType.Swimming) -- Quick state change to interrupt current animations
                        wait()
                        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                        
                        -- Try to play attack animation if available
                        local animation = Instance.new("Animation")
                        animation.AnimationId = "rbxassetid://4841574018" -- Default attack animation
                        local animTrack = humanoid:LoadAnimation(animation)
                        animTrack:Play()
                    end
                end
            end
            
            -- Auto collect drops functionality (stub - would need to be implemented based on your game)
            if AutoFarmModule.Settings.AutoCollectDrops then
                -- Search for drops near the character
                for _, obj in pairs(workspace:GetChildren()) do
                    if obj:IsA("BasePart") and obj.Name == "Drop" and 
                       (obj.Position - characterPos).Magnitude < 30 then
                        -- Move the drop to character
                        obj.CFrame = character.HumanoidRootPart.CFrame
                    end
                end
            end
        end)
        
        -- Notify that auto-farm started
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Auto-Farm",
            Text = "Auto-farm started for " .. selectedEnemy.Name,
            Duration = 3
        })
    end
    
    -- Function to stop auto-farming
    function stopAutoFarm()
        if autoFarmUpdateConnection then
            autoFarmUpdateConnection:Disconnect()
            autoFarmUpdateConnection = nil
        end
        
        -- Restore original humanoid properties
        local character = player.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.WalkSpeed = 16  -- Default walk speed
            character.Humanoid.JumpPower = 50  -- Default jump power
        end
        
        isAutoFarmEnabled = false
        
        -- Update UI if it exists
        local ui = playerGui:FindFirstChild("AutoFarmUI")
        if ui and ui:FindFirstChild("MainFrame") and ui.MainFrame:FindFirstChild("Content") then
            local content = ui.MainFrame.Content
            if content:FindFirstChild("StatusFrame") then
                local statusLabel = content.StatusFrame:FindFirstChild("StatusLabel")
                if statusLabel then
                    statusLabel.Text = "Inactive"
                    statusLabel.TextColor3 = UIUtils.Theme.WarningColor
                end
            end
            
            -- Update toggle
            if content:FindFirstChild("ToggleFrame") and content.ToggleFrame:FindFirstChild("AutoFarmToggle") then
                local toggle = content.ToggleFrame.AutoFarmToggle
                if toggle.GetState and toggle.GetState() ~= isAutoFarmEnabled then
                    toggle.SetState(isAutoFarmEnabled)
                end
            end
        end
        
        -- Notify that auto-farm stopped
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Auto-Farm",
            Text = "Auto-farm stopped",
            Duration = 3
        })
    end
    
    -- Show loading screen
    local ui = Instance.new("ScreenGui")
    ui.Name = "AutoFarmUI"
    ui.ResetOnSpawn = false
    ui.Parent = playerGui
    
    -- Display loading screen first
    local loadingScreen = LoadingScreen.Show(ui)
    
    -- Wait for loading screen to complete its animation
    task.wait(4.5)
    
    -- Create the UI
    local uiComponents = createMainUI()
    
    -- Create settings menu
    local settingsMenu = SettingsMenu.Create(playerGui:WaitForChild("AutoFarmUI"))
    
    -- Connect settings button
    local settingsButton = uiComponents.MainFrame.Content.SettingsButton
    settingsButton.MouseButton1Click:Connect(function()
        settingsMenu.Toggle()
    end)
    
    -- Toggle button to show/hide UI
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "AutoFarmToggleButton"
    toggleButton.Size = UDim2.new(0, 40, 0, 40)
    toggleButton.Position = UDim2.new(0.95, 0, 0.3, 0)
    toggleButton.AnchorPoint = Vector2.new(0.5, 0.5)
    toggleButton.BackgroundColor3 = UIUtils.Theme.AccentColor
    toggleButton.BorderSizePixel = 0
    toggleButton.Text = "AF"
    toggleButton.Font = UIUtils.Theme.FontTitles
    toggleButton.TextSize = 16
    toggleButton.TextColor3 = UIUtils.Theme.TextColor
    toggleButton.Parent = playerGui:WaitForChild("AutoFarmUI")
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = toggleButton
    
    toggleButton.MouseButton1Click:Connect(function()
        uiComponents.MainFrame.Visible = not uiComponents.MainFrame.Visible
    end)
    
    -- Set up a loop to check if the selected enemy still exists
    spawn(function()
        while wait(1) do
            if selectedEnemy then
                -- Check if enemy still exists and is valid
                if not selectedEnemy:IsDescendantOf(game.Workspace) or 
                   not selectedEnemy:FindFirstChild("Humanoid") or 
                   selectedEnemy.Humanoid.Health <= 0 then
                    -- Enemy is gone or defeated
                    selectedEnemy = nil
                    uiComponents.TargetLabel.Text = "Target: None Selected"
                    
                    -- Stop auto-farm if it was running
                    if isAutoFarmEnabled then
                        uiComponents.AutoFarmToggle:SetState(false)
                        isAutoFarmEnabled = false
                        stopAutoFarm()
                        
                        -- Notify player
                        game:GetService("StarterGui"):SetCore("SendNotification", {
                            Title = "Auto-Farm",
                            Text = "Target lost or defeated",
                            Duration = 3
                        })
                    end
                    
                    -- Refresh the enemy list
                    uiComponents.RefreshEnemyList()
                end
            end
        end
    end)
    
    -- Server-side handler for auto-farm events
    if game:GetService("RunService"):IsServer() then
        AutoFarmRemotes.CheckGamepassOwnership.OnInvoke = function()
            return true -- Everyone has access to auto-farm
        end
        
        AutoFarmRemotes.ToggleAutoFarm.OnServerEvent:Connect(function(player, enabled)
            -- You can add server-side logging or validation here
        end)
    end
end

-- Execute the auto-farm functionality
InitializeAutoFarm()
]]

-- Wrap the loadstring
return loadstring(AutoFarmLoadstring)()
