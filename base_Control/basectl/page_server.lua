-- page_server.lua — BaseControl Pocket: Server Control Page (v0.1.0)
-- Controls the Label Config Server running in background or on mainframe.
-- Shows current version, last broadcast, and allows manual broadcast toggle.

local page = {}

local ui, util

-- State cache
local state = {
  serverStatus = false,
  currentVersion = "-",
  prevVersion = "-",
  lastBroadcast = "never",
}

local function draw()
  util.clear()
  ui.drawHeader("Server Control")
  term.setCursorPos(2,3)
  term.write("Server Status: ")
  term.setTextColor(state.serverStatus and colors.lime or colors.red)
  term.write(state.serverStatus and "ONLINE" or "OFFLINE")
  term.setTextColor(colors.white)

  term.setCursorPos(2,5)
  term.write("Current Config Version: "..state.currentVersion)
  term.setCursorPos(2,6)
  term.write("Previous Version: "..state.prevVersion)
  term.setCursorPos(2,8)
  term.write("Last Broadcast: "..state.lastBroadcast)

  ui.drawFooter("[T] Toggle Server  [B] Broadcast Now  [Q] Back")
end

-- Toggle server on/off (dummy logic for now)
local function toggleServer()
  state.serverStatus = not state.serverStatus
  state.lastBroadcast = textutils.formatTime(os.time(), true)
end

-- Manual broadcast trigger (dummy logic)
local function broadcastNow()
  state.lastBroadcast = textutils.formatTime(os.time(), true)
  util.log("Manual broadcast triggered.")
end

function page.run(ctx)
  ui, util = ctx.ui, ctx.util
  while true do
    draw()
    local ev, key = os.pullEvent("key")
    if key == keys.q then return end
    if key == keys.t then toggleServer() end
    if key == keys.b then broadcastNow() end
  end
end

return page