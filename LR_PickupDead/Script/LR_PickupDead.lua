local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_PickupDead"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_PickupDead"
local _L=LR.LoadLangPack(AddonPath)
---------------------------------------------------------------
local VERSION = "20170912"
---------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
----自动拾取Doodad
-------------------------------------------------------------------------------------------------------------
-----SYNC_LOOT_LIST在DOODAD_ENTER_SCENE之后
-----SYNC_LOOT_LIST:在有可拾取的DOODAD出现后会触发，任务物品不会触发，另外当拾取物品后，会产生SYNC_LOOT_LIST
-----所以优先使用SYNC_LOOT_LIST
-----步骤：
-----SYNC_LOOT_LIST将doodad加入doodadList
-----breathe打开附近的DOODAD，触发OPEN_DOODAD(别人打开，包括队友打开都不触发，只有自己打开会触发)
-----触发OPEN_DOODAD后，进行拾取
-----有些物品被所有人放弃后再打开DOODAD，就会直接放进包里，所以最好Roll点在打开之后


local PICKUP_MIN_TIME = 3
local PICKUP_MAX_DISTANCE = 6
local ROLL_ITEM_CHOICE = {
	NEED = 2,
	GREED = 1,
	CANCEL = 0,
}

LR_PickupDead = {}
LR_PickupDead.doodadList = {}
LR_PickupDead.pickedUpList = {}
LR_PickupDead.rolledItemList = {}
LR_PickupDead.rollItemList = {}
LR_PickupDead.lastPickupTime = 0
LR_PickupDead.customData = {
	ignorList = {},
	pickList = {},
}
LR_PickupDead.UsrData = {
	pickUpLevel = 1,	--拾取白色及以上
	bOn = false,
	bPickupTaskItem = true,
	bPickupUnReadBook = true,
	bPickupOnlyOneBindBook = true,
	bPickupOnlyOneNotBindBook = true,
	bPickupItems = false,		---开启白名单
	bnotPickupItems = false,		--开启黑名单
	bOnlyPickupItems = false,		---只拾取白名单
	bGiveUpItemsBTLON = true,  --Give up items beyond the limit of number 放弃超过上限的物品
}
RegisterCustomData("LR_PickupDead.UsrData", VERSION)

function LR_PickupDead.SaveCustomData()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local path = sformat("%s\\UsrData\\CustomData.dat", SaveDataPath)
	local data = clone(LR_PickupDead.customData)
	SaveLUAData (path,data)
end

function LR_PickupDead.LoadCustomData()
	local path = sformat("%s\\UsrData\\CustomData.dat", SaveDataPath)
	local data = LoadLUAData(path) or {ignorList = {},pickList = {},}
	LR_PickupDead.customData = clone(data)
end

------------------------------------------------------------------
function LR_PickupDead.CloseLootListPanel()
	local hL = Station.Lookup("Normal/LootList", "Handle_LootList")
	if hL then
		hL:Clear()
	end
end

