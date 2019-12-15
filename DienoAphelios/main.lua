local orb = module.internal("orb");
local evade = module.internal("evade");
local pred = module.internal("pred");
local ts = module.internal('TS');
local common = module.load("daphelios", "common");
local ObjMinion_Type = objManager.minions
local version = 0.02

--Changelogs are on my discord. Visit hanbot forums, my github, or pm dienofail#1100 on discord if you need an invite.

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
local LastWeaponReload = 0 
local CalibrumAArange = 650 
local CalibrumCD = {9, 8.25, 7.5, 6.75, 6,6}
local SeverumCD = {10,9,8,8,8,8}
local GravitumCD = {12,11.5,11,10.5,10,10}
local InfernumCD = {9,8,7,6,6,6}
local CrescendumCD = {9,8.25,7.5,6.75,6,6}
local MoonlightDamage = {125, 175, 225}
local CrescendumBuffs = 0 
local CalibrumR, SeverumR, GravitumR, InfernumR, CrescendumR = true,true,true,true,true
local CalibrumT, SeverumT, GravitumT, InfernumT, CrescendumT = 0,0,0,0,0
local LastSwapTime = 0
local menu = menu("daphelios", "Dieno Aphelios")
menu:menu("c", "Combo Settings")
menu.c:header("combogeneral", "Combo settings")
menu.c:slider("calibrumQRange", "Calibrum Q max range", 1375, 900, 1450, 25)
menu.c:boolean("forceQ", "Force Calibrum Q on buff", true)
menu.c:slider("gravitumSnare", "Gravitum min # hit for snare", 2, 1, 5, 1)
menu.c:boolean("gravitumOne", "Use Gravitum in 1v1 situations", true)
menu.c:boolean("slowPred", "Use slow pred for Calbirum Q and R", true)
menu.c:slider("ultNum", "Minimum num # hit for combo ult", 3, 1, 5, 1)
menu.c:boolean("forceInfernumR", "Force infernum R if possible", true)
menu.c:boolean("forceGravitumR", "^Force gravitum R if infernum not possible", true)
menu.c:boolean("forceSeverumR", "^^Force severum R if low health", true)
menu.c:keybind("ultKey", "Semi-R key", 'T', nil)
menu.c:boolean("pause", "(ADV USERS) Pause orb for wep swap", true)


menu:menu("f", "Farm settings")
menu.f:header("farmgeneral", "Farm settings")
menu.f:boolean("useQ", "Use weapon Q skills during farm", true)
menu.f:boolean("useQslow", "^ Use gravitum snare during farm", true)
menu.f:slider("manaManager", "Farm mana manager", 35, 1, 100, 1)

menu:menu("ks", "Kill steal settings")
menu.ks:header("ksgeneral", "KS settings")
menu.ks:boolean("useQ", "Use calibrum Q to KS if safe", true)
menu.ks:boolean("useQMark", "Include mark in Q damage calc", true)
menu.ks:boolean("useMark", "Use calibrum mark to KS if safe", true)
menu.ks:boolean("useR", "(Leave False) Use R KS ONE KILL Minimum", false)
menu.ks:boolean("useRsmart", "Use R KS ONE KILL + ONE HIT Minimum", true)
menu.ks:boolean("swap", "Swap weapons to KS if possible", true)

menu:menu("swap", "Weapon auto swap")
menu.swap:header("swap", "Autoswap settings")
menu.swap:boolean("usecombo", "Use weapon autoswap in combo", true)
menu.swap:boolean("usefarm", "Use weapon autoswap in farm", true)
menu.swap:boolean("cal", "Autoswap to proc calibrum mark when safe", true)
menu.swap:boolean("crescendum", "Force crescendum & (infer/sever) stacking", true)
menu.swap:slider("stacks", "^Force >X Crescendum stacks before swap", 3,1,15,1)
menu.swap:boolean("crescendumcal", "^^Force calibrum + crescendum stacking", false)

--menu.swap.info:set('tooltip', 'You have to swap to offhand weapon at least once to know')


