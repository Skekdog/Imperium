local ReplicatedFirst = game:GetService("ReplicatedFirst")
local CAS = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SM = require(script.Parent)

-- This must be run before anything yields, especially todo with ui
local options = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ServerClient"):WaitForChild("LoadSavedData").OnClientEvent:Wait()
options = SM.JSONDecode(options)

if options then
	for i, v in options do
		if i == "__VERSION" then
			continue
		end

		local setting = SM.Settings[i]
		if not setting then
			continue
		end
		local definition = setting.Definition
		if definition.SpecifyToggle == false then
			v.Toggled = (definition.Default :: SM.KeybindSetting).Toggled
		end
		SM.SetSetting(i, v)
	end
end
ReplicatedFirst:SetAttribute("ControlsReady", true)

local UIAnimation = require(script.Parent.Parent.UIAnimation)
local ScreenMessage = require(script.Parent.Parent.ScreenMessage)

local UIManager = require(ReplicatedFirst.Shared.UIManager)
local Controls = require(ReplicatedFirst.Shared.ControlManager)

local pageBase = script.__TabPage
local tabBase = script.__Tab

local keybindFrame = script.__SettingKeybind
local selectorFrame = script.__SettingSelector
local booleanFrame = script.__SettingBoolean

local ui = UIManager.WaitForUI("Settings") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Settings)}
local uiObject = ui.Object
local settingsFrame = uiObject.Main

local tabsFrame = settingsFrame.Tabs
local tabUnderline = tabsFrame.Underline
local createdTabs = {}
for _, v in SM.AvailableSettings do
	if not table.find(createdTabs, v.Tab) then
		table.insert(createdTabs, v.Tab)
	end
end

