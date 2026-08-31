local InputService = game:GetService('UserInputService');
local TextService = game:GetService('TextService');
local CoreGui = game:GetService('CoreGui');
local Teams = game:GetService('Teams');
local Players = game:GetService('Players');
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService');
local Lighting = game:GetService('Lighting');
local RenderStepped = RunService.RenderStepped;
local LocalPlayer = Players.LocalPlayer;
local Mouse = LocalPlayer:GetMouse();

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end);

local ScreenGui = Instance.new('ScreenGui');
ProtectGui(ScreenGui);
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
ScreenGui.Parent = CoreGui;

local Toggles = {};
local Options = {};

getgenv().Toggles = Toggles;
getgenv().Options = Options;

local Library = {
    Registry = {};
    RegistryMap = {};

    HudRegistry = {};

    FontColor = Color3.fromRGB(235, 235, 235);
    MainColor = Color3.fromRGB(14, 14, 14);
    BackgroundColor = Color3.fromRGB(20, 20, 20);
    AccentColor = Color3.fromRGB(235, 235, 235);
    OutlineColor = Color3.fromRGB(32, 32, 32);
    RiskColor = Color3.fromRGB(255, 70, 70),

    Black = Color3.new(0, 0, 0);

    Font = Enum.Font.Code,
    FontSize = 14,

    OpenedFrames = {};
    DependencyBoxes = {};

    Signals = {};
    ScreenGui = ScreenGui;

    Toggled = false;
    WireframeDrag = true;
    UseBlur = false;
    BlurSize = 15;

    KeybindMode = 'All';

    WindowCornerRadius = 12;
    MobileCornerRadius = 10;
    WindowCorners = {};
    MobileCorners = {};

    UILocked = false;

    MobileButtonConfig = {
        Transparency = 0;
        Size = Vector2.new(88, 30);
        Color = Color3.fromRGB(14, 14, 16);
        TextColor = Color3.fromRGB(255, 255, 255);
        TapMode = "Single";
        Invisible = false;
        CornerRadius = 10;
    };

    TopBarEnabled = true;
    TopBarWidgets = {};

    NotifyConfig = {
        Alignment = 'Left';
        BarSide   = 'Left';
        PositionX = 0;
        PositionY = 40;
    };
    DPI = 100;
    TabPosition = "Top";
    CustomBackgroundId = nil;
    WindowTransparency = 0;
    TopBarTransparency = 0;
    TopBarIconSize = 24;

    GlassEnabled = false;
    GlassIntensity = 0.45;
    GlassSurfaces = {};

    TopBarIconColor = nil;
};
local UIScale = Instance.new("UIScale");
UIScale.Scale = 1;
UIScale.Parent = ScreenGui;
Library.UIScale = UIScale;
Library.CustomBackgroundFrame = Instance.new("ImageLabel");
Library.CustomBackgroundFrame.BackgroundTransparency = 1;
Library.CustomBackgroundFrame.Size = UDim2.new(1,0,1,0);
Library.CustomBackgroundFrame.Position = UDim2.new(0,0,0,0);
Library.CustomBackgroundFrame.ImageTransparency = 0.15;
Library.CustomBackgroundFrame.Visible = false;
Library.CustomBackgroundFrame.ZIndex = 0;
Library.CustomBackgroundFrame.ScaleType = Enum.ScaleType.Crop;
Library.CustomBackgroundFrame.Parent = ScreenGui;

Library.KeyPickerList = {};

Library.BlurEffect = Instance.new("BlurEffect")
Library.BlurEffect.Name = "LinoriaBlur"
Library.BlurEffect.Size = 0
Library.BlurEffect.Enabled = false
pcall(function() Library.BlurEffect.Parent = Lighting end)

function Library:UpdateBlur()
    if Library.UseBlur then
        if Library.Toggled then
            Library.BlurEffect.Enabled = true
            TweenService:Create(Library.BlurEffect, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {Size = Library.BlurSize}):Play()
        end
    else
        local tween = TweenService:Create(Library.BlurEffect, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {Size = 0})
        tween:Play()

        task.delay(0.2, function()
            if not Library.UseBlur then
                Library.BlurEffect.Enabled = false
            end
        end)
    end
end

function Library:SetFontSize(Size)
    Library.FontSize = Size
    for _, descendant in pairs(ScreenGui:GetDescendants()) do
        if descendant:IsA("TextLabel") or descendant:IsA("TextBox") or descendant:IsA("TextButton") then
            local offset = descendant:GetAttribute("FontSizeOffset")
            if offset then
                descendant.TextSize = Size + offset
            end
        end
    end
    local mobileUI = CoreGui:FindFirstChild("LinoriaMobileUI")
    if mobileUI then
        for _, descendant in pairs(mobileUI:GetDescendants()) do
            if descendant:IsA("TextLabel") or descendant:IsA("TextBox") or descendant:IsA("TextButton") then
                local offset = descendant:GetAttribute("FontSizeOffset")
                if offset then
                    descendant.TextSize = Size + offset
                end
            end
        end
    end
end

local RainbowStep = 0
local Hue = 0

table.insert(Library.Signals, RenderStepped:Connect(function(Delta)
    RainbowStep = RainbowStep + Delta

    if RainbowStep >= (1 / 60) then
        RainbowStep = 0

        Hue = Hue + (1 / 400);
        if Hue > 1 then
            Hue = 0;
        end;

        Library.CurrentRainbowHue = Hue;
        Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1);
    end
end))

local function GetPlayersString()
    local PlayerList = Players:GetPlayers();
    for i = 1, #PlayerList do
        PlayerList[i] = PlayerList[i].Name;
    end;
    table.sort(PlayerList, function(str1, str2) return str1 < str2 end);

    return PlayerList;
end;

local function GetTeamsString()
    local TeamList = Teams:GetTeams();
    for i = 1, #TeamList do
        TeamList[i] = TeamList[i].Name;
    end;
    table.sort(TeamList, function(str1, str2) return str1 < str2 end);

    return TeamList;
end;

function Library:SafeCallback(f, ...)
    if (not f) then
        return;
    end;
    if not Library.NotifyOnError then
        return f(...);
    end;

    local success, event = pcall(f, ...);
    if not success then
        local _, i = event:find(":%d+: ");
        if not i then
            return Library:Notify(event);
        end;
        return Library:Notify(event:sub(i + 1), 3);
    end;
end;

function Library:AttemptSave()
    if Library.SaveManager then
        Library.SaveManager:Save();
    end;
end;

function Library:Create(Class, Properties)
    local _Instance = Class;
    if type(Class) == 'string' then
        _Instance = Instance.new(Class);
    end;
    for Property, Value in next, Properties do
        _Instance[Property] = Value;
    end;

    if _Instance:IsA("TextLabel") or _Instance:IsA("TextBox") or _Instance:IsA("TextButton") then
        if Properties.TextSize then
            _Instance:SetAttribute("FontSizeOffset", Properties.TextSize - Library.FontSize)
        else
            _Instance:SetAttribute("FontSizeOffset", 0)
        end
    end

    return _Instance;
end;

function Library:ApplyTextStroke(Inst)
    Inst.TextStrokeTransparency = 1;

    Library:Create('UIStroke', {
        Color = Color3.new(0, 0, 0);
        Thickness = 1;
        LineJoinMode = Enum.LineJoinMode.Miter;
        Parent = Inst;
    });
end;

-- Adds a thin, low-opacity accent-colored outline. Used to give an element
-- a bit of definition without a hard border.
function Library:ApplyGlow(Inst)
    if Inst:FindFirstChild("AccentGlow") then return end
    local Stroke = Library:Create('UIStroke', {
        Name = "AccentGlow";
        Thickness = 1;
        Color = Library.AccentColor;
        Transparency = 0.7;
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
        Parent = Inst;
    });
    Library:AddToRegistry(Stroke, { Color = 'AccentColor' });
end;

-- Registers a top-level panel (window, top bar, sub window) as a glass
-- material surface. Glass styling is applied immediately if already enabled,
-- and again automatically whenever SetGlassEnabled/SetGlassIntensity change.
function Library:MarkGlassSurface(Inst)
    table.insert(Library.GlassSurfaces, Inst)
    if Library.GlassEnabled then
        Library:ApplyGlassPanel(Inst, true)
    end
    return Inst
end;

-- Adds or removes the frosted-glass look (translucency plus a bright
-- top-left/dim bottom-right edge highlight, like light catching an edge)
-- on a single panel.
function Library:ApplyGlassPanel(Inst, Enabled)
    if not (Inst and Inst.Parent) then return end

    if Enabled then
        Inst.BackgroundTransparency = Library.GlassIntensity

        if not Inst:FindFirstChild("GlassEdge") then
            local Edge = Library:Create('UIStroke', {
                Name = "GlassEdge";
                Thickness = 1;
                Transparency = 0.4;
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
                Parent = Inst;
            });
            Library:Create('UIGradient', {
                Rotation = 115;
                Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0, 0, 0));
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.15);
                    NumberSequenceKeypoint.new(0.5, 0.8);
                    NumberSequenceKeypoint.new(1, 0.5);
                });
                Parent = Edge;
            });
        end
    else
        Inst.BackgroundTransparency = 0;
        local Edge = Inst:FindFirstChild("GlassEdge")
        if Edge then Edge:Destroy() end
    end
end;

function Library:RefreshGlass()
    for _, Inst in ipairs(Library.GlassSurfaces) do
        Library:ApplyGlassPanel(Inst, Library.GlassEnabled)
    end
end;

-- Turns the frosted-glass material on or off for every marked surface
-- (windows, the top bar, sub windows), and enables the background blur
-- that makes the translucency read as glass rather than a flat tint.
function Library:SetGlassEnabled(Enabled)
    Library.GlassEnabled = Enabled
    Library:RefreshGlass()
    if Enabled then
        Library.UseBlur = true
        Library.BlurSize = math.max(Library.BlurSize, 18)
    end
    Library:UpdateBlur()
end;

-- Sets how transparent glass surfaces are (0 = opaque, 0.9 = almost invisible).
function Library:SetGlassIntensity(Value)
    Library.GlassIntensity = math.clamp(Value, 0, 0.9)
    Library:RefreshGlass()
end;

function Library:ApplyCorner(Inst, Radius, IsWindow)
    local corner = Library:Create('UICorner', {
        CornerRadius = UDim.new(0, Radius or Library.WindowCornerRadius);
        Parent = Inst;
    });
    if IsWindow then
        table.insert(Library.WindowCorners, corner);
    end
    return corner;
end;

function Library:ApplyMobileCorner(Inst, Radius)
    local corner = Library:Create('UICorner', {
        CornerRadius = UDim.new(0, Radius or Library.MobileCornerRadius);
        Parent = Inst;
    });
    table.insert(Library.MobileCorners, corner);
    return corner;
end;

function Library:SetWindowCornerRadius(Radius)
    Library.WindowCornerRadius = Radius;
    for _, c in ipairs(Library.WindowCorners) do
        c.CornerRadius = UDim.new(0, Radius);
    end;
end;

function Library:SetMobileCornerRadius(Radius)
    Library.MobileCornerRadius = Radius;
    Library.MobileButtonConfig.CornerRadius = Radius;
    for _, c in ipairs(Library.MobileCorners) do
        c.CornerRadius = UDim.new(0, Radius);
    end;
end;

function Library:SetMobileButtonTransparency(Alpha)
    Library.MobileButtonConfig.Transparency = math.clamp(Alpha, 0, 1);
    if Library.MobileButtons then
        for _, btn in ipairs(Library.MobileButtons) do
            if btn.Outer then
                local a = Library.MobileButtonConfig.Invisible and 1 or Library.MobileButtonConfig.Transparency
                btn.Outer.BackgroundTransparency = a
                if btn.TextLabel then btn.TextLabel.BackgroundTransparency = a end
                if btn.Btn then
                    btn.Btn.BackgroundTransparency = 1
                    btn.Btn.TextTransparency = Library.MobileButtonConfig.Invisible and 1 or a
                end
            end;
        end;
    end;
    if Library.MobileGui then
        Library.MobileGui.Enabled = true
    end
end;

function Library:SetMobileButtonSize(SizeVector2)
    Library.MobileButtonConfig.Size = SizeVector2;
    if Library.MobileButtons then
        for _, btn in ipairs(Library.MobileButtons) do
            if btn.Outer then
                btn.Outer.Size = UDim2.fromOffset(SizeVector2.X, SizeVector2.Y);
            end;
        end;
    end;
end;

function Library:SetMobileButtonColor(Color)
    Library.MobileButtonConfig.Color = Color;
    if Library.MobileButtons then
        for _, btn in ipairs(Library.MobileButtons) do
            if btn.Outer then btn.Outer.BackgroundColor3 = Color; end;
        end;
    end;
end;

function Library:SetMobileButtonTapMode(Mode)
    assert(Mode == "Single" or Mode == "Double" or Mode == "Hold", "TapMode must be Single/Double/Hold");
    Library.MobileButtonConfig.TapMode = Mode;
end;

function Library:SetMobileInvisible(Bool)
    Library.MobileButtonConfig.Invisible = Bool;
    if Library.MobileButtons then
        for _, btn in ipairs(Library.MobileButtons) do
            if btn.Outer then
                btn.Outer.Visible = true
                btn.Outer.Active = true
                btn.Outer.BackgroundTransparency = Bool and 1 or Library.MobileButtonConfig.Transparency
            end
            if btn.Btn then
                btn.Btn.Visible = true
                btn.Btn.Active = true
                btn.Btn.TextTransparency = Bool and 1 or Library.MobileButtonConfig.Transparency
            end
        end
    end
end;

function Library:SetUILocked(Locked)
    Library.UILocked = Locked;
    if Library.LockMobileBtn then
        Library.LockMobileBtn.Text = Locked and "Unlock UI" or "Lock UI";
        Library.LockMobileBtn.TextColor3 = Locked and Library.FontColor or Library.AccentColor
    end;
end;
function Library:SetDPI(Percent)
    Percent = math.clamp(Percent, 50, 150)
    Library.DPI = Percent
    local scale = Percent / 100
    if Library.UIScale then
        Library.UIScale.Scale = scale
    end
end;
function Library:SetCustomBackground(AssetId)
    if not AssetId or AssetId == "" then
        Library.CustomBackgroundFrame.Visible = false
        Library.CustomBackgroundId = nil
        return
    end
    local id = tostring(AssetId)
    if not id:find("rbxassetid") then
        id = "rbxassetid://" .. id
    end
    Library.CustomBackgroundId = id
    Library.CustomBackgroundFrame.Image = id
    Library.CustomBackgroundFrame.Visible = true
end;
function Library:RemoveCustomBackground()
    Library.CustomBackgroundFrame.Visible = false
    Library.CustomBackgroundId = nil
    Library.CustomBackgroundFrame.Image = ""
end;
function Library:SetTabPosition(Position)
    Library.TabPosition = Position
    local refs = Library.WindowRefs
    if not refs or not refs.TabBarOuter then return end
    local outer = refs.TabBarOuter
    local main = refs.MainSectionOuter
    local area = refs.TabArea
    local layout = area:FindFirstChildOfClass("UIListLayout")
    if Position == "Top" then
        outer.AnchorPoint = Vector2.new(0,0)
        outer.Position = UDim2.new(0,8,0,25)
        outer.Size = UDim2.new(1,-16,0,29)
        main.Position = UDim2.new(0,8,0,58)
        main.Size = UDim2.new(1,-16,1,-66)
        if layout then layout.FillDirection = Enum.FillDirection.Horizontal end
        outer.Visible = true
    elseif Position == "Bottom" then
        outer.AnchorPoint = Vector2.new(0,0)
        outer.Position = UDim2.new(0,8,1,-37)
        outer.Size = UDim2.new(1,-16,0,29)
        main.Position = UDim2.new(0,8,0,8)
        main.Size = UDim2.new(1,-16,1,-45)
        if layout then layout.FillDirection = Enum.FillDirection.Horizontal end
        outer.Visible = true
    elseif Position == "Left" then
        outer.AnchorPoint = Vector2.new(0,0)
        outer.Position = UDim2.new(0,8,0,25)
        outer.Size = UDim2.new(0,110,1,-33)
        main.Position = UDim2.new(0,126,0,25)
        main.Size = UDim2.new(1,-134,1,-33)
        if layout then layout.FillDirection = Enum.FillDirection.Vertical end
        outer.Visible = true
    elseif Position == "Right" then
        outer.AnchorPoint = Vector2.new(0,0)
        outer.Position = UDim2.new(1,-118,0,25)
        outer.Size = UDim2.new(0,110,1,-33)
        main.Position = UDim2.new(0,8,0,25)
        main.Size = UDim2.new(1,-134,1,-33)
        if layout then layout.FillDirection = Enum.FillDirection.Vertical end
        outer.Visible = true
    elseif Position == "Center" then
        outer.AnchorPoint = Vector2.new(0.5,0)
        outer.Position = UDim2.new(0.5,0,0,25)
        outer.Size = UDim2.new(1,-16,0,29)
        main.Position = UDim2.new(0,8,0,58)
        main.Size = UDim2.new(1,-16,1,-66)
        if layout then layout.FillDirection = Enum.FillDirection.Horizontal end
        outer.Visible = true
    end
