-- Chaos terrain.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2017
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)


-- floating glass spheres

local max_depth = 31000
local baseline = chaos.baseline
local extent_bottom = chaos.extent_bottom
local lamp_prob = 50
local tree_spacing = 4
local river_scale = 15
local terrain_scale = 50

local heat_1_map, heat_2_map, humidity_1_map, humidity_2_map = {}, {}, {}, {}
local heat_1_noise, heat_2_noise, humidity_1_noise, humidity_2_noise
local heat_1_p = {offset = 50, scale = 50, seed = 5349, spread = {x = 1000, y = 1000, z = 1000}, octaves = 3, persist = 0.5, lacunarity = 2}
local heat_2_p = {offset = 0, scale = 1.5, seed = 13, spread = {x = 8, y = 8, z = 8}, octaves = 2, persist = 1.0, lacunarity = 2}
local humidity_1_p = {offset = 50, scale = 50, seed = 842, spread = {x = 1000, y = 1000, z = 1000}, octaves = 3, persist = 0.5, lacunarity = 2}
local humidity_2_p = {offset = 0, scale = 1.5, seed = 90003, spread = {x = 8, y = 8, z = 8}, octaves = 2, persist = 1.0, lacunarity = 2}

local ground_level_noise, terrain_noise, sea_noise
local max_btype = 8

local terrain_map = {}
local terrain_p = {offset = 0, scale = river_scale, seed = -6819, spread = {x = 150, y = 150, z = 150}, octaves = 3, persist = 1, lacunarity = 2.0}
local sea_map = {}
--local sea_p = {offset = 0, scale = river_scale, seed = 5299, spread = {x = 150, y = 150, z = 150}, octaves = 3, persist = 1, lacunarity = 2.0}
local sea_p = {offset = -30, scale = 50, seed = 8402, spread = {x = 451, y = 451, z = 451}, octaves = 2, persist = 0.6, lacunarity = 2.0}

local ground_level_map = {}
local ground_level_p = {offset = 0, scale = 20, seed = 4382, spread = {x = 251, y = 251, z = 251}, octaves = 5, persist = 0.6, lacunarity = 2.0}


local math_abs = math.abs
local math_ceil = math.ceil
local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local math_random = math.random
local math_sqrt = math.sqrt
local math_sin = math.sin

local seed = minetest.get_mapgen_setting('seed')
local seed_int = 0
while seed:len() > 0 do
  seed_int = seed_int + tonumber(seed:sub(1,2))
  seed = seed:sub(3)
end
chaos.seed_int = seed_int

function b_rand(s)
  local x
  repeat
    x = math_sin(s) * 10000
    x = x - math_floor(x)
    s = s + 1
  until not (x < 0.15 or x > 0.9)
  return (x-0.15) * 1 / 0.75 
end

chaos.decorations = {}

