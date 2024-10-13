local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LobbyTypes = require(script.Parent.LobbyTypes)
local GameConfiguration = require(script.Parent.Parent.Shared.GameConfiguration)
local GetPlayerName = require(script.Parent.Parent.Shared.GetPlayerName)
local Notification = require(script.Parent.Parent.Shared.Notification)
local PlayClickSound = require(script.Parent.Parent.Shared.PlayClickSound)
local UIAnimation = require(script.Parent.Parent.Shared.UIAnimation)
local UIManager = require(script.Parent.Parent.Shared.UIManager)

local serverClient = ReplicatedStorage:WaitForChild("Lobby"):WaitForChild("ServerClient")
local clientServer = ReplicatedStorage:WaitForChild("Lobby"):WaitForChild("ClientServer")

local MAX_PLAYERS = 8

local ui = UIManager.WaitForUI("LobbyUI") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.LobbyUI)}

local browser = ui.Object.Browser
local hostView = ui.Object.HostView
local create = ui.Object.Create

type LobbySlot = typeof(browser.LobbyTemplate)
type LobbyOverview = typeof(hostView.LobbyOverview)
type PrivateLobbySlot = typeof(browser.PrivateLobbyTemplate)
type AnyLobbySlot = LobbySlot | PrivateLobbySlot | LobbyOverview

local lobbies: {[number]: LobbySlot?} = {}

local camera = workspace.CurrentCamera
camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = CFrame.fromEulerAnglesXYZ(math.rad(-40), math.rad(170), 0)

local DURATION = 240
local timePerHour = DURATION / 24
local function animateTime(): ()
    local tween = TweenService:Create(Lighting, TweenInfo.new((24 - Lighting.ClockTime) * timePerHour, Enum.EasingStyle.Linear), {ClockTime = 24})
    tween:Play()

    tween.Completed:Once(animateTime)
end
animateTime()

local currentLobby: number?
local function setCurrentLobby(id: number?): ()
    local function resetSlots(): ()
        for _, v in browser:GetChildren() do
            if v:IsA("Frame") then
                local slot = v :: LobbySlot
                slot.UIStroke.Color = Color3.new(1, 1, 1);
                slot.Join.UIStroke.Color = Color3.new(1, 1, 1)

                slot.Join.BackgroundColor3 = Color3.fromRGB(0, 217, 90)
                slot.Join.Text = "▶"
            end
        end
    end

    currentLobby = id
    if not id then
        return resetSlots()
    end
    
    local slot = lobbies[id]

    if not slot then
        return
    end

    if slot.Parent ~= (hostView :: any) then
        for _, v in browser:GetChildren() do
            if v:IsA("Frame") then
                local vSlot = v :: LobbySlot
                vSlot.UIStroke.Color = Color3.new(1, 1, 1);
                vSlot.Join.UIStroke.Color = Color3.new(1, 1, 1)
            end
        end

        slot.UIStroke.Color = Color3.fromRGB(55, 255, 0)
        slot.Join.UIStroke.Color = Color3.fromRGB(55, 255, 0)

        slot.Join.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
        slot.Join.Text = "🚪"
    end
end

local function getThumbnail(plr: Player): string
    return (Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100))
end

local function addPlayer(slot: LobbySlot, plr: Player): ()
    local thumbnail = getThumbnail(plr)
    local image = slot.Players.PlayerTemplate:Clone()

    image.Name = tostring(plr.UserId)
    image.Visible = true
    image.Image = thumbnail
    image.Parent = slot.Players

    slot.Capacity.Text = `{#slot.Players:GetChildren() - 3} / {tostring(MAX_PLAYERS)}`

    if slot.Parent == (hostView :: any) then
        local button: typeof(hostView.LobbyOverview.Players.PlayerTemplate) = image :: any
        button.MouseEnter:Connect(function()
            button.Kick.Visible = true
        end)
        button.MouseLeave:Connect(function()
            button.Kick.Visible = false
        end)

        button.Activated:Connect(function()
            PlayClickSound()
            clientServer.KickPlayer:FireServer(plr)
        end)
    end
end

