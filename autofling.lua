local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local TOGGLE_KEY = 0xC0 -- Backtick (`) for AutoFling toggle
local TELEPORT_KEY = 0xDD -- Virtual key code for ']' (OEM_6 / right bracket)

local DwellTime = 0.5   
local DefaultHeights = {3, 2, 1}
local SpinSpeed = 75    
local DangerClearance = 15 
local DangerLingerTime = 0.4 

local ExcludedPlayers = {
    "WRKN99", "Aim_Motion", "67rizzlerauratung", "67RIZZLERAURATUNG67",
    "IAM_LEG1T", "Dustoduck", "9_vtx", "1wa_rf", "Vedh00", 
    "ZHR_Azure", "sai_trarun", "Baconrivalpro23", "ILIKETOAIMBOT12367", "razerviper01", "ziyfin101", "HxzeRL", "Lollolol910"
}

local scriptActive = false -- Boots up toggled OFF on auto-execute
local keyWasDown = false
local wasActive = false

-- Teleport state variables
local isTeleportedOut = false
local savedPosition = nil
local savedCameraCF = nil
local tpKeyWasDown = false

print("[AutoFling] Script Status: 🔴 OFF (Press '`' to Toggle)")

-- Create the Rage status text object on screen
local rageStatusText = Drawing.new("Text")
rageStatusText.Visible = true
rageStatusText.Size = 24
rageStatusText.Center = false
rageStatusText.Outline = true
rageStatusText.Position = Vector2.new(15, 1050)

-- Create the Teleport status text object beside it
local tpStatusText = Drawing.new("Text")
tpStatusText.Visible = true
tpStatusText.Size = 24
tpStatusText.Center = false
tpStatusText.Outline = true
tpStatusText.Position = Vector2.new(180, 1050)

-- Safe position helper
local function getObjectPosition(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then
        return obj.Position
    elseif obj:IsA("Model") then
        return obj:GetPivot().Position
    elseif obj:IsA("Attachment") then
        return obj.WorldPosition
    elseif obj.Position and typeof(obj.Position) == "Vector3" then
        return obj.Position
    elseif obj.CFrame and typeof(obj.CFrame) == "CFrame" then
        return obj.CFrame.Position
    end
    return nil
end

-- Fast check for weapons using ViewModels format
local function playerHasWeapon(playerName, weaponKeyword)
    local ViewModels = Workspace:FindFirstChild("ViewModels")
    if not ViewModels then return false end
    
    for _, child in ipairs(ViewModels:GetChildren()) do
        local nameParts = string.split(child.Name, "-")
        if #nameParts >= 3 then
            local vmPlayerName = nameParts[1]:gsub("^%s*(.-)%s*$", "%1")
            local weaponName = nameParts[3]:gsub("^%s*(.-)%s*$", "%1"):lower()
            
            if vmPlayerName:lower() == playerName:lower() and string.find(weaponName, weaponKeyword, 1, true) then
                return true
            end
        end
    end
    return false
end

local function playerHasChainsaw(playerName)
    return playerHasWeapon(playerName, "chainsaw")
end

local function playerHasExplosive(playerName)
    return playerHasWeapon(playerName, "rpg") or playerHasWeapon(playerName, "grenade") or playerHasWeapon(playerName, "launcher")
end

local function getClosestTripmineDistance(targetPos)
    local tripmineFolder = Workspace:FindFirstChild("SubspaceTripmineHitbox")
    if not tripmineFolder then return 9999 end
    
    local minDistance = 9999
    local mainPos = getObjectPosition(tripmineFolder)
    if mainPos then
        local dist = (targetPos - mainPos).Magnitude
        if dist < minDistance then minDistance = dist end
    end
    
    for _, child in ipairs(tripmineFolder:GetDescendants()) do
        local childPos = getObjectPosition(child)
        if childPos then
            local dist = (targetPos - childPos).Magnitude
            if dist < minDistance then minDistance = dist end
        end
    end
    return minDistance
end

local function isExcluded(playerName)
    local targetLower = playerName:lower()
    for _, name in ipairs(ExcludedPlayers) do
        if name:lower() == targetLower then return true end
    end
    return false
end

local function isTeammate(targetPlayer)
    if LocalPlayer.Team and targetPlayer.Team then
        return LocalPlayer.Team == targetPlayer.Team
    end
    return false
end

local function getValidTargets()
    local validList = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not isExcluded(player.Name) and not isTeammate(player) and player.Character then
            local targetChar = player.Character
            local rootPart = targetChar:FindFirstChild("HumanoidRootPart")
            local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 and rootPart then
                table.insert(validList, player)
            end
        end
    end
    return validList
end

local currentTarget = nil
local targetSwitchTimer = 0
local heightIndex = 1
local currentAngle = 0
local lastDangerTime = 0

-- Main Control Loop with Input Checking & Roblox Active State Handling
task.spawn(function()
    while true do
        local isActive = true
        pcall(function()
            if isrbxactive then isActive = isrbxactive() end
        end)

        if isActive then
            pcall(function()
                if setrobloxinput then setrobloxinput(true) end
            end)

            local keyIsDown = false
            local tpKeyIsDown = false
            pcall(function()
                if iskeypressed then 
                    keyIsDown = iskeypressed(TOGGLE_KEY) 
                    tpKeyIsDown = iskeypressed(TELEPORT_KEY)
                end
            end)

            -- Handle Backtick (`) Toggle
            if not wasActive then
                keyWasDown = keyIsDown
                tpKeyWasDown = tpKeyIsDown
            else
                if keyIsDown and not keyWasDown then
                    print("toggle detected")
                    scriptActive = not scriptActive
                    if scriptActive then
                        print("[AutoFling] Status: 🟢 ENABLED")
                    else
                        print("[AutoFling] Status: 🔴 DISABLED")
                    end
                end
                keyWasDown = keyIsDown

                -- Handle ']' Teleport Toggle
                if tpKeyIsDown and not tpKeyWasDown then
                    local char = LocalPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if root then
                        if not isTeleportedOut then
                            -- Save current position/CFrame and camera position, then shift 50,000 studs to the right
                            savedPosition = root.CFrame
                            savedCameraCF = Camera.CFrame
                            
                            local rightVector = Camera.CFrame.RightVector
                            local targetCF = savedPosition + (rightVector * 50000)
                            
                            root.CFrame = targetCF
                            Camera.CFrame = savedCameraCF + (rightVector * 50000)
                            
                            isTeleportedOut = true
                            print("[Teleport] 🚀 Shifted character & camera 50,000 studs right!")
                        else
                            -- Return to saved position and camera
                            if savedPosition then
                                root.CFrame = savedPosition
                            end
                            if savedCameraCF then
                                Camera.CFrame = savedCameraCF
                            end
                            isTeleportedOut = false
                            print("[Teleport] 🏠 Returned to original position & camera!")
                        end
                    end
                end
                tpKeyWasDown = tpKeyIsDown
            end
        else
            pcall(function()
                if setrobloxinput then setrobloxinput(false) end
            end)
            keyWasDown = false
            tpKeyWasDown = false
        end

        -- If actively teleported out, enforce the hold position & camera offset
        if isTeleportedOut then
            pcall(function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root and savedPosition and savedCameraCF then
                    local rightVector = Camera.CFrame.RightVector
                    root.CFrame = savedPosition + (rightVector * 50000)
                    Camera.CFrame = savedCameraCF + (rightVector * 50000)
                end
            end)
            task.wait(0.25) -- 4 times a second
        else
            task.wait(0.05)
        end

        wasActive = isActive
    end
end)

-- Real-time UI Text Status Loop
RunService.RenderStepped:Connect(function()
    -- Rage Status UI Update
    if scriptActive then
        rageStatusText.Text = "Rage: [ON]"
        rageStatusText.Color = Color3.fromRGB(0, 255, 0) -- Green for ON
    else
        rageStatusText.Text = "Rage: [OFF]"
        rageStatusText.Color = Color3.fromRGB(255, 50, 50) -- Red for OFF
    end

    -- Teleport Status UI Update
    if isTeleportedOut then
        tpStatusText.Text = "TP: [AWAY]"
        tpStatusText.Color = Color3.fromRGB(255, 165, 0) -- Orange when phased out
    else
        tpStatusText.Text = "TP: [READY]"
        tpStatusText.Color = Color3.fromRGB(0, 255, 255) -- Cyan when ready at home
    end
end)

-- Main Fling & Safety Loop
RunService.RenderStepped:Connect(function(dt)
    if not scriptActive then return end
    if isTeleportedOut then return end -- Don't run fling logic while phased away

    local myChar = LocalPlayer.Character
    local myHumanoid = myChar and myChar:FindFirstChildOfClass("Humanoid")
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    
    if not myChar or not myHumanoid or not myRoot or myHumanoid.Health <= 0 then 
        return 
    end
    
    local targets = getValidTargets()
    if #targets == 0 then 
        currentTarget = nil
        return 
    end
    
    local now = tick()
    local targetIsInvalid = true
    if currentTarget and currentTarget.Character then
        local hum = currentTarget.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then targetIsInvalid = false end
    end
    
    if targetIsInvalid or (now - targetSwitchTimer >= DwellTime) then
        local nextIndex = 1
        if currentTarget then
            for i, p in ipairs(targets) do
                if p == currentTarget then
                    nextIndex = (i % #targets) + 1
                    break
                end
            end
        end
        currentTarget = targets[nextIndex]
        targetSwitchTimer = now
    end
    
    local currentHeightOffset = 0
    if currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild("HumanoidRootPart") then
        local targetRootPos = currentTarget.Character.HumanoidRootPart.Position
        local hasChainsaw = playerHasChainsaw(currentTarget.Name)
        local hasExplosive = playerHasExplosive(currentTarget.Name)
        local tripmineDist = getClosestTripmineDistance(targetRootPos)
        
        if hasChainsaw or hasExplosive or tripmineDist < DangerClearance then
            lastDangerTime = now 
        end
        
        if hasChainsaw or hasExplosive or (now - lastDangerTime <= DangerLingerTime) then
            currentHeightOffset = DangerClearance 
        else
            heightIndex = (heightIndex % #DefaultHeights) + 1
            currentHeightOffset = DefaultHeights[heightIndex]
        end
    end
    
    currentAngle = currentAngle + (SpinSpeed * dt)
    
    if currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild("HumanoidRootPart") then
        local targetRoot = currentTarget.Character.HumanoidRootPart
        local jitterX = math.random(-30, 30) / 100
        local jitterZ = math.random(-30, 30) / 100
        
        myRoot.CFrame = targetRoot.CFrame * CFrame.new(jitterX, currentHeightOffset, jitterZ) * CFrame.Angles(0, currentAngle, 0)
    end
end)
