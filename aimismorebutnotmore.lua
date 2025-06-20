-- Predict the enemy's future position
local function getPredictedPosition(part)
	local velocity = part.Velocity
	local predictionTime = 0.2 -- tweak this to match bullet speed/distance
	return part.Position + velocity * predictionTime
end

-- Face toward predicted position every frame
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
