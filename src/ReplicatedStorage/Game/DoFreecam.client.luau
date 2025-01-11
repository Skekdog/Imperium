local Freecam = require(script.Parent.Freecam)
local ControlManager = require(script.Parent.Parent.Shared.ControlManager)
local CreateSidebarButton = require(script.Parent.Parent.Shared.CreateSidebarButton)

ControlManager.Register("Freecam", false, function()
    Freecam()
    return Enum.ContextActionResult.Sink
end)

CreateSidebarButton("Freecam", "Freecam", Freecam)