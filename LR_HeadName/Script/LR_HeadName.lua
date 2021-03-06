local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
local AddonPath = "Interface\\LR_Plugin\\LR_HeadName"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_HeadName"
local _L = LR.LoadLangPack(AddonPath)
local szIniFile = sformat("%s\\UI\\LR_HeadNameItem.ini", AddonPath)
local DEBUG = false
local CustomVersion = "20190727c"    --�޸Ĵ˴�������Ĭ������
---------------------------------------------------------
local HEAD_CLIENTPLAYER = 0
local HEAD_OTHERPLAYER = 1
local HEAD_NPC = 2

local HEAD_LEFE = 0
local HEAD_GUILD = 1
local HEAD_TITLE = 2
local HEAD_NAME = 3

local freq_limit = 120    --

local ROLETYPE_TEXT = {
    [1] = _L["ChengNan"],
    [2] = _L["ChengNv"],
    [5] = _L["ZhengTai"],
    [6] = _L["Loli"],
}

local function _D(dwDoodadTemplateID)
    return LR.TABLE_GetDoodadTemplateName(dwDoodadTemplateID)
end

HEAD_NAME_MINERAL = {
    _D(1020), --ͭ��
    _D(1021), --����
    _D(1022), --Ǧп��
    _D(1024), --����
    _D(1025), --����
}

HEAD_NAME_AGRICULTURE = {
    _D(1001), --�ʲ�
    _D(1002), --���
    _D(1003), --��ҩ
    _D(1009), --��ζ��
    _D(1012), --���
    _D(1015), --ǧ����
    _D(2641), --����
    _D(2642), --���
    _D(4228), --�˰���
    _D(7526), --ɺ��

    ---
    _D(3358), --������
    _D(3359), --�����
    _D(3360), --�����
    _D(3361), --�ϻ���ޣ
}

-----------------------------------------------
LR_HeadName = {
    AllList         = {},
    _Role           = {},
    handle          = nil,
    tTongList       = {},
    RandomRGB       = { 70, 145, 220, 1, 1, 1 },
    MissionList     = {},
    dwMapID         = nil,
    old_dwTargetID  = 0,
    old_nTargetType = nil,
    tSysSettings    = {},
    MissionNeed     = {},
    bOn             = false,
}

local FIRST_LOADING_END = false
LR_HeadName.szMissionName = ""
LR_HeadName.DoodadCache = {}
LR_HeadName.DoodadList = {}
LR_HeadName.CustomDoodad = {}
LR_HeadName.BookCopyQuests = {}
local MINIMAP_LIST = {}    --���ڴ��С��ͼ��ʾ�Ķ���
local NPC_QUEST_LIST = {}    --���npc������keyΪģ��id
local NPC_CAN_ACCEPT_QUEST = {}
local NPC_CAN_FINISH_QUEST = {}
local SCENE_QUEST_CACHE = {}
local SCENE_DATA_CACHE = {}

LR_HeadName.UIScale = 1

LR_HeadName.default = {
    DoodadKind   = {
        [DOODAD_KIND.INVALID]      = false,
        [DOODAD_KIND.NORMAL]       = false,
        [DOODAD_KIND.CORPSE]       = false,
        [DOODAD_KIND.QUEST]        = false,
        [DOODAD_KIND.READ]         = false,
        [DOODAD_KIND.DIALOG]       = false,
        [DOODAD_KIND.ACCEPT_QUEST] = true,
        [DOODAD_KIND.TREASURE]     = false,
        [DOODAD_KIND.ORNAMENT]     = false,
        [DOODAD_KIND.CRAFT_TARGET] = true,
        [DOODAD_KIND.CLIENT_ONLY]  = false,
        [DOODAD_KIND.CHAIR]        = false,
        [DOODAD_KIND.GUIDE]        = false,
        [DOODAD_KIND.DOOR]         = false,
        [DOODAD_KIND.NPCDROP]      = false,
    },
    UsrData      = {
        font                  = 192,
        nFontScale            = 0.9,
        Height                = 16, --�м��
        SeeMax                = 250,
        distanceMax           = 65,
        CustomText            = "��",
        bShowQuestFlag        = false, --�Ƿ���ʾ������
        bShowQMode            = 1, --��������ʾ��ʽ 1��������ߣ���̬�� 2���������棨��̬��
        bDisLimit             = true, --�Ƿ��о�������
        bSeeLimit             = false, --�Ƿ����Ƹ���
        bShowDoodadKind       = false, --�Ƿ���ʾDoodad������
        bShowTeamMark         = true, --�Ƿ���ʾ������
        nShowTeamMarkType     = 2, ----1:��ʾ���֣�2����ʾͼ��
        bHightLightTeamMark   = true, --�Ƿ����������
        nMarkOffset           = 14, --ͼ��ƫ��
        nOffset               = 0, --ͷ����Ը߶�
        nLifeBarOffset        = 0, --Ѫ���߶�ƫ����
        bShowBalloon          = false, --�Ƿ���ʾ����
        nBallonType           = 5, ---������ʽ
        nBallonTopOffset      = 45, --����ƫ��
        bEnhanceGuDing        = true, --��ǿ�ƶ���ʾ
        bMiniMapAgriculture   = true, --��ũС��ͼ��ʾ
        bMiniMapMine          = true, --���С��ͼ��ʾ
        bShowAgriculture      = false, --��ʾ��ũ
        bShowMine             = false,
        bShowQuestDoodad      = false, --��ʾ����ʰȡ��Ʒ
        bShowTargetDis        = true,
        bShowTargetFace       = false, --��ʾĿ������
        bShowFightingEnemyDis = false,
        bChangeSizeByUIScale  = false, --��UI����һ��任��С
        NPC                   = {
            bShow                = true,
            bAlwaysHideSysNpcTop = true,
            ["Ally"]             = {
                bShow       = true,
                Name        = true,
                Title       = true,
                Level       = false,
                LifeBar     = false,
                HideLifeBar = true,
            },
            ["Enemy"]            = {
                bShow        = true,
                Name         = true,
                Title        = true,
                Level        = true,
                LifeBar      = true,
                HideLifeBar  = true,
                bShowLifePer = true,
            },
            ["Neutrality"]       = {
                bShow       = true,
                Name        = true,
                Title       = true,
                Level       = false,
                LifeBar     = false,
                HideLifeBar = true,
            },
        },
        Player                = {
            bShow                   = true,
            bAlwaysHideSysPlayerTop = true,
            ["Ally"]                = {
                bShow       = true,
                Name        = true,
                Title       = true,
                Tong        = true,
                Level       = false,
                LifeBar     = false,
                HideLifeBar = true,
                ForceID     = false,
                RoleType    = false,
                nColorMode  = 1, --��ɫģʽ 1��Ĭ����ɫ��2�������ɷ�ʽ��ɫ
            },
            ["Enemy"]               = {
                bShow        = true,
                Name         = true,
                Title        = true,
                Tong         = true,
                Level        = true,
                LifeBar      = true,
                HideLifeBar  = true,
                ForceID      = false,
                RoleType     = false,
                bShowLifePer = true,
                nColorMode   = 1, --��ɫģʽ 1��Ĭ����ɫ��2�������ɷ�ʽ��ɫ
            },
            ["Neutrality"]          = {
                bShow       = true,
                Name        = true,
                Title       = true,
                Tong        = true,
                Level       = false,
                LifeBar     = false,
                HideLifeBar = true,
                ForceID     = false,
                RoleType    = false,
                nColorMode  = 1, --��ɫģʽ 1��Ĭ����ɫ��2�������ɷ�ʽ��ɫ
            },
            ["Party"]               = {
                bShow       = true,
                Name        = true,
                Title       = true,
                Tong        = true,
                Level       = false,
                LifeBar     = true,
                HideLifeBar = true,
                ForceID     = false,
                RoleType    = false,
                nColorMode  = 1, --��ɫģʽ 1��Ĭ����ɫ��2�������ɷ�ʽ��ɫ
            },
            ["Self"]                = {
                bShow       = true,
                Name        = true,
                Title       = true,
                Tong        = true,
                Level       = false,
                LifeBar     = true,
                HideLifeBar = true,
                ForceID     = false,
                RoleType    = false,
                nColorMode  = 1, --��ɫģʽ 1��Ĭ����ɫ��2�������ɷ�ʽ��ɫ
            },
        },
        HideInDungeon         = {
            bOn      = true,
            Name     = false,
            Title    = true,
            Tong     = true,
            Level    = true,
            LifeBar  = true,
            ForceID  = true,
            RoleType = true,
        },
        LifeBar               = {
            ShowBorder              = true,
            Height                  = 7,
            Lenth                   = 64,
            Alpha                   = 255,
            ColorMode               = 2,
            nOffsetY                = 0,
            BorderColor             = { 0, 0, 0 },
            bShowLifePercentText    = true,
            nLifePercentTextOffsetX = 14,
            nLifePercentTextOffsetY = 0,
            nLifePercentTextScale   = 0.6,
            bNotCalLifeLenth        = false,
        },
        ChangGeShadow         = {
            bShow          = true, -----�ܿ���
            ["Ally"]       = {
                bShow       = false, ----����
                bShowShadow = true, ----��ʾӰ��
                bShowBody   = true, ----��ʾ����
            },
            ["Enemy"]      = {
                bShow       = false, ----����
                bShowShadow = false, ----��ʾӰ��
                bShowBody   = false, ----��ʾ����
            },
            ["Neutrality"] = {
                bShow       = false, ----����
                bShowShadow = true, ----��ʾӰ��
                bShowBody   = true, ----��ʾ����
            },
            ["Party"]      = {
                bShow       = false, ----����
                bShowShadow = true, ----��ʾӰ��
                bShowBody   = true, ----��ʾ����
            },
            ["Self"]       = {
                bShow       = true, ----����
                bShowShadow = true, ----��ʾӰ��
                bShowBody   = true, ----��ʾ����
            },
        },
    },
    Version      = CustomVersion,
    CustomDoodad = {
        [_D(3996)] = true,
        [_D(3874)] = true,
        [_D(4255)] = true,
    },
}

--���ÿ�Ĭ������
LR_HeadName.default.Mineral = {}
for k, v in pairs(HEAD_NAME_MINERAL) do
    LR_HeadName.default.Mineral[v] = true
end
--[[LR_HeadName.default.Mineral[_D(1020)] = true	--ͭ��
LR_HeadName.default.Mineral[_D(5661)] = true	--����ʯ��
LR_HeadName.default.Mineral[_D(5662)] = true	--����ʯ��]]

--������ũĬ������
LR_HeadName.default.Agriculture = {}
for k, v in pairs(HEAD_NAME_AGRICULTURE) do
    LR_HeadName.default.Agriculture[v] = true
end
--[[LR_HeadName.default.Agriculture[_D(1001)] = true	--�ʲ�
LR_HeadName.default.Agriculture[_D(1002)] = true	--���
LR_HeadName.default.Agriculture[_D(5659)] = true	--����
LR_HeadName.default.Agriculture[_D(5660)] = true	--����]]

LR_HeadName.UsrData = clone(LR_HeadName.default.UsrData)
LR_HeadName.DoodadKind = clone(LR_HeadName.default.DoodadKind)
LR_HeadName.Agriculture = clone(LR_HeadName.default.Agriculture)
LR_HeadName.Mineral = clone(LR_HeadName.default.Mineral)

RegisterCustomData("LR_HeadName.bOn", CustomVersion)

LR_HeadName.DoodadKindDescribe = {
    [DOODAD_KIND.INVALID]      = "INVALID",
    [DOODAD_KIND.NORMAL]       = _L["DOODAD_KIND_NORMAL"],
    [DOODAD_KIND.CORPSE]       = _L["DOODAD_KIND_CORPSE"],
    [DOODAD_KIND.QUEST]        = _L["DOODAD_KIND_QUEST"],
    [DOODAD_KIND.READ]         = _L["DOODAD_KIND_READ"],
    [DOODAD_KIND.DIALOG]       = "DIALOG",
    [DOODAD_KIND.ACCEPT_QUEST] = _L["DOODAD_KIND_ACCEPT_QUEST"],
    [DOODAD_KIND.TREASURE]     = _L["DOODAD_KIND_TREASURE"],
    [DOODAD_KIND.ORNAMENT]     = _L["DOODAD_KIND_ORNAMENT"],
    [DOODAD_KIND.CRAFT_TARGET] = _L["DOODAD_KIND_CRAFT_TARGET"],
    [DOODAD_KIND.CLIENT_ONLY]  = "CLIENT_ONLY",
    [DOODAD_KIND.CHAIR]        = "CHAIR",
    [DOODAD_KIND.GUIDE]        = "GUIDE",
    [DOODAD_KIND.DOOR]         = "DOOR",
    [DOODAD_KIND.NPCDROP]      = "NPCDROP",
    [15]                       = "UNKNOWN",
}

LR_HeadName.DefaultHighLightColor = {
    ["Doodad"]     = { 255, 200, 255 },
    ["Ally"]       = { 176, 240, 180 },
    ["Enemy"]      = { 249, 137, 104 },
    ["Neutrality"] = { 244, 244, 134 },
    ["Party"]      = { 129, 201, 239 },
    ["Self"]       = { 129, 201, 239 },
}
LR_HeadName.HighLightColor = clone(LR_HeadName.DefaultHighLightColor)

LR_HeadName.DefaultColor = {
    ["Doodad"]     = { 255, 155, 255 },
    ["Ally"]       = { 33, 184, 40 },
    ["Enemy"]      = { 195, 51, 9 },
    ["Neutrality"] = { 185, 185, 17 },
    ["Party"]      = { 26, 156, 227 },
    ["Self"]       = { 26, 156, 227 },
}
LR_HeadName.Color = clone(LR_HeadName.DefaultColor)

LR_HeadName.MissionPatch = {}
LR_HeadName.MissionPatch2 = {}

------Doodad�ض���ʾ�Ĳ���
LR_HeadName.DoodadBeShow = {
    [_D(183)] = true,
    [_D(342)] = true,
    [_D(343)] = true,
    [_D(344)] = true,
}

----------NPC��Template��������ʾ�Ĳ���
LR_HeadName.NpcTemplateSee = {}

----------Doodad��Template��������ʾ�Ĳ���
LR_HeadName.DoodadTemplateSee = {
    ----[dwTemplateID] = true
}

------Doodad��Զ������ʾ�Ĳ���
LR_HeadName.DoodadDonotAddPatch = {
    -------[dwTemplateID] = true
    [5376] = true, ------��̨ɽ ի��
}

-----------�Ŷӱ��
local _tPartyMark = {}
local tMarkerImageList = { 66, 67, 73, 74, 75, 76, 77, 78, 81, 82 } --ͼƬid
local tMarkerTextList = { _L["White Cloud"], _L["Dagger"], _L["Axe"], _L["Hook"], _L["Red Drum"], _L["Scissors"], _L["Cudgel"], _L["Ruyi"], _L["Darts"], _L["Fan"], }

local _GuDing = {}
_GuDing.nExistMaxTime = 60000
_GuDing.dwTemplateID = 2418
_GuDing.dwSkillID = 2234
_GuDing.tCastList = {}
_GuDing.tDoodadList = {}
_GuDing.nDelayTime = 500

local _BeiMing = {}

-----------------------------
---ͷ����ʾ��
-----------------------------
local _HandleRole = {
    handle     = nil,
    dwID       = nil,
    nIndex     = 0,
    nTopOffset = 0,
}
_HandleRole.__index = _HandleRole

function _HandleRole:new(dwID)
    local o = {}
    setmetatable(o, self)
    o.dwID = dwID
    return o
end

function _HandleRole:Create()
    local handle = LR_HeadName.handle
    local dwID = self.dwID
    local Handle_Dummy = handle:Lookup(sformat("Handle_Dummy_%d", dwID))
    if not Handle_Dummy then
        Handle_Dummy = handle:AppendItemFromIni(szIniFile, "Handle_Dummy", sformat("Handle_Dummy_%d", dwID))
    end
    Handle_Dummy:SetAlpha(255)
    local hText = Handle_Dummy:Lookup("Shadow_Text")
    local LifeBar = Handle_Dummy:Lookup("Shadow_LifeBar")
    local BorderOut = Handle_Dummy:Lookup("Shadow_BorderOut")
    local BorderIn = Handle_Dummy:Lookup("Shadow_BorderIn")
    local Patch = Handle_Dummy:Lookup("Shadow_Patch")

    local r, g, b, a = 0, 0, 0, 0
    Patch:SetTriangleFan(true)
    Patch:ClearTriangleFanPoint()
    --shadow:AppendTriangleFanPoint(0, 0, r, g, b, a)
    Patch:AppendTriangleFanPoint(0, 0, r, g, b, a)
    Patch:AppendTriangleFanPoint(0, 0, r, g, b, a)
    Patch:AppendTriangleFanPoint(0, 0, r, g, b, a)
    Patch:Show()

    self.handle = Handle_Dummy
    self.Image_TeamMark = Handle_Dummy:Lookup("Image_TeamMark")
    --Output("2", self.dwID)
    return Handle_Dummy
end

function _HandleRole:Remove()
    local handle = LR_HeadName.handle
    local dwID = self.dwID
    local Handle_Dummy = handle:Lookup(sformat("Handle_Dummy_%d", dwID))
    if Handle_Dummy then
        Handle_Dummy = handle:RemoveItem(Handle_Dummy)
    end
    return self
end

function _HandleRole:GetHandle()
    return self.handle
end

function _HandleRole:SetDrawName(tText)
    if type(tText) == "table" then
        self.tDrawName = clone(tText)
    end
    return self
end

