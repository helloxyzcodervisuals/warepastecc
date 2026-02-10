local LegitAimbotModule = {
    Enabled = false,
    Settings = {
        FOV = 120,
        Smoothness = 40,
        VisibleCheck = true,
        ForcefieldCheck = true,
        DownedCheck = true,
        DiedCheck = true,
        TeamCheck = true,
        AimKey = Enum.KeyCode.LeftAlt,
        UseKeybind = true
    },
    ArmChams = {
        Enabled = false,
        OriginalTransparency = {},
        OriginalMaterial = {},
        TransparencyValue = 0.5
    },
    ItemsChams = {
        Enabled = false,
        OriginalData = {},
        TransparencyValue = 0.5
    },
    Connection = nil
}

local function InitializeLegitAimbot()
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer
    local Camera = workspace.CurrentCamera
    
    local function GetViewModel()
        return Camera:FindFirstChild("ViewModel")
    end
    
    local function GetArms()
        local viewModel = GetViewModel()
        if not viewModel then return nil, nil end
        
        local rightArm = viewModel:FindFirstChild("Right Arm")
        local leftArm = viewModel:FindFirstChild("Left Arm")
        
        return rightArm, leftArm
    end
    
    local function ApplyArmChams()
        local rightArm, leftArm = GetArms()
        if not rightArm or not leftArm then return end
        
        for _, arm in pairs({rightArm, leftArm}) do
            if not LegitAimbotModule.ArmChams.OriginalTransparency[arm] then
                LegitAimbotModule.ArmChams.OriginalTransparency[arm] = arm.Transparency
                LegitAimbotModule.ArmChams.OriginalMaterial[arm] = arm.Material
            end
            
            arm.Transparency = LegitAimbotModule.ArmChams.TransparencyValue
            arm.Material = Enum.Material.ForceField
        end
    end
    
    local function RestoreArms()
        local rightArm, leftArm = GetArms()
        if not rightArm or not leftArm then return end
        
        for _, arm in pairs({rightArm, leftArm}) do
            if LegitAimbotModule.ArmChams.OriginalTransparency[arm] then
                arm.Transparency = LegitAimbotModule.ArmChams.OriginalTransparency[arm]
            end
            
            if LegitAimbotModule.ArmChams.OriginalMaterial[arm] then
                arm.Material = LegitAimbotModule.ArmChams.OriginalMaterial[arm]
            end
        end
    end
    
    local function UpdateArms()
        if LegitAimbotModule.ArmChams.Enabled then
            ApplyArmChams()
        else
            RestoreArms()
        end
    end
    
    local function ApplyItemsChams()
        for _, tool in ipairs(workspace:GetDescendants()) do
            if tool:IsA("Tool") then
                for _, part in ipairs(tool:GetDescendants()) do
                    if part:IsA("BasePart") then
                        if not LegitAimbotModule.ItemsChams.OriginalData[part] then
                            LegitAimbotModule.ItemsChams.OriginalData[part] = {
                                Transparency = part.Transparency,
                                Material = part.Material
                            }
                        end
                        
                        part.Transparency = LegitAimbotModule.ItemsChams.TransparencyValue
                        part.Material = Enum.Material.ForceField
                    end
                end
            end
        end
    end
    
    local function RestoreItemsChams()
        for part, data in pairs(LegitAimbotModule.ItemsChams.OriginalData) do
            if part and part.Parent then
                part.Transparency = data.Transparency
                part.Material = data.Material
            end
        end
        LegitAimbotModule.ItemsChams.OriginalData = {}
    end
    
    local function UpdateItemsChams()
        if LegitAimbotModule.ItemsChams.Enabled then
            ApplyItemsChams()
        else
            RestoreItemsChams()
        end
    end
    
    local function IsVisible(targetPart, origin)
        if not origin then
            origin = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
            if not origin then return false end
        end
        
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
        
        local direction = (targetPart.Position - origin.Position).Unit
        local raycastResult = workspace:Raycast(origin.Position, direction * 1000, raycastParams)
        
        if raycastResult then
            local hitPart = raycastResult.Instance
            local hitChar = hitPart:FindFirstAncestorOfClass("Model")
            return hitChar == targetPart.Parent
        end
        return true
    end

    local function HasForcefield(character)
        if not character then return false end
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("ForceField") then
                return true
            end
        end
        return false
    end

    local function GetHealth(character)
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            return humanoid.Health
        end
        return 100
    end

    local function IsAlive(character)
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            return humanoid.Health > 0
        end
        return false
    end

    local function GetClosestPlayer()
        local closest = nil
        local closestDist = LegitAimbotModule.Settings.FOV
        
        local camera = workspace.CurrentCamera
        local mousePos = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                if LegitAimbotModule.Settings.TeamCheck and player.Team == LocalPlayer.Team then
                    continue
                end
                
                local character = player.Character
                if character then
                    if LegitAimbotModule.Settings.DiedCheck and not IsAlive(character) then
                        continue
                    end
                    
                    if LegitAimbotModule.Settings.DownedCheck and GetHealth(character) < 15 then
                        continue
                    end
                    
                    if LegitAimbotModule.Settings.ForcefieldCheck and HasForcefield(character) then
                        continue
                    end
                    
                    local head = character:FindFirstChild("Head")
                    if head then
                        local screenPoint = camera:WorldToViewportPoint(head.Position)
                        if screenPoint.Z > 0 then
                            local screenPos = Vector2.new(screenPoint.X, screenPoint.Y)
                            local distance = (mousePos - screenPos).Magnitude
                            
                            if LegitAimbotModule.Settings.VisibleCheck and not IsVisible(head) then
                                continue
                            end
                            
                            if distance < closestDist then
                                closestDist = distance
                                closest = {player = player, character = character, head = head}
                            end
                        end
                    end
                end
            end
        end
        
        return closest
    end

    local function ShouldAim()
        if not LegitAimbotModule.Enabled then
            return false
        end
        
        if LegitAimbotModule.Settings.UseKeybind then
            return UserInputService:IsKeyDown(LegitAimbotModule.Settings.AimKey)
        else
            return true
        end
    end

    local function AimAssist()
        if not ShouldAim() then return end
        
        local targetData = GetClosestPlayer()
        if targetData then
            local camera = workspace.CurrentCamera
            
            local targetCFrame = CFrame.new(camera.CFrame.Position, targetData.head.Position)
            local currentCFrame = camera.CFrame
            
            local smoothFactor = (100 - LegitAimbotModule.Settings.Smoothness) / 100
            smoothFactor = math.max(smoothFactor, 0.01)
            
            local lerpCFrame = currentCFrame:Lerp(targetCFrame, smoothFactor * 0.1)
            
            camera.CFrame = lerpCFrame
        end
    end

    LegitAimbotModule.Connection = RunService.RenderStepped:Connect(function()
        if LegitAimbotModule.Enabled then
            AimAssist()
        end
        UpdateArms()
        UpdateItemsChams()
    end)

    game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        UpdateArms()
    end)

    

    workspace.DescendantAdded:Connect(function(descendant)
        if LegitAimbotModule.ItemsChams.Enabled and descendant:IsA("Tool") then
            task.wait()
            ApplyItemsChams()
        end
    end)