menu:menu("d", "Drawing")
menu.d:header("drawd", "Drawing settings")
menu.d:boolean("drawCalibrum", "Draw Calibrum range", true)
menu.d:boolean("drawCalibrumX", "^ Only if Calibrum is main/alt weapon", false)
menu.d:boolean("drawCalibrumQ", "Draw Calibrum Q range", true)
menu.d:boolean("drawR", "Draw R range", true) 
menu.d:boolean("drawRcounter", "Draw R hit counter (WARNING: FPS DROP!)", false) 
menu.d:boolean("drawDebug", "Debugging draw", false)
menu.d:boolean("printDebug", "Print debug", false)
menu.d:keybind("debugKey", "Debug print key", '-', nil)

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

local TargetSelectionAA = function(res, obj, dist)
  if dist > AArange+obj.boundingRadius  then 
    return false 
  end 

  if dist <= AArange then
    res.obj = obj
    return true
  end
end

local GetTargetAA = function()
  return ts.get_result(TargetSelectionAA).obj
end

local TargetSelectionAACalbrium = function(res, obj, dist)
  if dist > CalibrumAArange+obj.boundingRadius then 
    return false 
  end 


  if dist <= CalibrumAArange+25 then
    res.obj = obj
    return true
  end
end

local GetTargetAACalibrum = function()
  return ts.get_result(TargetSelectionAACalbrium).obj
end


local TargetSelectionQCalbrium = function(res, obj, dist)
  if dist <= menu.c.calibrumQRange:get()+obj.boundingRadius then
    res.obj = obj
    return true
  end
end

local GetTargetQCalibrum = function()
  return ts.get_result(TargetSelectionQCalbrium, ts.get_active_filter()).obj
end

local TargetSelectionR = function(res, obj, dist)
  if dist <= spellR.range+obj.boundingRadius then
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
            buff_counter = buff_counter + 1
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

  if IsSafe(375) then 
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
  elseif not common.IsValidTarget(AATarget) and AltGun == "Calibrum" and IsSafe(300) then 
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
    pred_pos = pred.core.get_pos_after_time(CalibrumAATarget, 0.25)
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
    if menu.c.gravitumOne:get() and common.IsValidTarget(AATarget) and common.tablelength(common.GetEnemyHeroesInRange(700, player)) < 2 and common.CheckBuff(AATarget, "ApheliosGravitumDebuff") then
      player:castSpell("self", 0)
    end
    if menu.c.gravitumOne:get() and common.IsValidTarget(CalibrumQTarget) and common.tablelength(common.GetEnemyHeroesInRange(700, player)) < 2 and common.CheckBuff(CalibrumQTarget, "ApheliosGravitumDebuff") then
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
  crescendumfound = false

  if CrescendumBuffs == nil then 
    CrescendumBuffs = 0 
  end 
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

        if buff.name == "aphelioscrescendumorbitmanager" and buff.endTime - game.time >= 0.25 then 
          CrescendumBuffs = buff.stacks2 
          crescendumfound = true
        elseif buff.name == "aphelioscrescendumorbitmanager" and buff.endTime - game.time < 0.25 then  
          CrescendumBuffs = 0 
          crescendumfound = true
        end
      end
  end
  if not crescendumfound then 
    CrescendumBuffs =0 
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

local qSpells = {ApheliosCalibrumQ = true,ApheliosGravitumQ= true,ApheliosInfernumQ = true,ApheliosCrescendumQ = true,ApheliosSeverumQ = true}

