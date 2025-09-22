-- page_utils.lua — BaseControl Pocket: Utilities & Debug Page (v0.1.0)
-- Displays runtime stats, memory usage, and debug tools.

local page = {}
local ui, util

local function getStats()
  return {
    uptime = os.clock(),
    id = os.getComputerID(),
    label = os.getComputerLabel() or "(none)",
    freeMemory = collectgarbage("count"),
  }
end

local function draw()
  util.clear()
  ui.drawHeader("Utilities & Debug")

  local stats = getStats()
  term.setCursorPos(2,3)
  term.write("Computer ID: "..stats.id)
  term.setCursorPos(2,4)
  term.write("Label: "..stats.label)
  term.setCursorPos(2,5)
  term.write(string.format("Uptime: %.1f sec", stats.uptime))
  term.setCursorPos(2,6)
  term.write(string.format("Free Memory: %.1f KB", stats.freeMemory))

  ui.drawFooter("[G] GC Collect  [Q] Back")
end

local function collectMemory()
  util.log("Running garbage collection...")
  collectgarbage()
end

function page.run(ctx)
  ui, util = ctx.ui, ctx.util
  while true do
    draw()
    local ev, key = os.pullEvent("key")
    if key == keys.q then return end
    if key == keys.g then collectMemory() end
  end
end

return page