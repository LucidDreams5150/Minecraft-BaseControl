-- page_metrics.lua — BaseControl Pocket: Metrics Mapping Page (v0.1.0)
-- Displays and edits metrics mappings for monitors.
-- Example sources: AE2 fluids, Mekanism tanks via Block Reader.
-- Scrollable list with placeholder data.

local page = {}
local ui, util

local function loadMetrics()
  return {
    { monitor = "monitor_21", source = { type="tank_reader", periph="blockReader_3" }, max = 16000000, style = { color="cyan" } },
    { monitor = "monitor_22", source = { type="me_fluid", name="mekanism:steam" }, max = 8000000, style = { color="blue" } },
  }
end

local metrics = loadMetrics()
local scroll = 0
local cursor = 1

local function draw()
  util.clear()
  ui.drawHeader("Metrics Mapping")
  local w,h = term.getSize()
  local listHeight = h - 4

  for i=1,listHeight do
    local idx = i + scroll
    local m = metrics[idx]
    if m then
      term.setCursorPos(2, i+1)
      if idx == cursor then term.write("> ") else term.write("  ") end
      local src = (m.source.type=="tank_reader" and ("Tank:"..m.source.periph)) or ("Fluid:"..m.source.name)
      term.write(string.format("%s | %s | Max:%s", m.monitor, src, util.formatNumber(m.max or 0)))
    end
  end

  ui.drawFooter("[Arrows] Move  [E] Edit  [S] Save  [Q] Back")
end

local function editMetric(m)
  util.clear()
  ui.drawHeader("Edit Metric")
  term.setCursorPos(2,3)
  term.write("Monitor name: ")
  local mon = read()
  term.setCursorPos(2,5)
  term.write("Source type (tank_reader/me_fluid): ")
  local stype = read()
  term.setCursorPos(2,7)
  term.write("Source name/periph: ")
  local sname = read()
  term.setCursorPos(2,9)
  term.write("Max capacity (number): ")
  local max = tonumber(read()) or 0

  m.monitor = mon
  m.source = { type = stype, name = sname, periph = sname }
  m.max = max
end

local function saveMetrics()
  util.log("Metrics config saved (stub). Replace with network push to server.")
end

function page.run(ctx)
  ui, util = ctx.ui, ctx.util
  while true do
    draw()
    local ev, key = os.pullEvent("key")
    if key == keys.q then return end
    if key == keys.down then
      cursor = math.min(#metrics, cursor+1)
      if cursor - scroll > (select(2,term.getSize())-4) then scroll = scroll + 1 end
    elseif key == keys.up then
      cursor = math.max(1, cursor-1)
      if cursor <= scroll then scroll = scroll - 1 end
    elseif key == keys.e then
      editMetric(metrics[cursor])
    elseif key == keys.s then
      saveMetrics()
    end
  end
end

return page