local function OnProcessSpell(spell)
  if spell.owner.ptr == player.ptr then
    spell_level = player:spellSlot(0).level

    if spell.isBasicAttack and player.sar==1 then
      if menu.c.pause:get() then 
        orb.core.set_pause_attack(0.99)
      else
        orb.core.set_pause_attack(0.15)
      end
    end

    if qSpells[spell.name] and player.sar<10 then -- <= ??
      --start timer
      if menu.c.pause:get() and spell.name ~= "ApheliosCrescendumQ" then 
        orb.core.set_pause_attack(0.99)
      else
        orb.core.set_pause_attack(0.125)
      end
    end

    if spell.name == "ApheliosGravitumQ" then 
      GravitumT = game.time + CalculateRealCD(GravitumCD[spell_level])
    elseif spell.name == "ApheliosSeverumQ" and MainGun == "Severum" then 
      SeverumT = game.time + CalculateRealCD(SeverumCD[spell_level])
      orb.core.set_pause_attack(1.75)
    elseif spell.name == "ApheliosCalibrumQ" then 
      CalibrumT = game.time + CalculateRealCD(CalibrumCD[spell_level])
    elseif spell.name == "ApheliosInfernumQ" then 
      InfernumT = game.time + CalculateRealCD(InfernumCD[spell_level])
    elseif spell.name == "ApheliosCrescendumQ" then 
      CrescendumT = game.time + CalculateRealCD(CrescendumCD[spell_level])
    end

    -- if menu.d.printDebug:get() and MainGunAmmo < 3 or MainGunAmmo >= 49 then 
    --   print("Current process spell stacks .." .. tostring(MainGunAmmo))
    --   print(spell.name)
    -- end
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
    elseif MainGunReady() and AltGunReady() and MainGun == "Crescendum" and (AltGun == "Severum" or AltGun == "Infernum" or (AltGun == "Calibrum" and menu.swap.crescendumcal:get())) and menu.swap.stacks:get() < menu.swap.stacks:get() then
      --print("Cond2")
      --print("Cond4")
      player:castSpell("self", 1)
      if menu.d.printDebug:get() then 
        print("Swap to stack crescendum mode 1")
      end
    elseif common.IsValidTarget(CalibrumAATarget) and not MainGunReady() and AltGunReady() and CountCalibrumMarks() >= 1 and IsSafe(450) and MainGun == "Calibrum" then 
      if menu.d.printDebug:get() then 
        print("Don't swap due to actived calibrum marks")
      end
    elseif not MainGunReady() and common.IsValidTarget(AATarget) and (MainGun == "Severum" or MainGun == "Infernum" or (MainGun == "Calibrum" and menu.swap.crescendumcal:get())) and AltGun == "Crescendum" and AltGunReady() and menu.swap.crescendum:get() and CrescendumBuffs >= menu.swap.stacks:get() then 
       player:castSpell("self", 1)
      if menu.d.printDebug:get() then 
        print("Swap due to excess crescendum stacking")
      end
    -- elseif not MainGunReady() and AltGunReady() and common.IsValidTarget(AATarget) and (MainGun == "Severum" or MainGun == "Infernum" or (MainGun == "Calibrum" and menu.swap.crescendumcal:get())) and AltGun == "Crescendum" and AltGunReady() and menu.swap.crescendum:get() and CrescendumBuffs < menu.swap.stacks:get() then 
    --   if menu.d.printDebug:get() then 
    --     print("Don't swap due to forced crescendum stacking")
    --   end
    elseif common.IsValidTarget(CalibrumAATarget) and (AltGun == "Severum" or AltGun == "Infernum" or (AltGun == "Calibrum" and menu.swap.crescendumcal:get())) and MainGun == "Crescendum" and not MainGunReady() and menu.swap.crescendum:get() and CrescendumBuffs < menu.swap.stacks:get() then 
      if menu.d.printDebug:get() then 
        print("Swap to stack crescendum mode 2")
      end
      player:castSpell("self", 1)
    -- elseif not MainGunReady() and AltGunReady() and not (AltGun == "Crescendum" and CrescendumBuffs < menu.swap.stacks:get() and menu.swap.crescendum:get()) and not (MainGun == "Severum" or MainGun == "Infernum" or (MainGun == "Calibrum" and menu.swap.crescendumcal:get())) then -- 
    --   if menu.d.printDebug:get() then 
    --     print("Prevented swap out of Ccrescendum due to forced crescendum stacking2")
    --   end
    elseif not MainGunReady() and AltGunReady() then -- 
      player:castSpell("self", 1)
    elseif not MainGunReady() and not AltGunReady() then -- specify no gun ready order
      if AltGun == "Calibrum" and not common.IsValidTarget(AATarget) and common.IsValidTarget(CalibrumAATarget) then
        player:castSpell("self", 1)
        --print("")
      elseif AltGun == "Calibrum" and CountCalibrumMarks() >= 2 and IsSafe(450) and common.IsValidTarget(CalibrumAATarget) then 
        player:castSpell("self", 1)
      elseif AltGun == "Infernum" and common.IsValidTarget(AATarget) and common.tablelength(common.GetEnemyHeroesInRange(200, AATarget)) >= 2 then 
        player:castSpell("self", 1)
      elseif MainGun == "Severum" and (player.health/player.maxHealth) > 0.8 then 
        player:castSpell("self", 1)
      elseif MainGun == "Crescendum" and (AltGun == "Severum" or AltGun == "Infernum" or (AltGun == "Calibrum" and menu.swap.crescendumcal:get())) and common.IsValidTarget(CalibrumAATarget) and CrescendumBuffs < menu.swap.stacks:get() then 
        player:castSpell("self", 1)
        --print("CondB")
      elseif AltGun == "Crescendum" and (MainGun == "Severum" or MainGun == "Infernum" or (MainGun == "Calibrum" and menu.swap.crescendumcal:get())) and common.IsValidTarget(CalibrumAATarget) and CrescendumBuffs >= menu.swap.stacks:get() then 
        player:castSpell("self", 1)
      end 
    end
  end
