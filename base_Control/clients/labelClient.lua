-- labelClient.lua — unified Labels + Metrics client (v0.7.0)
-- Works with your existing labels config server and adds per-monitor metrics rendering.
-- Metrics sources supported:
--   - me_fluid: read fluid totals from AE2 (Advanced Peripherals meBridge)
--   - tank_reader: read Mekanism Dynamic Tank fill via AP Block Reader
--
-- It prefers service modules if present:
--   /base_Control/services/ae2_service.lua
--   /base_Control/services/tank_service.lua
-- else it falls back to a minimal direct peripheral access.
--
-- Perf design:
--   * Single event loop
--   * Diff-draw for labels & metrics
--   * 5s metrics cadence (configurable per metric later)
--   * Debounced redraw on config change
--
local CLIENT_VER = "v0.7.0"
local PROTO      = "labels_cfg"     -- config protocol (same as server)
local HOST_NAME  = "labels-hub"     -- server host name

-- === utils ===
local function openAllModems()
  for _,n in ipairs(peripheral.getNames()) do
    if peripheral.getType(n)=="modem" and not rednet.isOpen(n) then rednet.open(n) end
  end
end

-- compat: pullEventTimeout for older CC:Tweaked
local function pullEventTimeoutCompat(sec)
  if os.pullEventTimeout then
    return os.pullEventTimeout(sec)
  end
  local timer = os.startTimer(sec or 0)
  while true do
    local ev,a,b,c,d = os.pullEvent()
    if ev == "timer" then
      if a == timer then return nil end        -- timed out
      -- else: some other timer; ignore and keep waiting
    else
      return ev,a,b,c,d                        -- got a real event
    end
  end
end


local COLORS = { white=colors.white, orange=colors.orange, magenta=colors.magenta, lightblue=colors.lightBlue,
  yellow=colors.yellow, lime=colors.lime, pink=colors.pink, gray=colors.gray, lightgray=colors.lightGray,
  cyan=colors.cyan, purple=colors.purple, blue=colors.blue, brown=colors.brown, green=colors.green,
  red=colors.red, black=colors.black }
local function toColor(name)
  return COLORS[(name or ""):lower()] or colors.white
end

