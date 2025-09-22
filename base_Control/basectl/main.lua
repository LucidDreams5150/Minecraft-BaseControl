-- main.lua — BaseControl Pocket Core (v0.1.0)
-- Entry point for Pocket Computer control system.
-- Lazy-loads pages and services to keep memory light.
--
-- Provides navigation between pages:
--   * Server (config server control)
--   * Labels (edit monitor labels & metrics)
--   * Metrics (mapping of metrics sources)
--   * Updates (manifest update checks)
--   * Utils (stats, debug)
--
-- This is a stub; fill in page drawing logic as pages are built.

local ui = dofile("/base_Control/basectl/ui.lua")
local util = dofile("/base_Control/basectl/util.lua")

local pages = {
  { key="server",  title="Server",  file="/base_Control/basectl/page_server.lua" },
  { key="labels",  title="Labels",  file="/base_Control/basectl/page_labels.lua" },
  { key="metrics", title="Metrics", file="/base_Control/basectl/page_metrics.lua" },
  { key="updates", title="Updates", file="/base_Control/basectl/page_updates.lua" },
  { key="utils",   title="Utils",   file="/base_Control/basectl/page_utils.lua" },
}

local function drawMenu(selected)
  util.clear()
  ui.drawHeader("BaseControl Pocket v0.1.0")
  for i,p in ipairs(pages) do
    term.setCursorPos(2, 2+i)
    if i==selected then term.write("> "..p.title) else term.write("  "..p.title) end
  end
end

local function runPage(page)
  util.clear()
  local mod = dofile(page.file)
  if mod and mod.run then
    mod.run({ui=ui,util=util})
  else
    term.setCursorPos(2,3)
    print("Page missing: "..page.file)
    sleep(2)
  end
end

local selected = 1
while true do
  drawMenu(selected)
  local ev, key = os.pullEvent("key")
  if key == keys.down then selected = math.min(#pages, selected+1) end
  if key == keys.up then selected = math.max(1, selected-1) end
  if key == keys.enter then runPage(pages[selected]) end
end