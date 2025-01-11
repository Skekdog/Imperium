local UIManager = require(script.Parent.Parent.Shared.UIManager)
local diceRollUI = UIManager.WaitForUI("RollDice")
local payFineUI = UIManager.WaitForUI("PayFine")
local useGetOutOfJailFreeCardUI = UIManager.WaitForUI("UseGetOutOfJailFreeCard")

return function(): ()
    diceRollUI:ToggleVisible(false)
    payFineUI:ToggleVisible(false)
    useGetOutOfJailFreeCardUI:ToggleVisible(false)
end