end 

local function KillMob(mob)
  local EnoughQMana = ((player.mana/player.maxMana)*100 > menu.f.manaManager:get())

  if menu.d.drawDebug:get() and common.IsValidTarget(mob) then
    graphics.draw_circle(mob.pos, 150, 2, graphics.argb(255, 0, 255, 0), 100)
  end 

  if common.IsValidTarget(mob) and player.pos:dist(mob.pos) < 550 and EnoughQMana and Wready and MainGun == "Gravitum" and menu.swap.usefarm:get() then
    player:castSpell("self",1)
  elseif EnoughQMana and common.IsValidTarget(mob) and player.pos:dist(mob.pos) < 650 and EnoughQMana and MainGunReady() and MainGun == "Calibrum" and menu.f.useQ:get() then
    orb.core.set_pause(0.25)
    player:castSpell("pos", 0, mob.pos)
  elseif EnoughQMana and common.IsValidTarget(mob) and player.pos:dist(mob.pos) < 550 and EnoughQMana and MainGunReady() and (MainGun == "Infernum" or MainGun == "Crescendum") and menu.f.useQ:get() then 
    orb.core.set_pause(0.25)
    player:castSpell("pos", 0, mob.pos)
    --player:castSpell("obj", 0, mob)
  elseif EnoughQMana and common.IsValidTarget(mob) and player.pos:dist(mob.pos) < 550 and MainGun == "Severum" and menu.f.useQ:get() then 
    player:castSpell("self", 0)
  elseif EnoughQMana and common.IsValidTarget(mob) and player.pos:dist(mob.pos) < 550 and MainGun == "Gravitum" and menu.f.useQ:get() and menu.f.useQslow:get() then 
    player:castSpell("self", 0)
  end

  if common.IsValidTarget(mob) and player.pos:dist(mob.pos) < 650 and not MainGunReady() and AltGunReady() and AltGun ~= "Gravitum" and menu.swap.usefarm:get() then
    player:castSpell("self",1)
  end

  if common.IsValidTarget(mob) and player.pos:dist(mob.pos) < 575 and not MainGunReady() and not AltGunReady() and (AltGun == "Infernum" or AltGun == "Severum") and menu.swap.usefarm:get() then 
    player:castSpell("self", 1)
  end
end


