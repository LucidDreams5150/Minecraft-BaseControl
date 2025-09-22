-- install_mainframe.lua — BaseControl Installer for Mainframe (v0.1.0)
-- Sets up a mainframe computer to serve as a network repository and config host.

local REPO_URL = "https://raw.githubusercontent.com/LucidDreams5150/Minecraft-BaseControl/main/base_Control"
local FILES = {
  "mainframe/repo_service.lua",
  "basectl/util.lua", -- reuse utils for logging
}

local function fetch(url)
  local h = http.get(url)
  if not h then error("Failed to fetch: "..url) end
  local data = h.readAll()
  h.close()
  return data
end

local function ensureDirs()
  local dirs = {"mainframe","basectl"}
  for _,d in ipairs(dirs) do
    if not fs.exists(d) then fs.makeDir(d) end
  end
end

local function install()
  ensureDirs()
  print("Installing BaseControl Mainframe...")
  for _,path in ipairs(FILES) do
    local fullUrl = REPO_URL.."/"..path
    print("Downloading "..path)
    local data = fetch(fullUrl)
    local fh = fs.open(path, "w")
    fh.write(data)
    fh.close()
  end
  print("Done! Launch repo with: shell.run('mainframe/repo_service.lua')")
end

install()