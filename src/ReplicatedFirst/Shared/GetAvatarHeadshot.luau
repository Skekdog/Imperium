local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BotNameFormatting = require(script.Parent.BotNameFormatting)

local function GetAvatarHeadshot(player: Player | Configuration | string): ImageLabel | ViewportFrame
    if typeof(player) == "string" then
        assert(BotNameFormatting.IsFormattedBotName(player), "Player is not a bot")
    end

    if typeof(player) == "string" or player:IsA("Configuration") then
        local frame = Instance.new("ViewportFrame")

        local name = BotNameFormatting.Unformat(if typeof(player) == "string" then player else player.Name)
        local model = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BotModels"):WaitForChild(name):Clone()

        assert(model:IsA("Model"), "Bot model is not a model")
        local head = model:FindFirstChild("Head")

        assert(head and head:IsA("BasePart"), "Bot model has no head")

        model.Parent = frame

        local camera = Instance.new("Camera")
        camera.CFrame = CFrame.new(head.Position + head.CFrame.LookVector * 1.75, head.Position)
        camera.Parent = frame

        frame.CurrentCamera = camera

        frame.Ambient = Color3.new(1, 1, 1)
        frame.LightColor = Color3.new(1, 1, 1)

        return frame
    else
        local imageLabel = Instance.new("ImageLabel")
        local success = pcall(function()
			imageLabel.Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		end)
        if not success then
            imageLabel.Image = "rbxthumb://type=AvatarHeadShot&id=965735486&w=48&h=48"
        end
        return imageLabel
    end
end

return GetAvatarHeadshot