-- labels_config_server.lua — Labels & Metrics Config Hub (v1.0.0)
-- Hosts a simple config service for label clients & Pocket UI.
-- Protocol: "labels_cfg"; Hostname: "labels-hub"
-- Commands:
--   {cmd="get"}           -> {ok=true, version=N, prev=M, config=table}
--   {cmd="put", config=T} -> {ok=true, version=N}  (saves + broadcasts)
--   {cmd="version"}       -> {ok=true, version=N, prev=M}
-- Broadcast on save: {cmd="changed", version=N, prev=M}
--
-- Storage format: writes /labels_config.lua as `return <table>` (Lua) for readability.
-- Also accepts JSON if sent (we auto-detect strings that look like JSON and parse).
-- Compatible with older setups that used a plain Lua `return { ... }` file.

local PROTO, HOST, PATH = "labels_cfg", "labels-hub", "/labels_config.lua"
local version, prevVersion = 0, 0

-- =============== helpers ===============
local function openAllModems()
  for _,n in ipairs(peripheral.getNames()) do
    if peripheral.getType(n)=="modem" and not rednet.isOpen(n) then rednet.open(n) end
  end
end

local function defaultConfig()
  return {
    defaults = {
      bg = "gray", fg = "purple", align = "center", pad_x = 0, pad_y = 0,
      autodiscover = true, default_label_template = "Monitor $n", center_vert = true,
    },
    monitors = {},
    metrics = {},
  }
end

local function serializeLua(tbl)
  -- writes `return <serialized>` so users can edit by hand
  return "return " .. textutils.serialize(tbl)
end

local function readAll(p)
  if not fs.exists(p) then return nil end
  local fh = fs.open(p, "r")
  local s = fh.readAll()
  fh.close()
  return s
end

local function writeAll(p, s)
  local fh = fs.open(p, "w")
  fh.write(s)
  fh.close()
end

local function tryParseJSON(s)
  if type(s)~="string" then return nil end
  -- very light heuristic: must start with { or [ and contain a colon or bracket
  local c = s:match("^%s*([%[%{])")
  if not c then return nil end
  local ok, t = pcall(textutils.unserializeJSON, s)
  return ok and t or nil
end

local function loadConfig()
  -- try Lua `return {}` first
  if fs.exists(PATH) then
    -- First try to treat file as Lua source that returns a table
    local ok, res = pcall(dofile, PATH)
    if ok and type(res)=="table" then return res end

    -- Else try to parse as serialized/string (legacy or manual edits)
    local raw = readAll(PATH)
    if raw then
      -- attempt to exec `return ...` content
      local f = loadstring(raw)
      if f then
        local ok2, res2 = pcall(f)
        if ok2 and type(res2)=="table" then return res2 end
      end
      -- last chance: JSON
      local j = tryParseJSON(raw)
      if type(j)=="table" then return j end
    end
  end
  return defaultConfig()
end

local function saveConfig(cfg)
  -- always write in Lua form so users can hand-edit easily
  writeAll(PATH, serializeLua(cfg))
end

local function bump()
  prevVersion, version = version, (version + 1)
  rednet.broadcast({cmd="changed", version=version, prev=prevVersion}, PROTO)
end

-- =============== server ===============
local function serve()
  openAllModems()
  rednet.host(PROTO, HOST)
  print(("labels_config_server online as %s / %s"):format(HOST, PROTO))

  while true do
    local id, msg = rednet.receive(PROTO)
    if type(msg) ~= "table" then goto continue end

    if msg.cmd == "get" then
      local cfg = loadConfig()
      rednet.send(id, { ok=true, version=version, prev=prevVersion, config=cfg }, PROTO)

    elseif msg.cmd == "put" then
      local cfg = msg.config
      -- Allow sending config as table OR JSON string
      if type(cfg)=="string" then cfg = tryParseJSON(cfg) or cfg end
      if type(cfg)~="table" then
        rednet.send(id, { ok=false, err="bad_config" }, PROTO)
      else
        saveConfig(cfg); bump()
        rednet.send(id, { ok=true, version=version }, PROTO)
      end

    elseif msg.cmd == "version" then
      rednet.send(id, { ok=true, version=version, prev=prevVersion }, PROTO)

    else
      rednet.send(id, { ok=false, err="unknown_cmd" }, PROTO)
    end

    ::continue::
  end
end

serve()
