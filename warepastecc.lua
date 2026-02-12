local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Library = {
    Flags = {},
    Theme = {
        Main = Color3.fromRGB(20, 20, 23),
        OuterOutline = Color3.fromRGB(65, 65, 70),
        InnerOutline = Color3.fromRGB(45, 45, 50),
        Accent = Color3.fromRGB(255, 100, 150),
        Text = Color3.fromRGB(220, 220, 220),
        SectionInlay = Color3.fromRGB(15, 15, 18)
    }
}
Library.__index = Library

local function Create(class, props)
    local inst = Instance.new(class)
    for i, v in next, props do inst[i] = v end
    return inst
end

local function GetFont(name, file)
    if not isfile(file) then 
        writefile(file, game:HttpGet("https://github.com/rylepm/" .. file)) 
    end
    local Data = {name = name, faces = {{name = "Normal", weight = 400, style = "Normal", assetId = getcustomasset(file)}}}
    writefile(name .. ".font", HttpService:JSONEncode(Data))
    return Font.new(getcustomasset(name .. ".font"))
end

Library.Font = GetFont("ProggyClean", "ProggyClean.ttf")
Library.SectionFont = GetFont("TahomaBold", "tahoma_bold.ttf")

local function ApplyShadow(parent)
    return Create("UIGradient", {
        Parent = parent, Rotation = 90,
        Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(160, 160, 160))
    })
end