function LR_PickupDead.GetEquipItemEquiped(nEqSubType, nDetailType)
	local nPos = 0
	if nEqSubType == EQUIPMENT_SUB.MELEE_WEAPON then
		nPos = EQUIPMENT_INVENTORY.MELEE_WEAPON
		if nDetailType == WEAPON_DETAIL.BIG_SWORD then
			nPos = EQUIPMENT_INVENTORY.BIG_SWORD
		end
	elseif nEqSubType == EQUIPMENT_SUB.RANGE_WEAPON then
		nPos = EQUIPMENT_INVENTORY.RANGE_WEAPON
	elseif nEqSubType == EQUIPMENT_SUB.ARROW then
		nPos = EQUIPMENT_INVENTORY.ARROW
	elseif nEqSubType == EQUIPMENT_SUB.CHEST then
		nPos = EQUIPMENT_INVENTORY.CHEST
	elseif nEqSubType == EQUIPMENT_SUB.HELM then
		nPos = EQUIPMENT_INVENTORY.HELM
	elseif nEqSubType == EQUIPMENT_SUB.AMULET then
		nPos = EQUIPMENT_INVENTORY.AMULET
	elseif nEqSubType == EQUIPMENT_SUB.RING then
		nPos = EQUIPMENT_INVENTORY.RIGHT_RING
		return INVENTORY_INDEX.EQUIP, nPos, EQUIPMENT_INVENTORY.LEFT_RING
	elseif nEqSubType == EQUIPMENT_SUB.WAIST then
		nPos = EQUIPMENT_INVENTORY.WAIST
	elseif nEqSubType == EQUIPMENT_SUB.PENDANT then
		nPos = EQUIPMENT_INVENTORY.PENDANT
	elseif nEqSubType == EQUIPMENT_SUB.PANTS then
		nPos = EQUIPMENT_INVENTORY.PANTS
	elseif nEqSubType == EQUIPMENT_SUB.BOOTS then
		nPos = EQUIPMENT_INVENTORY.BOOTS
	elseif nEqSubType == EQUIPMENT_SUB.BANGLE then
		nPos = EQUIPMENT_INVENTORY.BANGLE
	elseif nEqSubType == EQUIPMENT_SUB.WAIST_EXTEND then
		nPos = EQUIPMENT_INVENTORY.WAIST_EXTEND
	elseif nEqSubType == EQUIPMENT_SUB.BACK_EXTEND then
		nPos = EQUIPMENT_INVENTORY.BACK_EXTEND
	elseif nEqSubType == EQUIPMENT_SUB.HORSE then
		nPos = EQUIPMENT_INVENTORY.HORSE
	end

	return INVENTORY_INDEX.EQUIP, nPos
end

function LR_PickupDead.CheckHorse(item)
	if LR.GetItemNumInLimitedBag(item.dwTabType, item.dwIndex, item.nBookID) > 0 then
		return false
	end
	if LR.GetItemNumInHorseBag(item.dwTabType, item.dwIndex, item.nBookID) > 0 then
		return false
	end
	return true
end

local function GetItemScore(item)
	if not item then
		return 0
	end
	return item.nBaseScore
end

function LR_PickupDead.CheckEquip(item)
	local flag = true
	local me = GetClientPlayer()
	if not me then
		return false
	end
	if LR.GetItemNumInLimitedBag(item.dwTabType, item.dwIndex, item.nBookID) > 0 then
		if item.nQuality < 4 then
			return false	--包里有，低于紫品的直接不捡
		end
	end
	local dwBox, nPos, nPos2 = LR_PickupDead.GetEquipItemEquiped(item.nSub, item.nDetail)

	if item.nSub == EQUIPMENT_SUB.RING then
		local item2, item3 = me.GetItem(dwBox, nPos), me.GetItem(dwBox, nPos2)
		if item2 and item3 then
			if not (item2 and (GetItemScore(item2) < GetItemScore(item)) or item3 and (GetItemScore(item3) < GetItemScore(item))) then
				if item.nQuality < 4 then
					return false	--装备的物品品质高，且物品不是紫的直接不捡
				end
			end
		end
	else
		local item2 = me.GetItem(dwBox, nPos)
		if item2 then
			if GetItemScore(item2) >= GetItemScore(item) then
				if item.nQuality < 4 then
					return false	--装备的物品品质高，且物品不是紫的直接不捡
				end
			end
		end
	end

	return true
end

--------------------------------------------------------------
---事件操作
--------------------------------------------------------------
local CRAFT_SUCCESS = false

function LR_PickupDead.SYNC_LOOT_LIST()
	local dwDoodadID = arg0
	local doodad = GetDoodad(dwDoodadID)
	if doodad then
		LR_PickupDead.doodadList[dwDoodadID] = {dwID = dwDoodadID, nX = doodad.nX, nY = doodad.nY, nZ = doodad.nZ,}
	end
end

function LR_PickupDead.DOODAD_LEAVE_SCENE()
	local dwID = arg0
	LR_PickupDead.doodadList[dwID] = nil
	LR_PickupDead.pickedUpList[dwID] = nil
