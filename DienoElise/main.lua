local orb = module.internal("orb");
local evade = module.internal("evade");
local pred = module.internal("pred");
local ts = module.internal('TS');
local common = module.load("delise", "common");
local ObjMinion_Type = objManager.minions
local version = 0.02

local spellQ = {
  range = 625,
  delay = 0.25,
}

local spellW = {
  range = 950,
  delay = 0.3,
  width=40,
  speed = math.huge,
  windup=0,
  collision= {hero = false, minion=true},
  boundingRadiusMod =0
}

local spellAA = {
  range = 425
}

local spellE = {
  range = 1075,
  width = 55,
  speed = 1600,
  delay = 0,
  windUp = 0.25,
  collision = {
    hero = true,
    minion = true,
    wall=true,
  },
  boundingRadiusMod = 0
}

local spellSpiderE = {
  range = 1000,
  width = 0,
  speed = math.huge,
  delay = 0.25,
  windUp = 0,
  collision = {
    hero = false,
    minion = false,
  },
  boundingRadiusMod = 0
}

local spellSpiderQ = {
  range = 475,
  width = 0,
  speed = math.huge,
  delay = 0.25,
  windUp = 0,
  collision = {
    hero = false,
    minion = false
  },
  boundingRadiusMod = 0
}

--[[
local HumanTrueQcd, SpiderTrueQcd = 6000, 6000
local HumanTrueWcd, SpiderTrueWcd = 12000, 12000
local HumanTrueEcd = {14000, 13000, 12000, 11000, 10000}
local SpiderTrueEcd = {26000, 24000, 22000, 20000, 18000} 
local RTruecd = 4000
]]--

local HumanTrueQcd, SpiderTrueQcd = 6, 6
local HumanTrueWcd, SpiderTrueWcd = 12, 12
local HumanTrueEcd = {14, 13, 12, 11, 10}
local SpiderTrueEcd = {26, 24, 22, 20, 18} 
local RTruecd = 40
local RappelTimer = 0
local RappelStartTimer = 0
local RappelMaxTimer = 2000 
local SpiderQcd, SpiderWcd, SpiderEcd = 0, 0, 0
local HumanQcd, HumanWcd, HumanEcd = 0, 0, 0
local HumanQready, HumanWready, HumanEready = false, false, false
local SpiderQready, SpiderWready, SpiderEready = false, false, false
local HumanReady, HumanCombatReady, SpiderReady, SpiderCombatReady = false, false, false, false

local Rcd = 0
local Rrange = 800
local SpiderSpellERange = 750
local isSpider = false
local isRappel
local RappelEndTime = 0
local RappelTimeLeft = 0
local HumanReady, HumanCombatReady, SpiderReady, SpiderCombatReady = false, false, false, false


local menu = menu("delise", "Dieno Elise")
menu:menu("q", "Q Settings")
menu.q:header("qgeneral", "Combat Q settings")
menu.q:boolean("useHumanQ", "Use Human Q for combat", true)
menu.q:slider("humanQManaManager","Human Q mana manager", 12, 1, 100, 1)
menu.q:boolean("useSpiderQ", "Use Spider Q for combat", true)

menu.q:header("qfarm", "Farm Q settings mode")
menu.q:boolean("useHumanQFarm", "Use Human Q for farm", true)
menu.q:slider("humanFarmQManaManager","Human Q mana manager", 25, 1, 100, 1)
menu.q:boolean("useSpiderQFarm", "Use Spider Q for farm", true)

menu:menu("w", "W Settings")

menu.w:header("wgeneral", "Combat W settings")
menu.w:boolean("useHumanW", "Use Human W", true)
menu.w:slider("humanWManaManager","Human W Mana Manager", 12, 1, 100, 1)
menu.w:boolean("useSpiderW", "Use Spider W", true)

menu.w:header("wfarm", "Farm W settings mode")
menu.w:boolean("useHumanWFarm", "Enable Human W farm usage", true)
menu.w:slider("humanFarmWManaManager","Human W farm mana manager", 25, 1, 100, 1)
menu.w:boolean("useSpiderWFarm", "Spider W farm usage", true)

menu:menu("e", "E Settings")
menu.e:header("egeneral", "E usage in Combat mode")
menu.e:boolean("useHumanE", "Use Human E if hittable at all times", true)
menu.e:boolean("useHumanECC", "Autochain CC using Human E (on all times)", true)
menu.e:boolean("useSpiderE", "Use Spider E ", true)
menu.e:slider("SpiderEDistance","Minimum distance from target to use rappel", 480, 175, 750, 25)

