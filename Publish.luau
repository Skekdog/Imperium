local fs = require("@lune/fs")
local net = require("@lune/net")
local serde = require("@lune/serde")
local process = require("@lune/process")

local baseUrl = "https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions?versionType=Published"

assert(fs.isFile(".env"), "Missing .env file")
local env = serde.decode("toml", fs.readFile(".env"))

local universe = env.UNIVERSE or error("Missing UNIVERSE in .env")
local targets = env.TARGETS or error("Missing TARGETS in .env")
local apiKey = env.APIKEY or error("Missing APIKEY in .env")

for _, projectName in targets:split(";") do
    assert(fs.isFile(projectName .. ".project.json"), `Missing {projectName}.project.json file`)

    local projectFileName = projectName .. ".project.json"
    local projectFile = fs.readFile(projectFileName)
    local project = serde.decode("json", projectFile)

    local placeId = (project.servePlaceIds or error("Missing servePlaceIds"))[1]

    local outputName = projectName .. ".rbxl"
    local buildResult = process.spawn("rojo", {"build", "--output", outputName, projectFileName})
    assert(buildResult.ok, buildResult.stderr)

    local outputFile = fs.readFile(outputName)

    local response = net.request({
        url = baseUrl:gsub("{universeId}", universe):gsub("{placeId}", placeId),
        method = "POST",
        headers = {
            ["x-api-key"] = apiKey,
            ["Content-Type"] = "application/octet-stream",
        },
        body = outputFile,
    })

    assert(response.ok, `Failed to upload {outputName}: {response.body}`)
    print(`Uploaded {outputName} with version: {serde.decode("json", response.body).versionNumber}`)
end