local function splitLines(s)
  local t={} ; for line in tostring(s):gmatch("([^\n]*)\n?") do t[#t+1]=line end ; return t
end

local function wrapText(s, width)
  if width<=0 then return {s} end
  local out = {}
  for word in s:gmatch("%S+") do
    local last = out[#out] or ""
    if last=="" then out[#out+1]=word
    elseif #last + 1 + #word <= width then out[#out] = last.." "..word
    else out[#out+1]=word end
  end
  if #out==0 then out={""} end
  return out
end

local function alignLine(line, w, align, pad_x)
  pad_x = tonumber(pad_x or 0) or 0
  align = align or "center"
  local len = #line
  if align=="left" then
    local s = line .. string.rep(" ", math.max(0, w-len))
    if pad_x>0 then s = string.rep(" ", math.min(pad_x, w)) .. s end
    return s:sub(1,w)
  elseif align=="right" then
    local s = string.rep(" ", math.max(0, w-len)) .. line
    if pad_x>0 then s = s .. string.rep(" ", math.min(pad_x, w)) end
    return s:sub(1,w)
  else -- center
    local left = math.floor((w-len)/2)
    if pad_x>0 then left = math.max(0, left - pad_x) end
    local s = string.rep(" ", math.max(0,left)) .. line
    return s:sub(1,w)
  end
end

-- === config fetch ===
local function fetchConfig()
  local host = rednet.lookup(PROTO, HOST_NAME)
  if not host then return nil, "No config host (labels-hub)" end
  rednet.send(host, {cmd="get"}, PROTO)
  local _, msg = rednet.receive(PROTO, 3)
  if type(msg)=="table" and msg.ok and type(msg.config)=="table" then return msg.config end
  return nil, "No config reply"
end

-- === monitor discovery ===
local function discoverMonitors()
  local list = {}
  for _,n in ipairs(peripheral.getNames()) do
    if peripheral.getType(n)=="monitor" then list[#list+1] = { name=n, mon=peripheral.wrap(n) } end
  end
  return list
end

-- === LABELS rendering ===
local lastLabel = {}   -- keyed by monitor name

local function drawLabel(mon, entry, defaults)
  local w,h = mon.getSize()
  local label = entry.label
  if (not label or label=="") and defaults and defaults.default_label_template then
    local nn = entry.name or "" ; local num = nn:match("(%d+)") or "?"
    label = (defaults.default_label_template:gsub("%$n", num):gsub("%$name", nn):gsub("%$client", os.getComputerLabel() or ("#"..os.getComputerID())))
  end
  label = label or ""

  local text_scale = entry.text_scale or defaults.text_scale
  if text_scale then mon.setTextScale(math.max(0.5, math.min(5, text_scale))) end
  local ww,hh = mon.getSize()

  local fg = toColor(entry.fg or (defaults and defaults.fg))
  local bg = toColor(entry.bg or (defaults and defaults.bg))

  local key = entry.name or tostring(mon)
  local prev = lastLabel[key] or {}
  if prev.label==label and prev.fg==fg and prev.bg==bg and prev.w==ww and prev.h==hh then
    return -- no changes
  end
  lastLabel[key] = { label=label, fg=fg, bg=bg, w=ww, h=hh }

  mon.setBackgroundColor(bg); mon.setTextColor(fg); mon.clear()

  local wrapW = ww - 2*(entry.pad_x or (defaults and defaults.pad_x or 0))
  local lines = wrapText(label, math.max(1, wrapW))
  local align = entry.align or (defaults and defaults.align) or "center"
  local pad_y = entry.pad_y or (defaults and defaults.pad_y or 0)
  local startY
  if (defaults and defaults.center_vert) or entry.center_vert then
    startY = math.max(1, math.floor(hh/2 - #lines/2))
  else
    startY = 1 + pad_y
  end
  for i=1, math.min(#lines, hh) do
    local s = alignLine(lines[i], ww, align, entry.pad_x or (defaults and defaults.pad_x))
    mon.setCursorPos(1, startY + i - 1)
    mon.write(s)
  end
end

-- === METRICS (services + draw) ===
local ae2_svc, tank_svc
local function ae2_probe()
  if not ae2_svc then
    pcall(function() ae2_svc = dofile("/base_Control/services/ae2_service.lua") end)
  end
  if ae2_svc and ae2_svc.probe then return ae2_svc.probe() end
  -- fallback: direct peripheral
  return peripheral.find and (peripheral.find("meBridge") ~= nil) or false
end
local function ae2_stockFluid(name)
  if ae2_svc and ae2_svc.stockFluid then return ae2_svc.stockFluid(name) end
  local br = peripheral.find and peripheral.find("meBridge")
  if not br then return { amount=0, displayName=name } end
  local fs = br.listFluids()
  for _,f in ipairs(fs or {}) do if f.name==name then return { amount=f.amount, displayName=f.displayName or name } end end
  return { amount=0, displayName=name }
end
local function tank_read(periph)
  if not tank_svc then pcall(function() tank_svc = dofile("/base_Control/services/tank_service.lua") end) end
  if tank_svc and tank_svc.read then return tank_svc.read(periph) end
  if peripheral.isPresent(periph) and peripheral.getType(periph)=="blockReader" then
    local br = peripheral.wrap(periph)
    local t = br and br.getBlockData() or {}
    local f = t.stored or t.storedFluid or (t.tank and t.tank.fluid)
    local name, amt, cap
    if f then
      name = f.name or (f.resource and f.resource.name) or f.fluid or f.id
      amt  = f.amount or f.amount_mb or f.level or f.stored or 0
    end
    cap = t.capacity or (t.tank and (t.tank.capacity or t.tank.capacity_mb)) or t.max or 0
    if not name and t.displayName then name=t.displayName end
    return { name = name or "(unknown)", amount = tonumber(amt) or 0, capacity = tonumber(cap) or 0 }
  end
  return { name=periph or "(unknown)", amount=0, capacity=0 }
end

local lastMetric = {}
local function drawMetric(mon, m, val)
  local w,h = mon.getSize()
  local cap = (val.capacity and val.capacity>0) and val.capacity or (m.max or 0)
  local pct = (cap>0) and (val.amount/cap) or 0
  local key = m.monitor
  local prev = lastMetric[key] or {}
  if prev.amount==val.amount and prev.cap==cap and prev.name==val.name and prev.w==w and prev.h==h then return end
  lastMetric[key] = { amount=val.amount, cap=cap, name=val.name, w=w, h=h }

  mon.setTextScale(m.text_scale or 1)
  mon.setBackgroundColor(toColor(m.bg or "black"))
  mon.setTextColor(toColor(m.fg or "white"))
  mon.clear()
  local title = (val.name or m.source.name or "(unknown)"):gsub("^%l", string.upper)
  local function center(y, s)
    local x = math.max(1, math.floor((w-#s)/2))
    mon.setCursorPos(x, y); mon.write(s)
  end
  center(1, title)
  center(3, string.format("%s / %s", tostring(val.amount), tostring(cap>0 and cap or "?")))
  center(4, string.format("%d%%", math.floor(pct*100)))
  -- vertical bar at right
  local fill = math.floor((h-2) * pct + 0.5)
  for y=1,h-2 do
    mon.setCursorPos(w-1, h-1-y)
    mon.setBackgroundColor((y<=fill) and toColor((m.style and m.style.color) or "cyan") or colors.gray)
    mon.write(" ")
  end
end

local function resolveMetric(m)
  if not (m and m.source and m.monitor) then return nil end
  if m.source.type=="me_fluid" then
    if not ae2_probe() then return { name=m.source.name, amount=0, capacity=m.max or 0 } end
    local r = ae2_stockFluid(m.source.name)
    return { name=r.displayName or m.source.name, amount=r.amount or 0, capacity=m.max or 0 }
  elseif m.source.type=="tank_reader" then
    local r = tank_read(m.source.periph)
    return r
  end
  return { name="(unknown)", amount=0, capacity=0 }
end

-- === main ===
openAllModems()

local cfg = nil
local monitors = discoverMonitors()
local nextCfgPoll = 0
local nextMetricsTick = 0
local redrawNeeded = true

print("Label+Metrics Client "..CLIENT_VER.." starting…")

while true do
  local now = os.clock()
  if now >= nextCfgPoll then
    local c = select(1, fetchConfig())
    if c then cfg=c; redrawNeeded=true end
    nextCfgPoll = now + 10 -- re-poll config mapping every 10s
  end

  if redrawNeeded and cfg then
    -- Draw labels first
    local defaults = cfg.defaults or { fg="white", bg="black", align="center", pad_x=0, pad_y=0, center_vert=true }
    -- explicit monitors
    if type(cfg.monitors)=="table" then
      for _,m in ipairs(cfg.monitors) do
        local mon = peripheral.wrap(m.name or "")
        if mon and peripheral.getType(peripheral.getName(mon))=="monitor" then
          drawLabel(mon, m, defaults)
        end
      end
    end
    -- autodiscover
    if defaults.autodiscover then
      for _,it in ipairs(monitors) do
        local isExplicit=false
        if type(cfg.monitors)=="table" then
          for _,m in ipairs(cfg.monitors) do if m.name==it.name then isExplicit=true break end end
        end
        if not isExplicit then
          drawLabel(it.mon, { name=it.name }, defaults)
        end
      end
    end
    redrawNeeded=false
  end

  -- Metrics tick (5s)
  if cfg and type(cfg.metrics)=="table" and now >= nextMetricsTick then
    for _,m in ipairs(cfg.metrics) do
      local mon = peripheral.wrap(m.monitor or "")
      if mon and peripheral.getType(peripheral.getName(mon))=="monitor" then
        local val = resolveMetric(m)
        if val then drawMetric(mon, m, val) end
      end
    end
    nextMetricsTick = now + 5
  end

  -- Event handling
  local ev, a, b, c, d = pullEventTimeoutCompat(2)
  if ev=="rednet_message" then
    local _, msg = a, b
    if type(msg)=="table" and msg.cmd=="changed" then
      redrawNeeded=true
      nextMetricsTick = 0 -- refresh metrics ASAP too
    end
  elseif ev=="monitor_resize" then
    redrawNeeded=true
    nextMetricsTick = 0
  end
end
