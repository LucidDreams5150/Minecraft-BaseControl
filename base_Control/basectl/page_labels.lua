-- page_labels.lua — BaseControl Pocket: Labels Management Page (v0.1.0)
-- Displays and edits monitor label configuration, including text scale and padding.
-- Scrollable list for many monitors.

local page = {}
local ui, util

-- Dummy config loader (replace with config server fetch)
local function loadConfig()
  return {
    monitors = {
      { name = "monitor_1", label = "Iron Ingot", text_scale = 1, pad_x = 0, pad_y = 0 },
      { name = "monitor_2", label = "Gold Ingot", text_scale = 1, pad_x = 0, pad_y = 0 },
      { name = "monitor_3", label = "Diamond", text_scale = 1, pad_x = 0, pad_y = 0 },
      { name = "monitor_4", label = "Emerald", text_scale = 1, pad_x = 0, pad_y = 0 },
      { name = "monitor_5", label = "Netherite", text_scale = 1, pad_x = 0, pad_y = 0 },
    }
  }
end

local cfg = loadConfig()
local scroll = 0
local cursor = 1

local function draw()
  util.clear()
  ui.drawHeader("Labels Config")

  local w,h = term.getSize()
  local listHeight = h - 4 -- minus header/footer

  for i=1,listHeight do
    local idx = i + scroll
    local m = cfg.monitors[idx]
    if m then
      term.setCursorPos(2, i+1)
      if idx == cursor then term.write("> ") else term.write("  ") end
      term.write(string.format("%s | %s | Scale:%0.1f | X:%d Y:%d", m.name, m.label, m.text_scale, m.pad_x, m.pad_y))
    end
  end

  ui.drawFooter("[Arrows] Move  [E] Edit  [S] Save  [Q] Back")
end

local function editField(monitor)
  util.clear()
  ui.drawHeader("Edit: "..monitor.name)
  term.setCursorPos(2,3)
  term.write("Label: ")
  local label = read()
  term.setCursorPos(2,5)
  term.write("Text Scale (0.5-5): ")
  local scale = tonumber(read()) or 1
  term.setCursorPos(2,7)
  term.write("Padding X: ")
  local pad_x = tonumber(read()) or 0
  term.setCursorPos(2,9)
  term.write("Padding Y: ")
  local pad_y = tonumber(read()) or 0

  monitor.label = label
  monitor.text_scale = math.max(0.5, math.min(5, scale))
  monitor.pad_x = pad_x
  monitor.pad_y = pad_y
end

local function saveConfig()
  util.log("Config saved (stub). Replace with network push to server.")
end

function page.run(ctx)
  ui, util = ctx.ui, ctx.util
  while true do
    draw()
    local ev, key = os.pullEvent("key")
    if key == keys.q then return end
    if key == keys.down then
      cursor = math.min(#cfg.monitors, cursor+1)
      if cursor - scroll > (select(2,term.getSize())-4) then scroll = scroll + 1 end
    elseif key == keys.up then
      cursor = math.max(1, cursor-1)
      if cursor <= scroll then scroll = scroll - 1 end
    elseif key == keys.e then
      editField(cfg.monitors[cursor])
    elseif key == keys.s then
      saveConfig()
    end
  end
end

return page