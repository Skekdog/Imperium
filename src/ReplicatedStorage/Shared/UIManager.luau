-- Taken from TYT. Last updated 08/09/24.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CreateSidebarButton = require(script.Parent.CreateSidebarButton)
local ControlManager = require(ReplicatedStorage.Shared.ControlManager)
local UIAnimation = require(script.Parent.UIAnimation)

local plr = Players.LocalPlayer
local plrUi = plr.PlayerGui

-- Undocumented behaviour, but GetGuiInset() returns zero sometimes
local inset = GuiService:GetGuiInset()
while inset == Vector2.zero do
	inset =  GuiService:GetGuiInset()
	task.wait()
end

--[[ Principles:
- Special is the highest layer
- Popups are 2nd highest. All popups should appear on top of others when they are made visible
- Buttons 3rd
- HUD is lowest layer

- All popups must have a close button and transition style
]]

local UIManager = {}

export type Layer = "Special" | "Popup" | "Button" | "HUD"

export type UI = {
	Name: string, -- Unique identifier
	Layer: Layer,
	DisplayName: string, -- Name shown in sidebar
	NoClose: boolean?, -- Prevents closing with the X key
	Visible: boolean,
	Sidebar: boolean?,
	Object: GuiObject,

	ToggleVisible: (self: UI, force: boolean?, ignoreOtherUIs: boolean?, callback: (() -> ())?) -> (),
	Unregister: (self: UI) -> (),
}

local registeredUIs: {UI} = {}

UIManager.UnregisteredUIs = script.Parent.UnregisteredUIs

function UIManager.RegisterUI(object: GuiObject): UI
	local ignoreInset = object:GetAttribute("IgnoreInset") :: boolean?
	local modal = object:GetAttribute("Modal") :: boolean?
	local transitionStyle = object:GetAttribute("TransitionStyle") :: "Position" | "Size"
	local transitionTarget = object:GetAttribute("TransitionTarget") :: UDim2

	local self: UI = {
		Name = object.Name,
		Layer = object:GetAttribute("Layer") :: Layer,
		DisplayName = object:GetAttribute("DisplayName") :: string? or object.Name,
		Visible = object.Visible,
		NoClose = object:GetAttribute("PreventClose") :: boolean?,
		Sidebar = object:GetAttribute("Sidebar") :: boolean?,
		Object = object,

		ToggleVisible = function(self: UI, force: boolean?, ignoreOtherUIs: boolean?, callback: ((Enum.PlaybackState) -> ())?)
			local newVisible = if force ~= nil then force else not self.Visible

			if newVisible == self.Visible then
				if callback then
					callback(Enum.PlaybackState.Cancelled)
				end
				return
			end

			self.Visible = newVisible

			local object = self.Object
			if transitionStyle then
				local tween = UIAnimation.TransitionUIState(object, newVisible)
				if callback then
					if tween then
						tween.Completed:Once(callback)
					else
						callback(Enum.PlaybackState.Completed)
					end
				end
			else
				object.Visible = newVisible
			end

			if ignoreOtherUIs or self.Layer ~= "Popup" then
				return
			end
			if object:GetAttribute("IgnoreStacking") then
				return
			end

			if not newVisible then
				object.ZIndex = 0
				return
			end

			local highestIndex = 0
			for _, ui in registeredUIs do
				if ui.Layer == "Popup" and highestIndex < ui.Object.ZIndex and ui.Visible then
					highestIndex = ui.Object.ZIndex
					if ui ~= self and not ui.Object:GetAttribute("IgnoreStacking") then
						ui:ToggleVisible(false, true)
					end
				end
			end
			object.ZIndex = highestIndex + 1
		end,

		Unregister = function(self: UI)
			if not table.find(registeredUIs, self) then
				return warn(self.Name.." is not registered!")
			end
			ControlManager.Unregister(self.Name)
			self:ToggleVisible(false, true, function()
				self.Object.Parent = UIManager.UnregisteredUIs
			end)
			
			if self.Sidebar then
				local sb = UIManager.GetUI("Sidebar").Object; -- Ambiguous syntax means we need a semicolon here, day ruined
				(sb :: any)[self.Name]:Destroy()
			end
			
			table.remove(registeredUIs, table.find(registeredUIs, self))
		end
	}
	
	if self.Layer == "Popup" and not object:GetAttribute("NoKeybind") then
		ControlManager.Register(self.Name, false, function(act, state, input, toggled)
			if not toggled then
				if state == Enum.UserInputState.End then
					self:ToggleVisible(false)
				elseif state == Enum.UserInputState.Begin then
					self:ToggleVisible(true)
				end
				return Enum.ContextActionResult.Sink
			end
			self:ToggleVisible()
			return Enum.ContextActionResult.Sink
		end)
	end
	
	if self.Sidebar then
		CreateSidebarButton(self.Name, self.DisplayName, function()
			self:ToggleVisible()
		end)
	end
	
	if not self.NoClose then
		local close = object:FindFirstChild("CloseUI") :: (ObjectValue & {Value: TextButton})?
		if close then
			close.Value.MouseButton1Click:Connect(function()
				self:ToggleVisible(false)
			end)
		elseif self.Layer == "Popup" then
			warn(self.Name.." does not have a registered Close button!")
		end
	end
	
	if ignoreInset and not object:GetAttribute("InsetAdjusted") then
		object:SetAttribute("InsetAdjusted", true)
		object.Size += UDim2.fromOffset(inset.X, inset.Y)
	end
	
	if transitionStyle then
		if not transitionTarget then -- check to make sure transTarget is not already set, because uis like EquipmentShop are registered multiple times
			local target: UDim2 | number
			if transitionStyle == "Size" then
				target = object.Size
			elseif transitionStyle == "Position" then
				target = object.Position
			elseif transitionStyle == "Transparency" then
				target = object.BackgroundTransparency
			end
			object:SetAttribute("TransitionTarget", target)
		end
	elseif self.Layer == "Popup" then
		warn(self.Name.." does not have a transition style!")
	end
	
	-- Disabled when ui is closing but not fully closed yet
	if modal then
		local modalise = Instance.new("TextButton")
		modalise.Modal = true
		modalise.Size = UDim2.new()
		modalise.Name = "Modalise"
		modalise.BackgroundTransparency = 1
		modalise.TextTransparency = 1
		
		modalise.Visible = true
		
		modalise.Parent = object
	end
	
	object.Parent = plrUi:FindFirstChild(self.Layer)
	table.insert(registeredUIs, self)
	return self
end

function UIManager.TryGetUI(name: string): UI?
	for _, v in registeredUIs do
		if v.Name == name then
			return v
		end
	end
	return
end

function UIManager.GetUI(name: string): UI
	for _, v in registeredUIs do
		if v.Name == name then
			return v
		end
	end
	error("Failed to find UI: "..name)
end

function UIManager.GetUIs(layer: Layer): {UI}
	local uis = {}
	for _, v in registeredUIs do
		if v.Layer == layer then
			table.insert(uis, v)
		end
	end
	return uis
end

function UIManager.WaitForUI(name: string, ignoreYield: boolean?): UI
	local start = os.clock()
	local warned = false
	repeat
		task.wait()
		if not warned and not ignoreYield then
			if start + 5 <= os.clock() then
				warned = true
				warn(debug.traceback(`Infinite yield possible on WaitForUI("{name}")`, 0))
			end
		end
	until UIManager.TryGetUI(name)
	return UIManager.GetUI(name)
end

return UIManager