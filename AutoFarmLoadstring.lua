-- Command-based Auto-Farm Script

-- Core auto-farm functionality
local AutoFarmModule = {}

-- Settings
AutoFarmModule.Settings = {
    FloatHeight = 10,          -- Height above enemy to float
    UpdateInterval = 0.1,      -- Seconds between position updates
    MaxTargetDistance = 1000,  -- Maximum distance to consider enemies
    MinTargetDistance = 2,     -- Minimum distance to consider as "reached" target
    FlySpeed = 20,             -- Speed to move toward target
    AutoAttack = true,         -- Whether to automatically attack enemies
    AttackInterval = 1.0,      -- Seconds between auto attacks
    AutoCollectDrops = true,   -- Whether to collect drops automatically
}

-- Connect to player
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local isAutoFarmEnabled = false
local selectedEnemy = nil
local autoFarmUpdateConnection = nil

-- Function to identify if an object is an enemy
function AutoFarmModule.IsEnemy(object)
    -- Basic checks
    if not object:IsA("Model") or not object:FindFirstChild("Humanoid") then
        return false
    end
    
    -- Check if it's a character that belongs to another player
    local players = Players:GetPlayers()
    for _, plr in ipairs(players) do
        if plr.Character == object then
            return false
        end
    end
    
    -- Look for common enemy indicators
    if object:FindFirstChild("Enemy") or object:FindFirstChild("NPC") or 
       object:FindFirstChild("Monster") or string.find(string.lower(object.Name), "enemy") or
       string.find(string.lower(object.Name), "npc") or string.find(string.lower(object.Name), "boss") or
       string.find(string.lower(object.Name), "monster") then
        return true
    end
    
    -- Check for enemy teams
    if object:FindFirstChild("Team") then
        local possibleTeams = {"Enemies", "Monsters", "NPC", "Opponents"}
        for _, teamName in ipairs(possibleTeams) do
            if object.Team.Value == teamName then
                return true
            end
        end
    end
    
    -- Check for common folders
    for _, parent in ipairs(object:GetAncestors()) do
        local possibleFolders = {"Enemies", "NPCs", "Monsters", "Bosses", "Mobs"}
        for _, folderName in ipairs(possibleFolders) do
            if parent.Name == folderName then
                return true
            end
        end
    end
    
    -- If it has Humanoid but isn't a player, it's likely an enemy
    return true
end

-- Function to find an enemy by name (full or partial match)
function AutoFarmModule.FindEnemyByName(name)
    name = string.lower(name)
    local bestMatch = nil
    local exactMatch = nil
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if AutoFarmModule.IsEnemy(obj) and 
           obj:FindFirstChild("Humanoid") and obj.Humanoid.Health > 0 and
           obj:FindFirstChild("HumanoidRootPart") then
            
            local objName = string.lower(obj.Name)
            
            -- Exact match
            if objName == name then
                exactMatch = obj
                break
            end
            
            -- Partial match
            if string.find(objName, name) then
                bestMatch = obj
            end
        end
    end
    
    -- Prefer exact match
    return exactMatch or bestMatch
end

-- Get all enemies
function AutoFarmModule.GetAllEnemies()
    local enemies = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if AutoFarmModule.IsEnemy(obj) and 
           obj:FindFirstChild("Humanoid") and obj.Humanoid.Health > 0 and
           obj:FindFirstChild("HumanoidRootPart") then
            table.insert(enemies, obj)
        end
    end
    
    return enemies
end

-- Calculate position above enemy
function AutoFarmModule.GetPositionAboveEnemy(enemy, height)
    height = height or AutoFarmModule.Settings.FloatHeight
    
    if not enemy or not enemy:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local rootPart = enemy.HumanoidRootPart
    local position = rootPart.Position + Vector3.new(0, height, 0)
    
    return position
end