do
  for _, odeco in pairs(minetest.registered_decorations) do
    if not odeco.schematic then
      local deco = {}
      if odeco.biomes then
        deco.biomes = {}
        for _, b in pairs(odeco.biomes) do
          deco.biomes[b] = true
        end
      end

      deco.deco_type = odeco.deco_type
      deco.decoration = odeco.decoration
      deco.schematic = odeco.schematic
      deco.fill_ratio = odeco.fill_ratio

      if odeco.noise_params then
        deco.fill_ratio = math.max(0.001, (odeco.noise_params.scale + odeco.noise_params.offset) / 4)
      end

      local nod = minetest.registered_nodes[deco.decoration]
      if nod and nod.groups and nod.groups.flower then
        deco.flower = true
      end

      chaos.decorations[#chaos.decorations+1] = deco
    end
  end
end

chaos.biomes = {}
local biomes = chaos.biomes
local biome_names = {}
do
  local biome_mod = {
    cold_desert = { y_min = 1, },
    cold_desert_ocean = { y_min = -max_depth, y_max = 0, },
    coniferous_forest = { y_min = 1, },
    coniferous_forest_ocean = { y_min = -max_depth, y_max = 0, },
    deciduous_forest = {},
    deciduous_forest_ocean = { y_min = -max_depth, },
    deciduous_forest_shore = {},
    desert = { y_min = 1, },
    desert_ocean = { y_min = -max_depth, y_max = 0, },
    --glacier = { y_min = 1, node_water_top = 'chaos:thin_ice', depth_water_top = 1, },
    glacier = { y_min = 1, depth_water_top = 1, },
    glacier_ocean = { y_min = -max_depth, y_max = 0, },
    grassland = { y_min = 1, },
    grassland_ocean = { y_min = -max_depth, y_max = 0, },
    icesheet = { y_min = 1, },
    icesheet_ocean = { y_min = -max_depth, y_max = 0, },
    rainforest = {},
    rainforest_ocean = { y_min = -max_depth, },
    rainforest_swamp = {},
    sandstone_desert = { y_min = 1, },
    sandstone_desert_ocean = { y_min = -max_depth, y_max = 0, },
    savanna = {},
    savanna_ocean = { y_min = -max_depth, },
    savanna_shore = {},
    snowy_grassland = { y_min = 1, },
    snowy_grassland_ocean = { y_min = -max_depth, y_max = 0, },
    --taiga = { y_min = 1, node_water_top = 'chaos:thin_ice', depth_water_top = 1, },
    taiga = { y_min = 1, depth_water_top = 1, },
    taiga_ocean = { y_min = -max_depth, y_max = 0, },
    --tundra = { node_river_water = "chaos:thin_ice", },
    --tundra_beach = { node_river_water = "chaos:thin_ice", },
    --tundra = { node_top = 'default:snowblock', depth_top = 1,  y_min = 1, node_water_top = 'chaos:thin_ice', depth_water_top = 1, },
    tundra = { node_top = 'default:snowblock', depth_top = 1,  y_min = 1, depth_water_top = 1, },
    tundra_ocean = { y_min = -max_depth, y_max = 0, },
    underground = {},
  }

  do
    local tree_biomes = {}
    tree_biomes["deciduous_forest"] = {"apple_tree", 'aspen_tree'}
    tree_biomes["coniferous_forest"] = {"pine_tree"}
    tree_biomes["taiga"] = {"pine_tree"}
    tree_biomes["rainforest"] = {"jungle_tree"}
    tree_biomes["rainforest_swamp"] = {"jungle_tree"}
    tree_biomes["coniferous_forest"] = {"pine_tree"}
    tree_biomes["savanna"] = {"acacia_tree"}

    for i, obiome in pairs(minetest.registered_biomes) do
      local biome = table.copy(obiome)
      biome.special_tree_prob = 2 * 25

      if string.match(biome.name, "^rainforest") then
        biome.special_tree_prob = 0.8 * 25
      end

      if biome.name == "savanna" then
        biome.special_tree_prob = 30 * 25
      end

      biome.special_trees = tree_biomes[biome.name]
      biomes[biome.name] = biome
      biome_names[#biome_names+1] = biome.name

      for n, bi in pairs(biome_mod) do
        for i, rbi in pairs(biomes) do
          if rbi.name == n then
            for j, prop in pairs(bi) do
              biomes[i][j] = prop
            end
          end
        end
      end
    end
  end

  biomes["desertstone_grassland"] = {
    name = "desertstone_grassland",
    --node_dust = "",
    node_top = "default:dirt_with_grass",
    depth_top = 1,
    node_filler = "default:dirt",
    depth_filler = 1,
    node_stone = "default:desert_stone",
    node_riverbed = "default:sand",
    depth_riverbed = 2,
    --node_water_top = "",
    --depth_water_top = ,
    --node_water = "",
    --node_river_water = "",
    y_min = 6,
    y_max = max_depth,
    heat_point = 80,
    humidity_point = 55,
  }

  chaos.decorations[#chaos.decorations+1] = {
    deco_type = "simple",
    place_on = {"default:dirt_with_grass"},
    sidelen = 80,
    fill_ratio = 0.1,
    biomes = {"desertstone_grassland", },
    y_min = 1,
    y_max = max_depth,
    decoration = "default:junglegrass",
  }
end


local function register_flower(name, desc, biomes, chance)
  local groups = {}
  groups.snappy = 3
  groups.flammable = 2
  groups.flower = 1
  groups.flora = 1
  groups.attached_node = 1

  minetest.register_node("chaos:" .. name, {
    description = desc,
    drawtype = "plantlike",
    waving = 1,
    tiles = {"chaos_" .. name .. ".png"},
    inventory_image = "chaos_" .. name .. ".png",
    wield_image = "flowers_" .. name .. ".png",
    sunlight_propagates = true,
    paramtype = "light",
    walkable = false,
    buildable_to = true,
    stack_max = 99,
    groups = groups,
    sounds = default.node_sound_leaves_defaults(),
    selection_box = {
      type = "fixed",
      fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},
    }
  })

  local bi = {}
  if biomes then
    bi = {}
    for _, b in pairs(biomes) do
      bi[b] = true
    end
  end

  chaos.decorations[#chaos.decorations+1] = {
    deco_type = "simple",
    place_on = {"default:dirt_with_grass"},
    biomes = bi,
    fill_ratio = chance,
    flower = true,
    decoration = "chaos:"..name,
  }
end

register_flower("orchid", "Orchid", {"rainforest", "rainforest_swamp"}, 0.025)
register_flower("bird_of_paradise", "Bird of Paradise", {"rainforest", "desertstone_grassland"}, 0.025)
register_flower("gerbera", "Gerbera", {"savanna", "rainforest", "desertstone_grassland"}, 0.005)


local function register_decoration(deco, place_on, biomes, chance)
  local bi = {}
  if biomes then
    bi = {}
    for _, b in pairs(biomes) do
      bi[b] = true
    end
  end

  chaos.decorations[#chaos.decorations+1] = {
    deco_type = "simple",
    place_on = place_on,
    biomes = bi,
    fill_ratio = chance,
    decoration = deco,
  }
end


local function get_decoration(biome_name)
  for i, deco in pairs(chaos.decorations) do
    if not deco.biomes or deco.biomes[biome_name] then
      if deco.deco_type == "simple" then
        if deco.fill_ratio and math.random(1000) - 1 < deco.fill_ratio * 1000 then
          return deco.decoration
        end
      end
    end
  end
end


chaos.get_btype = function(x, z)
  local btype = 0
  local dx = math.floor((x + 80) / 160)
  local dz = math.floor((z + 80) / 160)

  if dx == 0 and dz == 0 then
    btype = 0
  else
    btype = math_floor(max_btype * b_rand(dz * 991 + dx * 7 + chaos.seed_int))
  end
  --btype = 7

  return btype
end


chaos.terrain = function(minp, maxp, data, p2data, area, node)
  if not (minp and maxp and data and area and node and type(data) == 'table') then
    return
  end


  local squaresville_town
  if minetest.get_modpath('squaresville') and squaresville.in_town then
    squaresville_town = true
  end


  local csize = vector.add(vector.subtract(maxp, minp), 1)
  local map_max = {x = csize.x, y = csize.y + 2, z = csize.z}
  local map_min = {x = minp.x, y = minp.y - 1, z = minp.z}


  if not (terrain_noise and sea_noise and ground_level_noise) then
    ground_level_noise = minetest.get_perlin_map(ground_level_p, {x=csize.x, y=csize.z})
    terrain_noise = minetest.get_perlin_map(terrain_p, {x=csize.x, y=csize.z})
    sea_noise = minetest.get_perlin_map(sea_p, {x=csize.x, y=csize.z})

    if not (terrain_noise and sea_noise and ground_level_noise) then
      return
    end
  end

  terrain_map = terrain_noise:get2dMap_flat({x=minp.x, y=minp.z}, terrain_map)
  sea_map = sea_noise:get2dMap_flat({x=minp.x, y=minp.z}, sea_map)
  ground_level_map = ground_level_noise:get2dMap_flat({x=minp.x, y=minp.z}, ground_level_map)

  if not (terrain_map and sea_map and ground_level_map) then
    return
  end

  if not (heat_1_noise and heat_2_noise and humidity_1_noise and humidity_2_noise) then
    heat_1_noise = minetest.get_perlin_map(heat_1_p, {x=csize.x, y=csize.z})
    heat_2_noise = minetest.get_perlin_map(heat_2_p, {x=csize.x, y=csize.z})
    humidity_1_noise = minetest.get_perlin_map(humidity_1_p, {x=csize.x, y=csize.z})
    humidity_2_noise = minetest.get_perlin_map(humidity_2_p, {x=csize.x, y=csize.z})

    if not (heat_1_noise and heat_2_noise and humidity_1_noise and humidity_2_noise) then
      return
    end
  end

  heat_1_map = heat_1_noise:get2dMap_flat({x=minp.x, y=minp.z}, heat_1_map)
  heat_2_map = heat_2_noise:get2dMap_flat({x=minp.x, y=minp.z}, heat_2_map)
  humidity_1_map = humidity_1_noise:get2dMap_flat({x=minp.x, y=minp.z}, humidity_1_map)
  humidity_2_map = humidity_2_noise:get2dMap_flat({x=minp.x, y=minp.z}, humidity_2_map)
  chaos.humidity = humidity_1_map

  local tree_map = {}
  for z = minp.z, maxp.z, tree_spacing do
    for x = minp.x, maxp.x, tree_spacing do
      tree_map[ (x + math_random(tree_spacing)) .. ',' .. (z + math_random(tree_spacing)) ] = true
    end
  end

  local sphere_count = 30
  local caves = {}
  for i = 1, sphere_count do
    caves[#caves+1] = {x=math_random(minp.x + 8, maxp.x - 8), y=math_random(minp.y + 8, maxp.y - 8), z=math_random(minp.z + 8, maxp.z - 8), r=math_random(1,20)}
  end

  local index = 0
  local index3d = 0
  local write
  for z = minp.z, maxp.z do
    for x = minp.x, maxp.x do
      index = index + 1
      index3d = (z - minp.z) * (csize.y + 2) * csize.x + (x - minp.x) + 1
      local terrain = math_abs(terrain_map[index])
      local sea_level = sea_map[index] + baseline

      local inv = (6 - terrain)
      local bot = -2 - inv
      bot = math_floor(bot + ground_level_map[index] + baseline)
      inv = math_ceil(inv + ground_level_map[index] + baseline)

      local heat = heat_1_map[index] + heat_2_map[index]
      local humidity = (humidity_1_map[index] + humidity_2_map[index]) * (2.5 - ((sea_level - baseline) / river_scale)) / 2
      humidity_1_map[index] = humidity

      local biome_height = math_max(1, inv - baseline)
      if sea_level >= inv then
        biome_height = inv - sea_level + baseline + 2
      end

      heat = heat - 20 * biome_height / terrain_scale

      local biome_name = 'underground'
      local biome_diff = 1000
      for name, biome in pairs(biomes) do
        if (biome.y_min or -max_depth) <= biome_height and (biome.y_max or max_depth) >= biome_height then
          local diff = math_abs(biome.heat_point - heat) + math_abs(biome.humidity_point - humidity)

          if diff < biome_diff then
            biome_name = name
            biome_diff = diff
          end
        end
      end

      local deco

      local btype = chaos.get_btype(x, z)

      local tdx = (x + 80) % 160 - 80
      local tdz = (z + 80) % 160 - 80
      local pyr = math_min(math_abs(80 - (x % 160)), math_abs(80 - (z % 160)))
      local r2
      if btype == 4 then
        r2 = 32 + math_floor(tdx / 4) % 3 * 6 + math_floor(tdz / 4) % 3 * 6
      end

      local ivm = area:index(x, maxp.y, z)
      for y = maxp.y, minp.y, -1 do
        if terrain < 2 then
          if y <= inv + 32 and y >= inv + 30 then
            if sea_level < y then
              data[ivm] = node["chaos:weightless_lava"]
            else
              data[ivm] = node["default:stone"]
            end
          end
        end

        if terrain < 8 then
          if y == inv and y >= bot then
            data[ivm] = node[biomes[biome_name].node_top or 'default:stone']
            deco = y
          elseif y < inv and y >= inv - 2 and y >= bot then
            data[ivm] = node[biomes[biome_name].node_filler or 'default:stone']
          elseif y < inv and y >= bot then
            data[ivm] = node[biomes[biome_name].node_stone or 'default:stone']
          end
        end

        local tree_dist
        if btype == 4 then
          tree_dist = math_floor(math_sqrt(tdx ^ 2 + tdz ^ 2 + (y - baseline - 60) ^ 2))
        end

        if btype ~= 6 and y > baseline - 97 and pyr > 70 then
          deco = nil
          if btype == 5 then
            if y < pyr + baseline - 90 then
              data[ivm] = node["air"]
            end
          elseif y < baseline + 80 and pyr >= 79 and btype ~= 3 and btype ~= 7 then
            data[ivm] = node['chaos:air_ladder']
          elseif y < baseline + 80 and btype < 3 and pyr < 79 and (baseline + y) % 5 == 4 then
            if pyr % 3 == 0 and (x % 4 + z % 4 == 0) then
              data[ivm] = node['default:meselamp']
            elseif btype == 0 then
              data[ivm] = node['default:steelblock']
            elseif btype == 1 then
              data[ivm] = node['default:glass']
            elseif btype == 2 then
              data[ivm] = node['default:obsidian_glass']
            end
          elseif btype == 0 and y < baseline + 80 and (pyr > 71 or x % 2 == 0 or z % 2 == 0) then
            data[ivm] = node['air']
          elseif btype == 0 and y < pyr + baseline + 10 then
            data[ivm] = node['default:steelblock']
          elseif btype == 3 and pyr == 71 and y < baseline + 81 then
            data[ivm] = node['default:obsidian_glass']
          elseif btype == 3 and y < baseline + 81 then
            data[ivm] = node['chaos:weightless_water']
            --data[ivm] = node['default:water_source']
          elseif btype == 7 and pyr == 71 and y < baseline + 81 then
            data[ivm] = node['default:obsidian']
          elseif btype == 7 and y < baseline + 81 then
            data[ivm] = node['default:lava_source']
          elseif btype == 4 and pyr > 71 and y < pyr + baseline + 10 and y > baseline + -pyr - 17 then
            data[ivm] = node['chaos:tree']
          elseif btype == 4 and ((pyr == 71 and y < pyr + baseline + 10 and y > baseline + -pyr - 17) or y == pyr + baseline + 10 or y == baseline + -pyr - 17) then
            data[ivm] = node['chaos:bark']
          else
            data[ivm] = node["air"]
          end
        elseif data[ivm] == node['air'] and y < baseline + -90 + pyr then
          data[ivm] = node['default:stone']
        elseif y <= sea_level and data[ivm] == node['air'] then
          data[ivm] = node[biomes[biome_name].node_water_top or 'default:water_source']
          if data[ivm] == node['default:water_source'] then
            data[ivm] = node["chaos:weightless_water"]
          end
        end

        if tree_dist and tree_dist < r2 and (baseline + y) % 10 == 0 and (math_floor((tdx + 0) / 4) % 3 == 0 or math_floor((tdz + 0) / 4) % 3 == 0) then
          if data[ivm] == node['air'] then
            data[ivm] = node['chaos:bark']
          end
        elseif tree_dist and tree_dist < r2 and (baseline + y + 3) % 10 < 7 and (math_floor((tdx + 3) / 4) % 3 < 2 or math_floor((tdz + 3) / 4) % 3 < 2) then
          local r = math_abs(((baseline + y + 3) % 10) - 3)
          if (r < 2 or math_random(r) == 1) and data[ivm] == node['air'] then
            data[ivm] = node['chaos:leaves']
          end
        end

        ivm = ivm - area.ystride
        index3d = index3d + csize.x
      end

      if deco then
        if sea_level < deco and biomes[biome_name].special_trees and tree_map[ x .. ',' .. z ] and (biome_name ~= 'savanna' or math.random(20) == 1) then
          local tree_y = deco + (string.match(biome_name, '^rainforest') and 0 or 1)
          chaos.place_schematic(minp, maxp, data, p2data, area, node, {x=x,y=tree_y,z=z}, chaos.schematics[biomes[biome_name].special_trees[math_random(#biomes[biome_name].special_trees)]], true)
        else
          local decoration = get_decoration(biome_name)
          if decoration then
            ivm = area:index(x, deco, z)
            if data[ivm + area.ystride] == node['air'] then
              data[ivm + area.ystride] = node[decoration]
            end
          end
        end
      end
    end
  end

  if minp.y > baseline + -50 and maxp.y < baseline + 1000 then
    for i = 1, 4 do
      local center = math_random(3)

      if caves[i].y > baseline + 40 and caves[i].x > minp.x + 10 and caves[i].x < maxp.x - 10 and caves[i].y > minp.y + 10 and caves[i].y < maxp.y - 10 and caves[i].z > minp.z + 10 and caves[i].z < maxp.z - 10 then
        for z = caves[i].z - caves[i].r, caves[i].z + caves[i].r do
          for x = caves[i].x - caves[i].r, caves[i].x + caves[i].r do
            local ivm = area:index(x, caves[i].y - caves[i].r, z)

            for y = caves[i].y - caves[i].r, caves[i].y + caves[i].r do
              local r = math_floor(math_sqrt((x - caves[i].x) ^ 2 + (y - caves[i].y) ^ 2 + (z - caves[i].z) ^ 2))
              if center == 1 and data[ivm] == node['air'] and r == caves[i].r then
                data[ivm] = node['default:glass']
              elseif center == 2 and data[ivm] == node['air'] and r <= caves[i].r then
                data[ivm] = node['chaos:weightless_water']
              elseif center == 3 and data[ivm] == node['air'] and r <= caves[i].r then
                data[ivm] = node['default:stone']
              elseif data[ivm] == node['air'] and r == 1 then
                if center == 1 then
                  data[ivm] = node['default:meselamp']
                end
              end

              ivm = ivm + area.ystride
            end
          end
        end
      end
    end
  end

  for i = 1, sphere_count do
    for z = caves[i].z - caves[i].r, caves[i].z + caves[i].r do
      for x = caves[i].x - caves[i].r, caves[i].x + caves[i].r do
        local pyr = math_min(math_abs(80 - (x % 160)), math_abs(80 - (z % 160)))
        local ivm = area:index(x, caves[i].y - caves[i].r, z)

        for y = caves[i].y - caves[i].r, caves[i].y + caves[i].r do
          if y < baseline + pyr - 91 and data[ivm] == node['default:stone'] and math_sqrt((x - caves[i].x) ^ 2 + (y - caves[i].y) ^ 2 + (z - caves[i].z) ^ 2) <= caves[i].r then
            data[ivm] = node['air']
          end

          ivm = ivm + area.ystride
        end
      end
    end
  end

  for z = minp.z, maxp.z do
    for x = minp.x, maxp.x do
      local ivm = area:index(x, minp.y, z)

      for y = minp.y, maxp.y do
        if y < baseline + extent_bottom then
          data[ivm] = node['air']
        elseif y == baseline + extent_bottom then
          data[ivm] = node['chaos:bedrock']
        elseif data[ivm] == node['air'] or data[ivm] == node['chaos:weightless_water'] then
          if data[ivm - area.ystride] == node['default:stone'] and math_random(lamp_prob) == 1 then
            data[ivm - area.ystride] = node['chaos:glowing_fungal_stone']
          end

          if data[ivm + area.ystride] == node['default:stone'] and math_random(lamp_prob) == 1 then
            data[ivm + area.ystride] = node['chaos:glowing_fungal_stone']
          end
        end

        ivm = ivm + area.ystride
      end
    end
  end

  return write
end