local function removePlayer(slot: LobbySlot, plr: Player): ()
    local image = slot.Players:FindFirstChild(tostring(plr.UserId))
    if image then
        image:Destroy()
    end

    slot.Capacity.Text = `{#slot.Players:GetChildren() - 3} / {tostring(MAX_PLAYERS)}`
end

local function setHostSettingsView(setting: string, value: string | number): ()
    local option = hostView.Settings:FindFirstChild(setting) :: typeof(hostView.Settings.InputSettingTemplate) | typeof(hostView.Settings.SelectionSettingTemplate)?

    if not option then
        return
    end

    local input = (option :: any):FindFirstChild("Input")
    if input then
        input.Text = tostring(value)
    else
        local selections = (option :: any):FindFirstChild("Options") :: typeof(hostView.Settings.SelectionSettingTemplate.Options)
        local selection = selections:FindFirstChild(tostring(value))

        if not selection or not selection:IsA("TextButton") then
            return
        end
        UIAnimation.TransitionUnderline(selections.Underline, selection)
    end
end

local function updateSetting(slot: LobbySlot, setting: string, value: string | number): ()
    local element = slot.Configuration:FindFirstChild(setting) :: typeof(slot.Configuration.SettingTemplate)?
    if not element then
        element = slot.Configuration.SettingTemplate:Clone()
    end
    assert(element)

    element.Title.Text = GameConfiguration[setting].DisplayName
    element.LayoutOrder = GameConfiguration[setting].Order
    element.Value.Text = tostring(value)
    element.Visible = true
    element.Name = setting
    element.Parent = slot.Configuration

    if slot.Parent == (hostView :: any) then
        setHostSettingsView(setting, value)
    end
end

local function createLobbySlot(lobby: LobbyTypes.ClientLobby): ()
    local id = lobby.Owner.UserId

    local slot: LobbySlot
    local parent: Instance
    if lobby.Owner == Players.LocalPlayer then
        slot = hostView.LobbyOverview :: any;
        (slot :: any).Password.Text = lobby.Password
        parent = hostView
    elseif lobby.Private then
        slot = browser.PrivateLobbyTemplate:Clone() :: any
        parent = browser
        slot.Name = tostring(lobby.Owner.UserId)
    else
        slot = browser.LobbyTemplate:Clone()
        parent = browser
        slot.Name = tostring(id)
    end

    slot.Visible = true

    for _, plr in lobby.Players do
        addPlayer(slot, plr)
    end

    for setting, value in lobby.Settings :: {[string]: string | number} do
        updateSetting(slot, setting, value)
    end

    local lobbyNameLabel = slot.LobbyName
    lobbyNameLabel:SetAttribute("Player_1", GetPlayerName(lobby.Owner))
    lobbyNameLabel:SetAttribute("Format", "[PLAYER]'s Lobby")
    lobbyNameLabel:AddTag("DynamicNames")

    lobbies[id] = slot

    slot.Parent = parent :: any

    if lobby.Owner ~= Players.LocalPlayer then
        slot.Join.Activated:Connect(function()
            PlayClickSound()
            if id == currentLobby then
                return clientServer.LeaveLobby:FireServer(id)
            end

            local password = ""
            if lobby.Private then
                password = ((slot :: any) :: PrivateLobbySlot).Password.Text
            end
            local response = clientServer.JoinLobby:InvokeServer(id, password)
            if response ~= "Success" then
                Notification(`Failed to join lobby because {response}.`)
            else
                setCurrentLobby(id)
            end
        end)
    end
end

local function switchView(view: "Browser" | "HostView" | "None"): ()
    hostView.Visible = view == "HostView"
    browser.Visible = view == "Browser"
    create.Visible = view == "Browser"
end

local function removeLobbySlot(userId: number): ()
    if userId == currentLobby then
        currentLobby = nil
    end

    local slot = lobbies[userId]

    if not slot then
        return
    end

    if slot.Parent == (hostView :: any) then
        switchView("Browser")
        local overview: LobbyOverview = hostView.LobbyOverview
        for _, v in overview.Players:GetChildren() do
            if v.Name ~= "PlayerTemplate" and v:IsA("ImageButton") then
                v:Destroy()
            end
        end

        for _, v in overview.Configuration:GetChildren() do
            if v.Name ~= "SettingTemplate" and v:IsA("Frame") then
                v:Destroy()
            end
        end
    else
        slot:Destroy()
    end

    lobbies[userId] = nil
