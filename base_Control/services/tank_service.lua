-- tank_service.lua — Block Reader wrapper for Mekanism Dynamic Tank (v0.1.0)
-- Reads exact fluid level and capacity directly from Block Reader peripheral.
--
-- Usage: local tank = require("services/tank_service"); tank.read("blockReader_3")
-- Returns: { name=string, amount=number, capacity=number }
--
-- Perf: caches peripheral wraps; callers choose polling cadence.
-- Safety: returns nil,err string if peripheral missing.

local M = {}
local cache = {}

local function wrap(name)
  if not name then return nil end
  if cache[name] and peripheral.isPresent(name) then return cache[name] end
  if peripheral.isPresent(name) and peripheral.getType(name)=="blockReader" then
    cache[name] = peripheral.wrap(name)
    return cache[name]
  end
end

--- Reads a block reader and normalizes Mekanism Dynamic Tank fields.
-- @param periphName string Peripheral name, e.g., "blockReader_3"
-- @return table|nil, string On success returns { name, amount, capacity }, else nil,err
function M.read(periphName)
  local br = wrap(periphName)
  if not br then return nil, "Block Reader not found: "..tostring(periphName) end

  local t = br.getBlockData() or {}

  -- Common Mekanism patterns:
  local f = t.stored or t.storedFluid or (t.tank and t.tank.fluid)
  local name, amt, cap
  if f then
    name = f.name or (f.resource and f.resource.name) or f.fluid or f.id
    amt  = f.amount or f.amount_mb or f.level or f.stored or 0
  end
  cap = t.capacity or (t.tank and (t.tank.capacity or t.tank.capacity_mb)) or t.max or 0

  if not name and t.displayName then name = t.displayName end
  return { name = name or "(unknown)", amount = tonumber(amt) or 0, capacity = tonumber(cap) or 0 }
end

return M