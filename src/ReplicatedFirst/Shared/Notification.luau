local TweenService = game:GetService("TweenService")
local GetPlayerName = require(script.Parent.GetPlayerName)
local SettingsManager = require(script.Parent.Parent.Shared.SettingsManager)
local UIAnimation = require(script.Parent.Parent.Shared.UIAnimation)
local UIManager = require(script.Parent.Parent.Shared.UIManager)

local ui = UIManager.WaitForUI("Notification").Object :: typeof(UIManager.UnregisteredUIs.Notification)

local global = ui.Global

local function fade(label: TextLabel, out: boolean)
	if out then
		local animate = SettingsManager.GetSetting("Animate UI Transitions")
		if animate then
			TweenService:Create(label, TweenInfo.new(5), {TextTransparency = 1, BackgroundTransparency = 1}):Play()
		end
		task.delay(5, label.Destroy, label)
	else
		UIAnimation.Animate(label, TweenInfo.new(0.25), {TextTransparency = 0, BackgroundTransparency = 0.4})
	end
end

local function moveDown(frame: Frame)
	for _, v in frame:GetChildren() do
		if v:IsA("TextLabel") then
			local target = v:GetAttribute("TargetPosition") :: UDim2 + UDim2.fromScale(0, 0.2)
			v:SetAttribute("TargetPosition", target)
			UIAnimation.Animate(v, TweenInfo.new(0.5), { Position = target})
		end
	end
end

local function makeLabel(text: string, players: {Player}?): ()
	local label = ui.Label:Clone()

	if players then
		for i, plr in players do
			if plr then
				label:SetAttribute("Player_" .. tostring(i), GetPlayerName(plr))
			end
		end
	end

	label:SetAttribute("Format", text)
	label:AddTag("DynamicNames")

	label:SetAttribute("TargetPosition", UDim2.fromScale(label.Position.X.Scale, 0))
	label.Position = UDim2.fromScale(label.Position.X.Scale, -0.3)
	label.BackgroundTransparency = 1
	label.TextTransparency = 1
	label.Visible = true

	moveDown(global)

	label.Parent = global :: any

	UIAnimation.Animate(label, TweenInfo.new(0.45), { Position = UDim2.fromScale(label.Position.X.Scale, 0) })

	fade(label, false)
	task.delay(2, fade, label, true)
end

local function makeLog(msg: string, players: {Player}?): ()
	local eventLog = UIManager.TryGetUI("EventLog") :: (UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.EventLog)})?
	if not eventLog then
		return
	end

	local label = eventLog.Object.ScrollingFrame.EventTemplate:Clone()

	if players then
		for i, plr in players do
			if plr then
				label:SetAttribute("Player_" .. tostring(i), GetPlayerName(plr))
			end
		end
	end

	label:SetAttribute("Format", msg)
	label:AddTag("DynamicNames")
	
	label.Visible = true
	label.LayoutOrder = #eventLog.Object.ScrollingFrame:GetChildren()

	label.Parent = eventLog.Object.ScrollingFrame

	UIAnimation.Animate(label, TweenInfo.new(0.25), {Size = UDim2.fromScale(1, 0.15)})
end

return function(msg: string, players: {Player}?)
	makeLabel(msg, players)
	makeLog(msg, players)
end