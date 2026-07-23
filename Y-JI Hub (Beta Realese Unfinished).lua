-- Y-JI Hub (Beta Unfinished Version) | Rivals

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local localPlayer = Players.LocalPlayer
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
getgenv().Smoothness = 0.45

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

-- SPEED settings
_G.EnableSpeed = false
_G.SpeedPower = 4

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


local FLY_SPEED = 100

-- Update character when respawning
localPlayer.CharacterAdded:Connect(function(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	rootPart = char:WaitForChild("HumanoidRootPart")
end)

-- GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StatusGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local statusLabel = Instance.new("TextLabel")
statusLabel.ZIndex = 10
statusLabel.BackgroundTransparency = 0
statusLabel.Active = true
statusLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- background colour
statusLabel.Size = UDim2.new(0, 0, 0, 0)
statusLabel.AutomaticSize = Enum.AutomaticSize.XY
statusLabel.Position = UDim2.new(0, 10, 0, 10)
statusLabel.BorderSizePixel = 0
statusLabel.TextColor3 = Color3.new(1, 1, 1)
statusLabel.TextStrokeTransparency = 0
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 16
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 5)
corner.Parent = statusLabel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Thickness = 2
stroke.Transparency = 0.3
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = statusLabel

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 7)
padding.PaddingRight = UDim.new(0, 7)
padding.PaddingTop = UDim.new(0, 7)
padding.PaddingBottom = UDim.new(0, 7)
padding.Parent = statusLabel

local TweenService = game:GetService("TweenService")

local normalSize = statusLabel.Size
local hoverSize = UDim2.new(
	normalSize.X.Scale,
	normalSize.X.Offset + 10,
	normalSize.Y.Scale,
	normalSize.Y.Offset + 5
)

statusLabel.MouseEnter:Connect(function()
	TweenService:Create(
		statusLabel,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			BackgroundColor3 = Color3.fromRGB(50, 50, 50),
			Size = hoverSize
		}
	):Play()
end)

statusLabel.MouseLeave:Connect(function()
	TweenService:Create(
		statusLabel,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			BackgroundColor3 = Color3.fromRGB(25, 25, 25),
			Size = normalSize
		}
	):Play()
end)

local function updateStatus()
	statusLabel.RichText = true

	statusLabel.Text =
		"<font color='rgb(104, 95, 233)'>Y-JI Hub (Beta) | Rivals</font>"
		.. "\nSilent Aim (X): " .. (scriptEnabled and "🟢 ON" or "🔴 OFF")
		.. "\nAimlock (Z): " .. (not AimbotEnabled and "🔴 OFF" or aiming and "🟢 ON" or "🟡 READY")
		.. "\nAuto Shoot (E): " .. (autoShootEnabled and "🟢 ON" or "🔴 OFF")
		.. "\nFly (Q): " .. (flying and "🟢 ON" or "🔴 OFF")
		.. "\nNoclip (K): " .. (noclipEnabled and "🟢 ON" or "🔴 OFF")
		.. "\nTP + Auto (T): " .. (TP and "🟢 ON" or "🔴 OFF")
		.. "\nWalkSpeed (H): " .. (_G.EnableSpeed and "🟢 ON" or "🔴 OFF")
		.. "\nESP (B): " .. (espenabled and "🟢 ON" or "🔴 OFF")
		.. "\n<font color='rgb(255,0,0)'>(Toggle Silent Aim before"
		.. "\ntoggling Auto Shoot ⚠️)</font>"
end

updateStatus()

local function isLobbyVisible()
    return localPlayer.PlayerGui.MainGui.MainFrame.Lobby.Currency.Visible == true
end

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

-- Speed
RunService.RenderStepped:Connect(function()
	if not _G.EnableSpeed then
		return
	end

	local char = localPlayer.Character

	if not char then
		return
	end

	local hum = char:FindFirstChild("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")

	if hum and root and hum.MoveDirection.Magnitude > 0 then
		root.CFrame += hum.MoveDirection * (_G.SpeedPower / 10)
	end
end)

-- NOCLIP FUNCTIONS

local function setNoclip(enabled)
	local char = localPlayer.Character

	if not char then
		return
	end

	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = not enabled
		end
	end
end

RunService.Stepped:Connect(function()
	if noclipEnabled then
		setNoclip(true)
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

-- FLY FUNCTIONS

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
				bodyVelocity.Velocity = moveDirection.Unit * FLY_SPEED
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

-- INPUT

UserInputService.InputBegan:Connect(function(input, isProcessed)
	if isProcessed then
		return
	end

    if input.UserInputType == Enum.UserInputType.MouseButton2 then
	    if AimbotEnabled then
	    	aiming = true
            updateStatus()
	    end
        return
    end

	if input.KeyCode == Enum.KeyCode.X then
  		scriptEnabled = not scriptEnabled
   		_G.ShowFOV = scriptEnabled

   		if not scriptEnabled then
    	    targetPlayer = nil
    		autoShootEnabled = false
        	aiming = false
    	end

    	updateStatus()
   		return
	end

	if input.KeyCode == Enum.KeyCode.Z then
		AimbotEnabled = not AimbotEnabled
		_G.ShowFOV = not _G.ShowFOV
		updateStatus()
		return
	end

	if input.KeyCode == Enum.KeyCode.E then
		autoShootEnabled = not autoShootEnabled
		updateStatus()
		return
	end

	if input.KeyCode == Enum.KeyCode.Q then
		if flying then
			stopFlying()
		else
			startFlying()
		end

		updateStatus()
		return
	end

	if input.KeyCode == Enum.KeyCode.K then
		noclipEnabled = not noclipEnabled
	
		setNoclip(noclipEnabled)
	
		updateStatus()
		return
	end

    if input.KeyCode == Enum.KeyCode.T then
		DoSilentKill()
		TP = true
		updateStatus()
		task.wait(0.09)
		TP = false
		updateStatus()
		return
    end
    
	if input.KeyCode == Enum.KeyCode.H then
		_G.EnableSpeed = not _G.EnableSpeed
		updateStatus()
		return
	end

	if input.KeyCode == Enum.KeyCode.B then
		espenabled = not espenabled
		rebuildHighlights()
		updateStatus()
		return
	end

	if not scriptEnabled then
		return
	end
end)

-- AUTO CLICK LOOP

RunService.Heartbeat:Connect(function()
    if not scriptEnabled then
        return
    end

    if not autoShootEnabled then
        return
    end

    if isLobbyVisible() then
        return
    end

    if tick() - lastClick >= CLICK_DELAY then
        lastClick = tick()

        VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,0)
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,0)
    end
end)

UserInputService.InputEnded:Connect(function(input, isProcessed)
	if isProcessed then
		return
	end

    if input.UserInputType == Enum.UserInputType.MouseButton2 then
	    aiming = false
        updateStatus()
    end
end)

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