end

function LR_PickupDead.OPEN_DOODAD()
	local dwDoodadID = arg0
	local dwPlayerID = arg1
	local me = GetClientPlayer()
	if not me then
		return
	end
	if dwPlayerID ~=  me.dwID then
		return
	end

	LR_PickupDead.PickItem(dwDoodadID)
end

function LR_PickupDead.PickItem(dwDoodadID)
	local dwDoodadID = dwDoodadID
	local me = GetClientPlayer()
	if not me then
		return
	end
	if not LR_PickupDead.UsrData.bOn then
		return
	end

	if LR_PickupDead.pickedUpList[dwDoodadID] and not CRAFT_SUCCESS then
		LR_PickupDead.doodadList[dwDoodadID] = nil
		return
	end
	CRAFT_SUCCESS = false

	local doodad =  GetDoodad (dwDoodadID)
	if not doodad then
		return
	end

	----清空LIst
	LR_PickupDead.doodadList[dwDoodadID] = nil
	LR_PickupDead.pickedUpList[dwDoodadID] = true

	--拾取金钱
	local nMoney = doodad.GetLootMoney()
	if nMoney > 0 then
		LootMoney (doodad.dwID)
	end

	local num = doodad.GetItemListCount()
	for i = num - 1, 0, -1 do
		local item, bNeedRoll, bLeader ,bGoldTeam = doodad.GetLootItem(i, me)
		if item then
			if bNeedRoll then
				--Output("bNeedRoll")
			elseif bLeader then
				--Output("bLeader")
			else
				local pickFlag = false
				--[[过滤规则(按顺序)：
				1、白名单中的放行
				2、如果只拾取白名单，则不管品级的过滤；否则根据品级过滤
				3、任务物品和过滤后的书籍不受只拾取白名单控制
				4、如果拾取后的物品数量超过允许的上限则不捡
				5、所有物品受黑名单的控制
				]]
				--白名单
				if LR_PickupDead.UsrData.bPickupItems then
					for k, v in pairs(LR_PickupDead.customData.pickList or {}) do
						if v.bPickup then
							if v.szName then
								if v.szName == LR.GetItemNameByItem(item) then
									pickFlag = true
								end
							elseif v.dwTabType then
								if v.dwTabType == item.dwTabType and v.dwIndex == item.dwIndex then
									pickFlag = true
								end
							elseif v.nUiId then
								if v.nUiId == item.nUiId then
									pickFlag = true
								end
							end
						end
					end
				end

				--不在白名单中的
				if not (LR_PickupDead.UsrData.bPickupItems and LR_PickupDead.UsrData.bOnlyPickupItems) then
					if item.nQuality >=  LR_PickupDead.UsrData.pickUpLevel then
						pickFlag = true
					end

					---如果在吃鸡地图
					if Table_IsTreasureBattleFieldMap(me.GetMapID()) then
						if item.nGenre == ITEM_GENRE.EQUIPMENT then
							if item.nSub == EQUIPMENT_SUB.HORSE then
								if not LR_PickupDead.CheckHorse(item) then
									pickFlag = false
								end
							else
								if not LR_PickupDead.CheckEquip(item) then
									pickFlag = false
								end
							end
						end
					end
				end

				if item.nGenre == ITEM_GENRE.BOOK then
					if LR_PickupDead.UsrData.bPickupUnReadBook then	--只拾取未阅读过的书籍
						local nBookID, nSegID = GlobelRecipeID2BookID(item.nBookID)
						if not me.IsBookMemorized(nBookID, nSegID) then
							pickFlag = true
						else
							pickFlag = false
						end
					end
					---只拾取一本
					if LR_PickupDead.UsrData.bPickupOnlyOneBindBook and item.bBind == true then
						if LR.GetItemNumInBag(item.dwTabType, item.dwIndex, item.nBookID) > 0 then
							pickFlag = false
						end
					end
					if LR_PickupDead.UsrData.bPickupOnlyOneNotBindBook and item.bBind == false then
						if LR.GetItemNumInBag(item.dwTabType, item.dwIndex, item.nBookID) > 0 then
							pickFlag = false
						end
					end
				end

				if item.nGenre ==  ITEM_GENRE.TASK_ITEM then		---如果是任务物品，则直接拾取
					if LR_PickupDead.UsrData.bPickupTaskItem then
						pickFlag = true
					end
				end

				if LR_PickupDead.UsrData.bGiveUpItemsBTLON then
					local nMaxExistAmount = item.nMaxExistAmount
					local nStackNum = 1
					if item.bCanStack then
						nStackNum = item.nStackNum
					end
					local numInBagAndBank = LR.GetItemNumInBagAndBank(item.dwTabType, item.dwIndex, item.nBookID)
					if nMaxExistAmount > 0 and nMaxExistAmount < numInBagAndBank + nStackNum then
						pickFlag = false
					end
				end

				--黑名单
				if LR_PickupDead.UsrData.bnotPickupItems then
					for k, v in pairs(LR_PickupDead.customData.ignorList or {}) do
						if v.bnotPickup then
							if v.szName then
								if v.szName == LR.GetItemNameByItem(item) then
									pickFlag = false
								end
							elseif v.dwTabType then
								if v.dwTabType == item.dwTabType and v.dwIndex == item.dwIndex then
									pickFlag = false
								end
							elseif v.nUiId then
								if v.nUiId == item.nUiId then
									pickFlag = false
								end
							end
						end
					end
				end

				if pickFlag then
					LootItem(dwDoodadID, item.dwID)
				end
			end
		end
	end

	if not Table_IsTreasureBattleFieldMap(me.GetMapID()) then
		LR.DelayCall(250, function() LR_PickupDead.CloseLootListPanel() end)
	end