menu:menu("r", "R auto usage settings")
menu.r:header("rgeneral", "R usage in Combat mode")
menu.r:boolean("rswap", "Auto swap R in combat", true)
menu.r:boolean("humanswapq", "Human Q must be on CD before swapping to Spider", true)
menu.r:boolean("humanswapw", "Human W must be on CD before swapping to Spider", true)
menu.r:boolean("humanswape", "Human E must be on CD before swapping to Spider", false)
menu.r:boolean("spiderswapq", "Spider Q must be on CD before swapping to Human", true)
menu.r:boolean("spiderswapw", "Spider W must be on CD before swapping to Human", true)
menu.r:boolean("rswapfarm", "Auto swap R in farm", true)


menu:menu("d", "Drawing")
menu:header("drawheader", "Drawing Settings")
menu.d:boolean("drawHumanQ", "Draw Human Q", true)
menu.d:boolean("drawHumanW", "Draw Human W", false)
menu.d:boolean("drawHumanE", "Draw Human E", true)
menu.d:boolean("drawSpiderQ", "Draw Spider Q", true)
menu.d:boolean("drawSpiderE", "Draw Spider E", true)
menu.d:boolean("drawOtherForm", "Draw other form CDs", true)
menu.d:boolean("drawDebug", "Draw debugging info (dev only)", false)

ts.load_to_menu();

local CalculateRealCD = function(total_cd)
  current_cd = player.percentCooldownMod
  real_cd = total_cd - total_cd * current_cd --see if this is correct code
  return real_cd
end



local TargetSelectionQ = function(res, obj, dist)
  if dist <= spellQ.range then
    res.obj = obj
    return true
  end
end

local GetTargetQ = function()
  return ts.get_result(TargetSelectionQ, ts.get_active_filter()).obj
end


local TargetSelectionW = function(res, obj, dist)
  if dist <= spellW.range then
    res.obj = obj
    return true
  end
end

local GetTargetW = function()
  return ts.get_result(TargetSelectionW, ts.get_active_filter()).obj
end


local TargetSelectionE = function(res, obj, dist)
  if dist <= spellE.range then
    res.obj = obj
    return true
  end
end

local GetTargetE = function()
  return ts.get_result(TargetSelectionE, ts.get_active_filter()).obj
end


local TargetSelectionSpiderE = function(res, obj, dist)
  if dist <= spellSpiderE.range then
    res.obj = obj
    return true
  end
end

local GetTargetSpiderE = function()
  return ts.get_result(TargetSelectionSpiderE, ts.get_active_filter()).obj
end



local TargetSelectionSpiderQ = function(res, obj, dist)
  if dist <= spellSpiderQ.range then
    res.obj = obj
    return true
  end
end

local GetTargetSpiderQ = function()
  return ts.get_result(TargetSelectionSpiderQ, ts.get_active_filter()).obj
end


local CheckForm = function()
  if player:spellSlot(0).name == 'EliseHumanQ' then 
    isSpider = false
  else
    isSpider = true
  end
end 

local HumanTargetSelection = function(res, obj, dist)
  if dist <= spellAA.range then
    res.obj = obj
    return true
  end
end

local SpiderTargetSelection = function(res, obj, dist)
  if dist <= 210 then
    res.obj = obj
    return true
  end
end

local GetHumanTarget = function()
  return ts.get_result(HumanTargetSelection, ts.get_active_filter()).obj
end

local GetSpiderTarget = function()
  return ts.get_result(SpiderTargetSelection, ts.get_active_filter()).obj
end

local q_module = {

}

-- Try to EQ when casting E
function q_module.CanCast()
  return player:spellSlot(0).state == 0
end


function q_module.TryCast(target)
  if not q_module.CanCast() then
    return
  end

  if target.pos:dist(player.pos) < spellQ.range then 
    player:castSpell("obj", 0, target)
  end
end

w_module = {

}

function w_module.CanCast()
  return player:spellSlot(1).state == 0
end

function w_module.TryCast(target)
  local segment = pred.linear.get_prediction(spellW, target, player)
  --print(segment)
  if segment then
    local coll = pred.collision.get_prediction(spellW, segment, target)
    if not coll then
      local endPos = segment.endPos
      if endPos:dist(segment.startPos) > spellW.range then
        return
      end
      player:castSpell("pos", 1, vec3(endPos.x, target.y, endPos.y))
    end
  end
end


e_module = {

}

