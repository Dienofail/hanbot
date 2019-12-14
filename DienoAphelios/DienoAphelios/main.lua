local orb = module.internal("orb");
local evade = module.internal("evade");
local pred = module.internal("pred");
local ts = module.internal('TS');
local common = module.load("daphelios", "common");
local ObjMinion_Type = objManager.minions
local version = 0.01

--Weapons
--Calibrum, Severum, Gravitum, Infernum, Crescendum 

local spellCalibrumQ = {
  range = 1450,
  delay = 0.35,
  width= 60,
  speed = 1800,
  windup=0,
  collision= {hero=true, minion=true, wall=true},
  boundingRadiusMod =0
}

local spellR = {
  range = 1820,
  width = 125,
  speed = 2050,
  delay = 0.5,
  windup=0, 
  collision = {
    wall=true,
  },
  boundingRadiusMod = 0
}

local MainGun ="Calibrum"
local AltGun = "Severum"
local MainGunAmmo = 50
local AltGunAmmo = 50 
local GunOrder = {"Gravitum", "Infernum", "Crescendum"}
local CheckState = ""
local lastDebugPrint = 0
local AArange = 550 
local CalibrumAArange = 650 
local CalibrumCD = {9, 8.25, 7.5, 6.75, 6,6}
local SeverumCD = {10,9,8,8,8,8}
local GravitumCD = {12,11.5,11,10.5,10,10}
local InfernumCD = {9,8,7,6,6,6}
local CrescendumCD = {9,8.25,7.5,6.75,6,6}
local MoonlightDamage = {125, 175, 225}
local CalibrumR, SeverumR, GravitumR, InfernumR, CrescendumR = true,true,true,true,true
local CalibrumT, SeverumT, GravitumT, InfernumT, CrescendumT = 0,0,0,0,0
local LastSwapTime = 0
local menu = menu("daphelios", "Dieno Aphelios")
menu:menu("c", "Combo Settings")
menu.c:header("combogeneral", "Combo settings")
menu.c:slider("calibrumQRange", "Calibrum Q max range", 1375, 900, 1450, 25)
menu.c:boolean("forceQ", "Force Calibrum Q on buff", true)
menu.c:slider("gravitumSnare", "Gravitum minimum number of players for snare", 2, 1, 5, 1)
menu.c:boolean("gravitumOne", "Use Gravitum in 1v1 situations", true)
menu.c:boolean("slowPred", "Use slow pred for Calbirum Q and R", true)
menu.c:slider("ultNum", "Minimum number of players for ult", 3, 1, 5, 1)
menu.c:keybind("ultKey", "Semi-R key", 'T', nil)


menu:menu("f", "Farm settings")
menu.f:header("farmgeneral", "Farm settings")

menu:menu("ks", "Kill steal settings")
menu.ks:header("ksgeneral", "KS settings")
menu.ks:boolean("useRKS", "Use R for KS", true)


menu:menu("swap", "Weapon auto swap")
menu.swap:header("swap", "Autoswap settings")
menu.swap:boolean("usecombo", "Use weapon autoswap in combo", true)
menu.swap:boolean("usefarm", "Use weapon autoswap in farm", true)
menu.swap:boolean("info", "Swap to learn 2nd weapon when safe", true) 
menu.swap:boolean("cal", "Autoswap to proc calibrum mark when safe", true)
--menu.swap.info:set('tooltip', 'You have to swap to offhand weapon at least once to know')


menu:menu("d", "Drawing")
menu.d:header("drawd", "Drawing settings")
menu.d:boolean("drawCalibrumQ", "Draw Calibrum Q range", true)
menu.d:boolean("drawR", "Draw R range", true) 
menu.d:boolean("drawDebug", "Debugging draw", false)
menu.d:boolean("printDebug", "Print debug", false)

ts.load_to_menu(); 

local function DebugPrint(text)
  if menu.d.printDebug:get() then
    print()
  end
end 

local TargetSelectionAA = function(res, obj, dist)
  if dist <= AArange then
    res.obj = obj
    return true
  end
end

