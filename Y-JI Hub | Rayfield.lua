-- UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Movement Tab
local flyEnabled = false
local flySpeed = 50
local flying = false
local bodyVelocity = nil
local speedEnabled = false
local speedPower = 4
local noclipEnabled = false

-- Keybinds
local FlyKey = "Q"
local SpeedKey = "H"
local NoclipKey = "E"
local AimbotKey = "Z"
local SilentAimKey = "X"
local ESPKey = "B"
local TPKey = "T"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local localPlayer = Players.LocalPlayer
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local Mouse = localPlayer:GetMouse()

local bodyVelocity
local targetPlayer = nil

local ClickInterval = 0.10

-- ESP settings
local FILL_COLOR = Color3.fromRGB(255, 0, 0)
local OUTLINE_COLOR = Color3.fromRGB(255, 255, 255)
local FILL_TRANSPARENCY = 0.5
local OUTLINE_TRANSPARENCY = 0
local RainbowColor = Color3.fromRGB(255, 0, 0)
local RAINBOW_ESP = true
local RAINBOW_SPEED = 0.1

-- AIM settings
getgenv().Aimbot = true
getgenv().Smoothness = 0.49

_G.ShowFOV = false
_G.FOV = 150

local Circle = Drawing.new("Circle")
Circle.Visible = _G.ShowFOV
Circle.Color = Color3.fromRGB(255, 0, 0)
Circle.Thickness = 2
Circle.NumSides = 64
Circle.Filled = false
Circle.Transparency = 1
Circle.Radius = _G.FOV

local AimbotEnabled = false
local aiming = false

-- AutoShoot settings
local CLICK_DELAY = 0.05
local lastClick = 0

-- Toggles
local scriptEnabled = false
local autoShootEnabled = false
local flying = false
local TP
local noclipEnabled = false
local espenabled = false

local function getCharacter()
    local character = player.Character or player.CharacterAdded:Wait()
    return character, character:WaitForChild("Humanoid"), character:WaitForChild("HumanoidRootPart")
end