end;
function Library:SetWindowTransparency(Alpha)
    Alpha = math.clamp(Alpha, 0, 1)
    Library.WindowTransparency = Alpha
    local refs = Library.WindowRefs
    if refs then
        if refs.Outer then refs.Outer.BackgroundTransparency = Alpha end
        if refs.Inner then refs.Inner.BackgroundTransparency = Alpha end
        if refs.TabBarOuter then refs.TabBarOuter.BackgroundTransparency = Alpha end
        if refs.MainSectionOuter then refs.MainSectionOuter.BackgroundTransparency = Alpha end
        if refs.MainSectionInner then refs.MainSectionInner.BackgroundTransparency = Alpha end
        if refs.TabContainer then refs.TabContainer.BackgroundTransparency = Alpha end
    end
    if Library.WidgetWindows then
        for _, w in ipairs(Library.WidgetWindows) do
            if w.Outer then w.Outer.BackgroundTransparency = Alpha end
            if w.Inner then w.Inner.BackgroundTransparency = Alpha end
            if w.TitleBar then w.TitleBar.BackgroundTransparency = Alpha end
        end
    end
    if Library.TopBar then
        Library.TopBar.BackgroundTransparency = Alpha
    end
end;
-- Recomputes the top bar's frame size from its content and the current icon
-- size. Shared by SetTopBarIconSize and AddTopBarWidget to avoid duplicating
-- the same layout math in both places.
function Library:RefreshTopBarSize()
    if not (Library.TopBar and Library.TopBarListLayout) then return end
    local content = Library.TopBarListLayout.AbsoluteContentSize
    local height = Library.TopBarIconSize + 8
    Library.TopBar.Size = UDim2.new(0, content.X + 20, 0, height)
    if Library.TopBarCorner then
        Library.TopBarCorner.CornerRadius = UDim.new(0, height / 2)
    end
end;

-- Sets the top bar's background transparency (0-1). Has no visible effect
-- while glass mode is on; use SetGlassIntensity for that instead.
function Library:SetTopBarTransparency(Alpha)
    Alpha = math.clamp(Alpha, 0, 1)
    Library.TopBarTransparency = Alpha
    if Library.TopBar and not Library.GlassEnabled then
        Library.TopBar.BackgroundTransparency = Alpha
    end
end;

-- Sets the size (in pixels, clamped 12-40) of every top bar icon button,
-- including ones added after this is called.
function Library:SetTopBarIconSize(Size)
    Size = math.clamp(Size, 12, 40)
    Library.TopBarIconSize = Size
    for _, w in ipairs(Library.TopBarWidgets) do
        if w.Button then
            w.Button.Size = UDim2.fromOffset(Size, Size)
        end
        if w.Corner then
            w.Corner.CornerRadius = UDim.new(0, Size / 2)
        end
    end
    Library:RefreshTopBarSize()
end;

-- Sets the icon color used by every top bar widget button while idle
-- (pass nil to go back to the theme's FontColor). Active/hovered buttons
-- still switch to the accent color as usual.
function Library:SetTopBarIconColor(Color)
    Library.TopBarIconColor = Color
    for _, w in ipairs(Library.TopBarWidgets) do
        if w.Refresh then w.Refresh(true) end
    end
end;

-- Changes the icon of a single top bar widget. Widget can be the table
-- returned by AddTopBarWidget, or its 1-based insertion index.
function Library:SetTopBarWidgetIcon(Widget, IconName)
    if not Widget then return end
    local target = nil
    if typeof(Widget) == "table" and Widget.Button then
        target = Widget
    elseif typeof(Widget) == "number" then
        target = Library.TopBarWidgets[Widget]
    else
        for _, w in ipairs(Library.TopBarWidgets) do
            if w.Button and w.Button.Name == tostring(Widget) then target = w break end
        end
    end
    if target and target.Button then
        target.Button.Image = Library:GetLucideIcon(IconName)
    end
end;

-- Sets the top bar's background color.
function Library:SetTopBarBackgroundColor(Color)
    if Library.TopBar then
        Library.TopBar.BackgroundColor3 = Color
    end
end;

Library.LucideIcons = {
    wrench = "rbxassetid://10747383470",
    users = "rbxassetid://10747373426",
    user = "rbxassetid://10747373176",
    settings = "rbxassetid://10734950309",
    ["settings-2"] = "rbxassetid://10734950020",
    shield = "rbxassetid://10734951847",
    ["shield-check"] = "rbxassetid://10734951367",
    eye = "rbxassetid://10723346959",
    ["eye-off"] = "rbxassetid://10723346871",
    globe = "rbxassetid://10723404337",
    ["globe-2"] = "rbxassetid://10723398002",
    box = "rbxassetid://10709782497",
    palette = "rbxassetid://10734910430",
    music = "rbxassetid://10734905958",
    ["music-2"] = "rbxassetid://10734900215",
    sparkles = "rbxassetid://10734966248",
    sparkle = "rbxassetid://10734966248",
    x = "rbxassetid://10747384394",
    close = "rbxassetid://10747384394",
    plus = "rbxassetid://10734924532",
    home = "rbxassetid://10723407389",
    star = "rbxassetid://10734966248",
    brush = "rbxassetid://10709782758",
    paintbrush = "rbxassetid://10734910187",
    activity = "rbxassetid://10709752035",
    search = "rbxassetid://10734943674",
    cog = "rbxassetid://10709810948",
    sliders = "rbxassetid://10734963400",
    command = "rbxassetid://10709811365",
    bell = "rbxassetid://10709775704",
    book = "rbxassetid://10709781824",
    bookmark = "rbxassetid://10709782154",
    camera = "rbxassetid://10709789686",
    calendar = "rbxassetid://10709789505",
    clock = "rbxassetid://10709805144",
    trash = "rbxassetid://10747362393",
    trash2 = "rbxassetid://10747362241",
    folder = "rbxassetid://10723387563",
    file = "rbxassetid://10723374641",
    heart = "rbxassetid://10723406885",
    lock = "rbxassetid://10723434711",
    unlock = "rbxassetid://10747366027",
    usercheck = "rbxassetid://10747371901",
    hammer = "rbxassetid://10723405360",
    zap = "rbxassetid://10734898592",
};

-- Resolves an icon name to its asset id. Unknown names are returned as-is,
-- so a raw "rbxassetid://..." string can be passed directly.
function Library:GetLucideIcon(Name)
    if not Name then return nil end
    local lower = string.lower(tostring(Name))
    return Library.LucideIcons[lower] or Name
end;

-- Adds or overrides an icon name so it can be used anywhere Icon = "name" is
-- accepted (e.g. AddTopBarWidget), including the built-in Lucide set.
function Library:RegisterLucideIcon(Name, AssetId)
    if not Name or not AssetId then return end
    Library.LucideIcons[string.lower(tostring(Name))] = AssetId
end;

function Library:CreateLabel(Properties, IsHud)
    local _Instance = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        Font = Library.Font;
        TextColor3 = Library.FontColor;
        TextSize = Library.FontSize + 2;
        TextStrokeTransparency = 0;
    });
    Library:ApplyTextStroke(_Instance);

    Library:AddToRegistry(_Instance, {
        TextColor3 = 'FontColor';
    }, IsHud);
    return Library:Create(_Instance, Properties);
end;

function Library:MakeDraggable(Instance, Cutoff, IsWindow)
    Instance.Active = true;
    Instance.InputBegan:Connect(function(Input)
        if Library.UILocked then return end;
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            local StartPos = Instance.Position
            local DragStart = Input.Position

            if (DragStart.Y - Instance.AbsolutePosition.Y) > (Cutoff or 40) then
                return
            end

            local Dragging = true
            local HasMoved = false
            local Wireframe = nil
            local ChangedConn, EndedConn

            ChangedConn = InputService.InputChanged:Connect(function(Change)
                if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                    local Delta = Change.Position - DragStart

                    if IsWindow and Library.WireframeDrag then
                        if not HasMoved and Delta.Magnitude > 2 then
                            HasMoved = true

                            Wireframe = Library:Create("Frame", {
                                Size = Instance.Size,
                                Position = Instance.Position,
                                AnchorPoint = Instance.AnchorPoint,
                                BackgroundTransparency = 1,
                                Active = false,
                                ZIndex = 100000,
                                Parent = ScreenGui
                            })

                            local stroke = Library:Create("UIStroke", {
                                Color = Library.AccentColor,
                                Thickness = 1,
                                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                                Parent = Wireframe
                            })
                        end

                        if HasMoved and Wireframe then
                            Wireframe.Position = UDim2.new(
                                StartPos.X.Scale, StartPos.X.Offset + Delta.X,
                                StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
                            )
                        end
                    else
                        Instance.Position = UDim2.new(
                            StartPos.X.Scale, StartPos.X.Offset + Delta.X,
                            StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
                        )
                    end
                end
            end)

            EndedConn = InputService.InputEnded:Connect(function(EndInput)
                if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                    Dragging = false
                    ChangedConn:Disconnect()
                    EndedConn:Disconnect()

                    if IsWindow and Library.WireframeDrag and HasMoved and Wireframe then
                        Instance.Position = Wireframe.Position

                        Wireframe:Destroy()
                        Wireframe = nil
                    end
                end
            end)
        end
    end)
end;

-- Adds a small grip to the bottom-left corner of Instance that lets the
-- user click-drag to resize it, clamped between MinSize and MaxSize.
-- Works with any AnchorPoint, including the centered anchor used by
-- Config.Center windows.
function Library:MakeResizable(Instance, MinSize, MaxSize)
    MinSize = MinSize or Vector2.new(340, 260)
    MaxSize = MaxSize or Vector2.new(1000, 900)

    local Grip = Library:Create('ImageButton', {
        Name = "ResizeGrip";
        AnchorPoint = Vector2.new(0, 1);
        BackgroundTransparency = 1;
        AutoButtonColor = false;
        Position = UDim2.new(0, 0, 1, 0);
        Size = UDim2.fromOffset(18, 18);
        Image = "";
        Text = "";
        ZIndex = 50;
        Parent = Instance;
    });

    local Dots = {}
    for row = 1, 3 do
        for col = 1, row do
            local Dot = Library:Create('Frame', {
                BackgroundColor3 = Library.FontColor;
                BackgroundTransparency = 0.55;
                BorderSizePixel = 0;
                AnchorPoint = Vector2.new(0.5, 0.5);
                Position = UDim2.new(0, 5 + (col - 1) * 4, 1, -5 - (row - 1) * 4);
                Size = UDim2.fromOffset(2, 2);
                ZIndex = 51;
                Parent = Grip;
            });
            Library:ApplyCorner(Dot, 1)
            table.insert(Dots, Dot)
        end
    end

    local function SetGripHighlighted(Highlighted)
        for _, Dot in ipairs(Dots) do
            Dot.BackgroundTransparency = Highlighted and 0.1 or 0.55
            Dot.BackgroundColor3 = Highlighted and Library.AccentColor or Library.FontColor
        end
    end

    Grip.MouseEnter:Connect(function() SetGripHighlighted(true) end)
    Grip.MouseLeave:Connect(function() SetGripHighlighted(false) end)

    Grip.InputBegan:Connect(function(Input)
        if Library.UILocked then return end
        if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then return end

        local StartSize = Instance.Size
        local StartPos = Instance.Position
        local Anchor = Instance.AnchorPoint
        local DragStart = Input.Position

        local Wireframe = Library:Create("Frame", {
            Size = StartSize;
            Position = StartPos;
            AnchorPoint = Anchor;
            BackgroundTransparency = 1;
            Active = false;
            ZIndex = 100000;
            Parent = ScreenGui;
        });
        Library:Create("UIStroke", {
            Color = Library.AccentColor;
            Thickness = 1;
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
            Parent = Wireframe;
        });

        local ChangedConn, EndedConn
        ChangedConn = InputService.InputChanged:Connect(function(Change)
            if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                local Delta = Change.Position - DragStart

                local NewWidth = math.clamp(StartSize.X.Offset - Delta.X, MinSize.X, MaxSize.X)
                local NewHeight = math.clamp(StartSize.Y.Offset + Delta.Y, MinSize.Y, MaxSize.Y)
                local NewPosX = StartPos.X.Offset + (StartSize.X.Offset - NewWidth) * (1 - Anchor.X)
                local NewPosY = StartPos.Y.Offset + (NewHeight - StartSize.Y.Offset) * Anchor.Y

                Wireframe.Size = UDim2.new(StartSize.X.Scale, NewWidth, StartSize.Y.Scale, NewHeight)
                Wireframe.Position = UDim2.new(StartPos.X.Scale, NewPosX, StartPos.Y.Scale, NewPosY)
            end
        end)

        EndedConn = InputService.InputEnded:Connect(function(EndInput)
            if EndInput.UserInputType == Enum.UserInputType.MouseButton1 or EndInput.UserInputType == Enum.UserInputType.Touch then
                ChangedConn:Disconnect()
                EndedConn:Disconnect()

                Instance.Size = Wireframe.Size
                Instance.Position = Wireframe.Position
                Wireframe:Destroy()
            end
        end)
    end)

    return Grip
end;

function Library:AddToolTip(InfoStr, HoverInstance)
    local X, Y = Library:GetTextBounds(InfoStr, Library.Font, Library.FontSize);
    local Tooltip = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,

        Size = UDim2.fromOffset(X + 5, Y + 4),
        ZIndex = 100,
        Parent = Library.ScreenGui,

        Visible = false,
    })

    local Label = Library:CreateLabel({
        Position = UDim2.fromOffset(3, 1),
        Size = UDim2.fromOffset(X, Y);
        TextSize = Library.FontSize;
        Text = InfoStr,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = Tooltip.ZIndex + 1,

        Parent = Tooltip;
    });
    Library:AddToRegistry(Tooltip, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });
    Library:AddToRegistry(Label, {
        TextColor3 = 'FontColor',
    });
    local IsHovering = false

    HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then
            return
        end

        IsHovering = true

        Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        Tooltip.Visible = true

        while IsHovering do
            RunService.Heartbeat:Wait()
            Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        end
    end)

    HoverInstance.MouseLeave:Connect(function()
        IsHovering = false
        Tooltip.Visible = false
    end)
end

function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault)
    HighlightInstance.MouseEnter:Connect(function()
        local Reg = Library.RegistryMap[Instance];

        for Property, ColorIdx in next, Properties do
            Instance[Property] = Library[ColorIdx] or ColorIdx;

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;
    end)

    HighlightInstance.MouseLeave:Connect(function()
        local Reg = Library.RegistryMap[Instance];

        for Property, ColorIdx in next, PropertiesDefault do
            Instance[Property] = Library[ColorIdx] or ColorIdx;

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;
    end)
end;

function Library:MouseIsOverOpenedFrame()
    for Frame, _ in next, Library.OpenedFrames do
        local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;
        if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
            and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then

            return true;
        end;
    end;
end;

function Library:IsMouseOverFrame(Frame)
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;
    if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
        and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then

        return true;
    end;
end;

function Library:UpdateDependencyBoxes()
    for _, Depbox in next, Library.DependencyBoxes do
        Depbox:Update();
    end;
end;

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB;
end;

function Library:GetTextBounds(Text, Font, Size, Resolution)
    local Bounds = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920, 1080))
    return Bounds.X, Bounds.Y
end;

function Library:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color);
    return Color3.fromHSV(H, S, V / 1.5);
end;

Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor);

function Library:AddToRegistry(Instance, Properties, IsHud)
    local Idx = #Library.Registry + 1;
    local Data = {
        Instance = Instance;
        Properties = Properties;
        Idx = Idx;
    };

    table.insert(Library.Registry, Data);
    Library.RegistryMap[Instance] = Data;

    if IsHud then
        table.insert(Library.HudRegistry, Data);
    end;
end;

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance];

    if Data then
        for Idx = #Library.Registry, 1, -1 do
            if Library.Registry[Idx] == Data then
                table.remove(Library.Registry, Idx);
            end;
        end;

        for Idx = #Library.HudRegistry, 1, -1 do
            if Library.HudRegistry[Idx] == Data then
                table.remove(Library.HudRegistry, Idx);
            end;
        end;

        Library.RegistryMap[Instance] = nil;
    end;
end;

function Library:UpdateColorsUsingRegistry()
    for Idx, Object in next, Library.Registry do
        for Property, ColorIdx in next, Object.Properties do
            if type(ColorIdx) == 'string' then
                Object.Instance[Property] = Library[ColorIdx];
            elseif type(ColorIdx) == 'function' then
                Object.Instance[Property] = ColorIdx()
            end
        end;
    end;
end;

function Library:GiveSignal(Signal)
    table.insert(Library.Signals, Signal)
end