function e_module.CanCast()
  return player:spellSlot(2).state == 0
end

function e_module.TryCast(target)
  local segment = pred.linear.get_prediction(spellE, target, player)
  if segment then
    local coll = pred.collision.get_prediction(spellE, segment, target)
    if not coll then
      local endPos = segment.endPos
      if endPos:dist(segment.startPos) > spellE.range then
        return
      end
      player:castSpell("pos", 2, vec3(endPos.x, target.y, endPos.y))
    end
  end
end


r_module = {

}

function r_module.CanCast()
  return player:spellSlot(3).state == 0
end


function r_module.TryCast() 
  player:castSpell("self", 3)
end

-- Standard auto attacking stuff

aa_module = {

}

-- On Key functions
local function OnKeyDown(key)
  if chat.isOpened then
    return
  end
  core.block_input()
  local char = string.char(key)
end

local function CombatHuman()
  local useHumanQCombat = menu.q.useHumanQ:get()
  local useHumanWCombat = menu.w.useHumanW:get()
  local useHumanECombat = menu.e.useHumanE:get()
  local HumanQTarget = GetTargetQ()
  local HumanWTarget = GetTargetW()
  local HumanETarget = GetTargetE()

  if common.IsValidTarget(HumanQTarget) and useHumanQCombat and q_module.CanCast() then
    q_module.TryCast(HumanQTarget)
  end

  if common.IsValidTarget(HumanWTarget) and useHumanWCombat and w_module.CanCast() then
    w_module.TryCast(HumanWTarget)
  end

  if common.IsValidTarget(HumanETarget) and useHumanECombat and e_module.CanCast() then
    e_module.TryCast(HumanETarget)
  end
end 

local function CombatSpider()
  local useSpiderQCombat = menu.q.useSpiderQ:get()
  local useSpiderWCombat = menu.w.useSpiderW:get()
  local useSpiderECombat = menu.e.useSpiderE:get()
  local SpiderEMinDistance = menu.e.SpiderEDistance:get()
  local SpiderQTarget = GetTargetSpiderQ()
  local SpiderETarget = GetTargetSpiderE()
  local SpiderTarget = GetSpiderTarget()

  if common.IsValidTarget(SpiderQTarget) and useSpiderQCombat and player:spellSlot(0).state == 0 then
    player:castSpell("obj", 0, SpiderQTarget)
  end

  if common.IsValidTarget(SpiderTarget) and useSpiderWCombat and player:spellSlot(1).state == 0 then
    player:castSpell("self", 1)
  end 

  if common.IsValidTarget(SpiderETarget) and useSpiderECombat and player:spellSlot(2).state == 0 then
    local pred_e_pos = pred.core.get_pos_after_time(SpiderETarget, 0.3)
    if pred_e_pos:dist(player.pos) < spellSpiderE.range then 
      player:castSpell("obj", 2, SpiderETarget)
    end 
  end   
end 


local function CombatFormSwap()
  if not menu.r.rswap:get() then 
    return 
  end 

  local SpiderTarget = GetSpiderTarget()
  local SpiderQTarget = GetTargetSpiderQ()
  local HumanTarget = GetHumanTarget()

  if common.IsValidTarget(SpiderQTarget) and SpiderQTarget.pos:dist(player.pos) < 450 and SpiderCombatReady and HumanCombatReady and isSpider and r_module.CanCast() then
    if menu.d.drawDebug:get() then 
      print("Swap1")
    end
    return 
  elseif SpiderCombatReady and HumanCombatReady and isSpider and r_module.CanCast() then 
    if menu.d.drawDebug:get() then 
      print("Swap2")
    end
    r_module.TryCast()
  elseif not HumanCombatReady and SpiderCombatReady and not isSpider and r_module.CanCast() then
    if menu.d.drawDebug:get() then 
      print("Swap3")
    end
    r_module.TryCast()
  elseif not SpiderCombatReady and HumanReady and isSpider and r_module.CanCast() then 
    if menu.d.drawDebug:get() then 
      print("Swap4")
    end
    r_module.TryCast()
  end 
end

local function AutoCC()
  local autoCC = menu.e.useHumanECC:get()
  if not isSpider and autoCC then 
    common.ForEachEnemyInRange(spellE.range, function(enemy) 
      travel_time = (enemy.pos:dist(player.pos))/(spellE.speed) + 0.25
      if common.IsImmobileBuffer(enemy, travel_time) and e_module.CanCast() then 
        e_module.TryCast(enemy)
      end 
    end)
  end