-- Update character when respawning
localPlayer.CharacterAdded:Connect(function(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	rootPart = char:WaitForChild("HumanoidRootPart")
end)

local function isLobbyVisible()
    return localPlayer.PlayerGui.MainGui.MainFrame.Lobby.Currency.Visible == true
end

local character, humanoid, rootPart = getCharacter()

player.CharacterAdded:Connect(function()
    character, humanoid, rootPart = getCharacter()
end)

-- Fly Functions
local function startFlying()
	if flying then
		return
	end

	flying = true

	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bodyVelocity.Velocity = Vector3.zero
	bodyVelocity.Parent = rootPart

	humanoid.PlatformStand = false

	RunService:BindToRenderStep(
		"FlyMovement",
		Enum.RenderPriority.Character.Value + 1,
		function()
			if not flying then
				return
			end

			local moveDirection = Vector3.zero

			if UserInputService:IsKeyDown(Enum.KeyCode.W) then
				moveDirection += camera.CFrame.LookVector
			end

			if UserInputService:IsKeyDown(Enum.KeyCode.S) then
				moveDirection -= camera.CFrame.LookVector
			end

			if UserInputService:IsKeyDown(Enum.KeyCode.A) then
				moveDirection -= camera.CFrame.RightVector
			end

			if UserInputService:IsKeyDown(Enum.KeyCode.D) then
				moveDirection += camera.CFrame.RightVector
			end

			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
				moveDirection += Vector3.new(0, 1, 0)
			end

			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
				moveDirection -= Vector3.new(0, 1, 0)
			end

			if moveDirection.Magnitude > 0 then
				bodyVelocity.Velocity = moveDirection.Unit * flySpeed
			else
				bodyVelocity.Velocity = Vector3.zero
			end
		end
	)
end

local function stopFlying()
	if not flying then
		return
	end

	flying = false

	RunService:UnbindFromRenderStep("FlyMovement")

	if bodyVelocity then
		bodyVelocity:Destroy()
		bodyVelocity = nil
	end
end

-- Speed
RunService.RenderStepped:Connect(function()
    if not speedEnabled then
        return
    end

    local char = player.Character
    if not char then
        return
    end

    local hum = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")

    if hum and root and hum.MoveDirection.Magnitude > 0 then
        root.CFrame += hum.MoveDirection * (speedPower / 10)
    end
end)

-- Noclip
RunService.Stepped:Connect(function()
    if not noclipEnabled then
        return
    end

    local character = player.Character
    if not character then
        return
    end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end)

local function IsVisible(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end

	-- Check if the character is on screen
	local _, onScreen = camera:WorldToViewportPoint(root.Position)
	if not onScreen then
		return false
	end

	-- Check for walls between the camera and the character
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {
		localPlayer.Character,
		workspace.CurrentCamera
	}

	local origin = camera.CFrame.Position
	local direction = root.Position - origin

	local result = workspace:Raycast(origin, direction, params)

	-- Nothing hit, so they're visible
	if not result then
		return true
	end

	-- If the first thing hit belongs to the character, they're visible
	return result.Instance:IsDescendantOf(character)
end

local function getClosestPlayerToMouse()
	local closestPlayer = nil
	local shortestDistance = _G.FOV

	local mousePosition = UserInputService:GetMouseLocation()

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character then

			local humanoid = player.Character:FindFirstChild("Humanoid")
			local head = player.Character:FindFirstChild("Head")

			if humanoid and humanoid.Health > 0 and head then

				local screenPosition, onScreen = camera:WorldToViewportPoint(head.Position)

				if onScreen then
					local distance = (
						Vector2.new(screenPosition.X, screenPosition.Y)
						- mousePosition
					).Magnitude

					if distance < shortestDistance then
						shortestDistance = distance
						closestPlayer = player
					end
				end
			end
		end
	end

	return closestPlayer
end

local function lockCameraToHead()
    if targetPlayer
    and targetPlayer.Character
    and targetPlayer.Character:FindFirstChild("Head") then

        camera.CFrame = CFrame.new(
            camera.CFrame.Position,
            targetPlayer.Character.Head.Position
        )
    end
end

local function get_target()
	local target = nil
	local closestDistance = _G.FOV

	local center = UserInputService:GetMouseLocation()

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character then
			local humanoid = player.Character:FindFirstChild("Humanoid")

			local part = player.Character:FindFirstChild("HeadHB")
				or player.Character:FindFirstChild("Head")
				or player.Character:FindFirstChild("UpperTorso")

			if humanoid and humanoid.Health > 0 and part then
				local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)

				if onScreen then
					local distance = (
						Vector2.new(screenPos.X, screenPos.Y) - center
					).Magnitude

					if distance < closestDistance then
						closestDistance = distance
						target = part
					end
				end
			end
		end
	end

	return target
end

-- Aimbot
RunService.RenderStepped:Connect(function()

	-- Update FOV circle
	Circle.Position = UserInputService:GetMouseLocation()
	local rainbow = Color3.fromHSV((tick() * RAINBOW_SPEED) % 1, 1, 1)

	Circle.Color = RainbowColor

	Circle.Radius = _G.FOV
	Circle.Visible = _G.ShowFOV

	-- Aimbot
	if AimbotEnabled and aiming and getgenv().Aimbot then
		local target = get_target()

		if target and target.Parent then
			local pos, onScreen = camera:WorldToViewportPoint(target.Position)

			if onScreen then
				local center = Vector2.new(
					camera.ViewportSize.X / 2,
					camera.ViewportSize.Y / 2
				)

				local x = (pos.X - center.X) * getgenv().Smoothness
				local y = (pos.Y - center.Y) * getgenv().Smoothness

				if mousemoverel then
					mousemoverel(x, y)
				end
			end
		end
	end
end)

RunService.RenderStepped:Connect(function()
	RainbowColor = Color3.fromHSV((tick() * RAINBOW_SPEED) % 1, 1, 1)
end)

-- ESP
local function clearHighlights()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			local highlight = player.Character:FindFirstChild("PlayerHighlight")

			if highlight then
				highlight:Destroy()
			end
		end
	end
end

local function addHighlight(character)
	if not character then
		return
	end

	if character:FindFirstChild("PlayerHighlight") then
		return
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "PlayerHighlight"
	highlight.FillColor = FILL_COLOR
	highlight.OutlineColor = OUTLINE_COLOR
	highlight.FillTransparency = FILL_TRANSPARENCY
	highlight.OutlineTransparency = OUTLINE_TRANSPARENCY
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = character
end

local function rebuildHighlights()
	clearHighlights()

	if not espenabled then
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character then
			addHighlight(player.Character)
		end
	end
end

RunService.RenderStepped:Connect(function()
	if not espenabled or not RAINBOW_ESP then
		return
	end

	local rainbow = Color3.fromHSV((tick() * RAINBOW_SPEED) % 1, 1, 1)

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character then
			local highlight = player.Character:FindFirstChild("PlayerHighlight")
			if highlight then
				highlight.FillColor = RainbowColor
				highlight.OutlineColor = RainbowColor
			end
		end
	end
end)

local function DoSilentKill()
	pcall(function()
		local target = nil
		local distMin = math.huge

		for _, v in pairs(Players:GetPlayers()) do
			if v ~= localPlayer
			and v.Character
			and v.Character:FindFirstChild("HumanoidRootPart") then
				
				local distance = (
					v.Character.HumanoidRootPart.Position 
					- localPlayer.Character.HumanoidRootPart.Position
				).Magnitude

				if distance < distMin then
					distMin = distance
					target = v
				end
			end
		end

		if target and localPlayer.Character then
			local character = localPlayer.Character
			local hrp = character:FindFirstChild("HumanoidRootPart")

			if hrp then
				local oldPosition = hrp.CFrame

				local targetHRP = target.Character.HumanoidRootPart
				local targetHead = target.Character:FindFirstChild("Head")

				local tpPos = targetHRP.CFrame * CFrame.new(0, 0, 6)

				character:PivotTo(tpPos)

				if targetHead then
					camera.CFrame = CFrame.new(
						camera.CFrame.Position,
						targetHead.Position
					)
				end

				task.wait(0.05)

				VirtualInputManager:SendMouseButtonEvent(
					0,0,0,true,game,0
				)

				task.wait(0.02)

				VirtualInputManager:SendMouseButtonEvent(
					0,0,0,false,game,0
				)

				task.wait(0.02)

				character:PivotTo(oldPosition)
			end
		end
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.UserInputType ~= Enum.UserInputType.Keyboard then
        return
    end

    local key = input.KeyCode.Name:upper()

    if key == FlyKey then
        flying = not flying

        if flying then
            startFlying()
        else
            stopFlying()
        end

    elseif key == SpeedKey then
        speedEnabled = not speedEnabled

    elseif key == NoclipKey then
        noclipEnabled = not noclipEnabled

    elseif key == AimbotKey then
        AimbotEnabled = not AimbotEnabled
        _G.ShowFOV = AimbotEnabled

    elseif key == SilentAimKey then
        scriptEnabled = not scriptEnabled
        _G.ShowFOV = scriptEnabled

    elseif key == ESPKey then
        espenabled = not espenabled
        rebuildHighlights()
    end
end)

UserInputService.InputBegan:Connect(function(input, isProcessed)
	if isProcessed then
		return
	end

    if input.UserInputType == Enum.UserInputType.MouseButton2 then
	    if AimbotEnabled then
	    	aiming = true
	    end
        return
    end
end)

UserInputService.InputEnded:Connect(function(input, isProcessed)
	if isProcessed then
		return
	end

    if input.UserInputType == Enum.UserInputType.MouseButton2 then
	    aiming = false
    end
end)

-- Player connections
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		if espenabled then
			task.wait(0.1)
			addHighlight(character)
		end
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	if player ~= localPlayer then
		player.CharacterAdded:Connect(function(character)
			if espenabled then
				task.wait(0.1)
				addHighlight(character)
			end
		end)
	end
end

-- MAIN LOOP
RunService.Heartbeat:Connect(function()
    if not scriptEnabled then 
        return
    end

    if not isLobbyVisible() then
 	    targetPlayer = getClosestPlayerToMouse()

	    if targetPlayer then
	 	    lockCameraToHead()
	    end
    end

end)

-- GUI
local Window = Rayfield:CreateWindow({
   Name = "Y-JI Hub | Rivals | Rayfield",
   Icon = 0,
   LoadingTitle = "Loading Y-JI Hub",
   LoadingSubtitle = "by FlagWars_ProSniper",
   ShowText = "Rayfield",
   Theme = "Default",

   ToggleUIKeybind = "K",

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil,
      FileName = "Big Hub"
   },

   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },

   KeySystem = false,
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided",
      FileName = "Key",
      SaveKey = true,
      GrabKeyFromSite = false,
      Key = {"Hello"}
   }
})