function Library:Unload()
    for Idx = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Idx)
        Connection:Disconnect()
    end

    if Library.OnUnload then
        Library.OnUnload()
    end

    if Library.BlurEffect then
        Library.BlurEffect:Destroy()
    end

    ScreenGui:Destroy()
end

function Library:OnUnload(Callback)
    Library.OnUnload = Callback
end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
    if Library.RegistryMap[Instance] then
        Library:RemoveFromRegistry(Instance);
    end;
end))

local BaseAddons = {};
do
    local Funcs = {};

    function Funcs:AddColorPicker(Idx, Info)
        local ToggleLabel = self.TextLabel;
        assert(Info.Default, 'AddColorPicker: Missing default value.');

        local ColorPicker = {
            Value = Info.Default;
            Transparency = Info.Transparency or 0;
            Type = 'ColorPicker';
            Title = type(Info.Title) == 'string' and Info.Title or 'Color picker',
            Callback = Info.Callback or function(Color) end;
        };

        function ColorPicker:SetHSVFromRGB(Color)
            local H, S, V = Color3.toHSV(Color);
            ColorPicker.Hue = H;
            ColorPicker.Sat = S;
            ColorPicker.Vib = V;
        end;

        ColorPicker:SetHSVFromRGB(ColorPicker.Value);
        local DisplayFrame = Library:Create('Frame', {
            BackgroundColor3 = ColorPicker.Value;
            BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(0, 28, 0, 14);
            ZIndex = 6;
            Parent = ToggleLabel;
        });
        local CheckerFrame = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(0, 27, 0, 13);
            ZIndex = 5;
            Image = 'http://www.roblox.com/asset/?id=12977615774';
            Visible = not not Info.Transparency;
            Parent = DisplayFrame;
        });

        local PickerFrameOuter = Library:Create('Frame', {
            Name = 'Color';
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18),
            Size = UDim2.fromOffset(230, Info.Transparency and 271 or 253);
            Visible = false;
            ZIndex = 15;
            Parent = ScreenGui,
        });
        DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            PickerFrameOuter.Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18);
        end)

        local PickerFrameInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 16;
            Parent = PickerFrameOuter;
        });
        local Highlight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 0, 2);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });
        local SatVibMapOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 4, 0, 25);
            Size = UDim2.new(0, 200, 0, 200);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });
        local SatVibMapInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = SatVibMapOuter;
        });
        local SatVibMap = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Image = 'rbxassetid://4155801252';
            Parent = SatVibMapInner;
        });
        local CursorOuter = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0.5, 0.5);
            Size = UDim2.new(0, 6, 0, 6);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ImageColor3 = Color3.new(0, 0, 0);
            ZIndex = 19;
            Parent = SatVibMap;
        });
        local CursorInner = Library:Create('ImageLabel', {
            Size = UDim2.new(0, CursorOuter.Size.X.Offset - 2, 0, CursorOuter.Size.Y.Offset - 2);
            Position = UDim2.new(0, 1, 0, 1);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ZIndex = 20;
            Parent = CursorOuter;
        })

        local HueSelectorOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 208, 0, 25);
            Size = UDim2.new(0, 15, 0, 200);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local HueSelectorInner = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = HueSelectorOuter;
        });
        local HueCursor = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1);
            AnchorPoint = Vector2.new(0, 0.5);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, 0, 0, 1);
            ZIndex = 18;
            Parent = HueSelectorInner;
        });

        local HueBoxOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(4, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            ZIndex = 18,
            Parent = PickerFrameInner;
        });
        local HueBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18,
            Parent = HueBoxOuter;
        });
        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = HueBoxInner;
        });

        local HueBox = Library:Create('TextBox', {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = 'Hex color',
            Text = '#FFFFFF',
            TextColor3 = Library.FontColor;
            TextSize = Library.FontSize;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 20,
            Parent = HueBoxInner;
        });

        Library:ApplyTextStroke(HueBox);

        local RgbBoxBase = Library:Create(HueBoxOuter:Clone(), {
            Position = UDim2.new(0.5, 2, 0, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            Parent = PickerFrameInner
        });
        local RgbBox = Library:Create(RgbBoxBase.Frame:FindFirstChild('TextBox'), {
            Text = '255, 255, 255',
            PlaceholderText = 'RGB color',
            TextColor3 = Library.FontColor
        });
        local TransparencyBoxOuter, TransparencyBoxInner, TransparencyCursor;

        if Info.Transparency then
            TransparencyBoxOuter = Library:Create('Frame', {
                BorderColor3 = Color3.new(0, 0, 0);
                Position = UDim2.fromOffset(4, 251);
                Size = UDim2.new(1, -8, 0, 15);
                ZIndex = 19;
                Parent = PickerFrameInner;
            });
            TransparencyBoxInner = Library:Create('Frame', {
                BackgroundColor3 = ColorPicker.Value;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 19;
                Parent = TransparencyBoxOuter;
            });
            Library:AddToRegistry(TransparencyBoxInner, { BorderColor3 = 'OutlineColor' });

            Library:Create('ImageLabel', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 1, 0);
                Image = 'http://www.roblox.com/asset/?id=12978095818';
                ZIndex = 20;
                Parent = TransparencyBoxInner;
            });
            TransparencyCursor = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(1, 1, 1);
                AnchorPoint = Vector2.new(0.5, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(0, 1, 1, 0);
                ZIndex = 21;
                Parent = TransparencyBoxInner;
            });
        end;

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 14);
            Position = UDim2.fromOffset(5, 5);
            TextXAlignment = Enum.TextXAlignment.Left;
            TextSize = Library.FontSize;
            Text = ColorPicker.Title,
            TextWrapped = false;
            ZIndex = 16;
            Parent = PickerFrameInner;
        });
        local ContextMenu = {}
        do
            ContextMenu.Options = {}
            ContextMenu.Container = Library:Create('Frame', {
                BorderColor3 = Color3.new(),
                ZIndex = 14,
                Visible = false,
                Parent = ScreenGui
            })

            ContextMenu.Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.fromScale(1, 1);
                ZIndex = 15;
                Parent = ContextMenu.Container;
            });
            Library:Create('UIListLayout', {
                Name = 'Layout',
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = ContextMenu.Inner;
            });
            Library:Create('UIPadding', {
                Name = 'Padding',
                PaddingLeft = UDim.new(0, 4),
                Parent = ContextMenu.Inner,
            });
            local function updateMenuPosition()
                ContextMenu.Container.Position = UDim2.fromOffset(
                    (DisplayFrame.AbsolutePosition.X + DisplayFrame.AbsoluteSize.X) + 4,
                    DisplayFrame.AbsolutePosition.Y + 1
                )
            end

            local function updateMenuSize()
                local menuWidth = 60
                for i, label in next, ContextMenu.Inner:GetChildren() do
                    if label:IsA('TextLabel') then
                        menuWidth = math.max(menuWidth, label.TextBounds.X)
                    end
                end

                ContextMenu.Container.Size = UDim2.fromOffset(
                    menuWidth + 8,
                    ContextMenu.Inner.Layout.AbsoluteContentSize.Y + 4
                )
            end

            DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(updateMenuPosition)
            ContextMenu.Inner.Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(updateMenuSize)

            task.spawn(updateMenuPosition)
            task.spawn(updateMenuSize)

            Library:AddToRegistry(ContextMenu.Inner, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });

            function ContextMenu:Show()
                self.Container.Visible = true
            end

            function ContextMenu:Hide()
                self.Container.Visible = false
            end

            function ContextMenu:AddOption(Str, Callback)
                if type(Callback) ~= 'function' then
                    Callback = function() end
                end

                local Button = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, 0, 0, 15);
                    TextSize = Library.FontSize - 1;
                    Text = Str;
                    ZIndex = 16;
                    Parent = self.Inner;
                    TextXAlignment = Enum.TextXAlignment.Left,
                });
                Library:OnHighlight(Button, Button,
                    { TextColor3 = 'AccentColor' },
                    { TextColor3 = 'FontColor' }
                );
                Button.InputBegan:Connect(function(Input)
                    if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then
                        return
                    end

                    Callback()
                end)
            end

            ContextMenu:AddOption('Copy color', function()
                Library.ColorClipboard = ColorPicker.Value
                Library:Notify('Copied color!', 2)
            end)

            ContextMenu:AddOption('Paste color', function()
                if not Library.ColorClipboard then
                    return Library:Notify('You have not copied a color!', 2)
                end
                ColorPicker:SetValueRGB(Library.ColorClipboard)
            end)

            ContextMenu:AddOption('Copy HEX', function()
                pcall(setclipboard, ColorPicker.Value:ToHex())
                Library:Notify('Copied hex code to clipboard!', 2)
            end)

            ContextMenu:AddOption('Copy RGB', function()
                pcall(setclipboard, table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', '))
                Library:Notify('Copied RGB values to clipboard!', 2)
            end)

        end

        Library:AddToRegistry(PickerFrameInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(Highlight, { BackgroundColor3 = 'AccentColor'; });
        Library:AddToRegistry(SatVibMapInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(HueBoxInner, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(RgbBoxBase.Frame, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(RgbBox, { TextColor3 = 'FontColor', });
        Library:AddToRegistry(HueBox, { TextColor3 = 'FontColor', });

        local SequenceTable = {};
        for Hue = 0, 1, 0.1 do
            table.insert(SequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)));
        end;

        local HueSelectorGradient = Library:Create('UIGradient', {
            Color = ColorSequence.new(SequenceTable);
            Rotation = 90;
            Parent = HueSelectorInner;
        });
        HueBox.FocusLost:Connect(function(enter)
            if enter then
                local success, result = pcall(Color3.fromHex, HueBox.Text)
                if success and typeof(result) == 'Color3' then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(result)
                end
            end

            ColorPicker:Display()
        end)

        RgbBox.FocusLost:Connect(function(enter)
            if enter then
                local r, g, b = RgbBox.Text:match('(%d+),%s*(%d+),%s*(%d+)')
                if r and g and b then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(Color3.fromRGB(r, g, b))
                end
            end

            ColorPicker:Display()
        end)

        function ColorPicker:Display()
            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib);
            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1);

            Library:Create(DisplayFrame, {
                BackgroundColor3 = ColorPicker.Value;
                BackgroundTransparency = ColorPicker.Transparency;
                BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
            });
            if TransparencyBoxInner then
                TransparencyBoxInner.BackgroundColor3 = ColorPicker.Value;
                TransparencyCursor.Position = UDim2.new(1 - ColorPicker.Transparency, 0, 0, 0);
            end;

            CursorOuter.Position = UDim2.new(ColorPicker.Sat, 0, 1 - ColorPicker.Vib, 0);
            HueCursor.Position = UDim2.new(0, 0, ColorPicker.Hue, 0);

            HueBox.Text = '#' .. ColorPicker.Value:ToHex()
            RgbBox.Text = table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', ')

            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value);
            Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value);
        end;

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func;
            Func(ColorPicker.Value)
        end;

        function ColorPicker:Show()
            for Frame, Val in next, Library.OpenedFrames do
                if Frame.Name == 'Color' then
                    Frame.Visible = false;
                    Library.OpenedFrames[Frame] = nil;
                end;
            end;

            PickerFrameOuter.Visible = true;
            Library.OpenedFrames[PickerFrameOuter] = true;
        end;
        function ColorPicker:Hide()
            PickerFrameOuter.Visible = false;
            Library.OpenedFrames[PickerFrameOuter] = nil;
        end;
        function ColorPicker:SetValue(HSV, Transparency)
            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3]);
            ColorPicker.Transparency = Transparency or 0;
            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;

        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Transparency = Transparency or 0;
            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;

        SatVibMap.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                local function UpdateColor(PosX, PosY)
                    local MinX = SatVibMap.AbsolutePosition.X;
                    local MaxX = MinX + SatVibMap.AbsoluteSize.X;
                    local MouseX = math.clamp(PosX, MinX, MaxX);

                    local MinY = SatVibMap.AbsolutePosition.Y;
                    local MaxY = MinY + SatVibMap.AbsoluteSize.Y;
                    local MouseY = math.clamp(PosY, MinY, MaxY);

                    ColorPicker.Sat = (MouseX - MinX) / (MaxX - MinX);
                    ColorPicker.Vib = 1 - ((MouseY - MinY) / (MaxY - MinY));
                    ColorPicker:Display();
                end

                UpdateColor(Input.Position.X, Input.Position.Y)

                local ChangedConn = InputService.InputChanged:Connect(function(Change)
                    if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                        UpdateColor(Change.Position.X, Change.Position.Y)
                    end
                end)

                local EndedConn
                EndedConn = InputService.InputEnded:Connect(function(EndInput)
                    if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                        ChangedConn:Disconnect()
                        EndedConn:Disconnect()
                        Library:AttemptSave()
                    end
                end)
            end
        end);
        HueSelectorInner.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                local function UpdateHue(PosY)
                    local MinY = HueSelectorInner.AbsolutePosition.Y;
                    local MaxY = MinY + HueSelectorInner.AbsoluteSize.Y;
                    local MouseY = math.clamp(PosY, MinY, MaxY);

                    ColorPicker.Hue = ((MouseY - MinY) / (MaxY - MinY));
                    ColorPicker:Display();
                end

                UpdateHue(Input.Position.Y)

                local ChangedConn = InputService.InputChanged:Connect(function(Change)
                    if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                        UpdateHue(Change.Position.Y)
                    end
                end)

                local EndedConn
                EndedConn = InputService.InputEnded:Connect(function(EndInput)
                    if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                        ChangedConn:Disconnect()
                        EndedConn:Disconnect()
                        Library:AttemptSave()
                    end
                end)
            end
        end);
        DisplayFrame.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                if PickerFrameOuter.Visible then
                    ColorPicker:Hide()
                else
                    ContextMenu:Hide()
                    ColorPicker:Show()
                end;
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ContextMenu:Show()
                ColorPicker:Hide()
            end
        end);

        if TransparencyBoxInner then
            TransparencyBoxInner.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    local function UpdateAlpha(PosX)
                        local MinX = TransparencyBoxInner.AbsolutePosition.X;
                        local MaxX = MinX + TransparencyBoxInner.AbsoluteSize.X;
                        local MouseX = math.clamp(PosX, MinX, MaxX);

                        ColorPicker.Transparency = 1 - ((MouseX - MinX) / (MaxX - MinX));
                        ColorPicker:Display();
                    end

                    UpdateAlpha(Input.Position.X)

                    local ChangedConn = InputService.InputChanged:Connect(function(Change)
                        if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                            UpdateAlpha(Change.Position.X)
                        end
                    end)

                    local EndedConn
                    EndedConn = InputService.InputEnded:Connect(function(EndInput)
                        if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                            ChangedConn:Disconnect()
                            EndedConn:Disconnect()
                            Library:AttemptSave()
                        end
                    end)
                end
            end);
        end;

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                local AbsPos, AbsSize = PickerFrameOuter.AbsolutePosition, PickerFrameOuter.AbsoluteSize;
                local DFPos = DisplayFrame.AbsolutePosition;
                local DFSize = DisplayFrame.AbsoluteSize;

                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < DFPos.Y or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    if not (Mouse.X >= DFPos.X and Mouse.X <= DFPos.X + DFSize.X
                        and Mouse.Y >= DFPos.Y and Mouse.Y <= DFPos.Y + DFSize.Y) then
                        ColorPicker:Hide();
                    end
                end;

                if not Library:IsMouseOverFrame(ContextMenu.Container) then
                    ContextMenu:Hide()
                end
            end;

            if Input.UserInputType == Enum.UserInputType.MouseButton2 and ContextMenu.Container.Visible then
                if not Library:IsMouseOverFrame(ContextMenu.Container) and not Library:IsMouseOverFrame(DisplayFrame) then
                    ContextMenu:Hide()
                end
            end
        end))

        function ColorPicker:GetTransparency()
            return ColorPicker.Transparency;
        end;

        function ColorPicker:OnTransparencyChanged(Func)
            ColorPicker.TransparencyChanged = Func;
            Func(ColorPicker.Transparency);
        end;

        local _OrigDisplay = ColorPicker.Display;
        ColorPicker.Display = function(self)
            _OrigDisplay(self);
            Library:SafeCallback(ColorPicker.TransparencyChanged, ColorPicker.Transparency);
        end;

        ColorPicker:Display();
        ColorPicker.DisplayFrame = DisplayFrame

        Options[Idx] = ColorPicker;

        return self;
    end;

    function Funcs:AddColorPickerAlpha(Idx, Info)
        Info = Info or {};
        if Info.Transparency == nil then
            Info.Transparency = 0;
        end;
        return Funcs.AddColorPicker(self, Idx, Info);
    end;

    function Funcs:AddKeyPicker(Idx, Info)
        local ParentObj = self;
        local ToggleLabel = self.TextLabel;
        local Container = self.Container;

        assert(Info.Default, 'AddKeyPicker: Missing default value.');

        local KeyPicker = {
            Value = Info.Default;
            Toggled = false;
            Mode = Info.Mode or 'Toggle';
            Type = 'KeyPicker';
            Callback = Info.Callback or function(Value) end;
            ChangedCallback = Info.ChangedCallback or function(New) end;

            SyncToggleState = Info.SyncToggleState or false;
        };
        if KeyPicker.SyncToggleState then
            Info.Modes = { 'Toggle' }
            Info.Mode = 'Toggle'
        end

        local PickOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 28, 0, 15);
            ZIndex = 6;
            Parent = ToggleLabel;
        });
        local PickInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 7;
            Parent = PickOuter;
        });
        Library:AddToRegistry(PickInner, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });
        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = Library.FontSize - 1;
            Text = Info.Default;
            TextWrapped = true;
            ZIndex = 8;
            Parent = PickInner;
        });
        local ModeSelectOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
            Size = UDim2.new(0, 60, 0, 45 + 2);
            Visible = false;
            ZIndex = 14;
            Parent = ScreenGui;
        });
        ToggleLabel:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            ModeSelectOuter.Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
        end);
        local ModeSelectInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 15;
            Parent = ModeSelectOuter;
        });
        Library:AddToRegistry(ModeSelectInner, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });
        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ModeSelectInner;
        });
        local KeybindEntry = Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Visible = false,
            ZIndex = 110,
            Parent = Library.KeybindContainer,
        })

        local ContainerLabel = Library:CreateLabel({
            Position = UDim2.new(0, 2, 0, 0),
            Size = UDim2.new(1, -4, 1, 0),
            TextSize = Library.FontSize - 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 111,
            Parent = KeybindEntry,
        }, true)

        local Modes = Info.Modes or { 'Always', 'Toggle', 'Hold' };
        local ModeButtons = {};

        for Idx, Mode in next, Modes do
            local ModeButton = {};
            local Label = Library:CreateLabel({
                Active = false;
                Size = UDim2.new(1, 0, 0, 15);
                TextSize = Library.FontSize - 1;
                Text = Mode;
                ZIndex = 16;
                Parent = ModeSelectInner;
            });
            function ModeButton:Select()
                for _, Button in next, ModeButtons do
                    Button:Deselect();
                end;

                KeyPicker.Mode = Mode;

                Label.TextColor3 = Library.AccentColor;
                Library.RegistryMap[Label].Properties.TextColor3 = 'AccentColor';

                ModeSelectOuter.Visible = false;
            end;
            function ModeButton:Deselect()
                KeyPicker.Mode = nil;
                Label.TextColor3 = Library.FontColor;
                Library.RegistryMap[Label].Properties.TextColor3 = 'FontColor';
            end;

            Label.InputBegan:Connect(function(Input)
                if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                    ModeButton:Select();
                    Library:AttemptSave();
                end;
            end);
            if Mode == KeyPicker.Mode then
                ModeButton:Select();
            end;

            ModeButtons[Mode] = ModeButton;
        end;

        function KeyPicker:Update()
            if Info.NoUI then
                return;
            end;

            local State = KeyPicker:GetState();

            local displayKey = (KeyPicker.Value == 'None') and '...' or KeyPicker.Value
            ContainerLabel.Text = string.format('[%s] %s (%s)', displayKey, Info.Text, KeyPicker.Mode);
            local kbMode = Library.KeybindMode or 'All'
            if kbMode == 'Active' then
                KeybindEntry.Visible = State == true
            elseif kbMode == 'Toggled' then
                local parentOn = false
                if ParentObj and ParentObj.Type == 'Toggle' then
                    parentOn = ParentObj.Value == true
                elseif KeyPicker.SyncToggleState and ParentObj then
                    parentOn = ParentObj.Value == true
                else
                    parentOn = true
                end
                KeybindEntry.Visible = parentOn
            else
                KeybindEntry.Visible = true
            end

            ContainerLabel.TextColor3 = State and Library.AccentColor or Library.FontColor;
            Library.RegistryMap[ContainerLabel].Properties.TextColor3 = State and 'AccentColor' or 'FontColor';

            local YSize = 0
            local XSize = 0

            for _, Frame in next, Library.KeybindContainer:GetChildren() do
                if Frame:IsA('Frame') and Frame.Visible then
                    YSize = YSize + 18;
                    local LabelChild = Frame:FindFirstChildOfClass('TextLabel')
                    if LabelChild and (LabelChild.TextBounds.X + 20 > XSize) then
                        XSize = LabelChild.TextBounds.X + 20
                    end
                end;
            end;

            Library.KeybindFrame.Size = UDim2.new(0, math.max(XSize + 10 + 15, 210), 0, YSize + 23)
        end;
        function KeyPicker:GetState()
            if KeyPicker.Mode == 'Always' then
                return true;
            elseif KeyPicker.Mode == 'Hold' then
                if KeyPicker.Value == 'None' then
                    return false;
                end

                local Key = KeyPicker.Value;
                if Key == 'MB1' or Key == 'MB2' or Key == 'Touch' then
                    return Key == 'MB1' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                        or Key == 'MB2' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                        or Key == 'Touch' and true
                else
                    return InputService:IsKeyDown(Enum.KeyCode[KeyPicker.Value]);
                end;
            else
                return KeyPicker.Toggled;
            end;
        end;

        function KeyPicker:SetValue(Data)
            local Key, Mode = Data[1], Data[2];
            DisplayLabel.Text = Key;
            KeyPicker.Value = Key;
            ModeButtons[Mode]:Select();
            KeyPicker:Update();
        end;

        function KeyPicker:OnClick(Callback)
            KeyPicker.Clicked = Callback
        end

        function KeyPicker:OnChanged(Callback)
            KeyPicker.Changed = Callback
            Callback(KeyPicker.Value)
        end

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, KeyPicker)
            table.insert(Library.KeyPickerList, KeyPicker)
        end

        function KeyPicker:DoClick()
            if ParentObj.Type == 'Toggle' and KeyPicker.SyncToggleState then
                ParentObj:SetValue(not ParentObj.Value)
            end

            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)
        end

        local Picking = false;
        PickOuter.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                Picking = true;

                DisplayLabel.Text = '';

                local Break;
                local Text = '';

                task.spawn(function()
                    while (not Break) do
                        if Text == '...' then
                            Text = '';
                        end;

                        Text = Text .. '.';
                        DisplayLabel.Text = Text;

                        wait(0.4);
                    end;
                end);

                wait(0.2);

                local Event;
                Event = InputService.InputBegan:Connect(function(Input)
                    local Key;

                    if Input.UserInputType == Enum.UserInputType.Keyboard then
                        Key = Input.KeyCode.Name;
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Key = 'MB1';
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                        Key = 'MB2';
                    elseif Input.UserInputType == Enum.UserInputType.Touch then
                        Key = 'Touch';
                    end;

                    Break = true;
                    Picking = false;

                    DisplayLabel.Text = Key;
                    KeyPicker.Value = Key;
                    Library:SafeCallback(KeyPicker.ChangedCallback, Input.KeyCode or Input.UserInputType)
                    Library:SafeCallback(KeyPicker.Changed, Input.KeyCode or Input.UserInputType)

                    Library:AttemptSave();
                    Event:Disconnect();
                end);
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ModeSelectOuter.Visible = true;
            end;
        end);

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if (not Picking) then
                if KeyPicker.Mode == 'Toggle' then
                    local Key = KeyPicker.Value;

                    if Key == 'MB1' or Key == 'MB2' or Key == 'Touch' then
                        if Key == 'MB1' and Input.UserInputType == Enum.UserInputType.MouseButton1
                        or Key == 'MB2' and Input.UserInputType == Enum.UserInputType.MouseButton2
                        or Key == 'Touch' and Input.UserInputType == Enum.UserInputType.Touch then
                            KeyPicker.Toggled = not KeyPicker.Toggled
                            KeyPicker:DoClick()
                        end;
                    elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                        if Input.KeyCode.Name == Key then
                            KeyPicker.Toggled = not KeyPicker.Toggled;
                            KeyPicker:DoClick()
                        end;
                    end;
                end;

                KeyPicker:Update();
            end;
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                local AbsPos, AbsSize = ModeSelectOuter.AbsolutePosition, ModeSelectOuter.AbsoluteSize;
                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    ModeSelectOuter.Visible = false;
                end;
            end;
        end))

        Library:GiveSignal(InputService.InputEnded:Connect(function(Input)
            if (not Picking) then
                KeyPicker:Update();
            end;
        end))

        KeyPicker:Update();
        Options[Idx] = KeyPicker;

        return self;
    end;

    BaseAddons.__index = Funcs;
    BaseAddons.__namecall = function(Table, Key, ...)
        return Funcs[Key](...);
    end;
