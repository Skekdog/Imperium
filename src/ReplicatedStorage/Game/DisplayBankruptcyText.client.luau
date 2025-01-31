local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetCurrencySymbol = require(script.Parent.GetCurrencySymbol)
local GetPlayerName = require(ReplicatedStorage.Shared.GetPlayerName)
local UIAnimation = require(ReplicatedStorage.Shared.UIAnimation)
local UIManager = require(ReplicatedStorage.Shared.UIManager)

local ui = UIManager.WaitForUI("CurrentTurnIndicator")
local object = ui.Object :: typeof(UIManager.UnregisteredUIs.CurrentTurnIndicator)

local function animate(visible: boolean): ()
	UIAnimation.Animate(object.Bankruptcy, TweenInfo.new(0.1), {
        Position = UDim2.fromScale(0.5, if visible then 1 else 0.7)
    })
end

ReplicatedStorage.Game.ServerClient.Bankruptcy.OnClientEvent:Connect(function(plrName: Player?, neededMoney: number?)
	if not plrName then
		return animate(false)
	end

	object.Bankruptcy:SetAttribute("Player_1", GetPlayerName(plrName))
	object.Bankruptcy:SetAttribute("Format", `[PLAYER] IS GOING BANKRUPT (NEED ANOTHER {GetCurrencySymbol()}{neededMoney})`)
	object.Bankruptcy:SetAttribute("MakeUpper", true)
	object.Bankruptcy:AddTag("DynamicNames")

	animate(true)
end)
