-- Chaos nodes.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2017
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)


local newnode

newnode = chaos.clone_node("default:stone")
newnode.diggable = false
newnode.groups = {}
minetest.register_node("chaos:bedrock", newnode)


newnode = chaos.clone_node("default:water_source")
newnode.description = "Water"
newnode.drop = "default:water_source"
newnode.liquid_range = 0
newnode.liquid_viscosity = 1
newnode.liquid_renewable = false
newnode.liquid_alternative_flowing = "chaos:weightless_water"
newnode.liquid_alternative_source = "chaos:weightless_water"
minetest.register_node("chaos:weightless_water", newnode)

if bucket and bucket.liquids then
  bucket.liquids['chaos:weightless_water'] = {
    source = 'chaos:weightless_water',
    flowing = 'chaos:weightless_water',
    itemname = 'bucket:bucket_water',
  }
end

newnode = chaos.clone_node("default:lava_source")
newnode.description = "Lava"
newnode.drop = "default:lava_source"
newnode.sunlight_propagates = true
newnode.liquid_range = 0
newnode.liquid_viscosity = 1
newnode.liquid_renewable = false
newnode.liquid_alternative_flowing = "chaos:weightless_lava"
newnode.liquid_alternative_source = "chaos:weightless_lava"
minetest.register_node("chaos:weightless_lava", newnode)

if bucket and bucket.liquids then
  bucket.liquids['chaos:weightless_lava'] = {
    source = 'chaos:weightless_lava',
    flowing = 'chaos:weightless_lava',
    itemname = 'bucket:bucket_lava',
  }
end

minetest.register_node("chaos:air_ladder", {
  description = "Air Ladder",
  drawtype = "glasslike",
  tiles = {"chaos_air_ladder.png"},
  paramtype = "light",
  sunlight_propagates = true,
  walkable = false,
  use_texture_alpha = true,
  climbable = true,
  is_ground_content = false,
  selection_box = {
    type = "fixed",
    fixed = {0, 0, 0, 0, 0, 0},
  },
})


local newnode = chaos.clone_node("default:tree")
newnode.description = "Bark"
newnode.tiles = {"default_tree.png"}
newnode.is_ground_content = false
newnode.groups.tree = nil
newnode.groups.flammable = nil
minetest.register_node("chaos:bark", newnode)

newnode = chaos.clone_node("default:tree")
newnode.description = "Giant Wood"
newnode.tiles = {"chaos_tree.png"}
newnode.groups.flammable = nil
newnode.is_ground_content = false
minetest.register_node("chaos:tree", newnode)

newnode = chaos.clone_node("chaos:tree")
newnode.description = "Giant Wood With Mineral"
newnode.tiles = {"chaos_tree.png^chaos_mineral_aquamarine.png"}
newnode.drop = {
  max_items = 1,
  items = {
    {
      items = { 'default:mese_crystal_fragment', },
      rarity = 10,
    },
    {
      items = { 'default:copper_lump', },
      rarity = 4,
    },
    {
      items = { 'default:stone', },
      rarity = 1,
    },
  },
}
minetest.register_node("chaos:tree_mineral", newnode)

minetest.register_craft({
  output = 'default:wood 4',
  recipe = {
    {'chaos:tree'},
  }
})

