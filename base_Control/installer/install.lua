-- install.lua — Unified installer for BaseControl v2 (v1.0.1)
-- Run this on ANY CC computer. It asks which role to install and chains to the role installer.
-- Roles: 1) Client (labelClient)  2) Pocket (BaseControl)  3) Mainframe (repo service)
--
-- Note: We avoid varargs/cli flags because `wget run` does not pass args to chunks.
-- If you need to override repo/branch, edit the constants below before running.

local OWNER  = "LucidDreams5150"
local REPO   = "Minecraft-BaseControl"
local BRANCH = "main"
local BASE   = "base_Control"     -- repo subfolder where installers live

local ROLES = {
  client    = { title = "Label Client",            file = "installer/install_client.lua" },
  pocket    = { title = "Pocket (BaseControl)",    file = "installer/install_pocket.lua" },
  mainframe = { title = "Mainframe (Repo Service)", file = "installer/install_mainframe.lua" },
}

local function httpReady()
  if not http then return false, "HTTP API missing" end
  local ok, why = http.checkURL and http.checkURL("https://raw.githubusercontent.com/")
  if ok == false then return false, why or "HTTP blocked by config" end
  return true
end

local function buildURL(roleKey)
  local role = ROLES[roleKey]
  return ("https://raw.githubusercontent.com/%s/%s/%s/%s/%s"):format(
    OWNER, REPO, BRANCH, BASE, role.file)
end

local function pickRoleInteractive()
  term.clear(); term.setCursorPos(1,1)
  print("BaseControl v2 — Unified Installer (v1.0.1)
")
  print("Choose what to install:")
  print("  [1] Client    — labelClient only (monitors + modem)")
  print("  [2] Pocket    — full BaseControl app (Pocket Computer)")
  print("  [3] Mainframe — repo/manifest service (modem required)")
  print()
  write("Selection (1-3): ")
  local s = read()
  if s=="1" then return "client" end
  if s=="2" then return "pocket" end
  if s=="3" then return "mainframe" end
  return nil
end

local function confirm(msg)
  write(msg.." [y/N]: ")
  local s = (read() or ""):lower()
  return s=="y" or s=="yes"
end

local function runWget(url)
  print("
Downloading & running:
"..url)
  local ok = shell.run("wget","run",url)
  if not ok then
    print("
Error: wget failed. If this is a proxy/SSL issue, try allow-insecure-http in config.")
    return false
  end
  return true
end

-- MAIN
local ok, why = httpReady()
if not ok then
  print("HTTP not available: "..tostring(why))
  print("Enable HTTP in server config or single-player settings and retry.")
  return
end

local role = pickRoleInteractive()
if not role then print("Invalid selection. Exiting.") return end

local url = buildURL(role)
print("")
print("Target repo:   "..OWNER.."/"..REPO)
print("Branch:        "..BRANCH)
print("Role:          "..role.." — "..ROLES[role].title)
print("Installer URL: "..url)
print("")
if not confirm("Proceed?") then print("Canceled.") return end

runWget(url)