local GetTargetAA = function()
  return ts.get_result(TargetSelectionAA, ts.get_active_filter()).obj
end

local TargetSelectionAACalbrium = function(res, obj, dist)
  if dist <= CalibrumAArange then
    res.obj = obj
    return true
  end
end

local GetTargetAACalibrum = function()
  return ts.get_result(TargetSelectionAACalbrium, ts.get_active_filter()).obj
end


local TargetSelectionQCalbrium = function(res, obj, dist)
  if dist <= menu.c.calibrumQRange:get() then
    res.obj = obj
    return true
  end
end

local GetTargetQCalibrum = function()
  return ts.get_result(TargetSelectionQCalbrium, ts.get_active_filter()).obj
end

local TargetSelectionR = function(res, obj, dist)
  if dist <= spellR.range then
    res.obj = obj
    return true
  end
end

local GetTargetR = function()
  return ts.get_result(TargetSelectionR, ts.get_active_filter()).obj
end


function SlowPredQ(target, segment)
    if pred.collision.get_prediction(spellCalibrumQ, segment, target) then 
      return false
    end

    if segment.startPos:dist(segment.endPos) < menu.c.calibrumQRange:get() then 
      return true
    end 

    if pred.trace.linear.hardlock(spellCalibrumQ, segment, target) then 
      return true 
    end

    if pred.trace.linear.hardlockmove(spellCalibrumQ, segment, target) then 
      return true
    end

    if pred.trace.newpath(target, 0.033, 0.500) then 
      return true
    end

end

function tryCalbriumQ(target) 
  local segment = pred.linear.get_prediction(spellCalibrumQ, target, player)
  if menu.c.slowPred:get() then 
      if SlowPredQ(target, segment) and common.IsValidTarget(target) then 
          player:castSpell("pos", 0, vec3(segment.endPos.x, target.y, segment.endPos.y))
      end
  else
      if segment then
        local coll = pred.collision.get_prediction(spellCalibrumQ, segment, target)
        if not coll then
          local endPos = segment.endPos
          if endPos:dist(segment.startPos) > spellE.range then
            return
          end
          player:castSpell("pos", 0, vec3(endPos.x, target.y, endPos.y))
        end
      end
  end
end

local function CountGravitumBuffs()
    buff_counter = 0 
    for _, obj in ipairs(common.GetEnemyHeroes()) do
      if obj then 
        for i = 0, obj.buffManager.count - 1 do
          local buff = obj.buffManager:get(i)
          if buff and buff.valid and buff.name =="ApheliosGravitumDebuff" and buff.source == player and (buff.stacks > 0 or buff.stacks2 > 0) and (buff.endTime - buff.startTime <= 0.4) then
            buff_counter = buffer_counter + 1
          end
        end
      end
    end
    return buff_counter
end 
 
local function IsSafe(range)
  safe = true
  for _, obj in ipairs(common.GetEnemyHeroes()) do
      if obj and common.IsValidTarget(obj) then 
        pred_pos = pred.core.get_pos_after_time(obj, 0.5)
        if player.pos:dist(vec3(pred_pos.x,player.pos.z ,pred_pos.y)) < range then 
          safe = false
        end
      end
    end  
  return safe 
end 

local function CountUltHit(PredictedPos, range)
  counter = 0 
  hit_loc = vec3(PredictedPos.x, player.pos.z, PredictedPos.y)
  travel_time = player.pos:dist(hit_loc)/spellR.speed
  for _, obj in ipairs(common.GetEnemyHeroes()) do
      if obj and common.IsValidTarget(obj) then 
        pred_pos = pred.core.get_pos_after_time(obj, travel_time)
        if hit_loc:dist(vec3(pred_pos.x,player.pos.z ,pred_pos.y)) < range then 
          counter = counter + 1
        end
      end
  end
  return counter
end


