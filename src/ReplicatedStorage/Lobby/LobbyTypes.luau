local GameConfiguration = require(script.Parent.Parent.Shared.GameConfiguration)
export type Lobby = {
    Owner: Player,
    Password: string,
    Players: {string},
    Settings: GameConfiguration.SerialisedSettings,

    Kick: (Lobby, plr: string) -> (),
    Start: (Lobby) -> (),
    Disband: (Lobby, notification: string?) -> (),

    TryAddBotPlayer: (Lobby) -> "Success" | string,
    AddPlayer: (Lobby, plr: Player) -> (),
    RemovePlayer: (Lobby, plr: string) -> (),

    TryJoin: (Lobby, plr: Player, password: unknown) -> "Success" | string,

    SetSetting: (Lobby, setting: string, value: string | number) -> (),
    GetAllSettings: (Lobby) -> GameConfiguration.SerialisedSettings,

    GetClientLobby: (Lobby, to: Player?) -> ClientLobby,
}

export type ClientLobby = {
    Owner: Player,
    Players: {string},
    Settings: GameConfiguration.SerialisedSettings,
    Private: boolean,
    Password: string?,
}

return nil