end

local function addPlayerToLobby(lobbyId: number, plr: Player): ()
    local lobby = lobbies[lobbyId]
    if lobby then
        addPlayer(lobby, plr)
    end
end

local function removePlayerFromLobby(lobbyId: number, plr: Player): ()
    if lobbyId == currentLobby then
        setCurrentLobby(nil)
    end

    local lobby = lobbies[lobbyId]
    if lobby then
        removePlayer(lobby, plr)
    end
end

local function updateSettingForLobby(lobbyId: number, setting: string, value: string | number): ()
    local lobby = lobbies[lobbyId]
    if lobby then
        updateSetting(lobby, setting, value)
    end
end

serverClient.LobbyAdded.OnClientEvent:Connect(createLobbySlot)
serverClient.LobbyRemoved.OnClientEvent:Connect(removeLobbySlot)
serverClient.PlayerAdded.OnClientEvent:Connect(addPlayerToLobby)
serverClient.PlayerRemoved.OnClientEvent:Connect(removePlayerFromLobby)
serverClient.SettingUpdated.OnClientEvent:Connect(updateSettingForLobby)

ui.Object.Create.TextButton.Activated:Connect(function()
    PlayClickSound()
    clientServer.CreateLobby:FireServer(ui.Object.Create.Password.Text)
    switchView("HostView")
end)

hostView.Start.Activated:Connect(function()
    PlayClickSound()
    clientServer.StartLobby:FireServer()
end)

local settingsOverview = hostView.Settings
for _, setting in GameConfiguration do
    if setting.PossibleValues == "number" then
        local inputSetting = settingsOverview.InputSettingTemplate:Clone()

        inputSetting.Name = setting.Name
        inputSetting.Title.Text = setting.DisplayName
        inputSetting.LayoutOrder = setting.Order
        
        local placeholderText
        if setting.Min and setting.Max then
            placeholderText = `{setting.Min} - {setting.Max}`
        elseif setting.Min then
            placeholderText = `{setting.Min}+`
        elseif setting.Max then
            placeholderText = `{setting.Max}-`
        else
            placeholderText = ""
        end

        inputSetting.Input.PlaceholderText = placeholderText

        inputSetting.Visible = true
        inputSetting.Parent = settingsOverview

        inputSetting.Input.FocusLost:Connect(function()
            clientServer.UpdateSetting:FireServer(setting.Name, tonumber(inputSetting.Input.Text))
        end)
    else
        local selectionSetting = settingsOverview.SelectionSettingTemplate:Clone()

        selectionSetting.Name = setting.Name
        selectionSetting.Title.Text = setting.Name
        selectionSetting.LayoutOrder = setting.Order

        for i, v in setting.PossibleValues do
            local option = selectionSetting.Options.OptionTemplate:Clone()

            option.Name = v
            option.Text = v
            option.Visible = true
            option.Position = UDim2.fromScale((i-1) / #setting.PossibleValues, 0)
            option.Parent = selectionSetting.Options

            option.Activated:Connect(function()
                PlayClickSound()
                clientServer.UpdateSetting:FireServer(setting.Name, v)
            end)
        end

        selectionSetting.Visible = true
        selectionSetting.Parent = settingsOverview
    end
    setHostSettingsView(setting.Name, setting.Default)
end

ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ServerClient"):WaitForChild("SendNotification").OnClientEvent:Connect(Notification)

serverClient.ToggleUI.OnClientEvent:Connect(function(state: boolean)
    UIManager.WaitForUI("Settings"):ToggleVisible(state)
    UIManager.WaitForUI("Sidebar"):ToggleVisible(state)
    switchView("None")
end)

for _, v in clientServer.GetAllLobbies:InvokeServer() do
    createLobbySlot(v)
end
