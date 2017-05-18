-- Chaos init.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2017
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)


chaos = {}
chaos.version = '1.0'
chaos.path = minetest.get_modpath(minetest.get_current_modname())
chaos.world = minetest.get_worldpath()

chaos.baseline = 5000  -- the altitude of the chaos "dimension"
chaos.extent_bottom = -500  -- how far down to make the chaos
chaos.extent_top = 500  -- how far up to make it

local baseline = chaos.baseline
local extent_bottom = chaos.extent_bottom
local extent_top = chaos.extent_top


if not minetest.set_mapgen_setting then
  return
end


local math_random = math.random


-- Modify a node to add a group
function minetest.add_group(node, groups)
  local def = minetest.registered_items[node]
  if not (node and def and groups and type(groups) == 'table') then
    return false
  end
  local def_groups = def.groups or {}
  for group, value in pairs(groups) do
    if value ~= 0 then
      def_groups[group] = value
    else
      def_groups[group] = nil
    end
  end
  minetest.override_item(node, {groups = def_groups})
  return true
end


function chaos.clone_node(name)
  if not (name and type(name) == 'string') then
    return
  end

  local node = minetest.registered_nodes[name]
  local node2 = table.copy(node)
  return node2
end


chaos.surround = function(node, data, area, ivm)
  if not (node and data and area and ivm and type(data) == 'table' and type(ivm) == 'number') then
    return
  end

  -- Check to make sure that a plant root is fully surrounded.
  -- This is due to the kludgy way you have to make water plants
  --  in minetest, to avoid bubbles.
  for x1 = -1,1,2 do
    local n = data[ivm+x1] 
    if n == node['default:river_water_source'] or n == node['default:water_source'] or n == node['air'] then
      return false
    end
  end
  for z1 = -area.zstride,area.zstride,2*area.zstride do
    local n = data[ivm+z1] 
    if n == node['default:river_water_source'] or n == node['default:water_source'] or n == node['air'] then
      return false
    end
  end

  return true
end


dofile(chaos.path .. '/nodes.lua')
dofile(chaos.path .. '/schematics.lua')
dofile(chaos.path .. '/mapgen.lua')
dofile(chaos.path .. '/mobs.lua')
dofile(chaos.path .. '/trans.lua')


local function chaotic_sky(player)
  player:set_sky("#4070FF", "skybox", {'chaos_sky_1.png', 'chaos_sky_6.png', 'chaos_sky_5.png', 'chaos_sky_3.png', 'chaos_sky_4.png', 'chaos_sky_2.png'})
  --player:set_sky("#4070FF", "skybox", {'raven_chaos_top.png', 'raven_chaos_bottom.png', 'raven_chaos_right.png', 'raven_chaos_left.png', 'raven_chaos_front.png', 'raven_chaos_back.png'})
end


players_underground = {}
players_in_chaos = {}
local dps_delay = 3
local last_dps_check = 0
minetest.register_globalstep(function(dtime)
  if not (dtime and type(dtime) == 'number') then
    return
  end

  if not (players_underground and players_in_chaos) then
    return
  end

  local time = minetest.get_gametime()
  if not (time and type(time) == 'number') then
    return
  end

  if last_dps_check and time - last_dps_check < dps_delay then
    return
  end

  local players = minetest.get_connected_players()
  if not (players and type(players) == 'table') then
    return
  end

  for i = 1, #players do
    local player = players[i]
    local pos = player:getpos()
    pos = vector.round(pos)
    local player_name = player:get_player_name()

    if pos.y < baseline - 90 and pos.y > baseline + extent_bottom then
      if not players_underground[player_name] then
        player:set_sky("#000000", "plain")
        players_in_chaos[player_name] = nil
        players_underground[player_name] = true
      end
    elseif pos.y < baseline + extent_top and pos.y >= baseline - 90 then
      if not players_in_chaos[player_name] then
        chaotic_sky(player)
        players_in_chaos[player_name] = true
        players_underground[player_name] = nil
      end
    elseif players_in_chaos[player_name] or players_underground[player_name] then
      players_in_chaos[player_name] = nil
      players_underground[player_name] = nil
      player:set_sky(nil, "regular")
    end
  end
end)
