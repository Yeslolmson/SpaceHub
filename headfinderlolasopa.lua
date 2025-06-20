-- LocalScript (put in StarterPlayerScripts)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera
local localPlayer = Players.LocalPlayer

local locked = false
local connection
local currentHead

local function getVisibleTargetHead()
    local rayOrigin = camera.CFrame.Position
    local rayDirection = camera.CFrame.LookVector * 100

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {localPlayer.Character}
    raycastParams.IgnoreWater = true

    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

    if raycastResult then
        local hitPart = raycastResult.Instance
        if hitPart and hitPart.Name == "Head" and hitPart:IsA("BasePart") then
            local targetCharacter = hitPart:FindFirstAncestorOfClass("Model")
            local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)
            if targetCharacter and targetPlayer and targetPlayer ~= localPlayer then
                return hitPart
            end
        end
    end

    return nil
end

local function lockCameraToHead(targetHead)
    if locked or not targetHead then return end

    locked = true
    currentHead = targetHead
    camera.CameraType = Enum.CameraType.Scriptable

    connection = RunService.RenderStepped:Connect(function()
        if currentHead and currentHead.Parent then
            local offset = Vector3.new(0, 2, 8)
            local targetPos = currentHead.Position
            camera.CFrame = CFrame.new(targetPos + offset, targetPos)
        end
    end)
end

local function unlockCamera()
    if not locked then return end

    locked = false
    currentHead = nil
    camera.CameraType = Enum.CameraType.Custom

    if connection then
        connection:Disconnect()
        connection = nil
    end
end

-- Main check loop
RunService.RenderStepped:Connect(function()
    local targetHead = getVisibleTargetHead()

    if targetHead and not locked then
        lockCameraToHead(targetHead)
    elseif not targetHead and locked then
        unlockCamera()
    end
end)
