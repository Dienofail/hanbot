local orb = module.internal("orb");
local evade = module.internal("evade");
local pred = module.internal("pred");
local ts = module.internal('TS');
local common = module.load("daphelios", "common");
local ObjMinion_Type = objManager.minions
local version = "0.04"

--Full changelogs are on my discord. Visit hanbot forums, my github, or pm dienofail#1100 on discord if you need an invite.

local spellCalibrumQ = {
  range = 1450,
  delay = 0.35,
  width= 60,
  speed = 1800,
  windup=0,
  collision= {hero=true, minion=true, wall=true},
  damage = function(m)
  local q_level = player:spellSlot(0).level 
  if MainGun == "Calibrum" then return 65 + 25*q_level +  common.GetBonusAD() * 0.6 + common.GetTotalAP() else return 0 end 
  end,
  boundingRadiusMod =0, 
}

local spellR = {
  range = 1500,
  width = 125,
  speed = 2050,
  delay = 0.5,
  windup=0, 
  collision = {
    minion=false,
    hero=false,
    wall=true,
  },
  boundingRadiusMod = 0
}

local spellInfernumQ = {
  range = 600,
  delay = 0.4,
  speed = 2050,
  angle = 45,
  width=0,
  windup=0,
  collision={hero=false, minion=false, wall=true},
  damage = function(m)
  local q_level = player:spellSlot(0).level 
  if MainGun =="Infernum" then return 25+10*q_level + common.GetBonusAD() * 0.8 + common.GetTotalAP() * 0.7 else return 0 end 
  end,
  boundingRadiusMod=0
}

local spellCrescendumQLastHit = {
  range = 530,
  delay = 0.25,
  speed = math.huge,
  radius = 475,
  width=0,
  windup=0,
  collision={hero=false, minion=false, wall=true},
  damage = function(m)
  local q_level = player:spellSlot(0).level 
  if MainGun =="Crescendum" then return (25+15*q_level + common.GetBonusAD() * 0.5 + common.GetTotalAP() * 0.5) else return 0 end 
  end,
  boundingRadiusMod=0
}

local spellSeverumQ = {
  range = 475,
  delay = 0.25,
  speed = math.huge,
  collision={hero=false, minion=false, wall=true},
  damage = function(m)
  local q_level = player:spellSlot(0).level 
  if MainGun =="Severum" then return (common.GetTotalAD()*4) else return 0 end 
  end,
  boundingRadiusMod=0
}


local spellCrescendumQFarm = {
  range = 530,
  delay = 0.25,
  speed = math.huge,
  radius = 475,
  width=0,
  windup=0,
  collision={hero=false, minion=false, wall=true},
  damage = function(m)
  local q_level = player:spellSlot(0).level 
  if MainGun =="Crescendum" then return 3*(25+15*q_level + common.GetBonusAD() * 0.5 + common.GetTotalAP() * 0.5) else return 0 end 
  end,
  boundingRadiusMod=0
} 