local function Clear()
  local EnoughQMana = ((player.mana/player.maxMana)*100 > menu.f.manaManager:get())
  
  for i = 0, ObjMinion_Type.size[TEAM_NEUTRAL] - 1 do
        local mob = ObjMinion_Type[TEAM_NEUTRAL][i]
        if valid_minion(mob) and common.can_target_minion(mob) then 
          KillMob(mob)
        end
    end

  for i = 0, ObjMinion_Type.size[TEAM_ENEMY] - 1 do
        local mob = ObjMinion_Type[TEAM_ENEMY][i]
        if valid_minion(mob) and common.can_target_minion(mob) then 
          KillMob(mob)
        end 
  end  
end 


local function DebugPrint()
  if game.time - lastDebugPrint >= 50 then
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
  if MainGunAmmo == 0 then
    print("I HIT 0 MAIN GUN AMMO")
  end

  if menu.d.debugKey:get() then 
    for i = 0, player.buffManager.count - 1 do
        local buff = player.buffManager:get(i)
        if menu.d.printDebug:get() and buff and buff.valid and buff.source == player and (buff.stacks >= 2 or buff.stacks2 >= 2) and buff.endTime - game.time > 0.05 then
          if buff.name ~= "apheliosbuffad" or buff.name ~= "apheliosbuffas" or buff.name ~= "sru_crabspeedboost" then  
            if buff.stacks and buff.name then 
              print("Buff name with " .. tostring(buff.name) .. " with stacks " .. tostring(buff.stacks) .. " " .. tostring(buff.stacks2) .. " " .. tostring(buff.endTime-game.time)) 
            end
          end
        end
    end
  end 


  if MainGunAmmo < 2 or MainGunAmmo == 50 and game.time - lastDebugPrint>= 0.1 then 
    --print("Current stacks .." .. tostring(MainGunAmmo))

    for i = 0, player.buffManager.count - 1 do
        local buff = player.buffManager:get(i)
        if menu.d.printDebug:get() and buff and buff.valid and buff.source == player and (buff.stacks > 0 or buff.stacks2 > 0) then
          if buff.name ~= "apheliosbuffad" or buff.name ~= "apheliosbuffas" or buff.name ~= "sru_crabspeedboost" then  
            --print(buff.name)
            if buff.name == "aphelioslockfacing" and MainGun == "Severum" then 
              --print("Bingo")
              time_left = buff.endTime - game.time              
              orb.core.set_pause_attack(time_left)
              -- print('aphelioslockfacing exists with endtime ' .. tostring(time_left))
              -- local coloractive = graphics.argb(255, 25, 185,50)
              -- local colorCD = graphics.argb(255, 185, 25, 50)
              -- local player_world_pos = graphics.world_to_screen(player.pos)
              -- graphics.draw_text_2D('aphelioslockfacing exists with endtime ' .. tostring(time_left) , 18, player_world_pos.x-105, player_world_pos.y-125, colorCD)
            end
          end
        end
    end
    lastDebugPrint = game.time 
  end
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


local function CountUltHit(PredictedPos, range)
  counter = 0 
  hit_loc = vec3(PredictedPos.x, player.pos.z, PredictedPos.y)
  travel_time = player.pos:dist(hit_loc)/spellR.speed
  for _, obj in ipairs(common.GetEnemyHeroes()) do
      if obj and common.IsValidTarget(obj) then 
        pred_pos = pred.core.get_pos_after_time(obj, travel_time)
        if hit_loc:dist(vec3(pred_pos.x,obj.pos.z ,pred_pos.y)) < range then 
          counter = counter + 1
        end
      end
  end
  return counter
end


