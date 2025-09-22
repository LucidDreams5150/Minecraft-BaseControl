-- util.lua — BaseControl shared utilities (v0.1.0)
-- General helpers for screen control, timers, network, and logging.

local util = {}

-- Clear terminal
function util.clear(bg)
  term.setBackgroundColor(bg or colors.black)
  term.setTextColor(colors.white)
  term.clear()
  term.setCursorPos(1,1)
end

-- Wait for keypress
function util.waitForKey(keysTable)
  while true do
    local ev, key = os.pullEvent("key")
    for _,k in ipairs(keysTable) do
      if key == k then return k end
    end
  end
end

-- Open all attached modems
function util.openAllModems()
  for _,n in ipairs(peripheral.getNames()) do
    if peripheral.getType(n)=="modem" and not rednet.isOpen(n) then
      rednet.open(n)
    end
  end
end

-- Draw centered message block
function util.centerMessage(lines)
  local w,h = term.getSize()
  local startY = math.floor((h - #lines) / 2)
  for i,line in ipairs(lines) do
    local x = math.max(1, math.floor((w - #line) / 2))
    term.setCursorPos(x, startY + i)
    term.write(line)
  end
end

-- Simple logger (prints with timestamp)
function util.log(msg)
  local t = textutils.formatTime(os.time(), true)
  print(string.format("[%s] %s", t, tostring(msg)))
end

-- Format large numbers with commas
function util.formatNumber(num)
  local formatted = tostring(math.floor(num))
  local k
  while true do
    formatted, k = formatted:gsub("^(%d+)(%d%d%d)", '%1,%2')
    if k == 0 then break end
  end
  return formatted
end

-- Sleep while still handling events (non-blocking)
function util.sleepWithEvents(sec)
  local deadline = os.clock() + sec
  while os.clock() < deadline do
    os.pullEvent("timer")
  end
end

return util