end

InitializeLegitAimbot()

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/helloxyzcodervisuals/warepastecc/refs/heads/main/warepastecc.lua"))()
local UI = Library:CreateWindow("Warepaste", UDim2.new(0, 650, 0, 750))
local Tab1 = UI:CreateTab("Legitbot")
local Sec1 = Tab1:CreateSection("Aimbot", "Left")
local Sec2 = Tab1:CreateSection("Visual", "Right")

Sec1:CreateToggle("Enable Legit Aimbot", false, function(v)
    LegitAimbotModule.Enabled = v
end)

Sec1:CreateToggle("Visible Check", true, function(v)
    LegitAimbotModule.Settings.VisibleCheck = v
end)

Sec1:CreateToggle("Forcefield Check", true, function(v)
    LegitAimbotModule.Settings.ForcefieldCheck = v
end)

Sec1:CreateToggle("Downed Check", true, function(v)
    LegitAimbotModule.Settings.DownedCheck = v
end)

Sec1:CreateToggle("Died Check", true, function(v)
    LegitAimbotModule.Settings.DiedCheck = v
end)

Sec1:CreateToggle("Team Check", true, function(v)
    LegitAimbotModule.Settings.TeamCheck = v
end)

Sec1:CreateToggle("Use Keybind", true, function(v)
    LegitAimbotModule.Settings.UseKeybind = v
end)

