-- ui.lua — BaseControl shared UI helpers (v0.1.0)
-- Provides consistent header, footer, and widgets for Pocket and Mainframe apps.

local ui = {}

-- Colors
ui.colors = {
  header_bg = colors.purple,
  header_fg = colors.white,
  footer_bg = colors.gray,
  footer_fg = colors.white,
}

-- Clear the screen
function ui.clear(bg)
  term.setBackgroundColor(bg or colors.black)
  term.setTextColor(colors.white)
  term.clear()
  term.setCursorPos(1,1)
end

-- Draws a header bar at top with title
function ui.drawHeader(title)
  local w, _ = term.getSize()
  term.setBackgroundColor(ui.colors.header_bg)
  term.setTextColor(ui.colors.header_fg)
  term.setCursorPos(1,1)
  term.clearLine()
  local x = math.max(1, math.floor((w - #title) / 2))
  term.setCursorPos(x,1)
  term.write(title)
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
end

-- Draw footer message (e.g., controls)
function ui.drawFooter(msg)
  local w,h = term.getSize()
  term.setBackgroundColor(ui.colors.footer_bg)
  term.setTextColor(ui.colors.footer_fg)
  term.setCursorPos(1,h)
  term.clearLine()
  local x = math.max(1, math.floor((w - #msg) / 2))
  term.setCursorPos(x,h)
  term.write(msg)
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
end

-- Centered text at given Y
function ui.centerText(y, text, color)
  local w,_ = term.getSize()
  local x = math.max(1, math.floor((w - #text) / 2))
  term.setCursorPos(x, y)
  if color then term.setTextColor(color) end
  term.write(text)
  term.setTextColor(colors.white)
end

return ui