end;

local BaseGroupbox = {};

do
    local Funcs = {};
    function Funcs:AddBlank(Size)
        local Groupbox = self;
        local Container = Groupbox.Container;
        Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, Size);
            ZIndex = 1;
            Parent = Container;
        });
    end;

    function Funcs:AddRow(Columns)
        local Groupbox = self
        local Container = Groupbox.Container

        local ColumnsCount = type(Columns) == 'number' and math.max(1, Columns) or 2

        local RowOuter = Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            ZIndex = 1,
            Parent = Container
        })

        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = RowOuter
        })

        local Boxes = {}

        for i = 1, ColumnsCount do
            local Box = { Type = 'Groupbox' }

            local BoxContainer = Library:Create('Frame', {
                BackgroundTransparency = 1,
                Size = UDim2.new(1 / ColumnsCount, -((ColumnsCount - 1) * 8) / ColumnsCount, 1, 0),
                ZIndex = 1,
                Parent = RowOuter
            })

            local BoxLayout = Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4),
                Parent = BoxContainer
            })

            Box.Container = BoxContainer
            setmetatable(Box, BaseGroupbox)

            function Box:Resize()
                local maxHeight = 0
                for _, child in next, RowOuter:GetChildren() do
                    if child:IsA('Frame') then
                        local layout = child:FindFirstChildOfClass('UIListLayout')
                        if layout and layout.AbsoluteContentSize.Y > maxHeight then
                            maxHeight = layout.AbsoluteContentSize.Y
                        end
                    end
                end
                RowOuter.Size = UDim2.new(1, 0, 0, maxHeight)
                if Groupbox.Resize then
                    Groupbox:Resize()
                end
            end

            BoxLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                Box:Resize()
            end)

            table.insert(Boxes, Box)
        end

        Groupbox:AddBlank(1)
        if Groupbox.Resize then Groupbox:Resize() end

        return unpack(Boxes)
    end;
    function Funcs:AddLabel(Text, DoesWrap)
        local Label = {};

        local Groupbox = self;
        local Container = Groupbox.Container;

        local TextLabel = Library:CreateLabel({
            Size = UDim2.new(1, -4, 0, 15);
            TextSize = Library.FontSize;
            Text = Text;
            TextWrapped = DoesWrap or false,
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container;
        });
        if DoesWrap then
            local Y = select(2, Library:GetTextBounds(Text, Library.Font, Library.FontSize, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
            TextLabel.Size = UDim2.new(1, -4, 0, Y)
        else
            Library:Create('UIListLayout', {
                Padding = UDim.new(0, 4);
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Right;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TextLabel;
            });
        end

        Label.TextLabel = TextLabel;
        Label.Container = Container;
        function Label:SetText(Text)
            TextLabel.Text = Text

            if DoesWrap then
                local Y = select(2, Library:GetTextBounds(Text, Library.Font, Library.FontSize, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
                TextLabel.Size = UDim2.new(1, -4, 0, Y)
            end

            Groupbox:Resize();
        end

        if (not DoesWrap) then
            setmetatable(Label, BaseAddons);
        end

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        return Label;
    end;
    function Funcs:AddButton(...)
        local Button = {};
        local function ProcessButtonParams(Class, Obj, ...)
            local Props = select(1, ...)
            if type(Props) == 'table' then
                Obj.Text = Props.Text
                Obj.Func = Props.Func
                Obj.DoubleClick = Props.DoubleClick
                Obj.Tooltip = Props.Tooltip
            else
                Obj.Text = select(1, ...)
                Obj.Func = select(2, ...)
            end

            assert(type(Obj.Func) == 'function', 'AddButton: `Func` callback is missing.');
        end

        ProcessButtonParams('Button', Button, ...)

        local Groupbox = self;
        local Container = Groupbox.Container;

        local function CreateBaseButton(Button)
            local Outer = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(0, 0, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -4, 0, 20);
                ZIndex = 5;
            });
            local Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.MainColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 6;
                Parent = Outer;
            });
            local Label = Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0);
                TextSize = Library.FontSize;
                Text = Button.Text;
                ZIndex = 6;
                Parent = Inner;
            });

            Library:Create('UIGradient', {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
                });
                Rotation = 90;
                Parent = Inner;
            });
            Library:AddToRegistry(Outer, {
                BorderColor3 = 'Black';
            });
            Library:AddToRegistry(Inner, {
                BackgroundColor3 = 'MainColor';
                BorderColor3 = 'OutlineColor';
            });
            Library:OnHighlight(Outer, Outer,
                { BorderColor3 = 'AccentColor' },
                { BorderColor3 = 'Black' }
            );
            return Outer, Inner, Label
        end

        local function InitEvents(Button)
            local function WaitForEvent(event, timeout, validator)
                local bindable = Instance.new('BindableEvent')
                local connection = event:Once(function(...)

                    if type(validator) == 'function' and validator(...) then
                        bindable:Fire(true)
                    else
                        bindable:Fire(false)
                    end
                end)
                task.delay(timeout, function()
                    connection:disconnect()
                    bindable:Fire(false)
                end)
                return bindable.Event:Wait()
            end

            local function ValidateClick(Input)
                if Library:MouseIsOverOpenedFrame() then
                    return false
                end

                if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then
                    return false
                end

                return true
            end

            Button.Outer.InputBegan:Connect(function(Input)
                if not ValidateClick(Input) then return end

                if Button.Locked then return end

                if Button.DoubleClick then
                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, { TextColor3 = 'AccentColor' })

                    Button.Label.TextColor3 = Library.AccentColor
                    Button.Label.Text = 'Are you sure?'
                    Button.Locked = true

                    local clicked = WaitForEvent(Button.Outer.InputBegan, 0.5, ValidateClick)

                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, { TextColor3 = 'FontColor' })

                    Button.Label.TextColor3 = Library.FontColor
                    Button.Label.Text = Button.Text
                    task.defer(rawset, Button, 'Locked', false)

                    if clicked then
                        Library:SafeCallback(Button.Func)
                    end

                    return
                end

                Library:SafeCallback(Button.Func);
            end)
        end

        Button.Outer, Button.Inner, Button.Label = CreateBaseButton(Button)
        Button.Outer.Parent = Container

        InitEvents(Button)

        function Button:AddTooltip(tooltip)
            if type(tooltip) == 'string' then
                Library:AddToolTip(tooltip, self.Outer)
            end
            return self
        end

        function Button:AddButton(...)
            local SubButton = {}

            ProcessButtonParams('SubButton', SubButton, ...)

            self.Outer.Size = UDim2.new(0.5, -2, 0, 20)

            SubButton.Outer, SubButton.Inner, SubButton.Label = CreateBaseButton(SubButton)

            SubButton.Outer.Position = UDim2.new(1, 3, 0, 0)
            SubButton.Outer.Size = UDim2.fromOffset(self.Outer.AbsoluteSize.X - 2, self.Outer.AbsoluteSize.Y)
            SubButton.Outer.Parent = self.Outer

            function SubButton:AddTooltip(tooltip)
                if type(tooltip) == 'string' then
                    Library:AddToolTip(tooltip, self.Outer)
                 end
                return SubButton
            end

            if type(SubButton.Tooltip) == 'string' then
                SubButton:AddTooltip(SubButton.Tooltip)
            end

            InitEvents(SubButton)
            return SubButton
        end

        if type(Button.Tooltip) == 'string' then
            Button:AddTooltip(Button.Tooltip)
        end

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        return Button;
    end;

    function Funcs:AddDivider()
        local Groupbox = self;
        local Container = self.Container

        local Divider = {
            Type = 'Divider',
        }

        Groupbox:AddBlank(2);
        local DividerOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 5);
            ZIndex = 5;
            Parent = Container;
        });
        local DividerInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DividerOuter;
        });
        Library:AddToRegistry(DividerOuter, {
            BorderColor3 = 'Black';
        });
        Library:AddToRegistry(DividerInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        Groupbox:AddBlank(9);
        Groupbox:Resize();
    end

    function Funcs:AddInput(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')

        local Textbox = {
            Value = Info.Default or '';
            Numeric = Info.Numeric or false;
            Finished = Info.Finished or false;
            Type = 'Input';
            Callback = Info.Callback or function(Value) end;
        };
        local Groupbox = self;
        local Container = Groupbox.Container;

        local InputLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 15);
            TextSize = Library.FontSize;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container;
        });

        Groupbox:AddBlank(1);

        local TextBoxOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = Container;
        });
        local TextBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = TextBoxOuter;
        });
        Library:AddToRegistry(TextBoxInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        Library:OnHighlight(TextBoxOuter, TextBoxOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );
        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, TextBoxOuter)
        end

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = TextBoxInner;
        });
        local Container = Library:Create('Frame', {
            BackgroundTransparency = 1;
            ClipsDescendants = true;

            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);

            ZIndex = 7;
            Parent = TextBoxInner;
        })

        local Box = Library:Create('TextBox', {
            BackgroundTransparency = 1;

            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromScale(5, 1),

            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = Info.Placeholder or '';

            Text = Info.Default or '';
            TextColor3 = Library.FontColor;
            TextSize = Library.FontSize;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;

            ZIndex = 7;
            Parent = Container;
        });

        Library:ApplyTextStroke(Box);
        function Textbox:SetValue(Text)
            if Info.MaxLength and #Text > Info.MaxLength then
                Text = Text:sub(1, Info.MaxLength);
            end;

            if Textbox.Numeric then
                if (not tonumber(Text)) and Text:len() > 0 then
                    Text = Textbox.Value
                end
            end

            Textbox.Value = Text;
            Box.Text = Text;

            Library:SafeCallback(Textbox.Callback, Textbox.Value);
            Library:SafeCallback(Textbox.Changed, Textbox.Value);
        end;

        if Textbox.Finished then
            Box.FocusLost:Connect(function(enter)
                if not enter then return end

                Textbox:SetValue(Box.Text);
                Library:AttemptSave();
            end)
        else
            Box:GetPropertyChangedSignal('Text'):Connect(function()
                Textbox:SetValue(Box.Text);
                Library:AttemptSave();
            end);
        end

        local function Update()
            local PADDING = 2
            local reveal = Container.AbsoluteSize.X

            if not Box:IsFocused() or Box.TextBounds.X <= reveal - 2 * PADDING then
                Box.Position = UDim2.new(0, PADDING, 0, 0)
            else
                local cursor = Box.CursorPosition
                if cursor ~= -1 then
                    local subtext = string.sub(Box.Text, 1, cursor-1)
                    local width = TextService:GetTextSize(subtext, Box.TextSize, Box.Font, Vector2.new(math.huge, math.huge)).X

                    local currentCursorPos = Box.Position.X.Offset + width

                    if currentCursorPos < PADDING then
                        Box.Position = UDim2.fromOffset(PADDING-width, 0)
                    elseif currentCursorPos > reveal - PADDING - 1 then
                        Box.Position = UDim2.fromOffset(reveal-width-PADDING-1, 0)
                    end
                end
            end
        end

        task.spawn(Update)

        Box:GetPropertyChangedSignal('Text'):Connect(Update)
        Box:GetPropertyChangedSignal('CursorPosition'):Connect(Update)
        Box.FocusLost:Connect(Update)
        Box.Focused:Connect(Update)

        Library:AddToRegistry(Box, {
            TextColor3 = 'FontColor';
        });

        function Textbox:OnChanged(Func)
            Textbox.Changed = Func;
            Func(Textbox.Value);
        end;

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        Options[Idx] = Textbox;

        return Textbox;
    end;

    function Funcs:AddToggle(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')

        local Toggle = {
            Value = Info.Default or false;
            Type = 'Toggle';

            Callback = Info.Callback or function(Value) end;
            Addons = {},
            Risky = Info.Risky,
        };
        local Groupbox = self;
        local Container = Groupbox.Container;

        local ToggleOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 13, 0, 13);
            ZIndex = 5;
            Parent = Container;
        });
        Library:AddToRegistry(ToggleOuter, {
            BorderColor3 = 'Black';
        });
        local ToggleInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = ToggleOuter;
        });
        Library:AddToRegistry(ToggleInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        local ToggleLabel = Library:CreateLabel({
            Size = UDim2.new(0, 216, 1, 0);
            Position = UDim2.new(1, 6, 0, 0);
            TextSize = Library.FontSize;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 6;
            Parent = ToggleInner;
        });
        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 4);
            FillDirection = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Right;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ToggleLabel;
        });
        local ToggleRegion = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(0, 170, 1, 0);
            ZIndex = 8;
            Parent = ToggleOuter;
        });
        Library:OnHighlight(ToggleRegion, ToggleOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );
        function Toggle:UpdateColors()
            Toggle:Display();
        end;
        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, ToggleRegion)
        end

        function Toggle:Display()
            ToggleInner.BackgroundColor3 = Toggle.Value and Library.AccentColor or Library.MainColor;
            ToggleInner.BorderColor3 = Toggle.Value and Library.AccentColorDark or Library.OutlineColor;

            Library.RegistryMap[ToggleInner].Properties.BackgroundColor3 = Toggle.Value and 'AccentColor' or 'MainColor';
            Library.RegistryMap[ToggleInner].Properties.BorderColor3 = Toggle.Value and 'AccentColorDark' or 'OutlineColor';
        end;

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func;
            Func(Toggle.Value);
        end;

        function Toggle:SetValue(Bool)
            Bool = (not not Bool);
            Toggle.Value = Bool;
            Toggle:Display();

            for _, Addon in next, Toggle.Addons do
                if Addon.Type == 'KeyPicker' and Addon.SyncToggleState then
                    Addon.Toggled = Bool
                    Addon:Update()
                end
            end

            Library:SafeCallback(Toggle.Callback, Toggle.Value);
            Library:SafeCallback(Toggle.Changed, Toggle.Value);
            Library:UpdateDependencyBoxes();
        end;
        ToggleRegion.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                Toggle:SetValue(not Toggle.Value)
                Library:AttemptSave();
            end;
        end);
        if Toggle.Risky then
            Library:RemoveFromRegistry(ToggleLabel)
            ToggleLabel.TextColor3 = Library.RiskColor
            Library:AddToRegistry(ToggleLabel, { TextColor3 = 'RiskColor' })
        end

        Toggle:Display();
        Groupbox:AddBlank(Info.BlankSize or 5 + 2);
        Groupbox:Resize();

        Toggle.TextLabel = ToggleLabel;
        Toggle.Container = Container;
        setmetatable(Toggle, BaseAddons);

        Toggles[Idx] = Toggle;

        Library:UpdateDependencyBoxes();

        return Toggle;
    end;

    function Funcs:AddSlider(Idx, Info)
        assert(Info.Default, 'AddSlider: Missing default value.');
        assert(Info.Text, 'AddSlider: Missing slider text.');
        assert(Info.Min, 'AddSlider: Missing minimum value.');
        assert(Info.Max, 'AddSlider: Missing maximum value.');
        assert(Info.Rounding, 'AddSlider: Missing rounding value.');
        local Slider = {
            Value = Info.Default;
            Min = Info.Min;
            Max = Info.Max;
            Rounding = Info.Rounding;
            MaxSize = 232;
            Type = 'Slider';
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;
        if not Info.Compact then
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10);
                TextSize = Library.FontSize;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex = 5;
                Parent = Container;
            });
            Groupbox:AddBlank(3);
        end

        local SliderOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 13);
            ZIndex = 5;
            Parent = Container;
        });
        Library:AddToRegistry(SliderOuter, {
            BorderColor3 = 'Black';
        });
        local SliderInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = SliderOuter;
        });
        Library:AddToRegistry(SliderInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        local Fill = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderColor3 = Library.AccentColorDark;
            Size = UDim2.new(0, 0, 1, 0);
            ZIndex = 7;
            Parent = SliderInner;
        });
        Library:AddToRegistry(Fill, {
            BackgroundColor3 = 'AccentColor';
            BorderColor3 = 'AccentColorDark';
        });
        local HideBorderRight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Position = UDim2.new(1, 0, 0, 0);
            Size = UDim2.new(0, 1, 1, 0);
            ZIndex = 8;
            Parent = Fill;
        });

        Library:AddToRegistry(HideBorderRight, {
            BackgroundColor3 = 'AccentColor';
        });
        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = Library.FontSize;
            Text = 'Infinite';
            ZIndex = 9;
            Parent = SliderInner;
        });
        Library:OnHighlight(SliderOuter, SliderOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );
        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, SliderOuter)
        end

        function Slider:UpdateColors()
            Fill.BackgroundColor3 = Library.AccentColor;
            Fill.BorderColor3 = Library.AccentColorDark;
        end;

        function Slider:Display()
            local Suffix = Info.Suffix or '';
            if Info.Compact then
                DisplayLabel.Text = Info.Text .. ': ' .. Slider.Value .. Suffix
            elseif Info.HideMax then
                DisplayLabel.Text = string.format('%s', Slider.Value .. Suffix)
            else
                DisplayLabel.Text = string.format('%s/%s', Slider.Value .. Suffix, Slider.Max .. Suffix);
            end

            local X = math.ceil(Library:MapValue(Slider.Value, Slider.Min, Slider.Max, 0, Slider.MaxSize));
            Fill.Size = UDim2.new(0, X, 1, 0);

            HideBorderRight.Visible = not (X == Slider.MaxSize or X == 0);
        end;
        function Slider:OnChanged(Func)
            Slider.Changed = Func;
            Func(Slider.Value);
        end;
        local function Round(Value)
            if Slider.Rounding == 0 then
                return math.floor(Value);
            end;

            return tonumber(string.format('%.' .. Slider.Rounding .. 'f', Value))
        end;
        function Slider:GetValueFromXOffset(X)
            return Round(Library:MapValue(X, 0, Slider.MaxSize, Slider.Min, Slider.Max));
        end;
        function Slider:SetValue(Str)
            local Num = tonumber(Str);
            if (not Num) then
                return;
            end;

            Num = math.clamp(Num, Slider.Min, Slider.Max);

            Slider.Value = Num;
            Slider:Display();

            Library:SafeCallback(Slider.Callback, Slider.Value);
            Library:SafeCallback(Slider.Changed, Slider.Value);
        end;
        SliderInner.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then

                local function UpdateSlider(PosX)
                    local gPos = Fill.AbsolutePosition.X

                    local Diff = PosX - gPos
                    local nX = math.clamp(Diff, 0, Slider.MaxSize)

                    local nValue = Slider:GetValueFromXOffset(nX);
                    local OldValue = Slider.Value;

                    Slider.Value = nValue;

                    Slider:Display();

                    if nValue ~= OldValue then
                        Library:SafeCallback(Slider.Callback, Slider.Value);
                        Library:SafeCallback(Slider.Changed, Slider.Value);
                    end;
                end

                UpdateSlider(Input.Position.X)

                local ChangedConn = InputService.InputChanged:Connect(function(Change)
                    if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                        UpdateSlider(Change.Position.X)
                    end
                end)

                local EndedConn
                EndedConn = InputService.InputEnded:Connect(function(EndInput)
                    if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                        ChangedConn:Disconnect()
                        EndedConn:Disconnect()
                        Library:AttemptSave()
                    end
                end)
            end;
        end);

        Slider:Display();
        Groupbox:AddBlank(Info.BlankSize or 6);
        Groupbox:Resize();

        Options[Idx] = Slider;

        return Slider;
    end;
    function Funcs:AddDropdown(Idx, Info)
        if Info.SpecialType == 'Player' then
            Info.Values = GetPlayersString();
            Info.AllowNull = true;
        elseif Info.SpecialType == 'Team' then
            Info.Values = GetTeamsString();
            Info.AllowNull = true;
        end;

        assert(Info.Values, 'AddDropdown: Missing dropdown value list.');
        assert(Info.AllowNull or Info.Default, 'AddDropdown: Missing default value. Pass `AllowNull` as true if this was intentional.')

        if (not Info.Text) then
            Info.Compact = true;
        end;

        local Dropdown = {
            Values = Info.Values;
            Value = Info.Multi and {};
            Multi = Info.Multi;
            Type = 'Dropdown';
            SpecialType = Info.SpecialType;
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local RelativeOffset = 0;
        if not Info.Compact then
            local DropdownLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10);
                TextSize = Library.FontSize;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex = 5;
                Parent = Container;
            });
            Groupbox:AddBlank(3);
        end

        for _, Element in next, Container:GetChildren() do
            if not Element:IsA('UIListLayout') then
                RelativeOffset = RelativeOffset + Element.Size.Y.Offset;
            end;
        end;

        local DropdownOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = Container;
        });
        Library:AddToRegistry(DropdownOuter, {
            BorderColor3 = 'Black';
        });
        local DropdownInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DropdownOuter;
        });
        Library:AddToRegistry(DropdownInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = DropdownInner;
        });

        local DropdownArrow = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0, 0.5);
            BackgroundTransparency = 1;
            Position = UDim2.new(1, -16, 0.5, 0);
            Size = UDim2.new(0, 12, 0, 12);
            Image = 'http://www.roblox.com/asset/?id=6282522798';
            ZIndex = 8;
            Parent = DropdownInner;
        });
        local ItemList = Library:CreateLabel({
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            TextSize = Library.FontSize;
            Text = '--';
            TextXAlignment = Enum.TextXAlignment.Left;
            TextWrapped = true;
            ZIndex = 7;
            Parent = DropdownInner;
        });
        Library:OnHighlight(DropdownOuter, DropdownOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );
        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, DropdownOuter)
        end

        local MAX_DROPDOWN_ITEMS = 8;
        local ListOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            ZIndex = 20;
            Visible = false;
            Parent = ScreenGui;
        });
        local function RecalculateListPosition()
            ListOuter.Position = UDim2.fromOffset(DropdownOuter.AbsolutePosition.X, DropdownOuter.AbsolutePosition.Y + DropdownOuter.Size.Y.Offset + 1);
        end;

        local function RecalculateListSize(YSize)
            ListOuter.Size = UDim2.fromOffset(DropdownOuter.AbsoluteSize.X, YSize or (MAX_DROPDOWN_ITEMS * 20 + 2))
        end;
        RecalculateListPosition();
        RecalculateListSize();

        DropdownOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(RecalculateListPosition);

        local ListInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListOuter;
        });
        Library:AddToRegistry(ListInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        local Scrolling = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            CanvasSize = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListInner;

            TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
            BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',

            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.AccentColor,
        });
        Library:AddToRegistry(Scrolling, {
            ScrollBarImageColor3 = 'AccentColor'
        })

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 0);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Scrolling;
        });
        function Dropdown:Display()
            local Values = Dropdown.Values;
            local Str = '';

            if Info.Multi then
                for Idx, Value in next, Values do
                    if Dropdown.Value[Value] then
                        Str = Str .. Value .. ', ';
                    end;
                end;

                Str = Str:sub(1, #Str - 2);
            else
                Str = Dropdown.Value or '';
            end;

            ItemList.Text = (Str == '' and '--' or Str);
        end;
        function Dropdown:GetActiveValues()
            if Info.Multi then
                local T = {};
                for Value, Bool in next, Dropdown.Value do
                    table.insert(T, Value);
                end;

                return T;
            else
                return Dropdown.Value and 1 or 0;
            end;
        end;

        function Dropdown:BuildDropdownList()
            local Values = Dropdown.Values;
            local Buttons = {};

            for _, Element in next, Scrolling:GetChildren() do
                if not Element:IsA('UIListLayout') then
                    Element:Destroy();
                end;
            end;

            local Count = 0;

            for Idx, Value in next, Values do
                local Table = {};
                Count = Count + 1;

                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Library.OutlineColor;
                    BorderMode = Enum.BorderMode.Middle;
                    Size = UDim2.new(1, -1, 0, 20);
                    ZIndex = 23;
                    Active = true,
                    Parent = Scrolling;
                });
                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor';
                    BorderColor3 = 'OutlineColor';
                });
                local ButtonLabel = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, -6, 1, 0);
                    Position = UDim2.new(0, 6, 0, 0);
                    TextSize = Library.FontSize;
                    Text = Value;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    ZIndex = 25;
                    Parent = Button;
                });

                Library:OnHighlight(Button, Button,
                    { BorderColor3 = 'AccentColor', ZIndex = 24 },
                    { BorderColor3 = 'OutlineColor', ZIndex = 23 }
                );
                local Selected;

                if Info.Multi then
                    Selected = Dropdown.Value[Value];
                else
                    Selected = Dropdown.Value == Value;
                end;

                function Table:UpdateButton()
                    if Info.Multi then
                        Selected = Dropdown.Value[Value];
                    else
                        Selected = Dropdown.Value == Value;
                    end;

                    ButtonLabel.TextColor3 = Selected and Library.AccentColor or Library.FontColor;
                    Library.RegistryMap[ButtonLabel].Properties.TextColor3 = Selected and 'AccentColor' or 'FontColor';
                end;
                ButtonLabel.InputBegan:Connect(function(Input)
                    if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                        local Try = not Selected;

                        if Dropdown:GetActiveValues() == 1 and (not Try) and (not Info.AllowNull) then
                        else
                            if Info.Multi then
                                Selected = Try;

                                if Selected then
                                    Dropdown.Value[Value] = true;
                                else
                                    Dropdown.Value[Value] = nil;
                                end;
                            else
                                Selected = Try;

                                if Selected then
                                    Dropdown.Value = Value;
                                else
                                    Dropdown.Value = nil;
                                end;

                                for _, OtherButton in next, Buttons do
                                    OtherButton:UpdateButton();
                                end;
                            end;

                            Table:UpdateButton();
                            Dropdown:Display();

                            Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
                            Library:SafeCallback(Dropdown.Changed, Dropdown.Value);

                            Library:AttemptSave();
                        end;
                    end;
                end);

                Table:UpdateButton();
                Dropdown:Display();

                Buttons[Button] = Table;
            end;
            Scrolling.CanvasSize = UDim2.fromOffset(0, (Count * 20) + 1);

            local Y = math.clamp(Count * 20, 0, MAX_DROPDOWN_ITEMS * 20) + 1;
            RecalculateListSize(Y);
        end;

        function Dropdown:SetValues(NewValues)
            if NewValues then
                Dropdown.Values = NewValues;
            end;

            Dropdown:BuildDropdownList();
        end;

        function Dropdown:OpenDropdown()
            ListOuter.Visible = true;
            Library.OpenedFrames[ListOuter] = true;
            DropdownArrow.Rotation = 180;
        end;

        function Dropdown:CloseDropdown()
            ListOuter.Visible = false;
            Library.OpenedFrames[ListOuter] = nil;
            DropdownArrow.Rotation = 0;
        end;

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func;
            Func(Dropdown.Value);
        end;

        function Dropdown:SetValue(Val)
            if Dropdown.Multi then
                local nTable = {};
                for Value, Bool in next, Val do
                    if table.find(Dropdown.Values, Value) then
                        nTable[Value] = true
                    end;
                end;

                Dropdown.Value = nTable;
            else
                if (not Val) then
                    Dropdown.Value = nil;
                elseif table.find(Dropdown.Values, Val) then
                    Dropdown.Value = Val;
                end;
            end;

            Dropdown:BuildDropdownList();

            Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
            Library:SafeCallback(Dropdown.Changed, Dropdown.Value);
        end;

        DropdownOuter.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                if ListOuter.Visible then
                    Dropdown:CloseDropdown();
                else
                    Dropdown:OpenDropdown();
                end;
            end;
        end);
        InputService.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                local AbsPos, AbsSize = ListOuter.AbsolutePosition, ListOuter.AbsoluteSize;

                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    Dropdown:CloseDropdown();
                end;
            end;
        end);
        Dropdown:BuildDropdownList();
        Dropdown:Display();

        local Defaults = {}

        if type(Info.Default) == 'string' then
            local Idx = table.find(Dropdown.Values, Info.Default)
            if Idx then
                table.insert(Defaults, Idx)
            end
        elseif type(Info.Default) == 'table' then
            for _, Value in next, Info.Default do
                local Idx = table.find(Dropdown.Values, Value)
                if Idx then
                    table.insert(Defaults, Idx)
                end
            end
        elseif type(Info.Default) == 'number' and Dropdown.Values[Info.Default] ~= nil then
            table.insert(Defaults, Info.Default)
        end

        if next(Defaults) then
            for i = 1, #Defaults do
                local Index = Defaults[i]
                if Info.Multi then
                    Dropdown.Value[Dropdown.Values[Index]] = true
                else
                    Dropdown.Value = Dropdown.Values[Index];
                end

                if (not Info.Multi) then break end
            end

            Dropdown:BuildDropdownList();
            Dropdown:Display();
        end

        Groupbox:AddBlank(Info.BlankSize or 5);
        Groupbox:Resize();

        Options[Idx] = Dropdown;

        return Dropdown;
    end;
    function Funcs:AddDependencyBox()
        local Depbox = {
            Dependencies = {};
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local Holder = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, 0);
            Visible = false;
            Parent = Container;
        });
        local Frame = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            Visible = true;
            Parent = Holder;
        });
        local Layout = Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Frame;
        });
        function Depbox:Resize()
            Holder.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y);
            Groupbox:Resize();
        end;

        Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
            Depbox:Resize();
        end);
        Holder:GetPropertyChangedSignal('Visible'):Connect(function()
            Depbox:Resize();
        end);
        function Depbox:Update()
            for _, Dependency in next, Depbox.Dependencies do
                local Elem = Dependency[1];
                local Value = Dependency[2];

                if Elem.Type == 'Toggle' and Elem.Value ~= Value then
                    Holder.Visible = false;
                    Depbox:Resize();
                    return;
                end;
            end;

            Holder.Visible = true;
            Depbox:Resize();
        end;

        function Depbox:SetupDependencies(Dependencies)
            for _, Dependency in next, Dependencies do
                assert(type(Dependency) == 'table', 'SetupDependencies: Dependency is not of type `table`.');
                assert(Dependency[1], 'SetupDependencies: Dependency is missing element argument.');
                assert(Dependency[2] ~= nil, 'SetupDependencies: Dependency is missing value argument.');
            end;

            Depbox.Dependencies = Dependencies;
            Depbox:Update();
        end;

        Depbox.Container = Frame;

        setmetatable(Depbox, BaseGroupbox);

        table.insert(Library.DependencyBoxes, Depbox);

        return Depbox;
    end;

    BaseGroupbox.__index = Funcs;
    BaseGroupbox.__namecall = function(Table, Key, ...)
        return Funcs[Key](...);
    end;
