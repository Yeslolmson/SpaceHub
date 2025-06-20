local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- === Remote for Firing ===
local shootRemote = ReplicatedStorage:WaitForChild("ButtonPressed")

-- === GUI Setup ===
local screenGui = Instance.new("ScreenGui", localPlayer:WaitForChild("PlayerGui"))
screenGui.Name = "LockOnGUI"
screenGui.ResetOnSpawn = false

local lockButton = Instance.new("TextButton", screenGui)
lockButton.Size = UDim2.new(0.25, 0, 0.08, 0)
lockButton.Position = UDim2.new(0.5, 0, 1, -80)
lockButton.AnchorPoint = Vector2.new(0.5, 1)
lockButton.Text = "🎯 Lock-On"
lockButton.Font = Enum.Font.GothamBold
lockButton.TextSize = 22
lockButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
lockButton.TextColor3 = Color3.new(1, 1, 1)
lockButton.BorderSizePixel = 0
lockButton.Active = true
lockButton.Modal = true

-- === State ===
local holding = false
local lockedPlayer = nil
local targetList = {}
local currentTargetIndex = 1
local touchStart = nil

-- === Constants ===
local CONE_ANGLE_DEGREES = 90
local SWIPE_THRESHOLD = 50

-- === Arrow Indicator ===
local function createArrow(player)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "LockArrow"
	billboard.Size = UDim2.new(2, 0, 2, 0)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = player.Character:WaitForChild("HumanoidRootPart")
	billboard.Parent = player.Character

	local arrow = Instance.new("ImageLabel", billboard)
	arrow.Image = "rbxassetid://3926305904"
	arrow.ImageRectOffset = Vector2.new(964, 284)
	arrow.ImageRectSize = Vector2.new(36, 36)
	arrow.Size = UDim2.new(0.5, 0, 0.5, 0)
	arrow.BackgroundTransparency = 1
	arrow.Position = UDim2.new(0.25, 0, 0.25, 0)
end

local function removeArrow()
	if lockedPlayer and lockedPlayer.Character then
		local arrow = lockedPlayer.Character:FindFirstChild("LockArrow", true)
		if arrow then
			arrow:Destroy()
		end
	end
end

-- === Cone Check ===
local function isInCone(targetPos)
	local forward = humanoidRootPart.CFrame.LookVector
	local toTarget = (targetPos - humanoidRootPart.Position).Unit
	local dot = forward:Dot(toTarget)
	local angle = math.acos(dot) * (180 / math.pi)
	return angle < (CONE_ANGLE_DEGREES / 2)
end

-- === Visibility Check ===
local function isVisible(part)
	local origin = camera.CFrame.Position
	local direction = (part.Position - origin)

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {localPlayer.Character}
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist

	local result = workspace:Raycast(origin, direction, rayParams)
	return result and result.Instance and result.Instance:IsDescendantOf(part.Parent)
end

-- === Get Valid Targets ===
local function getValidTargets()
	local list = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local part = player.Character.HumanoidRootPart
			if isInCone(part.Position) and isVisible(part) then
				table.insert(list, player)
			end
		end
	end
	return list
end

-- === Predict Position ===
local function getPredictedPosition(part)
	local velocity = part.Velocity
	local predictionTime = 0.2
	return part.Position + velocity * predictionTime
end

-- === Lock + Rotate to Predicted Position ===
local function lockOnToTarget()
	if lockedPlayer and lockedPlayer.Character and lockedPlayer.Character:FindFirstChild("HumanoidRootPart") then
		local targetPart = lockedPlayer.Character.HumanoidRootPart
		local myPos = humanoidRootPart.Position
		local predicted = getPredictedPosition(targetPart)

		local direction = Vector3.new(predicted.X - myPos.X, 0, predicted.Z - myPos.Z)

		if direction.Magnitude > 0.1 then
			local lookCFrame = CFrame.new(myPos, myPos + direction)
			humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position, lookCFrame.Position + lookCFrame.LookVector)
			camera.CFrame = CFrame.new(camera.CFrame.Position, predicted)
		end
	end
end

-- === Target Switching ===
local function switchTarget(direction)
	if #targetList == 0 then return end
	removeArrow()
	currentTargetIndex += direction
	if currentTargetIndex < 1 then currentTargetIndex = #targetList end
	if currentTargetIndex > #targetList then currentTargetIndex = 1 end
	lockedPlayer = targetList[currentTargetIndex]
	createArrow(lockedPlayer)
end

-- === Swipe Detection ===
UserInputService.TouchStarted:Connect(function(input)
	touchStart = input.Position
end)

UserInputService.TouchEnded:Connect(function(input)
	if not holding or not touchStart then return end
	local delta = input.Position.X - touchStart.X
	if math.abs(delta) > SWIPE_THRESHOLD then
		switchTarget(delta > 0 and 1 or -1)
	end
	touchStart = nil
end)

-- === Lock Start/Stop ===
local function startLock()
	targetList = getValidTargets()
	if #targetList == 0 then return end
	currentTargetIndex = 1
	lockedPlayer = targetList[currentTargetIndex]
	createArrow(lockedPlayer)
	holding = true
end

local function stopLock()
	removeArrow()
	holding = false
	lockedPlayer = nil
end

-- === Input Bindings ===
lockButton.MouseButton1Down:Connect(startLock)
lockButton.MouseButton1Up:Connect(stopLock)

lockButton.TouchLongPress:Connect(function(_, state)
	if state == Enum.UserInputState.Begin then
		startLock()
	elseif state == Enum.UserInputState.End then
		stopLock()
	end
end)

-- === Frame Update: Rotate + Auto Fire + Auto Switch ===
RunService.RenderStepped:Connect(function()
	if holding then
		-- Auto-switch if current target is gone
		if not lockedPlayer or not lockedPlayer.Character or not lockedPlayer.Character:FindFirstChild("HumanoidRootPart") then
			targetList = getValidTargets()
			if #targetList > 0 then
				currentTargetIndex = currentTargetIndex % #targetList + 1
				lockedPlayer = targetList[currentTargetIndex]
				createArrow(lockedPlayer)
			else
				stopLock()
			end
		end

		if lockedPlayer then
			lockOnToTarget()
			shootRemote:FireServer()
		end
	end
end)
