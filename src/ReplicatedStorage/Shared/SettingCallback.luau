local module = {}

type Callback = (settingName: string, value: any) -> ()
local callbacks: {Callback} = {}

function module.Listen(callback: Callback): ()
    table.insert(callbacks, callback)
end

function module.Fire(settingName: string, value: any): ()
    for _, v in callbacks do
        v(settingName, value)
    end
end

return module