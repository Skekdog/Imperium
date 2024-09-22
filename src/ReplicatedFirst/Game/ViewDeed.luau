local UIManager = require(script.Parent.Parent.Shared.UIManager)

local ui = UIManager.WaitForUI("PropertyDeed") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.PropertyDeed)}
local object = ui.Object

return function(tile: Model?): ()
    if not tile then
        return ui:ToggleVisible(false)
    end

    local name = tile:GetAttribute("Name") :: string?
    if not name then
        return ui:ToggleVisible(false)
    end

    if object.TitleFrame.PropertyName.Text == name then
        return ui:ToggleVisible()
    end

    object.TitleFrame.BackgroundColor3 = tile:GetAttribute("Colour") :: Color3
    object.TitleFrame.PropertyName.Text = name

    local housePrice = tile:GetAttribute("HousePrice") :: string?
    if housePrice then
        object.Frame.PricingInfo.House.Value.Text = "£" .. housePrice
    end

    local hotelPrice = tile:GetAttribute("HotelPrice") :: string?
    if hotelPrice then
        object.Frame.PricingInfo.Hotel.Value.Text = "£" .. hotelPrice
    end

    for _, v in object.Frame.RentInfo:GetChildren() do
        if v:IsA("Frame") and v.Name ~= "Template" then
            v:Destroy()
        end
    end

    local rentDescription = tile:GetAttribute("RentDescription") :: string?
    if rentDescription then
        for i, v in rentDescription:split("\n") do
            local line = object.Frame.RentInfo.Template:Clone()
            line.Name = "RentLine" .. tostring(i)
            line.Title.Text = v:split(":")[1] .. ":"
            line.Value.Text = v:split(":")[2]
            line.Visible = true
            line.LayoutOrder = i
            line.Parent = object.Frame.RentInfo
        end
    end

    local mortgageValue = tile:GetAttribute("MortgageValue") :: string?
    if mortgageValue then
        object.Frame.MortgageValue.Value.Text = "£" .. mortgageValue
    end

    ui:ToggleVisible(true)
end