local spellCrescendumQ = {
  range = 530,
  delay = 1.35,
  speed = math.huge,
  radius = 475,
  width=0,
  windup=0,
  collision={hero=false, minion=false, wall=true},
  damage = function(m)
  local q_level = player:spellSlot(0).level 
  if MainGun =="Crescendum" then return 3*(25+15*q_level + common.GetBonusAD() * 0.5 + common.GetTotalAP() * 0.5) else return 0 end 
  end,
  boundingRadiusMod=0
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
local LastMoveOrder = 0 
local LastOrbPause = 0 
local LastSwap = 0 
local LastWindupPause = 0
local LastOrbPauseTime = 0
local LastWindUpPauseTime = 0
local LastFacingTick = 0
local CalibrumCD = {9, 8.25, 7.5, 6.75, 6,6}
local SeverumCD = {10,9,8,8,8,8}
local GravitumCD = {12,11.5,11,10.5,10,10}
local InfernumCD = {9,8,7,6,6,6}
local TimeSinceLastLongestPause = 0
local TimeSinceLastLongestAttackPause = 0 
local CrescendumCD = {9,8.25,7.5,6.75,6,6}
local IsSeverumQ = false
local MoonlightDamage = {125, 175, 225}
local CrescendumBuffs = 0 
local CalibrumR, SeverumR, GravitumR, InfernumR, CrescendumR = true,true,true,true,true
local CalibrumT, SeverumT, GravitumT, InfernumT, CrescendumT = 0,0,0,0,0
local LastSwapTime = 0
local ApheliosTurret = {}
local AATarget, CalibrumQTarget, CalibrumRTarget, CalibrumAATarget = nil, nil, nil, nil


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
menu.f:boolean("useQslow", "^ Use gravitum snare during farm", false)
menu.f:slider("manaManager", "Farm mana manager", 35, 1, 100, 1)
menu.f:keybind("farm", "Farm key", nil, 'A')


menu:menu("ks", "Kill steal settings")
menu.ks:header("ksgeneral", "KS settings")
menu.ks:boolean("useQ", "Use calibrum Q to KS if safe", true)
menu.ks:boolean("useQMark", "Include mark in Q damage calc", true)
menu.ks:boolean("useMark", "Use calibrum mark to KS if safe", true)
menu.ks:boolean("useR", "(Leave False) Use R KS ONE KILL Minimum", false)
menu.ks:boolean("useRsmart", "Use R KS ONE KILL + ONE HIT Minimum", true)
menu.ks:boolean("useRsmartone", "Use R KS 1v1", true)
menu.ks:boolean("swap", "Swap weapons to KS if possible", true)
menu.ks:boolean("considerRKS", "Consider Calibrum R + Proc dam KS", true)

menu:menu("swap", "Weapon auto swap")
menu.swap:header("swap", "Autoswap settings")
menu.swap:boolean("usecombo", "Use weapon autoswap in combo", true)
menu.swap:boolean("usefarm", "Use weapon autoswap in farm", true)
menu.swap:boolean("cal", "Autoswap to proc calibrum mark when safe", true)
menu.swap:boolean("crescendum", "Force crescendum & (infer/sever) stacking", true)
menu.swap:slider("stacks", "^Force >X Crescendum stacks before swap", 3,1,15,1)
menu.swap:boolean("crescendumcal", "^^Force calibrum + crescendum stacking", false)
menu.swap:slider("severumhigh", "Swap out of sev if %HP > X", 80, 1, 100, 5)
menu.swap:slider("severumlow", "Swap into sev if %HP < X", 25, 1, 100, 5)
menu.swap:boolean("swapturrets", "Swap for turrets when hard CC", true)
menu.swap:keybind("farmsave", "Save current offhand when farming", nil, 'Z')
--menu.swap.info:set('tooltip', 'You have to swap to offhand weapon at least once to know')

menu:menu("d", "Drawing")
menu.d:header("drawd", "Drawing settings")
menu.d:boolean("drawCalibrum", "Draw Calibrum range", true)
menu.d:boolean("drawCalibrumX", "^ Only if Calibrum is main/alt weapon", false)
menu.d:boolean("drawCalibrumQ", "Draw Calibrum Q range", true)
menu.d:boolean("drawCrescendum", "Draw Crescendum turret range", true)
menu.d:boolean("drawR", "Draw R range", true) 
menu.d:boolean("drawRcounter", "Draw R hit counter (WARNING: FPS DROP!)", false) 
menu.d:boolean("drawKS", "Draw KS", true)
menu.d:boolean("drawBuffTimer", "Draw buff timers", true)
menu.d:boolean("drawDebug", "Debugging draw", false)
menu.d:boolean("printDebug", "Print debug", false)
menu.d:keybind("debugKey", "Debug print key", '-', nil)


menu:menu("misc", "Misc. keybinds & functions")
menu.misc:header("miscd", "Misc. settings")
menu.misc:boolean("manualswaptoggle", "Use manual swap", false)
menu.misc:keybind("manualswap", "^Manual swap only hotkey", nil, nil)
menu.misc:keybind("turret", "Manual Turret at Mouse Location", nil, nil)
menu.misc:keybind("snarenow", "Snare now if possible (will swap)!", nil, nil)

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

local TargetSelectionQInfernum = function(res, obj, dist)
    if dist < spellInfernumQ.range + obj.boundingRadius then 
        table.insert(res, obj)
    end
end

local GetTargetQInfernum = function()
    local res = ts.loop(loop_filter)
    return res 
end 

local TargetSelectionQCrescendum = function(res, obj, dist)
    if dist < 1000 then 
        table.insert(res, obj)
    end
end

local GetTargetQInfernum = function()
    local res = ts.loop(loop_filter)
    return res 
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


local function AltCD()
  if AltGunReady then return 0 end 
  if AltGun == "Severum" and SeverumT - game.time >= 0 then 
    return SeverumT - game.time
  elseif AltGun == "Calibrum" and CalibrumT - game.time >= 0 then 
    return CalibrumT - game.time
  elseif AltGun == "Gravitum" and GravitumT - game.time >= 0 then 
    return GravitumT - game.time
  elseif AltGun == "Crescendum" and CrescendumT - game.time >= 0 then 
    return CrescendumT - game.time
  elseif AltGun == "Infernum" and InfernumT - game.time >= 0 then 
    return InfernumT - game.time 
  else return 0 
  end 
end  

local function MainCD()
  if MainGunReady then return 0 end 
  if MainGun == "Severum" and SeverumT - game.time >= 0 then 
    return SeverumT - game.time
  elseif MainGun == "Calibrum" and CalibrumT - game.time >= 0 then 
    return CalibrumT - game.time
  elseif MainGun == "Gravitum" and GravitumT - game.time >= 0 then 
    return GravitumT - game.time
  elseif MainGun == "Crescendum" and CrescendumT - game.time >= 0 then 
    return CrescendumT - game.time
  elseif MainGun == "Infernum" and InfernumT - game.time >= 0 then 
    return InfernumT - game.time 
  else return 0 
  end 
end  

function CountUltHit(PredictedPos, range)
  counter = 0 
  hit_loc = vec3(PredictedPos.x, player.pos.z, PredictedPos.y)
  travel_time = player.pos:dist(hit_loc)/spellR.speed
  for _, obj in ipairs(common.GetEnemyHeroes()) do
      if obj and common.IsValidTarget(obj) then 
        pred_pos = pred.core.get_pos_after_time(obj, travel_time)
        if hit_loc:dist(vec3(pred_pos.x,player.pos.z,pred_pos.y)) < range then 
          counter = counter + 1
        end
      end
  end
  return counter
end



local function SlowPredQ(target, segment)
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

local function tryCalbriumQ(target) 
  local segment = pred.linear.get_prediction(spellCalibrumQ, target, player)
  if menu.c.slowPred:get() then 
      if SlowPredQ(target, segment) and common.IsValidTarget(target) and player.pos:dist(vec3(segment.endPos.x, target.y, segment.endPos.y)) < spellCalibrumQ.range then 
          player:castSpell("pos", 0, vec3(segment.endPos.x, target.y, segment.endPos.y))
          orb.core.set_server_pause()
      end
  else
      if segment then
        local coll = pred.collision.get_prediction(spellCalibrumQ, segment, target)
        if not coll then
          local endPos = segment.endPos
          if endPos:dist(segment.startPos) > spellCalibrumQ.range then
            return
          end
          player:castSpell("pos", 0, vec3(endPos.x, target.y, endPos.y))
          orb.core.set_server_pause()
        end
      end
  end
end


local function CountSnared(pos, delay, range)
  counter = 0 
  pos2 = vec3(pos.x, player.pos.z,pos.y)
  for _, obj in ipairs(common.GetEnemyHeroes()) do
      if obj and common.IsValidTarget(obj) then 
        pred_pos = pred.core.get_pos_after_time(obj, delay)
        if pos2:dist(vec3(pred_pos.x,obj.pos.z ,pred_pos.y)) < range or common.IsImmobileBuffer(obj, delay) then 
          counter = counter + 1
        end
      end
  end
  return counter
end 


local function CountGravitumBuffs(range)
    buff_counter = 0 
    range = range or 2500
    for _, obj in ipairs(common.GetEnemyHeroes()) do
      if obj and obj.buffManager and obj.buffManager.count then 
        for i = 0, obj.buffManager.count - 1 do
          local buff = obj.buffManager:get(i)
          if buff and buff.valid and buff.name =="ApheliosGravitumDebuff" and player.pos:dist(obj.pos) < range and buff.source.ptr == player.ptr and (buff.stacks > 0 or buff.stacks2 > 0) and (buff.endTime - buff.startTime <= 0.4) then
            buff_counter = buff_counter + 1
          end
        end
      end
    end
    return buff_counter
end 
 
local function CountGravitumBuffsNow(range)
    buff_counter = 0 
    range = range or 2500
    for _, obj in ipairs(common.GetEnemyHeroes()) do
      if obj and obj.buffManager and obj.buffManager.count then 
        for i = 0, obj.buffManager.count - 1 do
          local buff = obj.buffManager:get(i)
          if buff and buff.valid and buff.name =="ApheliosGravitumDebuff" and player.pos:dist(obj.pos) < range and buff.source.ptr == player.ptr and (buff.stacks > 0 or buff.stacks2 > 0) then 
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

--from asdfaphelios 
function CalcBestCastAngle(angles)
    local maxCount = 0
    local maxStart = nil
    local maxEnd = nil
    for i = 1, #angles do
        local base = angles[i]
        local endAngle = base + spellInfernumQ.angle
        local over360 = endAngle > 360
        if over360 then
            endAngle = endAngle - 360
        end
        local function isContained(count, angle, base, over360, endAngle)
            if angle == base and count ~= 0 then
                return
            end
            if not over360 then
                if angle <= endAngle and angle >= base then
                    return true
                end
            else
                if angle > base and angle <= 360 then
                    return true
                elseif angle <= endAngle and angle < base then
                    return true
                end
            end
        end
        local angle = base
        local j = i
        local count = 0
        local endDelta = angle
        while (isContained(count, angle, base, over360, endAngle)) do
            endDelta = angles[j]
            count = count + 1
            j = j + 1
            if j > #angles then
                j = 1
            end
            angle = angles[j]
        end
        if count > maxCount then
            maxCount = count
            maxStart = base
            maxEnd = endDelta
        end
    end
    if maxStart and maxEnd then
        if maxStart + spellInfernumQ.angle> 360 then
            maxEnd = maxEnd + 360
        end
        local res = (maxStart + maxEnd) / 2
        if res > 360 then
            res = res - 360
        end
        return math.rad(res)
    end
end


-- function TryInfernumQ()
--     if myHero.spellbook:CanUseSpell(0) == 0 then
--         local qTargets, qPreds = self:GetTarget(self.infernumQ, true)
--         local angles = {}
--         local basePosition = nil
--         for _, pred in pairs(qPreds) do
--             if not basePosition then
--                 angles[1] = 0
--                 basePosition = pred.castPosition
--             else
--                 angles[#angles + 1] =
--                     Vector(myHero.position):angleBetweenFull(Vector(basePosition), Vector(pred.castPosition))
--             end
--         end
--         local best = self:CalcBestCastAngle(angles)
--         if best then
--             local castPosition =
--                 (Vector(myHero.position) +
--                 (Vector(basePosition) - Vector(myHero.position)):rotated(0, best, 0):normalized() * (self.infernumQ.range - 10)):toDX3()
--             myHero.spellbook:CastSpell(0, castPosition)
--         end
--     end
-- end

local function TurretRangeCheck(target) 
  if #ApheliosTurret > 0 and common.IsValidTarget(target) then 
    for idx, turret in ipairs(ApheliosTurret) do 
      if target.pos2D:dist(turret.pos2D) < 525 then 
        return true 
      end
    end
  else
    return false
  end
end

local function CountInTurretRangeWithGravitum()
  counter = 0 
  for _, obj in ipairs(common.GetEnemyHeroes()) do
    if obj and common.IsValidTarget(obj) and obj.pos then 
      isbuff, endtime = common.CheckBuffWithTimeEnd(obj, "ApheliosGravitumDebuff") 
      if TurretRangeCheck(obj) and isbuff and endtime - game.time > 0.35 then 
        counter = counter + 1
      end
    end
  end
  return counter 
end

local function HotKeyChecks()
  AATarget = GetTargetAA()
  CalibrumAATarget = GetTargetAACalibrum()
  CalibrumQTarget = GetTargetQCalibrum()
  CalibrumRTarget = GetTargetR()


  if menu.misc.snarenow:get() and MainGun == "Gravitum" and player:spellSlot(0).state == 0 then 
    player:castSpell("self", 0)
    orb.core.set_server_pause()
  elseif menu.misc.snarenow:get() and AltGun == "Gravitum" and AltGunReady() and CountGravitumBuffsNow(20000) > 0 and player:spellSlot(1).state == 0 then 
    player:castSpell("self", 1)
    orb.core.set_server_pause()
  elseif menu.misc.snarenow:get() and AltGun == "Gravitum"  and AltGunReady() and CountGravitumBuffsNow(20000) == 0 and player:spellSlot(1).state == 0 then 
    player:castSpell("self", 1)
    orb.core.set_server_pause()    
  end 

  if menu.misc.turret:get() and MainGun == "Crescendum" then 
    if player.pos:dist(mousePos) < 575 and player:spellSlot(0).state == 0 then 
      player:castSpell("pos", 0, mousePos)
      orb.core.set_server_pause()     
    end
  elseif menu.misc.turret:get() and AltGun == "Crescendum" and AltGunReady() then 
    if player.pos:dist(mousePos) < 575 and player:spellSlot(1).state == 0 then 
      player:castSpell("self", 1)
      orb.core.set_server_pause()     
    end    
  end 

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

  if IsSafe(225) then 
    best_attack_obj = nil
    best_attack_health = 100
    for _, obj in ipairs(common.GetEnemyHeroes()) do
      if obj and common.IsValidTarget(obj) then 
        for i = 0, obj.buffManager.count - 1 do
          local buff = obj.buffManager:get(i)
          if buff and buff.valid and buff.name == "aphelioscalibrumbonusrangedebuff" and  buff.source == player and (buff.stacks > 0 or buff.stacks2 > 0) then
            --print("Buff " .. buff.name .. "active")
            -- if common.IsValidTarget(AATarget) and common.IsValidTarget(CalibrumAATarget) and common.IsValidTarget(CalibrumQTarget) and obj.ptr == AATarget.ptr or obj.ptr == CalibrumQTarget.ptr or obj.ptr == CalibrumAATarget.ptr or obj.ptr == CalibrumQTarget.ptr then 
            --   player:attack(obj)
            -- elseif common.GetPercentHealth(obj) < best_attack_health then 
              best_attack_health = common.GetPercentHealth(obj)
              best_attack_obj = obj 
            --end 
          end
        end
      end
    end
    if best_attack_obj and best_attack_obj.pos and common.IsValidTarget(best_attack_obj) then 
      player:attack(best_attack_obj)
      orb.core.set_server_pause_attack()
    end
  elseif not common.IsValidTarget(AATarget) and AltGun == "Calibrum" and IsSafe(300) then 
    for _, obj in ipairs(common.GetEnemyHeroes()) do
      if obj and common.IsValidTarget(obj) then 
        for i = 0, obj.buffManager.count - 1 do
          local buff = obj.buffManager:get(i)
          if buff and buff.valid and buff.name == "aphelioscalibrumbonusrangedebuff" and  buff.source == player and (buff.stacks > 0 or buff.stacks2 > 0) then
            --print("Buff " .. buff.name .. "active")
            player:castSpell("self", 1)
            orb.core.set_server_pause()
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
            orb.core.set_server_pause()
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
    if player.pos:dist(vec3(pred_pos.x,0,pred_pos.y)) < AArange-25 then
      player:castSpell("self", 0)
      orb.core.set_server_pause()
    end    
  end 

  --Infernum logic 
  if MainGun == "Infernum" and player:spellSlot(0).state == 0 and common.IsValidTarget(CalibrumAATarget) then 
    pred_pos = pred.core.get_pos_after_time(CalibrumAATarget, 0.25)
    if common.IsValidTarget(CalibrumAATarget) and player.pos:dist(vec3(pred_pos.x,0,pred_pos.y)) < 615 then
      player:castSpell("pos", 0, vec3(pred_pos.x, 0, pred_pos.y))
      orb.core.set_server_pause()
    end 
  end

  --Crescendum logic 
  if MainGun == "Crescendum" and player:spellSlot(0).state == 0 and common.IsValidTarget(AATarget) then 
    pred_pos = pred.core.get_pos_after_time(AATarget, 0.25)
    if player.pos:dist(vec3(pred_pos.x,0,pred_pos.y)) < 475 then
      player:castSpell("pos", 0, vec3(pred_pos.x, player.pos.z, pred_pos.y))
      orb.core.set_server_pause()
    end 

    if common.IsValidTarget(AATarget) and MainGun == "Crescendum" and player:spellSlot(0).state == 0 and CountSnared(AATarget.pos, 0.75, 475) >= 2 then
      player:castSpell("pos", 0, vec3(pred_pos.x, player.pos.z, pred_pos.y))
      orb.core.set_server_pause()
    end 


  --elseif  common.IsValidTarget(AATarget) and MainGun == "Crescendum" and player:spellSlot(0).state == 0 and CountSnared(AATarget.pos, 0.45, 475) >= 2 then 
  --^only if gravitum count buffs >= 2 or something then do check 
  end

  --Gravitum logic 
  if MainGun == "Gravitum" and player:spellSlot(0).state == 0 then 
    num_debuffs = CountGravitumBuffs()
    --print("Numdebuffs " .. num_debuffs)
    --print(menu.c.gravitumSnare:get())
    if num_debuffs and num_debuffs >= menu.c.gravitumSnare:get() then 
      player:castSpell("self", 0)
      orb.core.set_server_pause()
    end 

    if menu.c.gravitumSnare:get() and CountInTurretRangeWithGravitum() >= 2 then 
      player:castSpell("self", 0)
      orb.core.set_server_pause()      
    end  
 

    if menu.c.gravitumOne:get() and common.IsValidTarget(CalibrumAATarget) and common.tablelength(common.GetEnemyHeroesInRange(685, player)) < 2 and common.CheckBuff(CalibrumAATarget, "ApheliosGravitumDebuff") and not common.IsImmobileBuffer(CalibrumAATarget, 0.2) then
      player:castSpell("self", 0)
      orb.core.set_server_pause()
    end
    if menu.c.gravitumOne:get() and common.IsValidTarget(AATarget) and common.tablelength(common.GetEnemyHeroesInRange(685, player)) < 2 and common.CheckBuff(AATarget, "ApheliosGravitumDebuff") and not common.IsImmobileBuffer(AATarget, 0.2) then
      player:castSpell("self", 0)
      orb.core.set_server_pause()
    end
    if menu.c.gravitumOne:get() and common.IsValidTarget(CalibrumQTarget) and common.tablelength(common.GetEnemyHeroesInRange(685, player)) < 2 and common.CheckBuff(CalibrumQTarget, "ApheliosGravitumDebuff") and not common.IsImmobileBuffer(CalibrumQTarget, 0.2) then
      player:castSpell("self", 0)
      orb.core.set_server_pause()
    end

    if menu.c.gravitumOne:get() and (common.tablelength(common.GetEnemyHeroesInRange(250))<2 or common.tablelength(common.GetEnemyHeroesInRange(485))<3 or common.tablelength(common.GetEnemyHeroesInRange(1000))<4) and common.CheckBuff(AATarget, "ApheliosGravitumDebuff")  then 
      player:castSpell("self", 0)
      orb.core.set_server_pause()
    end

    if common.IsValidTarget(AATarget) and menu.c.gravitumOne:get() and player.pos:dist(AATarget.pos) < 435 and player.pos:dist(AATarget.pos) > 550 and common.tablelength(common.GetEnemyHeroesInRange(1200,AATarget.pos)) < 3 and common.CheckBuff(AATarget, "ApheliosGravitumDebuff") then 
      player:castSpell("self", 0)
      orb.core.set_server_pause()
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
          AltGunAmmo = buff.stacks2 
        elseif buff.name == "ApheliosOffHandBuffGravitum" then 
          AltGun = "Gravitum"
          AltGunAmmo = buff.stacks2 
        elseif buff.name == "ApheliosOffHandBuffCalibrum" then 
          AltGun = "Calibrum"
          AltGunAmmo = buff.stacks2 
        elseif buff.name == "ApheliosOffHandBuffInfernum" then 
          AltGun = "Infernum"
          AltGunAmmo = buff.stacks2 
        elseif buff.name == "ApheliosOffHandBuffCrescendum" then 
          AltGun = "Crescendum"
          AltGunAmmo = buff.stacks2 
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

  if common.CheckBuff(player, "aphelioslockfacing") and MainGun == "Severum" then 
    IsSeverumQ = true 
  else
    IsSeverumQ = false
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
    if menu.d.printDebug:get() and game.time - lastDebugPrint > 0.1 then 
      print("DebugPrint")
      lastDebugPrint = game.time 
    end
    if player:spellSlot(0).level == 0 then 
      return 12
    elseif player:spellSlot(0).level == 1 then 
      return 10 
    elseif player:spellSlot(0).level == 2 then 
      return 8.75
    elseif player:spellSlot(0).level == 3 then   
      return 7.5
    elseif player:spellSlot(0).level == 4 then  
      return 7 
    else 
      return 6.85
    end 
  end
end

local qSpells = {ApheliosCalibrumQ = true,ApheliosGravitumQ= true,ApheliosInfernumQ = true,ApheliosCrescendumQ = true,ApheliosSeverumQ = true}

local function OnProcessSpell(spell)
  --if spell.owner.ptr == player.ptr and player.pos:dist(vec3(spell.startPos)) < 25 then

  -- if ApheliosTurret and ApheliosTurret.ptr and spell.owner.ptr == ApheliosTurret.ptr then 
  --   if menu.d.printDebug:get() and  menu.d.debugKey:get() and spell.target ~= nil and spell.startPos then 
  --     print(spell.name .. " from TURRET " .. tostring(ApheliosTurret.pos:dist(spell.startPos)))
  --   end 

  -- end  

  if menu.d.printDebug:get() and  menu.d.debugKey:get() and spell.owner and spell.owner.team == TEAM_ALLY then 
    for idx, turret in ipairs(ApheliosTurret) do 
      if spell.owner.ptr == turret.ptr then 
        print(tostrign(spell.name) .. " from turret")
      end
    end 
  end


  if spell.owner.ptr == player.ptr and player.pos:dist(spell.startPos) < player.boundingRadius then 
    spell_level = player:spellSlot(0).level

    if menu.d.printDebug:get() and  menu.d.debugKey:get() and spell.target ~= nil and spell.startPos then 
      print(spell.name .. " from " .. tostring(player.pos:dist(spell.startPos)))
    end 
 

    if spell.isBasicAttack and player.sar==1 and spell.target ~= nil and common.IsValidTarget(spell.target) and not IsSeverumQ and not spell.name:find("Line") then
      --orb.core.set_pause_attack(spell.windUpTime)
      if menu.c.pause:get() and (game.time + 1) >= LastOrbPause + LastOrbPauseTime then 
        orb.core.set_pause_attack(1+network.latency)
        LastOrbPause = game.time 
        LastOrbPauseTime = 1 
        common.ResetOrbDelay(1+0.01)
      end
    elseif qSpells[spell.name] and player.sar<10 and not spell.name:find("Line") then -- <= ??
      --start timer
      if menu.c.pause:get() and not IsSeverumQ and (game.time + 1 ) >= LastOrbPause + LastOrbPauseTime then 
        orb.core.set_pause_attack(1)
        LastOrbPause = game.time 
        LastOrbPauseTime = 1
        common.ResetOrbDelay(1+0.01)
      end
    -- elseif spell.name:find("Line") and spell.isBasicAttack and player.sar ==1 and  spell.target ~= nil and common.IsValidTarget(spell.target) and IsSeverumQ then 
    --   if menu.c.pause:get() then 
    --     orb.core.set_pause_attack(1+network.latency)      
    --     LastOrbPause = game.time 
    --     LastOrbPauseTime = 1 + network.latency 
    --   end 

    elseif spell.name == "ApheliosGravitumQ" and (game.time + spell.windUpTime) >= LastOrbPause + LastOrbPauseTime then 
      GravitumT = game.time + CalculateRealCD(GravitumCD[spell_level])
      orb.core.set_pause_attack(spell.windUpTime)
      LastWindupPause = game.time
      LastOrbPause = game.time 
      LastOrbPauseTime = 1 
      if menu.d.printDebug:get() and spell.windUpTime > 0.1 and game.time - lastDebugPrint >0.01 then 
        print("ApheliosGravitumQ winduptime" .. tostring(common.round(spell.windUpTime,2)))
      end
      LastWindupPause = game.time
      common.ResetOrbDelay(spell.windUpTime)
    elseif spell.name == "ApheliosSeverumQ" and not IsSeverumQ then 
      SeverumT = game.time + CalculateRealCD(SeverumCD[spell_level])
      orb.core.set_pause_attack(1.75+network.latency)
      if menu.d.printDebug:get() and spell.windUpTime > 0.1 and game.time - lastDebugPrint >0.01 then 
        print("ApheliosSeverumQ winduptime" .. tostring(common.round(spell.windUpTime,2)))
      end
      LastWindupPause = game.time
      LastOrbPause = game.time 
      LastOrbPauseTime = 1 
      common.ResetOrbDelay(1.75+0.01)
    elseif spell.name == "ApheliosCalibrumQ" and (game.time + spell.windUpTime) >= LastOrbPause + LastOrbPauseTime then 
      CalibrumT = game.time + CalculateRealCD(CalibrumCD[spell_level])
      orb.core.set_pause_attack(spell.windUpTime)
      if menu.d.printDebug:get() and spell.windUpTime > 0.1 and game.time - lastDebugPrint >0.01 then 
        print("ApheliosCalibrumQ winduptime" .. tostring(common.round(spell.windUpTime,2)))
      end
      LastWindupPause = game.time
      LastOrbPause = game.time 
      LastOrbPauseTime = spell.windUpTime
      common.ResetOrbDelay(spell.windUpTime)
    elseif spell.name == "ApheliosInfernumQ" and (game.time + spell.windUpTime) >= LastOrbPause + LastOrbPauseTime then 
      InfernumT = game.time + CalculateRealCD(InfernumCD[spell_level])
      orb.core.set_pause_attack(spell.windUpTime)
      LastWindupPause = game.time
      LastOrbPause = game.time 
      LastOrbPauseTime = spell.windUpTime
      if menu.d.printDebug:get() and spell.windUpTime > 0.1 and game.time - lastDebugPrint >0.05  then 
        print("ApheliosInfernumQ winduptime" .. tostring(common.round(spell.windUpTime,2)))
      end
      common.ResetOrbDelay(spell.windUpTime)
    elseif spell.name == "ApheliosCrescendumQ" and game.time - LastWindupPause > 0.05  and (game.time + spell.windUpTime) >= (LastOrbPause + LastOrbPauseTime) then 
      CrescendumT = game.time + CalculateRealCD(CrescendumCD[spell_level])
      orb.core.set_pause_attack(spell.windUpTime)
      LastWindupPause = game.time
      LastOrbPause = game.time 
      LastOrbPauseTime = spell.windUpTime
      if menu.d.printDebug:get() and spell.windUpTime > 0.1 and game.time - lastDebugPrint >0.05  then 
        print("ApheliosCrescendumQ winduptime" .. tostring(common.round(spell.windUpTime,2)))
      end
    elseif spell.name == "ApheliosW" and game.time - LastWindupPause > 0.05 and (game.time + spell.windUpTime) >= LastOrbPause + LastOrbPauseTime then 
      orb.core.set_pause_attack(spell.windUpTime) 
      if menu.d.printDebug:get() and spell.windUpTime > 0.05 and game.time - lastDebugPrint >0.05 then 
        print("ApheliosW winduptime" .. tostring(common.round(spell.windUpTime,2)))
      end
      LastOrbPause = game.time 
      LastOrbPauseTime = spell.windUpTime
      LastWindupPause = game.time
      LastSwapTime = game.time
    elseif spell.name == "ApheliosR" and game.time - LastWindupPause > 0.2 and (game.time + spell.windUpTime) >= LastOrbPause + LastOrbPauseTime then 
      orb.core.set_pause_attack(spell.windUpTime)  
      LastWindupPause = game.time
      LastOrbPause = game.time 
      LastOrbPauseTime = spell.windUpTime
      if menu.d.printDebug:get() and spell.windUpTime > 0.1 and game.time - lastDebugPrint >0.05 then 
        print("ApheliosR winduptime" .. tostring(common.round(spell.windUpTime,2)))
      end
    end
    -- if menu.d.printDebug:get() and MainGunAmmo < 3 or MainGunAmmo >= 49 then 
    --   print("Current process spell stacks .." .. tostring(MainGunAmmo))
    --   print(spell.name)
    -- end
  end

end


local function SwapNow()
  if player:spellSlot(1).state == 0 then
    player:castSpell("self", 1)
    orb.core.set_server_pause()  
  end 
end 

local function SwapDelay(delay)
  if player:spellSlot(1).state == 0 and game.time - LastSwapTime > delay then 
    player:castSpell("self", 1)
    orb.core.set_server_pause()     
  end 
end  

--{OOR}
local function Priority(MainGunName, AltGunName)
  if MainGunName == "Calibrum" and AltGunName == "Severum" then 
    return {OOR = "Calibrum", BothR = "Calibrum", OneVsOne="Severum", AOE="Calibrum", Low="Severum"}
  elseif MainGunName == "Severum" and AltGunName == "Calibrum" then 

  end 

  if MainGunName == "Calibrum" and AltGunName == "Gravitum" then 

  elseif MainGunName == "Gravitum" and AltGunName == "Calibrum" then 

  end 

  if MainGunName == "Calibrum" and AltGunName == "Infernum" then 

  elseif MainGunName == "Infernum" and AltGunName == "Calibrum" then 

  end 
  
  if MainGunName == "Calibrum" and AltGunName == "Crescendum" then 

  elseif MainGunName == "Crescendum" and AltGunName == "Calibrum" then 

  end 

  if MainGunName == "Severum" and AltGunName == "Gravitum" then 

  elseif MainGunName == "Gravitum" and AltGunName == "Severum" then 

  end 

  if MainGunName == "Severum" and AltGunName == "Infernum" then 

  elseif MainGunName == "Infernum" and AltGunName == "Severum" then 

  end 

  if MainGunName == "Severum" and AltGunName == "Crescendum" then 

  elseif MainGunName == "Crescendum" and AltGunName == "Severum" then 

  end 

  if MainGunName == "Gravitum" and AltGunName == "Infernum" then 

  elseif MainGunName == "Infernum" and AltGunName == "Gravitum" then 

  end   

  if MainGunName == "Gravitum" and AltGunName == "Crescendum" then 

  elseif MainGunName == "Crescendum" and AltGunName == "Gravitum" then 

  end   

  if MainGunName == "Infernum" and AltGunName == "Crescendum" then 

  elseif MainGunName == "Crescendum" and AltGunName == "Infernum" then 

  end   
end


local function AutoSwapCombo()
  AATarget = GetTargetAA()
  CalibrumAATarget = GetTargetAACalibrum()
  if player:spellSlot(1).state == 1 then return end 
    
  if MainGunReady() and AltGunReady() then 
    --Out of range default 
    if AltGun == "Gravitum" and CountInTurretRangeWithGravitum() >= 3 then  
        SwapDelay(0.25)      
    elseif not (common.IsValidTarget(AATarget) or common.IsValidTarget(CalibrumAATarget)) and common.IsValidTarget(CalibrumQTarget) then 
      if MainGun == "Calibrum" then return 
      elseif AltGun == "Calibrum" then 
        SwapDelay(2.5)
      elseif MainGun == "Infernum" then return 
      elseif AltGun == "Infernum" then 
        SwapDelay(2.5)
      elseif MainGun == "Crescendum" then return 
      elseif AltGun == "Crescendum" then 
        SwapDelay(2.5)
      elseif AltGun == "Severum" and common.GetPercentHealth() < menu.swap.severumlow:get() then 
        SwapDelay(2.5)  
      elseif MainGun == "Severum" and common.GetPercentHealth() >= menu.swap.severumhigh:get() then 
        SwapDelay(2.5)
      end 
    --Calibrum range checks first 
    elseif AltGun == "Calibrum" and not common.IsValidTarget(AATarget) and (common.IsValidTarget(CalibrumAATarget) or common.IsValidTarget(CalibrumQTarget)) then 
      SwapDelay(2.5)
    elseif AltGun == "Calibrum" and not (common.IsValidTarget(AATarget) or common.IsValidTarget(CalibrumAATarget) or common.IsValidTarget(CalibrumQTarget)) then 
      SwapDelay(0.5)
    elseif MainGun == "Calibrum" and not common.IsValidTarget(AATarget) and (common.IsValidTarget(CalibrumAATarget) or common.IsValidTarget(CalibrumQTarget)) then 
      --don't swap out 

    --Severum low checks 
    elseif MainGun == "Severum" and common.IsValidTarget(AATarget) and common.GetPercentHealth() < menu.swap.severumlow:get() then  
      --DON'T SWAP OUT
    elseif AltGun == "Severum" and common.IsValidTarget(AATarget) and common.GetPercentHealth() < menu.swap.severumlow:get() and player.pos:dist(AATarget.pos) < 475 then 
      --Swap into severum when low
      SwapDelay(0.5)
    elseif common.IsValidTarget(AATarget) and MainGun == "Severum" and (AltGun == "Infernum" or AltGun == "Calibrum" or AltGun == "Crescendum") and  common.GetPercentHealth() >= menu.swap.severumhigh:get() and player.pos:dist(AATarget.pos) > 510 then 
      SwapDelay(0.5)

    --Infernum checks
    elseif MainGun == "Infernum" and common.IsValidTarget(CalibrumAATarget) and common.tablelength(common.GetEnemyHeroesInRange(210, CalibrumAATarget)) >= 2 then 
      --Don't swap out
    elseif AltGun == "Infernum" and common.IsValidTarget(CalibrumAATarget) and common.tablelength(common.GetEnemyHeroesInRange(210, CalibrumAATarget)) >= 2 then 
      SwapDelay(0.5)
    --elseif MainGun == "Crescendum" 
    --Crescendum Checks 
    elseif AltGun == "Gravitum" and common.IsValidTarget(CalibrumAATarget) and common.CheckBuff(CalibrumAATarget, "ApheliosGravitumDebuff") and 
          (common.tablelength(common.GetEnemyHeroesInRange(250))<2 or common.tablelength(common.GetEnemyHeroesInRange(485))<3 or common.tablelength(common.GetEnemyHeroesInRange(1000))<4) then
      SwapDelay(0.5)     
    elseif common.IsValidTarget(AATarget) and AltGun == "Crescendum" and player:spellSlot(1).state == 0 and CountSnared(AATarget.pos, 0.75, 475) >= 2 then 
      SwapDelay(0.5)
    end
  -- elseif not MainGunReady() and AltGunReady() and not (AltGun == "Crescendum" and CrescendumBuffs < menu.swap.stacks:get() and menu.swap.crescendum:get()) and not (MainGun == "Severum" or MainGun == "Infernum" or (MainGun == "Calibrum" and menu.swap.crescendumcal:get())) then -- 
  --   if menu.d.printDebug:get() then 
  --     print("Prevented swap out of Ccrescendum due to forced crescendum stacking2")
  --   end
  elseif not MainGunReady() and AltGunReady() then -- 
    --Don't swap logic first 
    --if common.IsValidTarget(AATarget) and AltGun == "Severum" and common.GetPercentHealth() > menu.swap.severumhigh:get() and player.pos:dist(AATarget) >= 475 then 
    if common.IsValidTarget(AATarget) and (MainGun == "Crescendum" or MainGun == "Infernum" or MainGun == "Calibrum") and AltGun == "Gravitum" and player.pos:dist(AATarget.pos) < 425+AATarget.boundingRadius and player.pos:dist(AATarget.pos) > 535+AATarget.boundingRadius and common.tablelength(common.GetEnemyHeroesInRange(1200,AATarget.pos)) < 3 and CountInTurretRangeWithGravitum() < 3  then     
    elseif not common.IsValidTarget(AATarget) and (common.IsValidTarget(CalibrumAATarget) or  common.IsValidTarget(CalibrumQTarget)) and MainGun == "Calibrum" and AltGun ~= "Crescendum" then 
    elseif player:spellSlot(1).state == 0 then  --then cast all other times
      player:castSpell("self", 1)
      orb.core.set_server_pause()
    end
  elseif not MainGunReady() and not AltGunReady() then -- specify no gun ready order
    if AltGun == "Calibrum" and not common.IsValidTarget(AATarget) and not common.IsValidTarget(CalibrumAATarget) and common.IsValidTarget(CalibrumQTarget) then 
      player:castSpell("self", 1)
      orb.core.set_server_pause()
    elseif AltGun == "Calibrum" and not common.IsValidTarget(AATarget) and common.IsValidTarget(CalibrumAATarget) then
      player:castSpell("self", 1)
      orb.core.set_server_pause()
      --print("")
    elseif AltGun == "Infernum" and common.IsValidTarget(AATarget) and common.tablelength(common.GetEnemyHeroesInRange(210, AATarget.pos)) >= 2 then 
      player:castSpell("self", 1)
      orb.core.set_server_pause()
    elseif MainGun == "Severum" and common.GetPercentHealth() > menu.swap.severumhigh:get() and game.time - LastSwapTime > 1.75 and
          AltGun ~= "Gravitum" then 
      player:castSpell("self", 1)
      orb.core.set_server_pause()
    elseif MainGun == "Crescendum" and (AltGun == "Severum" or AltGun == "Infernum" or (AltGun == "Calibrum" and menu.swap.crescendumcal:get())) and common.IsValidTarget(AATarget) and CrescendumBuffs < menu.swap.stacks:get() and game.time - LastSwapTime > 3 then 
      player:castSpell("self", 1)
      orb.core.set_server_pause()
      --print("CondB")
    elseif AltGun == "Crescendum" and (MainGun == "Severum" or MainGun == "Infernum" or (MainGun == "Calibrum" and menu.swap.crescendumcal:get())) and common.IsValidTarget(AATarget) and CrescendumBuffs >= menu.swap.stacks:get() and game.time - LastSwapTime > 3 then 
      player:castSpell("self", 1)
      orb.core.set_server_pause()
    elseif AltGun == "Crescendum" and common.IsValidTarget(AATarget) and CountUltHit(vec3(AATarget.pos.x, player.pos.z, AATarget.pos.y), 700)==1 and (AATarget.health/AATarget.maxHealth) < 0.70 then
      player:castSpell("self", 1)
      orb.core.set_server_pause()      
    elseif MainGun == "Gravitum" and (AltGun == "Calibrum" or AltGun == "Infernum" or AltGun == "Crescendum")  and common.IsValidTarget(AATarget) and GravitumT - game.time > 0.75 then 
      SwapDelay(0.5)
    elseif MainGun == "Severum" and (AltGun == "Calibrum" or AltGun == "Infernum" or AltGun == "Crescendum")  and common.IsValidTarget(AATarget) and SeverumT - game.time > 0.75 then 
      SwapDelay(0.5)
    elseif MainGun == "Calibrum" and (AltGun == "Infernum" or AltGun == "Crescendum")  and common.IsValidTarget(AATarget) and CalibrumT - game.time > 0.75 and AltCD() < MainCD() then 
      SwapDelay(0.5)
    elseif (MainGun == "Calibrum" or MainGun == "Infernum" or MainGun == "Crescendum" or MainGun == "Severum") and AltGun == "Gravitum" and common.IsValidTarget(AATarget)  and GravitumT - game.time > 1 and MainCD() < AltCD() then 
    end 
  end
end 


local function FarmSwap(mob) 
  if not menu.swap.usefarm:get() then return end 
  if not player:spellSlot(1).state == 0 then return end 
  if menu.swap.farmsave:get() then return end 
  if mob.pos then 
    mob_pos = vec3(mob.pos.x, player.pos.z, mob.pos.y)
  else 
    return
  end
  local MobSev = false 
  local MobAA = false
  local MobQ = false 
  local MobCAA = false 
  if player.pos2D:dist(mob.pos2D) < 525 then MobSev = true else MobSev = false end 
  if player.pos2D:dist(mob.pos2D) < AArange then MobAA = true else MobAA = false end 
  if player.pos2D:dist(mob.pos2D) < CalibrumAArange then MobCAA = true else MobCAA = false end 
  if player.pos2D:dist(mob.pos2D) < spellCalibrumQ.range then MobQ = true else MobQ = false end 
  local EnoughQMana = ((player.mana/player.maxMana)*100 > menu.f.manaManager:get())
  if MainGunReady() and AltGunReady() and (MobAA or MobCAA or MobQ) then 
    --Severum health swap 
    if AltGun == "Severum" and common.GetPercentHealth() < menu.swap.severumlow:get() and MobAA then 
      player:castSpell("self", 1)
      orb.core.set_server_pause()
    elseif MobAA and MainGun == "Severum" and AltGun ~= "Gravitum" and common.GetPercentHealth()+10 > menu.swap.severumhigh:get() then 
      player:castSpell("self", 1)
      orb.core.set_server_pause()
    end 

    --Swap to Calibrum when out of range 
    if not MobAA and (MobCAA or MobQ) and AltGun == "Calibrum" then 
      player:castSpell("self", 1)
      orb.core.set_server_pause()
    end 

    --Swap to Infernum when AOE 
    if MobAA and mob_pos and AltGun == "Infernum" and ((common.tablelength(common.GetMinionsInRange(300, TEAM_ENEMY, mob_pos)) >= 3) or 
        (common.tablelength(common.GetMinionsInRange(300, TEAM_NEUTRAL, mob_pos)) >= 3)) then 
      player:castSpell("self", 1)
      orb.core.set_server_pause()      
    end 

    --Swap out of Gravitum 
    if MobAA and MainGun == "Gravitum" and not menu.f.useQslow:get() then 
      player:castSpell("self", 1)
      orb.core.set_server_pause()
    end 

    --Swap into Crescendum for turret 
    if MobAA and AltGun == "Crescendum" and MainGun ~= "Infernum" and ((common.tablelength(common.GetMinionsInRange(400, TEAM_ENEMY, mob_pos)) >= 3) or 
        (common.tablelength(common.GetMinionsInRange(400, TEAM_NEUTRAL, mob_pos)) >= 3)) then 
      player:castSpell("self", 1)
      orb.core.set_server_pause()      
    end 

  elseif not MainGunReady() and AltGunReady() then 
    --Prevent swapping if no targets in range 
    if MainGun == "Calibrum" and not MobAA and (MobCAA or MobQ) then  
        return 
    --Prevent swap into Garvitum
    elseif AltGun == "Gravitum" and not menu.f.useQslow:get() then 
        return 
    --Prevent swapping out of Calibrum if out of range 
    elseif MainGun == "Calibrum" and not MobAA and (MobCAA or MobQ) then 
        return
    else
      player:castSpell("self", 1)
      orb.core.set_server_pause()  
    end   
  
  elseif ((not MainGunReady() and not AltGunReady()) or not EnoughQMana) then 
    --Severum swap logic 
    if AltGun == "Severum" and common.GetPercentHealth() < menu.swap.severumlow:get() then 
      player:castSpell("self", 1)
      orb.core.set_server_pause()
    elseif MainGun == "Severum" and AltGun ~= "Gravitum" and common.GetPercentHealth() > menu.swap.severumhigh:get() then 
      player:castSpell("self", 1)
      orb.core.set_server_pause()
    end 

    --Swap calibrum range 
    if not MobAA and (MobCAA or MobQ) and AltGun == "Calibrum" then 
      player:castSpell("self", 1)
      orb.core.set_server_pause()
    end 

    --Swap infernum 
    if MobAA and mob_pos and AltGun == "Infernum" and ((common.tablelength(common.GetMinionsInRange(300, TEAM_ENEMY, mob_pos)) >= 3) or 
        (common.tablelength(common.GetMinionsInRange(300, TEAM_NEUTRAL, mob_pos)) >= 3)) then 
      player:castSpell("self", 1)
      orb.core.set_server_pause()      
    end 
  end 
end


local function FarmUse(mob) --Q state usage for farm mode
  if not menu.f.useQ:get() then return end 
  if not common.IsValidTarget(mob) then return end 
  local EnoughQMana = ((player.mana/player.maxMana)*100 > menu.f.manaManager:get())
  if not EnoughQMana then return end 
  if mob.pos then 
    mob_pos = vec3(mob.pos.x, player.pos.z, mob.pos.y)
  else 
    return
  end

  --Let Hanbot Orb takeover for 3 targeted spells 
  if MainGun == "Infernum" and MainGunReady then 
    seg, obj = orb.farm.skill_clear_linear(spellInfernumQ)
    if seg and player.pos:dist(vec3(seg.endPos.x, 0, seg.endPos.y)) < spellInfernumQ.range then 
      player:castSpell("pos", 0, vec3(seg.endPos.x, player.pos.y, seg.endPos.y))
      orb.core.set_server_pause()
    end   
  elseif MainGun == "Calibrum" and MainGunReady then  
    seg, obj = orb.farm.skill_clear_linear(spellCalibrumQ)
    if seg and player.pos:dist(vec3(seg.endPos.x, 0, seg.endPos.y)) < spellCalibrumQ.range then 
      player:castSpell("pos", 0 , vec3(seg.endPos.x, player.pos.y, seg.endPos.y))
      orb.core.set_server_pause()
    end   
  elseif MainGun == "Crescendum" and MainGunReady then 
    seg, obj = orb.farm.skill_clear_linear(spellCrescendumQFarm)
    if seg and player.pos:dist(vec3(seg.endPos.x, 0, seg.endPos.y)) < spellCrescendumQFarm.range then 
      player:castSpell("pos", 0 , vec3(seg.endPos.x, player.pos.y, seg.endPos.y))
      orb.core.set_server_pause()
    end   
  elseif MainGun == "Severum" and MainGunReady then 
    seg, obj = orb.farm.skill_clear_target(spellSeverumQ)
    if seg and obj and obj.pos and player.pos:dist(vec3(seg.endPos.x, 0, seg.endPos.y)) < spellSeverumQ.range then 
      player:castSpell("obj", 0 , obj)
      orb.core.set_server_pause()
    end
  end 

  --Manually use two other spells 
  local MobSev = false 
  local MobAA = false
  local MobQ = false 
  local MobCAA = false 
  if player.pos2D:dist(mob.pos2D) < 525 then MobSev = true else MobSev = false end 
  if player.pos2D:dist(mob.pos2D) < AArange then MobAA = true else MobAA = false end 
  if player.pos2D:dist(mob.pos2D) < CalibrumAArange then MobCAA = true else MobCAA = false end 
  if player.pos2D:dist(mob.pos2D) < spellCalibrumQ.range then MobQ = true else MobQ = false end 
  -- if menu.d.printDebug:get() and game.time - lastDebugPrint > 10 then 
  --   print(player.pos2D:dist(mob.pos2D))
  -- end
  if MobAA and MainGun == "Gravitum" and menu.f.useQslow:get()  and MainGunReady then 
    player:castSpell("self", 0)
    orb.core.set_server_pause()
  end   
end 

local function Clear()
  local EnoughQMana = ((player.mana/player.maxMana)*100 > menu.f.manaManager:get())
  if orb.farm.clear_target and player.pos2D:dist(orb.farm.clear_target.pos2D) < spellCalibrumQ.range-50 then 
    FarmUse(orb.farm.clear_target)
    if not(menu.misc.manualswaptoggle:get() and menu.misc.manualswap:get()) then 
      FarmSwap(orb.farm.clear_target)
    end
  end

  -- for i = 0, ObjMinion_Type.size[TEAM_NEUTRAL] - 1 do
  --       local mob = ObjMinion_Type[TEAM_NEUTRAL][i]
  --       if mob.pos and valid_minion(mob) and common.can_target_minion(mob) and player.pos2D:dist(mob.pos2D) < spellCalibrumQ.range then 
  --         FarmUse(mob)
  --         FarmSwap(mob)
  --       end
  --   end

  -- for i = 0, ObjMinion_Type.size[TEAM_ENEMY] - 1 do
  --       local mob = ObjMinion_Type[TEAM_ENEMY][i]
  --       if mob.pos and valid_minion(mob) and common.can_target_minion(mob) and player.pos:dist(vec3(mob.pos.x, player.pos.z, mob.pos.y)) < spellCalibrumQ.range  then 
  --         FarmUse(mob)
  --         FarmSwap(mob)
  --       end 
  -- end  
end 

function SlowPredR(target, segment)
    if pred.collision.get_prediction(spellR, segment, target) then 
      return false
    end

    if segment.startPos:dist(segment.endPos) < spellR.range then 
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

    if menu.c.ultKey:get() then 
      return true 
    end 
end



local function RLogic(obj, segment) 
  if menu.c.slowPred:get() then 
    if menu.c.forceInfernumR:get() and player:spellSlot(1).state == 0 and AltGun == "Infernum" then 
      player:castSpell("self",1)
      orb.core.set_server_pause()
    elseif menu.c.forceInfernumR:get() and MainGun == "Infernum" then 
      player:castSpell("pos", 3, vec3(segment.endPos.x, 0, segment.endPos.y))
      orb.core.set_server_pause()
    elseif menu.c.forceGravitumR:get() and player:spellSlot(1).state == 0  and MainGun ~= "Infernum" and AltGun ~= "Infernum" and AltGun == "Gravitum" then 
      player:castSpell("self",1)
      orb.core.set_server_pause()
    elseif menu.c.forceGravitumR:get() and MainGun ~= "Infernum" and AltGun ~= "Infernum" and MainGun == "Gravitum" then 
      player:castSpell("pos", 3, vec3(segment.endPos.x, 0, segment.endPos.y))
      orb.core.set_server_pause()
    elseif menu.c.forceSeverumR:get() and common.GetPercentHealth() < 0.18 and player:spellSlot(1).state == 0 and MainGun ~= "Infernum" and AltGun ~= "Infernum" and  MainGun ~= "Gravitum" and AltGun ~= "Gravitum" and AltGun == "Severum" then 
      player:castSpell("self",1)
      orb.core.set_server_pause()
    elseif menu.c.forceSeverumR:get() and common.GetPercentHealth() > 0.45 and MainGun == "Severum" and player:spellSlot(1).state == 0 then 
      player:castSpell("self",1)
      orb.core.set_server_pause()
    else
      player:castSpell("pos", 3, vec3(segment.endPos.x, 0, segment.endPos.y))
      orb.core.set_server_pause()
    end 
  end
end 
 

local function AutoUlt()
  for _,obj in ipairs(common.GetEnemyHeroesInRange(spellR.range, player.pos)) do
    if common.IsValidTarget(obj) and player:spellSlot(3).state == 0 then 
      local segment = pred.linear.get_prediction(spellR, obj, player)
      local seg_vec3 = vec3(segment.endPos.x,0 , segment.endPos.y)
      if seg_vec3 and SlowPredR(obj, segment) and common.IsValidTarget(obj) and CountUltHit(seg_vec3, 400) >= menu.c.ultNum:get() then 
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
    local D = orb.utility.get_damage(player,target,true) + CalibrumQDamageTable[player:spellSlot(0).level] + 0.3*common.GetBonusAD(player) + 1
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
      damage = (common.CalculatePhysicalDamage(target, D))*CountUltHit(target.pos, 235)
    elseif mode == "Severum" then 
      damage = common.CalculatePhysicalDamage(target, D)
    elseif mode == "Infernum" then 
      D = D + (InfernumBonusMark[player:spellSlot(3).level] + common.GetBonusAD(player) * 0.25)*CountUltHit(target.pos, 235)
      damage = common.CalculatePhysicalDamage(target, D)
    elseif mode == "Crescendum" then 
      damage = common.CalculatePhysicalDamage(target, D)
    end
    return damage
  else 
    return 0
  end
end  

--Add later
-- local function FindCrescendumQCastLoc(target) 
--     if Common.IsValidTarget(target) and player:post.

-- end



-- local function CrescendumQKS(target)
--     if spell:splot(0).state == 0 and MainGun == "Crescendum" then
--         if orb.tett
--     end

-- end

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

  if menu.ks.considerRKS:get() and MainGun =="Calibrum" then 
    Rdam = Rdam + Procdam 
  end 

  --Proc KS
  if menu.ks.useMark:get() and IsSafe(215)  then 
    if target and common.IsValidTarget(target) and target.health < Procdam+25 and target.buffManager then 
      for i = 0, target.buffManager.count - 1 do
        local buff = target.buffManager:get(i)
        if buff and buff.valid and buff.name == "aphelioscalibrumbonusrangedebuff" and  buff.source == player and (buff.stacks > 0 or buff.stacks2 > 0) then
          --print("Buff " .. buff.name .. "active")
          player:attack(target)
          orb.core.set_server_pause_attack()
        end
      end
    end
  end
  --Q KS 
  if menu.ks.useQ:get() and IsSafe(215) and player.mana > 60  then  
    if target and common.IsValidTarget(target) and target.health < Qdam then 
      local segment = pred.linear.get_prediction(spellCalibrumQ, target, player)
      if SlowPredQ(target, segment) and common.IsValidTarget(target) then 
        if MainGun == "Calibrum" then 
          player:castSpell("pos", 0, vec3(segment.endPos.x, target.y, segment.endPos.y))
          orb.core.set_server_pause()
          if menu.d.printDebug:get() and game.time - lastDebugPrint > 0.25 then 
              print("Q ks active")
          end

        elseif AltGun == "Calibrum" and player:spellSlot(1).state == 0 and menu.ks.swap:get() then 
          pred_pos = pred.core.get_pos_after_time(target, 0.3)
          if player.pos:dist(vec3(pred_pos.x,player.pos.z ,pred_pos.y)) < spellCalibrumQ.range then 
            player:castSpell("self", 1)
            orb.core.set_server_pause()
            if menu.d.printDebug:get() and game.time - lastDebugPrint > 0.25  then 
                print("Q ks swap is active")
            end
          end            
        end
      end
    end  
  end 

  --R KS
  if (menu.ks.useR:get() or menu.ks.useRsmart:get()) and IsSafe(215) and player.mana > 100 then
      if target and common.IsValidTarget(target) and target.health < Rdam then 
        local segment = pred.linear.get_prediction(spellR, target, player)
        if SlowPredR(target, segment) and common.IsValidTarget(target) and menu.ks.useR:get() then 
          player:castSpell("pos", 3, vec3(segment.endPos.x, player.pos.z, segment.endPos.y))
          orb.core.set_server_pause()
          if menu.d.printDebug:get() and game.time - lastDebugPrint > 0.25 then 
            print("R ks swap is active")
          end
        end
        local seg_vec3 = vec3(segment.endPos.x, target.z, segment.endPos.y)
        if SlowPredR(target, segment) and common.IsValidTarget(target) and menu.ks.useRsmart:get() and CountUltHit(seg_vec3, 375) >= 2 then 
          player:castSpell("pos", 3, vec3(segment.endPos.x, player.pos.z, segment.endPos.y))
          orb.core.set_server_pause()
          if menu.d.printDebug:get() and game.time - lastDebugPrint > 0.25 then 
          end
        end
        if menu.ks.useRsmartone:get() and SlowPredR(target, segment) and common.IsValidTarget(target) and menu.ks.useRsmart:get() and 
            common.tablelength(common.GetEnemyHeroesInRange(1850)) < 3  and common.tablelength(common.GetAllyHeroesInRange(950)) < 2 then 
          player:castSpell("pos", 3, vec3(segment.endPos.x, player.pos.z, segment.endPos.y))
          orb.core.set_server_pause()
          if menu.d.printDebug:get() and game.time - lastDebugPrint > 0.25 then 
            print("R ks swap is active smart2")
          end
        end
      end
    elseif target and menu.ks.useRsmart:get() and common.IsValidTarget(target) and AltGun == "Infernum" and CalcRDamage(target, "Infernum") > target.health and player:spellSlot(1).state == 0 then
      if SlowPredR(target, segment) and common.IsValidTarget(target) and menu.ks.useRsmart:get() and CountUltHit(seg_vec3, 250) >= 2 then 
        player:castSpell("self", 1)
        if menu.d.printDebug:get() and game.time - lastDebugPrint > 0.25 then 
          print("R ks swap is active smart3")
        end
      end
      if menu.ks.useRsmartone:get() and SlowPredR(target, segment) and common.IsValidTarget(target) and menu.ks.useRsmart:get() and 
          AltGun == "Infernum" and CalcRDamage(target, "Infernum") > target.health and 
          common.GetEnemyHeroesInRange(900, target.pos) < 2 and common.tablelength(common.GetEnemyHeroesInRange(1500)) < 2 and common.tablelength(common.GetAllyHeroesInRange(950)) < 3 then 
        player:castSpell("self", 1)
        orb.core.set_server_pause()
        if menu.d.printDebug:get() and game.time - lastDebugPrint > 0.25 then 
          print("R ks swap is active smart4")
        end
      end   
    end   

end 
--R KS 
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
  if MainGunAmmo == 0 and game.time - lastDebugPrint > 10 then
    lastDebugPrint = game.time 
    print("I HIT 0 MAIN GUN AMMO")
  end

  -- if menu.d.debugKey:get() then 
  --   for i = 0, player.buffManager.count - 1 do
  --       local buff = player.buffManager:get(i)
  --       if menu.d.printDebug:get() and buff and buff.valid and buff.source == player and (buff.stacks >= 2 or buff.stacks2 >= 2) and buff.endTime - game.time > 0.05 then
  --         if buff.name ~= "apheliospbuffad" or buff.name ~= "apheliospbuffas" or buff.name ~= "apheliospbuffap" or buff.name ~= "sru_crabspeedboost" then  
  --           if buff.stacks and buff.name then 
  --             print("Buff name with " .. tostring(buff.name) .. " with stacks " .. tostring(buff.stacks) .. " " .. tostring(buff.stacks2) .. " " .. tostring(buff.endTime-game.time)) 
  --           end
  --         end
  --       end
  --   end
  -- end 

  -- if menu.d.debugKey:get() and game.time - lastDebugPrint>= 0.1 then 
  --   for i=0, objManager.maxObjects-1 do
  --       local obj = objManager.get(i)
  --       if obj and obj.name and obj.owner and obj.owner.ptr == player.ptr then
  --         if string.find(obj.name, "aphelios") or string.find(obj.name, "Aphelios") then
  --           print(obj.name .. " " .. obj.charName)
  --           lastDebugPrint = game.time 
  --         end
  --       end
  --   end
  -- end 

  -- if MainGunAmmo < 2 or MainGunAmmo == 50 and game.time - lastDebugPrint>= 0.1 then 
  --   --print("Current stacks .." .. tostring(MainGunAmmo))

  --   for i = 0, player.buffManager.count - 1 do
  --       local buff = player.buffManager:get(i)
  --       if menu.d.printDebug:get() and buff and buff.valid and buff.source == player and (buff.stacks > 0 or buff.stacks2 > 0) then
  --         if buff.name ~= "apheliosbuffad" or buff.name ~= "apheliosbuffas" or buff.name ~= "sru_crabspeedboost" then  
  --           --print(buff.name)
  --           if buff.name == "aphelioslockfacing" and MainGun == "Severum" then 
  --             --print("Bingo")
  --             time_left = buff.endTime - game.time              
  --             --orb.core.set_pause_attack(time_left)
  --             -- print('aphelioslockfacing exists with endtime ' .. tostring(time_left))
  --             -- local coloractive = graphics.argb(255, 25, 185,50)
  --             -- local colorCD = graphics.argb(255, 185, 25, 50)
  --             -- local player_world_pos = graphics.world_to_screen(player.pos)
  --             -- graphics.draw_text_2D('aphelioslockfacing exists with endtime ' .. tostring(time_left) , 18, player_world_pos.x-105, player_world_pos.y-125, colorCD)
  --           end
  --         end
  --       end
  --   end
  --   lastDebugPrint = game.time 
  -- end
end 

local function OnCreateMinion(obj)  
  if obj and (obj.name or obj.charName) and obj.owner and obj.owner.ptr == player.ptr and obj.pos and obj.team == TEAM_ALLY and obj.name == "ApheliosTurret" then
    table.insert(ApheliosTurret, obj)
    if menu.d.printDebug:get() and game.time - lastDebugPrint > 0.5 then 
      print("TurretFounda!")
      lastDebugPrint = game.time 
    end 
    orb.core.reset()
    common.ResetOrb()
    common.ResetAllOrbDelay(network.latency+0.01)
  end
end

local function OnDeleteMinion(obj)  
  for idx, turret in ipairs(ApheliosTurret) do 
    if turret.ptr == obj.ptr then 
      _ = table.remove(ApheliosTurret, idx)
      if menu.d.printDebug:get() and game.time - lastDebugPrint > 0.5 then 
        print("TurretDeleted!")
        lastDebugPrint = game.time 
      end
    end 
  end
end

local function OnTick()

  if common.CheckBuff(player, "aphelioslockfacing") then 
      -- if menu.d.printDebug:get() then 
      --   print("returning aphelios lock2")
      -- end
      --player:move(game.mousePos)
    _,cur_end_time = common.CheckBuffWithTimeEnd(player, "aphelioslockfacing") 
    --if cur_end_time and cur_end_time - game.time > 0 and IsSeverumQ then
    --if cur_end_time and cur_end_time - game.time > 0 and (IsSeverumQ or MainGun == "Infernum" or player.sar < 2) then
    if cur_end_time and cur_end_time - game.time > 0 then
      --orb.core.set_pause(cur_end_time - game.time)
      if game.time - LastMoveOrder > 0.02 then 
        --if player.pos:dist(mousePos) > 250 then 
          --common.MoveToNormalizeMouse()
        --else
          player:move(mousePos) 
        --end
        LastMoveOrder = game.time 
      end
      LastFacingTick = game.time 
      --common.ResetOrbDelay(cur_end_time - game.time)
      -- if menu.d.printDebug:get() then 
      --   print("returning aphelios lock3" .. tostring(common.round(cur_end_time - game.time ,2)))
      --   print("Game time " .. tostring(common.round(game.time)) .. " lockend " ..  tostring(common.round(cur_end_time)))
      -- end
    else 
      if menu.d.printDebug:get() then 
        print("Resetting ORB")
      end
      common.ResetOrb()

    end
  else  

  end 


  CheckSpellState()
  CheckWeapons()
  HotKeyChecks()
  -- for i = 0, player.buffManager.count - 1 do
  --     local buff = player.buffManager:get(i)
  --     if buff and buff.valid and buff.source == player and (buff.stacks > 0 or buff.stacks2 > 0) then
  --       if buff.name ~= "apheliosbuffad" or buff.name ~= "apheliosbuffas" or buff.name ~= "sru_crabspeedboost" then  
  --         --print(buff.name)
  --         if buff.name == "aphelioslockfacing" and game.time - LastOrbPause >= 1.75 and MainGun == "Severum" then 
  --           --print("Bingo")
  --           time_left = buff.endTime - game.time    
  --           if time_left >= 1.7 then 
  --             orb.core.set_pause_attack(time_left)
  --             LastOrbPause = game.time
  --           end
  --         end
  --       end
  --     end
  -- end

  if menu.d.printDebug:get() then 
    DebugPrint()
    --print(MainGunAmmo)
  end


  if (menu.ks.useQ:get() or menu.ks.useMark:get() or menu.ks.useR:get()) then 
    for _, obj in ipairs(common.GetEnemyHeroes()) do
      if obj and common.IsValidTarget(obj) and player.pos:dist(obj.pos) < 2500 then 
        AutoKS(obj)
      end
    end
  end

  if menu.c.ultKey:get() and player.levelRef > 1 then
    AutoUlt()
    Rtarget = GetTargetR()
    if Rtarget and common.IsValidTarget(Rtarget) and player:spellSlot(3).state == 0 then
      local segment = pred.linear.get_prediction(spellR, Rtarget, player)
      if menu.c.slowPred:get() then 
          if SlowPredR(Rtarget, segment) and common.IsValidTarget(Rtarget) then 
            RLogic(Rtarget, segment)
          end
      end
    end
  end 

  if (orb.menu.combat.key:get()) and player.levelRef > 1 then 
    AutoUlt()
    Combo()
    if not(menu.misc.manualswaptoggle:get() and menu.misc.manualswap:get()) then 
      AutoSwapCombo()
    end
  end

  if orb.menu.lane_clear.key:get() and player.levelRef > 1 and menu.f.farm:get() then 
    Clear()
  end

  if (orb.menu.last_hit.key:get()) and player.levelRef > 1 and menu.f.farm:get() then 
    if MainGun == "Calibrum" and MainGunReady() then 
      local seg, obj = orb.farm.skill_farm_linear(spellCalibrumQ)
      if seg and seg.endPOs and player:spellSlot(0).state == 0 then 
        player:castSpell('pos', 0, seg.endPos)
      end 
    end
    if MainGun == "Infernum" and MainGunReady() then 
      local seg, obj = orb.farm.skill_farm_linear(spellInfernumQ)
      if seg and seg.endPos and player:spellSlot(0).state == 0 then 
        player:castSpell('pos', 0, seg.endPos)
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
      if menu.f.farm:get() then 
        graphics.draw_text_2D('Farm: true', 12, player_world_pos.x, player_world_pos.y+45, coloractive)
      else
        graphics.draw_text_2D('Farm: false', 12, player_world_pos.x, player_world_pos.y+45, colorCD)
      end

      if menu.misc.manualswaptoggle:get() and menu.misc.manualswap:get() then 
        graphics.draw_text_2D('Manual weapon swap: true', 12, player_world_pos.x-22, player_world_pos.y+65, coloractive)
      else
        graphics.draw_text_2D('Manual weapon swap: false', 12, player_world_pos.x-22, player_world_pos.y+65, colorCD)
      end

      farm_offset = 25
      farm_offset_x = 15 
      if not menu.swap.farmsave:get() then 
        graphics.draw_text_2D('Saving: false', 12, player_world_pos.x , player_world_pos.y+farm_offset, colorCD)
      elseif menu.swap.farmsave:get() and AltGun == "Calibrum" then 
        graphics.draw_text_2D('Saving: Calibrum', 12, player_world_pos.x, player_world_pos.y+farm_offset, coloractive)
      elseif menu.swap.farmsave:get() and AltGun == "Crescendum" then 
        graphics.draw_text_2D('Saving: Crescendum', 12, player_world_pos.x, player_world_pos.y+farm_offset, coloractive)
      elseif menu.swap.farmsave:get() and AltGun == "Gravitum" then 
        graphics.draw_text_2D('Saving: Gravitum', 12, player_world_pos.x, player_world_pos.y+farm_offset, coloractive)
      elseif menu.swap.farmsave:get() and AltGun == "Infernum" then 
        graphics.draw_text_2D('Saving: Calibrum', 12, player_world_pos.x, player_world_pos.y+farm_offset, coloractive)
      elseif menu.swap.farmsave:get() and AltGun == "Severum" then 
        graphics.draw_text_2D('Saving: Severum', 12, player_world_pos.x, player_world_pos.y+farm_offset, coloractive)
      end  

      if ApheliosTurret and #ApheliosTurret >= 1 then 
        for idx, turret in ipairs(ApheliosTurret) do 
          if turret.pos then 
            graphics.draw_circle(turret.pos, 550, 5, graphics.argb(255, 0, 255, 0), 100)
            graphics.draw_text_2D(tostring(idx), 22, graphics.world_to_screen(turret.pos).x, graphics.world_to_screen(turret.pos).y-100, coloractive)
          end 
        end
      end 

      local grav_buff_color = graphics.argb(255, 204, 0, 255)
      local calibrum_buff_color = graphics.argb(255, 0, 153, 255)
      if menu.d.drawBuffTimer:get() then 
        if common.CountEnemyHeroesInRange(2750, player) > 0 then 
          for _, obj in ipairs(common.GetEnemyHeroesInRange(2750)) do 
            if obj and obj.pos and common.IsValidTarget(obj) then 
              grav_bool, grav_end_time = common.CheckBuffWithTimeEnd(obj, "ApheliosGravitumDebuff")
              if grav_bool and grav_end_time - game.time >= 0 then 
                graphics.draw_circle(obj.pos, 30, 6, grav_buff_color, 75)
                graphics.draw_text_2D(tostring(common.round(grav_end_time - game.time,2)), 26, graphics.world_to_screen(obj.pos).x, graphics.world_to_screen(obj.pos).y-150, grav_buff_color)
              end
              cal_buff, cal_end_time = common.CheckBuffWithTimeEnd(obj, "aphelioscalibrumbonusrangedebuff")
              if cal_buff and cal_end_time - game.time >= 0 then 
                graphics.draw_circle(obj.pos, 55, 6, calibrum_buff_color, 75)
                graphics.draw_text_2D(tostring(common.round(cal_end_time - game.time,2)), 26, graphics.world_to_screen(obj.pos).x ,graphics.world_to_screen(obj.pos).y-176 , calibrum_buff_color)
              end 
            end
          end
        end
      end
  end 
  if menu.d.drawDebug:get() then
    if AltGunReady() then 
      graphics.draw_text_2D('AltGun: ' .. tostring(AltGun).. " AltGun ready true"  , 18, player_world_pos.x+55, player_world_pos.y+55, colorCD)
    else
      graphics.draw_text_2D('AltGun: ' .. tostring(AltGun).. " AltGun ready false"  , 18, player_world_pos.x+55, player_world_pos.y+55, colorCD)
    end
    if MainGunReady() and MainGun then 
      graphics.draw_text_2D('MainGunReady ' .. tostring(MainGun), 18, player_world_pos.x+55, player_world_pos.y+75, colorCD)
    else 
      graphics.draw_text_2D('NotMainGunReady '.. tostring(MainGun), 18, player_world_pos.x+55, player_world_pos.y+75, colorCD)
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

    if LastOrbPause then 
      graphics.draw_text_2D('Last orb pause '.. tostring(common.round(game.time - LastOrbPause, 2))  .. ' windup pause ' .. tostring(common.round(game.time -LastWindupPause,2)), 18, player_world_pos.x+55, player_world_pos.y-55, colorCD)
    end
    
    if common.CheckBuff(player, "aphelioslockfacing") then 
      graphics.draw_text_2D('Lockfacing true' .. ' SevQ ' .. tostring(IsSeverumQ) .. ' Canattack ' .. tostring(orb.core.can_attack()) .. ' Paused ' .. tostring(orb.core.is_paused()), 28, player_world_pos.x-20, player_world_pos.y-155, coloractive)
    elseif common.CheckBuff(player, "aphelioslockfacing") and pred.trace.newpath(player, 0.1, 1.5) then 
      graphics.draw_text_2D('Lockfacing true' .. ' SevQ ' .. tostring(IsSeverumQ) .. ' Canattack ' .. tostring(orb.core.can_attack()) .. ' Paused ' .. tostring(orb.core.is_paused()) .. ' newpath ' .. tostring(pred.trace.newpath(player, 0.1, 1.5)), 28, player_world_pos.x-20, player_world_pos.y-155, coloractive)
    elseif pred.trace.newpath(player, 0.5, 1.5) then 
      graphics.draw_text_2D(' newpath ' .. tostring(pred.trace.newpath(player, 0.1, 1.5)), 28, player_world_pos.x-20, player_world_pos.y-155, colorCD)
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
cb.add(cb.tick, OnTick)
cb.add(cb.create_minion, OnCreateMinion)
cb.add(cb.delete_minion, OnDeleteMinion)

--cb.add(cb.delete_minion, OnDeleteMinion)
--orb.combat.register_f_pre_tick(OnTick)
chat.print("DienoAlphelios beta version " .. tostring(version) .. " loaded! Please provide feedback to dienofail#1100 on discord")
chat.print("If your orbwalker freezes constantly using this script, check the '(ADV USERS) Pause orb for wep swap)' under combat settings off")