local function AutoUlt()
  for _,obj in ipairs(common.GetEnemyHeroesInRange(spellR.range, player.pos)) do
    if common.IsValidTarget(obj) then 
      local segment = pred.linear.get_prediction(spellR, obj, player)
      local seg_vec3 = vec3(segment.endPos.x, obj.z, segment.endPos.y)
      if menu.c.slowPred:get() then 
          if SlowPredR(obj, segment) and common.IsValidTarget(obj) and CountUltHit(seg_vec3, 225) >= menu.c.ultNum:get() then 
              player:castSpell("pos", 3, vec3(segment.endPos.x, obj.z, segment.endPos.y))
          end
      end
    end
  end
end


local function CountCalibrumMarks()
  counter = 0 
    for _, obj in ipairs(common.GetEnemyHeroes()) do
      if obj and common.IsValidTarget(obj) then 
        for i = 0, obj.buffManager.count - 1 do
          local buff = obj.buffManager:get(i)
          if buff and buff.valid and buff.name == "aphelioscalibrumbonusrangedebuff" and  buff.source == player and (buff.stacks > 0 or buff.stacks2 > 0) then
            --print("Buff " .. buff.name .. "active")
            counter = counter + 1 
          end
        end
      end
    end
  return counter
end


local function Combo()
  AATarget = GetTargetAA()
  CalibrumAATarget = GetTargetAACalibrum()
  CalibrumQTarget = GetTargetQCalibrum()
  CalibrumRTarget = GetTargetR()
  --Calibrum logic  


  if MainGun == "Calibrum" and player:spellSlot(0).state == 0 then 
    if common.IsValidTarget(CalibrumQTarget) then
      tryCalbriumQ(CalibrumQTarget)
    end
  end 

  if MainGun == "Calibrum" and IsSafe(400) then 
    for _, obj in ipairs(common.GetEnemyHeroes()) do
      if obj and common.IsValidTarget(obj) then 
        for i = 0, obj.buffManager.count - 1 do
          local buff = obj.buffManager:get(i)
          if buff and buff.valid and buff.name == "aphelioscalibrumbonusrangedebuff" and  buff.source == player and (buff.stacks > 0 or buff.stacks2 > 0) then
            --print("Buff " .. buff.name .. "active")
            player:attack(obj)
          end
        end
      end
    end
  elseif not common.IsValidTarget(AATarget) and AltGun == "Calibrum" and IsSafe(400) then 
    for _, obj in ipairs(common.GetEnemyHeroes()) do
      if obj and common.IsValidTarget(obj) then 
        for i = 0, obj.buffManager.count - 1 do
          local buff = obj.buffManager:get(i)
          if buff and buff.valid and buff.name == "aphelioscalibrumbonusrangedebuff" and  buff.source == player and (buff.stacks > 0 or buff.stacks2 > 0) then
            --print("Buff " .. buff.name .. "active")
            player:castSpell("self", 1)
          end
        end
      end
    end
  elseif AltGun == "Calibrum" and IsSafe(400) then 
    for _, obj in ipairs(common.GetEnemyHeroes()) do
      if obj and common.IsValidTarget(obj) and (obj == CalibrumRTarget or obj==CalibrumQTarget or obj == AATarget) then 
        for i = 0, obj.buffManager.count - 1 do
          local buff = obj.buffManager:get(i)
          if buff and buff.valid and buff.name == "aphelioscalibrumbonusrangedebuff" and  buff.source == player and (buff.stacks > 0 or buff.stacks2 > 0) then
            --print("Buff " .. buff.name .. "active")
            player:castSpell("self", 1)
          end
        end
      end
    end    
  end 

  --Severum logic 
  if MainGun == "Severum" and player:spellSlot(0).state == 0 and common.IsValidTarget(AATarget) then 
    pred_pos = pred.core.get_pos_after_time(AATarget, 0.25)
    --print(pred_pos.x)
    --print(pred_pos.endPos.y)
    --print(player.pos:dist(vec3(pred_pos.x,AATarget.z,pred_pos.y)))
    --print(vec3(pred_pos.x,player.pos.z,pred_pos.y)):dist(player.pos)
    if player.pos:dist(vec3(pred_pos.x,0,pred_pos.y)) < AArange then
      player:castSpell("self", 0)
    end    
  end 

  --Infernum logic 
  if MainGun == "Infernum" and player:spellSlot(0).state == 0 and common.IsValidTarget(AATarget) then 
    pred_pos = pred.core.get_pos_after_time(AATarget, 0.25)
    if common.IsValidTarget(AATarget) and player.pos:dist(vec3(pred_pos.x,0,pred_pos.y)) < AArange then
      player:castSpell("pos", 0, vec3(pred_pos.x, 0, pred_pos.y))
    end 
  end

  --Crescendum logic 
  if MainGun == "Crescendum" and player:spellSlot(0).state == 0 and common.IsValidTarget(CalibrumAATarget) then 
    pred_pos = pred.core.get_pos_after_time(CalibrumAATarget, 0.5)
    if player.pos:dist(vec3(pred_pos.x,0,pred_pos.y)) < CalibrumAArange then
      player:castSpell("pos", 0, vec3(pred_pos.x, player.pos.z, pred_pos.y))
    end 
  end

  --Gravitum logic 
  if MainGun == "Gravitum" and player:spellSlot(0).state == 0 then 
    num_debuffs = CountGravitumBuffs()
    --print("Numdebuffs " .. num_debuffs)
    --print(menu.c.gravitumSnare:get())
    if num_debuffs and num_debuffs >= menu.c.gravitumSnare:get() then 
      player:castSpell("self", 0)
    end 

    if menu.c.gravitumOne:get() and common.IsValidTarget(CalibrumAATarget) and common.tablelength(common.GetEnemyHeroesInRange(700, player)) < 2 and common.CheckBuff(CalibrumAATarget, "ApheliosGravitumDebuff") then
      player:castSpell("self", 0)
    end
  end 