end;
do
    Library.NotificationArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, Library.NotifyConfig.PositionX, 0, Library.NotifyConfig.PositionY);
        Size = UDim2.new(0, 300, 1, -Library.NotifyConfig.PositionY);
        ZIndex = 100;
        Parent = ScreenGui;
    });
    Library.NotifLayout = Library:Create('UIListLayout', {
        Padding = UDim.new(0, 4);
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = Library.NotificationArea;
    });
    local function Library_UpdateNotifAlignment()
        local cfg = Library.NotifyConfig
        local area = Library.NotificationArea
        local layout = Library.NotifLayout

        area.Position = UDim2.new(0, cfg.PositionX, 0, cfg.PositionY)
        area.Size     = UDim2.new(0, 300, 1, -cfg.PositionY)

        local align = cfg.Alignment or 'Left'
        if align == 'Left' then
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
            area.AnchorPoint = Vector2.new(0, 0)
        elseif align == 'Right' then
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
            area.AnchorPoint = Vector2.new(0, 0)
        elseif align == 'Center' then
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            area.AnchorPoint = Vector2.new(0, 0)
        end
    end
    Library.UpdateNotifAlignment = Library_UpdateNotifAlignment
    Library_UpdateNotifAlignment()

    local WatermarkOuter = Library:Create('Frame', {
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 100, 0, -25);
        Size = UDim2.new(0, 213, 0, 20);
        ZIndex = 200;
        Visible = false;
        Parent = ScreenGui;
    });

    local WatermarkInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.AccentColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 201;
        Parent = WatermarkOuter;
    });
    Library:AddToRegistry(WatermarkInner, {
        BorderColor3 = 'AccentColor';
    });
    local InnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 202;
        Parent = WatermarkInner;
    });
    local Gradient = Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        });
        Rotation = -90;
        Parent = InnerFrame;
    });
    Library:AddToRegistry(Gradient, {
        Color = function()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                ColorSequenceKeypoint.new(1, Library.MainColor),
            });
        end
    });
    local WatermarkLabel = Library:CreateLabel({
        Position = UDim2.new(0, 5, 0, 0);
        Size = UDim2.new(1, -4, 1, 0);
        TextSize = Library.FontSize;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 203;
        Parent = InnerFrame;
    });
    Library.Watermark = WatermarkOuter;
    Library.WatermarkText = WatermarkLabel;
    Library:MakeDraggable(Library.Watermark);

    local KeybindOuter = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0, 0.5);
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 10, 0.5, 0);
        Size = UDim2.new(0, 210, 0, 20);
        Visible = false;
        ZIndex = 100;
        Parent = ScreenGui;
    });
    Library:ApplyGlow(KeybindOuter);

    local KeybindInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = KeybindOuter;
    });
    Library:AddToRegistry(KeybindInner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    }, true);
    local ColorFrame = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 0, 2);
        ZIndex = 102;
        Parent = KeybindInner;
    });
    Library:AddToRegistry(ColorFrame, {
        BackgroundColor3 = 'AccentColor';
    }, true);
    local KeybindLabel = Library:CreateLabel({
        Size = UDim2.new(1, 0, 0, 20);
        Position = UDim2.fromOffset(5, 2),
        TextXAlignment = Enum.TextXAlignment.Left,

        Text = 'Keybinds';
        ZIndex = 104;
        Parent = KeybindInner;
    });
    local KeybindContainer = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Size = UDim2.new(1, 0, 1, -20);
        Position = UDim2.new(0, 0, 0, 20);
        ZIndex = 1;
        Parent = KeybindInner;
    });
    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = KeybindContainer;
    });
    Library:Create('UIPadding', {
        PaddingLeft = UDim.new(0, 5),
        Parent = KeybindContainer,
    })

    Library.KeybindFrame = KeybindOuter;
    Library.KeybindContainer = KeybindContainer;
    Library:MakeDraggable(KeybindOuter);
