local TweenService = game:GetService("TweenService")
local SettingsManager = require(script.Parent.SettingsManager)

local module = {}

function module.Animate(object: Instance, tweenInfo: TweenInfo, properties: {[string]: any}, noAnimate: boolean?): Tween?
	local animate = SettingsManager.GetSetting("Animate UI Transitions")

	if not animate or noAnimate then
		for i, v in properties do
			(object :: any)[i] = v
		end
		return
	end
	local tween = TweenService:Create(object, tweenInfo, properties)
	tween:Play()
	return tween
end

function module.TransitionUIState(frame: GuiObject, open: boolean): Tween?
	-- If open is true, open animation should play, otherwise close
	
	local tween: Tween?
	local style = frame:GetAttribute("TransitionStyle")
	if style == "Position" or style == "Size" then
		local oldTween = frame:FindFirstChild("StateTransitionTween") :: Tween
		if oldTween then
			oldTween:Cancel()
			oldTween:Destroy()
		end

		local isSize = frame:GetAttribute("TransitionStyle") == "Size"
		local targetUDim = frame:GetAttribute("TransitionTarget") :: UDim2

		local direction = frame:GetAttribute("TransitionDirection") -- The direction it moves when OPENING
		local offScreenPosition = targetUDim
		if direction == "Right" then
			offScreenPosition = UDim2.fromScale(frame.Size.X.Scale * frame.AnchorPoint.X, targetUDim.Y.Scale)
		elseif direction == "Left" then
			offScreenPosition = UDim2.fromScale(1 + (frame.Size.X.Scale * frame.AnchorPoint.X), targetUDim.Y.Scale)
		elseif direction == "Up" then
			offScreenPosition = UDim2.fromScale(targetUDim.X.Scale, 1 + (frame.Size.Y.Scale * frame.AnchorPoint.Y))
		elseif direction == "Down" then
			offScreenPosition = UDim2.fromScale(targetUDim.X.Scale, frame.Size.Y.Scale * frame.AnchorPoint.Y)
		elseif not isSize then
			error("Invalid direction for "..frame.Name)
		end

		local function onFinish()
			if open then
				if isSize then
					frame.Size = targetUDim
				else
					frame.Position = targetUDim
				end
			else
				frame.Visible = false
				if isSize then
					frame.Size = UDim2.new()
				else
					frame.Position = offScreenPosition
				end
			end
		end
		
		local UI_TRANSITION_TIME = if open then 0.2 else tonumber(SettingsManager.GetSetting("Close Speed")) :: number
		local UI_SCALE_FACTOR = tonumber(SettingsManager.GetSetting("Close Scale")) :: number
		
		local startSize = UDim2.new(targetUDim.X.Scale * UI_SCALE_FACTOR, targetUDim.X.Offset * UI_SCALE_FACTOR, targetUDim.Y.Scale * UI_SCALE_FACTOR, targetUDim.Y.Offset * UI_SCALE_FACTOR)
		
		local info = TweenInfo.new(
			UI_TRANSITION_TIME,
			Enum.EasingStyle.Exponential,
			Enum.EasingDirection.Out
		)
		
		local properties: {[string]: any}
		if isSize then
			properties = {
				Size = if open then targetUDim else startSize
			}
		else
			properties = {
				Position = if open then targetUDim else offScreenPosition
			}
		end
		
		tween = module.Animate(frame, info, properties)
		
		if open then
			if isSize then
				frame.Size = startSize
			else
				frame.Position = offScreenPosition
			end
			frame.Visible = true
		end
		
		local modalise = frame:FindFirstChild("Modalise") :: TextButton
		if modalise then
			modalise.Visible = open
		end

		if tween then
			tween.Completed:Once(function()
				tween:Destroy()
				onFinish()
			end)
			tween.Name = "StateTransitionTween"
			tween.Parent = frame
		else
			onFinish()
		end
	elseif style == "Transparency" then
		local lastTween: Tween?
		for _, v in frame:GetDescendants() do
			local oldTween = v:FindFirstChildOfClass("Tween")
			if oldTween then
				oldTween:Cancel()
				oldTween:Destroy()
			end

			local property
			if v:IsA("ImageLabel") then
				property = "ImageTransparency"
			elseif v:IsA("Frame") then
				property = "BackgroundTransparency"
			else
				continue
			end

			if open then
				(v :: any)[property] = 1
			end

			local properties = {[property] = if open then 0 else 1}
			tween = module.Animate(v, TweenInfo.new(0.25, Enum.EasingStyle.Quad), properties)

			if tween then
				lastTween = tween
				tween.Parent = v
				tween.Completed:Once(function()
					tween:Destroy()
					if open then
						(v :: any)[property] = 0
					else
						(v :: any)[property] = 1
					end
				end)
			end
		end

		if open then
			frame.Visible = true
		end

		if lastTween and not open then
			lastTween.Completed:Once(function()
				frame.Visible = false
			end)
		end
	end
	
	return tween