end 

local function CheckWeapons()
  if player:spellSlot(0).name == "ApheliosGravitumQ" then 
    MainGun = "Gravitum"
  elseif player:spellSlot(0).name == "ApheliosSeverumQ" then
    MainGun = "Severum"
  elseif player:spellSlot(0).name == "ApheliosCalibrumQ" then 
    MainGun = "Calibrum"
  elseif player:spellSlot(0).name == "ApheliosInfernumQ" then 
    MainGun = "Infernum"
  elseif player:spellSlot(0).name == "ApheliosCrescendumQ" then 
    MainGun = "Crescendum"
  end 
  MainGunAmmo = player:spellSlot(0).stacks
  for i = 0, player.buffManager.count - 1 do
      local buff = player.buffManager:get(i)
      if buff and buff.valid and buff.source == player and (buff.stacks > 0 or buff.stacks2 > 0) then
        if buff.name == "ApheliosOffHandBuffSeverum" then 
          AltGun = "Severum"
        elseif buff.name == "ApheliosOffHandBuffGravitum" then 
          AltGun = "Gravitum"
        elseif buff.name == "ApheliosOffHandBuffCalibrum" then 
          AltGun = "Calibrum"
        elseif buff.name == "ApheliosOffHandBuffInfernum" then 
          AltGun = "Infernum"
        elseif buff.name == "ApheliosOffHandBuffCrescendum" then 
          AltGun = "Crescendum"
        elseif menu.d.printDebug:get() and game.time - buff.startTime < 5 and buff.endTime - game.time > 0.05 then
          --print(buff.name)
          -- if buff.name == "ApheliosSeverumQ" then 
          --   time_left = buff.endTime - game.time 
          --   orb.core.set_pause_attack(time_left)
          -- end
        end 
      end
  end
end

local CalculateRealCD = function(total_cd)
  --print(current_cd)
  if total_cd and total_cd ~= nil then 
    if total_cd > 0 then 
      real_cd = total_cd - total_cd * player.percentCooldownMod--see if this is correct code
      return real_cd
    end 
  else
    return 8.5
  end
end

