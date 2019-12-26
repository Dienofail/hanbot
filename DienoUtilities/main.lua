local orb = module.internal("orb");
local evade = module.internal("evade");
local pred = module.internal("pred");
local ts = module.internal('TS');
local common = module.load("dutilities", "common");
local ObjMinion_Type = objManager.minions
local version = "0.1_rc2"

--Full changelogs are on my discord. Visit hanbot forums, my github, or pm dienofail#1100 on discord if you need an invite.

local lastDebugPrint = 0 
local lastSeen = {}
local lastFlash = {}
local lastTeleport = {}
local lastHeal = {}
local lastBarrier = {}
local lastIgnite = {}
local lastSmite = {}
local lastGhost = {}
local lastPrintTime = 0
local lastCleanse = {}
local lastExhaust = {}
local Choices = {'Top', 'Jungle', 'Mid' , 'ADC', 'Sup'}
local menu = menu("dutilities", "Dieno Utilities")
menu:menu("map", "Minimap settings")
menu.map:header("mapgeneral", "Minimap settings")
menu.map:boolean("maptoggle", "Minimap toggle", true)
menu.map:boolean("drawbox", "Draw box", true)
menu.map:boolean("drawneutral", "Draw neutral", true)
menu.map:boolean("drawlane", "Draw lanes", true)
menu.map:boolean("followplayer", "Minimap follows player", true)
menu.map:slider("offsetx", "^X offset relative to player", 100,-750,750,10)
menu.map:slider("offsety", "^Y offset relative to player", 100,-750,750,10)
menu.map:boolean("fixedloc", "Minimap fixed location", false)
menu.map:slider("offsetfixedx", "^X offset relative to screen", 100,100,3440,25)
menu.map:slider("offsetfixedy", "^Y offset relative to screen", 100,100,1440,25)
menu.map:slider("size", "Box size", 400, 200, 600, 25)


menu:menu("chat", "Enemy summoner chat helper")
menu.chat:header("chatgeneral", "Enemy summoner chat helper settings")
menu.chat:boolean("chattoggle", "Enable summoner chat helper toggle", true)
menu.chat:keybind("chatkeybind", "Print timers in chat", 'Z', '')
menu.chat:boolean("prostyle", "Look like a pro (no colon)", true)
menu.chat:boolean("flashteleport","Print only flash/teleport", false)
menu.chat:boolean("round", "Round to nearest 5s", true)
menu.chat:boolean("printroles", "Try to print roles", false)
for idx, obj in ipairs(common.GetEnemyHeroes()) do 
    menu.chat:dropdown('role ' .. obj.charName, obj.charName .. " role" ,1, {'Top', 'Jungle', 'Mid' , 'ADC', 'Sup'})
end

for idx, obj in ipairs(common.GetEnemyHeroes()) do 
    menu.chat:boolean('track ' .. obj.charName,"Tracking " .. obj.charName .. " CDs", true)
end

menu:menu("misc", "Misc. keybinds & functions")
menu.misc:header("miscd", "Misc. settings")
if player.charName == "Twitch" then
  menu.misc:keybind('twitch', "Twitch stealth and back", 'T', '')
end

ts.load_to_menu(); 
local excluded_minions = {
  ["CampRespawn"] = true,
  ["PlantMasterMinion"] = true,
  ["PlantHealth"] = true,
  ["PlantSatchel"] = true,
  ["PlantVision"] = true
}

local function valid_minion(minion)
  return minion and minion.type == TYPE_MINION and not minion.isDead and minion.health > 0 and minion.maxHealth > 100 and
    minion.maxHealth < 10000 and
    not minion.name:find("Ward") and
    not excluded_minions[minion.name]
end

local function CalculateRealCD(c_cd)
  --print(current_cd)
  if c_cd and c_cd > 0 then 
      f_cd = c_cd - c_cd * (-1*player.percentCooldownMod)--see if this is correct code
      return f_cd
  else return 0
  end
end