function Library:CreateWindow(Title, Size)
    local Screen = Create("ScreenGui", {Parent = game.CoreGui, ResetOnSpawn = false, Name = "warepaste"})
    local Mainframe = Create("Frame", {Parent = Screen, Size = Size or UDim2.new(0, 520, 0, 420), Position = UDim2.new(0.5, -260, 0.5, -210), BackgroundColor3 = Library.Theme.OuterOutline, BorderSizePixel = 0})
    local Main = Create("Frame", {Parent = Mainframe, Size = UDim2.new(1, -4, 1, -4), Position = UDim2.new(0, 2, 0, 2), BackgroundColor3 = Library.Theme.Main, BorderSizePixel = 0})
    Create("Frame", {Parent = Main, Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Library.Theme.Accent, BorderSizePixel = 0})
    local TabHolder = Create("Frame", {Parent = Main, Size = UDim2.new(1, -40, 0, 30), Position = UDim2.new(0, 20, 0, 20), BackgroundColor3 = Library.Theme.SectionInlay, BorderSizePixel = 1, BorderColor3 = Library.Theme.InnerOutline})
    local Container = Create("Frame", {Parent = Main, Size = UDim2.new(1, -40, 1, -80), Position = UDim2.new(0, 20, 0, 60), BackgroundColor3 = Library.Theme.SectionInlay, BorderSizePixel = 1, BorderColor3 = Library.Theme.InnerOutline})
    local Window = {Tabs = {}, Count = 0}

    local dragging = false
    local dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        Mainframe.Position = UDim2.new(0, startPos.X.Offset + delta.X, 0, startPos.Y.Offset + delta.Y)
    end
    Main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Mainframe.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    Main.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input == dragInput) then
            update(input)
        end
    end)

    function Window:CreateTab(Name)
        Window.Count = Window.Count + 1
        local TabBtn = Create("TextButton", {
            Parent = TabHolder, 
            Text = Name:upper(), 
            FontFace = Library.Font, 
            TextSize = 13, 
            TextColor3 = Color3.fromRGB(130, 130, 130), 
            BackgroundTransparency = 1, 
            BorderSizePixel = 0, 
            AutoButtonColor = false,
            Size = UDim2.new(1/Window.Count, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0)
        })
        local Underline = Create("Frame", {
            Parent = TabBtn, 
            Size = UDim2.new(1, 0, 0, 2), 
            Position = UDim2.new(0, 0, 1, -2), 
            BackgroundColor3 = Library.Theme.Accent, 
            BackgroundTransparency = 1, 
            BorderSizePixel = 0
        })
        local Page = Create("Frame", {
            Parent = Container, 
            Size = UDim2.new(1, 0, 1, 0), 
            BackgroundTransparency = 1, 
            Visible = false
        })
        local LeftCol = Create("ScrollingFrame", {
            Parent = Page, 
            Size = UDim2.new(0.5, -15, 1, -20), 
            Position = UDim2.new(0, 10, 0, 10), 
            BackgroundTransparency = 1, 
            ScrollBarThickness = 0, 
            AutomaticCanvasSize = "Y"
        })
        local RightCol = Create("ScrollingFrame", {
            Parent = Page, 
            Size = UDim2.new(0.5, -15, 1, -20), 
            Position = UDim2.new(0.5, 5, 0, 10), 
            BackgroundTransparency = 1, 
            ScrollBarThickness = 0, 
            AutomaticCanvasSize = "Y"
        })
        Create("UIListLayout", {Parent = LeftCol, Padding = UDim.new(0, 12)})
        Create("UIListLayout", {Parent = RightCol, Padding = UDim.new(0, 12)})

        local function ResizeTabs()
            for i, btn in ipairs(TabHolder:GetChildren()) do
                if btn:IsA("TextButton") then
                    btn.Size = UDim2.new(1/Window.Count, 0, 1, 0)
                    btn.Position = UDim2.new((i-1)/Window.Count, 0, 0, 0)
                end
            end
        end
        
        local function Activate()
            for _, t in next, Window.Tabs do 
                t.Page.Visible = false 
                t.Underline.BackgroundTransparency = 1 
                t.Button.TextColor3 = Color3.fromRGB(130, 130, 130) 
            end
            Page.Visible = true 
            Underline.BackgroundTransparency = 0 
            TabBtn.TextColor3 = Color3.new(1, 1, 1)
        end
        
        TabBtn.Activated:Connect(Activate)
        TabBtn.AncestryChanged:Connect(ResizeTabs)
        
        local Tab = {Page = Page, Underline = Underline, Button = TabBtn}
        table.insert(Window.Tabs, Tab)
        
        ResizeTabs()
        if Window.Count == 1 then Activate() end
        
        function Tab:CreateSection(Title, Side)
            local Parent = (Side == "Right") and RightCol or LeftCol
            local SecMain = Create("Frame", {
                Parent = Parent, 
                Size = UDim2.new(1, 0, 0, 0), 
                BackgroundColor3 = Library.Theme.Main, 
                BorderSizePixel = 1, 
                BorderColor3 = Library.Theme.InnerOutline, 
                AutomaticSize = "Y"
            })
            local SecTitle = Create("TextLabel", {
                Parent = SecMain, 
                Text = "  " .. Title, 
                Size = UDim2.new(1, 0, 0, 24), 
                BackgroundColor3 = Library.Theme.SectionInlay, 
                FontFace = Library.SectionFont, 
                TextSize = 14, 
                TextColor3 = Library.Theme.Accent, 
                TextXAlignment = "Left"
            })
            ApplyShadow(SecTitle)
            local SecContent = Create("Frame", {
                Parent = SecMain, 
                Size = UDim2.new(1, 0, 0, 0), 
                Position = UDim2.new(0, 0, 0, 24), 
                BackgroundTransparency = 1, 
                AutomaticSize = "Y"
            })
            Create("UIListLayout", {Parent = SecContent, Padding = UDim.new(0, 8)})
            Create("UIPadding", {
                Parent = SecContent, 
                PaddingLeft = UDim.new(0, 10), 
                PaddingRight = UDim.new(0, 10), 
                PaddingTop = UDim.new(0, 8), 
                PaddingBottom = UDim.new(0, 8)
            })

            local Section = {}
            
            function Section:CreateLabel(Text)
                return Create("TextLabel", {
                    Parent = SecContent, 
                    Text = Text, 
                    Size = UDim2.new(1, 0, 0, 16), 
                    BackgroundTransparency = 1, 
                    TextColor3 = Library.Theme.Text, 
                    FontFace = Library.Font, 
                    TextSize = 13, 
                    TextXAlignment = "Left"
                })
            end

            function Section:CreateToggle(Text, Default, Callback)
                local Flag = Text:gsub("%s+", "")
                Library.Flags[Flag] = Default
                local Tgl = Create("TextButton", {
                    Parent = SecContent, 
                    Size = UDim2.new(1, 0, 0, 22), 
                    BackgroundColor3 = Library.Theme.SectionInlay, 
                    Text = "", 
                    BorderSizePixel = 1, 
                    BorderColor3 = Library.Theme.InnerOutline, 
                    AutoButtonColor = false
                })
                ApplyShadow(Tgl)
                Create("TextLabel", {
                    Parent = Tgl, 
                    Text = " " .. Text, 
                    Size = UDim2.new(1, -30, 1, 0), 
                    BackgroundTransparency = 1, 
                    TextColor3 = Library.Theme.Text, 
                    FontFace = Library.Font, 
                    TextSize = 13, 
                    TextXAlignment = "Left"
                })
                local Box = Create("Frame", {
                    Parent = Tgl, 
                    Size = UDim2.new(0, 12, 0, 12), 
                    Position = UDim2.new(1, -15, 0.5, -6), 
                    BackgroundColor3 = Default and Library.Theme.Accent or Library.Theme.InnerOutline, 
                    BorderSizePixel = 0
                })
                ApplyShadow(Box)
                Tgl.Activated:Connect(function() 
                    Library.Flags[Flag] = not Library.Flags[Flag] 
                    Default = Library.Flags[Flag]
                    Box.BackgroundColor3 = Default and Library.Theme.Accent or Library.Theme.InnerOutline 
                    Callback(Default) 
                end)
                return {Toggle = function() Library.Flags[Flag] = not Library.Flags[Flag] Default = Library.Flags[Flag] Box.BackgroundColor3 = Default and Library.Theme.Accent or Library.Theme.InnerOutline Callback(Default) end}
            end

            function Section:CreateSlider(Text, Min, Max, Default, Suffix, Callback)
                local Flag = Text:gsub("%s+", "")
                Library.Flags[Flag] = Default
                local Sld = Create("Frame", {
                    Parent = SecContent, 
                    Size = UDim2.new(1, 0, 0, 30), 
                    BackgroundTransparency = 1
                })
                Create("TextLabel", {
                    Parent = Sld, 
                    Text = Text, 
                    Size = UDim2.new(1, 0, 0, 16), 
                    BackgroundTransparency = 1, 
                    TextColor3 = Library.Theme.Text, 
                    FontFace = Library.Font, 
                    TextSize = 13, 
                    TextXAlignment = "Left"
                })
                local Tray = Create("Frame", {
                    Parent = Sld, 
                    Size = UDim2.new(1, 0, 0, 4), 
                    Position = UDim2.new(0, 0, 0, 20), 
                    BackgroundColor3 = Library.Theme.SectionInlay, 
                    BorderSizePixel = 1, 
                    BorderColor3 = Library.Theme.InnerOutline
                })
                ApplyShadow(Tray)
                local Fill = Create("Frame", {
                    Parent = Tray, 
                    Size = UDim2.new((Default - Min) / (Max - Min), 0, 1, 0), 
                    BackgroundColor3 = Library.Theme.Accent, 
                    BorderSizePixel = 0
                })
                ApplyShadow(Fill)
                local ValueText = Create("TextLabel", {
                    Parent = Sld, 
                    Text = tostring(Default) .. Suffix, 
                    Size = UDim2.new(0, 0, 0, 12), 
                    Position = UDim2.new((Default - Min) / (Max - Min), 0, 0, 22), 
                    AnchorPoint = Vector2.new(0.5, 0), 
                    BackgroundTransparency = 1, 
                    TextColor3 = Color3.new(1, 1, 1), 
                    FontFace = Library.Font, 
                    TextSize = 10, 
                    ZIndex = 10, 
                    AutomaticSize = "X"
                })
                local function Update(input)
                    local pos = math.clamp((input.Position.X - Tray.AbsolutePosition.X) / Tray.AbsoluteSize.X, 0, 1)
                    local val = math.floor(Min + (Max - Min) * pos)
                    Fill.Size = UDim2.new(pos, 0, 1, 0)
                    ValueText.Position = UDim2.new(pos, 0, 0, 22)
                    ValueText.Text = tostring(val) .. Suffix
                    Library.Flags[Flag] = val
                    Callback(val)
                end
                local dragging = false
                Tray.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true Update(i) end end)
                UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then Update(i) end end)
                UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
                return {Set = function(val) local pos = (val - Min) / (Max - Min) Fill.Size = UDim2.new(pos, 0, 1, 0) ValueText.Position = UDim2.new(pos, 0, 0, 22) ValueText.Text = tostring(val) .. Suffix Library.Flags[Flag] = val Callback(val) end}
            end

            function Section:CreateListbox(Text, Options, Multi, Callback)
                local Flag = Text:gsub("%s+", "")
                local List = {Selected = {}, Options = Options}
                Library.Flags[Flag] = Multi and {} or nil
                
                local ListboxFrame = Create("Frame", {
                    Parent = SecContent, 
                    Size = UDim2.new(1, 0, 0, 120), 
                    BackgroundTransparency = 1
                })
                
                Create("TextLabel", {
                    Parent = ListboxFrame, 
                    Text = Text, 
                    Size = UDim2.new(1, 0, 0, 16), 
                    BackgroundTransparency = 1, 
                    TextColor3 = Library.Theme.Text, 
                    FontFace = Library.Font, 
                    TextSize = 13, 
                    TextXAlignment = "Left"
                })
                
                local Tray = Create("ScrollingFrame", {
                    Parent = ListboxFrame, 
                    Size = UDim2.new(1, 0, 0, 100), 
                    Position = UDim2.new(0, 0, 0, 16), 
                    BackgroundColor3 = Library.Theme.SectionInlay, 
                    BorderSizePixel = 1, 
                    BorderColor3 = Library.Theme.InnerOutline, 
                    CanvasSize = UDim2.new(0,0,0,0), 
                    AutomaticCanvasSize = "Y", 
                    ScrollBarThickness = 2, 
                    ScrollBarImageColor3 = Library.Theme.Accent
                })
                
                Create("UIListLayout", {Parent = Tray})
                
                local function RenderOptions()
                    for _, v in next, Tray:GetChildren() do 
                        if v:IsA("TextButton") then 
                            v:Destroy() 
                        end 
                    end
                    
                    for _, opt in next, List.Options do
                        local OptBtn = Create("TextButton", {
                            Parent = Tray, 
                            Size = UDim2.new(1, 0, 0, 20), 
                            BackgroundTransparency = 1, 
                            Text = "  " .. opt, 
                            FontFace = Library.Font, 
                            TextSize = 13, 
                            TextColor3 = table.find(List.Selected, opt) and Library.Theme.Accent or Library.Theme.Text, 
                            TextXAlignment = "Left", 
                            AutoButtonColor = false
                        })
                        
                        OptBtn.Activated:Connect(function()
                            if Multi then 
                                if table.find(List.Selected, opt) then 
                                    table.remove(List.Selected, table.find(List.Selected, opt)) 
                                else 
                                    table.insert(List.Selected, opt) 
                                end 
                            else 
                                List.Selected = {opt} 
                            end
                            
                            Library.Flags[Flag] = Multi and List.Selected or List.Selected[1]
                            RenderOptions()
                            Callback(Library.Flags[Flag])
                        end)
                    end
                end
                
                function List:Add(opt) 
                    table.insert(self.Options, opt) 
                    RenderOptions() 
                end
                
                function List:Remove(opt) 
                    local i = table.find(self.Options, opt) 
                    if i then 
                        table.remove(self.Options, i) 
                    end 
                    RenderOptions() 
                end
                
                function List:Refresh(new) 
                    self.Options = new 
                    self.Selected = {} 
                    RenderOptions() 
                end
                
                RenderOptions()
                return List
            end

            function Section:CreateColorpicker(Text, Default, Callback)
                local Flag = Text:gsub("%s+", "")
                Library.Flags[Flag] = Default
                local ColorH, ColorS, ColorV = Default:ToHSV()
                local Picker = Create("Frame", {
                    Parent = SecContent, 
                    Size = UDim2.new(1, 0, 0, 22), 
                    BackgroundTransparency = 1
                })
                Create("TextLabel", {
                    Parent = Picker, 
                    Text = Text, 
                    Size = UDim2.new(1, 0, 1, 0), 
                    BackgroundTransparency = 1, 
                    TextColor3 = Library.Theme.Text, 
                    FontFace = Library.Font, 
                    TextSize = 13, 
                    TextXAlignment = "Left"
                })
                
                local BoxOuter = Create("Frame", {
                    Parent = Picker, 
                    Size = UDim2.new(0, 32, 0, 16), 
                    Position = UDim2.new(1, -32, 0.5, -8), 
                    BackgroundColor3 = Library.Theme.InnerOutline, 
                    BorderSizePixel = 0
                })
                local Box = Create("TextButton", {
                    Parent = BoxOuter, 
                    Size = UDim2.new(1, -2, 1, -2), 
                    Position = UDim2.new(0, 1, 0, 1), 
                    BackgroundColor3 = Default, 
                    Text = "", 
                    AutoButtonColor = false, 
                    BorderSizePixel = 0
                })
                ApplyShadow(Box)

                local Window = Create("Frame", {
                    Parent = Screen, 
                    Size = UDim2.new(0, 180, 0, 160), 
                    BackgroundColor3 = Library.Theme.Main, 
                    BorderSizePixel = 1, 
                    BorderColor3 = Library.Theme.InnerOutline, 
                    Visible = false, 
                    ZIndex = 50
                })
                local SatMap = Create("ImageButton", {
                    Parent = Window, 
                    Size = UDim2.new(0, 150, 0, 150), 
                    Position = UDim2.new(0, 5, 0, 5), 
                    Image = "rbxassetid://4155801252", 
                    ScaleType = "Slice", 
                    BorderSizePixel = 0, 
                    ZIndex = 50
                })
                local HueMap = Create("ImageButton", {
                    Parent = Window, 
                    Size = UDim2.new(0, 15, 0, 150), 
                    Position = UDim2.new(0, 160, 0, 5), 
                    Image = "rbxassetid://4155801252", 
                    BorderSizePixel = 0, 
                    ZIndex = 50
                })
                Create("UIGradient", {
                    Parent = HueMap, 
                    Rotation = -90, 
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.new(1,0,0)), 
                        ColorSequenceKeypoint.new(0.17, Color3.new(1,1,0)), 
                        ColorSequenceKeypoint.new(0.33, Color3.new(0,1,0)), 
                        ColorSequenceKeypoint.new(0.5, Color3.new(0,1,1)), 
                        ColorSequenceKeypoint.new(0.67, Color3.new(0,0,1)), 
                        ColorSequenceKeypoint.new(0.83, Color3.new(1,0,1)), 
                        ColorSequenceKeypoint.new(1, Color3.new(1,0,0))
                    })
                })
                
                local Pointer = Create("Frame", {
                    Parent = SatMap, 
                    Size = UDim2.new(0, 4, 0, 4), 
                    BackgroundColor3 = Color3.new(1,1,1), 
                    BorderColor3 = Color3.new(0,0,0), 
                    BorderSizePixel = 1, 
                    ZIndex = 51, 
                    Position = UDim2.new(ColorS, 0, 1 - ColorV, 0)
                })
                local HuePointer = Create("Frame", {
                    Parent = HueMap, 
                    Size = UDim2.new(1, 0, 0, 2), 
                    BackgroundColor3 = Color3.new(1,1,1), 
                    BorderColor3 = Color3.new(0,0,0), 
                    BorderSizePixel = 1, 
                    ZIndex = 51, 
                    Position = UDim2.new(0, 0, 1 - ColorH, 0)
                })

                local function Update()
                    local finalColor = Color3.fromHSV(ColorH, ColorS, ColorV)
                    SatMap.BackgroundColor3 = Color3.fromHSV(ColorH, 1, 1)
                    Box.BackgroundColor3 = finalColor
                    Pointer.Position = UDim2.new(ColorS, 0, 1 - ColorV, 0)
                    HuePointer.Position = UDim2.new(0, 0, 1 - ColorH, 0)
                    Library.Flags[Flag] = finalColor
                    Callback(finalColor)
                end

                Box.Activated:Connect(function() 
                    Window.Visible = not Window.Visible
                    Window.Position = UDim2.new(0, Box.AbsolutePosition.X - 190, 0, Box.AbsolutePosition.Y)
                end)

                SatMap.InputBegan:Connect(function(i) 
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then 
                        local con
                        con = UserInputService.InputChanged:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                                ColorS = math.clamp((input.Position.X - SatMap.AbsolutePosition.X) / SatMap.AbsoluteSize.X, 0, 1)
                                ColorV = 1 - math.clamp((input.Position.Y - SatMap.AbsolutePosition.Y) / SatMap.AbsoluteSize.Y, 0, 1)
                                Update()
                            end
                        end)
                        local function endCon(input) 
                            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
                                con:Disconnect() 
                            end 
                        end
                        UserInputService.InputEnded:Connect(endCon)
                    end 
                end)

                HueMap.InputBegan:Connect(function(i) 
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then 
                        local con
                        con = UserInputService.InputChanged:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                                ColorH = 1 - math.clamp((input.Position.Y - HueMap.AbsolutePosition.Y) / HueMap.AbsoluteSize.Y, 0, 1)
                                Update()
                            end
                        end)
                        local function endCon(input) 
                            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
                                con:Disconnect() 
                            end 
                        end
                        UserInputService.InputEnded:Connect(endCon)
                    end 
                end)
                
                Update()
                return {Set = function(c) ColorH, ColorS, ColorV = c:ToHSV() Update() end}
            end

            function Section:CreateKeybind(Text, Default, Callback)
                local Flag = Text:gsub("%s+", "")
                Library.Flags[Flag] = Default
                local Keybind = Create("Frame", {
                    Parent = SecContent, 
                    Size = UDim2.new(1, 0, 0, 22), 
                    BackgroundTransparency = 1
                })
                Create("TextLabel", {
                    Parent = Keybind, 
                    Text = Text, 
                    Size = UDim2.new(1, 0, 1, 0), 
                    BackgroundTransparency = 1, 
                    TextColor3 = Library.Theme.Text, 
                    FontFace = Library.Font, 
                    TextSize = 13, 
                    TextXAlignment = "Left"
                })
                local Keybtn = Create("TextButton", {
                    Parent = Keybind, 
                    Size = UDim2.new(0, 50, 0, 16), 
                    Position = UDim2.new(1, -50, 0.5, -8), 
                    BackgroundColor3 = Library.Theme.SectionInlay, 
                    BorderSizePixel = 1, 
                    BorderColor3 = Library.Theme.InnerOutline, 
                    Text = Default.Name, 
                    TextColor3 = Library.Theme.Text, 
                    FontFace = Library.Font, 
                    TextSize = 11, 
                    AutoButtonColor = false
                })
                ApplyShadow(Keybtn)
                local listening = false
                Keybtn.Activated:Connect(function()
                    listening = true
                    Keybtn.BackgroundColor3 = Library.Theme.Accent
                    Keybtn.Text = "..."
                end)
                local function SetKey(key)
                    listening = false
                    Library.Flags[Flag] = key
                    Keybtn.BackgroundColor3 = Library.Theme.SectionInlay
                    Keybtn.Text = key.Name
                    Callback(key)
                end
                UserInputService.InputBegan:Connect(function(input)
                    if listening then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            SetKey(input.KeyCode)
                        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                            SetKey(Enum.UserInputType.MouseButton1)
                        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                            SetKey(Enum.UserInputType.MouseButton2)
                        end
                    end
                end)
                return {Set = function(key) SetKey(key) end}
            end

            function Section:CreateButton(Text, Callback)
                local Btn = Create("TextButton", {
                    Parent = SecContent, 
                    Size = UDim2.new(1, 0, 0, 22), 
                    BackgroundColor3 = Library.Theme.SectionInlay, 
                    BorderSizePixel = 1, 
                    BorderColor3 = Library.Theme.InnerOutline, 
                    Text = Text, 
                    TextColor3 = Library.Theme.Text, 
                    FontFace = Library.Font, 
                    TextSize = 13, 
                    AutoButtonColor = false
                })
                ApplyShadow(Btn)
                Btn.Activated:Connect(function() Callback() end)
                return {Fire = function() Callback() end}
            end
            function Section:CreateTextbox(Text, Default, Callback)
                local Flag = Text:gsub("%s+", "")
                Library.Flags[Flag] = Default or ""
                
                local Box = Create("Frame", {
                    Parent = SecContent,
                    Size = UDim2.new(1, 0, 0, 22),
                    BackgroundTransparency = 1
                })
                
                Create("TextLabel", {
                    Parent = Box,
                    Text = Text,
                    Size = UDim2.new(0, 80, 1, 0),
                    BackgroundTransparency = 1,
                    TextColor3 = Library.Theme.Text,
                    FontFace = Library.Font,
                    TextSize = 13,
                    TextXAlignment = "Left"
                })
                
                local Input = Create("TextBox", {
                    Parent = Box,
                    Size = UDim2.new(1, -90, 0, 18),
                    Positend UDim2.new(1, -90, 0.5, -9),
                    BackgroundColor3 = Library.Theme.SectionInlay,
                    BorderSizePixel = 1,
                    BorderColor3 = Library.Theme.InnerOutline,
                    Text = Default or "",
                    TextColor3 = Library.Theme.Text,
                    FontFace = Library.Font,
                    TextSize = 12,
                    TextXAlignment = "Center",
                    ClearTextOnFocus = false
                })
                
                ApplyShadow(Input)
                
                Input.FocusLost:Connect(function()
                    Library.Flags[Flag] = Input.Text
                    Callback(Input.Text)
                end)
                
                return {Set = function(text) Input.Text = text Library.Flags[Flag] = text Callback(text) end}
            end
            return Section
        end
        return Tab
    end
    return Window