end

local function Clear()
  local useSpiderQFarm = menu.q.useSpiderQFarm:get()
  local useSpiderWFarm = menu.w.useSpiderWFarm:get()
  local useHumanQFarm = menu.q.useHumanQFarm:get()  
  local useHumanWFarm = menu.w.useHumanWFarm:get()  
  local useRFarm = menu.r.rswapfarm:get()
  local HumanQMana = menu.q.humanFarmQManaManager:get()
  local HumanWMana = menu.w.humanFarmWManaManager:get()

  local EnoughHumanQMana = (player.mana/player.maxMana)*100 > HumanQMana 
  local EnoughHumanWMana = (player.mana/player.maxMana)*100 > HumanWMana 

  for i = 0, ObjMinion_Type.size[TEAM_NEUTRAL] - 1 do
        local mob = ObjMinion_Type[TEAM_NEUTRAL][i]

        if isSpider and not SpiderReady and HumanReady and EnoughHumanQMana and EnoughHumanWMana then 
          player:castSpell("self",3)
        elseif not isSpider and SpiderReady and not HumanReady then 
          player:castSpell("self",3)
        elseif not isSpider and not EnoughHumanWMana and not EnoughHumanQMana then 
          player:castSpell("self",3)
        end 
 

        if isSpider and player:spellSlot(0).state == 0 then 
          if common.IsValidTarget(mob) and player.pos:dist(mob.pos) < spellSpiderQ.range then 
            player:castSpell("obj", 0, mob)
          end
        end

        if isSpider and player:spellSlot(1).state == 0 then 
          if common.IsValidTarget(mob) and player.pos:dist(mob.pos) < 225 then 
            player:castSpell("self", 1)
          end
        end

        if not isSpider and player:spellSlot(0).state == 0 and EnoughHumanQMana then 
          if common.IsValidTarget(mob) and player.pos:dist(mob.pos) < spellQ.range then 
            player:castSpell("obj", 0, mob)
          end
        end          


        if not isSpider and player:spellSlot(1).state == 0 and EnoughHumanWMana then 
          if common.IsValidTarget(mob) and player.pos:dist(mob.pos) < spellW.range then 
            player:castSpell("pos", 1, mob.pos)
          end
        end          
    end


  for i = 0, ObjMinion_Type.size[TEAM_ENEMY] - 1 do
        local mob = ObjMinion_Type[TEAM_ENEMY][i]

        if isSpider and not SpiderReady and HumanReady and EnoughHumanQMana and EnoughHumanWMana then 
          player:castSpell("self",3)
        elseif not isSpider and SpiderReady and not HumanReady then 
          player:castSpell("self",3)
        end 
 

        if isSpider and player:spellSlot(0).state == 0 then 
          if common.IsValidTarget(mob) and player.pos:dist(mob.pos) < spellSpiderQ.range then 
            player:castSpell("obj", 0, mob)
          end
        end

        if isSpider and player:spellSlot(1).state == 0 then 
          if common.IsValidTarget(mob) and player.pos:dist(mob.pos) < 175 then 
            player:castSpell("self", 1)
          end
        end

        if not isSpider and player:spellSlot(0).state == 0 and EnoughHumanQMana then 
          if common.IsValidTarget(mob) and player.pos:dist(mob.pos) < spellQ.range then 
            player:castSpell("obj", 0, mob)
          end
        end          


        if not isSpider and player:spellSlot(1).state == 0 and EnoughHumanWMana then 
          if common.IsValidTarget(mob) and player.pos:dist(mob.pos) < spellW.range then 
            player:castSpell("pos", 1, mob.pos)
          end
        end          
    end  
end 
-- Main tick functions


function CheckSpellState()
  Current_Tick = game.time

  -- --print(Current_Tick - SpiderQcd)
  -- --print(Current_Tick - HumanQcd)

  if Current_Tick - SpiderQcd > 0 then 
    SpiderQready = true
  else
    SpiderQready = false
  end

  if Current_Tick - SpiderWcd > 0 then 
    SpiderWready = true
  else
    SpiderWready = false
  end

  if Current_Tick - SpiderEcd > 0 then 
    SpiderEready = true
  else
    SpiderEready = false
  end

  if Current_Tick - HumanQcd > 0 then 
    HumanQready = true
  else
    HumanQready = false
  end

  if Current_Tick - HumanWcd > 0 then 
    HumanWready = true
  else
    HumanWready = false
  end

  if Current_Tick - HumanEcd > 0 then 
    HumanEready = true
  else
    HumanEready = false
  end

  if Current_Tick - Rcd > 0 then 
    RReady = true
  else
    RReady = false
  end