local function RLogic(obj, segment) 
  if menu.c.slowPred:get() then 
    if menu.c.forceInfernumR:get() and player:spellSlot(1).state == 0 and AltGun == "Infernum" then 
      player:castSpell("self",1)
    elseif  menu.c.forceInfernumR:get() and MainGun == "Infernum" then 
      player:castSpell("pos", 3, vec3(segment.endPos.x, obj.z, segment.endPos.y))
    elseif menu.c.forceGravitumR:get() and MainGun ~= "Infernum" and AltGun ~= "Infernum" and AltGun == "Gravitum" then 
      player:castSpell("self",1)
    elseif menu.c.forceGravitumR:get() and MainGun ~= "Infernum" and AltGun ~= "Infernum" and MainGun == "Gravitum" then 
      player:castSpell("pos", 3, vec3(segment.endPos.x, obj.z, segment.endPos.y))
    elseif menu.c.forceSeverumR:get() and (player.health/player.maxHealth) < 0.285 and MainGun ~= "Infernum" and AltGun ~= "Infernum" and  MainGun ~= "Gravitum" and AltGun ~= "Gravitum" and AltGun == "Severum" then 
      player:castSpell("self",1)
    else
      player:castSpell("pos", 3, vec3(segment.endPos.x, obj.z, segment.endPos.y))
    end 
  end
end 
 

local function AutoUlt()
  for _,obj in ipairs(common.GetEnemyHeroesInRange(spellR.range, player.pos)) do
    if common.IsValidTarget(obj) and player:spellSlot(3).state == 0 then 
      local segment = pred.linear.get_prediction(spellR, obj, player)
      local seg_vec3 = vec3(segment.endPos.x, obj.z, segment.endPos.y)
      if seg_vec3 and SlowPredR(obj, segment) and common.IsValidTarget(obj) and CountUltHit(seg_vec3, 320) >= menu.c.ultNum:get() then 
        RLogic(obj, segment)
        if menu.d.printDebug:get() then
            print("AutoUlt with min # for " .. tostring(CountUltHit(seg_vec3, 350)) .. " enemies")
        end     
      end      
    end
  end
end


local function SemiR()
    Rtarget = GetTargetR()
    if Rtarget and common.IsValidTarget(GetTargetR()) and player:spellSlot(3).state == 0 then
      local segment = pred.linear.get_prediction(spellR, Rtarget, player)
      if menu.c.slowPred:get() then 
          if SlowPredR(Rtarget, segment) and common.IsValidTarget(Rtarget) then 
            RLogic(Rtarget, segment)
          end
      end
    end
end 


local function CalcCalibrumQDamage(target) 
  local damage = 0
  local CalibrumQDamageTable = {60,85,110,135,160,160}
  if player:spellSlot(0).level > 0 and player:spellSlot(0).state == 0 then
    local D = CalibrumQDamageTable[player:spellSlot(0).level] + common.GetBonusAD() * 0.6 + common.GetTotalAP() 
    damage = common.CalculatePhysicalDamage(target, D) 
    return damage
  else
    return 0
  end
end 

local function CalcCalibrumMarkDamage(target) 
  local damage = 0
  local CalibrumQDamageTable = {20,25,30,35,40,40,40,40} 
  if player:spellSlot(0).level > 0 and player:spellSlot(0).state == 0 then 
    local D = (common.GetTotalAD(player) + CalibrumQDamageTable[player:spellSlot(0).level])
    if D and D ~= nil and D >= 0 then 
      return common.CalculatePhysicalDamage(target, D)
    else 
      return 0 
    end 
  else 
    return 0
  end 
end

local function CalcRDamage(target, mode) 
  local mode = mode or "Base"
  local damage = 0
  local RDamageTable = {125,175,225,225,225,225}
  local CalribumBonusMark = {20,45,70,70,70,70} 
  local InfernumBonusMark = {50,100,150,150,150,150}
  if player:spellSlot(3).level > 0 and player:spellSlot(3).state == 0 then
    local D = RDamageTable[player:spellSlot(3).level] + common.GetBonusAD(player) * 0.2 + common.GetTotalAP(player) 
    if mode == "Base" then 
      damage = common.CalculatePhysicalDamage(target, D)
    elseif mode == "Calibrum" then 
      D = D + CalribumBonusMark[player:spellSlot(3).level]
      damage = common.CalculatePhysicalDamage(target, D)
    elseif mode == "Severum" then 
      damage = common.CalculatePhysicalDamage(target, D)
    elseif mode == "Infernum" then 
      D = D + InfernumBonusMark[player:spellSlot(3).level] + common.GetBonusAD(player) * 0.4
      damage = common.CalculatePhysicalDamage(target, D)
    elseif mode == "Crescendum" then 
      damage = common.CalculatePhysicalDamage(target, D)
    end
    return damage
  else 
    return 0
  end
