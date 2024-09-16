local GameConfiguration = require(script.Parent.Parent.Shared.GameConfiguration)
export type Lobby = {
    Owner: Player,
    Password: string,
    Players: {Player},
    Settings: GameConfiguration.SerialisedSettings,

    Kick: (Lobby, plr: Player) -> (),
    Start: (Lobby) -> (),
    Disband: (Lobby, notification: string?) -> (),

    AddPlayer: (Lobby, plr: Player) -> (),
    RemovePlayer: (Lobby, plr: Player) -> (),

    TryJoin: (Lobby, plr: Player, password: unknown) -> "Success" | string,

    SetSetting: (Lobby, setting: string, value: string | number) -> (),
    GetAllSettings: (Lobby) -> GameConfiguration.SerialisedSettings,

    GetClientLobby: (Lobby, to: Player?) -> ClientLobby,
}

export type ClientLobby = {
    Owner: Player,
    Players: {Player},
    Settings: GameConfiguration.SerialisedSettings,
    Private: boolean,
    Password: string?,
}

return {}