end;

function Library:SetKeybindMode(Mode)
    assert(Mode == 'All' or Mode == 'Active' or Mode == 'Toggled',
        "SetKeybindMode: Mode must be 'All', 'Active', or 'Toggled'")
    Library.KeybindMode = Mode
    Library:RefreshKeybinds()
end

function Library:RefreshKeybinds()
    for _, kp in ipairs(Library.KeyPickerList) do
        if not kp.NoUI then
            pcall(function() kp:Update() end)
        end
    end
end

function Library:SetWatermarkVisibility(Bool)
    Library.Watermark.Visible = Bool;
end;

function Library:SetWatermark(Text)
    local X, Y = Library:GetTextBounds(Text, Library.Font, Library.FontSize);
    Library.Watermark.Size = UDim2.new(0, X + 15, 0, (Y * 1.5) + 3);
    Library:SetWatermarkVisibility(true)

    Library.WatermarkText.Text = Text;
end;
function Library:Notify(Text, Time)
    local cfg     = Library.NotifyConfig
    local barSide = cfg.BarSide   or 'Left'
    local align   = cfg.Alignment or 'Left'

    local XSize, YSize = Library:GetTextBounds(Text, Library.Font, Library.FontSize)
    YSize = YSize + 7

    local BAR_THIN  = 3
    local BAR_THICK = 3

    local innerPosX  = (barSide == 'Left')   and 1 or 1
    local innerPosY  = (barSide == 'Top')    and BAR_THICK or 1
    local innerSizeW = (barSide == 'Left' or barSide == 'Right') and -2 or -2
    local innerSizeH = (barSide == 'Top' or barSide == 'Bottom') and -(BAR_THICK + 1) or -2

    local labelPosX  = (barSide == 'Left')  and BAR_THIN + 2 or 4
    local labelSizeW = (barSide == 'Left' or barSide == 'Right') and -(BAR_THIN + 4) or -4

    local outerAnchor = Vector2.new(0, 0)
    local outerPosX   = 0
    if align == 'Center' then
        outerAnchor = Vector2.new(0.5, 0)
        outerPosX   = 0
    elseif align == 'Right' then
        outerAnchor = Vector2.new(1, 0)
        outerPosX   = 0
    end

    local NotifyOuter = Library:Create('Frame', {
        BackgroundTransparency = 1;
        AnchorPoint = outerAnchor;
        BorderColor3 = Color3.new(0, 0, 0);
        Position     = (align == 'Center')
            and UDim2.new(0.5, 0, 0, 0)
            or  (align == 'Right' and UDim2.new(1, 0, 0, 0) or UDim2.new(0, 0, 0, 0));
        Size = UDim2.new(0, 0, 0, YSize);
        ClipsDescendants = true;
        ZIndex = 100;
        Parent = Library.NotificationArea;
    });
    local NotifyInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = NotifyOuter;
    });
    Library:AddToRegistry(NotifyInner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    }, true);
    local InnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, innerPosX, 0, innerPosY);
        Size     = UDim2.new(1, innerSizeW, 1, innerSizeH);
        ZIndex = 102;
        Parent = NotifyInner;
    });
    local Gradient = Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        });
        Rotation = -90;
        Parent = InnerFrame;
    });
    Library:AddToRegistry(Gradient, {
        Color = function()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                ColorSequenceKeypoint.new(1, Library.MainColor),
            });
        end
    });
    local NotifyLabel = Library:CreateLabel({
        Position = UDim2.new(0, labelPosX, 0, 0);
        Size     = UDim2.new(1, labelSizeW, 1, 0);
        Text     = Text;
        TextXAlignment = (align == 'Center')
            and Enum.TextXAlignment.Center
            or  Enum.TextXAlignment.Left;
        TextSize = Library.FontSize;
        ZIndex   = 103;
        Parent   = InnerFrame;
    });
    local AccentBar = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel  = 0;
        ZIndex           = 104;
        Parent           = NotifyOuter;
    });
    if barSide == 'Left' then
        AccentBar.Position = UDim2.new(0, -1, 0, -1)
        AccentBar.Size     = UDim2.new(0, BAR_THIN, 1, 2)
    elseif barSide == 'Right' then
        AccentBar.Position = UDim2.new(1, -BAR_THIN + 1, 0, -1)
        AccentBar.Size     = UDim2.new(0, BAR_THIN, 1, 2)
    elseif barSide == 'Top' then
        AccentBar.Position = UDim2.new(0, -1, 0, -1)
        AccentBar.Size     = UDim2.new(1, 2, 0, BAR_THICK)
    elseif barSide == 'Bottom' then
        AccentBar.Position = UDim2.new(0, -1, 1, -BAR_THICK + 1)
        AccentBar.Size     = UDim2.new(1, 2, 0, BAR_THICK)
    end

    Library:AddToRegistry(AccentBar, {
        BackgroundColor3 = 'AccentColor';
    }, true);
    local finalWidth = XSize + 8 + 4
    if barSide == 'Left' or barSide == 'Right' then
        finalWidth = finalWidth + BAR_THIN
    end
    pcall(NotifyOuter.TweenSize, NotifyOuter,
        UDim2.new(0, finalWidth, 0, YSize), 'Out', 'Quad', 0.4, true);
    task.spawn(function()
        wait(Time or 5);
        pcall(NotifyOuter.TweenSize, NotifyOuter,
            UDim2.new(0, 0, 0, YSize), 'Out', 'Quad', 0.4, true);
        wait(0.4);
        NotifyOuter:Destroy();
    end);
end;

