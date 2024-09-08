local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SettingsManager = require(script.Parent.SettingsManager)

local screenMessageFormats = {
	Standard = {
		Name = "Standard",
		LabelProperties = {
			Text = "Standard Message",
			TextScaled = true,
			TextColor3 = Color3.new(1, 1, 1),
			TextStrokeColor3 = Color3.new(0, 0, 0),
			FontFace = Font.fromName("Ubuntu"),
			BackgroundTransparency = 1,
			RichText = false, -- If enabled, UIStroke does not apply
		}
	},
	Error = {
		Name = "Error",
		InheritsFrom = "Standard",
		LabelProperties = {
			Text = "Error Message",
			TextColor3 = Color3.new(1, 0, 0)
		},
	},
	Info = {
		Name = "Info",
		InheritsFrom = "Standard",
		LabelProperties = {
			Text = "Info Message",
			TextColor3 = Color3.new(0.125, 0.5, 1)
		}
	},
	Success = {
		Name = "Success",
		InheritsFrom = "Standard",
		LabelProperties = {
			Text = "Success Message",
			TextColor3 = Color3.new(0, 0.71, 0)
		}
	},
	Warn = {
		Name = "Warn",
		InheritsFrom = "Standard",
		LabelProperties = {
			Text = "Warning Message",
			TextColor3 = Color3.new(1, 0.48, 0.13)
		}
	}
}

return function(format: string, text: string, formatOverrides: {[string]: any}?): TextLabel
	local label = Instance.new("TextLabel")
	
	local inheritanceOrder = {}
	
	do
		local inheritanceStep = format
		repeat
			table.insert(inheritanceOrder, 1, inheritanceStep)
			inheritanceStep = screenMessageFormats[inheritanceStep].InheritsFrom
		until not inheritanceStep
		
		if formatOverrides then
			inheritanceOrder[#inheritanceOrder + 1] = "__formatOverride"
		end
	end
	
	for _, formatName in inheritanceOrder do
		local formatTable = formatName == "__formatOverride" and formatOverrides or screenMessageFormats[formatName]
		
		if formatTable.LabelProperties then
			for i, v in formatTable.LabelProperties do
				(label :: any)[i] = v
			end
		end
	end
	
	label.Text = text

	local gui: Frame = (Players.LocalPlayer.PlayerGui:WaitForChild("Special") :: any).ScreenMessage
	label.Size = UDim2.fromScale(0.8, 0.05)
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.fromScale(0.5, 0.05 * (#gui:GetChildren() + 1))

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Parent = label

	label.Parent = gui

	local animate = SettingsManager.GetSetting("Animate UI Transitions")
	if not animate then
		task.delay(4, function()
			label:Destroy()
		end)
		return label
	end
	
	local tween = TweenService:Create(label, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 3), {
		BackgroundTransparency = 1,
		TextTransparency = 1,
	})
	TweenService:Create(stroke, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 3), {
		Transparency = 1
	}):Play()
	tween.Completed:Once(function()
		for _, v in gui:GetChildren() do
			assert(v:IsA("TextLabel"))
			local foundTween = v:FindFirstChildOfClass("Tween")
			if foundTween then
				foundTween:Cancel()
				foundTween:Destroy()
			end
			local tween = TweenService:Create(v, TweenInfo.new(0.5), {
				Position = UDim2.fromScale(0.5, v.Position.Y.Scale - 0.05)
			})
			tween.Parent = v
			tween:Play()
		end
		label:Destroy()
	end)
	tween:Play()
	
	return label
end