end
function Library:UpdateTheme()
    if not Screen then return end
    
    local function updateColors(obj)
        if obj:IsA("Frame") then
            if obj.Name == "Main" then
                obj.BackgroundColor3 = Library.Theme.Main
            elseif obj.Name == "Mainframe" then
                obj.BackgroundColor3 = Library.Theme.OuterOutline
            elseif obj.Name == "TabHolder" or obj.Name == "Container" then
                obj.BackgroundColor3 = Library.Theme.SectionInlay
                obj.BorderColor3 = Library.Theme.InnerOutline
            elseif obj.Name == "SecTitle" then
                obj.BackgroundColor3 = Library.Theme.SectionInlay
                obj.TextColor3 = Library.Theme.Accent
            elseif obj.Name == "SecMain" then
                obj.BackgroundColor3 = Library.Theme.Main
                obj.BorderColor3 = Library.Theme.InnerOutline
            elseif obj.Name == "BoxOuter" then
                obj.BackgroundColor3 = Library.Theme.InnerOutline
            elseif obj.BackgroundColor3 == Library.Theme.SectionInlay or 
                   obj.BackgroundColor3 == Color3.fromRGB(15, 15, 18) then
                obj.BackgroundColor3 = Library.Theme.SectionInlay
            elseif obj.BorderColor3 == Library.Theme.InnerOutline or 
                   obj.BorderColor3 == Color3.fromRGB(45, 45, 50) then
                obj.BorderColor3 = Library.Theme.InnerOutline
            elseif obj.BackgroundColor3 == Library.Theme.Accent or 
                   obj.BackgroundColor3 == Color3.fromRGB(65, 110, 255) then
                obj.BackgroundColor3 = Library.Theme.Accent
            end
        elseif obj:IsA("TextLabel") then
            if obj.TextColor3 == Library.Theme.Text or 
               obj.TextColor3 == Color3.fromRGB(220, 220, 220) then
                obj.TextColor3 = Library.Theme.Text
            elseif obj.TextColor3 == Library.Theme.Accent or 
                   obj.TextColor3 == Color3.fromRGB(65, 110, 255) then
                obj.TextColor3 = Library.Theme.Accent
            end
        elseif obj:IsA("TextButton") then
            if obj.TextColor3 == Library.Theme.Text or 
               obj.TextColor3 == Color3.fromRGB(220, 220, 220) then
                obj.TextColor3 = Library.Theme.Text
            elseif obj.TextColor3 == Library.Theme.Accent or 
                   obj.TextColor3 == Color3.fromRGB(65, 110, 255) then
                obj.TextColor3 = Library.Theme.Accent
            end
        elseif obj:IsA("ScrollingFrame") then
            if obj.ScrollBarImageColor3 == Library.Theme.Accent or 
               obj.ScrollBarImageColor3 == Color3.fromRGB(65, 110, 255) then
                obj.ScrollBarImageColor3 = Library.Theme.Accent
            end
        end
        
        for _, child in pairs(obj:GetChildren()) do
            updateColors(child)
        end
    end
    
    updateColors(currentScreenGui)