local MovementTab = Window:CreateTab("Movement", 4483362458)

local FlySection = MovementTab:CreateSection("Fly")

MovementTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "FlyToggle",
    Callback = function(Value)
        flyEnabled = Value

        if Value then
            startFlying()
        else
            stopFlying()
        end
    end,
})

local Slider = MovementTab:CreateSlider({
    Name = "Fly Speed",
    Range = {0, 200},
    Increment = 10,
    CurrentValue = 50,
    Flag = "FlySpeed",
    Callback = function(Value)
        flySpeed = Value
    end,
})

local SpeedSection = MovementTab:CreateSection("Speed")

MovementTab:CreateToggle({
    Name = "Speed",
    CurrentValue = false,
    Flag = "SpeedToggle",
    Callback = function(Value)
        speedEnabled = Value
    end,
})

MovementTab:CreateSlider({
    Name = "Speed Power",
    Range = {1, 20},
    Increment = 1,
    CurrentValue = 4,
    Flag = "SpeedSlider",
    Callback = function(Value)
        speedPower = Value
    end,
})

local NoclipSection = MovementTab:CreateSection("Noclip")

MovementTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "NoclipToggle",
    Callback = function(Value)
        noclipEnabled = Value

        if not Value then
            local character = player.Character
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
    end,
})

