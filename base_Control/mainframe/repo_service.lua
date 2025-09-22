-- repo_service.lua — BaseControl Mainframe Repo Service (v0.1.0)
-- Provides file distribution and versioning to Pocket and Client computers.
-- Serves files listed in manifest.json to network via rednet.

local service = {}
local util = dofile("/base_Control/basectl/util.lua")

local PROTOCOL = "pkg_repo"
local manifestPath = "/manifest.json"

local manifest

-- Load manifest.json from disk
local function loadManifest()
  if not fs.exists(manifestPath) then
    util.log("manifest.json not found!")
    return { version = "0.0.0", files = {} }
  end
  local fh = fs.open(manifestPath, "r")
  local data = textutils.unserializeJSON(fh.readAll())
  fh.close()
  return data or { version = "0.0.0", files = {} }
end

-- Handle incoming network requests
local function handleRequest(sender, msg)
  if msg.cmd == "getManifest" then
    rednet.send(sender, { ok = true, manifest = manifest }, PROTOCOL)
  elseif msg.cmd == "getFile" and msg.path then
    if fs.exists(msg.path) then
      local fh = fs.open(msg.path, "r")
      local data = fh.readAll()
      fh.close()
      rednet.send(sender, { ok = true, path = msg.path, data = data }, PROTOCOL)
    else
      rednet.send(sender, { ok = false, error = "File not found: "..msg.path }, PROTOCOL)
    end
  else
    rednet.send(sender, { ok = false, error = "Unknown command" }, PROTOCOL)
  end
end

function service.run()
  util.openAllModems()
  manifest = loadManifest()
  util.log("Repo Service started. Version: "..manifest.version)

  while true do
    local id, msg = rednet.receive(PROTOCOL)
    if type(msg) == "table" then
      handleRequest(id, msg)
    end
  end
end

return service