Sec1:CreateSlider("FOV Size", 0, 360, 120, "°", function(v)
    LegitAimbotModule.Settings.FOV = v
end)

Sec1:CreateSlider("Smoothness", 0, 100, 40, "%", function(v)
    LegitAimbotModule.Settings.Smoothness = v
end)

Sec1:CreateKeybind("Aimbot Key", Enum.KeyCode.LeftAlt, function(key)
    LegitAimbotModule.Settings.AimKey = key
end)

Sec1:CreateButton("Test Aimbot", function()
    print("Legit Aimbot Test")
end)

Sec2:CreateToggle("Arm Chams", false, function(v)
    LegitAimbotModule.ArmChams.Enabled = v
end)

Sec2:CreateSlider("Arm Transparency", 0, 1, 0.5, "", function(v)
    LegitAimbotModule.ArmChams.TransparencyValue = v
end)

Sec2:CreateToggle("Items Chams", false, function(v)
    LegitAimbotModule.ItemsChams.Enabled = v
end)

Sec2:CreateSlider("Items Transparency", 0, 1, 0.5, "", function(v)
    LegitAimbotModule.ItemsChams.TransparencyValue = v
end)

Sec2:CreateButton("Reset All Chams", function()
    LegitAimbotModule.ArmChams.Enabled = false
    LegitAimbotModule.ItemsChams.Enabled = false
    
    local rightArm, leftArm = GetArms()
    if rightArm and LegitAimbotModule.ArmChams.OriginalTransparency[rightArm] then
        rightArm.Transparency = LegitAimbotModule.ArmChams.OriginalTransparency[rightArm]
        rightArm.Material = LegitAimbotModule.ArmChams.OriginalMaterial[rightArm]
    end
    if leftArm and LegitAimbotModule.ArmChams.OriginalTransparency[leftArm] then
        leftArm.Transparency = LegitAimbotModule.ArmChams.OriginalTransparency[leftArm]
        leftArm.Material = LegitAimbotModule.ArmChams.OriginalMaterial[leftArm]
    end
    
    for part, data in pairs(LegitAimbotModule.ItemsChams.OriginalData) do
        if part and part.Parent then
            part.Transparency = data.Transparency
            part.Material = data.Material
        end
    end
    LegitAimbotModule.ItemsChams.OriginalData = {}
end)
local VisualModule = {
    ESP = {
        Enabled = false,
        Box = true,
        Name = true,
        Distance = true,
        Health = true,
        Tool = true,
        TeamColor = false,
        MaxDistance = 500,
        BoxColor = Color3.new(1, 1, 1),
        NameColor = Color3.new(1, 1, 1),
        DistanceColor = Color3.new(1, 1, 1),
        HealthColor = Color3.fromRGB(0, 255, 0),
        EnemyColor = Color3.fromRGB(255, 50, 50),
        FriendColor = Color3.fromRGB(0, 150, 255),
        TextSize = 14
    },
    PlayerChams = {
        Enabled = false,
        BoxChams = true,
        Color = Color3.fromRGB(170, 0, 255),
        BorderColor = Color3.new(1, 1, 1),
        Transparency = 0,
        BorderTransparency = 0.5,
        LightEnabled = true,
        GlowEnabled = true,
        WallCheck = true,
        WallColor = Color3.new(1, 1, 1),
        WallTransparency = 0.3
    }
}

