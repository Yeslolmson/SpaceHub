local bullet = script.Parent
local speed = 150
local homingStrength = 0.1 -- how sharply the bullet adjusts its path

-- Replace with how you find the head target
local enemy = workspace:FindFirstChild("Enemy")
local head = enemy and enemy:FindFirstChild("Head")

game:GetService("RunService").Heartbeat:Connect(function(dt)
	if head and head.Parent then
		local toTarget = (head.Position - bullet.Position).Unit
		local currentDir = bullet.CFrame.LookVector
		local newDir = currentDir:Lerp(toTarget, homingStrength)
		
		bullet.CFrame = CFrame.new(bullet.Position, bullet.Position + newDir)
		bullet.Position = bullet.Position + newDir * speed * dt
	end
end)