function SecondsToClock(seconds)
  local seconds = tonumber(seconds)

  if menu.chat.round:get() then 
      seconds = common.round(seconds/5)*5
  end

  if seconds <= 0 then
    return "00:00";
  else
    if not menu.chat.prostyle:get() then 
        hours = string.format("%02.f", math.floor(seconds/3600));
        mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
        secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
        return mins..":"..secs
    else
        hours = string.format("%02.f", math.floor(seconds/3600));
        if math.floor(seconds/60 - (hours*60)) < 10 then 
            mins = string.format("%01.f", math.floor(seconds/60 - (hours*60)));
        else
            mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
        end
        secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
        return mins..""..secs
    end
  end
end

local function OnCreateMinion(obj)  

end

local function OnDeleteMinion(obj)  

end


local function DebugPrint()
  if game.time - lastDebugPrint >= 2 then
    -- slot_num = 5
    -- print("Printing slot " .. tostring(slot_num))
    -- print("Name: " ..  player:spellSlot(slot_num).name)
    -- print(player:spellSlot(slot_num).state)
    -- print("Level: " .. tostring(player:spellSlot(slot_num).level))
    --print("CD: " .. tostring(common.round(player:spellSlot(0).cooldown,2)))
    --print(player:spellSlot(0).stacks)
    --print("Printing W")
    --print(player:spellSlot(1).name)
    --print(player:spellSlot(1).state)
    --print(player:spellSlot(1).level)
    --print(player:spellSlot(1).stacks)
    --print("Printing E")
    --print(player:spellSlot(2).name)
    --print(player:spellSlot(2).state)
    --print(player:spellSlot(2).level)
    --lastDebugPrint = game.time 
  end 
end


local function OnProcessSpell(spell)
  if spell.owner.ptr == player.ptr and spell.owner.team == TEAM_ALLY then 
      --print(tostring(spell.name) .. " " .. tostring(spell.charName) ..  ' ' .. tostring(spell.slot))
  end
  target_team = TEAM_ENEMY
  if spell.owner and spell.name == "SummonerFlash" and spell.owner.team == target_team then 
    lastFlash[spell.owner.ptr] = game.time 
    --print("Flash detected")
  elseif spell.name and spell.name == "SummonerHeal" and spell.owner.team == target_team then 
    lastHeal[spell.owner.ptr] = game.time
  elseif spell.name and  spell.name == "SummonerTeleport" and spell.owner.team == target_team then 
    lastTeleport[spell.owner.ptr] = game.time
  elseif spell.name and spell.name == "SummonerBarrier" and spell.owner.team == target_team then 
    lastBarrier[spell.owner.ptr] = game.time
  elseif spell.name and spell.name == "SummonerIgnite" and spell.owner.team == target_team then
    lastIgnite[spell.owner.ptr] = game.time
  elseif spell.name and spell.name == "SummonerBoost" and spell.owner.team == target_team then 
    lastCleanse[spell.owner.ptr] = game.time
  elseif spell.name and spell.name == "SummonerExhaust" and spell.owner.team == target_team then 
    lastExhaust[spell.owner.ptr] = game.time
  elseif spell.name and spell.name == "SummonerHaste" and spell.owner.team == target_team then 
    lastGhost[spell.owner.ptr] = game.time
  end 
end

local function ConstructString(enemy_ptr)
    str = ""
    if lastFlash[enemy_ptr] and game.time - lastFlash[enemy_ptr] < 300 then 
        str = str .. " Flash " .. SecondsToClock(lastFlash[enemy_ptr]+300)
        --print("Flash str " .. str)
    end

    if lastTeleport[enemy_ptr] and game.time - lastTeleport[enemy_ptr] < 360 then 
        str = str .. " Teleport " .. tostring(SecondsToClock(lastTeleport[enemy_ptr]+360))
    end

    if not menu.chat.flashteleport:get() then
      if lastHeal[enemy_ptr] and game.time - lastHeal[enemy_ptr] < 240 then 
          str = str .. " Heal " .. tostring(SecondsToClock(lastHeal[enemy_ptr]+240))
          --print("Heal str " .. str)
      end

      if lastBarrier[enemy_ptr] and game.time - lastBarrier[enemy_ptr] < 180 then 
          str = str .. " Barrier " .. tostring(SecondsToClock( lastBarrier[enemy_ptr]+180))
      end

      if lastCleanse[enemy_ptr] and game.time - lastCleanse[enemy_ptr] < 210 then 
          str = str .. " Cleanse " .. tostring(SecondsToClock(lastCleanse[enemy_ptr]+210))
      end

      if lastIgnite[enemy_ptr] and game.time - lastIgnite[enemy_ptr] < 180 then 
          str = str .. " Ignite " .. tostring(SecondsToClock(lastIgnite[enemy_ptr]+180))
      end

      if lastExhaust[enemy_ptr] and game.time - lastExhaust[enemy_ptr] < 210 then 
          str = str .. " Exhaust " .. tostring(SecondsToClock(lastExhaust[enemy_ptr]+210))
      end
      
      if lastGhost[enemy_ptr] and game.time - lastGhost[enemy_ptr] < 180 then 
          str = str .. " Ghost " .. tostring(SecondsToClock(lastGhost[enemy_ptr]+180))
      end
    end

    return str 