minetest.register_node("chaos:ironwood", {
  description = "Ironwood",
  tiles = {"chaos_tree.png^[colorize:#B7410E:80"},
  is_ground_content = false,
  groups = {tree = 1, choppy = 2, level=1},
  sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("chaos:diamondwood", {
  description = "Diamondwood",
  tiles = {"chaos_tree.png^[colorize:#5D8AA8:80"},
  is_ground_content = false,
  groups = {tree = 1, choppy = 2, level=2},
  sounds = default.node_sound_wood_defaults(),
})

newnode = chaos.clone_node("default:leaves")
newnode.tiles = {"default_leaves.png^[noalpha"}
newnode.special_tiles = nil
newnode.groups.leafdecay = 0
newnode.drawtype = nil
newnode.waving = nil
newnode.groups.flammable = nil
minetest.register_node("chaos:leaves", newnode)


minetest.register_craftitem("chaos:charcoal", {
  description = "Charcoal Briquette",
  inventory_image = "default_coal_lump.png",
  groups = {coal = 1}
})

minetest.register_craft({
  type = "fuel",
  recipe = "chaos:charcoal",
  burntime = 50,
})

minetest.register_craft({
  type = "cooking",
  output = "default:sand",
  recipe = "chaos:bark",
})

minetest.register_craft({
  type = "cooking",
  output = "default:iron_lump",
  recipe = "chaos:ironwood",
})

minetest.register_craft({
  type = "cooking",
  output = "default:diamond",
  recipe = "chaos:diamondwood",
})

minetest.register_craft({
  type = "cooking",
  output = "chaos:charcoal",
  recipe = "group:tree",
})

minetest.register_craft({
  output = 'default:torch 4',
  recipe = {
    {'group:coal'},
    {'group:stick'},
  }
})

minetest.register_craft({
  output = 'default:coalblock',
  recipe = {
    {'group:coal', 'group:coal', 'group:coal'},
    {'group:coal', 'group:coal', 'group:coal'},
    {'group:coal', 'group:coal', 'group:coal'},
  }
})

if minetest.get_modpath('tnt') then
  minetest.register_craft({
    output = "tnt:gunpowder",
    type = "shapeless",
    recipe = {"group:coal", "default:gravel"}
  })
end

minetest.register_craft({
  output = 'chaos:syrup',
  type = "shapeless",
  recipe = {
    'vessels:glass_bottle',
    'group:sap_bucket',
  },
  replacements = {
    {'chaos:bucket_sap', 'bucket:bucket_empty'},
    {'chaos:bucket_wood_sap', 'chaos:bucket_wood_empty'},
  },
})

minetest.register_craft({
  type = "cooking",
  output = "chaos:amber",
  recipe = "chaos:bucket_sap",
  replacements = {{'chaos:bucket_sap', 'bucket:bucket_empty'},},
})


if minetest.registered_items['underworlds:glowing_fungal_stone'] then
  minetest.register_alias("chaos:glowing_fungal_stone", 'underworlds:glowing_fungal_stone')
  minetest.register_alias("chaos:glowing_fungus", 'underworlds:glowing_fungus')
else
  -- Glowing fungal stone provides an eerie light.
  minetest.register_node("chaos:glowing_fungal_stone", {
    description = "Glowing Fungal Stone",
    tiles = {"default_stone.png^vmg_glowing_fungal.png",},
    is_ground_content = true,
    light_source = LIGHT_MAX - 4,
    groups = {cracky=3, stone=1},
    drop = {items={ {items={"default:cobble"},}, {items={"chaos:glowing_fungus",},},},},
    sounds = default.node_sound_stone_defaults(),
  })

  -- Glowing fungus grows underground.
  minetest.register_craftitem("chaos:glowing_fungus", {
    description = "Glowing Fungus",
    drawtype = "plantlike",
    paramtype = "light",
    tiles = {"vmg_glowing_fungus.png"},
    inventory_image = "vmg_glowing_fungus.png",
    groups = {dig_immediate = 3},
  })
end

-- moon glass (glows)
if not minetest.registered_items['elixirs:moon_glass'] then
  newnode = chaos.clone_node("default:glass")
  newnode.description = "Glowing Glass"
  newnode.light_source = default.LIGHT_MAX
  minetest.register_node("chaos:moon_glass", newnode)
end

-- Moon juice is extracted from glowing fungus, to make glowing materials.
minetest.register_craftitem("chaos:moon_juice", {
  description = "Moon Juice",
  drawtype = "plantlike",
  paramtype = "light",
  tiles = {"vmg_moon_juice.png"},
  inventory_image = "vmg_moon_juice.png",
  --groups = {dig_immediate = 3, attached_node = 1},
  groups = {dig_immediate = 3, vessel = 1},
  sounds = default.node_sound_glass_defaults(),
})