local function InitializeVisuals()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local CoreGui = game:GetService("CoreGui")
    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera
    
    local l_1 = Players
    local l_4 = RunService
    local l_7 = CoreGui
    local l_8 = LocalPlayer
    local Camera = Camera
    
    local function vc()
        local v2 = "Font_" .. tostring(math.random(10000, 99999))
        local v24 = "Folder_" .. tostring(math.random(10000, 99999))
        if isfolder("UI_Fonts") then delfolder("UI_Fonts") end
        makefolder(v24)
        local v3 = v24 .. "/" .. v2 .. ".ttf"
        local v4 = v24 .. "/" .. v2 .. ".json"
        
        local success, body = pcall(function()
            return game:HttpGet("https://github.com/i77lhm/storage/blob/main/fonts/smallest_pixel-7.ttf?raw=true")
        end)
        
        if success then 
            writefile(v3, body) 
        else
            return Font.fromEnum(Enum.Font.Code)
        end

        local v16 = {
            name = v2,
            faces = {{
                name = "Regular",
                weight = 400,
                style = "Normal",
                assetId = getcustomasset(v3)
            }}
        }
        writefile(v4, game:GetService("HttpService"):JSONEncode(v16))
        VisualModule.Font = Font.new(getcustomasset(v4))
    end
    
    vc()
    
    local espParts = {}
    local chamParts = {}
    local connections = {}
    local espDrawings = {}
    
    local function createESP(player)
        if player == l_8 then return end
        if espDrawings[player] then return end

        local box = Drawing.new("Square")
        box.Visible = false
        box.Thickness = 1
        box.Filled = false
        box.Color = VisualModule.ESP.BoxColor
        box.Transparency = 1

        local sg = Instance.new("ScreenGui")
        sg.Name = player.Name .. "_ESP"
        sg.IgnoreGuiInset = true
        sg.Parent = l_7

        local infoLabel = Instance.new("TextLabel")
        infoLabel.BackgroundTransparency = 1
        infoLabel.TextColor3 = VisualModule.ESP.NameColor
        infoLabel.FontFace = VisualModule.Font or Font.fromEnum(Enum.Font.Code)
        infoLabel.TextSize = VisualModule.ESP.TextSize
        infoLabel.TextStrokeTransparency = 0
        infoLabel.Parent = sg

        local distLabel = Instance.new("TextLabel")
        distLabel.BackgroundTransparency = 1
        distLabel.TextColor3 = VisualModule.ESP.DistanceColor
        distLabel.FontFace = VisualModule.Font or Font.fromEnum(Enum.Font.Code)
        distLabel.TextSize = VisualModule.ESP.TextSize
        distLabel.TextStrokeTransparency = 0
        distLabel.Parent = sg

        local healthOutline = Instance.new("Frame")
        healthOutline.BackgroundColor3 = Color3.new(0, 0, 0)
        healthOutline.BorderSizePixel = 1
        healthOutline.BorderColor3 = Color3.new(0, 0, 0)
        healthOutline.Visible = false
        healthOutline.Parent = sg

        local healthFill = Instance.new("Frame")
        healthFill.BorderSizePixel = 0
        healthFill.Size = UDim2.new(1, 0, 1, 0)
        healthFill.Parent = healthOutline

        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 0)),
            ColorSequenceKeypoint.new(1, VisualModule.ESP.HealthColor)
        })
        gradient.Rotation = -90
        gradient.Parent = healthFill

        local connection
        connection = l_4.RenderStepped:Connect(function()
            if not VisualModule.ESP.Enabled then
                box.Visible = false
                infoLabel.Visible = false
                distLabel.Visible = false
                healthOutline.Visible = false
                return
            end
            
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")

            if hrp and hum and hum.Health > 0 then
                local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                if dist > VisualModule.ESP.MaxDistance then
                    box.Visible = false
                    infoLabel.Visible = false
                    distLabel.Visible = false
                    healthOutline.Visible = false
                    return
                end
                
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local sizeX, sizeY = 2000/dist, 3500/dist
                    local topY = pos.Y - sizeY/2
                    local bottomY = pos.Y + sizeY/2
                    local tool = char:FindFirstChildOfClass("Tool")
                    local toolName = tool and tool.Name or "None"

                    box.Visible = VisualModule.ESP.Box
                    box.Position = Vector2.new(pos.X - sizeX/2, topY)
                    box.Size = Vector2.new(sizeX, sizeY)
                    
                    if VisualModule.ESP.TeamColor then
                        if player.Team == l_8.Team then
                            box.Color = VisualModule.ESP.FriendColor
                            infoLabel.TextColor3 = VisualModule.ESP.FriendColor
                            distLabel.TextColor3 = VisualModule.ESP.FriendColor
                        else
                            box.Color = VisualModule.ESP.EnemyColor
                            infoLabel.TextColor3 = VisualModule.ESP.EnemyColor
                            distLabel.TextColor3 = VisualModule.ESP.EnemyColor
                        end
                    else
                        box.Color = VisualModule.ESP.BoxColor
                        infoLabel.TextColor3 = VisualModule.ESP.NameColor
                        distLabel.TextColor3 = VisualModule.ESP.DistanceColor
                    end

                    infoLabel.Visible = VisualModule.ESP.Name
                    infoLabel.Text = player.Name .. (VisualModule.ESP.Tool and " [" .. toolName .. "]" or "")
                    infoLabel.Position = UDim2.new(0, pos.X, 0, topY - 20)

                    distLabel.Visible = VisualModule.ESP.Distance
                    distLabel.Text = math.floor(dist) .. "ft"
                    distLabel.Position = UDim2.new(0, pos.X, 0, bottomY + 8)

                    healthOutline.Visible = VisualModule.ESP.Health
                    healthOutline.Position = UDim2.new(0, (pos.X - sizeX/2) - 6, 0, topY)
                    healthOutline.Size = UDim2.new(0, 3, 0, sizeY)

                    local hpPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    healthFill.Size = UDim2.new(1, 0, hpPercent, 0)
                    healthFill.Position = UDim2.new(0, 0, 1 - hpPercent, 0)
                    return
                end
            end
            box.Visible = false
            infoLabel.Visible = false
            distLabel.Visible = false
            healthOutline.Visible = false
        end)

        espDrawings[player] = {
            box = box,
            gui = sg,
            infoLabel = infoLabel,
            distLabel = distLabel,
            healthOutline = healthOutline,
            connection = connection
        }

        player.AncestryChanged:Connect(function()
            if not player:IsDescendantOf(l_1) then
                if espDrawings[player] then
                    espDrawings[player].box:Remove()
                    espDrawings[player].gui:Destroy()
                    espDrawings[player].connection:Disconnect()
                    espDrawings[player] = nil
                end
            end
        end)
    end
    
    local function createChams(character)
        if not VisualModule.PlayerChams.Enabled then return end
        if chamParts[character] then return end
        
        local boxes = {}
        
        local bodyParts = {
            "Head",
            "Torso", 
            "Left Arm",
            "Right Arm",
            "Left Leg",
            "Right Leg"
        }
        
        for _, partName in ipairs(bodyParts) do
            local originalPart = character:FindFirstChild(partName)
            if originalPart and originalPart:IsA("BasePart") then
                local box = Instance.new("BoxHandleAdornment")
                box.Name = "ChamsBox"
                box.Adornee = originalPart
                box.AlwaysOnTop = true
                box.ZIndex = 1
                box.Size = originalPart.Size
                box.Transparency = VisualModule.PlayerChams.Transparency
                box.Color3 = VisualModule.PlayerChams.Color
                
                local whiteBorder = Instance.new("BoxHandleAdornment")
                whiteBorder.Name = "ChamsBorder"
                whiteBorder.Adornee = originalPart
                whiteBorder.AlwaysOnTop = true
                whiteBorder.ZIndex = 0
                whiteBorder.Size = originalPart.Size + Vector3.new(0.05, 0.05, 0.05)
                whiteBorder.Transparency = VisualModule.PlayerChams.BorderTransparency
                whiteBorder.Color3 = VisualModule.PlayerChams.BorderColor
                
                if VisualModule.PlayerChams.LightEnabled then
                    local pointLight = Instance.new("PointLight")
                    pointLight.Name = "ChamsLight"
                    pointLight.Parent = box
                    pointLight.Brightness = 1.2
                    pointLight.Range = 8
                    pointLight.Shadows = false
                    pointLight.Color = VisualModule.PlayerChams.Color
                end
                
                if VisualModule.PlayerChams.GlowEnabled then
                    local bloomEffect = Instance.new("BloomEffect")
                    bloomEffect.Name = "ChamsGlow"
                    bloomEffect.Parent = box
                    bloomEffect.Intensity = 0.15
                    bloomEffect.Size = 12
                    bloomEffect.Threshold = 0.9
                end
                
                box.Parent = character
                whiteBorder.Parent = character
                
                table.insert(boxes, {box = box, border = whiteBorder})
            end
        end
        
        chamParts[character] = boxes
    end
    
    local function updateChams()
        for character, boxes in pairs(chamParts) do
            if character and character:IsDescendantOf(Workspace) then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    local rootPart = character:FindFirstChild("HumanoidRootPart")
                    if rootPart then
                        local isBehindWall = false
                        
                        if VisualModule.PlayerChams.WallCheck then
                            local raycastParams = RaycastParams.new()
                            raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                            raycastParams.FilterDescendantsInstances = {character, camera}
                            raycastParams.IgnoreWater = true
                            
                            local origin = camera.CFrame.Position
                            local direction = (rootPart.Position - origin).Unit * 500
                            local raycastResult = Workspace:Raycast(origin, direction, raycastParams)
                            
                            if raycastResult then
                                local hitParent = raycastResult.Instance:GetFullName()
                                local targetParent = character:GetFullName()
                                if not string.find(hitParent, targetParent) then
                                    isBehindWall = true
                                end
                            end
                        end
                        
                        for _, boxData in ipairs(boxes) do
                            if boxData.box.Adornee and boxData.box.Adornee:IsDescendantOf(Workspace) then
                                if isBehindWall then
                                    boxData.box.Visible = false
                                    boxData.border.Color3 = VisualModule.PlayerChams.WallColor
                                    boxData.border.Transparency = VisualModule.PlayerChams.WallTransparency
                                    boxData.border.Visible = true
                                else
                                    boxData.box.Visible = VisualModule.PlayerChams.BoxChams
                                    boxData.box.Color3 = VisualModule.PlayerChams.Color
                                    boxData.box.Transparency = VisualModule.PlayerChams.Transparency
                                    boxData.border.Color3 = VisualModule.PlayerChams.BorderColor
                                    boxData.border.Transparency = VisualModule.PlayerChams.BorderTransparency
                                    boxData.border.Visible = true
                                end
                                
                                boxData.box.Size = boxData.box.Adornee.Size
                                boxData.border.Size = boxData.box.Adornee.Size + Vector3.new(0.05, 0.05, 0.05)
                            end
                        end
                    end
                else
                    for _, boxData in ipairs(boxes) do
                        boxData.box:Destroy()
                        boxData.border:Destroy()
                    end
                    chamParts[character] = nil
                end
            else
                for _, boxData in ipairs(boxes) do
                    boxData.box:Destroy()
                    boxData.border:Destroy()
                end
                chamParts[character] = nil
            end
        end
    end
    
    local function onPlayerAdded(player)
        if player ~= LocalPlayer then
            local function characterAdded(character)
                task.wait(1)
                createESP(player)
                createChams(character)
            end
            
            if player.Character then
                characterAdded(player.Character)
            end
            
            table.insert(connections, player.CharacterAdded:Connect(characterAdded))
        end
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end
    
    table.insert(connections, Players.PlayerAdded:Connect(onPlayerAdded))
    
    table.insert(connections, Players.PlayerRemoving:Connect(function(player)
        if espDrawings[player] then
            espDrawings[player].box:Remove()
            espDrawings[player].gui:Destroy()
            espDrawings[player].connection:Disconnect()
            espDrawings[player] = nil
        end
        
        local character = player.Character
        if character and chamParts[character] then
            for _, boxData in ipairs(chamParts[character]) do
                boxData.box:Destroy()
                boxData.border:Destroy()
            end
            chamParts[character] = nil
        end
    end))
    
    local updateConnection = RunService.RenderStepped:Connect(function()
        if VisualModule.PlayerChams.Enabled then
            updateChams()
        end
    end)
    
    table.insert(connections, updateConnection)
    
    local function cleanup()
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        
        for player, drawing in pairs(espDrawings) do
            drawing.box:Remove()
            drawing.gui:Destroy()
            drawing.connection:Disconnect()
        end
        
        for character, boxes in pairs(chamParts) do
            for _, boxData in ipairs(boxes) do
                boxData.box:Destroy()
                boxData.border:Destroy()
            end
        end
    end
    
    return cleanup
