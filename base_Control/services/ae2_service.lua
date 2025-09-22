-- ae2_service.lua — Advanced Peripherals ME Bridge wrapper (v0.1.0)
-- Thin, safe, and cached accessors for AE2 via meBridge.
-- Exposes: probe, summary, stockItem, stockFluid, listItems, listFluids,
--          craft, export, import, cpus (optional), handleEvent
--
-- Perf: caches peripheral handle; no polling; callers decide cadence.
-- Errors: functions assert on missing bridge to fail-fast in dev, so wrap calls in pcall in UIs.

local M = {}
local bridge         -- cached peripheral handle
local lastProbeAt = 0
local PROBE_INTERVAL = 2  -- seconds between probe attempts

-- internal: (re)locate bridge with light throttling
local function _find()
  local now = os.clock()
  if bridge and peripheral.isPresent(peripheral.getName(bridge)) then return true end
  if now - lastProbeAt < PROBE_INTERVAL then return bridge ~= nil end
  lastProbeAt = now
  bridge = peripheral.find and peripheral.find("meBridge") or nil
  return bridge ~= nil
end

function M.probe() return _find() end
local function ok() assert(_find(), "ME Bridge not found") end

-- Storage summary
function M.summary()
  ok()
  return {
    usedItem   = bridge.getUsedItemStorage(),
    totalItem  = bridge.getTotalItemStorage(),
    usedFluid  = bridge.getUsedFluidStorage(),
    totalFluid = bridge.getTotalFluidStorage(),
  }
end

-- Items
function M.listItems() ok(); return bridge.listItems() end
function M.stockItem(spec) ok(); return bridge.getItem(spec) end  -- spec {name|fingerprint,count?}

-- Fluids
function M.listFluids() ok(); return bridge.listFluids() end
function M.stockFluid(name)
  ok()
  local fluids = bridge.listFluids() or {}
  for _,f in ipairs(fluids) do
    if f.name==name then return { amount=f.amount, displayName=f.displayName or name } end
  end
  return { amount=0, displayName=name }
end

-- Crafting
function M.craft(spec, cpu)
  ok()
  -- spec { name=string, count=number } or fingerprint table from listItems()
  return bridge.craftItem(spec, cpu)
end

-- Import/Export (requires an adjacent inventory/tank on the meBridge side)
function M.export(spec, direction)
  ok(); return bridge.exportItem(spec, direction)  -- direction: "north"|"south"|... per AP docs
end
function M.import(spec, direction)
  ok(); return bridge.importItem(spec, direction)
end

-- Optional: CPUs (if AP exposes; safe to pcall)
function M.cpus()
  ok()
  local ok2, data = pcall(function() return bridge.getCraftingCPUs and bridge.getCraftingCPUs() end)
  return ok2 and data or {}
end

-- Bubble crafting events up to caller
function M.handleEvent(ev, a, b)
  if ev=="crafting" then return { type="crafting", success=a, message=b } end
end

return M
