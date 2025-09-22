-- install_pocket.lua — BaseControl Installer for Pocket Computer (v0.1.0)
-- Installs the full BaseControl suite for Pocket usage.

local REPO_URL = "https://raw.githubusercontent.com/LucidDreams5150/Minecraft-BaseControl/main/base_Control"
local FILES = {
  "basectl/main.lua",
  "basectl/ui.lua",
  "basectl/util.lua",
  "basectl/page_server.lua",
  "basectl/page_labels.lua",
  "basectl/page_metrics.lua",
  "basectl/page_updates.lua",
  "basectl/page_utils.lua",
  "services/ae2_service.lua",
  "services/tank_service.lua",
  "services/colony_service.lua",
}

local function fetch(url)
  local h = http.get(url)
  if not h then error("Failed to fetch: "..url) end
  local data = h.readAll()
  h.close()
  return data
end

local function ensureDirs()
  local dirs = {"basectl","services"}
  for _,d in ipairs(dirs) do
    if not fs.exists(d) then fs.makeDir(d) end
  end
end

local function install()
  ensureDirs()
  print("Installing BaseControl Pocket...")
  for _,path in ipairs(FILES) do
    local fullUrl = REPO_URL.."/"..path
    print("Downloading "..path)
    local data = fetch(fullUrl)
    local fh = fs.open(path, "w")
    fh.write(data)
    fh.close()
  end
  print("Done! Launch with: shell.run('basectl/main.lua')")
end

install()