end

local cleanupVisuals = InitializeVisuals()
local Tab1 = UI:CreateTab("Visuals")
local Sec1 = Tab1:CreateSection("ESP", "Left")

Sec1:CreateToggle("Enable ESP", false, function(v)
    VisualModule.ESP.Enabled = v
end)

Sec1:CreateToggle("Box ESP", true, function(v)
    VisualModule.ESP.Box = v
end)

Sec1:CreateToggle("Name ESP", true, function(v)
    VisualModule.ESP.Name = v
end)

Sec1:CreateToggle("Distance ESP", true, function(v)
    VisualModule.ESP.Distance = v
end)

Sec1:CreateToggle("Health ESP", true, function(v)
    VisualModule.ESP.Health = v
end)

Sec1:CreateToggle("Tool ESP", true, function(v)
    VisualModule.ESP.Tool = v
end)

Sec1:CreateToggle("Team Colors", false, function(v)
    VisualModule.ESP.TeamColor = v
end)

Sec1:CreateSlider("Max Distance", 0, 1000, 500, "ft", function(v)
    VisualModule.ESP.MaxDistance = v
end)

Sec1:CreateSlider("Text Size", 10, 20, 14, "", function(v)
    VisualModule.ESP.TextSize = v
end)

Sec1:CreateColorpicker("Box Color", Color3.new(1, 1, 1), function(c)
    VisualModule.ESP.BoxColor = c
end)