local CombatTab = Window:CreateTab("Combat", 4483362458)

local AimbotSection = CombatTab:CreateSection("Aimbot")

CombatTab:CreateToggle({
	Name = "Aimbot",
	CurrentValue = false,
	Flag = "AimbotToggle",
	Callback = function(Value)
		AimbotEnabled = Value
		_G.ShowFOV = Value
	end,
})

CombatTab:CreateSlider({
    Name = "Aim Smoothness",
    Range = {0.05, 0.49},
    Increment = 0.05,
    CurrentValue = 0.49,
    Flag = "SmoothnessSlider",
    Callback = function(Value)
        getgenv().Smoothness = Value
    end,
})

CombatTab:CreateSlider({
    Name = "FOV Size",
    Range = {20, 500},
    Increment = 5,
    CurrentValue = 150,
    Flag = "FOVSlider",
    Callback = function(Value)
        _G.FOV = Value
        Circle.Radius = Value
    end,
})

local SilentSection = CombatTab:CreateSection("Silent Aim")

CombatTab:CreateToggle({
	Name = "Silent Aim",
	CurrentValue = false,
	Flag = "SilentAimToggle",
	Callback = function(Value)
		scriptEnabled = Value
		_G.ShowFOV = Value
	end,
})

local SilentKillSection = CombatTab:CreateSection("Silent Kill")

CombatTab:CreateButton({
	Name = "Silent Kill",
	Callback = function()
		DoSilentKill()
	end,
})

local VisualsTab = Window:CreateTab("Visuals", 4483362458)

local EspSection = VisualsTab:CreateSection("ESP")

VisualsTab:CreateToggle({
	Name = "ESP",
	CurrentValue = false,
	Flag = "EspToggle",
	Callback = function(Value)
		espenabled = Value
	end,
})

local KeybindsTab = Window:CreateTab("Keybinds", 4483362458)

local MovementKeybindsSections = KeybindsTab:CreateSection("Movement Keybinds")

KeybindsTab:CreateInput({
    Name = "Fly Key",
    CurrentValue = FlyKey,
    PlaceholderText = "",
    RemoveTextAfterFocusLost = false,
    Flag = "FlyKey",
    Callback = function(Text)
        FlyKey = Text:upper()
    end,
})

KeybindsTab:CreateInput({
    Name = "Speed Key",
    CurrentValue = SpeedKey,
    PlaceholderText = "",
    RemoveTextAfterFocusLost = false,
    Flag = "SpeedKey",
    Callback = function(Text)
        SpeedKey = Text:upper()
    end,
})

KeyBindsTab:CreateInput({
	Name = "Noclip Key",
	CurrentValue = NoclipKey,
	PlaceholderText = "",
	RemoveTextAfterFocusLost = false,
	Flag = "NoclipKey",
	Callback = function(Text)
		NoclipKey = Text:upper()
	end,
})

local CombatKeybindsSection = KeybindsTab:CreateSection("Combat Keybinds")

KeyBindsTab:CreateInput({
	Name = "Aimbot Key",
	CurrentValue = AimbotKey,
	PlaceholderText = "",
	RemoveTextAfterFocusLost = false,
	Flag = "AimbotKey",
	Callback = function(Text)
		AimbotKey = Text:upper()
	end,
})

KeyBindsTab:CreateInput({
	Name = "Silent Aim Key",
	CurrentValue = SilentAimKey,
	PlaceholderText = "",
	RemoveTextAfterFocusLost = false,
	Flag = "SilentAimKey",
	Callback = function(Text)
		SilentAimKey = Text:upper()
	end,
})

local VisualKeybindSection = KeybindsTab:CreateSection("Visuals Keybinds")

KeyBindsTab:CreateInput({
	Name = "ESP Key",
	CurrentValue = ESPKey,
	PlaceholderText = "",
	RemoveTextAfterFocusLost = false,
	Flag = "ESPKey",
	Callback = function(Text)
		ESPKey = Text:upper()
	end,
})
