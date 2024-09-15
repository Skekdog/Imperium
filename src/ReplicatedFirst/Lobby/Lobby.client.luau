local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LobbyTypes = require(script.Parent.LobbyTypes)
local Notification = require(script.Parent.Parent.Shared.Notification)
local GetPlayerName = require(script.Parent.Parent.Shared.GetPlayerName)
local UIManager = require(script.Parent.Parent.Shared.UIManager)

local serverClient = ReplicatedStorage.Lobby.ServerClient
local clientServer = ReplicatedStorage.Lobby.ClientServer

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

local function updateSetting(slot: LobbySlot, setting: string, value: string | number): ()
    local element = slot.Configuration:FindFirstChild(setting) :: typeof(slot.Configuration.SettingTemplate)?
    if not element then
        element = slot.Configuration.SettingTemplate:Clone()
    end
    assert(element)

    element.Title.Text = setting
    element.Value.Text = tostring(value)
    element.Visible = true
    element.Name = setting
    element.Parent = slot.Configuration
end

local function createLobbySlot(lobby: LobbyTypes.ClientLobby): ()
    local id = lobby.Owner.UserId

    local slot: LobbySlot
    local parent: Instance
    if lobby.Owner == Players.LocalPlayer then
        slot = hostView.LobbyOverview :: any
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

    slot.LobbyName.Text = `{GetPlayerName(lobby.Owner)}'s Lobby`

    lobbies[id] = slot

    slot.Parent = parent :: any

    if lobby.Owner ~= Players.LocalPlayer then
        slot.Join.Activated:Connect(function()
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

local function switchView(view: "Browser" | "HostView"): ()
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

serverClient.LobbyAdded.OnClientEvent:Connect(createLobbySlot)
serverClient.LobbyRemoved.OnClientEvent:Connect(removeLobbySlot)
serverClient.PlayerAdded.OnClientEvent:Connect(addPlayerToLobby)
serverClient.PlayerRemoved.OnClientEvent:Connect(removePlayerFromLobby)
serverClient.SettingUpdated.OnClientEvent:Connect(updateSetting)

ui.Object.Create.TextButton.Activated:Connect(function()
    clientServer.CreateLobby:FireServer(ui.Object.Create.Password.Text)
    switchView("HostView")
end)

hostView.Start.Activated:Connect(function()
    clientServer.StartLobby:FireServer()
end)

local settings: LobbyTypes.AvailableSettings = clientServer.GetAvailableSettings:InvokeServer()
for setting: string, value: {string} | number in settings :: any do
    if typeof(value) == "number" then
        local inputElement = hostView.Settings.InputSettingTemplate:Clone()
        inputElement.Title.Text = setting
        inputElement.Input.Text = tostring(value)
        inputElement.Parent = hostView.Settings

        inputElement.Input.FocusLost:Connect(function()
            clientServer.UpdateSetting:FireServer(setting, inputElement.Input.Text)
        end)
    elseif typeof(value) == "table" then
        local selectElement = hostView.Settings.SelectionSettingTemplate:Clone()
        selectElement.Title.Text = setting
    end
end

ReplicatedStorage.Shared.ServerClient.SendNotification.OnClientEvent:Connect(Notification)

for _, v in clientServer.GetAllLobbies:InvokeServer() do
    createLobbySlot(v)
end
