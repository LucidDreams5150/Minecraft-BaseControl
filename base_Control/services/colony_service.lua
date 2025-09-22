-- colony_service.lua — Advanced Peripherals Colony Integrator wrapper (v0.1.0)
-- Thin, safe accessor for MineColonies data via colonyIntegrator peripheral.
--
-- Provides: probe, stats, requests, workOrders, builderResources
--
-- Perf: caches handle; no polling; UI decides refresh cadence.
-- Safety: returns nil if peripheral missing.

local M = {}
local ci           -- cached peripheral handle
local lastProbeAt = 0
local PROBE_INTERVAL = 2

local function _find()
  local now = os.clock()
  if ci and peripheral.isPresent(peripheral.getName(ci)) then return true end
  if now - lastProbeAt < PROBE_INTERVAL then return ci ~= nil end
  lastProbeAt = now
  ci = peripheral.find and peripheral.find("colonyIntegrator") or nil
  return ci ~= nil
end

function M.probe() return _find() end
local function ok() assert(_find(), "Colony Integrator not found") end

-- General colony stats
function M.stats()
  ok()
  return {
    name = ci.getColonyName(),
    id = ci.getColonyID(),
    happiness = ci.getHappiness(),
    active = ci.isActive(),
    underAttack = ci.isUnderAttack(),
    citizens = ci.amountOfCitizens(),
    maxCitizens = ci.maxOfCitizens(),
    constructionSites = ci.amountOfConstructionSites(),
  }
end

-- Active item requests
function M.requests()
  ok(); return ci.getRequests()
end

-- Active work orders (building upgrades/constructions)
function M.workOrders()
  ok(); return ci.getWorkOrders()
end

-- Builder hut resources for a specific position (table with x,y,z)
function M.builderResources(pos)
  ok(); return ci.getBuilderResources(pos)
end

return M
