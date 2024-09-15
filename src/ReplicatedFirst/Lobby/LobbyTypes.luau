export type Map = "Happy Home"
export type Board = "Classic (UK)"
export type Settings = {
    ["Turn Time"]: number,
    ["Auction Time"]: number,
    ["Map"]: string,
    ["Board"]: string,
}

export type Setting = {
    Name: string,
    Default: string | number,
    PossibleValues: {string} | "number",
    Max: number?,
    Min: number?,
}
export type AvailableSettings = {Setting}

export type Lobby = {
    Owner: Player,
    Password: string,
    Players: {Player},
    Settings: Settings,

    Kick: (Lobby, plr: Player) -> (),
    Start: (Lobby) -> (),
    Disband: (Lobby, notification: string?) -> (),

    AddPlayer: (Lobby, plr: Player) -> (),
    RemovePlayer: (Lobby, plr: Player) -> (),

    TryJoin: (Lobby, plr: Player, password: unknown) -> "Success" | string,

    SetSetting: (Lobby, setting: string, value: string | number) -> (),
    GetAllSettings: (Lobby) -> Settings,

    GetClientLobby: (Lobby, to: Player?) -> ClientLobby,
}

export type ClientLobby = {
    Owner: Player,
    Players: {Player},
    Settings: Settings,
    Private: boolean,
    Password: string?,
}

return {}