end

function module.TransitionSwitch(target: GuiObject, disabled: boolean)
	disabled = not disabled
	local switch = target:FindFirstChild("Switch") :: TextLabel
    module.Animate(switch, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Position = UDim2.fromScale(disabled and 0.9 or 0.1, 0.5)})
	module.Animate(target,
		TweenInfo.new(
			0.25,
			Enum.EasingStyle.Quad
		), {
			BackgroundColor3 = disabled and Color3.fromRGB(189, 0, 0) or Color3.fromRGB(47, 189, 47)
		}
	)
	
	switch.Text = disabled and "O" or "I"
end

local pageTransitionTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)
function module.TransitionUIPage(currentPage: GuiObject, newPage: GuiObject, targetPosition: UDim2): ()
	assert(currentPage.LayoutOrder ~= newPage.LayoutOrder, `I forgor 💀 (Page transition failed for {currentPage:GetFullName()})`)
	local goRight = currentPage.LayoutOrder < newPage.LayoutOrder

	local targetPositionForCurrent
	if goRight then
		targetPositionForCurrent = UDim2.new(targetPosition.X - currentPage.Size.X, newPage.Position.Y)
		newPage.Position = UDim2.new(targetPosition.X + newPage.Size.X, newPage.Position.Y)
	else
		targetPositionForCurrent = UDim2.new(targetPosition.X + currentPage.Size.X, newPage.Position.Y)
		newPage.Position = UDim2.new(targetPosition.X - newPage.Size.X, newPage.Position.Y)
	end

	newPage.Visible = true
	module.Animate(newPage, pageTransitionTweenInfo, { Position = targetPosition })

	local tween = module.Animate(currentPage, pageTransitionTweenInfo, { Position = targetPositionForCurrent })
	if tween then
		tween:GetPropertyChangedSignal("PlaybackState"):Connect(function()
			if tween.PlaybackState == Enum.PlaybackState.Completed then
				currentPage.Visible = false
			end
		end)
	end
end

local UNDERLINE_TRANSITION_SCALE = 0.125
local UNDERLINE_TRANSITION_TIME = 0.5
function module.TransitionUnderline(underline: Frame, target: TextButton)
	local halfSize = UDim2.new(target.Size.X.Scale * UNDERLINE_TRANSITION_SCALE, 0, underline.Size.Y.Scale, 0)
	local fullSize = UDim2.new(target.Size.X.Scale / 1.5, 0, underline.Size.Y.Scale, 0)
	
	local newPosition = UDim2.fromScale(target.Position.X.Scale + (target.Size.X.Scale / 2), 1)
	
	local halfSizeTween = module.Animate(underline, TweenInfo.new(
		UNDERLINE_TRANSITION_TIME / 2,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
	),
		{ Size = halfSize }
	)
	
	local function originalSize()
		module.Animate(underline, TweenInfo.new(
			UNDERLINE_TRANSITION_TIME / 2,
			Enum.EasingStyle.Exponential,
			Enum.EasingDirection.Out
			),
			{ Size = fullSize }
		)
	end
	if halfSizeTween then
		halfSizeTween.Completed:Once(originalSize)
	else
		originalSize()
	end
	
	-- Tween position
	module.Animate(underline, TweenInfo.new(
		UNDERLINE_TRANSITION_TIME,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
		),
	{ Position = newPosition })
end

function module.Slider(background: Frame, noTransition: boolean?, value: number, max: number): ()
	module.Animate(background, TweenInfo.new(0.1), {Size = UDim2.new(value / max, 0, 1, 0)}, noTransition)
end

return module