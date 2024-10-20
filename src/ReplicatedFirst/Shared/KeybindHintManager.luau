local CollectionService = game:GetService("CollectionService")
local ControlManager = require(script.Parent.ControlManager)
local SettingsManager = require(script.Parent.SettingsManager)

local boundInstances: {[string]: {TextLabel}} = {}

local function setText(control: string, label: TextLabel): ()
    local text = ControlManager.GetFirstKeyCode(control, true)
    if text == "" then
        label.Text = ""
        return
    end
    label.Text = `[{text}]`
end

SettingsManager.KeybindUpdatedEvent.Event:Connect(function(actionName: string)
    if boundInstances[actionName] then
        for _, v in boundInstances[actionName] do
            setText(actionName, v)
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

    local label = Instance.new("TextLabel")
    setText(control, label)
    label.Position = position or UDim2.fromScale(1, 0)
    label.AnchorPoint = anchorPoint or Vector2.new(0.5, 0.5)
    label.Size = size or UDim2.fromScale(0.45, 0.6)
    label.TextScaled = true
    label.Font = Enum.Font.SourceSans
    label.BackgroundTransparency = 1
    label.TextStrokeTransparency = 0

    if not noStyle then
        label:AddTag("StyledUI")
    end

    label.Parent = instance

    if not boundInstances[control] then
        boundInstances[control] = {}
    end
    table.insert(boundInstances[control], label)
end

CollectionService:GetInstanceAddedSignal("ControlHint"):Connect(loadInstance)
for _, v in CollectionService:GetTagged("ControlHint") do
    loadInstance(v)
end

return function(): ()
    return
end
