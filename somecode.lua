-- Highlight all players with red glow, looping every second to catch late spawns

local Players = game:GetService("Players")

local function highlightCharacter(character)
	if character and not character:FindFirstChild("Highlight") then
		local highlight = Instance.new("Highlight")
		highlight.Name = "Highlight"
		highlight.FillColor = Color3.fromRGB(255, 0, 0) -- Red fill
		highlight.OutlineColor = Color3.fromRGB(150, 0, 0) -- Dark red outline
		highlight.FillTransparency = 0.2
		highlight.OutlineTransparency = 0
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- Show through walls
		highlight.Adornee = character
		highlight.Parent = character
	end
end

-- Loop every 1 second to catch all current players
while true do
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			highlightCharacter(player.Character)
		end
	end
	task.wait(1) -- Wait 1 second
end