end

function Library:SetTheme(themeTable)
    if themeTable and type(themeTable) == "table" then
        for key, value in pairs(themeTable) do
            if Library.Theme[key] ~= nil and typeof(value) == "Color3" then
                Library.Theme[key] = value
            end
        end
        self:UpdateTheme()
        return true
    end
    return false
end

function Library:CreateThemeSection(tab, side)
    local themeSection = tab:CreateSection("Themes", side)
    
    local themes = {
        ["Warepaste Default"] = {
            Main = Color3.fromRGB(20, 20, 23),
            OuterOutline = Color3.fromRGB(65, 65, 70),
            InnerOutline = Color3.fromRGB(45, 45, 50),
            Accent = Color3.fromRGB(65, 110, 255),
            Text = Color3.fromRGB(220, 220, 220),
            SectionInlay = Color3.fromRGB(15, 15, 18)
        },
        ["Tokyo Night"] = {
            Main = Color3.fromRGB(26, 27, 38),
            OuterOutline = Color3.fromRGB(65, 72, 104),
            InnerOutline = Color3.fromRGB(41, 46, 66),
            Accent = Color3.fromRGB(122, 162, 247),
            Text = Color3.fromRGB(192, 202, 245),
            SectionInlay = Color3.fromRGB(22, 23, 33)
        },
        ["Deadcell"] = {
            Main = Color3.fromRGB(15, 15, 20),
            OuterOutline = Color3.fromRGB(40, 40, 50),
            InnerOutline = Color3.fromRGB(30, 30, 40),
            Accent = Color3.fromRGB(255, 50, 50),
            Text = Color3.fromRGB(240, 240, 240),
            SectionInlay = Color3.fromRGB(10, 10, 15)
        },
        ["Warepaste Purple"] = {
            Main = Color3.fromRGB(30, 20, 40),
            OuterOutline = Color3.fromRGB(80, 60, 100),
            InnerOutline = Color3.fromRGB(60, 40, 80),
            Accent = Color3.fromRGB(170, 110, 255),
            Text = Color3.fromRGB(220, 220, 220),
            SectionInlay = Color3.fromRGB(25, 15, 35)
        }
    }
    
    themeSection:CreateLabel("Select Theme")
    
    local themeList = themeSection:CreateListbox("Themes", {"Default", "Tokyo Night", "Deadcell", "Purple"}, false, function(selected)
        Library:SetTheme(themes[selected])
    end)
    
    themeSection:CreateLabel("Custom Colors")
    
    themeSection:CreateColorpicker("Main", Library.Theme.Main, function(color)
        Library.Theme.Main = color
        Library:UpdateTheme()
    end)
    
    themeSection:CreateColorpicker("OuterOutline", Library.Theme.OuterOutline, function(color)
        Library.Theme.OuterOutline = color
        Library:UpdateTheme()
    end)
    
    themeSection:CreateColorpicker("InnerOutline", Library.Theme.InnerOutline, function(color)
        Library.Theme.InnerOutline = color
        Library:UpdateTheme()
    end)
    
    themeSection:CreateColorpicker("Accent", Library.Theme.Accent, function(color)
        Library.Theme.Accent = color
        Library:UpdateTheme()
    end)
    
    themeSection:CreateColorpicker("Text", Library.Theme.Text, function(color)
        Library.Theme.Text = color
        Library:UpdateTheme()
    end)
    
    themeSection:CreateColorpicker("SectionInlay", Library.Theme.SectionInlay, function(color)
        Library.Theme.SectionInlay = color
        Library:UpdateTheme()
    end)
    
    themeSection:CreateButton("Apply Theme", function()
        Library:UpdateTheme()
    end)
    
    return themeSection