-- Function to start auto-farming
function startAutoFarm()
    if not selectedEnemy or not isAutoFarmEnabled then return end
    
    -- Clear existing connection
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
                
                -- Try various attack methods
                local tool = character:FindFirstChildOfClass("Tool")
                if tool then
                    -- Approach 1: Activate remote
                    if tool:FindFirstChild("Activate") and tool:FindFirstChild("Activate"):IsA("RemoteEvent") then
                        tool.Activate:FireServer()
                    -- Approach 2: Tool-specific remotes
                    elseif tool:FindFirstChild("Attack") and tool:FindFirstChild("Attack"):IsA("RemoteEvent") then
                        tool.Attack:FireServer()
                    elseif tool:FindFirstChild("Click") and tool:FindFirstChild("Click"):IsA("RemoteEvent") then
                        tool.Click:FireServer()
                    -- Approach 3: Find any RemoteEvent in the tool and try it
                    else
                        for _, obj in pairs(tool:GetDescendants()) do
                            if obj:IsA("RemoteEvent") then
                                obj:FireServer()
                                break
                            end
                        end
                    end
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
        
        -- Auto collect drops functionality 
        if AutoFarmModule.Settings.AutoCollectDrops then
            -- Search for drops near the character
            for _, obj in pairs(workspace:GetChildren()) do
                if (obj:IsA("BasePart") or obj:IsA("Model")) and 
                   (obj.Name == "Drop" or obj.Name == "Pickup" or obj.Name == "Coin" or obj.Name == "Chest" or
                   string.find(string.lower(obj.Name), "pickup") or string.find(string.lower(obj.Name), "drop") or
                   string.find(string.lower(obj.Name), "coin") or string.find(string.lower(obj.Name), "gem") or
                   string.find(string.lower(obj.Name), "chest")) and 
                   (obj.Position - characterPos).Magnitude < 50 then
                    
                    -- Try to bring it to the player
                    if obj:IsA("BasePart") then
                        obj.CFrame = character.HumanoidRootPart.CFrame
                    elseif obj:FindFirstChild("HumanoidRootPart") then
                        obj.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame
                    elseif obj:FindFirstChildOfClass("Part") then
                        obj:FindFirstChildOfClass("Part").CFrame = character.HumanoidRootPart.CFrame
                    end
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
    
    -- Notify that auto-farm stopped
    if selectedEnemy then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Auto-Farm",
            Text = "Auto-farm stopped for " .. selectedEnemy.Name,
            Duration = 3
        })
    else
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Auto-Farm",
            Text = "Auto-farm stopped",
            Duration = 3
        })
    end
end

-- Create command input UI
local ui = Instance.new("ScreenGui")
ui.Name = "CommandAutoFarm"
ui.ResetOnSpawn = false
ui.Parent = player.PlayerGui

-- Create frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 100)
frame.Position = UDim2.new(0.5, 0, 0.1, 0)
frame.AnchorPoint = Vector2.new(0.5, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Parent = ui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 5)
corner.Parent = frame

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundTransparency = 1
title.Text = "RayWare Auto-Farm"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.Parent = frame

-- Input box
local input = Instance.new("TextBox")
input.Size = UDim2.new(1, -20, 0, 30)
input.Position = UDim2.new(0, 10, 0, 35)
input.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
input.BorderSizePixel = 0
input.PlaceholderText = "Type 'auto farm [enemy name]' or 'stop'"
input.Text = ""
input.TextColor3 = Color3.fromRGB(255, 255, 255)
input.Font = Enum.Font.SourceSans
input.TextSize = 14
input.ClearTextOnFocus = false
input.Parent = frame

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 5)
inputCorner.Parent = input

-- Status label
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 20)
status.Position = UDim2.new(0, 10, 0, 70)
status.BackgroundTransparency = 1
status.Text = "Ready"
status.TextColor3 = Color3.fromRGB(0, 200, 0)
status.Font = Enum.Font.SourceSans
status.TextSize = 14
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = frame