end

function CheckStatesReady()
  HumanEBoolean = nil

  if menu.r.humanswape:get() then
    if HumanEready and player.mana > 18 then
      HumanEBoolean = true
    else
      HumanEBoolean = false
    end
  else
    HumanEBoolean = true
  end
  --print(player.levelRef)

  if player.levelRef == 1 then
    if HumanQready or HumanWready then
      HumanReady = true
      HumanCombatReady = true
    else
      HumanReady = false
      HumanCombatReady = false
    end

    if SpiderQready or SpiderWready then
      SpiderCombatReady = true
    else
      SpiderCombatReady = false
    end

  elseif player.levelRef == 2 then
    if HumanQready and HumanWready then
      HumanReady = true
      HumanCombatReady = true
    else
      HumanReady = false
      HumanCombatReady = false
    end

    if SpiderQready and SpiderWready then
      SpiderCombatReady = true
    else
      SpiderCombatReady = false
    end

  else
    if HumanQready and HumanWready then
      HumanReady = true
    else 
      HumanReady = false
    end

    if (HumanQready and HumanWready) and HumanEBoolean then
      HumanCombatReady = true
    else
      HumanCombatReady = false
    end

    if SpiderQready and SpiderWready then
      SpiderReady = true
    else
      SpiderReady = false
    end

    if SpiderQready and SpiderWready then
      SpiderCombatReady = true
    else
      SpiderCombatReady = false
    end
  end

end


local function CheckEliseE()
  if common.CheckBuff(player, "elisespidere") then 
    isRappel = true
    --print("I'm up in the air!!!")
    buff =  common.ReturnBuff(player, "elisespidere")
    RappelTimeLeft = buff.endTime - game.time
    --print(RappelTimeLeft)
  else
    isRappel = false
  end
end

local function OnProcessSpell(spell)
  if spell.owner == player then
    print(spell.name)
  end

  if spell.owner == player and spell.name == "EliseSpiderQCast" then 
    SpiderQcd = game.time + CalculateRealCD(SpiderTrueQcd)
  end

  if spell.owner == player and spell.name == "EliseSpiderW" then 
    SpiderWcd = game.time + CalculateRealCD(SpiderTrueWcd)
  end 

  if spell.owner == player and spell.name == "EliseSpiderEInitial" then 
    SpiderEcd = game.time + CalculateRealCD(SpiderTrueEcd[player:spellSlot(3).level])
    isRappel = true
  end 

  if spell.owner == player and spell.name == 'EliseRSpider' then
    Rcd =game.time + CalculateRealCD(RTruecd)
  end

  if spell.owner == player and spell.name == "EliseHumanQ" then 
    HumanQcd =game.time + CalculateRealCD(HumanTrueQcd)
  end

  if spell.owner == player and spell.name == "EliseHumanW" then 
    HumanWcd =game.time + CalculateRealCD(HumanTrueWcd)
  end

  if spell.owner == player and spell.name == "EliseHumanE" then 
    HumanEcd = game.time + CalculateRealCD(HumanTrueEcd[player:spellSlot(3).level])
  end  
  if spell.owner == player and spell.name == 'EliseR' then
    Rcd = game.time + CalculateRealCD(RTruecd)
  end
end


local function OnTick()
  CheckForm()
  CheckEliseE()
  CheckSpellState()
  CheckStatesReady()
  --print(game.time)
  AutoCC()

  if (orb.combat.is_active()) then 
    if not isSpider then
      CombatHuman()
    elseif isSpider then 
      CombatSpider()
    end
    CombatFormSwap()
  end

  if (orb.menu.lane_clear:get()) then 
    Clear()
  end
  --swap logic
end


