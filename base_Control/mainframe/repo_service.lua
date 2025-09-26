-- repo_service.lua — resilient Mainframe Repo Service (v0.1.1)
-- Serves manifest + files over rednet (protocol: "pkg_repo") and stays running.

local PROTOCOL = "pkg_repo"
local MANIFEST = "/manifest.json"

-- Simple logger to avoid external deps
local function log(msg)
  local t = textutils.formatTime(os.time(), true)
  print(("[%s] %s"):format(t, tostring(msg)))
end

local function openAllModems()
  for _,n in ipairs(peripheral.getNames()) do
    if peripheral.getType(n)=="modem" and not rednet.isOpen(n) then
      rednet.open(n)
    end
  end
end

local function ensureManifest()
  if fs.exists(MANIFEST) then return end
  local fh = fs.open(MANIFEST, "w")
  fh.write('{"schema":2,"version":"0.0.0","files":{}}')
  fh.close()
  log("Created placeholder "..MANIFEST)
end

local function loadManifest()
  local fh = fs.open(MANIFEST, "r")
  if not fh then return {schema=2, version="0.0.0", files={}} end
  local s = fh.readAll(); fh.close()
  local ok, data = pcall(textutils.unserializeJSON, s)
  if ok and type(data)=="table" then return data end
  return {schema=2, version="0.0.0", files={}}
end

local function handleRequest(sender, msg, manifest)
  if msg.cmd == "getManifest" then
    rednet.send(sender, { ok=true, manifest=manifest }, PROTOCOL)
    return
  end
  if msg.cmd == "getFile" and type(msg.path)=="string" then
    if fs.exists(msg.path) then
      local fh = fs.open(msg.path, "r")
      local data = fh.readAll(); fh.close()
      rednet.send(sender, { ok=true, path=msg.path, data=data }, PROTOCOL)
    else
      rednet.send(sender, { ok=false, error="File not found: "..msg.path }, PROTOCOL)
    end
    return
  end
  rednet.send(sender, { ok=false, error="Unknown command" }, PROTOCOL)
end

local function main()
  openAllModems()
  rednet.host(PROTOCOL, "repo-mainframe") -- gives you lookup by name
  ensureManifest()
  local manifest = loadManifest()
  log("Repo Service started. Version: "..(manifest.version or "?"))

  while true do
    local id, msg = rednet.receive(PROTOCOL)
    local ok, err = pcall(function()
      if type(msg) == "table" then
        -- Reload manifest each request so you can update it on disk without restart
        manifest = loadManifest()
        handleRequest(id, msg, manifest)
      end
    end)
    if not ok then log("Error handling request: "..tostring(err)) end
  end
end

local ok, err = pcall(main)
if not ok then log("Fatal: "..tostring(err)) end