end 

local function AutoKS(target)
  if MainGun == "Infernum" then 
    Rdam = CalcRDamage(target, "Infernum")
  elseif MainGun == "Calibrum" then
    Rdam = CalcRDamage(target, "Calibrum")
  else
    Rdam = CalcRDamage(target, "Base")
  end

  Qdam = CalcCalibrumQDamage(target)
  Procdam = CalcCalibrumMarkDamage(target)

  if menu.ks.useQMark:get() then
      Qdam = Qdam + Procdam
  end 

  --Proc KS
  if menu.ks.useMark:get() and IsSafe(200)  then 
    if target and common.IsValidTarget(target) and target.health < Procdam then 
      for i = 0, target.buffManager.count - 1 do
        local buff = target.buffManager:get(i)
        if buff and buff.valid and buff.name == "aphelioscalibrumbonusrangedebuff" and  buff.source == player and (buff.stacks > 0 or buff.stacks2 > 0) then
          --print("Buff " .. buff.name .. "active")

          player:attack(target)

        end
      end
    end
  end
  --Q KS 
  if menu.ks.useQ:get() and IsSafe(350) then  
    if target and common.IsValidTarget(target) and target.health < Qdam then 
      local segment = pred.linear.get_prediction(spellCalibrumQ, target, player)
      if SlowPredQ(target, segment) and common.IsValidTarget(target) then 
        if MainGun == "Calibrum" then 
          player:castSpell("pos", 0, vec3(segment.endPos.x, target.y, segment.endPos.y))
          if menu.d.printDebug:get() then 
              print("Q ks active")
          end

        elseif AltGun == "Calibrum" and player:spellSlot(1).state == 0 and menu.ks.swap:get() then 
          pred_pos = pred.core.get_pos_after_time(target, 0.55)
          if player.pos:dist(vec3(pred_pos.x,player.pos.z ,pred_pos.y)) < 1375 then 
            player:castSpell("self", 1)
            if menu.d.printDebug:get() then 
                print("Q ks swap is active")
            end

          end            
        end
      end
    end  
  end 

  --R KS
  if (menu.ks.useR:get() or menu.ks.useRsmart:get()) and IsSafe(350) then
      if target and common.IsValidTarget(target) and target.health < Rdam then 
        if menu.d.printDebug:get() then 
          print("Q ks swap is active")
        end
        local segment = pred.linear.get_prediction(spellR, target, player)
        if SlowPredR(target, segment) and common.IsValidTarget(target) and menu.ks.useR:get() then 
          player:castSpell("pos", 3, vec3(segment.endPos.x, target.y, segment.endPos.y))
        end
        local seg_vec3 = vec3(segment.endPos.x, target.z, segment.endPos.y)
        if SlowPredR(target, segment) and common.IsValidTarget(target) and menu.ks.useRsmart:get() and CountUltHit(seg_vec3, 250) >= 2 then 
          player:castSpell("pos", 3, vec3(segment.endPos.x, target.y, segment.endPos.y))
        end

      end
    end   

end 
--R KS 