function Library:CreateWindow(...)
    local Arguments = { ... }
    local Config = { AnchorPoint = Vector2.zero }

    if type(...) == 'table' then
        Config = ...;
    else
        Config.Title = Arguments[1]
        Config.AutoShow = Arguments[2] or false;
    end

    if type(Config.Title) ~= 'string' then Config.Title = 'No title' end
    if type(Config.TabPadding) ~= 'number' then Config.TabPadding = 0 end
    if type(Config.MenuFadeTime) ~= 'number' then Config.MenuFadeTime = 0.2 end

    if typeof(Config.Size) ~= 'UDim2' then Config.Size = UDim2.fromOffset(530, 640) end
    if typeof(Config.Position) ~= 'UDim2' then Config.Position = UDim2.fromOffset(175, 50) end

    if InputService.TouchEnabled then
        local vp = workspace.CurrentCamera.ViewportSize
        local maxWidth = math.min(Config.Size.X.Offset, vp.X - 20)

        local maxHeight = math.min(Config.Size.Y.Offset, vp.Y - 60)
        Config.Size = UDim2.fromOffset(maxWidth, maxHeight)
    end

    if Config.Center then
        Config.AnchorPoint = Vector2.new(0.5, 0.5)
        Config.Position = UDim2.fromScale(0.5, 0.5)
    end

    local Window = {
        Tabs = {};
    };

    local Outer = Library:Create('Frame', {
        AnchorPoint = Config.AnchorPoint,
        BackgroundColor3 = Library.MainColor;
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        ClipsDescendants = true;
        Position = Config.Position,
        Size = Config.Size,
        Visible = false;
        ZIndex = 1;
        Parent = ScreenGui;
    });
    Library:ApplyCorner(Outer, Library.WindowCornerRadius, true);
    Library:MakeDraggable(Outer, 25, true);

    if Config.Resizable then
        Library:MakeResizable(Outer, Config.MinSize or Vector2.new(420, 320), Config.MaxSize or Vector2.new(1000, 900))
    end

    local Inner = Library:Create('Frame', {
        Name = "Inner",
        BackgroundColor3 = Library.MainColor;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 1;
        Parent = Outer;
    });
    Library:ApplyCorner(Inner, Library.WindowCornerRadius, true);
    Library:AddToRegistry(Inner, {
        BackgroundColor3 = 'MainColor';
    });
    Library:MarkGlassSurface(Inner);
    local WindowLabel = Library:CreateLabel({
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 0, 25);
        Text = Config.Title or '';
        RichText = true;
        TextXAlignment = Enum.TextXAlignment.Center;
        ZIndex = 1;
        Parent = Inner;
    });

    local CloseBtn = Library:Create('TextButton', {
        BackgroundTransparency = 1;
        AnchorPoint = Vector2.new(1, 0);
        Position = UDim2.new(1, -6, 0, 0);
        Size = UDim2.fromOffset(22, 22);
        Text = "✕";
        Font = Library.Font;
        TextSize = Library.FontSize + 2;
        TextColor3 = Library.FontColor;
        ZIndex = 5;
        Parent = Inner;
    });
    Library:Create('UICorner', { CornerRadius = UDim.new(0, 6), Parent = CloseBtn });
    CloseBtn.MouseEnter:Connect(function() CloseBtn.TextColor3 = Library.AccentColor; end)
    CloseBtn.MouseLeave:Connect(function() CloseBtn.TextColor3 = Library.FontColor; end)
    CloseBtn.MouseButton1Click:Connect(function()
        Library.Toggled = false;
        Outer.Visible = false;
        if Library.UseBlur then Library.BlurEffect.Enabled = false; end
    end);
    local MapNameLabel = Library:CreateLabel({
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -32, 0, 0);
        Size = UDim2.new(0, 0, 0, 25),
        Text = 'Loading...',
        TextColor3 = Library.FontColor;
        TextTransparency = 0.35;
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 1,
        Parent = Inner;
    });
    Library:AddToRegistry(MapNameLabel, {
        TextColor3 = 'FontColor';
    });
    task.spawn(function()
        local success, info = pcall(function()
            return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
        end)
        if success and info and info.Name then
            MapNameLabel.Text = info.Name
        else
            MapNameLabel.Text = game.Name or "Unknown Map"
        end
    end)

    local TabBarOuter = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 8, 0, 25);
        Size = UDim2.new(1, -16, 0, 29);
        ZIndex = 1;
        Parent = Inner;
    });
    Library:ApplyCorner(TabBarOuter, 8, true);
    Library:AddToRegistry(TabBarOuter, {
        BackgroundColor3 = 'BackgroundColor';
    });
    local TabBarInner = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 1;
        Parent = TabBarOuter;
    });
    Library:ApplyCorner(TabBarInner, 8, true);
    Library:AddToRegistry(TabBarInner, {
        BackgroundColor3 = 'BackgroundColor';
    });
    local TabArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 4, 0, 4);
        Size = UDim2.new(1, -8, 1, -8);
        ZIndex = 1;
        Parent = TabBarInner;
    });
    local TabListLayout = Library:Create('UIListLayout', {
        Padding = UDim.new(0, Config.TabPadding);
        FillDirection = Enum.FillDirection.Horizontal;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = TabArea;
    });
    local MainSectionOuter = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 8, 0, 58);
        Size = UDim2.new(1, -16, 1, -66);
        ZIndex = 1;
        Parent = Inner;
    });
    Library:ApplyCorner(MainSectionOuter, 8, true);
    Library:AddToRegistry(MainSectionOuter, {
        BackgroundColor3 = 'BackgroundColor';
    });
    local MainSectionInner = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 1;
        Parent = MainSectionOuter;
    });
    Library:ApplyCorner(MainSectionInner, 8, true);
    Library:AddToRegistry(MainSectionInner, {
        BackgroundColor3 = 'BackgroundColor';
    });
    local TabContainer = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 8, 0, 8);
        Size = UDim2.new(1, -16, 1, -16);
        ZIndex = 2;
        Parent = MainSectionInner;
    });
    Library:ApplyCorner(TabContainer, 6, true);
    Library:AddToRegistry(TabContainer, {
        BackgroundColor3 = 'MainColor';
    });
    Outer.ClipsDescendants = true;

    if not Library.TopBar then
        Library.TopBar = Library:Create('Frame', {
            Name = "TopBarWidgets",
            BackgroundColor3 = Library.BackgroundColor;
            BorderSizePixel = 0;
            AnchorPoint = Vector2.new(0.5, 0);
            Position = UDim2.new(0.5, 0, 0, 6);
            Size = UDim2.new(0, 0, 0, Library.TopBarIconSize + 8);
            ZIndex = 5;
            Visible = true;
            Parent = ScreenGui;
        });
        Library.TopBarCorner = Library:ApplyCorner(Library.TopBar, (Library.TopBarIconSize + 8) / 2, true);
        Library:AddToRegistry(Library.TopBar, { BackgroundColor3 = 'BackgroundColor'; });
        Library:MarkGlassSurface(Library.TopBar);
        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Library.TopBar,
        });
        Library:Create('UIPadding', {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 4),
            Parent = Library.TopBar,
        });
        Library.TopBarListLayout = Library.TopBar:FindFirstChildOfClass("UIListLayout");

        Library.TopBarListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Library:RefreshTopBarSize()
        end)
    end;

    if not Library.WidgetWindows then Library.WidgetWindows = {} end;

    -- Core floating panel used by both CreateWidgetWindow and CreateMiniWindow:
    -- draggable, optionally resizable (Config.Resizable, Config.MinSize,
    -- Config.MaxSize) and optionally collapsible to just its title bar
    -- (Config.Collapsible). Set Config.Closable = false to hide the X button.
    function Library:CreateSubWindow(Config)
        Config = Config or {};
        local Title = Config.Title or "Window";
        local Size = Config.Size or UDim2.fromOffset(300, 250);
        local Pos = Config.Position or UDim2.fromOffset(200, 100);
        local Closable = Config.Closable ~= false;

        local WOuter = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = Pos;
            Size = Size;
            ZIndex = 10;
            Visible = false;
            Parent = ScreenGui;
        });
        Library:ApplyCorner(WOuter, Library.WindowCornerRadius, true);
        Library:MakeDraggable(WOuter, 28, true);

        local WInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 11;
            Parent = WOuter;
        });
        Library:ApplyCorner(WInner, Library.WindowCornerRadius, true);
        Library:AddToRegistry(WInner, { BackgroundColor3 = 'MainColor'; });
        Library:MarkGlassSurface(WInner);

        local TitleBar = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 0, 26);
            ZIndex = 12;
            Parent = WInner;
        });
        Library:ApplyCorner(TitleBar, 8, true);
        Library:AddToRegistry(TitleBar, { BackgroundColor3 = 'BackgroundColor'; });

        local TitleFix = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 0, 1, -6);
            Size = UDim2.new(1, 0, 0, 6);
            ZIndex = 12;
            Parent = TitleBar;
        });
        Library:AddToRegistry(TitleFix, { BackgroundColor3 = 'BackgroundColor'; });

        local TitleLabel = Library:CreateLabel({
            Text = Title;
            Size = UDim2.new(1, -60, 1, 0);
            Position = UDim2.new(0, 8, 0, 0);
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 13;
            Parent = TitleBar;
        });

        local CollapseBtn = nil
        if Config.Collapsible then
            CollapseBtn = Library:Create('TextButton', {
                BackgroundTransparency = 1;
                AnchorPoint = Vector2.new(1, 0.5);
                Position = UDim2.new(1, Closable and -28 or -6, 0.5, 0);
                Size = UDim2.fromOffset(18, 18);
                Text = "–";
                Font = Library.Font;
                TextSize = Library.FontSize + 2;
                TextColor3 = Library.FontColor;
                ZIndex = 13;
                Parent = TitleBar;
            });
            CollapseBtn.MouseEnter:Connect(function() CollapseBtn.TextColor3 = Library.AccentColor end)
            CollapseBtn.MouseLeave:Connect(function() CollapseBtn.TextColor3 = Library.FontColor end)
        end

        local XBtn = nil
        if Closable then
            XBtn = Library:Create('TextButton', {
                BackgroundTransparency = 1;
                AnchorPoint = Vector2.new(1, 0.5);
                Position = UDim2.new(1, -6, 0.5, 0);
                Size = UDim2.fromOffset(20, 20);
                Text = "✕";
                Font = Library.Font;
                TextSize = Library.FontSize + 1;
                TextColor3 = Library.FontColor;
                ZIndex = 13;
                Parent = TitleBar;
            });
            XBtn.MouseEnter:Connect(function() XBtn.TextColor3 = Library.RiskColor end)
            XBtn.MouseLeave:Connect(function() XBtn.TextColor3 = Library.FontColor end)
            XBtn.MouseButton1Click:Connect(function() WOuter.Visible = false end)
        end

        local Content = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 6, 0, 32);
            Size = UDim2.new(1, -12, 1, -38);
            ZIndex = 12;
            Parent = WInner;
        });
        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
            Parent = Content;
        });

        local Grip = nil
        if Config.Resizable then
            Grip = Library:MakeResizable(WOuter, Config.MinSize or Vector2.new(220, 140), Config.MaxSize or Vector2.new(700, 600))
        end

        local SubWin = {
            Outer = WOuter;
            Inner = WInner;
            TitleBar = TitleBar;
            TitleLabel = TitleLabel;
            Content = Content;
            XBtn = XBtn;
            CollapseBtn = CollapseBtn;
            ResizeGrip = Grip;
            Visible = false;
            Collapsed = false;
        };
        function SubWin:Show() WOuter.Visible = true; self.Visible = true end
        function SubWin:Hide() WOuter.Visible = false; self.Visible = false end
        function SubWin:Toggle() WOuter.Visible = not WOuter.Visible; self.Visible = WOuter.Visible end
        function SubWin:SetTitle(T) TitleLabel.Text = T end
        function SubWin:AddLabel(Text, Wrap)
            local lbl = Library:CreateLabel({ Text = Text, TextWrapped = Wrap or false, Size = UDim2.new(1,0,0,18), TextSize = Library.FontSize, TextXAlignment = Enum.TextXAlignment.Left, Parent = Content });
            return lbl
        end
        function SubWin:AddButton(Info)
            local btnOuter = Library:Create('Frame', { BackgroundColor3 = Library.BackgroundColor, BorderSizePixel = 0, Size = UDim2.new(1,0,0,22), Parent = Content });
            Library:ApplyCorner(btnOuter, 6, true);
            Library:AddToRegistry(btnOuter, { BackgroundColor3 = 'BackgroundColor'; });
            local btn = Library:Create('TextButton', { BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), Text=Info.Text or "Button", Font=Library.Font, TextSize=Library.FontSize, TextColor3=Library.FontColor, Parent=btnOuter });
            Library:AddToRegistry(btn, { TextColor3 = 'FontColor'; });
            if Info.Func then btn.MouseButton1Click:Connect(function() Library:SafeCallback(Info.Func) end) end
            return btn
        end
        if Config.Collapsible then
            local ExpandedHeight = Size.Y.Offset
            function SubWin:Collapse()
                if self.Collapsed then return end
                self.Collapsed = true
                ExpandedHeight = WOuter.Size.Y.Offset
                Content.Visible = false
                if Grip then Grip.Visible = false end
                WOuter.Size = UDim2.new(WOuter.Size.X.Scale, WOuter.Size.X.Offset, WOuter.Size.Y.Scale, 26)
                if CollapseBtn then CollapseBtn.Text = "+" end
            end
            function SubWin:Expand()
                if not self.Collapsed then return end
                self.Collapsed = false
                Content.Visible = true
                if Grip then Grip.Visible = true end
                WOuter.Size = UDim2.new(WOuter.Size.X.Scale, WOuter.Size.X.Offset, WOuter.Size.Y.Scale, ExpandedHeight)
                if CollapseBtn then CollapseBtn.Text = "–" end
            end
            function SubWin:ToggleCollapse() if self.Collapsed then self:Expand() else self:Collapse() end end
            CollapseBtn.MouseButton1Click:Connect(function() SubWin:ToggleCollapse() end)
        end

        table.insert(Library.WidgetWindows, SubWin);
        return SubWin;
    end;

    -- A widget window opened from a top bar icon. See CreateSubWindow for
    -- the shared Config fields (Resizable, MinSize, MaxSize, Collapsible).
    function Library:CreateWidgetWindow(Config)
        Config = Config or {};
        return Library:CreateSubWindow(Config)
    end;

    -- A compact floating sub window: smaller default size, collapsible and
    -- resizable by default. Not tied to a top bar icon — call :Show() to
    -- display it (e.g. from a button or another widget window).
    function Library:CreateMiniWindow(Config)
        Config = Config or {};
        Config.Size = Config.Size or UDim2.fromOffset(220, 170);
        if Config.Collapsible == nil then Config.Collapsible = true end
        if Config.Resizable == nil then Config.Resizable = true end
        Config.MinSize = Config.MinSize or Vector2.new(180, 120)
        Config.MaxSize = Config.MaxSize or Vector2.new(480, 420)
        return Library:CreateSubWindow(Config)
    end;

    -- Adds an icon button to the top bar.
    -- Config: Icon (Lucide name or rbxassetid://, default "settings"),
    -- Tooltip, WidgetWindow (toggled on click), Callback (fires on click).
    function Library:AddTopBarWidget(Config)
        Config = Config or {};
        local IconName = Config.Icon or "settings";
        local Tooltip = Config.Tooltip or "";
        local Callback = Config.Callback;
        local WidgetWindow = Config.WidgetWindow;
        local ImageId = Library:GetLucideIcon(IconName);

        local Btn = Library:Create('ImageButton', {
            BackgroundColor3 = Library.AccentColor;
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Size = UDim2.fromOffset(Library.TopBarIconSize, Library.TopBarIconSize);
            Image = ImageId;
            ImageColor3 = Library.FontColor;
            AutoButtonColor = false;
            ZIndex = 6;
            Parent = Library.TopBar;
        });
        local BtnCorner = Library:ApplyCorner(Btn, Library.TopBarIconSize / 2, true);
        local IconScale = Library:Create('UIScale', { Scale = 1; Parent = Btn; });

        if Tooltip ~= "" then Library:AddToolTip(Tooltip, Btn) end

        local Active, Hovering = false, false
        local function Restyle(Instant)
            local BaseColor = Library.TopBarIconColor or Library.FontColor
            local Goal = {
                BackgroundTransparency = Active and 0.55 or (Hovering and 0.8 or 1);
                ImageColor3 = Active and Library.AccentColor or BaseColor;
            }
            local ScaleGoal = Hovering and 1.12 or 1

            if Instant then
                Btn.BackgroundColor3 = Library.AccentColor
                Btn.BackgroundTransparency = Goal.BackgroundTransparency
                Btn.ImageColor3 = Goal.ImageColor3
                IconScale.Scale = ScaleGoal
            else
                TweenService:Create(Btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), Goal):Play()
                TweenService:Create(IconScale, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Scale = ScaleGoal }):Play()
            end
        end
        Restyle(true)

        if WidgetWindow and WidgetWindow.Outer then
            Active = WidgetWindow.Outer.Visible
            Restyle(true)
            WidgetWindow.Outer:GetPropertyChangedSignal("Visible"):Connect(function()
                Active = WidgetWindow.Outer.Visible
                Restyle()
            end)
        end

        local function onClick()
            if WidgetWindow then
                WidgetWindow:Toggle();
            end
            if Callback then Library:SafeCallback(Callback, Btn) end
        end

        Btn.MouseEnter:Connect(function() Hovering = true; Restyle() end)
        Btn.MouseLeave:Connect(function() Hovering = false; Restyle() end)
        Btn.MouseButton1Click:Connect(onClick)

        local widget = { Button = Btn, Corner = BtnCorner, Window = WidgetWindow, Refresh = Restyle };
        table.insert(Library.TopBarWidgets, widget);

        task.defer(function()
            Library:RefreshTopBarSize()
        end)
        return widget
    end;

    function Window:SetWindowTitle(Title)
        WindowLabel.Text = Title;
    end;
    function Window:AddTab(Name)
        local Tab = {
            Groupboxes = {};
            Tabboxes = {};
        };

        local TabButtonWidth = Library:GetTextBounds(Name, Library.Font, Library.FontSize + 2);
        local TabButton = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderSizePixel = 0;
            Size = UDim2.new(0, TabButtonWidth + 8 + 4, 1, 0);
            ZIndex = 1;
            Parent = TabArea;
        });
        Library:ApplyCorner(TabButton, 6, true);
        Library:AddToRegistry(TabButton, {
            BackgroundColor3 = 'BackgroundColor';
        });
        local TabButtonLabel = Library:CreateLabel({
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, -1);
            Text = Name;
            ZIndex = 1;
            Parent = TabButton;
        });
        local TabIndicator = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 0, 2);
            Visible = false;
            ZIndex = 4;
            Parent = TabButton;
        });
        Library:AddToRegistry(TabIndicator, { BackgroundColor3 = 'AccentColor' });

        local Blocker = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(0, 0, 0, 0);
            Visible = false;
            Parent = TabButton;
        });
        local TabFrame = Library:Create('Frame', {
            Name = 'TabFrame',
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            Visible = false;
            ZIndex = 2;
            Parent = TabContainer;
        });
        local LeftSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 8 - 1, 0, 8 - 1);
            Size = UDim2.new(0.5, -12 + 2, 1, -16);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            BottomImage = '';
            TopImage = '';
            ScrollBarThickness = 0;
            ZIndex = 2;
            Parent = TabFrame;
        });
        local RightSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0.5, 4 + 1, 0, 8 - 1);
            Size = UDim2.new(0.5, -12 + 2, 1, -16);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            BottomImage = '';
            TopImage = '';
            ScrollBarThickness = 0;
            ZIndex = 2;
            Parent = TabFrame;
        });
        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = LeftSide;
        });
        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = RightSide;
        });
        for _, Side in next, { LeftSide, RightSide } do
            Side:WaitForChild('UIListLayout'):GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                Side.CanvasSize = UDim2.fromOffset(0, Side.UIListLayout.AbsoluteContentSize.Y);
            end);
        end;

        function Tab:ShowTab()
            for _, Tab in next, Window.Tabs do
                Tab:HideTab();
            end;

            Blocker.BackgroundTransparency = 0;
            TabButton.BackgroundColor3 = Library.MainColor;
            Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'MainColor';
            TabFrame.Visible = true;
            TabIndicator.Visible = true;
        end;
        function Tab:HideTab()
            Blocker.BackgroundTransparency = 1;
            TabButton.BackgroundColor3 = Library.BackgroundColor;
            Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'BackgroundColor';
            TabFrame.Visible = false;
            TabIndicator.Visible = false;
        end;
        function Tab:SetLayoutOrder(Position)
            TabButton.LayoutOrder = Position;
            TabListLayout:ApplyLayout();
        end;
        function Tab:AddGroupbox(Info)
            local Groupbox = {};
            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 507 + 2);
                ZIndex = 2;
                Parent = Info.Side == 1 and LeftSide or RightSide;
            });
            Library:ApplyCorner(BoxOuter, 8, true);
            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'BackgroundColor';
            });
            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 1, 0);
                Position = UDim2.new(0, 0, 0, 0);
                ZIndex = 4;
                Parent = BoxOuter;
            });
            Library:ApplyCorner(BoxInner, 8, true);
            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = 'BackgroundColor';
            });
            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 2);
                ZIndex = 5;
                Parent = BoxInner;
            });
            Library:AddToRegistry(Highlight, {
                BackgroundColor3 = 'AccentColor';
            });
            local GroupboxLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 18);
                Position = UDim2.new(0, 4, 0, 2);
                TextSize = Library.FontSize;
                Text = Info.Name;
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 5;
                Parent = BoxInner;
            });
            local Container = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 4, 0, 20);
                Size = UDim2.new(1, -4, 1, -20);
                ZIndex = 1;
                Parent = BoxInner;
            });
            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = Container;
            });
            function Groupbox:Resize()
                local Size = 0;
                for _, Element in next, Groupbox.Container:GetChildren() do
                    if (not Element:IsA('UIListLayout')) and Element.Visible then
                        Size = Size + Element.Size.Y.Offset;
                    end;
                end;

                BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2);
            end;

            Groupbox.Container = Container;
            setmetatable(Groupbox, BaseGroupbox);
            Groupbox:AddBlank(3);
            Groupbox:Resize();

            Tab.Groupboxes[Info.Name] = Groupbox;

            return Groupbox;
        end;

        function Tab:AddLeftGroupbox(Name)
            return Tab:AddGroupbox({ Side = 1; Name = Name; });
        end;

        function Tab:AddRightGroupbox(Name)
            return Tab:AddGroupbox({ Side = 2; Name = Name; });
        end;

        function Tab:AddTabbox(Info)
            local Tabbox = {
                Tabs = {};
            };

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 0);
                ZIndex = 2;
                Parent = Info.Side == 1 and LeftSide or RightSide;
            });
            Library:ApplyCorner(BoxOuter, 8, true);
            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'BackgroundColor';
            });
            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 1, 0);
                Position = UDim2.new(0, 0, 0, 0);
                ZIndex = 4;
                Parent = BoxOuter;
            });
            Library:ApplyCorner(BoxInner, 8, true);
            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = 'BackgroundColor';
            });
            local TabboxButtons = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 0, 0, 1);
                Size = UDim2.new(1, 0, 0, 18);
                ZIndex = 5;
                Parent = BoxInner;
            });
            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Left;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TabboxButtons;
            });
            function Tabbox:AddTab(Name)
                local Tab = {};
                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Color3.new(0, 0, 0);
                    Size = UDim2.new(0.5, 0, 1, 0);
                    ZIndex = 6;
                    Parent = TabboxButtons;
                });
                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor';
                });
                local TabHighlight = Library:Create('Frame', {
                    BackgroundColor3 = Library.AccentColor;
                    BorderSizePixel = 0;
                    Size = UDim2.new(1, 0, 0, 2);
                    Visible = false;
                    ZIndex = 10;
                    Parent = Button;
                });
                Library:AddToRegistry(TabHighlight, {
                    BackgroundColor3 = 'AccentColor';
                });
                local ButtonLabel = Library:CreateLabel({
                    Size = UDim2.new(1, 0, 1, 0);
                    TextSize = Library.FontSize;
                    Text = Name;
                    TextXAlignment = Enum.TextXAlignment.Center;
                    ZIndex = 7;
                    Parent = Button;
                });
                local Block = Library:Create('Frame', {
                    BackgroundColor3 = Library.BackgroundColor;
                    BorderSizePixel = 0;
                    Position = UDim2.new(0, 0, 1, 0);
                    Size = UDim2.new(1, 0, 0, 1);
                    Visible = false;
                    ZIndex = 9;
                    Parent = Button;
                });
                Library:AddToRegistry(Block, {
                    BackgroundColor3 = 'BackgroundColor';
                });
                local Container = Library:Create('Frame', {
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 4, 0, 20);
                    Size = UDim2.new(1, -4, 1, -20);
                    ZIndex = 1;
                    Visible = false;
                    Parent = BoxInner;
                });
                Library:Create('UIListLayout', {
                    FillDirection = Enum.FillDirection.Vertical;
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    Parent = Container;
                });
                function Tab:Show()
                    for _, Tab in next, Tabbox.Tabs do
                        Tab:Hide();
                    end;

                    Container.Visible = true;
                    Block.Visible = true;
                    TabHighlight.Visible = true;

                    Button.BackgroundColor3 = Library.BackgroundColor;
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'BackgroundColor';

                    Tab:Resize();
                end;
                function Tab:Hide()
                    Container.Visible = false;
                    Block.Visible = false;
                    TabHighlight.Visible = false;

                    Button.BackgroundColor3 = Library.MainColor;
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'MainColor';
                end;
                function Tab:Resize()
                    local TabCount = 0;
                    for _, Tab in next, Tabbox.Tabs do
                        TabCount = TabCount + 1;
                    end;

                    for _, Button in next, TabboxButtons:GetChildren() do
                        if not Button:IsA('UIListLayout') then
                            Button.Size = UDim2.new(1 / TabCount, 0, 1, 0);
                        end;
                    end;

                    if (not Container.Visible) then
                        return;
                    end;

                    local Size = 0;

                    for _, Element in next, Tab.Container:GetChildren() do
                        if (not Element:IsA('UIListLayout')) and Element.Visible then
                            Size = Size + Element.Size.Y.Offset;
                        end;
                    end;

                    BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2);
                end;
                Button.InputBegan:Connect(function(Input)
                    if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                        Tab:Show();
                        Tab:Resize();
                    end;
                end);

                Tab.Container = Container;
                Tabbox.Tabs[Name] = Tab;

                setmetatable(Tab, BaseGroupbox);

                Tab:AddBlank(3);
                Tab:Resize();

                if #TabboxButtons:GetChildren() == 2 then
                    Tab:Show();
                end;

                return Tab;
            end;

            Tab.Tabboxes[Info.Name or ''] = Tabbox;

            return Tabbox;
        end;
        function Tab:AddLeftTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 1; });
        end;

        function Tab:AddRightTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 2; });
        end;

        TabButton.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                Tab:ShowTab();
            end;
        end);
        if #TabContainer:GetChildren() == 1 then
            Tab:ShowTab();
        end;
        Window.Tabs[Name] = Tab;
        return Tab;
    end;

    local ModalElement = Library:Create('TextButton', {
        BackgroundTransparency = 1;
        Size = UDim2.new(0, 0, 0, 0);
        Visible = true;
        Text = '';
        Modal = false;
        Parent = ScreenGui;
    });
    function Library:Toggle()
        Library.Toggled = not Library.Toggled;
        ModalElement.Modal = Library.Toggled;
        Outer.Visible = Library.Toggled;
        if Library.TopBar then
            Library.TopBar.Visible = Library.Toggled
        end
        if Library.WidgetWindows then
            for _, w in ipairs(Library.WidgetWindows) do
                if not Library.Toggled then
                    w.Outer.Visible = false
                    w.Visible = false
                end
            end
        end
        if Library.CustomBackgroundFrame and Library.CustomBackgroundId then
            Library.CustomBackgroundFrame.Visible = Library.Toggled
        end
        if Library.Toggled then
            task.spawn(function()
                local State = InputService.MouseIconEnabled;

                local Cursor = Drawing.new('Triangle');
                Cursor.Thickness = 1;
                Cursor.Filled = true;
                Cursor.Visible = true;

                local CursorOutline = Drawing.new('Triangle');
                CursorOutline.Thickness = 1;
                CursorOutline.Filled = false;
                CursorOutline.Color = Color3.new(0, 0, 0);
                CursorOutline.Visible = true;

                while Library.Toggled and ScreenGui.Parent do
                    InputService.MouseIconEnabled = false;

                    local mPos = InputService:GetMouseLocation();

                    Cursor.Color = Library.AccentColor;

                    Cursor.PointA = Vector2.new(mPos.X, mPos.Y);
                    Cursor.PointB = Vector2.new(mPos.X + 16, mPos.Y + 6);
                    Cursor.PointC = Vector2.new(mPos.X + 6, mPos.Y + 16);
                    CursorOutline.PointA = Cursor.PointA;
                    CursorOutline.PointB = Cursor.PointB;
                    CursorOutline.PointC = Cursor.PointC;

                    RenderStepped:Wait();
                end;

                InputService.MouseIconEnabled = State;

                Cursor:Remove();
                CursorOutline:Remove();
            end);
        end;
        if Library.UseBlur then
            if Library.Toggled then
                Library.BlurEffect.Enabled = true
                Library.BlurEffect.Size = Library.BlurSize
            else
                Library.BlurEffect.Size = 0
                Library.BlurEffect.Enabled = false
            end
        else
            Library.BlurEffect.Size = 0
            Library.BlurEffect.Enabled = false
        end
    end

    Library:GiveSignal(InputService.InputBegan:Connect(function(Input, Processed)
        if type(Library.ToggleKeybind) == 'table' and Library.ToggleKeybind.Type == 'KeyPicker' then
            if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeybind.Value then
                task.spawn(Library.Toggle)
            end
        elseif type(Library.ToggleKeybind) == 'string' then
            if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeybind then
                task.spawn(Library.Toggle)
            end
        elseif Input.KeyCode == Enum.KeyCode.RightControl or (Input.KeyCode == Enum.KeyCode.RightShift and (not Processed)) then
            task.spawn(Library.Toggle)
        end
    end))

    if Config.AutoShow then task.spawn(Library.Toggle) end

    Library.WindowRefs = {
        TabBarOuter = TabBarOuter,
        MainSectionOuter = MainSectionOuter,
        MainSectionInner = MainSectionInner,
        TabContainer = TabContainer,
        TabArea = TabArea,
        Outer = Outer,
        Inner = Inner
    };
    Library.CurrentWindow = Window;
    Window.Holder = Outer;
    return Window;
