-- Chaos mapgen.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2017
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)


local DEBUG


chaos.real_get_mapgen_object = minetest.get_mapgen_object
minetest.get_mapgen_object = function(object)
  if object == 'heightmap' then
    return table.copy(chaos.last_heightmap)
  else
    return chaos.real_get_mapgen_object(object)
  end
end


-- This table looks up nodes that aren't already stored.
local node = setmetatable({}, {
  __index = function(t, k)
    if not (t and k and type(t) == 'table') then
      return
    end

    t[k] = minetest.get_content_id(k)
    return t[k]
  end
})
chaos.node = node


local data = {}
local p2data = {}  -- vm rotation data buffer
local heightmap = {}


local function generate(p_minp, p_maxp, seed)
  if not (p_minp and p_maxp and seed) then
    return
  end

  local minp, maxp = p_minp, p_maxp
  local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
  if not (vm and emin and emax) then
    return
  end

  vm:get_data(data)
  p2data = vm:get_param2_data()
  local area = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
  local csize = vector.add(vector.subtract(maxp, minp), 1)

  for fake_loop = 1, 1 do
    --chaos.terrain(minp, maxp, data, p2data, area, node, heightmap)
    chaos.terrain(minp, maxp, data, p2data, area, node, heightmap)
  end
  chaos.last_heightmap = heightmap


  vm:set_data(data)
  vm:set_param2_data(p2data)
  minetest.generate_ores(vm, minp, maxp)

  if DEBUG then
    vm:set_lighting({day = 15, night = 15})
  else
    vm:set_lighting({day = 0, night = 0}, minp, maxp)
    vm:calc_lighting()
  end
  vm:update_liquids()
  vm:write_to_map()
end


if chaos.path then
  dofile(chaos.path .. "/terrain.lua")
end


local function pgenerate(...)
  --local status, err = pcall(generate, ...)
  local status, err = true
  generate(...)
  if not status then
    print('Chaos: Could not generate terrain:')
    print(dump(err))
    collectgarbage("collect")
  end
end


-- Inserting helps to ensure that chaos operates first.
table.insert(minetest.registered_on_generateds, 1, pgenerate)