local function OnDraw()
  local drawSpiderQ = menu.d.drawSpiderQ:get()
  local drawSpiderE = menu.d.drawSpiderE:get()
  local drawHumanQ = menu.d.drawHumanQ:get()
  local drawHumanW = menu.d.drawHumanW:get()
  local drawHumanE = menu.d.drawHumanE:get()
  if player.isOnScreen and common.IsValidTarget(player) then
      if player:spellSlot(0).state == 0 and drawSpiderQ and isSpider then
          graphics.draw_circle(player.pos, spellSpiderQ.range, 2, graphics.argb(255, 0, 255, 0), 100)
      end
      if player:spellSlot(2).state == 0 and drawSpiderE and isSpider then
          graphics.draw_circle(player.pos, spellSpiderE.range, 2, graphics.argb(255, 0, 255, 0), 100)
      end
      if player:spellSlot(0).state == 0 and drawHumanQ and not isSpider then
          graphics.draw_circle(player.pos, spellQ.range, 2, graphics.argb(255, 0, 255, 0), 100)
      end
      if player:spellSlot(1).state == 0 and drawHumanW and not isSpider then
          graphics.draw_circle(player.pos, spellW.range, 2, graphics.argb(255, 0, 255, 0), 100)
      end
      if player:spellSlot(2).state == 0 and drawHumanE and not isSpider then 
          graphics.draw_circle(player.pos,  spellE.range, 2, graphics.argb(255, 0, 255, 0), 100)
      end

      local coloractive = graphics.argb(255, 25, 185,50)
      local colorCD = graphics.argb(255, 185, 25, 50)
      local drawCDs = menu.d.drawOtherForm:get()
      local player_world_pos = graphics.world_to_screen(player.pos)
      if drawCDs then 
        if isSpider and HumanQready then 
          graphics.draw_text_2D('Human Q: Ready', 18, player_world_pos.x, player_world_pos.y, coloractive)
        elseif isSpider and not HumanQready then 
          local humanQcdleft = HumanQcd - game.time 
          graphics.draw_text_2D('Human Q: ' .. tostring( common.round(humanQcdleft,2)), 18, player_world_pos.x, player_world_pos.y, colorCD)
        end
        if isSpider and HumanWready then 
          graphics.draw_text_2D('Human W: Ready', 18, player_world_pos.x, player_world_pos.y-30, coloractive)
        elseif isSpider and not HumanWready then 
          local humanWcdleft = HumanWcd - game.time 
          graphics.draw_text_2D('Human W: ' .. tostring( common.round(humanWcdleft,2)), 18, player_world_pos.x, player_world_pos.y-30, colorCD)
        end
        if isSpider and HumanEready then 
          graphics.draw_text_2D('Human E: Ready', 18, player_world_pos.x, player_world_pos.y-55, coloractive)
        elseif isSpider and not HumanEready then 
          local humanEcdleft = HumanEcd - game.time 
          graphics.draw_text_2D('Human E: ' .. tostring( common.round(humanEcdleft,2)), 18, player_world_pos.x, player_world_pos.y-55, colorCD)
        end

        if not isSpider and SpiderQready then 
          graphics.draw_text_2D('Spider Q: Ready', 18, player_world_pos.x, player_world_pos.y, coloractive)
        elseif not isSpider and not SpiderQready then 
          local spiderQcdleft = SpiderQcd - game.time 
          graphics.draw_text_2D('Spider Q: ' .. tostring( common.round(spiderQcdleft,2)), 18, player_world_pos.x, player_world_pos.y, colorCD)
        end

        if not isSpider and  SpiderWready then 
          graphics.draw_text_2D('Spider W: Ready', 18, player_world_pos.x, player_world_pos.y-30, coloractive)
        elseif not isSpider and not SpiderWready then 
          local spiderWcdleft = SpiderWcd - game.time 
          graphics.draw_text_2D('Spider W: ' .. tostring( common.round(spiderWcdleft,2)), 18, player_world_pos.x, player_world_pos.y-30, colorCD)
        end


        if not isSpider and SpiderEready then 
          graphics.draw_text_2D('Spider E: Ready', 18, player_world_pos.x, player_world_pos.y-55, coloractive)
        elseif not isSpider and not SpiderEready then 
          local spiderEcdleft = SpiderEcd - game.time 
          graphics.draw_text_2D('Spider E: ' .. tostring( common.round(spiderEcdleft,2)), 18, player_world_pos.x, player_world_pos.y-55, colorCD)
        end

        if menu.d.drawDebug:get() then
          graphics.draw_text_2D('Human Combat Ready: ' .. tostring(HumanCombatReady), 18, player_world_pos.x+55, player_world_pos.y+55, colorCD)
          graphics.draw_text_2D('Spider Combat Ready: ' .. tostring(SpiderCombatReady), 18, player_world_pos.x+55, player_world_pos.y+75, colorCD)
        end
      end
  end

end


cb.add(cb.draw, OnDraw)
cb.add(cb.spell, OnProcessSpell)
orb.combat.register_f_pre_tick(OnTick)
chat.print("DienoElise beta version " .. tostring(version) .. " loaded! Please provide feedback to dienofail#1100 on discord")
