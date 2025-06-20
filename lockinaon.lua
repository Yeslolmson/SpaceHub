local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local function getNearestPlayer()
	local shortestDistance = math.huge
	local nearestCharacter = nil

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Head") then
			local headPos = player.Character.Head.Position
			local screenPoint, onScreen = camera:WorldToViewportPoint(headPos)

			if onScreen then
				local mousePos = UserInputService:GetMouseLocation()
				local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude

				if distance < shortestDistance then
					shortestDistance = distance
					nearestCharacter = player.Character
				end
			end
		end
	end

	return nearestCharacter
end

RunService.RenderStepped:Connect(function()
	local targetCharacter = getNearestPlayer()
	if targetCharacter and targetCharacter:FindFirstChild("Head") then
		camera.CFrame = CFrame.new(camera.CFrame.Position, targetCharacter.Head.Position)
	end
end)
