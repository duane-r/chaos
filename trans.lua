-- Chaos trans.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2017
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)


local function teleport(user)
	if not (user) then
		return
	end

	local name = user:get_player_name()
	local pos = user:getpos()
	if not (name and pos and name ~= '' and type(name) == 'string') then
		return
	end


  local newpos = {x=0,y=chaos.baseline,z=0}
  for r = 0, 10 do
    local tdx = math.floor((pos.x + 80) / 160) * 160 - 0
    local tdz = math.floor((pos.z + 80) / 160) * 160 - 0
    for z = tdz - r * 160, tdz + r * 160, 160 do
      for x = tdx - r * 160, tdx + r * 160, 160 do
        local btype = chaos.get_btype(x, z)
        if btype == 0 then
          if pos.y < chaos.baseline + chaos.extent_bottom or pos.y > chaos.baseline + chaos.extent_top then
            newpos = {x=x, y=chaos.baseline, z=z}
          else
            newpos = {x=x, y=120, z=z}
          end

          user:setpos(newpos)
          print('Chaos: '..name..' teleported to ('..newpos.x..','..newpos.y..','..newpos.z..')')

          user:set_physics_override({gravity=0.1})

          minetest.after(20, function()
            user:set_physics_override({gravity=1})
          end)

          return
        end
      end
    end
  end
end


minetest.register_craftitem('chaos:trump', {
  description = 'Trump of Chaos',
  drawtype = "plantlike",
  paramtype = "light",
  tiles = {'chaos_trump.png'},
  inventory_image = 'chaos_trump.png',
  groups = {dig_immediate = 3},
  sounds = default.node_sound_stone_defaults(),
  on_use = function(itemstack, user, pointed_thing)
    teleport(user)
  end,
})

minetest.register_craft({
  output = 'chaos:trump',
  recipe = {
    {'','default:obsidian_shard',''},
    {'','default:paper',''},
    {'','default:mese_crystal_fragment',''},
  }
})