local function OnProcessSpell(spell)
  if spell.owner == player then
    spell_level = player:spellSlot(0).level
    if spell.name == "ApheliosGravitumQ" then 
      GravitumT = game.time + CalculateRealCD(GravitumCD[spell_level])
    elseif spell.name == "ApheliosSeverumQ" then 
      SeverumT = game.time + CalculateRealCD(SeverumCD[spell_level])
      orb.core.set_pause_attack(1.5)
    elseif spell.name == "ApheliosCalibrumQ" then 
      CalibrumT = game.time + CalculateRealCD(CalibrumCD[spell_level])
    elseif spell.name == "ApheliosInfernumQ" then 
      InfernumT = game.time + CalculateRealCD(InfernumCD[spell_level])
    elseif spell.name == "ApheliosCrescendumQ" then 
      CrescendumT = game.time + CalculateRealCD(CrescendumCD[spell_level])
    end
  end
end

function CheckSpellState()
  Current_Tick = game.time

  -- --print(Current_Tick - SpiderQcd)
  -- --print(Current_Tick - HumanQcd)

  if Current_Tick - GravitumT > 0 then 
    GravitumR = true
  else
    GravitumR = false
  end
  if Current_Tick - SeverumT > 0 then 
    SeverumR = true
  else
    SeverumR = false
  end
  if Current_Tick - CalibrumT > 0 then 
    CalibrumR = true
  else
    CalibrumR = false
  end
  if Current_Tick - InfernumT > 0 then 
    InfernumR = true
  else
    InfernumR = false
  end
  if Current_Tick - CrescendumT > 0 then 
    CrescendumR = true
  else
    CrescendumR = false
  end
end

local function MainGunReady()
  if MainGun == "Gravitum" and GravitumR then 
    return true 
  end 
  if MainGun == "Severum" and SeverumR then 
    return true 
  end 
  if MainGun == "Calibrum" and CalibrumR then 
    return true 
  end 
  if MainGun == "Infernum" and InfernumR then 
    return true 
  end 
  if MainGun == "Crescendum" and CrescendumR then 
    return true 
  end 
end


local function AltGunReady()
  if AltGun == "Gravitum" and GravitumR then 
    return true 
  end 
  if AltGun == "Severum" and SeverumR then 
    return true 
  end 
  if AltGun == "Calibrum" and CalibrumR then 
    return true 
  end 
  if AltGun == "Infernum" and InfernumR then 
    return true 
  end 
  if AltGun == "Crescendum" and CrescendumR then 
    return true 
  end 
end


local function AutoSwapCombo()
  AATarget = GetTargetAA()
  CalibrumAATarget = GetTargetAACalibrum()
  if player:spellSlot(1).state == 0 then 
    if AltGun == "Calibrum" and not common.IsValidTarget(AATarget) and common.IsValidTarget(CalibrumAATarget) then --Swap to calibrum for range
      player:castSpell("self", 1)
      --print("Cond1")
    elseif AltGun == "Severum" and (player.health/player.maxHealth) < 0.2 and common.IsValidTarget(AATarget) then 
      player:castSpell("self", 1)
    elseif not MainGunReady() and  AltGun == "Infernum" and common.IsValidTarget(AATarget) then --swap to infernum for aoe 
      player:castSpell("self", 1)
      --print("Cond2")
      --print("Cond4")
    elseif not MainGunReady() and AltGunReady() and CountCalibrumMarks() >= 1 and IsSafe(450) then 
      print("Don't swap due to marks")
    elseif not MainGunReady() and AltGunReady() then -- 
      player:castSpell("self", 1)
      --print("Cond3")
    elseif not MainGunReady() and not AltGunReady() then -- specify no gun ready order
      if MainGun == "Calibrum" and not common.IsValidTarget(AATarget) and common.IsValidTarget(CalibrumAATarget) then
        --print("")
      elseif AltGun == "Calibrum" and CountCalibrumMarks() >= 2 and IsSafe(450) then 
        player:castSpell("self", 1)
      elseif AltGun == "Infernum" and common.IsValidTarget(AATarget) and common.tablelength(common.GetEnemyHeroesInRange(200, AATarget)) >= 2 then 
        player:castSpell("self", 1)
      elseif MainGun == "Severum" and (player.health/player.maxHealth) > 0.8 then 
        player:castSpell("self", 1)
        --print("CondB")
      end 
    end
  end
end 