end

local function OnTick()
  DebugPrint()
  if player.charName == "Twitch" and menu.misc.twitch:get() then   
    if player:spellSlot(13).state == 0 and player:spellSlot(0).state == 0 then 
      player:castSpell("self", 0)
      orb.core.set_pause_attack(0.25)
      common.DelayAction(function() player:castSpell("self", 13) end, 0.05)
    end
  end

  if menu.chat.chattoggle:get() and menu.chat.chatkeybind:get() then 
    final_str = ""
    --print("calling chat toggle")
    for idx, obj in ipairs(common.GetEnemyHeroes()) do 
      if obj then
        champ_str = ""
        CD_str = ConstructString(obj.ptr)
        if string.len(CD_str) >= 1 and menu.chat['track ' .. obj.charName]:get() then
          if not menu.chat.printroles:get() then 
            champ_str = tostring(obj.charName) .. " " .. CD_str .. " "
            final_str = final_str .. champ_str .. " "
          else
            champ_str = Choices[menu.chat['role ' .. obj.charName]:get()] .. " " .. CD_str .. " "
            final_str = final_str .. champ_str .. " "
          end
        end
      end 
    --print(final_str)
    end
    --print(final_str)
    --keyboard.setClipboardText(final_str)
    if game.time - lastPrintTime >= 5 then 
      chat.send(final_str)
      lastPrintTime = game.time 
    end
  end

end


-- local function CalcOffset(target_pos, size, xoffset, yoffset)


-- end

local function CalcMinimapCorners(size, xoffset, yoffset)
  local player_world_pos = graphics.world_to_screen(player.pos)
  local center_x = player_world_pos.x + xoffset 
  local center_y = player_world_pos.y + yoffset 
  local half_offset = size/2
  local TLcorner = vec2(center_x-half_offset, center_y-half_offset)
  local TRcorner = vec2(center_x+half_offset, center_y-half_offset)
  local BLcorner = vec2(center_x-half_offset, center_y+half_offset)
  local BRcorner = vec2(center_x+half_offset, center_y+half_offset)
  return {BL=BLcorner, BR=BRcorner, TL=TLcorner, TR=TRcorner, CX = center_x, CY = center_y}

end

local function CalcOffsets(size, xoffset, yoffset)  
  local center_x = xoffset 
  local center_y = yoffset 
  local half_offset = size/2
  local TLcorner = vec2(center_x-half_offset, center_y-half_offset)
  local TRcorner = vec2(center_x+half_offset, center_y-half_offset)
  local BLcorner = vec2(center_x-half_offset, center_y+half_offset)
  local BRcorner = vec2(center_x+half_offset, center_y+half_offset)
  return {BL=BLcorner, BR=BRcorner, TL=TLcorner, TR=TRcorner, CX = center_x, CY = center_y}
end  

local function vec2minimap(invec,map_corners, map_size)
  x_ratio = invec.x/15000
  y_ratio = invec.y/15000 
  return vec2(map_corners.BL.x +x_ratio*map_size, map_corners.BL.y - y_ratio*map_size)
end


