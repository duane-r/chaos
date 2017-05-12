-- Chaos mobs.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2017
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)


-- This can reregister mobs_redo creatures to use weightless water.
--  However, they tend to have problems whenever the water isn't perfectly
--  flat.

local m
local water_mobs = {'mobs_sharks:shark_lg', 'mobs_sharks:shark_md', 'mobs_sharks:shark_sm'}

for _, mob in pairs(water_mobs) do
  if minetest.registered_entities[mob] then
    minetest.registered_entities[mob].fly_in = 'chaos:weightless_water'

		mobs:spawn_specific(mob, {'chaos:weightless_water', 'default:water_source'}, {'chaos:weightless_water', 'default:water_source'}, -1, 20, 30, 20000, 2, -31000, 31000)
  end
end