end
function Library:CreateWatermark(Config)
    Config = Config or {}
    
    local Holder = Create("Frame", {
        Parent = Screen,
        Size = UDim2.new(0, 0, 0, 22),
        Position = Config.Position or UDim2.new(0, 10, 0, 10),
        BackgroundColor3 = Config.Background or Library.Theme.Main,
        BorderSizePixel = 1,
        BorderColor3 = Config.Border or Library.Theme.InnerOutline,
        AutomaticSize = "X",
        Visible = Config.Visible ~= false,
        ZIndex = 100
    })
    
    ApplyShadow(Holder)
    
    Create("UIPadding", {
        Parent = Holder,
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 3),
        PaddingBottom = UDim.new(0, 3)
    })
    
    Create("Frame", {
        Parent = Holder,
        Size = UDim2.new(0, 2, 1, -4),
        Position = UDim2.new(0, 0, 0, 2),
        BackgroundColor3 = Config.Accent or Library.Theme.Accent,
        BorderSizePixel = 0
    })
    
    local Text = Create("TextLabel", {
        Parent = Holder,
        Text = Config.Text or "warepaste.cc",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = Config.TextColor or Library.Theme.Text,
        FontFace = Config.Font or Library.Font,
        TextSize = Config.TextSize or 12,
        TextXAlignment = "Left",
        AutomaticSize = "X"
    })
    
    if Config.ShowTime ~= false then
        RunService.Heartbeat:Connect(function()
            Text.Text = (Config.Text or "warepaste.cc") .. " | " .. os.date(Config.TimeFormat or "%H:%M:%S")
        end)
    end
    
    return Holder
end

function Library:AddWatermarkControls(tab, side)
    local section = tab:CreateSection("Watermark", side)
    
    local watermark = nil
    
    local textInput
    local function UpdateWatermark()
        if watermark then
            watermark:Destroy()
        end
        watermark = self:CreateWatermark({
            Text = textInput and textInput.Text or "warepaste.cc",
            ShowTime = true,
            TimeFormat = "%H:%M:%S"
        })
    end
    
    textInput = sesectionreateTextbox("Watermark Text", "warepaste.cc", function(value)
        if watermark then
            watermark:Destroy()
            watermark = self:CreateWatermark({
                Text = value,
                ShowTime = true
            })
        end
    end)
    
    section:CreateToggle("Show Watermark", true, function(state)
        if state then
            if not watermark then
                UpdateWatermark()
            else
                watermark.Visible = true
            end
        else
            if watermark then
                watermark.Visible = false
            end
        end
    end)
end
eturn Library