local function OnDraw()
  alpha = 255 
  local coloractive = graphics.argb(alpha, 25, 185,50)
  local colorCD = graphics.argb(alpha, 185, 25, 50)
  local colorwhite = graphics.argb(alpha, 255, 255, 255)
  local colorblue = graphics.argb(alpha, 0, 0, 204)
  local colorbaron = graphics.argb(alpha, 153, 51, 153)
  local colorred =  graphics.argb(alpha, 204,0,0)
  local colordragon = graphics.argb(alpha,204, 51, 0)
  local colorfriendly = graphics.argb(alpha,0, 153, 255)
  local colorlanes =  graphics.argb(common.round(alpha/3), 255, 255, 255)
  local colormissing = graphics.argb(alpha, 153,153,102)
  local player_world_pos = graphics.world_to_screen(player.pos)
  local cursor_world_pos = graphics.world_to_screen(mousePos)
  local baron = vec2(4954, 10419)
  local dragon = vec2(9843, 4379)
  local blue_blue = vec2(3847, 7859)
  local blue_red = vec2(7777, 4018)
  local red_blue = vec2(10980, 6992)
  local red_red = vec2(7100, 10840)
  local topa = vec2(1637,5177)
  local topb = vec2(1892, 11692)
  local topc = vec2(3277, 12879)
  local topd = vec2(9809, 13617)

  local midlefta = vec2(3795, 4501)
  local midleftb = vec2(6311, 7248)
  local midleftc = vec2(7500,8359)
  local midleftd = vec2(10382, 10941)


  local midrighta = vec2(4531,3804 )
  local midrightb = vec2(7255, 6557)
  local midrightc = vec2(8616,7552)
  local midrightd = vec2(11104, 10358)


  local bota = vec2(4924, 1810)
  local botb = vec2(11235, 1889)
  local botc = vec2(12917, 3297)
  local botd = vec2(13118, 9973)
  if mousePos then 
    --graphics.draw_text_2D('X ' .. tostring(mousePos.x) .. " " .. tostring(mousePos.y) .. " "..  tostring(mousePos.z), 14, cursor_world_pos.x-22, cursor_world_pos.y+65, coloractive)
  end



  if common.IsValidTarget(player) then
    if menu.map.maptoggle:get() then 
      local map_size = menu.map.size:get()
      if menu.map.followplayer:get() then 
        map_corners = CalcMinimapCorners(menu.map.size:get(), menu.map.offsetx:get(), menu.map.offsety:get())
      else
        map_corners = CalcOffsets(menu.map.size:get(), menu.map.offsetfixedx:get(), menu.map.offsetfixedy:get())
      end 
      --graphics.draw_rectangle_2D(map_corners.TL.x, map_corners.TL.y, menu.map.size:get()/2, menu.map.size:get()/2, 2, 0xFFFFFFFF)
      --graphics.draw_circle_2D(map_corners.CX, map_corners.CY,5, 2, 0xFFFFFFFF, 4)
      --graphics.draw_circle_2D(map_corners.BL.x, map_corners.BL.y,5, 2, coloractive, 4)
      --graphics.draw_circle_2D(map_corners.BR.x, map_corners.BR.y,5, 2, colorCD, 4)
      --graphics.draw_circle_2D(map_corners.TR.x, map_corners.TR.y,5, 4, coloractive, 4)
      --graphics.draw_circle_2D(map_corners.TL.x, map_corners.TL.y,5, 4, colorCD, 4)
      local v = vec2.array(5)
      v[0].x = map_corners.BL.x
      v[0].y = map_corners.BL.y
      v[1].x = map_corners.BR.x
      v[1].y = map_corners.BR.y
      v[2].x = map_corners.TR.x
      v[2].y = map_corners.TR.y
      v[3].x = map_corners.TL.x
      v[3].y = map_corners.TL.y 
      v[4].x = map_corners.BL.x
      v[4].y = map_corners.BL.y    
      if menu.map.drawbox:get() then 
        graphics.draw_line_strip_2D(v, 2, colorlanes, 5)
      end

      if menu.map.drawneutral:get() then 
        graphics.draw_circle_2D(vec2minimap(baron,map_corners, map_size).x, vec2minimap(baron,map_corners, map_size).y, 4, 2, colorbaron, 2)
        graphics.draw_circle_2D(vec2minimap(dragon,map_corners, map_size).x, vec2minimap(dragon,map_corners, map_size).y, 4, 2, colordragon, 2)
        graphics.draw_circle_2D(vec2minimap(blue_blue,map_corners, map_size).x, vec2minimap(blue_blue,map_corners, map_size).y, 4, 2, colorblue, 2)
        graphics.draw_circle_2D(vec2minimap(red_blue,map_corners, map_size).x, vec2minimap(red_blue,map_corners, map_size).y, 4, 2, colorblue, 2)
        graphics.draw_circle_2D(vec2minimap(red_red,map_corners, map_size).x, vec2minimap(red_red,map_corners, map_size).y, 4, 2, colorred, 2)
        graphics.draw_circle_2D(vec2minimap(blue_red,map_corners, map_size).x, vec2minimap(blue_red,map_corners, map_size).y, 4, 2, colorred, 2)
      end 

      if menu.map.drawlane:get() then 
        graphics.draw_line_2D(vec2minimap(topa,map_corners, map_size).x, vec2minimap(topa,map_corners, map_size).y, vec2minimap(topb,map_corners, map_size).x, vec2minimap(topb,map_corners, map_size).y, 3, colorlanes)
        graphics.draw_line_2D(vec2minimap(topc,map_corners, map_size).x, vec2minimap(topc,map_corners, map_size).y, vec2minimap(topd,map_corners, map_size).x, vec2minimap(topd,map_corners, map_size).y, 3, colorlanes)

        graphics.draw_line_2D(vec2minimap(bota,map_corners, map_size).x, vec2minimap(bota,map_corners, map_size).y, vec2minimap(botb,map_corners, map_size).x, vec2minimap(botb,map_corners, map_size).y, 3, colorlanes)
        graphics.draw_line_2D(vec2minimap(botc,map_corners, map_size).x, vec2minimap(botc,map_corners, map_size).y, vec2minimap(botd,map_corners, map_size).x, vec2minimap(botd,map_corners, map_size).y, 3, colorlanes)


        graphics.draw_line_2D(vec2minimap(midlefta,map_corners, map_size).x, vec2minimap(midlefta,map_corners, map_size).y, vec2minimap(midleftb,map_corners, map_size).x, vec2minimap(midleftb,map_corners, map_size).y, 3, colorlanes)
        graphics.draw_line_2D(vec2minimap(midleftc,map_corners, map_size).x, vec2minimap(midleftc,map_corners, map_size).y, vec2minimap(midleftd,map_corners, map_size).x, vec2minimap(midleftd,map_corners, map_size).y, 3, colorlanes)
      
        graphics.draw_line_2D(vec2minimap(midrighta,map_corners, map_size).x, vec2minimap(midrighta,map_corners, map_size).y, vec2minimap(midrightb,map_corners, map_size).x, vec2minimap(midrightb,map_corners, map_size).y, 3, colorlanes)
        graphics.draw_line_2D(vec2minimap(midrightc,map_corners, map_size).x, vec2minimap(midrightc,map_corners, map_size).y, vec2minimap(midrightd,map_corners, map_size).x, vec2minimap(midrightd,map_corners, map_size).y, 3, colorlanes)

      end 


      if player.pos then 
        x_ratio = player.pos.x/15000
        y_ratio = player.pos.z/15000
        graphics.draw_circle_2D(map_corners.BL.x +x_ratio*map_size, map_corners.BL.y - y_ratio*map_size,5, 4, coloractive, 4)
        s = string.sub(player.charName,1,2)
        graphics.draw_text_2D(s,14, map_corners.BL.x +x_ratio*map_size-2, map_corners.BL.y - y_ratio*map_size+17, 0xFFFFFFFF)
        healthPerc = common.round(common.GetPercentHealth(player))
        graphics.draw_text_2D(tostring(healthPerc),10, map_corners.BL.x +x_ratio*map_size-15, map_corners.BL.y - y_ratio*map_size+15, 0xFFFFFFFF)
        manaPerc = common.round(common.GetPercentMana(player))
        graphics.draw_text_2D(tostring(manaPerc),10, map_corners.BL.x +x_ratio*map_size-15, map_corners.BL.y - y_ratio*map_size+22, 0xFFFFFFFF)
      end 

      for idx, obj in ipairs(common.GetEnemyHeroes()) do 
        if obj and common.IsValidTarget(obj) then 
          objvec = vec2minimap(vec2(obj.pos.x, obj.pos.z), map_corners, map_size)
          graphics.draw_circle_2D(objvec.x,objvec.y,5, 4, colorCD, 4)
          s = string.sub(obj.charName,1,2)
          graphics.draw_text_2D(s,14, objvec.x-2,objvec.y+17, colorCD)
          healthPerc = common.round(common.GetPercentHealth(obj))
          graphics.draw_text_2D(tostring(healthPerc),10, objvec.x-15,objvec.y+15, colorCD)
          manaPerc = common.round(common.GetPercentMana(obj))
          graphics.draw_text_2D(tostring(manaPerc),10, objvec.x-15,objvec.y+22, colorCD)
          lastSeen[obj.ptr] = {}
          lastSeen[obj.ptr].time = game.time 
          lastSeen[obj.ptr].loc = obj.pos
          lastSeen[obj.ptr].health = healthPerc
          lastSeen[obj.ptr].mana = manaPerc
          lastSeen[obj.ptr].charName = obj.charName
        elseif lastSeen[obj.ptr] and game.time - lastSeen[obj.ptr].time < 120 and not obj.isDead then 
          objvec = vec2minimap(vec2(lastSeen[obj.ptr].loc.x, lastSeen[obj.ptr].loc.z), map_corners, map_size)
          graphics.draw_circle_2D(objvec.x,objvec.y,5, 4, colormissing, 4)
          s = string.sub(lastSeen[obj.ptr].charName,1,2)
          graphics.draw_text_2D(s,14, objvec.x-2,objvec.y+17, colormissing)
          healthPerc = common.round(lastSeen[obj.ptr].health)
          graphics.draw_text_2D(tostring(healthPerc),10, objvec.x-15,objvec.y+15, colormissing)
          manaPerc = common.round(lastSeen[obj.ptr].mana)
          graphics.draw_text_2D(tostring(manaPerc),10, objvec.x-15,objvec.y+22, colormissing)
          time_elapsed = tostring(common.round(game.time -lastSeen[obj.ptr].time))
          graphics.draw_text_2D(time_elapsed,14, objvec.x-15,objvec.y-6, colormissing)
        end
      end

      for idx, obj in ipairs(common.GetAllyHeroes()) do 
        if obj and common.IsValidTarget(obj) and obj.charName ~= player.charName then 
          objvec = vec2minimap(vec2(obj.pos.x, obj.pos.z), map_corners, map_size)
          graphics.draw_circle_2D(objvec.x,objvec.y,5, 4, colorfriendly, 4)
          s = string.sub(obj.charName,1,2)
          graphics.draw_text_2D(s,14, objvec.x-2,objvec.y+17, colorfriendly)
          healthPerc = common.round(common.GetPercentHealth(obj))
          graphics.draw_text_2D(tostring(healthPerc),10, objvec.x-15,objvec.y+15, colorfriendly)
          manaPerc = common.round(common.GetPercentMana(obj))
          graphics.draw_text_2D(tostring(manaPerc),10, objvec.x-15,objvec.y+22, colorfriendly)
        end
      end


      --graphics.draw_line_2D(map_corners.BL.x,map_corners.BL.y,map_corners.TL.x, map_corners.TL.y, 4, 0xFFFFFFFF )
    end
  end 
end

cb.add(cb.draw, OnDraw)
cb.add(cb.spell, OnProcessSpell)
--cb.add(cb.tick, OnTick)
cb.add(cb.create_minion, OnCreateMinion)
cb.add(cb.delete_minion, OnDeleteMinion)

--cb.add(cb.delete_minion, OnDeleteMinion)
orb.combat.register_f_pre_tick(OnTick)
chat.print("DienoUtilities beta version " .. tostring(version) .. " loaded! Please provide feedback to dienofail#1100 on discord")