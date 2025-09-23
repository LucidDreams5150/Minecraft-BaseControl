-- install.lua — Unified installer for BaseControl v2 (v1.0.0)
-- Run this on ANY CC computer. It asks which role to install and chains to the role installer.
-- Roles: 1) Client (labelClient)  2) Pocket (BaseControl)  3) Mainframe (repo service)
--
-- Non-interactive flags (optional):
--   --role=client|pocket|mainframe  --owner=LucidDreams5150  --repo=Minecraft-BaseControl  --branch=main  --base=base_Control
-- Example unattended: install.lua --role=pocket
--
-- Requires HTTP to be enabled. Uses `wget run` so we don't leave extra files behind.

local DEFAULT_OWNER  = "LucidDreams5150"
local DEFAULT_REPO   = "Minecraft-BaseControl"
local DEFAULT_BRANCH = "main"
local DEFAULT_BASE   = "base_Control"     -- repo subfolder where installers live

local ROLES = {
  client    = { title = "Label Client",  file = "installer/install_client.lua" },
  pocket    = { title = "Pocket (BaseControl)", file = "installer/install_pocket.lua" },
  mainframe = { title = "Mainframe (Repo)", file = "installer/install_mainframe.lua" },
}

local function parseArgs()
  local args = { owner=DEFAULT_OWNER, repo=DEFAULT_REPO, branch=DEFAULT_BRANCH, base=DEFAULT_BASE }
  for _,a in ipairs({...}) do
    local k,v = a:match("^%-%-(%w+)%=(.+)$")
    if k then args[k]=v
    elseif a:match("^%-%-") then args[a:sub(3)] = true
    elseif not args.role and ROLES[a] then args.role=a
    end
  end
  return args
end

local function httpReady()
  if not http then return false, "HTTP API missing" end
  local ok, why = http.checkURL and http.checkURL("https://raw.githubusercontent.com/")
  if ok == false then return false, why or "HTTP blocked by config" end
  return true
end

local function buildURL(args, roleKey)
  local role = ROLES[roleKey]
  return ("https://raw.githubusercontent.com/%s/%s/%s/%s/%s"):format(
    args.owner, args.repo, args.branch, args.base, role.file)
end

local function pickRoleInteractive()
  term.clear(); term.setCursorPos(1,1)
  print("BaseControl v2 — Unified Installer\n")
  print("Choose what to install:")
  print("  [1] Client   — labelClient only (monitors + modem)")
  print("  [2] Pocket   — full BaseControl app (Pocket Computer)")
  print("  [3] Mainframe— repo/manifest service (modem required)")
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
  print("Downloading & running: \n"..url)
  local ok = shell.run("wget","run",url)
  if not ok then
    print("\nError: wget failed. If this is a proxy/SSL issue, try allow-insecure-http in config.")
    return false
  end
  return true
end

-- MAIN
local args = parseArgs()
local ok, why = httpReady()
if not ok then
  print("HTTP not available: "..tostring(why))
  print("Enable HTTP in server config or single-player settings and retry.")
  return
end

local role = args.role
if not role or not ROLES[role] then
  role = pickRoleInteractive()
  if not role then print("Invalid selection. Exiting.") return end
end

local url = buildURL(args, role)
print("")
print("Target repo:   "..args.owner.."/"..args.repo)
print("Branch:        "..args.branch)
print("Role:          "..role.." — "..ROLES[role].title)
print("Installer URL: "..url)
print("")
if not confirm("Proceed?") then print("Canceled.") return end

runWget(url)