local function OnTick()
  CheckSpellState()
  CheckWeapons()
  if menu.d.printDebug:get() then 
    DebugPrint()
    --print(MainGunAmmo)
  end

  if menu.ks.useQ:get() or menu.ks.useMark:get() or menu.ks.useR:get() then 
    for _, obj in ipairs(common.GetEnemyHeroes()) do
      if obj and common.IsValidTarget(obj) and player.pos:dist(obj.pos) < 2500 then 
        AutoKS(obj)
      end
    end
  end

  if (orb.combat.is_active()) and player.levelRef > 1 then 
    AutoSwapCombo()
    Combo()
    AutoUlt()
  end

  if menu.c.ultKey:get() and player.levelRef > 1 then
    AutoUlt()
    Rtarget = GetTargetR()
    if Rtarget and common.IsValidTarget(GetTargetR()) and player:spellSlot(3).state == 0 then
      local segment = pred.linear.get_prediction(spellR, Rtarget, player)
      if menu.c.slowPred:get() then 
          if SlowPredR(Rtarget, segment) and common.IsValidTarget(Rtarget) then 
            SemiR()
          end
      end
    end
  end 

  if (orb.menu.lane_clear:get()) and player.levelRef > 1 then 
    Clear()
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
      if MainGun ~= "Calibrum" and menu.d.drawCalibrum:get() then
        if menu.d.drawCalibrumX:get() and AltGun == "Calibrum" then 
          graphics.draw_circle(player.pos, CalibrumAArange, 2, colorCD, 70)
        elseif not menu.d.drawCalibrumX:get() then 
          graphics.draw_circle(player.pos, CalibrumAArange, 2, colorCD, 70)
        end
      elseif MainGun == "Calibrum" and menu.d.drawCalibrum:get() then 
        graphics.draw_circle(player.pos, CalibrumAArange, 2, colorCD, 90)
      end
      if player:spellSlot(3).state == 0 and menu.d.drawR:get() then
          graphics.draw_circle(player.pos, spellR.range, 2, graphics.argb(255, 0, 255, 0), 100)
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
    AATarget = GetTargetAA()
    if AATarget ~= nil then
      if menu.d.printDebug:get() and common.IsValidTarget(AATarget) then 
        --print("Found AA target!")
      end 
    end
    if AATarget ~= nil and common.IsValidTarget(AATarget) then 
      graphics.draw_text_2D('AAtarget exists' , 18, player_world_pos.x+105, player_world_pos.y+125, colorCD)
    else
      graphics.draw_text_2D('AAtarget not found' , 18, player_world_pos.x+105, player_world_pos.y+125, colorCD)
    end
    CalibrumAATarget = GetTargetAACalibrum()
    if CalibrumAATarget ~= nil and common.IsValidTarget(CalibrumAATarget) then 
      graphics.draw_text_2D('AACalibrumtarget exists' , 18, player_world_pos.x+105, player_world_pos.y+155, colorCD)
    else
      graphics.draw_text_2D('AACalibrumtarget not found' , 18, player_world_pos.x+105, player_world_pos.y+155, colorCD)
    end
        Rtarget = GetTargetR()
    if common.IsValidTarget(RTarget) then 
      graphics.draw_text_2D('Rtarget exists' , 18, player_world_pos.x+105, player_world_pos.y+175, colorCD)
    else
      graphics.draw_text_2D('Rtarget not found' , 18, player_world_pos.x+105, player_world_pos.y+175, colorCD)
    end

    if common.IsValidTarget(AATarget) then
      if MainGun == "Infernum" then 
        Rdam = CalcRDamage(AATarget, "Infernum")
      elseif MainGun == "Calibrum" then
        Rdam = CalcRDamage(AATarget, "Calibrum")
      else
        Rdam = CalcRDamage(AATarget, "Base")
      end

      Qdam = CalcCalibrumQDamage(AATarget)
      Procdam = CalcCalibrumMarkDamage(AATarget)

      if menu.ks.useQMark:get() then
          Qdam = Qdam + Procdam
      end 
      graphics.draw_text_2D('Rtarget exists .. ' .. tostring(common.round(Procdam, 2)) .. ' ' .. tostring(common.round(Qdam, 2)) .. ' ' .. tostring(common.round(Rdam,2)) , 18, player_world_pos.x+105, player_world_pos.y+175, colorCD)
    end 
  end 
end


cb.add(cb.draw, OnDraw)
cb.add(cb.spell, OnProcessSpell)
orb.combat.register_f_pre_tick(OnTick)
chat.print("DienoAlphelios beta version " .. tostring(version) .. " loaded! Please provide feedback to dienofail#1100 on discord")