end

function LR_PickupDead.BreatheCall()
	local me = GetClientPlayer()
	if not me then
		return
	end
	if not LR_PickupDead.UsrData.bOn then
		return
	end
	if LR.IsMapBlockAddon() then
		return
	end

	for dwID, v in pairs(LR_PickupDead.doodadList) do
		if not LR_PickupDead.pickedUpList[dwID] then
			local distance = LR.GetDistance(v)
			if distance <=  PICKUP_MAX_DISTANCE then
				local doodad = GetDoodad(dwID)
				if doodad then
					if doodad.CanLoot(me.dwID) then
						--Output(me.nMoveState == MOVE_STATE.ON_STAND)
						if GetLogicFrameCount() - LR_PickupDead.lastPickupTime >=  PICKUP_MIN_TIME  and me.nMoveState == MOVE_STATE.ON_STAND then
							LR_PickupDead.lastPickupTime = GetLogicFrameCount()
							OpenDoodad(me, doodad)
							--InteractDoodad(doodad.dwID)
							return
						end
					else
						LR_PickupDead.doodadList[dwID] = nil
					end
				end
			else
				--Output(distance)
			end
		end
	end
end

function LR_PickupDead.LOGIN_GAME()
	LR_PickupDead.LoadCustomData()
end

function LR_PickupDead.SYS_MSG()
	if arg0 == "UI_OME_CRAFT_RESPOND" then
		if arg1 == CRAFT_RESULT_CODE.SUCCESS then
			CRAFT_SUCCESS = true
		end
	end
end


LR.BreatheCall("LR_PickupDead", function() LR_PickupDead.BreatheCall() end, 250)
LR.RegisterEvent("SYNC_LOOT_LIST",function() LR_PickupDead.SYNC_LOOT_LIST() end)
LR.RegisterEvent("DOODAD_LEAVE_SCENE",function() LR_PickupDead.DOODAD_LEAVE_SCENE() end)
LR.RegisterEvent("OPEN_DOODAD",function() LR_PickupDead.OPEN_DOODAD() end)
LR.RegisterEvent("LOGIN_GAME",function() LR_PickupDead.LOGIN_GAME() end)
LR.RegisterEvent("SYS_MSG",function() LR_PickupDead.SYS_MSG() end)