end;

local function OnPlayerChange()
    local PlayerList = GetPlayersString();
    for _, Value in next, Options do
        if Value.Type == 'Dropdown' and Value.SpecialType == 'Player' then
            Value:SetValues(PlayerList);
        end;
    end;
end;

Players.PlayerAdded:Connect(OnPlayerChange);
Players.PlayerRemoving:Connect(OnPlayerChange);

Library.MobileButtons = {}
Library.LockMobileBtn = nil
do
    local MobileGui = Instance.new("ScreenGui")
    MobileGui.Name = "LinoriaMobileUI"
    MobileGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    ProtectGui(MobileGui)
    MobileGui.Parent = CoreGui
    Library.MobileGui = MobileGui

    local cfg = Library.MobileButtonConfig
    local BTN_W, BTN_H = cfg.Size.X, cfg.Size.Y
    local BTN_GAP      = 8

    local function CreateMobileButton(name, text, startPos)
        local sz = Library.MobileButtonConfig.Size
        local Outer = Library:Create('Frame', {
            Name             = name .. "Outer",
            BackgroundColor3 = Library.MobileButtonConfig.Color,
            BorderSizePixel  = 0,
            Position         = startPos,
            Size             = UDim2.fromOffset(sz.X, sz.Y),
            ZIndex           = 300,
            Parent           = MobileGui,
            Active           = true,
            BackgroundTransparency = Library.MobileButtonConfig.Transparency,
        })
        local corner = Library:ApplyMobileCorner(Outer, Library.MobileButtonConfig.CornerRadius)

        local Btn = Library:Create('TextButton', {
            Name                = name .. "Btn",
            BackgroundTransparency = 1,
            Size                = UDim2.new(1, 0, 1, 0),
            Font                = Library.Font,
            Text                = text,
            TextColor3          = Library.MobileButtonConfig.TextColor,
            TextSize            = Library.FontSize - 1,
            ZIndex              = 304,
            Parent              = Outer,
            Active              = true,
        })

        local entry = { Name = name, Outer = Outer, Btn = Btn, Inner = Outer, Corner = corner }
        table.insert(Library.MobileButtons, entry)
        if name == "Lock" then Library.LockMobileBtn = Btn end

        if Library.MobileButtonConfig.Invisible then
            Outer.BackgroundTransparency = 1
            Btn.TextTransparency = 1
        end
        return Outer, Btn, entry
    end

    local ToggleOuter, ToggleBtn = CreateMobileButton("Toggle", "Toggle UI",  UDim2.new(0, 10, 0, 10))
    local LockOuter,   LockBtn  = CreateMobileButton("Lock",   Library.UILocked and "Unlock UI" or "Lock UI",  UDim2.new(0, 10, 0, 10 + BTN_H + (BTN_GAP)))

    Library.UILocked = false

    local function BindMobileButtonAction(Btn, Outer, ClickAction)
        local dragging  = false
        local dragInput = nil
        local dragStart = nil
        local startPos  = nil
        local hasMoved  = false
        local lastTapTime = 0
        local holdConn = nil
        local holdTriggered = false
        local holdThreshold = 0.6

        local function fireClick()
            local mode = Library.MobileButtonConfig.TapMode
            if mode == "Single" then
                ClickAction()
            elseif mode == "Double" then
                local now = tick()
                if now - lastTapTime < 0.35 then
                    ClickAction()
                    lastTapTime = 0
                else
                    lastTapTime = now
                end
            elseif mode == "Hold" then

            end
        end

        Btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging  = true
                hasMoved  = false
                holdTriggered = false
                dragStart = input.Position
                startPos  = Outer.Position
                dragInput = input

                if Library.MobileButtonConfig.TapMode == "Hold" then
                    holdConn = task.delay(holdThreshold, function()
                        if dragging and not hasMoved and not Library.UILocked then

                            if (Btn == ToggleBtn or Btn == LockBtn) and not holdTriggered then
                                holdTriggered = true

                                ClickAction()
                            end
                        end
                    end)
                end

                local connection
                connection = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        if holdConn then pcall(task.cancel, holdConn) end
                        connection:Disconnect()
                        if not hasMoved and not holdTriggered then

                            if Library.MobileButtonConfig.TapMode ~= "Hold" then
                                fireClick()
                            end
                        end
                    end
                end)
            end
        end)

        InputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                if delta.Magnitude > 3 then
                    hasMoved = true
                    if holdConn then pcall(task.cancel, holdConn) end
                end
                if not Library.UILocked and hasMoved then
                    Outer.Position = UDim2.new(
                        startPos.X.Scale, startPos.X.Offset + delta.X,
                        startPos.Y.Scale, startPos.Y.Offset + delta.Y
                    )
                end
            end
        end)
    end

    BindMobileButtonAction(ToggleBtn, ToggleOuter, function()
        local mode = Library.MobileButtonConfig.TapMode
        if mode == "Hold" then

            Library:Toggle()
        else
            Library:Toggle()
        end
    end)

    BindMobileButtonAction(LockBtn, LockOuter, function()
        Library.UILocked = not Library.UILocked
        Library:SetUILocked(Library.UILocked)
        LockBtn.Text = Library.UILocked and "Unlock UI" or "Lock UI"
        LockBtn.TextColor3 = Library.UILocked and Library.FontColor or Library.AccentColor

        if Library.UILocked then

        end
    end)

    Library.LockMobileBtn = LockBtn

    local _oldTrans = Library.SetMobileButtonTransparency

    Library:SetMobileButtonTransparency(cfg.Transparency)
    Library:SetMobileCornerRadius(cfg.CornerRadius)
end

getgenv().Library = Library
return Library