-- Process commands
input.FocusLost:Connect(function(enterPressed)
    if not enterPressed then return end
    
    local command = string.lower(input.Text)
    
    if string.find(command, "auto farm") or string.find(command, "autofarm") then
        local enemyName = string.gsub(command, "auto farm", "")
        enemyName = string.gsub(enemyName, "autofarm", "")
        enemyName = string.gsub(enemyName, " ", "")
        
        -- Stop previous auto-farm if running
        if isAutoFarmEnabled then
            stopAutoFarm()
        end
        
        -- Find enemy
        if enemyName and enemyName ~= "" then
            selectedEnemy = AutoFarmModule.FindEnemyByName(enemyName)
            if selectedEnemy then
                status.Text = "Auto-farming: " .. selectedEnemy.Name
                status.TextColor3 = Color3.fromRGB(0, 200, 0)
                isAutoFarmEnabled = true
                startAutoFarm()
            else
                status.Text = "Could not find enemy: " .. enemyName
                status.TextColor3 = Color3.fromRGB(255, 100, 0)
            end
        else
            -- If no name provided, show a list of enemies
            local enemies = AutoFarmModule.GetAllEnemies()
            if #enemies > 0 then
                local enemyList = "Available enemies: "
                for i = 1, math.min(5, #enemies) do
                    enemyList = enemyList .. enemies[i].Name
                    if i < math.min(5, #enemies) then
                        enemyList = enemyList .. ", "
                    end
                end
                if #enemies > 5 then
                    enemyList = enemyList .. " and " .. (#enemies - 5) .. " more"
                end
                status.Text = enemyList
                status.TextColor3 = Color3.fromRGB(0, 200, 0)
            else
                status.Text = "No enemies found in workspace"
                status.TextColor3 = Color3.fromRGB(255, 100, 0)
            end
        end
    elseif string.find(command, "stop") or string.find(command, "cancel") then
        status.Text = "Auto-farm stopped"
        status.TextColor3 = Color3.fromRGB(0, 200, 0)
        stopAutoFarm()
    elseif string.find(command, "height") then
        local height = tonumber(string.match(command, "%d+"))
        if height then
            AutoFarmModule.Settings.FloatHeight = height
            status.Text = "Float height set to " .. height
            status.TextColor3 = Color3.fromRGB(0, 200, 0)
        else
            status.Text = "Invalid height value"
            status.TextColor3 = Color3.fromRGB(255, 100, 0)
        end
    elseif string.find(command, "speed") then
        local speed = tonumber(string.match(command, "%d+"))
        if speed then
            AutoFarmModule.Settings.FlySpeed = speed
            status.Text = "Fly speed set to " .. speed
            status.TextColor3 = Color3.fromRGB(0, 200, 0)
        else
            status.Text = "Invalid speed value"
            status.TextColor3 = Color3.fromRGB(255, 100, 0)
        end
    elseif string.find(command, "help") then
        status.Text = "Commands: auto farm [name], stop, height [num], speed [num]"
        status.TextColor3 = Color3.fromRGB(0, 200, 0)
    else
        status.Text = "Unknown command. Try: auto farm [name], stop"
        status.TextColor3 = Color3.fromRGB(255, 100, 0)
    end
    
    -- Clear the input after processing
    wait(0.1)
    input.Text = ""
end)

-- Make the frame draggable
local dragging = false
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

title.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Show notification on load
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Command Auto-Farm",
    Text = "Type 'auto farm [enemy name]' to start farming",
    Duration = 5
})

-- Check for enemies disappearing
game:GetService("RunService").Heartbeat:Connect(function()
    if isAutoFarmEnabled and selectedEnemy then
        if not selectedEnemy:IsDescendantOf(game.Workspace) or 
           not selectedEnemy:FindFirstChild("Humanoid") or 
           selectedEnemy.Humanoid.Health <= 0 then
            
            status.Text = "Target lost or defeated"
            status.TextColor3 = Color3.fromRGB(255, 100, 0)
            stopAutoFarm()
        end
    end
end)

-- Return the module if using as loadstring
return AutoFarmModule
