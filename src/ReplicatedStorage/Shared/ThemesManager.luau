local CollectionService = game:GetService("CollectionService")

local module = {}

export type Theme = {
	Primary: Color3,
	Secondary: Color3,
	Text: Color3,
	TextStroke: Color3,
	UIStroke: Color3,
	PlaceholderText: Color3,
}

module.Themes = {
	Dark = {
		Primary = Color3.fromRGB(17, 17, 17),
		Secondary = Color3.fromRGB(34, 34, 34),
		Text = Color3.fromRGB(255, 255, 255),
		TextStroke = Color3.fromRGB(0, 0, 0),
		PlaceholderText = Color3.fromRGB(178, 178, 178),
		UIStroke = Color3.fromRGB(255, 255, 255),
	},
} :: {[string]: Theme}

local THEME_TRANSITION_TIME = 0.25
function module.UpdateThemeInstance(v: Instance, theme: Theme?, noTransition: boolean?): ()
	-- Updates the theme for one instance
	-- Tag StyledUI means that a UI object will be updated to match the theme
	-- Attribute Style is the style to use for the main element(s) of an object (e.g, background colour for a frame, image colour for an image)
	
	local UIAnimation = require(script.Parent.UIAnimation)
	local tweenInfo = TweenInfo.new(THEME_TRANSITION_TIME, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
	theme = theme or module.Themes.Dark
	assert(theme)
	
	local inverse = v:GetAttribute("Inverse")
	local keepText = v:GetAttribute("KeepText")
	local updateImage = v:GetAttribute("UpdateImage")
	
	local style = v:GetAttribute("Style")
	
	local properties: {[string]: Color3} = {}
	if v.ClassName == "UIStroke" then
		properties.Color = if not inverse then theme["UIStroke"] else theme[style or "Text"]
	elseif v.ClassName == "TextButton" or v.ClassName == "TextLabel" or v.ClassName == "TextBox" then
		if not keepText then
			properties.TextColor3 = if not inverse then theme.Text else theme[style or "Primary"]
			properties.TextStrokeColor3 = if not inverse then theme.TextStroke else theme[style or "Text"]

			if v.ClassName == "TextBox" then
				properties.PlaceholderColor3 = if not inverse then theme.PlaceholderText else theme[style or "Primary"]
			end
		end
	elseif v.ClassName == "ImageButton" or v.ClassName == "ImageLabel" then
		if updateImage then
			properties.ImageColor3 = if not inverse then theme[style or "Text"] else theme[style or "Primary"]
		end
	elseif v.ClassName == "ChatWindowConfiguration" or v.ClassName == "ChatInputBarConfiguration" then
		properties.BackgroundColor3 = if not inverse then theme[style or "Primary"] else theme.Text
		properties.TextColor3 = if not inverse then theme.Text or theme.UIStroke else theme[style or "Primary"]
		properties.TextStrokeColor3 = if not inverse then theme.TextStroke else theme[style or "Primary"]

		if v.ClassName == "ChatInputBarConfiguration" then
			properties.PlaceholderColor3 = if not inverse then theme.PlaceholderText else theme[style or "Primary"]
		end
	end
	
	if v:IsA("GuiObject") then
		properties.BackgroundColor3 = if not inverse then theme[style or "Primary"] else theme.Text
		properties.BorderColor3 = if not inverse then theme.UIStroke else theme[style or "Primary"]
	end

	UIAnimation.Animate(v, tweenInfo, properties, noTransition)
	
	return
end

function module.UpdateTheme(theme: string | Theme): ()
	if typeof(theme) == "string" then
		theme = module.Themes[theme]
	end
	assert(typeof(theme) == "table")
	for _, v in CollectionService:GetTagged("StyledUI") do
		module.UpdateThemeInstance(v, theme)
	end
end

CollectionService:GetInstanceAddedSignal("StyledUI"):Connect(function(instance)
	module.UpdateThemeInstance(instance)
end)

return module