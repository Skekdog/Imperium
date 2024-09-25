local HTTPService = game:GetService("HttpService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local UserInputService = game:GetService("UserInputService")

export type SettingDefinition = {
	Name: string,
	DisplayName: string?,
	Tab: "Display" | "Gameplay" | "Controls" | "Touch" | "General" | "Keybinds",
	Category: string,
	Tooltip: string,
	PossibleValues: {string} | "Boolean" | "Keybind" | "TouchPosition" | "TouchScale",
	Default: Setting,
	SpecifyToggle: boolean?, -- Whether the user can change if this is toggled or not. Only for keybinds.
	Callback: ((val: Setting?, name: string?) -> ())?,
}

export type Keybind = Enum.UserInputType | Enum.KeyCode
export type KeybindSetting = {
	Keycodes: {Keybind},
	Toggled: boolean,
}
export type Setting = KeybindSetting | string | boolean | UDim2 | number -- SelectionChoice, Boolean, TouchPosition, TouchScale

local module = {}

module.SETTINGS_VERSION = 3
module.Settings = {}
module.AvailableSettings = {
	{
		Name = "UI Theme",
		Tab = "Display",
		Category = "User Interface",
		Tooltip = "Select a theme for the UI.",
		PossibleValues = {"Dark", "Light", "Blue"},
		Default = "Dark",
		Callback = function(val) -- Can't directly reference this because cyclic dependency!
			require(script.Parent.ThemesManager).UpdateTheme(val)
		end :: any,
	},
	{
		Name = "Player Names",
		Tab = "Display",
		Category = "User Interface",
		Tooltip = "Choose whether to show display names, usernames, or both.",
		PossibleValues = {"Display Name", "Username", "Both"},
		Default = "Display Name",
	},
	{
		Name = "Sidebar Alignment",
		Tab = "Display",
		Category = "User Interface",
		Tooltip = "Controls the position of the sidebar. May be useful on phones with inset screens.",
		PossibleValues = {"Left", "Right"},
		Default = "Right",
		Callback = function(val)
			require(ReplicatedFirst.Shared.SetSidebarAlignment)(val)
		end
	},
	{
		Name = "Animate UI Transitions",
		Tab = "Display",
		Category = "User Interface",
		Tooltip = "Enables animated transitions for all UI.",
		PossibleValues = "Boolean",
		Default = true,
	},
	{
		Name = "Always Show Sidebar",
		Tab = "Display",
		Category = "User Interface",
		Tooltip = "This setting has no effect if a keyboard is not connected.",
		PossibleValues = "Boolean",
		Default = true,
		Callback = function(val)
			if not UserInputService.KeyboardEnabled then
				return
			end
			local sidebar = require(script.Parent.UIManager).WaitForUI("Sidebar")
			if sidebar then
				sidebar:ToggleVisible(val :: boolean)
			end
		end
	},
	{
		Name = "Close Scale",
		Tab = "Display",
		Category = "Development",
		Tooltip = "Intended for dev use only.",
		PossibleValues = {"0", "0.25", "0.5", "0.75"},
		Default = "0.75",
	},
	{
		Name = "Close Speed",
		Tab = "Display",
		Category = "Development",
		Tooltip = "Intended for dev use only.",
		PossibleValues = {"0.2", "0.3", "0.4", "0.5"},
		Default = "0.2",
	},

	{
		Name = "Roll Dice",
		Tab = "Keybinds",
		Category = "Controls",
		Tooltip = "Rolls the dice.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes = {Enum.KeyCode.Space, Enum.KeyCode.ButtonR3}, Toggled = true},
	},
	{
		Name = "Pay Fine",
		Tab = "Keybinds",
		Category = "Controls",
		Tooltip = "Pays fine when in jail, if possible.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes = {Enum.KeyCode.F, Enum.KeyCode.ButtonR2}, Toggled = true},
	},
	{
		Name = "Use Jail Card",
		Tab = "Keybinds",
		Category = "Controls",
		Tooltip = "Uses a Get Out of Jail Free card, if possible.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes = {Enum.KeyCode.E, Enum.KeyCode.ButtonR1}, Toggled = true},
	},

	{
		Name = "Close UI",
		Tab = "Keybinds",
		Category = "Menus",
		Tooltip = "Closes the fore-most UI.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes = {Enum.KeyCode.X, Enum.KeyCode.ButtonB}, Toggled = true},
	},
	{
		Name = "Playerlist",
		Tab = "Keybinds",
		Category = "Menus - Enable the checkbox to make a keybind toggled",
		Tooltip = "Opens the playerlist.",
		PossibleValues = "Keybind",
		SpecifyToggle = true,
		Default = {Keycodes = {Enum.KeyCode.Tab, Enum.KeyCode.ButtonL3}, Toggled = false},
	},
	{
		Name = "Asset Manager",
		Tab = "Keybinds",
		Category = "Menus - Enable the checkbox to make a keybind toggled",
		Tooltip = "Opens the asset manager.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes = {Enum.KeyCode.C, Enum.KeyCode.ButtonR2}, Toggled = true},
	},
	{
		Name = "Confirm Purchase",
		Tab = "Keybinds",
		Category = "Menus - Enable the checkbox to make a keybind toggled",
		Tooltip = "Opens the confirm purchase menu. Can also be opened by typing !purchase in chat.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes = {Enum.KeyCode.Y, Enum.KeyCode.ButtonR1}, Toggled = true},
	},
	{
		Name = "Settings",
		Tab = "Keybinds",
		Category = "Menus - Enable the checkbox to make a keybind toggled",
		Tooltip = "Opens the settings page. Can also be opened by typing !settings in chat.",
		PossibleValues = "Keybind",
		SpecifyToggle = true,
		Default = {Keycodes = {Enum.KeyCode.G, Enum.KeyCode.ButtonR3}, Toggled = true},
	},
	{
		Name = "EventLog",
		DisplayName = "Event Log",
		Tab = "Keybinds",
		Category = "Menus - Enable the checkbox to make a keybind toggled",
		Tooltip = "Opens the event log.",
		PossibleValues = "Keybind",
		SpecifyToggle = true,
		Default = {Keycodes = {Enum.KeyCode.B, Enum.KeyCode.ButtonR1}, Toggled = true},
	},
	{
		Name = "View Board Property",
		Tab = "Keybinds",
		Category = "Menus - Enable the checkbox to make a keybind toggled",
		Tooltip = "Opens the property deed at the current mouse position.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes = {Enum.UserInputType.MouseButton1}, Toggled = true},
	},
} :: {SettingDefinition}


for _, v in module.AvailableSettings do
	module.Settings[v.Name] = {Value = v.Default, Definition = v}
end

function module.SetSetting(setting: string, settingValue: Setting)
	local ref = module.Settings[setting]
	ref.Value = settingValue
	if ref.Definition.Callback then
		ref.Definition.Callback(settingValue, setting)
	end
end

function module.GetSetting(settingName: string): Setting
	return module.Settings[settingName].Value
end

-- This whole section of serialisation is horrid but it works
local function keybindToJson(keybind: KeybindSetting): string
	local keycodeText = '['
	for i, v in keybind.Keycodes do
		keycodeText = keycodeText .. `"{v}"` .. if i < #keybind.Keycodes then "," else ""
	end
	keycodeText = keycodeText..']'
	return `\{"Keycodes":{keycodeText},"Toggled":{keybind.Toggled}}`
end

function module.JSONEncode(): string
	local toEncode = {__VERSION = module.SETTINGS_VERSION}
	for i, v in module.Settings do
		local value = v.Value
		local converted: any = value
		if typeof(value) == "UDim2" then
			converted = {value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset}
		elseif (typeof(value) == "table") and value.Keycodes then
			converted = keybindToJson(value)
		end
		toEncode[i] = converted
	end
	return HTTPService:JSONEncode(toEncode)
end

function module.JSONDecode(optionsString): {} | false
	local options = HTTPService:JSONDecode(optionsString)
	local version = options.__VERSION
	if version ~= module.SETTINGS_VERSION then
		return false
	end
	for i, v in options do
		local isKeybind, isTouchPosition
		for _, p in module.AvailableSettings do
			if p.Name == i then
				isKeybind = p.PossibleValues == "Keybind"
				isTouchPosition = p.PossibleValues == "TouchPosition"
				break
			end
		end
		if isKeybind then
			local result = HTTPService:JSONDecode(v) :: KeybindSetting
			for b, keybind in result.Keycodes do
				assert(typeof(keybind) == "string")
				result.Keycodes[b] = (Enum :: any)[keybind:split(".")[2]][keybind:split(".")[3]]
			end
			options[i] = result
		elseif isTouchPosition then
			options[i] = UDim2.new(v[1], v[2], v[3], v[4])
		end
	end
	return options
end

return module