for i, v in createdTabs do
	local tab = tabBase:Clone() :: TextButton
	tab.Name = v
	tab.Text = v
	tab.Size = UDim2.fromScale(1 / #createdTabs, 1)
	tab.Position = UDim2.fromScale((i-1) / #createdTabs, 0)
	tab.Visible = true
	tab.LayoutOrder = i -- This is ordered more-or-less randomly, but the same random every time 
	tab.Parent = tabsFrame
	
	local page = pageBase:Clone() :: GuiObject
	page.Name = "Page_"..v
	page.LayoutOrder = i
	page.Parent = settingsFrame
	
	tab.MouseButton1Click:Connect(function()
		UIAnimation.TransitionUnderline(tabUnderline, tab)
		local currentPage
		for _, b in settingsFrame:GetChildren() do
			if (b.Name == "Page_"..settingsFrame:GetAttribute("CurrentTab") :: string) then
				currentPage = b :: GuiObject
				break
			end
		end
		if settingsFrame:GetAttribute("CurrentTab") == v then
			return
		end

		UIAnimation.TransitionUIPage(currentPage, page, UDim2.fromScale(0, 0.1))
		settingsFrame:SetAttribute("CurrentTab", v)
	end)
	
	if i == 1 then
		page.Visible = true
		settingsFrame:SetAttribute("CurrentTab", v)
		UIAnimation.TransitionUnderline(tabUnderline, tab)
	end
end

local tt = uiObject.Tooltip
local helpTarget: string?
local function tooltip(text: string, target: string)
	local show = helpTarget ~= target

	if show then
		tt.Text = text
		helpTarget = target
	else
		helpTarget = nil
	end

	tt.Visible = show
end

local categories = {__len = 0}

uiObject:GetPropertyChangedSignal("Visible"):Connect(function()
	if not uiObject.Visible then
		ReplicatedStorage:WaitForChild("Shared").ClientServer.SaveSettings:FireServer(SM.JSONEncode())
	end
end)

local keybindingCons: {RBXScriptConnection} = {}
for _, setting: SM.SettingDefinition in SM.AvailableSettings do
	local tab = setting.Tab
	local settingType = setting.PossibleValues
	local name = setting.Name
	local displayName = setting.DisplayName or name
	local page = settingsFrame:FindFirstChild("Page_"..tab) :: Instance
	
	local cat = setting.Category
	local catIndex = tab.."_"..cat
	if not categories[catIndex] then
		categories[catIndex] = 0
		
		local label = pageBase.CategoryLabel:Clone() :: TextLabel
		label.Text = cat
		label.LayoutOrder = categories["__len"]*1000
		label.Visible = true
		label.Name = "Category_"..cat
		label.Parent = page
		categories["__len"] += 1
	end
	local catLabel = page:FindFirstChild("Category_"..cat) :: TextLabel
	categories[catIndex] += 1
	
	local f: GuiObject
	if settingType == "Boolean" then
		local frame = booleanFrame:Clone() :: typeof(booleanFrame)
		local val = frame.Value
		UIAnimation.TransitionSwitch(val, SM.GetSetting(name) :: boolean)
		
		frame.Label.Text = displayName .. ":"
		
		frame.MouseButton1Click:Connect(function()
			local newVal = not SM.GetSetting(name)
			SM.SetSetting(name, newVal)
			UIAnimation.TransitionSwitch(frame.Value, newVal)
		end)
		f = frame
	elseif type(settingType) == "table" then
		local frame = selectorFrame:Clone() :: typeof(selectorFrame)
		frame.Label.Text = displayName .. ":"
		
		local opts = {}
		for i, v in settingType do
			local selections = frame.Selections
			
			local opt = selections.__Option:Clone()
			opt.Name = v
			opt.Text = v
			opt.Visible = true
			opt.Position = UDim2.fromScale((i-1) / #settingType, 0.5)
			
			local selectionUnderline = selections.Underline
			if SM.GetSetting(setting.Name) == v then
				UIAnimation.TransitionUnderline(selectionUnderline, opt)
			end
			
			opt.Parent = selections
			
			table.insert(opts, opt)
			opt.MouseButton1Click:Connect(function()
				SM.SetSetting(name, v)
				for _, p in opts do
					p.Text = p.Name
				end
				UIAnimation.TransitionUnderline(selectionUnderline, opt)
				opt.Text = v
			end)
		end
		f = frame
	elseif settingType == "Keybind" then
		local frame = keybindFrame:Clone()
		local m = frame.Frame
		m.Label.Text = displayName .. ":"
		
		local setBinds = SM.GetSetting(name) :: SM.KeybindSetting
		
		local function updateBinds(binds: {SM.Keybind})
			local numBoundKeys = 0
			for _, v in m.Keybinds:GetChildren() do
				if v:IsA("Frame") and (v.Name ~= "__KeybindFrame") then
					numBoundKeys += 1
				end
			end
			for i, v in binds do
				local bind = m.Keybinds.__KeybindFrame:Clone()
				
				bind.LayoutOrder = (i + numBoundKeys)*2 -- Separator in between, hence *2

				bind.Name = name .. tostring(i + numBoundKeys)
				
				local result = Controls.GetStringForKeyCode(v)
				if result:sub(1, 11) == "rbxasset://" then
					local img = bind.KeycodeImage
					img.Image = result
					img.Visible = true
					bind.Keycode.Visible = false
				else
					bind.Keycode.Text = result
				end

				bind.Visible = true
				bind.Parent = m.Keybinds

				if (numBoundKeys+i) > 1 then
					local sep = m.Keybinds.__Separator:Clone()
					sep.Name = "Separator"
					sep.Visible = true
					sep.LayoutOrder = bind.LayoutOrder-1
					sep.Name = "Separator"..tostring(sep.LayoutOrder)
					sep.Parent = m.Keybinds
				end

				local function removeBind()
					local binds = SM.GetSetting(name) :: SM.KeybindSetting
					table.remove(binds.Keycodes, table.find(binds.Keycodes, v))
					SM.SetSetting(name, binds)

					bind:Destroy()
					local sep
					if bind.Name:split(name)[2] == "1" then
						sep = m.Keybinds:FindFirstChild("Separator"..tostring(bind.LayoutOrder+1))
					else
						sep = m.Keybinds:FindFirstChild("Separator"..tostring(bind.LayoutOrder-1))
					end
					
					if sep then sep:Destroy() end
				end
				
				bind.KeycodeImage.MouseButton1Click:Connect(removeBind)
				bind.Keycode.MouseButton1Click:Connect(removeBind)
			end
		end
		
		updateBinds(setBinds.Keycodes)
		
		if setting.SpecifyToggle then
			local toggleButton = m.Toggled
			toggleButton.Visible = true
			toggleButton.Image = (SM.GetSetting(name) :: SM.KeybindSetting).Toggled and "rbxassetid://9155626912" or "rbxassetid://9155599240"
			toggleButton.MouseButton1Click:Connect(function()
				local cur = SM.GetSetting(name) :: SM.KeybindSetting
				cur.Toggled = not cur.Toggled
				SM.SetSetting(name, cur)
				
				toggleButton.Image = cur.Toggled and "rbxassetid://9155626912" or "rbxassetid://9155599240"
			end)
		end
		
		frame.ClickDetector.MouseButton1Click:Connect(function()
			for _, v in keybindingCons do
				v:Disconnect()
			end
			local msg = ScreenMessage("Info", "Press F5 to cancel keybinding.")
			CAS:BindActionAtPriority("SelectKeybind", function(_, state, input)
				
				if state ~= Enum.UserInputState.End then return end
				if (input.KeyCode == Enum.KeyCode.F5) then
					ScreenMessage("Info", "Cancelled keybinding.")
					if msg then msg:Destroy() end
					CAS:UnbindAction("SelectKeybind")
				end

				local t = if input.KeyCode ~= Enum.KeyCode.Unknown then input.KeyCode else input.UserInputType
				local cur = SM.GetSetting(name) :: SM.KeybindSetting
				table.insert(cur.Keycodes, t)
				SM.SetSetting(name, cur)
				if msg then msg:Destroy() end
				updateBinds({t})
				ScreenMessage("Success", "Keybinding updated!")
				ScreenMessage("Info", "Note: due to a bug, keybindings will not update until rejoining the game. Sorry!")
				CAS:UnbindAction("SelectKeybind")
				return
			end, false, 100000, Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.Keyboard, Enum.UserInputType.Gamepad1, Enum.UserInputType.MouseButton3)
		end)
		f = frame
	else
		error("Unknown setting type for Setting: "..setting.Name)
	end
	
	if not f then
		continue
	end
	
	f.Visible = true
	f.LayoutOrder = catLabel.LayoutOrder + categories[catIndex]
	f.Name = name
	f.Parent = settingsFrame:FindFirstChild("Page_"..tab)
	
	local help = f:FindFirstChild("Help") :: TextButton
	help.MouseButton1Click:Connect(function()
		tooltip(setting.Tooltip, setting.Name)
	end)
end