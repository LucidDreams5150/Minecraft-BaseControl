-- install_client.lua — BaseControl Installer for Label Clients (v0.1.0)
-- Downloads and installs only the client files needed for remote monitors.
-- Run on a computer connected to monitors + modem.

local REPO_URL = "https://raw.githubusercontent.com/LucidDreams5150/Minecraft-BaseControl/main/base_Control"
local FILES = {
  "clients/labelClient.lua",
}

local function fetch(url)
  local h = http.get(url)
  if not h then error("Failed to fetch: "..url) end
  local data = h.readAll()
  h.close()
  return data
end

local function install()
  print("Installing Label Client...")
  for _,path in ipairs(FILES) do
    local fullUrl = REPO_URL.."/"..path
    print("Downloading "..path)
    local data = fetch(fullUrl)
    local fh = fs.open(path, "w")
    fh.write(data)
    fh.close()
  end
  print("Done! Run with: shell.run('clients/labelClient.lua')")
end

install()