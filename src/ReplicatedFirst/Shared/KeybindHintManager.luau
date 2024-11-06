local CollectionService = game:GetService("CollectionService")
local ControlManager = require(script.Parent.ControlManager)
local SettingCallback = require(script.Parent.SettingCallback)
local SettingsManager = require(script.Parent.SettingsManager)

local boundInstances: {[string]: {Instance}} = {}

type Label = TextLabel | ImageLabel

local function setTextForTextLabel(text: string, label: TextLabel): ()
    if text == "" or text == "NONE" then
        label.Text = ""
        return
    end
    label.Text = `[{text}]`
end

local function setImageForImageLabel(image: string, label: ImageLabel): ()
    label.Image = image
end

local function createLabel(class: "TextLabel" | "ImageLabel", control: string, instance: Instance, position: UDim2?, size: UDim2?, anchorPoint: Vector2?, noStyle: boolean?): Label
    local label = Instance.new(class) :: GuiObject

    label.Position = position or UDim2.fromScale(1, 0)
    label.AnchorPoint = anchorPoint or Vector2.new(0.5, 0.5)
    label.Size = size or UDim2.fromScale(0.45, 0.6)
    label.BackgroundTransparency = 1
    label.Visible = false

    if class == "TextLabel" then
        assert(label:IsA("TextLabel"))

        label.TextScaled = true
        label.Font = Enum.Font.SourceSans
        label.TextStrokeTransparency = 0
        
        if not noStyle then
            label:AddTag("StyledUI")
        else
            label.TextColor3 = Color3.new(1, 1, 1)
        end
    elseif class == "ImageLabel" then
        assert(label:IsA("ImageLabel"))

        if not noStyle then
            label:AddTag("StyledUI")
        else
            label.ImageColor3 = Color3.new(1, 1, 1)
        end

        Instance.new("UIAspectRatioConstraint", label)
    end

    label.Parent = instance

    return label :: Label
end

local function createLabels(control: string, instance: Instance, position: UDim2?, size: UDim2?, anchorPoint: Vector2?, noStyle: boolean?): ()
    createLabel("ImageLabel", control, instance, position, size, anchorPoint, noStyle)
    createLabel("TextLabel", control, instance, position, size, anchorPoint, noStyle)

    if not boundInstances[control] then
        boundInstances[control] = {}
    end
    table.insert(boundInstances[control], instance)
end

local function updateText(control: string, instance: Instance): ()
    local text = ControlManager.GetFirstKeyCode(control, true)

    local imageLabel = instance:FindFirstChildOfClass("ImageLabel") :: ImageLabel?
    local textLabel = instance:FindFirstChildOfClass("TextLabel") :: TextLabel?

    if text:sub(1, 11) == "rbxasset://" then
        if not imageLabel then
            return
        end

        if textLabel then
            textLabel.Visible = false
        end

        imageLabel.Visible = true
        setImageForImageLabel(text, imageLabel)
    else
        if not textLabel then
            return
        end

        if imageLabel then
            imageLabel.Visible = false
        end

        textLabel.Visible = true
        setTextForTextLabel(text, textLabel)
    end
end

SettingCallback.Listen(function(name, value)
    if boundInstances[name] then
        for _, v in boundInstances[name] do
            updateText(name, v)
        end
    end
end)

local function loadInstance(instance: Instance): ()
    local control = instance:GetAttribute("Control") :: string?
    assert(typeof(control) == "string", "Expected attribute 'Control' to be a string")
    assert(SettingsManager.Settings[control], "Control not found: " .. control)

    local position = instance:GetAttribute("Position") :: UDim2?
    assert(typeof(position) == "UDim2" or position == nil, "Expected attribute 'Position' to be a UDim2 or nil")

    local size = instance:GetAttribute("Size") :: UDim2?
    assert(typeof(size) == "UDim2" or size == nil, "Expected attribute 'Size' to be a UDim2 or nil")

    local anchorPoint = instance:GetAttribute("AnchorPoint") :: Vector2?
    assert(typeof(anchorPoint) == "Vector2" or anchorPoint == nil, "Expected attribute 'AnchorPoint' to be a Vector2 or nil")

    local noStyle = instance:GetAttribute("NoStyle") :: boolean?
    createLabels(control, instance, position, size, anchorPoint, noStyle)
end

CollectionService:GetInstanceAddedSignal("ControlHint"):Connect(loadInstance)
for _, v in CollectionService:GetTagged("ControlHint") do
    loadInstance(v)
end

return function(): ()
    return
end
