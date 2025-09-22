-- page_updates.lua — BaseControl Pocket: Update Management Page (v0.1.0)
-- Checks manifest.json from GitHub and compares to local version.
-- Provides manual update check and install triggers.

local page = {}
local ui, util

-- Placeholder manifest data (replace with network fetch)
local manifest = {
  version = "0.1.0",
  files = {
    { path = "clients/labelClient.lua", version = "v0.7.0" },
    { path = "basectl/main.lua", version = "v0.1.0" },
  }
}

local function fetchManifest()
  util.log("Fetching manifest.json (stub)")
  return manifest
end

local function checkUpdates()
  -- Compare with local versions (stubbed)
  return {
    updates = {
      { path = "clients/labelClient.lua", current = "v0.6.0", latest = "v0.7.0" },
    }
  }
end

local function draw(updates)
  util.clear()
  ui.drawHeader("Updates")
  term.setCursorPos(2,3)
  term.write("Manifest version: "..manifest.version)
  term.setCursorPos(2,5)
  if #updates.updates == 0 then
    term.write("All files up-to-date.")
  else
    term.write("Updates available:")
    for i,u in ipairs(updates.updates) do
      term.setCursorPos(4,6+i)
      term.write(string.format("%s  (%s -> %s)", u.path, u.current, u.latest))
    end
  end
  ui.drawFooter("[C] Check Updates  [I] Install  [Q] Back")
end

function page.run(ctx)
  ui, util = ctx.ui, ctx.util
  local updates = { updates = {} }
  while true do
    draw(updates)
    local ev, key = os.pullEvent("key")
    if key == keys.q then return end
    if key == keys.c then updates = checkUpdates() end
    if key == keys.i then util.log("Installing updates (stub)") end
  end
end

return page