local function DebugPrint()
  if game.time - lastDebugPrint >= 10 then
    print("Printing Q")
    print(player:spellSlot(0).name)
    --print(player:spellSlot(0).state)
    print(player:spellSlot(0).level)
    print(player:spellSlot(0).stacks)
    --print("Printing W")
    --print(player:spellSlot(1).name)
    --print(player:spellSlot(1).state)
    --print(player:spellSlot(1).level)
    --print(player:spellSlot(1).stacks)
    --print("Printing E")
    --print(player:spellSlot(2).name)
    --print(player:spellSlot(2).state)
    --print(player:spellSlot(2).level)
    lastDebugPrint = game.time 
  end 

    -- for _, obj in ipairs(common.GetEnemyHeroes()) do
    --   if obj then 
    --     for i = 0, obj.buffManager.count - 1 do
    --       local buff = obj.buffManager:get(i)
    --       if buff and buff.valid and buff.source == player and (buff.stacks > 0 or buff.stacks2 > 0) and (buff.endTime - buff.startTime <= 10) then
    --         print(buff.name)
    --       end
    --     end
    --   end
    -- end
end 


function SlowPredR(target, segment)
    if segment.startPos:dist(segment.endPos) < 1770 then 
      return true
    end 

    if pred.trace.linear.hardlock(spellR, segment, target) then 
      return true 
    end

    if pred.trace.linear.hardlockmove(spellR, segment, target) then 
      return true
    end

    if pred.trace.newpath(target, 0.033, 0.500) then 
      return true
    end
end

local function OnTick()
  DebugPrint()
  CheckSpellState()
  CheckWeapons()
  if (orb.combat.is_active()) then 
    Combo()
    AutoSwapCombo()
    AutoUlt()
  end

  if menu.c.ultKey:get() then
    AutoUlt()
    Rtarget = GetTargetR()
    if Rtarget and common.IsValidTarget(GetTargetR()) then
      local segment = pred.linear.get_prediction(spellCalibrumQ, Rtarget, player)
      if menu.c.slowPred:get() then 
          if SlowPredR(Rtarget, segment) and common.IsValidTarget(Rtarget) then 
              player:castSpell("pos", 3, vec3(segment.endPos.x, Rtarget.z, segment.endPos.y))
          end
      end
    end
  end 
end


local function OnDraw()
  local coloractive = graphics.argb(255, 25, 185,50)
  local colorCD = graphics.argb(255, 185, 25, 50)
  local player_world_pos = graphics.world_to_screen(player.pos)
  if player.isOnScreen and common.IsValidTarget(player) then
      if player:spellSlot(0).state == 0 and MainGun == "Calibrum" and menu.d.drawCalibrumQ:get() then
          graphics.draw_circle(player.pos, spellCalibrumQ.range, 2, graphics.argb(255, 0, 255, 0), 100)
      end
      if player:spellSlot(3).state == 0 and menu.d.drawR:get() then
          graphics.draw_circle(player.pos, spellCalibrumQ.range, 2, graphics.argb(255, 0, 255, 0), 100)
      end
  end 
  if menu.d.drawDebug:get() then
    if AltGunReady() then 
      graphics.draw_text_2D('AltGun: ' .. tostring(AltGun).. " AltGun ready true"  , 18, player_world_pos.x+55, player_world_pos.y+55, colorCD)
    else
      graphics.draw_text_2D('AltGun: ' .. tostring(AltGun).. " AltGun ready false"  , 18, player_world_pos.x+55, player_world_pos.y+55, colorCD)
    end
    if MainGunReady() then 
      graphics.draw_text_2D('MainGunReady', 18, player_world_pos.x+55, player_world_pos.y+75, colorCD)
    else 
      graphics.draw_text_2D('NotMainGunReady', 18, player_world_pos.x+55, player_world_pos.y+75, colorCD)
    end
  end
end


cb.add(cb.draw, OnDraw)
cb.add(cb.spell, OnProcessSpell)
orb.combat.register_f_pre_tick(OnTick)
chat.print("DienoAlphelios beta version " .. tostring(version) .. " loaded! Please provide feedback to dienofail#1100 on discord")