Sec1:CreateColorpicker("Name Color", Color3.new(1, 1, 1), function(c)
    VisualModule.ESP.NameColor = c
end)

Sec1:CreateColorpicker("Distance Color", Color3.new(1, 1, 1), function(c)
    VisualModule.ESP.DistanceColor = c
end)

Sec1:CreateColorpicker("Health Color", Color3.fromRGB(0, 255, 0), function(c)
    VisualModule.ESP.HealthColor = c
end)

Sec1:CreateColorpicker("Enemy Color", Color3.fromRGB(255, 50, 50), function(c)
    VisualModule.ESP.EnemyColor = c
end)

Sec1:CreateColorpicker("Friend Color", Color3.fromRGB(0, 150, 255), function(c)
    VisualModule.ESP.FriendColor = c
end)

local Sec2 = Tab1:CreateSection("Player Chams", "Right")

Sec2:CreateToggle("Enable Chams", false, function(v)
    VisualModule.PlayerChams.Enabled = v
end)

Sec2:CreateToggle("Box Chams", true, function(v)
    VisualModule.PlayerChams.BoxChams = v
end)

Sec2:CreateToggle("Wall Check", true, function(v)
    VisualModule.PlayerChams.WallCheck = v
end)

Sec2:CreateToggle("Light Effect", true, function(v)
    VisualModule.PlayerChams.LightEnabled = v
end)

Sec2:CreateToggle("Glow Effect", true, function(v)
    VisualModule.PlayerChams.GlowEnabled = v
end)

Sec2:CreateSlider("Transparency", 0, 1, 0, "", function(v)
    VisualModule.PlayerChams.Transparency = v
end)

Sec2:CreateSlider("Border Transparency", 0, 1, 0.5, "", function(v)
    VisualModule.PlayerChams.BorderTransparency = v
end)

Sec2:CreateSlider("Wall Transparency", 0, 1, 0.3, "", function(v)
    VisualModule.PlayerChams.WallTransparency = v
end)

Sec2:CreateColorpicker("Chams Color", Color3.fromRGB(170, 0, 255), function(c)
    VisualModule.PlayerChams.Color = c
end)

Sec2:CreateColorpicker("Border Color", Color3.new(1, 1, 1), function(c)
    VisualModule.PlayerChams.BorderColor = c
end)

Sec2:CreateColorpicker("Wall Color", Color3.new(1, 1, 1), function(c)
    VisualModule.PlayerChams.WallColor = c
end)

Sec2:CreateButton("Refresh Visuals", function()
    if cleanupVisuals then
        cleanupVisuals()
    end
    InitializeVisuals()
end)