function _HandleRole:DrawName()
    local Handle_Dummy = self.handle
    local hText = Handle_Dummy:Lookup("Shadow_Text")
    local tText = clone(self.tDrawName)

    hText:SetTriangleFan(GEOMETRY_TYPE.TEXT)
    hText:ClearTriangleFanPoint()
    hText:SetAlpha(255)
    hText:SetD3DPT(D3DPT.TRIANGLEFAN)
    local nHight = LR_HeadName.UsrData.Height
    local nOffsetY = -(LR_HeadName.UsrData.nOffset or 0) - 26

    local dwID = self.dwID
    local _Role = LR_HeadName._Role[dwID]
    local bTop = true
    if _Role:GetTemplateID() == 46297 or _Role:GetTemplateID() == 46140 then
        nOffset = nOffset + 50
        bTop = false
    end
    local del_height = -nHight

    local UIScale = LR_HeadName.UIScale
    local fx = UIScale * (LR_HeadName.UsrData.nFontScale or 1)
    if LR_HeadName.UsrData.bChangeSizeByUIScale then
        fx = LR_HeadName.UsrData.nFontScale or 1
    end

    if self.nTeamMark and LR_HeadName.UsrData.bShowTeamMark then
        if tMarkerTextList[self.nTeamMark] then
            if LR_HeadName.UsrData.nShowTeamMarkType == 1 then
                local me = GetClientPlayer()
                local _nType, _dwTargetID = me.GetTarget()
                if dwID == _dwTargetID then
                    tText[#tText + 1] = { szText = sformat("�� %s ��", tMarkerTextList[self.nTeamMark]), rgb = { 255, 201, 14 }, font = LR_HeadName.UsrData.font, fScale = fx, }
                else
                    tText[#tText + 1] = { szText = sformat("�� %s ��", tMarkerTextList[self.nTeamMark]), rgb = { 206, 164, 10 }, font = LR_HeadName.UsrData.font, fScale = fx, }
                end
                self:TeamMarkImageHide()
            elseif LR_HeadName.UsrData.nShowTeamMarkType == 2 then
                self:ShowTeamMarkImage()
            end
            SceneObject_SetTitleEffect(LR_HeadName._Role[dwID].nType, dwID, 0)
        end
    else
        self:TeamMarkImageHide()
    end

    if SCENE_DATA_CACHE[dwID] then
        local Frame_Now = GetLogicFrameCount()
        local Frame_End = 0
        local data = nil
        for k, v in pairs(SCENE_DATA_CACHE[dwID]) do
            if v.nEndFrame < Frame_Now then
                tremove(SCENE_DATA_CACHE[dwID], k)
            end
        end
        for k, v in pairs(SCENE_DATA_CACHE[dwID]) do
            if v.nEndFrame > Frame_End and v.nEndFrame >= Frame_Now then
                data = clone(v)
                Frame_End = v.nEndFrame
                break
            end
        end
        if Frame_End > 0 then
            --szText, {szText = temp, rgb = rgb , font = font2, fScale = 1, }
            --tText = {}
            local x1 = Table_GetBuffName(data.dwID, data.nLevel)
            tinsert(tText, { szText = sformat("%s_%0.1f", x1, (Frame_End - Frame_Now) / 16.0), rgb = { 255, 255, 255 }, font = 2, fScale = fx })
            --tinsert(tText, {szText = sformat("%s", ), rgb = {255, 255, 255}, font = 2, fScale = 1})
        end
        if next(SCENE_DATA_CACHE[dwID]) == nil then
            SCENE_DATA_CACHE[dwID] = nil
        end
        --Output(tText)
    end

    for i = 1, #tText do
        local r, g, b = unpack(tText[i].rgb)
        --hText:AppendCharacterID(self.dwID, true, r, g, b, 255, -30-(i-1)*nHight , tText[i].font , tText[i].szText, 0, 1)	----tText[i].font

        if tText[i].nType and tText[i].nType == "symbol" then
            hText:AppendCharacterID(dwID, bTop, r, g, b, 255, { 0, 0, 0, (-(nHight - 2) * tText[i].lenth), nOffsetY }, tText[i].font, tText[i].szText, 0, fx)----tText[i].font
        else
            if self.nTeamMark and LR_HeadName.UsrData.bShowTeamMark and LR_HeadName.UsrData.bHightLightTeamMark then
                local font = 207
                if LR_HeadName._Role[dwID]:GetShip() == "Enemy" then
                    font = 99
                    local _, _dwID = GetClientPlayer().GetTarget()
                    if _dwID == dwID then
                        font = 2
                    end
                end
                hText:AppendCharacterID(dwID, bTop, r, g, b, 255, { 0, 0, 0, 0, nOffsetY }, font, tText[i].szText, 0, fx)----tText[i].font
            else
                hText:AppendCharacterID(dwID, bTop, r, g, b, 255, { 0, 0, 0, 0, nOffsetY }, tText[i].font, tText[i].szText, 0, fx)----tText[i].font
            end
            nOffsetY = nOffsetY - nHight
        end
    end
    self.nTopOffset = -nOffsetY
end

function _HandleRole:DrawDoodad(tText)
    local Handle_Dummy = self.handle
    local hText = Handle_Dummy:Lookup("Shadow_Text")

    hText:SetTriangleFan(GEOMETRY_TYPE.TEXT)
    hText:ClearTriangleFanPoint()
    hText:SetAlpha(255)
    local nHight = LR_HeadName.UsrData.Height
    local nOffset = LR_HeadName.UsrData.nOffset or 0
    nOffset = nOffset - 12
    local UIScale = LR_HeadName.UIScale
    local fx = UIScale * (LR_HeadName.UsrData.nFontScale or 1)
    if LR_HeadName.UsrData.bChangeSizeByUIScale then
        fx = LR_HeadName.UsrData.nFontScale or 1
    end
    for i = 1, #tText do
        local r, g, b = unpack(tText[i].rgb)
        hText:AppendDoodadID(self.dwID, r, g, b, 255, { 0, 0, 0, 0, -50 - (i - 1) * nHight - nOffset }, tText[i].font, tText[i].szText, 0, fx)
    end
end

function _HandleRole:DrawLifeBoard()
    local Handle_Dummy = self.handle
    local dwID = self.dwID

    local BorderOut = Handle_Dummy:Lookup("Shadow_BorderOut")
    local BorderIn = Handle_Dummy:Lookup("Shadow_BorderIn")

    if not LR_HeadName.UsrData.LifeBar.ShowBorder then
        BorderOut:ClearTriangleFanPoint()
        BorderIn:ClearTriangleFanPoint()
        BorderOut:Hide()
        BorderIn:Hide()
        return
    end

    local nWidth = LR_HeadName.UsrData.LifeBar.Lenth
    local nHeight = LR_HeadName.UsrData.LifeBar.Height
    local nOffsetY = LR_HeadName.UsrData.LifeBar.nOffsetY or 0
    nOffsetY = nOffsetY + 0 + (LR_HeadName.UsrData.nOffset or 0)
    local Alpha = LR_HeadName.UsrData.LifeBar.Alpha
    local nOffset = LR_HeadName.UsrData.nOffset or 0

    local me = GetControlPlayer()
    if not me then
        return
    end

    if me.dwID == dwID then
        local HideWhenNotFight = LR_HeadName.GetbShow(me, TARGET.PLAYER, "HideLifeBar", "Self")
        if HideWhenNotFight and not me.bFightState then
            Alpha = mfloor(Alpha / 1.75)
        end
    end

    local _Role = LR_HeadName._Role[dwID]
    local bTop = true
    if _Role:GetTemplateID() == 46297 or _Role:GetTemplateID() == 46140 then
        nOffsetY = nOffsetY + 50
        bTop = false
    end

    -- ������߿�
    local bcX, bcY = -nWidth / 2, (-nHeight) - nOffsetY
    local r, g, b = unpack(LR_HeadName.UsrData.LifeBar.BorderColor)
    BorderOut:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
    BorderOut:SetD3DPT(D3DPT.TRIANGLEFAN)
    BorderOut:ClearTriangleFanPoint()

    BorderOut:AppendCharacterID(dwID, bTop, r, g, b, Alpha, { 0, 0, 0, bcX, bcY })
    BorderOut:AppendCharacterID(dwID, bTop, r, g, b, Alpha, { 0, 0, 0, bcX + nWidth, bcY })
    BorderOut:AppendCharacterID(dwID, bTop, r, g, b, Alpha, { 0, 0, 0, bcX + nWidth, bcY + nHeight })
    BorderOut:AppendCharacterID(dwID, bTop, r, g, b, Alpha, { 0, 0, 0, bcX, bcY + nHeight })
    BorderOut:Hide()

    -- �����ڱ߿�
    bcX, bcY = -(nWidth / 2 - 1), (-(nHeight - 1)) - nOffsetY
    BorderIn:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
    BorderIn:SetD3DPT(D3DPT.TRIANGLEFAN)
    BorderIn:ClearTriangleFanPoint()

    r, g, b = 80, 80, 80
    BorderIn:AppendCharacterID(dwID, bTop, r, g, b, Alpha, { 0, 0, 0, bcX, bcY })
    BorderIn:AppendCharacterID(dwID, bTop, r, g, b, Alpha, { 0, 0, 0, bcX + (nWidth - 2), bcY })
    BorderIn:AppendCharacterID(dwID, bTop, r, g, b, Alpha, { 0, 0, 0, bcX + (nWidth - 2), bcY + (nHeight - 2) })
    BorderIn:AppendCharacterID(dwID, bTop, r, g, b, Alpha, { 0, 0, 0, bcX, bcY + (nHeight - 2) })
    BorderIn:Hide()
end

function _HandleRole:DrawLife(t)
    local Handle_Dummy = self.handle

    local nWidth = LR_HeadName.UsrData.LifeBar.Lenth
    local nHeight = LR_HeadName.UsrData.LifeBar.Height
    local nOffsetY = LR_HeadName.UsrData.LifeBar.nOffsetY or 0
    nOffsetY = nOffsetY + 0 + (LR_HeadName.UsrData.nOffset or 0)
    --local Alpha = LR_HeadName.UsrData.LifeBar.Alpha
    local Alpha = 255
    local nOffset = LR_HeadName.UsrData.nOffset or 0

    local dwID = t.dwID
    local _Role = LR_HeadName._Role[dwID]
    local bTop = true
    if _Role:GetTemplateID() == 46297 or _Role:GetTemplateID() == 46140 then
        nOffsetY = nOffsetY + 50
        bTop = false
    end

    local me = GetControlPlayer()
    if not me then
        return
    end
    if me.dwID == dwID then
        local HideWhenNotFight = LR_HeadName.GetbShow(me, TARGET.PLAYER, "HideLifeBar", "Self")
        if HideWhenNotFight and not me.bFightState then
            --Alpha = mfloor(Alpha/1.75)
            Alpha = 180
            if Handle_Dummy:GetAlpha() == 255 then
                Handle_Dummy:SetAlpha(254)
                self:DrawLifeBoard()
            end
            --self:HideLifeBorder()
        else
            if Handle_Dummy:GetAlpha() ~= 255 then
                Handle_Dummy:SetAlpha(255)
                self:DrawLifeBoard()
            end
        end
    end

    local LifeBar = Handle_Dummy:Lookup("Shadow_LifeBar")
    local bcX, bcY = -(nWidth / 2 - 2), (-(nHeight - 2)) - nOffsetY

    local r, g, b = unpack(t.rgb)
    local LifePer = t.LifePer

    nWidth = (nWidth - 4) * LifePer

    ---����Ѫ��
    LifeBar:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
    LifeBar:SetD3DPT(D3DPT.TRIANGLEFAN)
    LifeBar:ClearTriangleFanPoint()

    LifeBar:AppendCharacterID(dwID, bTop, r, g, b, Alpha, { 0, 0, 0, bcX, bcY })
    LifeBar:AppendCharacterID(dwID, bTop, r, g, b, Alpha, { 0, 0, 0, bcX + nWidth, bcY })
    LifeBar:AppendCharacterID(dwID, bTop, r, g, b, Alpha, { 0, 0, 0, bcX + nWidth, bcY + (nHeight - 4) })
    LifeBar:AppendCharacterID(dwID, bTop, r, g, b, Alpha, { 0, 0, 0, bcX, bcY + (nHeight - 4) })

    --LifeBar:SetTriangleFan(GEOMETRY_TYPE.TEXT)
    local hLifePer = Handle_Dummy:Lookup("Shadow_LifePer")
    local nLifePercentTextOffsetX = LR_HeadName.UsrData.LifeBar.nLifePercentTextOffsetX or 0
    local nLifePercentTextOffsetY = bcY + (LR_HeadName.UsrData.LifeBar.nLifePercentTextOffsetY or 0)
    local nLifePercentTextScale = LR_HeadName.UsrData.LifeBar.nLifePercentTextScale or 0.8

    hLifePer:SetTriangleFan(GEOMETRY_TYPE.TEXT)
    hLifePer:ClearTriangleFanPoint()

    local UIScale = LR_HeadName.UIScale
    local fx = UIScale * nLifePercentTextScale
    if LR_HeadName.UsrData.bChangeSizeByUIScale then
        fx = nLifePercentTextScale
    end
    local nX, nY = nLifePercentTextOffsetX, nLifePercentTextOffsetY - 3
    if not LR_HeadName.UsrData.LifeBar.bNotCalLifeLenth then
        nX = nX + LR_HeadName.UsrData.LifeBar.Lenth / 2 + 15
    end

    hLifePer:AppendCharacterID(dwID, true, r, g, b, 255, { 0, 0, 0, nX, nY }, LR_HeadName.UsrData.font, sformat("%d%%", LifePer * 100), 0, fx)

    hLifePer:Hide()
    LifeBar:Hide()

    if GetLogicFrameCount() % 16 == 0 then
        self:DrawLifeBoard()
    end
end

function _HandleRole:SetLifeBarColor(rgb)
    self.lifeBarColor = rgb
    return self
end

function _HandleRole:HideLifeBar()
    local Handle_Dummy = self.handle

    local BorderOut = Handle_Dummy:Lookup("Shadow_BorderOut")
    local BorderIn = Handle_Dummy:Lookup("Shadow_BorderIn")
    local LifeBar = Handle_Dummy:Lookup("Shadow_LifeBar")
    local hLifePer = Handle_Dummy:Lookup("Shadow_LifePer")

    BorderOut:Hide()
    BorderIn:Hide()
    hLifePer:Hide()
    LifeBar:Hide()
end

function _HandleRole:HideLifeBorder()
    local Handle_Dummy = self.handle

    local BorderOut = Handle_Dummy:Lookup("Shadow_BorderOut")
    local BorderIn = Handle_Dummy:Lookup("Shadow_BorderIn")

    BorderOut:Hide()
    BorderIn:Hide()
end

function _HandleRole:ShowLifeBar()
    local Handle_Dummy = self.handle

    local BorderOut = Handle_Dummy:Lookup("Shadow_BorderOut")
    local BorderIn = Handle_Dummy:Lookup("Shadow_BorderIn")
    local LifeBar = Handle_Dummy:Lookup("Shadow_LifeBar")
    local hLifePer = Handle_Dummy:Lookup("Shadow_LifePer")

    local me = GetControlPlayer()
    if not me then
        return
    end
    if me.dwID == self.dwID then
        local HideWhenNotFight = LR_HeadName.GetbShow(me, TARGET.PLAYER, "HideLifeBar", "Self")
        if HideWhenNotFight and not me.bFightState then
            BorderIn:Show()
            BorderOut:Show()
        else
            BorderIn:Show()
            BorderOut:Show()
        end
    else
        BorderIn:Show()
        BorderOut:Show()
    end

    --BorderOut:Show()
    --BorderIn:Show()
    if LR_HeadName.UsrData.LifeBar.bShowLifePercentText then
        hLifePer:Show()
    end
    LifeBar:Show()
end

function _HandleRole:HideHandle()
    local Handle_Dummy = self.handle
    Handle_Dummy:Hide()
end

function _HandleRole:ShowHandle()
    local Handle_Dummy = self.handle
    Handle_Dummy:Show()
end

function _HandleRole:SetnIndex(nIndex)
    self.nIndex = nIndex
    return self
end

function _HandleRole:GetnIndex()
    return self.nIndex
end

function _HandleRole:GetnTopOffset()
    return self.nTopOffset
end

function _HandleRole:SetnTopOffset(nOffset)
    self.nTopOffset = nOffset
    return self
end

function _HandleRole:SetTeamMark(nMark)
    self.nTeamMark = nMark
    return self
end

function _HandleRole:ShowTeamMarkImage()
    local Handle_Dummy = self.handle
    local Image_TeamMark = Handle_Dummy:Lookup("Image_TeamMark")
    local dwID = self.dwID
    if _tPartyMark[dwID] and LR_HeadName.UsrData.bShowTeamMark and LR_HeadName.UsrData.nShowTeamMarkType == 2 then
        if tMarkerTextList[_tPartyMark[dwID]] then
            Image_TeamMark:SetFrame(tMarkerImageList[_tPartyMark[dwID]])
            Image_TeamMark:SetSize(44, 44)
            Image_TeamMark:SetAlpha(255)
            Image_TeamMark:Show()
        else
            Image_TeamMark:Hide()
        end
    else
        Image_TeamMark:Hide()
    end
    return self
end

function _HandleRole:TeamMarkImageHide()
    local Handle_Dummy = self.handle
    local Image_TeamMark = Handle_Dummy:Lookup("Image_TeamMark")
    Image_TeamMark:Hide()
    return self
end

function _HandleRole:TeamMarkImageGetPos()
    local me = GetClientPlayer()
    if not me then
        return
    end
    local tab = self
    local dwID = self.dwID
    PostThreadCall(function(tab, xScreen, yScreen)
        local xScreen = xScreen or 0
        local yScreen = yScreen or 0

        xScreen, yScreen = Station.AdjustToOriginalPos(xScreen, yScreen)
        tab.xScreen = xScreen
        tab.yScreen = yScreen

        tab:TeamMarkImageSetPos()

    end, tab, "Scene_GetCharacterTopScreenPos", dwID)
    return self
end

function _HandleRole:TeamMarkImageSetPos()
    local xScreen = self.xScreen
    local yScreen = self.yScreen
    local Handle_Dummy = self.handle
    local Image_TeamMark = nil
    if Handle_Dummy:IsValid() then
        Image_TeamMark = Handle_Dummy:Lookup("Image_TeamMark")
    end
    local dwID = self.dwID
    if not LR_HeadName._Role[dwID] then
        return
    end

    if Image_TeamMark then
        --local Image_TeamMark = Handle_Dummy:Lookup("Image_TeamMark")
        xScreen = xScreen - 22
        yScreen = yScreen - self.nTopOffset - 44 + LR_HeadName.UsrData.nMarkOffset or 0
        if self.dwID == 8471036 then
            --Output("s")
        end
        if LR_HeadName.bOn then
            SceneObject_SetTitleEffect(LR_HeadName._Role[dwID].nType, dwID, 0)
        end
        if _tPartyMark[dwID] then
            if GetLogicFrameCount() % 36 == 0 then
                self:ShowTeamMarkImage()
            end
            Image_TeamMark:Show()
        else
            Image_TeamMark:Hide()
        end
        Image_TeamMark:SetAbsPos(xScreen, yScreen)
    end
    return self
end

-----------------------------
---������
-----------------------------
local _Role = {
    dwID               = nil,
    szName             = "",
    nType              = "",
    szTongName         = "",
    szTitle            = "",
    handle             = nil,
    nShip              = "Neutrality",
    IsMissionObj       = false,
    CanAcceptQuest     = false,
    CanFinishQuest     = false,
    old_IsMissionObj   = false,
    old_CanAcceptQuest = false,
    old_CanFinishQuest = false,
    self               = nil,
    dwTemplateID       = nil,
    nMoveState         = MOVE_STATE.ON_STAND,
}
_Role.__index = _Role

function _Role:new(obj, nType)
    local o = {}
    setmetatable(o, self)
    o.dwID = obj.dwID
    o.self = obj
    o.dwTemplateID = 0
    if nType == TARGET.NPC or nType == TARGET.DOODAD then
        o.dwTemplateID = obj.dwTemplateID
    end

    return o
end

--------���� npc or player
function _Role:GetType()
    return self.nType
end
function _Role:SetType(nType)
    if self.nType ~= nType then
        self.nType = nType
    end
    return self
end

---------����
function _Role:GetName()
    return self.szName
end
function _Role:SetName(szName)
    if self.szName ~= szName then
        self.szName = szName
    end
    return self
end

---------�ƺ�
function _Role:GetTitle()
    return self.szTitle
end
function _Role:SetTitle(szTitle)
    if self.szTitle ~= szTitle then
        self.szTitle = szTitle
    end
    return self
end

---------��ϵ���Ѻã��жԡ�����
function _Role:GetShip()
    return self.nShip
end
function _Role:SetShip(nShip)
    if self.nShip ~= nShip then
        self.nShip = nShip
    end
    return self
end

----------�������
function _Role:SetTongName(szTongName)
    if self.szTongName ~= szTongName then
        self.szTongName = szTongName
    end
    return self
end
function _Role:GetTongName()
    return self.szTongName
end

------ͷ��handle
function _Role:SetHandle(hHandle)
    self.handle = hHandle
    return self
end
function _Role:GetHandle()
    return self.handle
end

function _Role:GetTemplateID()
    return self.dwTemplateID
end

------����״̬
function _Role:SetIsMissionObj()
    self.IsMissionObj = LR_HeadName.IsMissionObj({ szName = self.szName, dwID = self.dwID, nType = self.nType, dwTemplateID = self.dwTemplateID, nX = self.self.nX, nY = self.self.nY })
    return self
end
function _Role:GetIsMissionObj()
    return self.IsMissionObj
end
function _Role:Setold_IsMissionObj(arg)
    self.old_IsMissionObj = arg
    return self
end
function _Role:Getold_IsMissionObj()
    return self.old_IsMissionObj
end

function _Role:SetCanAcceptQuest()
    if self.nType == TARGET.NPC or self.nType == TARGET.DOODAD then
        self.CanAcceptQuest = LR_HeadName.CheckQuestAccept({ dwID = self.dwID, dwTemplateID = self.dwTemplateID, })
    else
        self.CanAcceptQuest = false
    end
    return self
end
function _Role:GetCanAcceptQuest()
    return self.CanAcceptQuest
end
function _Role:Setold_CanAcceptQuest(arg)
    self.old_CanAcceptQuest = arg
    return self
end
function _Role:Getold_CanAcceptQuest()
    return self.old_CanAcceptQuest
end

function _Role:SetCanFinishQuest()
    self.CanFinishQuest = LR_HeadName.CheckQuestFinish({ dwID = self.dwID, dwTemplateID = self.dwTemplateID, })
    return self
end
function _Role:GetCanFinishQuest()
    return self.CanFinishQuest
end
function _Role:Setold_CanFinishQuest(arg)
    self.old_CanFinishQuest = arg
    return self
end
function _Role:Getold_CanFinishQuest()
    return self.old_CanFinishQuest
end

function _Role:GetnMoveState()
    return self.nMoveState
end
function _Role:SetnMoveState(arg)
    self.nMoveState = arg
    return self
end

---------------------------------------------------
---------------------------------------------------
function LR_HeadName.OnFrameCreate()
    this:RegisterEvent("RENDER_FRAME_UPDATE")
    this:RegisterEvent("LR_BUFF_TRAN")
    this:RegisterEvent("UI_SCALED")

    local handle = this:Lookup("", "")
    LR_HeadName.handle = handle:Lookup("Handle_HeadName")
    this:SetAlpha(255)
    LR_HeadName.GetUIScale()
end

function LR_HeadName.OnEvent(szEvent)
    if szEvent == "RENDER_FRAME_UPDATE" then
        LR_HeadName.SetTeamMarkPos()
    elseif szEvent == "LR_BUFF_TRAN" then
        LR_HeadName.LR_BUFF_TRAN()
    elseif szEvent == "UI_SCALED" then
        LR_HeadName.GetUIScale()
        LR_HeadName.ReDrawAll()
    end
end

function LR_HeadName.OnFrameBreathe()
    if not LR_HeadName.bOn then
        return
    end
    LR_HeadName.SetTeamMarkPos()
    local me = GetControlPlayer()
    if not me then
        return
    end

    if GetLogicFrameCount() % 1 == 0 then
        local r, g, b, r1, g1, b1 = unpack(LR_HeadName.RandomRGB)
        r, r1 = LR_HeadName.Random(r, r1)
        g, g1 = LR_HeadName.Random(g, g1)
        b, b1 = LR_HeadName.Random(b, b1)
        LR_HeadName.RandomRGB = { r, g, b, r1, g1, b1 }
    end

    if not LR_HeadName.handle then
        LR_HeadName.handle = this:Lookup("", ""):Lookup("Handle_HeadName")
    end
    --local m = this:Lookup("",""):Lookup("Handle_HeadName"):GetItemCount()
    local m = LR_HeadName.handle:GetItemCount()
    --[[	for k, v in pairs(LR_HeadName.AllList) do
		m = m+1
	end]]

    if GetLogicFrameCount() % 4 == 0 then
        LR_HeadName.SortHandle()
    end

    for k, v in pairs(SCENE_DATA_CACHE) do
        LR_HeadName.Check(k, TARGET.PLAYER, true)
    end

    if LR_HeadName.UsrData.bSeeLimit then
        local tTemp = {}
        for k, v in pairs(LR_HeadName.AllList) do
            if v then
                local obj
                if v.nType == TARGET.DOODAD then
                    if LR_HeadName.DoodadCache[k] then
                        obj = LR_HeadName.DoodadCache[k]
                        --obj = GetDoodad(k)
                    else
                        obj = GetDoodad(k)
                    end
                elseif v.nType == TARGET.NPC then
                    obj = GetNpc(k)
                elseif v.nType == TARGET.PLAYER then
                    obj = GetPlayer(k)
                end
                if obj then
                    local distance = LR.GetDistance(obj)
                    tinsert(tTemp, { dwID = k, nType = v.nType, distance = distance, })
                else
                    if LR_HeadName._Role[k]:GetHandle() then
                        LR_HeadName._Role[k]:GetHandle():Remove()
                        LR_HeadName._Role[k]:SetHandle(nil)
                    end
                end
            end
        end

        tsort(tTemp, function(a, b)
            return a.distance < b.distance
        end)

        local n = 1

        for i = 1, #tTemp, 1 do
            if n <= LR_HeadName.UsrData.SeeMax then
                if m >= freq_limit then
                    local p = mfloor(m / 50)
                    if ((tTemp[i].dwID) % p) == (GetLogicFrameCount() % p) then
                        LR_HeadName.Check(tTemp[i].dwID, tTemp[i].nType)
                    end
                else
                    LR_HeadName.Check(tTemp[i].dwID, tTemp[i].nType)
                end
                if LR_HeadName._Role[tTemp[i].dwID] then
                    if LR_HeadName._Role[tTemp[i].dwID]:GetHandle() then
                        n = n + 1
                    end
                end
            else
                if tTemp[i].nType == TARGET.DOODAD then
                    LR_HeadName.Check(tTemp[i].dwID, tTemp[i].nType)
                else
                    if LR_HeadName._Role[tTemp[i].dwID] then
                        if LR_HeadName._Role[tTemp[i].dwID]:GetHandle() then
                            LR_HeadName._Role[tTemp[i].dwID]:GetHandle():Remove()
                            LR_HeadName._Role[tTemp[i].dwID]:SetHandle(nil)
                        end
                    end
                end
            end
        end
    else
        for k, v in pairs(LR_HeadName.AllList) do
            if m >= freq_limit then
                local p = mfloor(m / 50)
                if (k % p) == (GetLogicFrameCount() % p) then
                    LR_HeadName.Check(k, v.nType)
                end
            else
                LR_HeadName.Check(k, v.nType)
            end
        end
    end

    local _nType, _dwTargetID = me.GetTarget()
    if _nType == TARGET.NO_TARGET then
        if LR_HeadName.old_dwTargetID then
            LR_HeadName.Check(LR_HeadName.old_dwTargetID, LR_HeadName.old_nTargetType, true)
        end
    elseif _dwTargetID ~= LR_HeadName.old_dwTargetID then
        LR_HeadName.Check(LR_HeadName.old_dwTargetID, LR_HeadName.old_nTargetType, true)
        LR_HeadName.Check(_dwTargetID, _nType, true)
    end
    LR_HeadName.old_nTargetType = _nType
    LR_HeadName.old_dwTargetID = _dwTargetID
end

function LR_HeadName.OnFrameDestroy()

end

function LR_HeadName.SetTeamMarkPos()
    local me = GetClientPlayer()
    if not me then
        return
    end
    if LR_HeadName.UsrData.bShowTeamMark and LR_HeadName.UsrData.nShowTeamMarkType == 2 then
        for dwID, v in pairs(_tPartyMark) do
            local tab = LR_HeadName._Role[dwID]
            if tab then
                local obj
                if IsPlayer(dwID) then
                    obj = GetPlayer(dwID)
                else
                    obj = GetNpc(dwID)
                end
                if obj then
                    if tab:GetHandle() then
                        if LR.GetDistance(obj) <= mmax(0, LR_HeadName.UsrData.distanceMax - 5) then
                            tab:GetHandle():TeamMarkImageGetPos()
                        else
                            tab:GetHandle():TeamMarkImageHide()
                        end
                    end
                end
            end
        end
    else
        for dwID, v in pairs(_tPartyMark) do
            local tab = LR_HeadName._Role[dwID]
            if tab and tab:GetHandle() then
                tab:GetHandle():TeamMarkImageHide()
            end
        end
    end
end

function LR_HeadName.SortHandle()
    local me = GetControlPlayer()
    if not me then
        return
    end

    local m = LR_HeadName.handle:GetItemCount()

    local n = 0
    local t = {}
    local t2 = {}
    local t3 = {}
    -- refresh current index data

    ----t3���ڴ���Լ���Ŀ����Ŷӱ��
    local _nType, _dwTargetID = me.GetTarget()
    local t4 = {}
    t4[#t4 + 1] = { dwID = _dwTargetID, }
    if me.bFightState then
        t4[#t4 + 1] = { dwID = me.dwID, }
    end
    for i = 1, #t4, 1 do
        local tab = LR_HeadName._Role[t4[i].dwID]
        if tab and tab:GetHandle() then
            t3[#t3 + 1] = { handle = tab:GetHandle():GetHandle(), index = tab:GetHandle():GetnIndex(), bring2Top = true, }
        end
    end
    for dwID, v in pairs(_tPartyMark) do
        local tab = LR_HeadName._Role[dwID]
        if tab and tab:GetHandle() then
            t3[#t3 + 1] = { handle = tab:GetHandle():GetHandle(), index = tab:GetHandle():GetnIndex(), bring2Top = true, }
        end
    end
    for dwID, v in pairs(_GuDing.tDoodadList or {}) do
        local tab = LR_HeadName._Role[dwID]
        if tab and tab:GetHandle() then
            t3[#t3 + 1] = { handle = tab:GetHandle():GetHandle(), index = tab:GetHandle():GetnIndex(), bring2Top = true, }
        end
    end

    if m <= freq_limit then
        for dwID, tab in pairs(LR_HeadName._Role) do
            if not _tPartyMark[dwID] and not _GuDing.tDoodadList[dwID] then
                n = n + 1
                if tab:GetHandle() then
                    PostThreadCall(function(tab, xScreen, yScreen)
                        local handle = tab:GetHandle()
                        handle:SetnIndex(yScreen or 99999)
                    end, tab, "Scene_GetCharacterTopScreenPos", dwID)
                    local bring2Top = false
                    local IsMissionObj = tab:GetIsMissionObj()
                    local CanAcceptQuest = tab:GetCanAcceptQuest()
                    local CanFinishQuest = tab:GetCanFinishQuest()
                    if IsMissionObj or CanAcceptQuest or CanFinishQuest then
                        bring2Top = true
                    end

                    if n <= 90 or bring2Top then
                        if bring2Top then
                            if not (dwID == _dwTargetID or dwID == me.dwID) then
                                t2[#t2 + 1] = { handle = tab:GetHandle():GetHandle(), index = tab:GetHandle():GetnIndex(), bring2Top = bring2Top, }
                            end
                        else
                            if not (dwID == _dwTargetID or (dwID == me.dwID and me.bFightState)) then
                                t[#t + 1] = { handle = tab:GetHandle():GetHandle(), index = tab:GetHandle():GetnIndex(), bring2Top = bring2Top, }
                            end
                        end
                    end
                end
            end
        end
        -- sort
        tsort(t, function(a, b)
            return a.index < b.index
        end)
        tsort(t2, function(a, b)
            return a.index < b.index
        end)
    end

    for i = 1, #t2, 1 do
        t[#t + 1] = t2[i]
    end
    for i = 1, #t3, 1 do
        t[#t + 1] = t3[i]
    end
    -- adjust
    local n = 1
    for i = 1, #t do
        if m <= freq_limit then
            if t[i].handle and t[i].handle:GetIndex() ~= (i - 1) then
                t[i].handle:ExchangeIndex(i - 1)
            end
        else
            if t[i].handle and t[i].handle:GetIndex() ~= (m - #t + i - 1) then
                t[i].handle:ExchangeIndex(m - #t + i - 1)
            end
        end
    end
    LR_HeadName.handle:Sort()
    --[[
	for i = #t, 1, -1 do
		if t[i].handle and t[i].handle:GetIndex() ~=  (m - n) then
			t[i].handle:ExchangeIndex(m - n)
		end
		n = n+1
	end
	]]
end

function LR_HeadName.OpenFrame()
    local frame = Station.Lookup("Lowest/LR_HeadName")
    if not frame then
        return
    end

    if LR_HeadName.bOn then
        if LR.IsMapBlockAddon() then
            frame:Hide()
            LR_HeadName.Convert2SysHead()
        else
            frame:Show()
            LR_HeadName.HideSysHead()
        end
    else
        frame:Hide()
        LR_HeadName.ResumeSysHead()
    end
end

--------------------------------------------------------------------------
function LR_HeadName.GetSysHeadSettings()
    LR_HeadName.tSysSettings = {
        ["HEAD_NPC_NAME"]           = GetGlobalTopHeadFlag(HEAD_NPC, HEAD_NAME),
        ["HEAD_NPC_TITLE"]          = GetGlobalTopHeadFlag(HEAD_NPC, HEAD_TITLE),
        ["HEAD_NPC_LEFE"]           = GetGlobalTopHeadFlag(HEAD_NPC, HEAD_LEFE),

        ["HEAD_OTHERPLAYER_NAME"]   = GetGlobalTopHeadFlag(HEAD_OTHERPLAYER, HEAD_NAME),
        ["HEAD_OTHERPLAYER_TITLE"]  = GetGlobalTopHeadFlag(HEAD_OTHERPLAYER, HEAD_TITLE),
        ["HEAD_OTHERPLAYER_LEFE"]   = GetGlobalTopHeadFlag(HEAD_OTHERPLAYER, HEAD_LEFE),
        ["HEAD_OTHERPLAYER_GUILD"]  = GetGlobalTopHeadFlag(HEAD_OTHERPLAYER, HEAD_GUILD),

        ["HEAD_CLIENTPLAYER_NAME"]  = GetGlobalTopHeadFlag(HEAD_CLIENTPLAYER, HEAD_NAME),
        ["HEAD_CLIENTPLAYER_TITLE"] = GetGlobalTopHeadFlag(HEAD_CLIENTPLAYER, HEAD_TITLE),
        ["HEAD_CLIENTPLAYER_LEFE"]  = GetGlobalTopHeadFlag(HEAD_CLIENTPLAYER, HEAD_LEFE),
        ["HEAD_CLIENTPLAYER_GUILD"] = GetGlobalTopHeadFlag(HEAD_CLIENTPLAYER, HEAD_GUILD),

        ["AI_LIFE_BAR"]             = GetGlobalTopIntelligenceLife()
    }
    --	Output(LR_HeadName.tSysSettings)
end

function LR_HeadName.HideSysNpcTop()
    SetGlobalTopHeadFlag(HEAD_NPC, HEAD_NAME, false)
    SetGlobalTopHeadFlag(HEAD_NPC, HEAD_TITLE, false)
    SetGlobalTopHeadFlag(HEAD_NPC, HEAD_LEFE, false)
end

function LR_HeadName.HideSysPlayerTop()
    SetGlobalTopHeadFlag(HEAD_OTHERPLAYER, HEAD_NAME, false)
    SetGlobalTopHeadFlag(HEAD_OTHERPLAYER, HEAD_TITLE, false)
    SetGlobalTopHeadFlag(HEAD_OTHERPLAYER, HEAD_LEFE, false)
    SetGlobalTopHeadFlag(HEAD_OTHERPLAYER, HEAD_GUILD, false)

    SetGlobalTopHeadFlag(HEAD_CLIENTPLAYER, HEAD_NAME, false)
    SetGlobalTopHeadFlag(HEAD_CLIENTPLAYER, HEAD_TITLE, false)
    SetGlobalTopHeadFlag(HEAD_CLIENTPLAYER, HEAD_LEFE, false)
    SetGlobalTopHeadFlag(HEAD_CLIENTPLAYER, HEAD_GUILD, false)
end

function LR_HeadName.HideSysHead()
    if LR_HeadName.UsrData.NPC.bShow or LR_HeadName.UsrData.NPC.bAlwaysHideSysNpcTop then
        LR_HeadName.HideSysNpcTop()
    end
    if LR_HeadName.UsrData.Player.bShow or LR_HeadName.UsrData.Player.bAlwaysHideSysPlayerTop then
        LR_HeadName.HideSysPlayerTop()
    end
    if LR_HeadName.UsrData.NPC.bAlwaysHideSysNpcTop and LR_HeadName.UsrData.Player.bAlwaysHideSysPlayerTop then
        SetGlobalTopIntelligenceLife(false)
    end
end

function LR_HeadName.ResumeSysNpcTop()
    SetGlobalTopHeadFlag(HEAD_NPC, HEAD_NAME, LR_HeadName.tSysSettings["HEAD_NPC_NAME"])
    SetGlobalTopHeadFlag(HEAD_NPC, HEAD_TITLE, LR_HeadName.tSysSettings["HEAD_NPC_TITLE"])
    SetGlobalTopHeadFlag(HEAD_NPC, HEAD_LEFE, LR_HeadName.tSysSettings["HEAD_NPC_LEFE"])
end

function LR_HeadName.ResumeSysPlayerTop()
    SetGlobalTopHeadFlag(HEAD_OTHERPLAYER, HEAD_NAME, LR_HeadName.tSysSettings["HEAD_OTHERPLAYER_NAME"])
    SetGlobalTopHeadFlag(HEAD_OTHERPLAYER, HEAD_TITLE, LR_HeadName.tSysSettings["HEAD_OTHERPLAYER_TITLE"])
    SetGlobalTopHeadFlag(HEAD_OTHERPLAYER, HEAD_LEFE, LR_HeadName.tSysSettings["HEAD_OTHERPLAYER_LEFE"])

    SetGlobalTopHeadFlag(HEAD_OTHERPLAYER, HEAD_GUILD, LR_HeadName.tSysSettings["HEAD_OTHERPLAYER_GUILD"])
    SetGlobalTopHeadFlag(HEAD_CLIENTPLAYER, HEAD_NAME, LR_HeadName.tSysSettings["HEAD_CLIENTPLAYER_NAME"])
    SetGlobalTopHeadFlag(HEAD_CLIENTPLAYER, HEAD_TITLE, LR_HeadName.tSysSettings["HEAD_CLIENTPLAYER_TITLE"])
    SetGlobalTopHeadFlag(HEAD_CLIENTPLAYER, HEAD_LEFE, LR_HeadName.tSysSettings["HEAD_CLIENTPLAYER_LEFE"])
    SetGlobalTopHeadFlag(HEAD_CLIENTPLAYER, HEAD_GUILD, LR_HeadName.tSysSettings["HEAD_CLIENTPLAYER_GUILD"])
end

function LR_HeadName.ResumeSysHead()
    if not LR_HeadName.bOn or not LR_HeadName.UsrData.NPC.bShow and not LR_HeadName.UsrData.NPC.bAlwaysHideSysNpcTop then
        LR_HeadName.ResumeSysNpcTop()
    end
    if not LR_HeadName.bOn or not LR_HeadName.UsrData.Player.bShow and not LR_HeadName.UsrData.Player.bAlwaysHideSysPlayerTop then
        LR_HeadName.ResumeSysPlayerTop()
    end
    SetGlobalTopIntelligenceLife(LR_HeadName.tSysSettings["AI_LIFE_BAR"])
end

function LR_HeadName.Convert2SysHead()
    if LR_HeadName.bOn and LR_HeadName.UsrData.NPC.bShow then
        SetGlobalTopHeadFlag(HEAD_NPC, HEAD_NAME, LR_HeadName.UsrData.NPC["Enemy"].Name)
        SetGlobalTopHeadFlag(HEAD_NPC, HEAD_TITLE, LR_HeadName.UsrData.NPC["Enemy"].Title)
        SetGlobalTopHeadFlag(HEAD_NPC, HEAD_LEFE, LR_HeadName.UsrData.NPC["Enemy"].LifeBar)
    end
    if LR_HeadName.bOn and LR_HeadName.UsrData.Player.bShow then
        SetGlobalTopHeadFlag(HEAD_OTHERPLAYER, HEAD_NAME, LR_HeadName.UsrData.Player["Enemy"].Name)
        SetGlobalTopHeadFlag(HEAD_OTHERPLAYER, HEAD_TITLE, LR_HeadName.UsrData.Player["Enemy"].Title)
        SetGlobalTopHeadFlag(HEAD_OTHERPLAYER, HEAD_LEFE, LR_HeadName.UsrData.Player["Enemy"].LifeBar)
        SetGlobalTopHeadFlag(HEAD_OTHERPLAYER, HEAD_GUILD, LR_HeadName.UsrData.Player["Enemy"].Tong)

        SetGlobalTopHeadFlag(HEAD_CLIENTPLAYER, HEAD_NAME, LR_HeadName.UsrData.Player["Self"].Name)
        SetGlobalTopHeadFlag(HEAD_CLIENTPLAYER, HEAD_TITLE, LR_HeadName.UsrData.Player["Self"].Title)
        SetGlobalTopHeadFlag(HEAD_CLIENTPLAYER, HEAD_LEFE, LR_HeadName.UsrData.Player["Self"].LifeBar)
        SetGlobalTopHeadFlag(HEAD_CLIENTPLAYER, HEAD_GUILD, LR_HeadName.UsrData.Player["Self"].Tong)
    end
    if LR_HeadName.UsrData.NPC.bAlwaysHideSysNpcTop and LR_HeadName.UsrData.Player.bAlwaysHideSysPlayerTop then
        SetGlobalTopIntelligenceLife(false)
    end
end
------------------------------------

function LR_HeadName.Check(dwID, nType, bForced)
    local me = GetControlPlayer()
    if not me then
        return
    end
    local scene = me.GetScene()
    if not scene then
        return
    end
    local obj
    if nType == TARGET.NPC then
        obj = GetNpc(dwID)
    elseif nType == TARGET.PLAYER then
        obj = GetPlayer(dwID)
    elseif nType == TARGET.DOODAD then
        local bnotPass = true
        if LR_HeadName._Role[dwID] then
            if LR_HeadName._Role[dwID]:GetHandle() then
                bnotPass = false
            else
                if (dwID % 4) == (GetLogicFrameCount() % 4) then
                    bnotPass = fasle
                end
            end
        else
            if (dwID % 4) == (GetLogicFrameCount() % 4) then
                bnotPass = fasle
            end
        end
        if bnotPass then
            return
        end
        if LR_HeadName.DoodadCache[dwID] then
            obj = LR_HeadName.DoodadCache[dwID]
        else
            obj = GetDoodad(dwID)
        end
        if not LR_HeadName.DoodadCache[dwID] and obj then
            LR_HeadName.DoodadCache[dwID] = {}
            LR_HeadName.DoodadCache[dwID].dwID = dwID
            LR_HeadName.DoodadCache[dwID].nX = obj.nX
            LR_HeadName.DoodadCache[dwID].nY = obj.nY
            LR_HeadName.DoodadCache[dwID].nZ = obj.nZ
            LR_HeadName.DoodadCache[dwID].dwTemplateID = obj.dwTemplateID
            LR_HeadName.DoodadCache[dwID].szName = LR.Trim(obj.szName)
            LR_HeadName.DoodadCache[dwID].nKind = obj.nKind
            LR_HeadName.DoodadCache[dwID].bHaveQuest = obj.HaveQuest(me.dwID)
        end
    end
    if not obj then
        return
    end

    ----��Զ������ʾ����Ʒ npc �ȹ��˵�
    if nType == TARGET.DOODAD or nType == TARGET.NPC then
        if LR_HeadName.DoodadDonotAddPatch[obj.dwTemplateID] then
            LR_HeadName.AllList[dwID] = nil
            LR_HeadName.DoodadCache[dwID] = nil
            return
        end
    end

    if LR_HeadName._Role[dwID] then
        if LR_HeadName.UsrData.bDisLimit then
            local distance = LR.GetDistance(obj)
            if (distance > LR_HeadName.UsrData.distanceMax and nType ~= TARGET.DOODAD) or (nType == TARGET.Doodad and distance > 150) then
                if LR_HeadName._Role[dwID] then
                    local h = LR_HeadName._Role[dwID]:GetHandle()
                    if h then
                        h:Remove()
                        LR_HeadName._Role[dwID]:SetHandle(nil)
                    end
                end
                return
            end
        end
        if nType == TARGET.PLAYER or nType == TARGET.NPC then
            local bFresh = false
            local bShow = false
            if not LR_HeadName._Role[dwID]:GetHandle() then
                local _h = _HandleRole:new(dwID)
                LR_HeadName._Role[dwID]:SetHandle(_h)
                LR_HeadName._Role[dwID]:GetHandle():Create()
                LR_HeadName._Role[dwID]:GetHandle():DrawLifeBoard()
                LR_HeadName._Role[dwID]:GetHandle():HideLifeBar()
                if _tPartyMark[dwID] then
                    LR_HeadName._Role[dwID]:GetHandle():SetTeamMark(v)
                end
                bFresh = true
            end
            local _Role = LR_HeadName._Role[dwID]
            local szName = _Role:GetName()
            local szNameBsee = LR.Trim(obj.szName)
            local nShip = _Role:GetShip()
            local isChangGeShadow = false
            local dwEmployer = nil
            local nEmployerShip = nil
            local bShowChangGeShadow = false
            if _Role:GetTemplateID() == 46297 or _Role:GetTemplateID() == 46140 then
                isChangGeShadow = true
                dwEmployer = obj.dwEmployer
                if not LR_HeadName._Role[dwEmployer] then
                    LR_HeadName.Check(dwEmployer, TARGET.PLAYER)
                end
                if LR_HeadName._Role[dwEmployer] then
                    nEmployerShip = LR_HeadName._Role[dwEmployer]:GetShip()
                    if nEmployerShip ~= "Enemy" then
                        if _Role:GetTemplateID() == 46297 then
                            bShowChangGeShadow = LR_HeadName.GetShadowbShow("bShowShadow", nEmployerShip)
                        elseif _Role:GetTemplateID() == 46140 then
                            bShowChangGeShadow = LR_HeadName.GetShadowbShow("bShowBody", nEmployerShip)
                        end
                    end
                    --Output(nEmployerShip, bShowChangGeShadow)
                end
            end

            if nType == TARGET.NPC and not obj.CanSeeName() then
                if (szName == _L["Mission Point"] or obj.szName == "") and not LR_HeadName.IsMissionObj({ dwTemplateID = obj.dwTemplateID, dwMapID = LR_HeadName.dwMapID, nType = TARGET.NPC }) then
                    szName = ""
                end
            end

            if szName ~= ""
                    and ((nType == TARGET.PLAYER and LR_HeadName.GetbShow(obj, TARGET.PLAYER, "bShow", nShip))
                    or (nType == TARGET.NPC and LR_HeadName.GetbShow(obj, TARGET.NPC, "bShow", nShip) and not isChangGeShadow)
                    or (nType == TARGET.NPC and LR_HeadName.GetbShow(obj, TARGET.NPC, "bShow", nShip) and isChangGeShadow and bShowChangGeShadow)
            ) then
                local szTitle = _Role:GetTitle()
                local szTongName = _Role:GetTongName()
                local IsMissionObj = _Role:GetIsMissionObj()
                local CanAcceptQuest = _Role:GetCanAcceptQuest()
                local CanFinishQuest = _Role:GetCanFinishQuest()
                local nMoveState = _Role:GetnMoveState()
                local _tartype, _tarid = me.GetTarget()

                if bForced then
                    bFresh = true
                elseif szTitle ~= LR.Trim(obj.szTitle) and LR.Trim(obj.szTitle) ~= "" then
                    _Role:SetTitle(LR.Trim(obj.szTitle))
                    szTitle = LR.Trim(obj.szTitle)
                    bFresh = true
                elseif nShip ~= LR_HeadName.GetShip(obj, nType) then
                    _Role:SetShip(LR_HeadName.GetShip(obj, nType))
                    nShip = LR_HeadName.GetShip(obj, nType)
                    bFresh = true
                elseif szTongName ~= LR_HeadName.GetTongName(obj) and LR_HeadName.GetTongName(obj) ~= "" and nType == TARGET.PLAYER then
                    _Role:SetTongName(LR_HeadName.GetTongName(obj))
                    szTongName = LR_HeadName.GetTongName(obj)
                    bFresh = true
                elseif (obj.bFightState and nShip == "Enemy")
                        or (nShip == "Ally" and obj.nCurrentLife < obj.nMaxLife and nType == TARGET.NPC)
                then
                    bFresh = true
                elseif _tarid == obj.dwID and LR_HeadName.UsrData.bShowTargetFace then
                    bFresh = true
                elseif _tarid == obj.dwID and LR_HeadName.UsrData.bShowTargetDis then
                    bFresh = true
                elseif IsMissionObj then
                    if LR_HeadName.UsrData.bShowQMode == 2 and LR_HeadName.UsrData.bShowQuestFlag then
                        bFresh = true
                        _Role:Setold_IsMissionObj(true)
                    elseif LR_HeadName.UsrData.bShowQMode == 1 and LR_HeadName.UsrData.bShowQuestFlag and not _Role:Getold_IsMissionObj() then
                        bFresh = true
                        _Role:Setold_IsMissionObj(true)
                    end
                elseif not IsMissionObj and _Role:Getold_IsMissionObj() then
                    if LR_HeadName.UsrData.bShowQuestFlag then
                        bFresh = true
                        _Role:Setold_IsMissionObj(false)
                    end
                elseif CanAcceptQuest ~= _Role:Getold_CanAcceptQuest() or CanAcceptQuest or CanFinishQuest ~= _Role:Getold_CanAcceptQuest() or CanFinishQuest then
                    if LR_HeadName.UsrData.bShowQMode == 2 and LR_HeadName.UsrData.bShowQuestFlag and (CanAcceptQuest or CanFinishQuest) then
                        bFresh = true
                        _Role:Setold_CanAcceptQuest(CanAcceptQuest)
                        _Role:Setold_CanFinishQuest(CanFinishQuest)
                    elseif LR_HeadName.UsrData.bShowQMode == 1 and LR_HeadName.UsrData.bShowQuestFlag then
                        if CanAcceptQuest ~= _Role:Getold_CanAcceptQuest() then
                            bFresh = true
                            _Role:Setold_CanAcceptQuest(CanAcceptQuest)
                        end
                        if CanFinishQuest ~= _Role:Getold_CanAcceptQuest() then
                            bFresh = true
                            _Role:Setold_CanFinishQuest(CanFinishQuest)
                        end
                    end
                elseif nMoveState ~= obj.nMoveState and obj.nMoveState == MOVE_STATE.ON_DEATH then
                    bFresh = true
                    _Role:SetnMoveState(obj.nMoveState)
                elseif nMoveState == MOVE_STATE.ON_DEATH and obj.nMoveState ~= MOVE_STATE.ON_DEATH then
                    bFresh = true
                    _Role:SetnMoveState(obj.nMoveState)
                end

                local handle = _Role:GetHandle()
                if bFresh then
                    if IsMissionObj and nType == TARGET.NPC then
                        if LR_HeadName.UsrData.bShowQuestFlag then
                            MINIMAP_LIST[dwID] = { nType = 8, obj = obj, nFrame1 = 199, nFrame2 = 48, }
                        end
                    else
                        MINIMAP_LIST[dwID] = nil
                    end
                    local szText = {}
                    local rgb = LR_HeadName.GetColor(obj, nType, nShip)
                    rgb = LR_HeadName.FixColor(obj, rgb, nShip)
                    local font = LR_HeadName.UsrData.font
                    local font2
                    if font == 17 then
                        font2 = font
                    else
                        font2 = font
                    end
                    local line1Text = ""
                    if line1Text ~= "" then
                        tinsert(szText, { szText = line1Text, rgb = rgb, font = font, })
                    end
                    if szTongName ~= "" and nType == TARGET.PLAYER and LR_HeadName.GetbShow(obj, TARGET.PLAYER, "Tong", nShip) then
                        if not (LR_HeadName.UsrData.HideInDungeon.bOn and LR_HeadName.UsrData.HideInDungeon.Tong and scene.nType == MAP_TYPE.DUNGEON) then
                            tinsert(szText, { szText = sformat("[%s]", szTongName), rgb = rgb, font = font, })
                        end
                    end
                    local line2Text = ""
                    if szTitle ~= "" and LR_HeadName.GetbShow(obj, nType, "Title", nShip) then
                        if not (nType == TARGET.PLAYER and LR_HeadName.UsrData.HideInDungeon.bOn and LR_HeadName.UsrData.HideInDungeon.Title and scene.nType == MAP_TYPE.DUNGEON) then
                            line2Text = sformat("<%s>", szTitle)
                        end
                    end
                    if nType == TARGET.PLAYER then
                        if g_tStrings.tForceTitle[obj.dwForceID] and LR_HeadName.GetbShow(obj, nType, "ForceID", nShip)
                                and not (LR_HeadName.UsrData.HideInDungeon.bOn and LR_HeadName.UsrData.HideInDungeon.ForceID and scene.nType == MAP_TYPE.DUNGEON) then
                            if line2Text ~= "" then
                                line2Text = sformat("%s %s", g_tStrings.tForceTitle[obj.dwForceID], line2Text)
                            else
                                line2Text = g_tStrings.tForceTitle[obj.dwForceID]
                            end
                        end
                        if ROLETYPE_TEXT[obj.nRoleType] and LR_HeadName.GetbShow(obj, nType, "RoleType", nShip)
                                and not (LR_HeadName.UsrData.HideInDungeon.bOn and LR_HeadName.UsrData.HideInDungeon.RoleType and scene.nType == MAP_TYPE.DUNGEON) then
                            if line2Text ~= "" then
                                line2Text = sformat("%s %s", line2Text, ROLETYPE_TEXT[obj.nRoleType])
                            else
                                line2Text = ROLETYPE_TEXT[obj.nRoleType]
                            end
                        end
                    end
                    if line2Text ~= "" then
                        tinsert(szText, { szText = line2Text, rgb = rgb, font = font, })
                    end
                    if szName ~= "" then
                        local temp = ""
                        if LR_HeadName.GetbShow(obj, nType, "Name", nShip) then
                            if not (nType == TARGET.PLAYER and LR_HeadName.UsrData.HideInDungeon.bOn and LR_HeadName.UsrData.HideInDungeon.Name and scene.nType == MAP_TYPE.DUNGEON) then
                                temp = szName
                            end
                            if nType == TARGET.NPC then
                                if obj.dwEmployer ~= nil then
                                    local Employer = GetPlayer(obj.dwEmployer)
                                    if Employer and LR.Trim(Employer.szName) ~= "" then
                                        if (obj.dwTemplateID ~= 46297 and obj.dwTemplateID ~= 46140) then
                                            temp = sformat("\"%s\"%s\"%s\"", LR.Trim(Employer.szName), _L["'s"], temp)
                                        else
                                            tinsert(szText, { szText = sformat("(%s)", LR.Trim(Employer.szName)), rgb = rgb, font = font, })
                                        end
                                    end
                                end
                            end
                        end
                        if LR_HeadName.GetbShow(obj, nType, "Level", nShip) then
                            if not (nType == TARGET.PLAYER and LR_HeadName.UsrData.HideInDungeon.bOn and LR_HeadName.UsrData.HideInDungeon.Level and scene.nType == MAP_TYPE.DUNGEON) then
                                if not (_Role:GetTemplateID() == 46297 or _Role:GetTemplateID() == 46140) then
                                    -----����Ӱ�Ӳ���ʾ�ȼ�
                                    temp = sformat("(%d) %s", obj.nLevel, temp)
                                end
                            end
                        end
                        if (obj.bFightState and nShip == "Enemy" and LR_HeadName.GetbShow(obj, nType, "bShowLifePer", nShip)) or
                                (nShip == "Ally" and obj.nCurrentLife < obj.nMaxLife and nType == TARGET.NPC)
                        then
                            local nMaxLife = obj.nMaxLife
                            local nCurrentLife = obj.nCurrentLife
                            if nType == TARGET.NPC then
                                nMaxLife = GetTargetMaxLife(TARGET.NPC, obj.dwID)
                            end
                            local LifePer = mmin(1, nCurrentLife / nMaxLife)
                            temp = sformat("%s (%0.1f%%)", temp, LifePer * 100)
                        end
                        local _, _dwID = me.GetTarget()
                        if _dwID ~= me.dwID and _dwID == obj.dwID and LR_HeadName.UsrData.bShowTargetDis or obj.bFightState and nShip == "Enemy" and LR_HeadName.UsrData.bShowFightingEnemyDis then
                            temp = sformat(_L["%s.%0.1f chi"], temp, LR.GetDistance(obj))
                        end
                        if _dwID ~= me.dwID and _dwID == obj.dwID and LR_HeadName.UsrData.bShowTargetFace then
                            if LR.IsInBack(obj) then
                                temp = sformat(_L["%s (B)"], temp)
                            else
                                temp = sformat(_L["%s (Z)"], temp)
                            end
                        end

                        if IsMissionObj or CanAcceptQuest or CanFinishQuest then
                            if LR_HeadName.UsrData.bShowQMode == 2 and LR_HeadName.UsrData.bShowQuestFlag then
                                local temp2 = ""
                                local rgb2 = LR_HeadName.RandomRGB
                                if CanAcceptQuest then
                                    temp2 = sformat("%s%s", temp2, _L["<SYMBOL_ACCEPT>"])
                                end
                                if CanFinishQuest then
                                    temp2 = sformat("%s%s", temp2, _L["<SYMBOL_FINISH>"])
                                end
                                if IsMissionObj then
                                    temp2 = sformat("%s%s", temp2, LR_HeadName.UsrData.CustomText or _L["<SYMBOL_MISSIONOBJ1>"])
                                end
                                tinsert(szText, { szText = temp, rgb = rgb, font = font2, fScale = 1, })
                                tinsert(szText, { szText = temp2, rgb = rgb2, font = font, })
                            elseif LR_HeadName.UsrData.bShowQMode == 1 and LR_HeadName.UsrData.bShowQuestFlag then
                                local cymbolText = ""
                                if CanFinishQuest then
                                    --cymbolText = "��"
                                    temp = sformat("%s %s   ", _L["<SYMBOL_FINISH>"], temp)
                                elseif IsMissionObj then
                                    --cymbolText = "��"
                                    temp = sformat("%s %s   ", _L["<SYMBOL_MISSIONOBJ2>"], temp)
                                elseif CanAcceptQuest then
                                    --cymbolText = "��"
                                    temp = sformat("%s %s   ", _L["<SYMBOL_ACCEPT>"], temp)
                                end
                                tinsert(szText, { szText = temp, rgb = rgb, font = font2, fScale = 1, })
                                --tinsert(szText, {szText = cymbolText, rgb = rgb , font = font2, fScale = 1, nType = "symbol", lenth = mceil(slen(temp)/2)})
                            else
                                tinsert(szText, { szText = temp, rgb = rgb, font = font2, fScale = 1, })
                            end
                        else
                            tinsert(szText, { szText = temp, rgb = rgb, font = font2, fScale = 1, })
                        end
                    end
                    handle:SetLifeBarColor(rgb)
                    if next(szText) ~= nil then
                        handle:SetDrawName(szText):DrawName()
                    end
                end

                -------------------------------------
                -----Ѫ����ʾ����;û���ֵĲ���ʾѪ��
                -------------------------------------
                local bShowLife = false
                if nType == TARGET.NPC then
                    local bShowLifeBar = LR_HeadName.GetbShow(obj, TARGET.NPC, "LifeBar", nShip)
                    local HideWhenFight = LR_HeadName.GetbShow(obj, TARGET.NPC, "HideLifeBar", nShip)
                    if bShowLifeBar then
                        if HideWhenFight then
                            if obj.bFightState then
                                bShowLife = true
                            end
                        else
                            bShowLife = true
                        end
                    end
                elseif nType == TARGET.PLAYER then
                    local bShowLifeBar = LR_HeadName.GetbShow(obj, TARGET.PLAYER, "LifeBar", nShip)
                    local HideWhenFight = LR_HeadName.GetbShow(obj, TARGET.PLAYER, "HideLifeBar", nShip)
                    if bShowLifeBar then
                        if scene.nType == MAP_TYPE.DUNGEON then
                            if LR_HeadName.UsrData.HideInDungeon.bOn and LR_HeadName.UsrData.HideInDungeon.LifeBar and obj.dwID ~= me.dwID then

                            else
                                if HideWhenFight then
                                    if obj.bFightState then
                                        bShowLife = true
                                    elseif obj.dwID == me.dwID and obj.nCurrentLife < obj.nMaxLife then
                                        bShowLife = true
                                    end
                                else
                                    bShowLife = true
                                end
                            end
                        else
                            if HideWhenFight then
                                if obj.bFightState then
                                    bShowLife = true
                                elseif obj.dwID == me.dwID and obj.nCurrentLife < obj.nMaxLife then
                                    bShowLife = true
                                end
                            else
                                bShowLife = true
                            end
                        end
                    end
                end
                if bForced then
                    handle:DrawLifeBoard()
                end
                if bShowLife then
                    local rgb = { 255, 0, 0 }
                    if LR_HeadName.UsrData.LifeBar.ColorMode == 1 then
                        rgb = { 255, 0, 0 }
                    elseif LR_HeadName.UsrData.LifeBar.ColorMode == 2 then
                        rgb = LR_HeadName.GetColor(obj, nType, nShip)
                        rgb = LR_HeadName.FixColor(obj, rgb, nShip)
                    end

                    local nMaxLife = obj.nMaxLife
                    local nCurrentLife = obj.nCurrentLife
                    if nType == TARGET.NPC then
                        nMaxLife = GetTargetMaxLife(TARGET.NPC, obj.dwID)
                    end
                    local LifePer = mmin(1, nCurrentLife / nMaxLife)
                    handle:DrawLife({ dwID = dwID, rgb = rgb, LifePer = LifePer, })
                    handle:ShowLifeBar()
                else
                    handle:HideLifeBar()
                end
                ----------------------------------------------------------
                ----------����Ѫ��------------------------------
                ----------------------------------------------------------
            else
                if szName == "" then
                    LR_HeadName._Role[dwID]:GetHandle():Remove()
                    LR_HeadName._Role[dwID]:SetHandle(nil)
                    LR_HeadName._Role[dwID] = nil
                    LR_HeadName.AllList[dwID] = nil
                else
                    LR_HeadName._Role[dwID]:GetHandle():Remove()
                    LR_HeadName._Role[dwID]:SetHandle(nil)
                end
            end
        elseif nType == TARGET.DOODAD then
            local bShow = false
            local bFresh = false
            local _Role = LR_HeadName._Role[dwID]
            local szName = _Role:GetName()
            local _szName = LR.Trim(obj.szName)
            if _szName == "" and LR_HeadName.IsMissionObj({ dwID = obj.dwID, dwTemplateID = obj.dwTemplateID, nType = TARGET.DOODAD, szName = LR.Trim(obj.szName) }) then
                _szName = LR.TABLE_GetDoodadTemplateName(obj.dwTemplateID)
            end

            if szName ~= _szName then
                _Role:SetName(_szName)
                szName = _szName
                LR_HeadName.OnEventCheckMission(dwID)
                bFresh = true
            end

            if szName ~= "" then
                local IsMissionObj = _Role:GetIsMissionObj()
                local isMineral = false
                local isAgriculture = false
                local isBeiMing = false
                local HasQuest = false
                if next(LR_HeadName.GetDoodadQuest(obj.dwTemplateID)) ~= nil then
                    HasQuest = true
                end
                local CanAcceptQuest = LR_HeadName.CheckDoodadCanAcceptQuest(obj)
                local AllQuestFinished = LR_HeadName.CheckDoodadAllQuestFinished(obj)
                if bForced then
                    bFresh = true
                    bShow = true
                elseif HasQuest or CanAcceptQuest then
                    bShow = true
                    bFresh = true
                elseif IsMissionObj then
                    if LR_HeadName.UsrData.bShowQuestDoodad then
                        if LR_HeadName.UsrData.bShowQMode == 2 and LR_HeadName.UsrData.bShowQuestFlag then
                            bFresh = true
                        end
                        bShow = true
                    end
                end
                if obj.nKind == DOODAD_KIND.QUEST then
                    if LR_HeadName.DoodadCache[obj.dwID].bHaveQuest and LR_HeadName.UsrData.bShowQuestDoodad then
                        bShow = true
                    end
                end
                if LR_HeadName.CustomDoodad[szName] then
                    bShow = true
                elseif LR_HeadName.CheckAgriculture(szName) and obj.nKind == DOODAD_KIND.CRAFT_TARGET then
                    bShow = true
                    isAgriculture = true
                elseif LR_HeadName.CheckMineral(szName) and obj.nKind == DOODAD_KIND.CRAFT_TARGET then
                    bShow = true
                    isMineral = true
                elseif LR_HeadName.DoodadBeShow[szName] then
                    bShow = true
                elseif LR_HeadName.DoodadKind[obj.nKind] then
                    if obj.nKind == DOODAD_KIND.CRAFT_TARGET then
                        local _start, _end = sfind(szName, _L["BeiMing."])
                        if _start then
                            bShow = true
                            isBeiMing = true
                        end
                    else
                        bShow = true
                    end
                elseif LR_HeadName.DoodadTemplateSee[obj.dwTemplateID] then
                    bShow = true
                end

                if not bShow and obj.nKind == DOODAD_KIND.QUEST and LR_HeadName.UsrData.bShowQuestDoodad then
                    local MissionList = LR_HeadName.MissionList
                    local dwMapID = LR_HeadName.dwMapID
                    for ii = 1, #MissionList, 1 do
                        if MissionList[ii].nType == "P" and MissionList[ii].dwMapID == dwMapID then
                            if MissionList[ii].p1 and MissionList[ii].p2 then
                                local dis = mfloor(((obj.nX - MissionList[ii].p1) ^ 2 + (obj.nY - MissionList[ii].p2) ^ 2) ^ 0.5) / 64
                                if dis <= 8 then
                                    bShow = true
                                end
                            end
                        end
                    end
                end

                if LR_HeadName.UsrData.bEnhanceGuDing then
                    if obj.dwTemplateID == _GuDing.dwTemplateID then
                        bShow = true
                        bFresh = true
                        szName = sformat(_L["%s.%s"], szName, mfloor((_GuDing.tDoodadList[obj.dwID].nEndFrame - GetLogicFrameCount()) / 16))
                        if _GuDing.tDoodadList[obj.dwID].szName ~= "" then
                            szName = sformat(_L["%s.%s"], _GuDing.tDoodadList[obj.dwID].szName, szName)
                        else
                            local flag = true
                            for k, v in pairs(_GuDing.tCastList) do
                                if mabs(_GuDing.tDoodadList[obj.dwID].nTime - v.nTime) <= 1 and flag then
                                    _GuDing.tDoodadList[obj.dwID].szName = v.szName
                                    _GuDing.tCastList[k] = nil
                                    flag = false
                                end
                            end
                        end
                    end
                end

                local handle = _Role:GetHandle()
                if bShow or bFresh then
                    if isBeiMing then
                        _BeiMing[dwID] = true
                    end
                    if not handle then
                        local _h = _HandleRole:new(dwID)
                        _Role:SetHandle(_h)
                        _Role:GetHandle():Create()
                        handle = _Role:GetHandle()
                        local rgb = LR_HeadName.Color["Doodad"]
                        local szText = {}
                        local font = LR_HeadName.UsrData.font
                        local temp = szName
                        if LR_HeadName.UsrData.bShowDoodadKind then
                            if isAgriculture then
                                temp = sformat("%s(%s)", temp, _L["Agriculture"])
                            elseif isMineral then
                                temp = sformat("%s(%s)", temp, _L["Mineral"])
                            else
                                temp = sformat("%s(%s)", temp, LR_HeadName.DoodadKindDescribe[obj.nKind])
                            end
                        end
                        tinsert(szText, { szText = temp, rgb = rgb, font = font, })
                        handle:DrawDoodad(szText)
                        handle:HideHandle()
                    end
                    if bFresh then
                        local _start, _end = sfind(szName, _L["BeiMing."])
                        if _start then
                            bShow = true
                            local bookname = sgsub(szName, _L["BeiMing."], "")
                            if LR.GetBookReadStatusByName(bookname) then
                                szName = sformat("%s (%s)", szName, _L["be read"])
                            end
                        end
                        local rgb = LR_HeadName.Color["Doodad"]
                        local szText = {}
                        local font = LR_HeadName.UsrData.font
                        local temp = szName
                        if LR_HeadName.UsrData.bShowDoodadKind then
                            if isAgriculture then
                                temp = sformat("%s (%s)", temp, _L["Agriculture"])
                            elseif isMineral then
                                temp = sformat("%s (%s)", temp, _L["Mineral"])
                            else
                                temp = sformat("%s (%s)", temp, LR_HeadName.DoodadKindDescribe[obj.nKind])
                            end
                        end

                        if IsMissionObj then
                            if LR_HeadName.UsrData.bShowQMode == 2 and LR_HeadName.UsrData.bShowQuestFlag then
                                local rgb2 = LR_HeadName.RandomRGB
                                local temp2 = LR_HeadName.UsrData.CustomText or _L["<SYMBOL_MISSIONOBJ1>"]
                                tinsert(szText, { szText = temp, rgb = rgb, font = font, })
                                tinsert(szText, { szText = temp2, rgb = rgb2, font = font, })
                            elseif LR_HeadName.UsrData.bShowQMode == 1 and LR_HeadName.UsrData.bShowQuestFlag then
                                temp = sformat("%s %s   ", _L["<SYMBOL_MISSIONOBJ2>"], temp)
                                if IsCtrlKeyDown() then
                                    temp = sformat("%s %d   ", temp, obj.dwTemplateID)
                                end

                                tinsert(szText, { szText = temp, rgb = rgb, font = font, })
                            else
                                tinsert(szText, { szText = temp, rgb = rgb, font = font, })
                            end
                        else
                            if CanAcceptQuest then
                                if LR_HeadName.UsrData.bShowQMode == 2 and LR_HeadName.UsrData.bShowQuestFlag then
                                    local rgb2 = LR_HeadName.RandomRGB
                                    local temp2 = LR_HeadName.UsrData.CustomText or _L["<SYMBOL_ACCEPT>"]
                                    tinsert(szText, { szText = temp, rgb = rgb, font = font, })
                                    tinsert(szText, { szText = temp2, rgb = rgb2, font = font, })
                                elseif LR_HeadName.UsrData.bShowQMode == 1 and LR_HeadName.UsrData.bShowQuestFlag then
                                    temp = sformat("%s %s   ", _L["<SYMBOL_ACCEPT>"], temp)
                                    tinsert(szText, { szText = temp, rgb = rgb, font = font, })
                                else
                                    tinsert(szText, { szText = temp, rgb = rgb, font = font, })
                                end
                            else
                                if HasQuest then
                                    if AllQuestFinished then
                                        tinsert(szText, { szText = temp, rgb = rgb, font = font, })
                                    else
                                        tinsert(szText, { szText = sformat("? %s", temp), rgb = rgb, font = font, })
                                    end
                                else
                                    tinsert(szText, { szText = temp, rgb = rgb, font = font, })
                                end
                            end
                        end
                        handle:DrawDoodad(szText)
                        handle:HideHandle()
                    end
                    if bShow then
                        handle:ShowHandle()
                    end
                else
                    local _h = LR_HeadName._Role[dwID]:GetHandle()
                    if _h then
                        _h:Remove()
                        LR_HeadName._Role[dwID]:SetHandle(nil)
                        LR_HeadName._Role[dwID] = nil
                        LR_HeadName.AllList[dwID] = nil
                    end
                    MINIMAP_LIST[dwID] = nil
                end
            else
                LR_HeadName._Role[dwID]:GetHandle():Remove()
                LR_HeadName._Role[dwID] = nil
                LR_HeadName.AllList[dwID] = nil
                LR_HeadName.DoodadCache[dwID] = nil
                LR_HeadName.DoodadList[dwID] = nil
                MINIMAP_LIST[dwID] = nil
            end
        end
    else
        local szName = LR.Trim(obj.szName)
        if nType == TARGET.NPC then
            if obj.CanSeeName() then
                if LR.Trim(obj.szName) == "" then
                    szName = LR.Trim(Table_GetNpcTemplateName(obj.dwTemplateID))
                end
            else
                if DEBUG then
                    if LR.Trim(obj.szName) == "" then
                        szName = LR.Trim(Table_GetNpcTemplateName(obj.dwTemplateID))
                    end
                    szName = sformat("#%d%s", obj.dwTemplateID, szName)
                else
                    --Output({dwTemplateID = obj.dwTemplateID, nType = TARGET.NPC, dwMapID = LR_HeadName.dwMapID})
                    if LR_HeadName.IsMissionObj({ dwTemplateID = obj.dwTemplateID, nType = TARGET.NPC, dwMapID = LR_HeadName.dwMapID }) then
                        if szName == "" then
                            if LR.Trim(Table_GetNpcTemplateName(obj.dwTemplateID)) == "" then
                                szName = _L["Mission Point"]
                            else
                                szName = LR.Trim(Table_GetNpcTemplateName(obj.dwTemplateID))
                            end
                        end
                    else
                        szName = ""
                    end
                end
            end
            if LR_HeadName.NpcTemplateSee[obj.dwTemplateID] then
                szName = LR.Trim(Table_GetNpcTemplateName(obj.dwTemplateID))
            end
            if obj.dwTemplateID == 46297 then
                szName = _L["[Shadow]"]
            end
            if obj.dwTemplateID == 46140 then
                szName = _L["[TrueBody]"]
            end
            if obj.dwTemplateID == 4691 then
                szName = _L["--"]
            end
        end
        if nType == TARGET.DOODAD then
            if LR_HeadName.DoodadTemplateSee[obj.dwTemplateID] then
                szName = LR.Trim(LR.TABLE_GetDoodadTemplateName(obj.dwTemplateID))
            end
            if LR_HeadName.IsMissionObj({ dwTemplateID = obj.dwTemplateID, dwID = obj.dwID, nType = TARGET.DOODAD, szName = LR.Trim(obj.szName) }) then
                if LR.Trim(obj.szName) == "" then
                    szName = LR.Trim(LR.TABLE_GetDoodadTemplateName(obj.dwTemplateID))
                end
            end
        end
        if szName ~= "" then
            LR_HeadName._Role[dwID] = _Role:new(obj, nType)
            LR_HeadName._Role[dwID]:SetType(nType)
            LR_HeadName._Role[dwID]:SetShip(LR_HeadName.GetShip(obj, nType))
            if nType == TARGET.NPC or nType == TARGET.PLAYER then
                LR_HeadName._Role[dwID]:SetName(szName)
            end
        end
    end
end

function LR_HeadName.ReDrawAll()
    for k, v in pairs(LR_HeadName.AllList) do
        if v then
            LR_HeadName.Check(k, v.nType, true)
        end
    end
end

function LR_HeadName.ReDrawNpc()
    for k, v in pairs(LR_HeadName.AllList) do
        if v and v.nType == TARGET.NPC then
            LR_HeadName.Check(k, v.nType, true)
        end
    end
end

function LR_HeadName.GetShip(obj, nType)
    local me = GetControlPlayer()
    if not me then
        return "Neutrality"
    end
    if nType == TARGET.NPC then
        local npc = GetNpc(obj.dwID)
        if npc then
            if IsEnemy(obj.dwID, me.dwID) then
                return "Enemy"
            elseif IsAlly(obj.dwID, me.dwID) then
                return "Ally"
            elseif IsNeutrality(obj.dwID, me.dwID) then
                return "Neutrality"
            end
        else
            return "Neutrality"
        end
    elseif nType == TARGET.PLAYER then
        local player = GetPlayer(obj.dwID)
        if player then
            if obj.dwID == me.dwID then
                return "Self"
            elseif me.IsPlayerInMyParty(obj.dwID) then
                return "Party"
            elseif IsEnemy(me.dwID, obj.dwID) then
                return "Enemy"
            elseif IsAlly(obj.dwID, me.dwID) then
                return "Ally"
            elseif IsNeutrality(obj.dwID, me.dwID) then
                return "Neutrality"
            end
        else
            return "Neutrality"
        end
    end
    return "Neutrality"
end

function LR_HeadName.GetColor(obj, nType, nShip)
    local me = GetControlPlayer()
    if not me then
        return LR_HeadName.Color["Neutrality"]
    end
    if not obj then
        return LR_HeadName.Color["Neutrality"]
    end
    if not nType then
        return LR_HeadName.Color["Neutrality"]
    end
    if not nShip then
        return LR_HeadName.Color["Neutrality"]
    end
    if nType == TARGET.NPC then
        if obj.dwEmployer ~= nil then
            local _obj = GetPlayer(obj.dwEmployer)
            if _obj then
                local nship2 = LR_HeadName.GetShip(_obj, TARGET.PLAYER)
                return LR_HeadName.GetColor(_obj, TARGET.PLAYER, nship2)
            end
        end
        return LR_HeadName.Color[nShip]
    elseif nType == TARGET.PLAYER then
        local nColorMode = LR_HeadName.UsrData.Player[nShip].nColorMode or 1
        if nColorMode == 1 then
            return LR_HeadName.Color[nShip]
        elseif nColorMode == 2 then
            local r, g, b = LR.GetMenPaiColor(obj.dwForceID)
            local h, s, v = LR.rgb2hsv(r, g, b)
            return { LR.hsv2rgb(h, s, (v * 0.8)) }
        end
    elseif nType == TARGET.DOODAD then
        return LR_HeadName.Color["Doodad"]
    end
    return LR_HeadName.Color["Neutrality"]
end

function LR_HeadName.FixColor(obj, rgb, nShip)
    local me = GetControlPlayer()
    if not me then
        return
    end
    local _nType, _dwTargetID = me.GetTarget()
    local r, g, b = unpack(rgb)
    if obj.nMoveState == MOVE_STATE.ON_DEATH then
        if _dwTargetID == obj.dwID then
            return { mceil(r / 2.2), mceil(g / 2.2), mceil(b / 2.2), }
        else
            return { mceil(r / 2.5), mceil(g / 2.5), mceil(b / 2.5), }
        end
    elseif _dwTargetID == obj.dwID then
        if _nType == TARGET.PLAYER then
            local nColorMode = LR_HeadName.UsrData.Player[nShip].nColorMode or 1
            if nColorMode == 1 then
                return LR_HeadName.HighLightColor[nShip]
            else
                local h, s, v = LR.rgb2hsv(r, g, b)
                return { LR.hsv2rgb(h, s, (v * 1.25)) }
            end
        else
            return LR_HeadName.HighLightColor[nShip]
        end
    else
        return rgb
    end
end

function LR_HeadName.Random(rgb, rgb1)
    local x1 = Random(16)
    rgb = rgb + rgb1 * x1
    if rgb > 255 then
        rgb = 255 * 2 - rgb
        rgb1 = -1
    elseif rgb < 80 then
        rgb = 160 - rgb
        rgb1 = 1
    end
    return rgb, rgb1
end

function LR_HeadName.GetTongName(player)
    if not player then
        return ""
    end
    if not IsPlayer(player.dwID) then
        return ""
    end
    local dwTongID = player.dwTongID
    if LR_HeadName.tTongList[dwTongID] then
        return LR_HeadName.tTongList[dwTongID].szName
    else
        local szName = LR.GetTongName(dwTongID)
        if dwTongID > 0 and szName ~= "" then
            LR_HeadName.tTongList[dwTongID] = { szName = szName }
        end
        return szName
    end
end

function LR_HeadName.GetbShow(obj, nType1, nType2, nShip)
    local me = GetControlPlayer()
    if not me then
        return false
    end
    if not obj then
        return false
    end
    if nType1 == TARGET.NPC then
        if not LR_HeadName.UsrData.NPC.bShow then
            return false
        else
            if LR_HeadName.UsrData.NPC[nShip].bShow then
                return LR_HeadName.UsrData.NPC[nShip][nType2]
            else
                return false
            end
        end
    elseif nType1 == TARGET.PLAYER then
        if not LR_HeadName.UsrData.Player.bShow then
            return false
        else
            if LR_HeadName.UsrData.Player[nShip].bShow then
                return LR_HeadName.UsrData.Player[nShip][nType2]
            else
                return false
            end
        end
    end
end

function LR_HeadName.GetShadowbShow(nType, nShip)
    local me = GetControlPlayer()
    if not me then
        return false
    end
    if not nType or not nShip then
        return false
    end
    if not LR_HeadName.UsrData.ChangGeShadow then
        return false
    end
    if not LR_HeadName.UsrData.ChangGeShadow.bShow then
        return false
    end
    if LR_HeadName.UsrData.ChangGeShadow[nShip].bShow then
        return LR_HeadName.UsrData.ChangGeShadow[nShip][nType]
    else
        return false
    end
end

function LR_HeadName.PLAYER_ENTER_SCENE()
    LR_HeadName.AllList[arg0] = { dwID = arg0, nType = TARGET.PLAYER, Quest_List = {}, }
    if not LR_HeadName.bOn then
        return
    end
    local me = GetClientPlayer()
    if not me then
        return
    end
    if _tPartyMark[arg0] then
        LR.DelayCall(400, function()
            LR_HeadName.PARTY_SET_MARK()
        end)
    end
end

function LR_HeadName.PLAYER_LEAVE_SCENE()
    local dwID = arg0
    if LR_HeadName._Role[dwID] then
        if LR_HeadName._Role[dwID]:GetHandle() then
            LR_HeadName._Role[dwID]:GetHandle():Remove()
            LR_HeadName._Role[dwID]:SetHandle(nil)
        end
        LR_HeadName._Role[dwID] = nil
    end
    LR_HeadName.AllList[dwID] = nil
end

function LR_HeadName.NPC_ENTER_SCENE()
    LR_HeadName.AllList[arg0] = { dwID = arg0, nType = TARGET.NPC, Quest_List = {}, }
    if not LR_HeadName.bOn then
        return
    end
    local dwID = arg0
    local npc = GetNpc(arg0)
    if not npc then
        return
    end
    local me = GetClientPlayer()
    if not me then
        return
    end
    --------��ȡnpc���ϵ������б�
    LR_HeadName.RefreshOneNPCQuest(dwID)
    if not npc.CanSeeName() and DEBUG then
        Output(npc.dwTemplateID, Table_GetNpcTemplateName(npc.dwTemplateID))
    end

    LR.DelayCall(200, LR_HeadName.Check(dwID, TARGET.NPC, true))
    ------ˢ��ǿ��ˢ��npc��һˢhandle
    LR.DelayCall(300, LR_HeadName.Check(dwID, TARGET.NPC, true))
    ------ˢ��ǿ��ˢ��npc����ˢ����
    LR.DelayCall(400, LR_HeadName.OnEventCheckMission(dwID))
    ------������npc������״̬
    if _tPartyMark[arg0] then
        LR.DelayCall(400, function()
            LR_HeadName.PARTY_SET_MARK()
        end)
    end
end

function LR_HeadName.NPC_LEAVE_SCENE()
    local dwID = arg0
    if LR_HeadName._Role[dwID] then
        if LR_HeadName._Role[dwID]:GetHandle() then
            local handle = LR_HeadName._Role[dwID]:GetHandle()
            LR_HeadName._Role[dwID]:SetHandle(nil)
            handle:Remove()
        end
        LR_HeadName._Role[dwID] = nil
    end
    LR_HeadName.AllList[dwID] = nil
    MINIMAP_LIST[arg0] = nil
    NPC_CAN_ACCEPT_QUEST[dwID] = nil
    NPC_CAN_FINISH_QUEST[dwID] = nil
end

function LR_HeadName.DOODAD_ENTER_SCENE()
    local dwID = arg0
    LR_HeadName.DoodadList[arg0] = { dwID = dwID, nType = TARGET.DOODAD, Quest_List = {}, nTime = GetCurrentTime(), nFrame = GetLogicFrameCount() }
    if not LR_HeadName.bOn then
        return
    end
    LR.DelayCall(100, function()
        LR_HeadName.AddSingleDoodad2AllList(dwID)
    end)
end

function LR_HeadName.DOODAD_LEAVE_SCENE()
    if LR_HeadName._Role[arg0] then
        local _h = LR_HeadName._Role[arg0]:GetHandle()
        if _h then
            _h:Remove()
        end
        LR_HeadName._Role[arg0] = nil
    end
    LR_HeadName.AllList[arg0] = nil
    LR_HeadName.DoodadCache[arg0] = nil
    LR_HeadName.DoodadList[arg0] = nil
    MINIMAP_LIST[arg0] = nil
    _BeiMing[arg0] = nil
end

function LR_HeadName.OnEventCheckMission(dwID)
    if LR_HeadName._Role[dwID] then
        LR_HeadName._Role[dwID]:SetIsMissionObj()
        LR_HeadName._Role[dwID]:SetCanAcceptQuest()
        LR_HeadName._Role[dwID]:SetCanFinishQuest()
    end
end

function LR_HeadName.PARTY_UPDATE_BASE_INFO()
    LR.DelayCall(400, function()
        LR_HeadName.PARTY_SET_MARK()
    end)
end

LR.RegisterEvent("PLAYER_ENTER_SCENE", function()
    LR_HeadName.PLAYER_ENTER_SCENE()
end)
LR.RegisterEvent("PLAYER_LEAVE_SCENE", function()
    LR_HeadName.PLAYER_LEAVE_SCENE()
end)
LR.RegisterEvent("NPC_ENTER_SCENE", function()
    LR_HeadName.NPC_ENTER_SCENE()
end)
LR.RegisterEvent("NPC_LEAVE_SCENE", function()
    LR_HeadName.NPC_LEAVE_SCENE()
end)
LR.RegisterEvent("DOODAD_ENTER_SCENE", function()
    LR_HeadName.DOODAD_ENTER_SCENE()
end)
LR.RegisterEvent("DOODAD_LEAVE_SCENE", function()
    LR_HeadName.DOODAD_LEAVE_SCENE()
end)

LR.RegisterEvent("PARTY_UPDATE_BASE_INFO", function()
    LR_HeadName.PARTY_UPDATE_BASE_INFO()
end)
----------------------------------
-------�������
----------------------------------
--[[
�ٷ������������ڴ������������Ϣ��
g_tTable.Quest�������˽�ȡnpc��������npc�����������£���Ҫ��ɵ�������doodad��npc��place�ص���Ϣ
g_tTable.Quests��������������ı���Ϣ�����֡����������µĶԻ����е�����
]]

local _QuestTraceInfo = {}    ---����׷���������ɶ�
local _QuestInfo = {}    --���ڴ���������������
local _dbQuestInfo = {}    ---���ڴ�������ִ�����ݣ�������ȡnpc��������npc����ɱnpc�ȸ�������

function LR_HeadName.SpliteString(szText, bOutput)
    local tList = {}

    for szType, szData in sgmatch(szText, "<(%a) ([%d,;|]+)>") do
        if szType == "D" or szType == "N" then
            if bOutput then
                Output(szData)
            end
            for szData2 in sgmatch(szData, "([%d,]+);?") do
                if bOutput then
                    Output(szData2)
                end
                local tNum = {}
                for nNum in sgmatch(szData2, "(%d+),?") do
                    tNum[#tNum + 1] = tonumber(nNum)
                end
                local szName = ""
                if szType == "N" then
                    if tNum[2] then
                        szName = Table_GetNpcTemplateName(tNum[2])
                    end
                else
                    if tNum[2] then
                        szName = LR.TABLE_GetDoodadTemplateName(tNum[2])
                    end
                end
                tList[#tList + 1] = { nType = szType, dwMapID = tNum[1], dwTemplateID = tNum[2], szName = szName }
            end
        else
            for szData2 in sgmatch(szData, "([%d,]+);?") do
                local tNum = {}
                for nNum in sgmatch(szData2, "(%d+),?") do
                    tNum[#tNum + 1] = tonumber(nNum)
                end
                tList[#tList + 1] = { nType = szType, dwMapID = tNum[1], nX = tNum[2], nY = tNum[3] }
            end
        end
    end
    return tList
end

function LR_HeadName.GetAllMissionNeed()
    local me = GetControlPlayer()
    if not me then
        return
    end
    _QuestTraceInfo = {}
    _QuestInfo = {}
    LR_HeadName.MissionNeed = {}
    for i = 0, 24, 1 do
        local dwQuestID = me.GetQuestID(i)
        if dwQuestID > 0 then
            LR_HeadName.GetSingleMissionNeed(dwQuestID)
        end
    end
end

function LR_HeadName.GetSingleMissionNeed(dwQuestID)
    local me = GetControlPlayer()
    if not me then
        return
    end

    _QuestTraceInfo[dwQuestID] = me.GetQuestTraceInfo(dwQuestID) or {}
    _QuestInfo[dwQuestID] = LR.Table_GetQuestStringInfo(dwQuestID) or {}
    _dbQuestInfo[dwQuestID] = g_tTable.Quest:Search(dwQuestID) or {}

    if _QuestInfo[dwQuestID].szName == LR_HeadName.szMissionName then
        Output(dwQuestID, _QuestTraceInfo[dwQuestID], _QuestInfo[dwQuestID])
    end

    LR_HeadName.MissionNeed[dwQuestID] = {}
    LR_HeadName.GetPatched(dwQuestID)
    LR_HeadName.Get_need_item(dwQuestID)
    LR_HeadName.Get_kill_npc(dwQuestID)
    LR_HeadName.Get_quest_state(dwQuestID)

    if _QuestInfo[dwQuestID].szName == LR_HeadName.szMissionName then
        Output(dwQuestID, LR_HeadName.MissionNeed[dwQuestID])
    end
end

function LR_HeadName.OutputSingleMissionNeed(dwQuestID)
    LR_HeadName.GetSingleMissionNeed(dwQuestID)
    Output(LR_HeadName.MissionNeed[dwQuestID])
end

function LR_HeadName.GetPatched(dwQuestID)
    local MissionNeed = LR_HeadName.MissionNeed[dwQuestID]
    local MissionPatch = LR_HeadName.MissionPatch[dwQuestID]
    if MissionPatch then
        for k, v in pairs(MissionPatch) do
            if v.dwQuestID == dwQuestID and v.mode == "all" then
                MissionNeed[#MissionNeed + 1] = v
            end
        end
    end
end

function LR_HeadName.Get_need_item(dwQuestID)
    local MissionNeed = LR_HeadName.MissionNeed[dwQuestID]
    local MissionPatch = LR_HeadName.MissionPatch[dwQuestID]
    local QuestTraceInfo = _QuestTraceInfo[dwQuestID] or {}
    local QuestInfo = _QuestInfo[dwQuestID] or {}
    local dbQuestInfo = _dbQuestInfo[dwQuestID] or {}
    local szMissionName = LR_HeadName.szMissionName
    local need_item = QuestTraceInfo.need_item or {}
    local MissionPatch = LR_HeadName.MissionPatch[dwQuestID]
    if next(need_item) == nil then
        return
    end
    local flag, finish_flag = {}, true
    for k, v in pairs(need_item) do
        if v.have < v.need then
            finish_flag = false
            local dbInfo = dbQuestInfo[sformat("szNeedItem%d", v.i + 1)]
            if dbInfo and dbInfo ~= "" then
                for k2, v2 in pairs(LR_HeadName.SpliteString(dbInfo)) do
                    MissionNeed[#MissionNeed + 1] = v2
                end
            end
            local itemInfo = GetItemInfo(v.type, v.index)
            if itemInfo then
                MissionNeed[#MissionNeed + 1] = { dwTabType = v.type, dwIndex = v.index, szName = itemInfo.szName, nType = "I" }
            end
            if MissionPatch then
                for k2, v2 in pairs(MissionPatch) do
                    if v2.dwQuestID == dwQuestID and v2.mode == "need_item" and v2.k == k then
                        MissionNeed[#MissionNeed + 1] = v2
                    end
                end
            end
        end
        flag[v.i + 1] = true
    end
    if not finish_flag then
        for i = 1, 4, 1 do
            if not flag[i] then
                local dbInfo = dbQuestInfo[sformat("szNeedItem%d", i)]
                if dbInfo and dbInfo ~= "" then
                    for k2, v2 in pairs(LR_HeadName.SpliteString(dbInfo)) do
                        MissionNeed[#MissionNeed + 1] = v2
                    end
                end
            end
        end
    end
end

function LR_HeadName.Get_kill_npc(dwQuestID)
    local MissionNeed = LR_HeadName.MissionNeed[dwQuestID]
    local MissionPatch = LR_HeadName.MissionPatch[dwQuestID]
    local QuestTraceInfo = _QuestTraceInfo[dwQuestID] or {}
    local QuestInfo = _QuestInfo[dwQuestID] or {}
    local dbQuestInfo = _dbQuestInfo[dwQuestID] or {}
    local szMissionName = LR_HeadName.szMissionName
    local kill_npc = QuestTraceInfo.kill_npc or {}
    if next(kill_npc) == nil then
        return
    end
    local flag, finish_flag = {}, true
    for k, v in pairs(kill_npc) do
        if v.have < v.need then
            local dbInfo = dbQuestInfo[sformat("szKillNpc%d", v.i + 1)]
            if dbInfo and dbInfo ~= "" then
                for k2, v2 in pairs(LR_HeadName.SpliteString(dbInfo)) do
                    MissionNeed[#MissionNeed + 1] = v2
                    MissionNeed[#MissionNeed + 1] = { dwTemplateID = v.template_id, dwMapID = v2.dwMapID, nType = "N" }
                end
            end

        end
        flag[v.i + 1] = true
    end
    if not finish_flag then
        for i = 1, 4, 1 do
            if not flag[i] then
                local dbInfo = dbQuestInfo[sformat("szKillNpc%d", i)]
                if dbInfo and dbInfo ~= "" then
                    for k2, v2 in pairs(LR_HeadName.SpliteString(dbInfo)) do
                        MissionNeed[#MissionNeed + 1] = v2
                    end
                end
            end
        end
    end
end

function LR_HeadName.Get_quest_state(dwQuestID, bOutput)
    local MissionNeed = LR_HeadName.MissionNeed[dwQuestID]
    local MissionPatch = LR_HeadName.MissionPatch[dwQuestID]
    local QuestTraceInfo = _QuestTraceInfo[dwQuestID] or {}
    local QuestInfo = _QuestInfo[dwQuestID] or {}
    local dbQuestInfo = _dbQuestInfo[dwQuestID] or {}
    local szMissionName = LR_HeadName.szMissionName
    local quest_state = QuestTraceInfo.quest_state or {}
    if next(quest_state) == nil then
        return
    end

    local flag, finish_flag = {}, true
    for k, v in pairs(quest_state) do
        if v.have < v.need then
            local dbInfo = dbQuestInfo[sformat("szQuestState%d", v.i + 1)]
            if dbInfo and dbInfo ~= "" then
                if bOutput then
                    Output(dbInfo)
                    Output(LR_HeadName.SpliteString(dbInfo, true))
                end
                for k2, v2 in pairs(LR_HeadName.SpliteString(dbInfo)) do
                    MissionNeed[#MissionNeed + 1] = v2
                end
            end
            finish_flag = false
        end
        flag[v.i + 1] = true
    end
    if not finish_flag then
        for i = 1, 4, 1 do
            if not flag[i] then
                local dbInfo = dbQuestInfo[sformat("szQuestState%d", i)]
                if dbInfo and dbInfo ~= "" then
                    for k2, v2 in pairs(LR_HeadName.SpliteString(dbInfo)) do
                        MissionNeed[#MissionNeed + 1] = v2
                    end
                end
            end
        end
    end
end

function LR_HeadName.GetQuestNeedTree()
    LR_HeadName.MissionList = {}
    local MissionList = LR_HeadName.MissionList
    local MissionNeed = LR_HeadName.MissionNeed
    for dwQuestID, v in pairs(MissionNeed) do
        for k1, v1 in pairs(v) do
            MissionList[#MissionList + 1] = clone(v1)
        end
    end
end

-----------------------------------------
------��ȡ���������������Ʒ��Ŀ����Ϣ����ˢ��LR_HeadName._Role����Ƿ�Ϊ������Ʒ
function LR_HeadName.Tree()
    local me = GetControlPlayer()
    if not me then
        return
    end
    if not LR_HeadName.bOn then
        return
    end
    --��ȡ�������������Ŀ����Ϣ
    LR_HeadName.GetQuestNeedTree()
    for dwID, v in pairs(LR_HeadName.AllList) do
        if v.nType == TARGET.NPC or v.nType == TARGET.DOODAD then
            LR_HeadName.OnEventCheckMission(dwID)
        end
    end
end

function LR_HeadName.GetQuestBaseInfo(dwQuestID)
    local dwQuestID = dwQuestID
    local me = GetControlPlayer()
    if not me then
        return
    end
    local t = { szAccept = {}, szFinish = {}, }
    local QuestInfo = LR.Table_GetQuestStringInfo(dwQuestID)
    --Output("5", dwQuestID)
    local szQuestName = QuestInfo.szName
    local tQuest = g_tTable.Quest:Search(dwQuestID)
    if not tQuest then
        return t
    end
    --Output("6", tQuest)
    local szAccept = LR.GetQuestPoint(tQuest.szAccept) or {}
    local szFinish = LR.GetQuestPoint(tQuest.szFinish) or {}
    --Output("7")
    for k, v in pairs(szAccept) do
        if (v[1][3] == "D" or v[1][3] == "N") and v[1][4] then
            t.szAccept[#t.szAccept + 1] = { dwMapID = k, dwTemplateID = v[1][4] }
        end
    end
    for k, v in pairs(szFinish) do
        if (v[1][3] == "D" or v[1][3] == "N") and v[1][4] then
            t.szFinish[#t.szFinish + 1] = { dwMapID = k, dwTemplateID = v[1][4] }
        end
    end
    t.szQuestName = szQuestName
    t.dwQuestID = dwQuestID
    return t
end

function LR_HeadName.RefreshAllNPCQuest()
    local dwQuestID = dwQuestID
    local me = GetClientPlayer()
    if not me then
        return
    end
    for dwID, v in pairs(LR_HeadName.AllList) do
        if v and v.nType == TARGET.NPC then
            LR_HeadName.RefreshOneNPCQuest(dwID)
        end
    end
end

function LR_HeadName.RefreshOneNPCQuest(dwID)
    local me = GetClientPlayer()
    if not me then
        return
    end
    local npc = GetNpc(dwID)
    if npc then
        NPC_CAN_ACCEPT_QUEST[dwID] = nil
        NPC_CAN_FINISH_QUEST[dwID] = nil
        local tQuestIDs = npc.GetNpcQuest()
        ---�����������
        for k2, dwQuestID in pairs(tQuestIDs) do
            if me.CanAcceptQuest(dwQuestID, TARGET.NPC, dwID) == 1 then
                NPC_CAN_ACCEPT_QUEST[dwID] = true
                break
            end
        end
        --������������
        for k2, dwQuestID in pairs(tQuestIDs) do
            if me.CanFinishQuest(dwQuestID, TARGET.NPC, dwID) == 1 then
                NPC_CAN_FINISH_QUEST[dwID] = true
                break
            end
        end
    end
end

function LR_HeadName.AddAllDoodad2AllList()
    for k, v in pairs(LR_HeadName.DoodadList) do
        LR_HeadName.AddSingleDoodad2AllList(k)
    end
end

-------------------------------------
--------������������doodad����alllist�б���ˢ��״̬
function LR_HeadName.AddSingleDoodad2AllList(dwID)
    local me = GetControlPlayer()
    if not me then
        return
    end
    local obj = GetDoodad(dwID)
    if obj then
        if LR_HeadName.DoodadDonotAddPatch[obj.dwTemplateID] then
            return
        end
        local bAdd = false
        local szName = LR.Trim(obj.szName)
        local IsMissionObj = LR_HeadName.IsMissionObj({ dwID = obj.dwID, dwTemplateID = obj.dwTemplateID, nType = TARGET.DOODAD, szName = LR.Trim(obj.szName) })
        local HasQuest = false
        if next(LR_HeadName.GetDoodadQuest(obj.dwTemplateID)) ~= nil then
            HasQuest = true
        end
        local CanAcceptQuest = LR_HeadName.CheckDoodadCanAcceptQuest(obj)
        if obj.nKind == DOODAD_KIND.QUEST and LR_HeadName.UsrData.bShowQuestDoodad then
            if obj.HaveQuest(me.dwID) then
                bAdd = true
                if LR_HeadName.DoodadCache[dwID] then
                    LR_HeadName.DoodadCache[dwID].bHaveQuest = true
                end
            else
                if LR_HeadName.DoodadCache[dwID] then
                    LR_HeadName.DoodadCache[dwID].bHaveQuest = false
                end
            end
        end
        if (HasQuest or CanAcceptQuest) and obj.nKind ~= DOODAD_KIND.CORPSE then
            bAdd = true
        elseif LR_HeadName.CustomDoodad[szName] then
            bAdd = true
        elseif LR_HeadName.DoodadBeShow[szName] then
            bAdd = true
        elseif LR_HeadName.CheckAgriculture(szName) and obj.nKind == DOODAD_KIND.CRAFT_TARGET then
            bAdd = true
        elseif LR_HeadName.CheckMineral(szName) and obj.nKind == DOODAD_KIND.CRAFT_TARGET then
            bAdd = true
        elseif LR_HeadName.DoodadKind[obj.nKind] then
            if obj.nKind == DOODAD_KIND.CRAFT_TARGET then
                local _start, _end = sfind(szName, _L["BeiMing."])
                if _start then
                    bAdd = true
                end
            else
                bAdd = true
            end
        elseif IsMissionObj and LR_HeadName.UsrData.bShowQuestDoodad then
            bAdd = true
        end
        if LR_HeadName.DoodadTemplateSee[obj.dwTemplateID] then
            bAdd = true
        end
        if not bAdd and obj.nKind == DOODAD_KIND.QUEST and LR_HeadName.UsrData.bShowQuestDoodad then
            local MissionList = LR_HeadName.MissionList
            local dwMapID = LR_HeadName.dwMapID
            for ii = 1, #MissionList, 1 do
                if MissionList[ii].nType == "P" and MissionList[ii].dwMapID == dwMapID then
                    if MissionList[ii].p1 and MissionList[ii].p2 then
                        local dis = mfloor(((obj.nX - MissionList[ii].p1) ^ 2 + (obj.nY - MissionList[ii].p2) ^ 2) ^ 0.5) / 64
                        if dis <= 6.5 then
                            bAdd = true
                        end
                    end
                end
            end
        end
        if obj.dwTemplateID == _GuDing.dwTemplateID then
            bAdd = true
            if not _GuDing.tDoodadList[dwID] then
                _GuDing.tDoodadList[dwID] = { szName = "", nTime = LR_HeadName.DoodadList[dwID].nTime, nEndFrame = LR_HeadName.DoodadList[dwID].nFrame + 60 * 16 }
                local flag = true
                for k, v in pairs(_GuDing.tCastList) do
                    if mabs(_GuDing.tDoodadList[dwID].nTime - v.nTime) <= 1 and flag then
                        _GuDing.tDoodadList[dwID].szName = v.szName
                        _GuDing.tCastList[k] = nil
                        flag = false
                    end
                end

                LR.DelayCall(60000, function()
                    _GuDing.tDoodadList[dwID] = nil
                end)
            elseif _GuDing.tDoodadList[dwID].szName == "" then
                local flag = true
                for k, v in pairs(_GuDing.tCastList) do
                    if mabs(_GuDing.tDoodadList[dwID].nTime - v.nTime) <= 1 and flag then
                        _GuDing.tDoodadList[dwID].szName = v.szName
                        _GuDing.tCastList[k] = nil
                        flag = false
                    end
                end
            end
        end
        if bAdd then
            LR_HeadName.AllList[dwID] = LR_HeadName.DoodadList[dwID]
            if LR_HeadName.UsrData.bMiniMapAgriculture and LR_HeadName.CheckAgriculture(szName) and obj.nKind == DOODAD_KIND.CRAFT_TARGET then
                MINIMAP_LIST[dwID] = { nType = 6, obj = obj, nFrame1 = 2, nFrame2 = 48 }
            end
            if LR_HeadName.UsrData.bMiniMapMine and LR_HeadName.CheckMineral(szName) then
                MINIMAP_LIST[dwID] = { nType = 6, obj = obj, nFrame1 = 16, nFrame2 = 48 }
            end
            if LR_HeadName.UsrData.bShowQuestFlag and obj.nKind == DOODAD_KIND.CRAFT_TARGET then
                local _start, _end = sfind(szName, _L["BeiMing."])
                if _start then
                    MINIMAP_LIST[dwID] = { nType = 6, obj = obj, nFrame1 = 265, nFrame2 = 48 }
                end
            end
            if IsMissionObj and LR_HeadName.UsrData.bShowQuestFlag then
                MINIMAP_LIST[dwID] = { nType = 6, obj = obj, nFrame1 = 199, nFrame2 = 48 }
            end
            if obj.nKind == DOODAD_KIND.QUEST and LR_HeadName.UsrData.bShowQuestFlag then
                if obj.HaveQuest(me.dwID) then
                    MINIMAP_LIST[dwID] = { nType = 6, obj = obj, nFrame1 = 199, nFrame2 = 48 }
                end
            end
            if HasQuest then
                MINIMAP_LIST[dwID] = { nType = 6, obj = obj, nFrame1 = 199, nFrame2 = 48 }
            end
        end
    end
end

function LR_HeadName.IsMissionObj(t)
    if LR.Trim(t.szName) == "" then
        --return false
    end
    local me = GetClientPlayer()
    if not me then
        return false, 1
    end
    local scene = me.GetScene()
    local dwMapID = scene.dwMapID
    local MissionList = LR_HeadName.MissionList
    for i = 1, #MissionList, 1 do
        if MissionList[i].dwMapID == dwMapID then
            if MissionList[i].nType == "N" then
                if MissionList[i].dwTemplateID == t.dwTemplateID and t.nType == TARGET.NPC then
                    return true, 2
                end
            elseif MissionList[i].nType == "D" then
                if MissionList[i].dwTemplateID == t.dwTemplateID and t.nType == TARGET.DOODAD then
                    return true, 3
                elseif LR.Trim(MissionList[i].szName) == LR.Trim(t.szName) and t.nType == TARGET.DOODAD then
                    --???����ΪɶҪ������ƣ�����
                    --return true
                end
            elseif MissionList[i].nType == "P" then
                if t.nX and t.nY and MissionList[i].nX and MissionList[i].nY then
                    if (MissionList[i].nX - t.nX) * (MissionList[i].nX - t.nX) + (MissionList[i].nY - t.nY) * (MissionList[i].nY - t.nY) < 55 then
                        return true, 4
                    end
                end
            end
        end
    end

    if t.nType == TARGET.DOODAD then
        local doodad = GetDoodad(t.dwID)
        if doodad then
            if doodad.HaveQuest(me.dwID) then
                return true, 5
            end
        end
    end

    return false, 6
end

function LR_HeadName.CheckQuestAccept(obj)
    if not obj then
        return false
    end
    return NPC_CAN_ACCEPT_QUEST[obj.dwID] or false
end

function LR_HeadName.CheckQuestFinish(obj)
    if not obj then
        return false
    end
    return NPC_CAN_FINISH_QUEST[obj.dwID] or false
end

function LR_HeadName.QUEST_FINISHED()
    if not (LR_HeadName.bOn and LR_HeadName.UsrData.bShowQuestFlag) then
        return
    end
    if LR_HeadName.BookCopyQuests[arg0] then
        return
    end

    local dwQuestID = arg0
    local me = GetControlPlayer()
    if not me then
        return
    end

    LR_HeadName.RefreshAllNPCQuest(dwQuestID)
    LR_HeadName.MissionNeed[dwQuestID] = nil
    _QuestTraceInfo[dwQuestID] = nil
    _QuestInfo[dwQuestID] = nil

    LR_HeadName.Tree()
    LR_HeadName.RefreshTarget()
    LR_HeadName.ReDrawNpc()

    --[[	LR.DelayCall(150, function()
		----ˢ��NPC/Doodad�ϵ�������
		LR_HeadName.Tree()
		----��Doodad������ʾ�б�
		--LR_HeadName.AddAllDoodad2AllList()
		----ˢ�µ�ǰĿ��
		LR_HeadName.RefreshTarget()
		LR_HeadName.ReDrawNpc()
	end)]]
end

function LR_HeadName.QUEST_FAILED()
    local me = GetClientPlayer()
    if not me then
        return
    end
    local dwQuestID = me.GetQuestID(arg0)
    if LR_HeadName.BookCopyQuests[dwQuestID] then
        return
    end

    LR_HeadName.RefreshAllNPCQuest(dwQuestID)
    LR_HeadName.MissionNeed[dwQuestID] = nil
    _QuestTraceInfo[dwQuestID] = nil
    _QuestInfo[dwQuestID] = nil

    LR_HeadName.Tree()
    LR_HeadName.RefreshTarget()
    LR_HeadName.ReDrawNpc()
end

function LR_HeadName.QUEST_ACCEPTED()
    if not (LR_HeadName.bOn and LR_HeadName.UsrData.bShowQuestFlag) then
        return
    end
    if LR_HeadName.BookCopyQuests[arg1] then
        return
    end
    local dwQuestID = arg1
    local me = GetControlPlayer()
    if not me then
        return
    end

    LR_HeadName.RefreshAllNPCQuest(dwQuestID)
    LR_HeadName.GetSingleMissionNeed(dwQuestID)
    LR_HeadName.Tree()
    LR_HeadName.ReDrawNpc()
    LR_HeadName.AddAllDoodad2AllList()
end

function LR_HeadName.QUEST_CANCELED()
    if not (LR_HeadName.bOn and LR_HeadName.UsrData.bShowQuestFlag) then
        return
    end
    if LR_HeadName.BookCopyQuests[arg0] then
        return
    end
    local dwQuestID = arg0
    local me = GetControlPlayer()
    if not me then
        return
    end

    LR_HeadName.RefreshAllNPCQuest(dwQuestID)
    LR_HeadName.MissionNeed[dwQuestID] = nil
    _QuestTraceInfo[dwQuestID] = nil
    _QuestInfo[dwQuestID] = nil

    LR_HeadName.Tree()
    LR_HeadName.RefreshTarget()
    LR_HeadName.ReDrawNpc()

    LR.DelayCall(150, function()
        ----ˢ��NPC/Doodad�ϵ�������
        LR_HeadName.Tree()
        ----��Doodad������ʾ�б�
        LR_HeadName.AddAllDoodad2AllList()
        ----ˢ�µ�ǰĿ��
        LR_HeadName.RefreshTarget()
        LR_HeadName.ReDrawNpc()
    end)
end

function LR_HeadName.QUEST_DATA_UPDATE()
    if not (LR_HeadName.bOn and LR_HeadName.UsrData.bShowQuestFlag) then
        return
    end

    local nQuestIndex = arg0
    local eEventType = arg1
    local nValue1 = arg2
    local nValue2 = arg3

    local me = GetControlPlayer()
    if not me then
        return
    end
    local dwQuestID = me.GetQuestID(nQuestIndex)
    if LR_HeadName.BookCopyQuests[dwQuestID] then
        return
    end

    LR_HeadName.GetSingleMissionNeed(dwQuestID)
    LR_HeadName.RefreshAllNPCQuest()
    LR_HeadName.Tree()
    ----��Doodad������ʾ�б�
    LR_HeadName.AddAllDoodad2AllList()
    ----ˢ�µ�ǰĿ��
    --LR_HeadName.RefreshTarget()
    LR_HeadName.ReDrawNpc()
end

function LR_HeadName.RefreshTarget()
    local me = GetControlPlayer()
    if not me then
        return
    end
    local _type, _dwID = me.GetTarget()
    if _type == TARGET.NPC then
        LR_HeadName.Check(_dwID, _type, true)
    end
end

function LR_HeadName.LR_BUFF_TRAN()
    local nType = arg0
    local dwID = arg1
    local data = arg2
    if nType == "Add" then
        SCENE_DATA_CACHE[dwID] = SCENE_DATA_CACHE[dwID] or {}
        tinsert(SCENE_DATA_CACHE[dwID], 1, data)
    elseif nType == "Del" then
        SCENE_DATA_CACHE[dwID] = SCENE_DATA_CACHE[dwID] or {}
        for k, v in pairs(SCENE_DATA_CACHE[dwID]) do
            if v.nIndex == data.nIndex then
                tremove(SCENE_DATA_CACHE[dwID], k)
            end
        end
    end
end

LR.RegisterEvent("QUEST_FINISHED", function()
    LR_HeadName.QUEST_FINISHED()
end)
--LR.RegisterEvent("QUEST_FAILED", function() LR_HeadName.QUEST_FINISHED()  end)
LR.RegisterEvent("QUEST_FAILED", function()
    LR_HeadName.QUEST_FAILED()
end)
LR.RegisterEvent("QUEST_DATA_UPDATE", function()
    LR_HeadName.QUEST_DATA_UPDATE()
end)
LR.RegisterEvent("QUEST_CANCELED", function()
    LR_HeadName.QUEST_CANCELED()
end)
LR.RegisterEvent("QUEST_ACCEPTED", function()
    LR_HeadName.QUEST_ACCEPTED()
end)
------------------------------------------------------------------------------------------
function LR_HeadName.ClearPartyMark()
    local temp = clone(_tPartyMark)
    _tPartyMark = {}
    for dwID, v in pairs(temp) do
        if LR_HeadName._Role[dwID] then
            local _h = LR_HeadName._Role[dwID]:GetHandle()
            if _h then
                _h:SetTeamMark(nil):DrawName()
            end
        end
    end
end

function LR_HeadName.DrawPartyMark()
    local team = GetClientTeam()
    if team then
        local temp = team.GetTeamMark() or {}
        _tPartyMark = clone(temp)
        for dwID, v in pairs(temp) do
            if LR_HeadName._Role[dwID] then
                local _h = LR_HeadName._Role[dwID]:GetHandle()
                if _h then
                    _h:SetTeamMark(v):DrawName()
                end
            end
        end
        _tPartyMark = clone(temp)
    end
end

function LR_HeadName.PARTY_SET_MARK()
    if not LR_HeadName.UsrData.bShowTeamMark then
        return
    end
    local team = GetClientTeam()
    if team then
        LR_HeadName.ClearPartyMark()
        LR_HeadName.DrawPartyMark()
    end
end

function LR_HeadName.PARTY_DELETE_MEMBER()
    local dwTeamID = arg0
    local dwMemberID = arg1
    local szName = arg2
    local nGroupIndex = arg3

    local me = GetClientPlayer()
    if not me then
        return
    end
    if dwMemberID == me.dwID then
        LR_HeadName.ClearPartyMark()
    end
end

function LR_HeadName.PARTY_DISBAND()
    LR_HeadName.ClearPartyMark()
end

LR.RegisterEvent("PARTY_SET_MARK", function()
    LR_HeadName.PARTY_SET_MARK()
end)
LR.RegisterEvent("PARTY_DELETE_MEMBER", function()
    LR_HeadName.PARTY_DELETE_MEMBER()
end)
LR.RegisterEvent("PARTY_DISBAND", function()
    LR_HeadName.PARTY_DISBAND()
end)
------------------------------------------------------------------------------------------
function LR_HeadName.ResetSettings()
    LR_HeadName.Agriculture = clone(LR_HeadName.default.Agriculture)
    LR_HeadName.Mineral = clone(LR_HeadName.default.Mineral)
    LR_HeadName.UsrData = clone(LR_HeadName.default.UsrData)
    LR_HeadName.DoodadKind = clone(LR_HeadName.default.DoodadKind)
    LR_HeadName.bUseCommonData = LR_HeadName.default.bUseCommonData
    LR_HeadName.CustomDoodad = clone(LR_HeadName.default.CustomDoodad)
    LR_HeadName.HighLightColor = clone(LR_HeadName.DefaultHighLightColor)
    LR_HeadName.Color = clone(LR_HeadName.DefaultColor)
end

function LR_HeadName.ResetFontAndColor()
    LR_HeadName.HighLightColor = clone(LR_HeadName.DefaultHighLightColor)
    LR_HeadName.Color = clone(LR_HeadName.DefaultColor)
end

--�����������������patch
function LR_HeadName.LoadPatch()
    local path = sformat("%s\\Script\\LR_HeadNamePatch.dat", AddonPath)
    local data = LoadLUAData(path) or {}
    LR_HeadName.MissionPatch = clone(data)
end

--���������ȡ/���npc��patch
function LR_HeadName.LoadPatch2()
    local path = sformat("%s\\Script\\LR_HeadNamePatch2.dat", AddonPath)
    local data = LoadLUAData(path) or {}
    LR_HeadName.MissionPatch2 = clone(data)
end

function LR_HeadName.LoadPatch3()
    local path = sformat("%s\\Script\\LR_HeadNamePatch3.dat", AddonPath)
    local data = LoadLUAData(path) or {}
    LR_HeadName.NpcTemplateSee = clone(data)

    local path2 = sformat("%s\\Script\\LR_HeadNamePatch4.dat", AddonPath)
    local data2 = LoadLUAData(path2) or {}
    LR_HeadName.DoodadTemplateSee = clone(data2)
end

function LR_HeadName.LoadCommonSettings()
    LR_HeadName.CheckCommonSettings()
    local path = sformat("%s\\UsrData\\CommonSettings.dat", SaveDataPath)
    local CommonSetting = LoadLUAData(path) or {}

    LR_HeadName.Agriculture = clone(CommonSetting.Agriculture)
    LR_HeadName.Mineral = clone(CommonSetting.Mineral)
    LR_HeadName.UsrData = clone(CommonSetting.UsrData)
    LR_HeadName.DoodadKind = clone(CommonSetting.DoodadKind)
    LR_HeadName.CustomDoodad = clone(CommonSetting.CustomDoodad)
    LR_HeadName.HighLightColor = clone(CommonSetting.HighLightColor)
    LR_HeadName.Color = clone(CommonSetting.Color)
end

function LR_HeadName.SaveCommonSettings()
    local path = sformat("%s\\UsrData\\CommonSettings.dat", SaveDataPath)
    local CommonSetting = {}
    CommonSetting.Version = LR_HeadName.default.Version
    CommonSetting.Agriculture = clone(LR_HeadName.Agriculture)
    CommonSetting.Mineral = clone(LR_HeadName.Mineral)
    CommonSetting.UsrData = clone(LR_HeadName.UsrData)
    CommonSetting.DoodadKind = clone(LR_HeadName.DoodadKind)
    CommonSetting.CustomDoodad = clone(LR_HeadName.CustomDoodad)
    CommonSetting.HighLightColor = clone(LR_HeadName.HighLightColor)
    CommonSetting.Color = clone(LR_HeadName.Color)
    SaveLUAData(path, CommonSetting)
end

function LR_HeadName.CheckCommonSettings()
    local path = sformat("%s\\UsrData\\CommonSettings.dat", SaveDataPath)
    local CommonSetting = LoadLUAData(path) or {}
    if CommonSetting.Version and CommonSetting.Version == LR_HeadName.default.Version then
        return
    end
    CommonSetting = clone(LR_HeadName.default)
    CommonSetting.HighLightColor = clone(LR_HeadName.DefaultHighLightColor)
    CommonSetting.Color = clone(LR_HeadName.Color)
    SaveLUAData(path, CommonSetting)
end

-------------------------------------------------------------------
function LR_HeadName.GetDoodadQuest(dwTemplateID)
    --���doodad����û�����񣬺͹ٷ��Ĳ�ͬ���ٷ��������doodad�Ƿ����������������Ʒ�����������doodad��û�п��Խӵ�����
    local t = SCENE_QUEST_CACHE[sformat("D_%d", dwTemplateID)] or {}
    local t2 = LR.tAllUnknownAccept[sformat("D_%d", dwTemplateID)] or {}
    for k, v in pairs(t2) do
        tinsert(t, v)
    end
    return t
end

function LR_HeadName.CheckDoodadCanAcceptQuest(doodad)
    local me = GetClientPlayer()
    if not me then
        return false
    end
    local tQuest = LR_HeadName.GetDoodadQuest(doodad.dwTemplateID)
    for k, dwQuestID in pairs(tQuest) do
        if me.CanAcceptQuest(dwQuestID, TARGET.DOODAD, doodad.dwID) == 1 then
            return true
        end
    end
    return false
end

function LR_HeadName.CheckDoodadAllQuestFinished(doodad)
    local me = GetClientPlayer()
    if not me then
        return true
    end
    local tQuest = LR_HeadName.GetDoodadQuest(doodad.dwTemplateID)
    for k, dwQuestID in pairs(tQuest) do
        if not (me.CanAcceptQuest(dwQuestID, TARGET.DOODAD, doodad.dwID) == 8 or me.CanAcceptQuest(dwQuestID, TARGET.DOODAD, doodad.dwID) == 7) then
            return false
        end
    end
    return true
end

function LR_HeadName.CheckAgriculture(szName)
    if not szName then
        return false
    end
    if LR_HeadName.UsrData.bShowAgriculture then
        return LR_HeadName.Agriculture[szName] or false
    else
        return false
    end
end

function LR_HeadName.CheckMineral(szName)
    if not szName then
        return false
    end
    if LR_HeadName.UsrData.bShowMine then
        return LR_HeadName.Mineral[szName] or false
    else
        return false
    end
end

function LR_HeadName.LoadBookCopyQuests()
    local path = sformat("%s\\Script\\LR_BookCopyQuests.dat", AddonPath)
    local data = LoadLUAData(path) or {}
    LR_HeadName.BookCopyQuests = clone(data)
end

function LR_HeadName.LOGIN_GAME()
    ---��������
    LR_HeadName.LoadCommonSettings()
    LR_HeadName.LoadPatch()
    LR_HeadName.LoadPatch2()
    LR_HeadName.LoadPatch3()
    LR_HeadName.LoadBookCopyQuests()
    Log("LR_HeadName loaded data\n")
end

function LR_HeadName.LOADING_END()
    LR_HeadName.AllList[GetClientPlayer().dwID] = { dwID = GetClientPlayer().dwID, nType = TARGET.PLAYER, Quest_List = {}, }
    local me = GetClientPlayer()
    if not me then
        return
    end
    local scene = me.GetScene()
    LR_HeadName.dwMapID = scene.dwMapID
    SCENE_QUEST_CACHE = clone(LR.tAllSceneQuest[scene.dwMapID] or {})
    if not LR_HeadName.bOn then
        return
    end

    NPC_CAN_ACCEPT_QUEST = {}
    NPC_CAN_FINISH_QUEST = {}
    LR_HeadName.RefreshAllNPCQuest()
    LR_HeadName.GetAllMissionNeed()
    LR_HeadName.Tree()
    LR_HeadName.OpenFrame()
    LR.DelayCall(500, function()
        LR_HeadName.PARTY_SET_MARK()
    end)
    LR_HeadName.AddAllDoodad2AllList()
    LR_HeadName.ReDrawNpc()
end

function LR_HeadName.FIRST_LOADING_END()
    local me = GetControlPlayer()
    if not me then
        return
    end

    --����������ʾ/�ر����
    LR_HeadName.GetSysHeadSettings()
    LR_HeadName.OpenFrame()

    FIRST_LOADING_END = true
    -----�������
    if not (LR_HeadName.bOn and LR_HeadName.UsrData.bShowQuestFlag) then
        return
    end

    LR_HeadName.AddAllDoodad2AllList()
    LR_HeadName.ReDrawAll()
end

function LR_HeadName.CUSTOM_DATA_LOADED()

end

function LR_HeadName.DO_SKILL_CAST()
    local dwCasterID = arg0
    local dwSkillID = arg1
    local dwSkillLevel = arg2
    local me = GetClientPlayer()
    if not me then
        return
    end
    if dwSkillID == _GuDing.dwSkillID and dwCasterID == me.dwID then
        _GuDing.tCastList[dwCasterID] = { szName = me.szName, nTime = GetCurrentTime() }
        if me.IsInParty() or me.IsInRaid() then
            local msg = { dwCasterID = dwCasterID, szName = me.szName, nTime = GetCurrentTime() }
            LR.BgTalk(PLAYER_TALK_CHANNEL.RAID, "LR_HeadName_GuDing", "Send", msg)
        end
    end
end

function LR_HeadName.ON_BG_CHANNEL_MSG()
    local szKey = arg0
    local nChannel = arg1
    local dwTalkerID = arg2
    local szTalkerName = arg3
    local data = arg4
    if szKey ~= "LR_HeadName_GuDing" then
        return
    end
    local me = GetClientPlayer()
    if not me then
        return
    end

    if data[1] == "Send" then
        local dwCasterID = data[2].dwCasterID
        local szName = data[2].szName
        local nTime = data[2].nTime
        _GuDing.tCastList[dwCasterID] = { szName = szName, nTime = nTime }
    end
end

function LR_HeadName.MiniMapBreatheCall()
    if not LR_HeadName.bOn then
        return
    end
    for k, v in pairs(MINIMAP_LIST) do
        LR.UpdateMiniFlag(v.nType, v.obj, v.nFrame1, v.nFrame2)
    end

end

LR.BreatheCall("LR_HEAD_NAME_MINIMAP", function()
    LR_HeadName.MiniMapBreatheCall()
end, 500)
LR.RegisterEvent("LOGIN_GAME", function()
    LR_HeadName.LOGIN_GAME()
end)
LR.RegisterEvent("LOADING_END", function()
    LR_HeadName.LOADING_END()
end)
LR.RegisterEvent("FIRST_LOADING_END", function()
    LR_HeadName.FIRST_LOADING_END()
end)
LR.RegisterEvent("CUSTOM_DATA_LOADED", function()
    LR_HeadName.CUSTOM_DATA_LOADED()
end)
LR.RegisterEvent("DO_SKILL_CAST", function()
    LR_HeadName.DO_SKILL_CAST()
end)
LR.RegisterEvent("ON_BG_CHANNEL_MSG", function()
    LR_HeadName.ON_BG_CHANNEL_MSG()
end)

function LR_HeadName.ON_READ_BOOK()
    for k, v in pairs(_BeiMing) do
        LR_HeadName.Check(k, TARGET.DOODAD, true)
    end
end
LR.RegisterEvent("ON_READ_BOOK", function()
    LR_HeadName.ON_READ_BOOK()
end)

function LR_HeadName.OneKeyShieldNpc()
    LR_HeadName.UsrData.NPC.bShow = not LR_HeadName.UsrData.NPC.bShow
    LR_HeadName.ReDrawAll()
end

function LR_HeadName.OneKeyShieldPlayer()
    LR_HeadName.UsrData.Player.bShow = not LR_HeadName.UsrData.Player.bShow
    LR_HeadName.ReDrawAll()
end

function LR_HeadName.GetUIScale()
    local Handle_Scale = this:Lookup("", ""):Lookup("Handle_Scale")
    local Handle_Fixed = this:Lookup("", ""):Lookup("Handle_Fixed")
    local w1, h1 = Handle_Scale:GetSize()
    local w2, h2 = Handle_Fixed:GetSize()
    LR_HeadName.UIScale = w2 / w1
end

Wnd.OpenWindow(sformat("%s\\UI\\LR_HeadNameNone.ini", AddonPath), "LR_HeadName"):Hide()
