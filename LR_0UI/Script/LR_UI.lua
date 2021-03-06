local _class = {}

local function class(super)
	local class_type = {}
	class_type.ctor = false
	class_type.super = super
	class_type.new = function(...)
		local obj = {}
		setmetatable(obj, { __index = _class[class_type]})
		do
			local create
			create = function(c, ...)
				if c.super then
					create(c.super, ...)
				end
				if c.ctor then
					c.ctor(obj, ...)
				end
			end
			create(class_type, ...)
		end
		return obj
	end
	local vtbl = {}
	_class[class_type] = vtbl

	setmetatable(class_type,{__newindex =
		function(t, k, v)
			vtbl[k] = v
		end
	})

	if super then
		setmetatable(vtbl,{__index =
			function(t, k)
				local ret = _class[super][k]
				vtbl[k] = ret
				return ret
			end
		})
	end

	return class_type
end

local __ini = "Interface/LR_Plugin/LR_0UI/ini/%s.ini"
local NAME_INDEX = 1
----------------------------------------------
-- Wnd Type Controls
----------------------------------------------

-- Append Control
local _AppendWnd = function(__parent, __type, __name)
	if not __name then
		__name = string.format("EASYUI_INDEX_%d", NAME_INDEX)
		NAME_INDEX = NAME_INDEX + 1
	end
	if __parent.__addon then
		__parent = __parent:GetSelf()
	end
	local hwnd = Wnd.OpenWindow(string.format(__ini, __type), __name):Lookup(__type)
	hwnd:ChangeRelation(__parent, true, true)
	hwnd:SetName(__name)
	Wnd.CloseWindow(__name)
	return hwnd
end

-- Base Class of WndType Control
local WndBase = class()
function WndBase:ctor(__this)
	self.__addon = true
	self.__listeners = {self}
end

function WndBase:GetName()
	return self.__this:GetName()
end

function WndBase:_SetSelf(__this)
	self.__this = __this
end

function WndBase:GetSelf()
	return self.__this
end

function WndBase:SetSize(...)
	self.__this:SetSize(...)
	return self
end

function WndBase:GetSize()
	return self.__this:GetSize()
end

function WndBase:SetRelPos(...)
	self.__this:SetRelPos(...)
	return self
end

function WndBase:GetRelPos()
	return self.__this:GetRelPos()
end

function WndBase:SetAbsPos(...)
	self.__this:SetAbsPos(...)
	return self
end

function WndBase:GetAbsPos()
	return self.__this:GetAbsPos()
end

function WndBase:Enable(...)
	self.__this:Enable(...)
	return self
end

function WndBase:_SetParent(__parent)
	self.__parent = __parent
end

function WndBase:GetParent()
	return self.__parent
end

function WndBase:HasParent(__name)
	if self:GetType() == "WndFrame" then
		return false
	else
		local Parent=self:GetParent()
		if Parent:GetName() == __name then
			return true
		else
			if Parent:GetType() == "WndFrame" then
				return false
			else
				return Parent:HasParent(__name)
			end
		end
	end
end

function WndBase:_SetType(__type)
	self.__type = __type
end

function WndBase:GetType()
	return self.__type
end

function WndBase:Hover(fnEnter, fnLeave)
	local wnd = self.self
	if self.type == "WndComboBox" then
		wnd = wnd:Lookup("Btn_ComboBox")
	elseif self.type == "WndCheckBox" then
		wnd = self.__CheckBox
	end
	if wnd then
		fnLeave = fnLeave or fnEnter
		if fnEnter then
			wnd.OnMouseEnter = function() fnEnter(true) end
		end
		if fnLeave then
			wnd.OnMouseLeave = function() fnLeave(false) end
		end
	end
	return self
end

function WndBase:Destroy()
	local __name = self:GetName()
	if self:GetType() == "WndFrame" then
		Wnd.CloseWindow(__name)
	else
		self.__this:Destroy()
	end
end

function WndBase:Show()
	self.__this:Show()
	return self
end

function WndBase:Hide()
	self.__this:Hide()
	return self
end

function WndBase:IsVisible()
	return self.__this:IsVisible()
end

function WndBase:ToggleVisible()
	self.__this:ToggleVisible()
end

function WndBase:Scale(...)
	self.__this:Scale(...)
	return self
end

function WndBase:CorrectPos(...)
	self.__this:CorrectPos(...)
	return self
end

function WndBase:SetMousePenetrable(...)
	self.__this:SetMousePenetrable(...)
	return self
end

function WndBase:SetAlpha(...)
	self.__this:SetAlpha(...)
	return self
end

function WndBase:GetAlpha()
	return self.__this:GetAlpha()
end

function WndBase:ChangeRelation(__parent, ...)
	if __parent.__addon then
		__parent = __parent:GetSelf()
	end
	self.__this:ChangeRelation(__parent, ...)
	return self
end

function WndBase:SetPoint(...)
	self.__this:SetPoint(...)
	return self
end

function WndBase:_FireEvent(__event, ...)
	for __k, __v in pairs(self.__listeners) do
		if __v[__event] then
			local res, err = pcall(__v[__event], ...)
			if not res then
				LR.SysMsg( "ERROR:" .. err .."\n")
			end
		end
	end
end

-- WndFrame Obejct
local WndFrame = class(WndBase)
function WndFrame:ctor(__name, __data)
	assert(__name ~= nil, "frame name can not be null.")
	__data = __data or {}
	local frame = nil
	if __data.style then
		if __data.style == "THIN" then
			frame = Wnd.OpenWindow(string.format(__ini, "WndFrameThin"), __name)
		elseif __data.style == "SMALL" then
			frame = Wnd.OpenWindow(string.format(__ini, "WndFrameSmall"), __name)
		elseif __data.style == "NORMAL" then
			frame = Wnd.OpenWindow(string.format(__ini, "WndFrame"), __name)
		elseif __data.style == "LARGER" then
			frame = Wnd.OpenWindow(string.format(__ini, "WndFrameLarger"), __name)
		elseif __data.style == "LARGER2" then
			frame = Wnd.OpenWindow(string.format(__ini, "WndFrameLarger2"), __name)
		elseif __data.style == "NONE" then
			frame = Wnd.OpenWindow(string.format(__ini, "WndFrameNone"), __name)
		elseif __data.style == "NONE2" then
			frame = Wnd.OpenWindow(string.format(__ini, "WndFrameNone2"), __name)
		elseif __data.style == "DialogPanel" then
			frame = Wnd.OpenWindow(string.format(__ini, "WndFrameDialogPanel"), __name)
		end
	else
		frame = Wnd.OpenWindow(__data.path , __name)
	end
	PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	--frame:SetAlpha(0)
	frame:SetName(__name)
	--self:Register(__name)
	self.__this = frame
	self:_SetSelf(self.__this)
	self:_SetType("WndFrame")
	if __data.style and __data.style ~= "NONE" and __data.style ~= "NONE2" or __data.path then
		if frame:Lookup("Btn_Close") then
			frame:Lookup("Btn_Close").OnLButtonClick = function()
				self:Destroy()
				PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
			end
		end
		if __data.title then
			self:SetTitle(__data.title or "")
		end
	end

--[[	self.__disableEffect = __data.disableEffect or false
	self.__w, self.__h = frame:GetSize()
	if not LR_TOOLS.DisableEffect and not self.__disableEffect then
		frame:Hide()
		self._startScale=0.8
		self._scale=self._startScale
		self._startTime=GetTime()
		self._endTime=self._startTime+200
		LR.DelayCall(2,function()
			self:Scale(self._scale,self._scale)
			self:Show()
			self:FadeIn(6)
			LR.DelayCall(2, function() self:ccc() end)
		end)
	else
		self:SetAlpha(255)
		LR.DelayCall(20,function() self:_FireEvent("ScaleEnd") end)
	end]]
end

function WndFrame:ccc()
	local scale=self._scale
	if scale<1 then
		local _leftTime=self._endTime - GetTime()
		local scale=self._startScale + (1-self._startScale)*( GetTime() - self._startTime)/(self._endTime - self._startTime)
		self:Scale(scale/self._scale,scale/self._scale)
		self._scale=scale
		LR.DelayCall(2, function() self:ccc() end)
	else
		self.__this:SetSize(self.__w, self.__h)
		self:_FireEvent("ScaleEnd")
		--self:Scale(1,1)
	end
end

function WndFrame:GetdisableEffect()
	return self.__disableEffect
end

function WndFrame:Lookup(...)
	return self.__this:Lookup(...)
end

function WndFrame:GetHandle()
	return self.__this:Lookup("", "")
end

function WndFrame:ClearHandle()
	self.__this:Lookup("", ""):Clear()
	return self
end

function WndFrame:SetTitle(...)
	self.__this:Lookup("", "Text_Title"):SetText(...)
	return self
end

function WndFrame:GetTitle()
	return self.__this:Lookup("", "Text_Title"):GetText()
end

function WndFrame:EnableDrag(...)
	self.__this:EnableDrag(...)
	return self
end

function WndFrame:IsDragable()
	return self.__this:IsDragable()
end

function WndFrame:SetDragArea(...)
	self.__this:SetDragArea(...)
	return self
end

function WndFrame:RegisterEvent(...)
	self.__this:RegisterEvent(...)
	return self
end

function WndFrame:FadeIn(...)
	self.__this:FadeIn(...)
	return self
end

function WndFrame:FadeOut(...)
	self.__this:FadeOut(...)
	return self
end

function WndFrame:IsAddOn()
	return self.__this:IsAddOn()
end

-- WndWindow Object
local WndWindow = class(WndBase)
function WndWindow:ctor(__parent, __name, __data)
	assert(__parent ~= nil, "parent can not be null.")
	__data = __data or {}
	local hwnd = _AppendWnd(__parent, "WndWindow", __name)
	self.__this = hwnd
	self:_SetSelf(self.__this)
	self:_SetParent(__parent)
	self:_SetType("WndWindow")
	self:SetSize(__data.w or 100, __data.h or 100)
	self:SetRelPos(__data.x or 0, __data.y or 0)
	self.data = {parent = __parent, name = __name, data = __data}
end

--[[function WndWindow:Lookup(...)
	return self.__this:Lookup(...)
end]]

function WndWindow:SetSize(...)
	self.__this:SetSize(...)
	self.__this:Lookup("", ""):SetSize(...)
	return self
end

function WndWindow:GetHandle()
	return self.__this:Lookup("", "")
end

function WndWindow:ClearHandle()
	self.__this:Destroy()
	local hwnd = _AppendWnd(self.data.parent, "WndWindow", self.data.name)
	self.__this = hwnd
	self:_SetSelf(self.__this)
	self:_SetParent(self.data.parent)
	self:_SetType("WndWindow")
	self:SetSize(self.data.data.w or 100, self.data.data.h or 100)
	self:SetRelPos(self.data.data.x or 0, self.data.data.y or 0)
	--self.__this:Lookup("", ""):Clear()
	return self
end

-- WndPageSet Object
local WndPageSet = class(WndBase)
function WndPageSet:ctor(__parent, __name, __data)
	assert(__parent ~= nil, "parent can not be null.")
	__data = __data or {}
	local hwnd = _AppendWnd(__parent, "WndPageSet", __name)
	self.__this = hwnd
	self:_SetSelf(self.__this)
	self:_SetParent(__parent)
	self:_SetType("WndPageSet")
	self:SetSize(__data.w or 100, __data.h or 100)
	self:SetRelPos(__data.x or 0, __data.y or 0)
end

function WndPageSet:AddPage(...)
	self.__this:AddPage(...)
	return self
end

function WndPageSet:GetActivePage()
	return self.__this:GetActivePage()
end

function WndPageSet:GetActiveCheckBox()
	return self.__this:GetActiveCheckBox()
end

function WndPageSet:ActivePage(...)
	self.__this:ActivePage(...)
	return self
end

function WndPageSet:GetActivePageIndex()
	return self.__this:GetActivePageIndex()
end

function WndPageSet:GetLastActivePageIndex()
	return self.__this:GetLastActivePageIndex()
end

-- WndButton Object
local WndButton = class(WndBase)
function WndButton:ctor(__parent, __name, __data)
	assert(__parent ~= nil, "parent can not be null.")
	__data = __data or {}
	local hwnd = _AppendWnd(__parent, "WndButton", __name)
	self.__text = hwnd:Lookup("", "Text_Default")
	self:SetText(__data.text or "")
	self.__this = hwnd
	self:_SetSelf(self.__this)
	self:_SetParent(__parent)
	self:_SetType("WndButton")
	self:Enable((__data.enable == nil or __data.enable) and true or false)
	self:SetSize(__data.w or 91, __data.h)
	self:SetRelPos(__data.x or 0, __data.y or 0)

	--Bind Button Events
	self.__this.OnLButtonClick = function()
		self:_FireEvent("OnClick")
	end
	self.__this.OnMouseEnter = function()
		self:_FireEvent("OnEnter")
	end
	self.__this.OnMouseLeave = function()
		self:_FireEvent("OnLeave")
	end
end

function WndButton:Enable(__enable)
	if __enable then
		self.__this:Enable(true)
		self.__text:SetFontColor(255, 255, 255)
	else
		self.__text:SetFontColor(180, 180, 180)
		self.__this:Enable(false)
	end
	return self
end

function WndButton:SetText(...)
	self.__text:SetText(...)
	return self
end

function WndButton:GetText()
	return self.__text:GetText()
end

function WndButton:SetFontScheme(...)
	self.__text:SetFontScheme(...)
	return self
end

function WndButton:IsEnabled()
	return self.__this:IsEnabled()
end

function WndButton:SetSize(__w, __h)
	self.__this:SetSize(__w, __h or 26)
	self.__this:Lookup("", ""):SetSize(__w, __h or 26)
	self.__text:SetSize(__w, __h or 26)
	return self
end

-- WndUIButton Object
local WndUIButton = class(WndBase)
function WndUIButton:ctor(__parent, __name, __data)
	assert(__parent ~= nil, "parent can not be null.")
	__data = __data or {}
	local hwnd = _AppendWnd(__parent, "WndUIButton", __name)
	self.__image = hwnd:Lookup("", "Image_Default")
	self.__text = hwnd:Lookup("", "Text_Default")
	self.__text:SetText(__data.text or "")
	self.__this = hwnd
	self:_SetSelf(self.__this)
	self:_SetParent(__parent)
	self:_SetType("WndUIButton")
	self.__animate = __data.ani
	self:SetSize(__data.w or 40, __data.h or 40)
	self:Enable((__data.enable == nil or __data.enable) and true or false)
	self:SetRelPos(__data.x or 0, __data.y or 0)
	self:_UpdateNormal()

	--Bind Button Events
	self.__this.OnMouseEnter = function()
		if self:IsEnabled() then
			self:_UpdateOver()
		end
		self:_FireEvent("OnEnter")
	end
	self.__this.OnMouseLeave = function()
		if self:IsEnabled() then
			self:_UpdateNormal()
		end
		self:_FireEvent("OnLeave")
	end
	self.__this.OnLButtonClick = function()
		self:_FireEvent("OnClick")
	end
	self.__this.OnLButtonDown = function()
		if self:IsEnabled() then
			self:_UpdateDown()
		end
	end
	self.__this.OnLButtonUp = function()
		if self:IsEnabled() then
			self:_UpdateOver()
		end
	end
	self.__this.OnRButtonDown = function()
		if self:IsEnabled() then
			self:_UpdateDown()
		end
	end
	self.__this.OnRButtonUp = function()
		if self:IsEnabled() then
			self:_UpdateOver()
		end
	end
	self.__this.OnRButtonClick = function()
		self:_FireEvent("OnRClick")
	end
end

function WndUIButton:SetFontColor(...)
	self.__text:SetFontColor(...)
	return self
end

function WndUIButton:Enable(__enable)
	if __enable then
		self.__text:SetFontColor(255, 255, 255)
		self.__this:Enable(true)
		self:_UpdateNormal()
	else
		self.__text:SetFontColor(180, 180, 180)
		self.__this:Enable(false)
		self:_UpdateDisable()
	end
	return self
end

function WndUIButton:_UpdateNormal()
	self.__image:FromUITex(self.__animate[1], self.__animate[2])
end

function WndUIButton:_UpdateOver()
	self.__image:FromUITex(self.__animate[1], self.__animate[3])
end

function WndUIButton:_UpdateDown()
	self.__image:FromUITex(self.__animate[1], self.__animate[4])
end

function WndUIButton:_UpdateDisable()
	self.__image:FromUITex(self.__animate[1], self.__animate[5])
end

function WndUIButton:IsEnabled()
	return self.__this:IsEnabled()
end

function WndUIButton:SetText(...)
	self.__text:SetText(...)
	return self
end

function WndUIButton:GetText()
	return self.__text:GetText()
end

function WndUIButton:SetSize(__w, __h)
	self.__this:SetSize(__w, __h)
	self.__this:Lookup("", ""):SetSize(__w, __h)
	self.__image:SetSize(__w, __h)
	self.__text:SetSize(__w, __h)
	return self
end

-- WndEdit Object
local WndEdit = class(WndBase)
function WndEdit:ctor(__parent, __name, __data)
	assert(__parent ~= nil, "parent can not be null.")
	__data = __data or {}
	local hwnd = _AppendWnd(__parent, "WndEdit", __name)
	self.__edit = hwnd:Lookup("Edit_Default")
	self:SetText(__data.text or "")
	self.__this = hwnd
	self:_SetSelf(self.__this)
	self:_SetParent(__parent)
	self:_SetType("WndEdit")
	self:SetLimit(__data.limit or 36)
	self:SetMultiLine(__data.multi or false)
	self:Enable((__data.enable == nil or __data.enable) and true or false)
	self:SetSize(__data.w or 187, __data.h or 25)
	self:SetRelPos(__data.x or 0, __data.y or 0)

	--Bind Edit Events
	self.__edit.OnEditChanged = function()
		local __text = self.__edit:GetText()
		self:_FireEvent("OnChange", __text)
	end
	self.__edit.OnSetFocus = function()
		self:_FireEvent("OnSetFocus")
	end
	self.__edit.OnKillFocus = function()
		self:_FireEvent("OnKillFocus")
	end
	self.__edit.OnMouseEnter = function()
		self:_FireEvent("OnMouseEnter")
	end
	self.__edit.OnMouseLeave = function()
		self:_FireEvent("OnMouseLeave")
	end
end

function WndEdit:GetTextLength(...)
	return self.__edit:GetTextLength(...)
end

function WndEdit:SetLimitMultiByte(...)
	self.__edit:SetLimitMultiByte(...)
	return self
end

function WndEdit:SetSize(__w, __h)
	self.__this:SetSize(__w + 4, __h)
	self.__this:Lookup("", ""):SetSize(__w + 4, __h)
	self.__this:Lookup("", "Image_Default"):SetSize(__w + 4, __h)
	self.__edit:SetSize(__w, __h)
	return self
end

function WndEdit:SetLimit(...)
	self.__edit:SetLimit(...)
	return self
end

function WndEdit:SetMultiLine(...)
	self.__edit:SetMultiLine(...)
	return self
end

function WndEdit:Enable(__enable)
	if __enable then
		self.__edit:SetFontColor(255, 255, 255)
		self.__edit:Enable(true)
	else
		self.__edit:SetFontColor(180, 180, 180)
		self.__edit:Enable(false)
	end
	return self
end

function WndEdit:SelectAll()
	self.__this:SelectAll()
	return self
end

function WndEdit:SetText(...)
	self.__edit:SetText(...)
	return self
end

function WndEdit:GetText()
	return self.__edit:GetText()
end

function WndEdit:ClearText()
	self.__edit:ClearText()
	return self
end

function WndEdit:SetType(...)
	self.__edit:SetType(...)
	return self
end

function WndEdit:SetFontScheme(...)
	self.__edit:SetFontScheme(...)
	return self
end

function WndEdit:SetFontColor(...)
	self.__edit:SetFontColor(...)
	return self
end

function WndEdit:SetSelectFontScheme(...)
	self.__edit:SetSelectFontScheme(...)
	return self
end

function WndEdit:InsertObj(...)
	self.__edit:InsertObj(...)
	return self
end

-- WndCheckBox Object
local WndCheckBox = class(WndBase)
function WndCheckBox:ctor(__parent, __name, __data)
	assert(__parent ~= nil, "parent can not be null.")
	__data = __data or {}
	local hwnd = _AppendWnd(__parent, "WndCheckBox", __name)
	self.__text = hwnd:Lookup("", "Text_Default")
	self.__this = hwnd
	self.__CheckBox=hwnd--:Lookup("WndCheckBox1")
	self.__h = hwnd:Lookup("", "")
	self:_SetSelf(self.__this)
	self:_SetParent(__parent)
	self:_SetType("WndCheckBox")
	self:Check(__data.check or false)
	self:Enable((__data.enable == nil or __data.enable) and true or false)
	self.__text:SetText(__data.text or "")
	--local _w=math.max((__data.w or 150),self.__text:GetTextExtent())
	self:SetSize(self.__text:GetTextExtent())
	self:SetRelPos(__data.x or 0, __data.y or 0)

	--Bind CheckBox Events
	self.__CheckBox.OnCheckBoxCheck = function()
		self:_FireEvent("OnCheck", true)
	end
	self.__CheckBox.OnCheckBoxUncheck = function()
		self:_FireEvent("OnCheck", false)
	end
	self.__CheckBox.OnMouseEnter = function()
		self:_FireEvent("OnEnter", true)
	end
	self.__CheckBox.OnMouseLeave = function()
		self:_FireEvent("OnLeave", true)
	end
	self.__text:SetVAlign(0)
end

function WndCheckBox:SetSize(__w)
	--self.__this:SetSize (__w+28 , 30)
	local _, h = self.__text:GetSize()
	local w = self.__text:GetTextExtent()
	self.__text:SetSize(w, h)
	self.__h:SetSize(w + 30, h)
	self.__h:FormatAllItemPos()
	return self
end

function WndCheckBox:Check(...)
	self.__CheckBox:Check(...)
	return self
end

function WndCheckBox:Enable(__enable)
	if __enable then
		self.__text:SetFontColor(255, 255, 255)
		self.__CheckBox:Enable(true)
	else
		self.__text:SetFontColor(180, 180, 180)
		self.__CheckBox:Enable(false)
	end
	return self
end

function WndCheckBox:IsChecked()
	return self.__CheckBox:IsCheckBoxChecked()
end

function WndCheckBox:SetText(...)
	self.__text:SetText(...)
	return self
end

function WndCheckBox:GetText()
	return self.__text:GetText()
end

function WndCheckBox:SetFontColor(...)
	self.__text:SetFontColor(...)
	return self
end

function WndCheckBox:GetFontColor()
	return self.__text:GetFontColor()
end

function WndCheckBox:SetFontScheme(...)
	self.__text:SetFontScheme(...)
	return self
end

function WndCheckBox:GetFontScheme()
	return self.__text:GetFontScheme()
end

-- WndComboBox Object
local WndComboBox = class(WndBase)
function WndComboBox:ctor(__parent, __name, __data)
	assert(__parent ~= nil, "parent can not be null.")
	__data = __data or {}
	local hwnd = _AppendWnd(__parent, "WndComboBox", __name)
	self.__text = hwnd:Lookup("", "Text_Default")
	self.__text:SetText(__data.text or "")
	self.__this = hwnd
	self:_SetSelf(self.__this)
	self:_SetParent(__parent)
	self:_SetType("WndComboBox")
	self:Enable((__data.enable == nil or __data.enable) and true or false)
	self:SetSize(__data.w or 185)
	self:SetRelPos(__data.x or 0, __data.y or 0)

	--Bind ComboBox Events
	self.__this:Lookup("Btn_ComboBox").OnLButtonClick = function()
		local __x, __y = self:GetAbsPos()
		local __w, __h = self:GetSize()
		local __menu = {}
		__menu.nMiniWidth = __w
		__menu.x = __x
		__menu.y = __y + __h
		self:_FireEvent("OnClick", __menu)
	end

	self.__this:Lookup("Btn_ComboBox").OnMouseEnter = function()
		self:_FireEvent("OnEnter")
	end

	self.__this:Lookup("Btn_ComboBox").OnMouseLeave = function()
		self:_FireEvent("OnLeave")
	end
end

function WndComboBox:Enable(__enable)
	if __enable then
		self.__text:SetFontColor(255, 255, 255)
		self.__this:Lookup("Btn_ComboBox"):Enable(true)
	else
		self.__text:SetFontColor(180, 180, 180)
		self.__this:Lookup("Btn_ComboBox"):Enable(false)
	end
	return self
end

function WndComboBox:SetSize(__w)
	self.__this:SetSize(__w, 25)
	local handle = self.__this:Lookup("", "")
	local btn = self.__this:Lookup("Btn_ComboBox")
	local hnd = btn:Lookup("", "")
	btn:SetRelPos(__w - 25, 3)
	hnd:SetAbsPos(self.__this:GetAbsPos())
	hnd:SetSize(__w, 25)
	hnd:SetAbsPos(self.__this:GetAbsPos())
	handle:SetSize(__w, 25)
	handle:Lookup("Image_ComboBoxBg"):SetSize(__w,25)
	handle:Lookup("Text_Default"):SetSize(__w - 20, 25)
	return self
end

function WndComboBox:SetRichText(...)
	self.__text:SetRichText(...)
	return self
end

function WndComboBox:SetText(...)
	self.__text:SetText(...)
	return self
end

function WndComboBox:GetText()
	return self.__text:GetText()
end

function WndComboBox:SprintfText(...)
	return self.__text:SprintfText(...)
end

function WndComboBox:SetFontColor(...)
	return self.__text:SetFontColor(...)
end


-- WndRadioBox Object
local WndRadioBox = class(WndBase)
local __RadioBoxGroups = {}
function WndRadioBox:ctor(__parent, __name, __data)
	assert(__parent ~= nil, "parent can not be null.")
	__data = __data or {}
	local hwnd = _AppendWnd(__parent, "WndRadioBox", __name)
	self.__text = hwnd:Lookup("", "Text_Default")
	self.__text:SetText(__data.text or "")
	self.__this = hwnd
	self.__h=hwnd:Lookup("","")
	self:_SetSelf(self.__this)
	self:_SetParent(__parent)
	self:_SetType("WndRadioBox")
	self:Check(__data.check or false)
	self:Enable((__data.enable == nil or __data.enable) and true or false)
	self:SetSize(__data.w or 150)
	self:SetRelPos(__data.x or 0, __data.y or 0)
	self:SetSize(self.__text:GetTextExtent())
	self.__this.__group = __data.group
	self:SetGroup(__data.group)

	--Bind RadioBox Events
	self.__this.OnCheckBoxCheck = function()
		if self.__group then
			for k, v in pairs(__RadioBoxGroups[self.__group]) do
				if v:GetGroup() == this.__group and v:GetName() ~= this:GetName() then
					v:Check(false)
				end
			end
			self:_FireEvent("OnCheck", true)
		end
	end

	self.__this.OnCheckBoxUncheck = function()
		if self.__group then
			self:_FireEvent("OnCheck", false)
		end
	end
end

function WndRadioBox:SetSize(__w)
	self.__h:SetSize(__w + 28 , 25)
	self.__text:SetSize(__w , 25)
	self.__h:FormatAllItemPos()
	return self
end

function WndRadioBox:SetGroup(__group)
	if __group then
		if not __RadioBoxGroups[__group] then
			__RadioBoxGroups[__group] = {}
		end
		table.insert(__RadioBoxGroups[__group], self)
	end
	self.__group = __group
	return self
end

function WndRadioBox:GetGroup()
	return self.__group
end

function WndRadioBox:IsChecked()
	return self.__this:IsCheckBoxChecked()
end

function WndRadioBox:Check(...)
	self.__this:Check(...)
	return self
end

function WndRadioBox:Enable(__enable)
	if __enable then
		self.__text:SetFontColor(255, 255, 255)
		self.__this:Enable(true)
	else
		self.__text:SetFontColor(180, 180, 180)
		self.__this:Enable(false)
	end
	return self
end

function WndRadioBox:SetText(...)
	self.__text:SetText(...)
	return self
end

function WndRadioBox:GetText()
	return self.__text:GetText()
end

function WndRadioBox:SprintfText(...)
	self.__text:SprintfText(...)
	return self
end

function WndRadioBox:SetFontColor(...)
	self.__text:SetFontColor(...)
	return self
end

function WndRadioBox:GetFontColor()
	return self.__text:GetFontColor()
end

function WndRadioBox:SetFontScheme(...)
	self.__text:SetFontScheme(...)
	return self
end

function WndRadioBox:GetFontScheme()
	return self.__text:GetFontScheme()
end

-- WndUICheckBox Object
local WndUICheckBox = class(WndBase)
local __UICheckBoxGroups = {}
function WndUICheckBox:ctor(__parent, __name, __data)
	assert(__parent ~= nil, "parent can not be null.")
	__data = __data or {}
	local hwnd = _AppendWnd(__parent, "WndUICheckBox", __name)
	self.__text = hwnd:Lookup("", "Text_Default")
	self:SetText(__data.text or "")
	self.__this = hwnd
	self:_SetSelf(self.__this)
	self:_SetParent(__parent)
	self:_SetType("WndUICheckBox")
	self:Check(__data.check or false)
	self:SetSize(__data.w or 83, __data.h or 30)
	self:SetRelPos(__data.x or 0, __data.y or 0)

	self.__this.__group = __data.group
	self:SetGroup(__data.group)

	--Bind UICheckBox Events
	self.__this.OnCheckBoxCheck = function()
		if self.__group then
			for k, v in pairs(__UICheckBoxGroups[self.__group]) do
				if v:GetGroup() == this.__group and v:GetName() ~= this:GetName() then
					v:Check(false)
				end
			end
		end
		self:_FireEvent("OnCheck", true)
	end
end

function WndUICheckBox:SetGroup(__group)
	if __group then
		if not __UICheckBoxGroups[__group] then
			__UICheckBoxGroups[__group] = {}
		end
		table.insert(__UICheckBoxGroups[__group], self)
	end
	self.__group = __group
	return self
end

function WndUICheckBox:GetGroup()
	return self.__group
end

function WndUICheckBox:Check(...)
	self.__this:Check(...)
	return self
end

function WndUICheckBox:SetText(...)
	self.__text:SetText(...)
	return self
end

function WndUICheckBox:SprintfText(...)
	self.__text:SprintfText(...)
	return self
end

function WndUICheckBox:SetAnimation(...)
	self.__this:SetAnimation(...)
	return self
end

function WndUICheckBox:SetSize(...)
	self.__this:SetSize(...)
	self.__this:Lookup("", ""):SetSize(...)
	self.__text:SetSize(...)
	return self
end

-- WndCSlider Object
local WndCSlider = class(WndBase)
function WndCSlider:ctor(__parent, __name, __data)
	assert(__parent ~= nil, "parent can not be null.")
	__data = __data or {}
	local hwnd = _AppendWnd(__parent, "WndCSlider", __name)
	self.__scroll = hwnd:Lookup("Scroll_Default")
	self.__text = hwnd:Lookup("", "Text_Default")
	self.__this = hwnd
	self:_SetSelf(self.__this)
	self:_SetParent(__parent)
	self:_SetType("WndCSlider")
	self.__min = __data.min
	self.__max = __data.max
	self.__step = __data.step
	self.__unit = __data.unit or ""
	self.__scroll:SetStepCount(__data.step)
	self:SetSize(__data.w or 120)
	self:Enable((__data.enable == nil or __data.enable) and true or false)
	self:SetRelPos(__data.x or 0, __data.y or 0)
	self:UpdateScrollPos(__data.value or 0)

	--Bind CSlider Events
	self.__scroll.OnScrollBarPosChanged = function()
		local __step = this:GetScrollPos()
		local __value = self:GetValue(__step)
		self.__text:SetText(__value .. self.__unit)
		self:_FireEvent("OnChange", __value)
	end
end

function WndCSlider:Enable(__enable)
	if __enable then
		self.__text:SetFontColor(255, 255, 255)
		self.__scroll:Enable(true)
	else
		self.__text:SetFontColor(180, 180, 180)
		self.__scroll:Enable(false)
	end
	return self
end

function WndCSlider:SetSize(__w)
	self.__this:SetSize(__w, 25)
	self.__this:Lookup("", ""):SetSize(__w, 25)
	self.__this:Lookup("", ""):Lookup("Image_BG"):SetSize(__w, 10)
	self.__scroll:SetSize(__w, 25)
	self.__text:SetRelPos(__w + 5, 2)
	self.__this:Lookup("", ""):FormatAllItemPos()
	return self
end

function WndCSlider:GetValue(__step)
	return self.__min + __step * (self.__max - self.__min) / self.__step
end

function WndCSlider:GetStep(__value)
	return (__value - self.__min) * self.__step / (self.__max - self.__min)
end

function WndCSlider:ChangeToArea(__min, __max, __step)
	return __min + (__max - __min) * (self:GetValue(__step) - self.__min) / (self.__max - self.__min)
end

function WndCSlider:ChangeToAreaFromValue(__min, __max, __value)
	return __min + (__max - __min) * (__value - self.__min) / (self.__max - self.__min)
end

function WndCSlider:GetStepFromArea(__min, __max, __value)
	return self:GetStep(self.__min + (self.__max - self.__min) * (__value - __min) / (__max - __min))
end

function WndCSlider:UpdateScrollPos(__value)
	self.__text:SetText(__value .. self.__unit)
	self.__scroll:SetScrollPos(self:GetStep(__value))
	return self
end

-- WndColorBox Object
local WndColorBox = class(WndBase)
function WndColorBox:ctor(__parent, __name, __data)
	assert(__parent ~= nil, "parent can not be null.")
	__data = __data or {}
	local hwnd = _AppendWnd(__parent, "WndColorBox", __name)
	self.__text = hwnd:Lookup("", "Text_Default")
	self.__shadow = hwnd:Lookup("", "Shadow_Default")
	self.__this = hwnd
	self:_SetSelf(self.__this)
	self:_SetParent(__parent)
	self:_SetType("WndColorBox")
	self.__r = __data.r
	self.__g = __data.g
	self.__b = __data.b
	self:SetText(__data.text)
	self:SetColor(__data.r, __data.g, __data.b)
	self:SetSize(self.__text:GetTextExtent())
	self:SetRelPos(__data.x or 0, __data.y or 0)

	--Bind ColorBox Events
	--hwnd.OnItemLButtonClick = function()
	self.__shadow.OnItemLButtonClick = function()
		local fnChangeColor = function(r, g, b)
			self:SetColor(r, g, b)
			self:_FireEvent("OnChange", {r, g, b})
		end
		LR.OpenColorTablePanel(fnChangeColor,{self.__r, self.__g, self.__b})
	end
	self.__shadow.OnItemMouseEnter = function()
		local x, y=this:GetAbsPos()
		local w, h = this:GetSize()
		local r,g,b=self.__r, self.__g, self.__b
		local szText=string.format("R:%s  G:%s  B:%s\n",r,g,b)
		szText=GetFormatText(szText,136,255,128,0)
		OutputTip(szText,350,{x,y,w,h})
	end
	self.__shadow.OnItemMouseLeave= function()
		HideTip()
	end
	self.__text.OnItemLButtonClick = self.__shadow.OnItemLButtonClick
	self.__text.OnItemMouseEnter = self.__shadow.OnItemMouseEnter
	self.__text.OnItemMouseLeave = self.__shadow.OnItemMouseLeave
end

function WndColorBox:SetSize(__w)
	self.__this:SetSize(__w+25, 25)
	self.__this:Lookup("", ""):SetSize(__w+25, 25)
	self.__text:SetSize(__w, 25)
	return self
end

function WndColorBox:SetText(...)
	self.__text:SetText(...)
	return self
end

function WndColorBox:SprintfText(...)
	self.__text:SprintfText(...)
	return self
end

function WndColorBox:SetColor(...)
	self.__shadow:SetColorRGB(...)
	self.__text:SetFontColor(...)
	self.__r, self.__g, self.__b = unpack({...})
	return self
end

-- WndContainer Object
local WndContainer = class(WndBase)
function WndContainer:ctor(__parent, __name, __data)
	assert(__parent ~= nil, "parent can not be null.")
	__data = __data or {}
	local hwnd = _AppendWnd(__parent, "WndContainer", __name)
	self.__this = hwnd
	self:_SetSelf(self.__this)
	self:_SetParent(__parent)
	self:_SetType("WndContainer")
	self:SetSize(__data.w or 100, __data.h or 100)
	self:SetRelPos(__data.x or 0, __data.y or 0)
	self.data = {parent = __parent, name = __name, data = __data}
end

function WndContainer:SetSize(...)
	self.__this:SetSize(...)
	return self
end

function WndContainer:ClearHandle()
	self.__this:Clear()
	return self
end

function WndContainer:GetAllContentCount()
	return self.__this:GetAllContentCount()
end

function WndContainer:GetAllContentSize()
	return self.__this:GetAllContentSize()
end

function WndContainer:FormatAllContentPos()
	return self.__this:FormatAllContentPos()
end


-- WndContainerScroll Object
local WndContainerScroll = class(WndBase)
function WndContainerScroll:ctor(__parent, __name, __data)
	assert(__parent ~= nil, "parent can not be null.")
	__data = __data or {}
	local hwnd = _AppendWnd(__parent, "WndContainerScroll", __name)
	local hWndScroll = hwnd:Lookup("WndScroll")
	local _WndContainer = hWndScroll:Lookup("_WndContainer")
	local Scroll_List=hwnd:Lookup("New_ScrollBar")
	self.__this = hwnd
	self.__WndContainer = _WndContainer
	self._hwnd = hwnd
	self._hWndScroll=hWndScroll
	self.__up = hWndScroll:Lookup("Btn_Up")
	self.__down = hWndScroll:Lookup("Btn_Down")
	self.__scroll = hWndScroll:Lookup("New_ScrollBar")
	self.__handle = hWndScroll:Lookup("", "")
	self:_SetSelf(self.__this)
	self:_SetParent(__parent)
	self:_SetType("WndContainerScroll")


	self:SetSize(__data.w or 500, __data.h or 345)
	self:SetRelPos(__data.x or 0, __data.y or 0)
end

function WndContainerScroll:GetSelf()
	return self.__WndContainer
end

function WndContainerScroll:SetSize(__w, __h)
	self.__this:SetSize(__w, __h)
	self._hwnd:SetSize(__w, __h)
	self._hWndScroll:SetSize(__w, __h)
	self.__handle:SetSize(__w, __h)
	self.__scroll:SetSize(15, __h - 40)
	self.__WndContainer:SetSize(__w, __h)
	self.__scroll:SetRelPos(__w - 17, 20)
	self.__up:SetRelPos(__w - 20, 3)
	self.__down:SetRelPos(__w - 20, __h - 20)
	return self
end

function WndContainerScroll:GetHandle()
	return self.__this
end

function WndContainerScroll:Clear()
	self.__WndContainer:Clear()
	return self.__WndContainer
end

function WndContainerScroll:ClearHandle()
	self.__WndContainer:Clear()
	return self.__WndContainer
end

function WndContainerScroll:GetAllContentCount()
	return self.__WndContainer:GetAllContentCount()
end

function WndContainerScroll:GetAllContentSize()
	return self.__WndContainer:GetAllContentSize()
end

function WndContainerScroll:FormatAllContentPos()
	self.__WndContainer:FormatAllContentPos()
end

-- WndScroll Object
local WndScroll = class(WndBase)
function WndScroll:ctor(__parent, __name, __data)
	assert(__parent ~= nil, "parent can not be null.")
	__data = __data or {}
	local hwnd = _AppendWnd(__parent, "WndScroll", __name)
	self.__this = hwnd
	self:_SetSelf(self.__this)
	self:_SetParent(__parent)
	self:_SetType("WndScroll")
	self.__up = self.__this:Lookup("Btn_Up")
	self.__down = self.__this:Lookup("Btn_Down")
	self.__scroll = self.__this:Lookup("Scroll_List")
	self.__handle = self.__this:Lookup("", "")

	self:SetSize(__data.w or 500, __data.h or 345)
	self:SetRelPos(__data.x or 0, __data.y or 0)

	self.__up.OnLButtonHold = function()
		self.__scroll:ScrollPrev(1)
	end
	self.__up.OnLButtonDown = function()
		self.__scroll:ScrollPrev(1)
	end
	self.__down.OnLButtonHold = function()
		self.__scroll:ScrollNext(1)
	end
	self.__down.OnLButtonDown = function()
		self.__scroll:ScrollNext(1)
	end
	self.__handle.OnItemMouseWheel = function()
		local __dist = Station.GetMessageWheelDelta()
		self.__scroll:ScrollNext(__dist)
		return true
	end
	self.__scroll.OnScrollBarPosChanged = function()
		local __value = this:GetScrollPos()
		if __value == 0 then
			self.__up:Enable(false)
		else
			self.__up:Enable(true)
		end
		if __value == this:GetStepCount() then
			self.__down:Enable(false)
		else
			self.__down:Enable(true)
		end
		self.__handle:SetItemStartRelPos(0, -__value * 10)
	end
end

function WndScroll:Lookup(...)
	return self.__handle:Lookup(...)
end

function WndScroll:GetHandle()
	return self.__handle
end

function WndScroll:AppendItemFromIni(...)
	local __item = self.__handle:AppendItemFromIni(...)
	return __item
end

function WndScroll:AddItem(__name)
	local __item = ScrollItems.new(self:GetHandle(), "Handle_Item", "Item_" .. __name)
	__item:Show()
	local __cover = __item:GetSelf():Lookup("Image_Cover")
	__item.OnEnter = function()
		__cover:Show()
	end
	__item.OnLeave = function()
		__cover:Hide()
	end
	return __item
end

function WndScroll:RemoveItem(...)
	self.__handle:RemoveItem(...)
	return self
end

function WndScroll:SetHandleStyle(...)
	self.__handle:SetHandleStyle(...)
	return self
end

function WndScroll:ClearHandle()
	self.__handle:Clear()
	return self
end

function WndScroll:GetItemCount()
	return self.__handle:GetItemCount()
end

function WndScroll:ScrollPagePrev()
	self.__scroll:ScrollPagePrev()
	return self
end

function WndScroll:ScrollPageNext()
	self.__scroll:ScrollPageNext()
	return self
end

function WndScroll:ScrollHome()
	self.__scroll:ScrollHome()
	return self
end

function WndScroll:ScrollEnd()
	self.__scroll:ScrollEnd()
	return self
end

function WndScroll:UpdateList()
	self.__handle:FormatAllItemPos()
	local __w, __h = self.__handle:GetSize()
	local __wAll, __hAll = self.__handle:GetAllItemSize()
	local __count = math.ceil((__hAll - __h) / 10)

	self.__scroll:SetStepCount(__count)
	if __count > 0 then
		self.__scroll:Show()
		self.__up:Show()
		self.__down:Show()
	else
		self.__scroll:Hide()
		self.__up:Hide()
		self.__down:Hide()
	end
end

function WndScroll:SetSize(__w, __h)
	self.__this:SetSize(__w, __h)
	self.__handle:SetSize(__w, __h)
	self.__scroll:SetSize(15, __h - 40)
	self.__scroll:SetRelPos(__w - 17, 20)
	self.__up:SetRelPos(__w - 20, 3)
	self.__down:SetRelPos(__w - 20, __h - 20)
	return self
end

----------------------------------------------
-- ItemNull Type Controls
----------------------------------------------

-- Append Control
local _AppendItem = function(__parent, __string, __name)
	if not __name then
		__name = string.format("EASYUI_INDEX_%d", NAME_INDEX)
		NAME_INDEX = NAME_INDEX + 1
	end
	if __parent.__addon then
		__parent = __parent:GetHandle()
	else
		if __parent:GetType() == "WndWindow" then

		end
	end

	local __count = __parent:GetItemCount()
	__parent:AppendItemFromString(__string)
	local hwnd = __parent:Lookup(__count)
	hwnd:SetName(__name)

	return hwnd
end

-- Base Class of ItemType Control
local ItemBase = class()
function ItemBase:ctor(__this)
	self.__addon = true
	self.__listeners = {self}
end

function ItemBase:SetName(...)
	self.__this:SetName(...)
	return self
end

function ItemBase:SetIndex(...)
	self.__this:SetIndex(...)
	return self
end

function ItemBase:GetName()
	return self.__this:GetName()
end

function ItemBase:Scale(...)
	self.__this:Scale(...)
	return self
end

function ItemBase:LockShowAndHide(...)
	self.__this:LockShowAndHide(...)
	return self
end

function ItemBase:_SetSelf(__this)
	self.__this = __this
end

function ItemBase:GetSelf()
	return self.__this
end

function ItemBase:SetSize(...)
	self.__this:SetSize(...)
	return self
end

function ItemBase:GetSize()
	return self.__this:GetSize()
end

function ItemBase:SetRelPos(...)
	self.__this:SetRelPos(...)
	return self
end

function ItemBase:GetRelPos()
	return self.__this:GetRelPos()
end

function ItemBase:SetAbsPos(...)
	self.__this:SetAbsPos(...)
	return self
end

function ItemBase:GetAbsPos()
	return self.__this:GetAbsPos()
end

function ItemBase:SetAlpha(...)
	self.__this:SetAlpha(...)
	return self
end

function ItemBase:SetTip(...)
	self.__this:SetTip(...)
	return self
end

function ItemBase:GetTip()
	return self.__this:GetTip()
end

function ItemBase:GetAlpha()
	return self.__this:GetAlpha()
end

function ItemBase:GetType()
	return self.__this:GetType()
end

function ItemBase:SetPosType(...)
	self.__this:SetPosType(...)
	return self
end

function ItemBase:GetPosType()
	return self.__this:GetPosType()
end

function ItemBase:_SetParent(__parent)
	self.__parent = __parent
end

function ItemBase:GetParent()
	return self.__parent
end

function ItemBase:IsValid()
	return self.__this:IsValid()
end

function ItemBase:HasParent(__name)
	if self:GetType() == "WndFrame" then
		return false
	else
		local Parent=self:GetParent()
		if Parent:GetName() == __name then
			return true
		else
			return Parent:HasParent(__name)
		end
	end
end

function ItemBase:Destroy()
	if self.__parent:GetType() == "WndScroll" then
		self.__parent:GetHandle():RemoveItem(self.__this)
	else
		self.__parent:RemoveItem(self.__this)
	end
	return self
end

function ItemBase:Show()
	self.__this:Show()
	return self
end

function ItemBase:Hide()
	self.__this:Hide()
	return self
end

function ItemBase:IsVisible()
	return self.__this:IsVisible()
end

function ItemBase:_FireEvent(__event, ...)
	for __k, __v in pairs(self.__listeners) do
		if __v[__event] then
			local res, err = pcall(__v[__event],  ...)
			if not res then
				LR.SysMsg( "ERROR:" .. err .. "\n")
			end
		end
	end
end

-- Handle Object
local ItemHandle = class(ItemBase)
function ItemHandle:ctor(__parent, __name, __data)
	assert(__parent ~= nil, "parent can not be null." .. __name)
	__data = __data or {}
	local __string = "<handle>w=10 h=10 handletype=0 postype=0 eventid=272 firstpostype=0 disablescale=0</handle>"
	if __data.w then
		__string = string.gsub(__string, "w=%d+", string.format("w=%d", __data.w))
	end
	if __data.h then
		__string = string.gsub(__string, "h=%d+", string.format("h=%d", __data.h))
	end
	if __data.handletype then
		__string = string.gsub(__string, "handletype=%d+", string.format("handletype=%d", __data.handletype))
	end
	if __data.firstpostype then
		__string = string.gsub(__string, "firstpostype=%d+", string.format("firstpostype=%d", __data.firstpostype))
	end
	if __data.postype then
		__string = string.gsub(__string, "postype=%d+", string.format("postype=%d", __data.postype))
	end
	if __data.eventid then
		__string = string.gsub(__string, "eventid=%d+", string.format("eventid=%d", __data.eventid))
	end
	if __data.hover then
		__string = string.gsub(__string, "hover=%d+", string.format("hover='%s'", __data.hover))
	end
	--Output(__string)
	local hwnd = _AppendItem(__parent, __string, __name)
	self.__this = hwnd
	self:_SetSelf(self.__this)
	self:_SetParent(__parent)
	self:SetRelPos(__data.x or 0, __data.y or 0)

	if __parent.__addon then
		__parent = __parent:GetHandle()
	end
	__parent:FormatAllItemPos()

	--Bind Handle Events
	self.__this.OnItemLButtonClick = function()
		self:_FireEvent("OnClick")
	end
	self.__this.OnItemMouseEnter = function()
		self:_FireEvent("OnEnter")
	end
	self.__this.OnItemMouseLeave = function()
		self:_FireEvent("OnLeave")
	end
	self.__this.OnItemRButtonClick = function()
		self:_FireEvent("OnRClick")
	end
end

function ItemHandle:Lookup(...)
	return self.__this:Lookup(...)
end

function ItemHandle:ChangeRelation(...)
	self.__this:ChangeRelation(...)
	return self
end

function ItemHandle:GetHandle()
	return self.__this
end

function ItemHandle:RegisterEvent(...)
	self.__this:RegisterEvent(...)
	return self
end

function ItemHandle:AppendItemFromString(...)
	return self.__this:AppendItemFromString(...)
end

function ItemHandle:AppendItemFromIni(...)
	return self.__this:AppendItemFromIni(...)
end

function ItemHandle:AppendItemFromData(...)
	self.__this:AppendItemFromData(...)
	return self
end

function ItemHandle:FormatAllItemPos()
	self.__this:FormatAllItemPos()
	return self
end

function ItemHandle:SetHandleStyle(...)
	self.__this:SetHandleStyle(...)
	return self
end

function ItemHandle:GetItemStartRelPos()
	return self.__this:GetItemStartRelPos()
end

function ItemHandle:SetItemStartRelPos(...)
	self.__this:SetItemStartRelPos(...)
	return self
end

function ItemHandle:SetSizeByAllItemSize()
	self.__this:SetSizeByAllItemSize()
	return self
end

function ItemHandle:GetAllItemSize()
	return self.__this:GetAllItemSize()
end

function ItemHandle:GetVisibleItemCount()
	return self.__this:GetVisibleItemCount()
end

function ItemHandle:EnableFormatWhenAppend(...)
	self.__this:EnableFormatWhenAppend(...)
	return self
end

function ItemHandle:ExchangeItemIndex(...)
	self.__this:ExchangeItemIndex(...)
	return self
end

function ItemHandle:SetMinRowHeight(...)
	self.__this:SetMinRowHeight(...)
	return self
end

function ItemHandle:SetMaxRowHeight(...)
	self.__this:SetMaxRowHeight(...)
	return self
end

function ItemHandle:SetRowHeight(...)
	self.__this:SetRowHeight(...)
	return self
end

function ItemHandle:Sort()
	self.__this:Sort()
	return self
end

function ItemHandle:GetItemCount()
	return self.__this:GetItemCount()
end

function ItemHandle:ClearHandle()
	self.__this:Clear()
	return self
end

function ItemHandle:Clear()
	self.__this:Clear()
	return self
end

-- hoverhandle
local ItemHoverHandle = class(ItemBase)
function ItemHoverHandle:ctor(__parent, __name, __data)
	assert(__parent ~= nil, "parent can not be null.")
	__data = __data or {}

	local hwnd = __parent:AppendItemFromIni(string.format(__ini, "ItemHoverHandle"), "HoverHandle", __name)
	self.__this = hwnd
	self:_SetSelf(self.__this)
	self:_SetParent(__parent)
	self:SetRelPos(__data.x or 0, __data.y or 0)
	self:SetSize(__data.w, __data.h)

	hwnd:SetName(__name)

	if __parent.__addon then
		__parent = __parent:GetHandle()
	end

	__parent:FormatAllItemPos()

	--Bind Handle Events
	self.__this.OnItemLButtonClick = function()
		self:_FireEvent("OnClick")
	end
	self.__this.OnItemMouseEnter = function()
		self:_FireEvent("OnEnter")
	end
	self.__this.OnItemMouseLeave = function()
		self:_FireEvent("OnLeave")
	end
	self.__this.OnItemRButtonClick = function()
		self:_FireEvent("OnRClick")
	end
end

function ItemHoverHandle:Lookup(...)
	return self.__this:Lookup(...)
end

function ItemHoverHandle:ChangeRelation(...)
	self.__this:ChangeRelation(...)
	return self
end

function ItemHoverHandle:GetHandle()
	return self.__this
end

function ItemHoverHandle:RegisterEvent(...)
	self.__this:RegisterEvent(...)
	return self
end

function ItemHoverHandle:AppendItemFromString(...)
	return self.__this:AppendItemFromString(...)
end

function ItemHoverHandle:AppendItemFromIni(...)
	return self.__this:AppendItemFromIni(...)
end

function ItemHoverHandle:AppendItemFromData(...)
	self.__this:AppendItemFromData(...)
	return self
end

function ItemHoverHandle:FormatAllItemPos()
	self.__this:FormatAllItemPos()
	return self
end

function ItemHoverHandle:SetHandleStyle(...)
	self.__this:SetHandleStyle(...)
	return self
end

function ItemHoverHandle:GetItemStartRelPos()
	return self.__this:GetItemStartRelPos()
end

function ItemHoverHandle:SetItemStartRelPos(...)
	self.__this:SetItemStartRelPos(...)
	return self
end

function ItemHoverHandle:SetSizeByAllItemSize()
	self.__this:SetSizeByAllItemSize()
	return self
end

function ItemHoverHandle:GetAllItemSize()
	return self.__this:GetAllItemSize()
end

function ItemHoverHandle:GetVisibleItemCount()
	return self.__this:GetVisibleItemCount()
end

function ItemHoverHandle:EnableFormatWhenAppend(...)
	self.__this:EnableFormatWhenAppend(...)
	return self
end

function ItemHoverHandle:ExchangeItemIndex(...)
	self.__this:ExchangeItemIndex(...)
	return self
end

function ItemHoverHandle:SetMinRowHeight(...)
	self.__this:SetMinRowHeight(...)
	return self
end

function ItemHoverHandle:SetMaxRowHeight(...)
	self.__this:SetMaxRowHeight(...)
	return self
end

function ItemHoverHandle:SetRowHeight(...)
	self.__this:SetRowHeight(...)
	return self
end

function ItemHoverHandle:Sort()
	self.__this:Sort()
	return self
end

function ItemHoverHandle:GetItemCount()
	return self.__this:GetItemCount()
end

function ItemHoverHandle:ClearHandle()
	self.__this:Clear()
	return self
end

function ItemHoverHandle:Clear()
	self.__this:Clear()
	return self
end

function ItemHoverHandle:SetSize(...)
	self.__this:SetSize(...)
	self.__this:Lookup("Image_Hover"):SetSize(...)
	return self
end

-- Text Object
local ItemText = class(ItemBase)
function ItemText:ctor(__parent, __name, __data)
	assert(__parent ~= nil, "parent can not be null.")
	__data = __data or {}
	local __string = "<text>w=150 h=30 valign=1 font=162 postype=0 </text>"
	if __data.w then
		__string = string.gsub(__string, "w=%d+", string.format("w=%d", __data.w))
	end
	if __data.h then
		__string = string.gsub(__string, "h=%d+", string.format("h=%d", __data.h))
	end
	if __data.valign then
		__string = string.gsub(__string, "valign=%d+", string.format("valign=%d", __data.valign))
	end
	if __data.font then
		__string = string.gsub(__string, "font=%d+", string.format("font=%d", __data.font))
	end
	if __data.postype then
		__string = string.gsub(__string, "postype=%d+", string.format("postype=%d", __data.postype))
	end
	local hwnd = _AppendItem(__parent, __string, __name)
	self.__this = hwnd
	self:_SetSelf(self.__this)
	self:_SetParent(__parent)
	self:SetText(__data.text or "")
	self:SetRelPos(__data.x or 0, __data.y or 0)
	if __parent.__addon then
		__parent = __parent:GetHandle()
	end
	__parent:FormatAllItemPos()

	--Bind Box Events
	self.__this.OnItemMouseEnter = function()
		self:_FireEvent("OnEnter")
	end
	self.__this.OnItemMouseLeave = function()
		self:_FireEvent("OnLeave")
	end
	self.__this.OnItemLButtonClick = function()
		self:_FireEvent("OnClick")
	end
end

function ItemText:Enable(__enable)
	if __enable then
		self.__this:SetFontColor(255, 255, 255)
	else
		self.__this:SetFontColor(180, 180, 180)
	end
	return self
end

function ItemText:SetText(...)
	self.__this:SetText(...)
	return self
end

function ItemText:GetText()
	return self.__this:GetText()
end

function ItemText:SprintfText(...)
	return self.__this:SprintfText(...)
end

function ItemText:RegisterEvent(...)
	self.__this:RegisterEvent(...)
end

function ItemText:SetFontScheme(...)
	self.__this:SetFontScheme(...)
	return self
end

function ItemText:GetFontScheme()
	return self.__this:GetFontScheme()
end

function ItemText:GetTextLen()
	return self.__this:GetTextLen()
end

function ItemText:SetVAlign(...)
	self.__this:SetVAlign(...)
	return self
end

function ItemText:GetVAlign()
	return self.__this:GetVAlign()
end

function ItemText:SetHAlign(...)
	self.__this:SetHAlign(...)
	return self
end

function ItemText:GetHAlign()
	return self.__this:GetHAlign()
end

function ItemText:SetRowSpacing(...)
	self.__this:SetRowSpacing(...)
	return self
end

function ItemText:GetRowSpacing()
	return self.__this:GetRowSpacing()
end

function ItemText:SetMultiLine(...)
	self.__this:SetMultiLine(...)
	return self
end

function ItemText:IsMultiLine()
	return self.__this:IsMultiLine()
end

function ItemText:FormatTextForDraw(...)
	self.__this:FormatTextForDraw(...)
	return self
end

function ItemText:AutoSize()
	self.__this:AutoSize()
	return self
end

function ItemText:SetCenterEachLine(...)
	self.__this:SetCenterEachLine(...)
	return self
end

function ItemText:IsCenterEachLine()
	return self.__this:IsCenterEachLine()
end

function ItemText:SetRichText(...)
	self.__this:SetRichText(...)
	return self
end

function ItemText:IsRichText()
	return self.__this:IsRichText()
end

function ItemText:GetFontScale()
	return self.__this:GetFontScale()
end

function ItemText:SetFontScale(...)
	self.__this:SetFontScale(...)
	return self
end

function ItemText:SetFontID(...)
	self.__this:SetFontID(...)
	return self
end

function ItemText:SetFontBorder(...)
	self.__this:SetFontBorder(...)
	return self
end

function ItemText:SetFontShadow(...)
	self.__this:SetFontShadow(...)
	return self
end

function ItemText:GetFontID()
	return self.__this:GetFontID()
end

function ItemText:GetFontBoder()
	return self.__this:GetFontBoder()
end

function ItemText:GetFontProjection()
	return self.__this:GetFontProjection()
end

function ItemText:GetTextExtent()
	return self.__this:GetTextExtent()
end

function ItemText:GetTextPosExtent()
	return self.__this:GetTextPosExtent()
end

function ItemText:SetFontColor(...)
	self.__this:SetFontColor(...)
	return self
end

function ItemText:GetFontColor()
	return self.__this:GetFontColor()
end

function ItemText:SetFontSpacing(...)
	self.__this:SetFontSpacing(...)
	return self
end

function ItemText:GetFontSpacing()
	return self.__this:GetFontSpacing()
end

-- Box Object
local ItemBox = class(ItemBase)
function ItemBox:ctor(__parent, __name, __data)
	assert(__parent ~= nil, "parent can not be null.")
	__data = __data or {}
	local __string = "<box>w=48 h=48 postype=0 eventid=272 </box>"
	if __data.w then
		__string = string.gsub(__string, "w=%d+", string.format("w=%d", __data.w))
	end
	if __data.h then
		__string = string.gsub(__string, "h=%d+", string.format("h=%d", __data.h))
	end
	if __data.postype then
		__string = string.gsub(__string, "postype=%d+", string.format("postype=%d", __data.postype))
	end
	if __data.eventid then
		__string = string.gsub(__string, "eventid=%d+", string.format("eventid=%d", __data.eventid))
	end
	local hwnd = _AppendItem(__parent, __string, __name)
	self.__this = hwnd
	self:_SetSelf(self.__this)
	self:_SetParent(__parent)
	self:SetRelPos(__data.x or 0, __data.y or 0)
	if __parent.__addon then
		__parent = __parent:GetHandle()
	end
	__parent:FormatAllItemPos()

	--Bind Box Events
	self.__this.OnItemMouseEnter = function()
		self:_FireEvent("OnEnter")
	end
	self.__this.OnItemMouseLeave = function()
		self:_FireEvent("OnLeave")
	end
	self.__this.OnItemLButtonClick = function()
		self:_FireEvent("OnClick")
	end
end

function ItemBox:SetObject(...)
	self.__this:SetObject(...)
	return self
end

function ItemBox:GetObject()
	return self.__this:GetObject()
end

function ItemBox:GetObjectType()
	return self.__this:GetObjectType()
end

function ItemBox:GetObjectData()
	return self.__this:GetObjectData()
end

function ItemBox:ClearObject()
	return self.__this:ClearObject()
end

function ItemBox:IsEmpty()
	return self.__this:IsEmpty()
end

function ItemBox:EnableObject(...)
	self.__this:EnableObject(...)
	return self
end

function ItemBox:IsObjectEnable()
	return self.__this:IsObjectEnable()
end

function ItemBox:SetObjectCoolDown(...)
	self.__this:SetObjectCoolDown(...)
	return self
end

function ItemBox:IsObjectCoolDown()
	return self.__this:IsObjectCoolDown()
end

function ItemBox:SetObjectSparking(...)
	self.__this:SetObjectSparking(...)
	return self
end

function ItemBox:SetObjectInUse(...)
	self.__this:SetObjectInUse(...)
	return self
end

function ItemBox:SetObjectStaring(...)
	self.__this:SetObjectStaring(...)
	return self
end

function ItemBox:SetObjectSelected(...)
	self.__this:SetObjectSelected(...)
	return self
end

function ItemBox:IsObjectSelected()
	return self.__this:IsObjectSelected()
end

function ItemBox:SetObjectMouseOver(...)
	self.__this:SetObjectMouseOver(...)
	return self
end

function ItemBox:IsObjectMouseOver()
	return self.__this:IsObjectMouseOver()
end

function ItemBox:SetObjectPressed(...)
	self.__this:SetObjectPressed(...)
	return self
end

function ItemBox:IsObjectPressed()
	return self.__this:IsObjectPressed()
end

function ItemBox:SetCoolDownPercentage(...)
	self.__this:SetCoolDownPercentage(...)
	return self
end

function ItemBox:GetCoolDownPercentage()
	return self.__this:GetCoolDownPercentage()
end

function ItemBox:SetObjectIcon(...)
	self.__this:SetObjectIcon(...)
	return self
end

function ItemBox:GetObjectIcon()
	return self.__this:GetObjectIcon()
end

function ItemBox:ClearObjectIcon()
	self.__this:ClearObjectIcon()
	return self
end

function ItemBox:SetOverText(...)
	self.__this:SetOverText(...)
	return self
end

function ItemBox:GetOverText()
	return self.__this:GetOverText()
end

function ItemBox:SetOverTextFontScheme(...)
	self.__this:SetOverTextFontScheme(...)
	return self
end

function ItemBox:GetOverTextFontScheme()
	return self.__this:GetOverTextFontScheme()
end

function ItemBox:SetOverTextPosition(...)
	self.__this:SetOverTextPosition(...)
	return self
end

function ItemBox:GetOverTextPosition()
	return self.__this:GetOverTextPosition()
end

function ItemBox:SetExtentImage(...)
	self.__this:SetExtentImage(...)
	return self
end

function ItemBox:ClearExtentImage()
	self.__this:ClearExtentImage()
	return self
end

function ItemBox:SetExtentAnimate(...)
	self.__this:SetExtentAnimate(...)
	return self
end

function ItemBox:ClearExtentAnimate()
	self.__this:ClearExtentAnimate()
	return self
end

-- Image Object
local ItemImage = class(ItemBase)
function ItemImage:ctor(__parent, __name, __data)
	assert(__parent ~= nil, "parent can not be null.")
	__data = __data or {}
	local __string = "<image>w=100 h=100 postype=0 lockshowhide=0 eventid=0 </image>"
	if __data.w then
		__string = string.gsub(__string, "w=%d+", string.format("w=%d", __data.w))
	end
	if __data.h then
		__string = string.gsub(__string, "h=%d+", string.format("h=%d", __data.h))
	end
	if __data.postype then
		__string = string.gsub(__string, "postype=%d+", string.format("postype=%d", __data.postype))
	end
	if __data.lockshowhide then
		__string = string.gsub(__string, "lockshowhide=%d+", string.format("lockshowhide=%d", __data.lockshowhide))
	end
	if __data.eventid then
		__string = string.gsub(__string, "eventid=%d+", string.format("eventid=%d", __data.eventid))
	end
	local hwnd = _AppendItem(__parent, __string, __name)
	self.__this = hwnd
	self:_SetSelf(self.__this)
	self:_SetParent(__parent)
	if __data.image then
		local __image = __data.image
		local __frame = __data.frame or nil
		self:SetImage(__image, __frame)
	end
	self:SetRelPos(__data.x or 0, __data.y or 0)
	if __parent.__addon then
		__parent = __parent:GetHandle()
	end
	__parent:FormatAllItemPos()

	--Bind Image Events
	self.__this.OnItemMouseEnter = function()
		self:_FireEvent("OnEnter")
	end
	self.__this.OnItemMouseLeave = function()
		self:_FireEvent("OnLeave")
	end
	self.__this.OnItemLButtonClick = function()
		self:_FireEvent("OnClick")
	end
	self.__this.OnItemRButtonClick = function()
		self:_FireEvent("OnRClick")
	end
end

function ItemImage:SetFrame(...)
	self.__this:SetFrame(...)
	return self
end

function ItemImage:GetFrame()
	return self.__this:GetFrame()
end

function ItemImage:SetImageType(...)
	self.__this:SetImageType(...)
	return self
end

function ItemImage:GetImageType()
	return self.__this:GetImageType()
end

function ItemImage:SetPercentage(...)
	self.__this:SetPercentage(...)
	return self
end

function ItemImage:GetPercentage()
	return self.__this:GetPercentage()
end

function ItemImage:SetRotate(...)
	self.__this:SetRotate(...)
	return self
end

function ItemImage:GetRotate()
	return self.__this:GetRotate()
end

function ItemImage:GetImageID()
	return self.__this:GetImageID()
end

function ItemImage:FromUITex(...)
	self.__this:FromUITex(...)
	return self
end

function ItemImage:FromTextureFile(...)
	self.__this:FromTextureFile(...)
	return self
end

function ItemImage:FromScene(...)
	self.__this:FromScene(...)
	return self
end

function ItemImage:FromImageID(...)
	self.__this:FromImageID(...)
	return self
end

function ItemImage:FromIconID(...)
	self.__this:FromIconID(...)
	return self
end

function ItemImage:SetImage(__image, __frame)
	if type(__image) == "string" then
		if __frame then
			self:FromUITex(__image, __frame)
		else
			self:FromTextureFile(__image)
		end
	elseif type(__image) == "number" then
		self:FromIconID(__image)
	end
	return self
end

-- Shadow Object
local ItemShadow = class(ItemBase)
function ItemShadow:ctor(__parent, __name, __data)
	assert(__parent ~= nil, "parent can not be null.")
	__data = __data or {}
	local __string = "<shadow>w=15 h=15 postype=0 eventid = 0 </shadow>"
	if __data.w then
		__string = string.gsub(__string, "w=%d+", string.format("w=%d", __data.w))
	end
	if __data.h then
		__string = string.gsub(__string, "h=%d+", string.format("h=%d", __data.h))
	end
	if __data.postype then
		__string = string.gsub(__string, "postype=%d+", string.format("postype=%d", __data.postype))
	end
	if __data.eventid then
		__string = string.gsub(__string, "eventid=%d+", string.format("eventid=%d", __data.eventid))
	end
	local hwnd = _AppendItem(__parent, __string, __name)
	self.__this = hwnd
	self:_SetSelf(self.__this)
	self:_SetParent(__parent)
	self:SetRelPos(__data.x or 0, __data.y or 0)
	if __parent.__addon then
		__parent = __parent:GetHandle()
	end
	__parent:FormatAllItemPos()
end

function ItemShadow:SetShadowColor(...)
	self.__this:SetShadowColor(...)
	return self
end

function ItemShadow:GetShadowColor()
	return self.__this:GetShadowColor()
end

function ItemShadow:SetColorRGB(...)
	self.__this:SetColorRGB(...)
	return self
end

function ItemShadow:GetColorRGB()
	return self.__this:GetColorRGB()
end

function ItemShadow:SetTriangleFan(...)
	self.__this:SetTriangleFan(...)
	return self
end

function ItemShadow:IsTriangleFan()
	return self.__this:IsTriangleFan()
end

function ItemShadow:AppendTriangleFanPoint(...)
	self.__this:AppendTriangleFanPoint(...)
	return self
end

function ItemShadow:SetD3DPT(...)
	self.__this:SetD3DPT(...)
	return self
end

function ItemShadow:AppendTriangleFan3DPoint(...)
	self.__this:AppendTriangleFan3DPoint(...)
	return self
end

function ItemShadow:ClearTriangleFanPoint()
	self.__this:ClearTriangleFanPoint()
end

function ItemShadow:AppendDoodadID(...)
	self.__this:AppendDoodadID(...)
	return self
end

function ItemShadow:AppendCharacterID(...)
	self.__this:AppendCharacterID(...)
	return self
end

-- ItemAnimate Object
local ItemAnimate = class(ItemBase)
function ItemAnimate:ctor(__parent, __name, __data)
	assert(__parent ~= nil, "parent can not be null.")
	__data = __data or {}
	local __string = "<animate>w=30 h=30 postype=0 eventid=0 </animate>"
	if __data.w then
		__string = string.gsub(__string, "w=%d+", string.format("w=%d", __data.w))
	end
	if __data.h then
		__string = string.gsub(__string, "h=%d+", string.format("h=%d", __data.h))
	end
	if __data.postype then
		__string = string.gsub(__string, "postype=%d+", string.format("postype=%d", __data.postype))
	end
	if __data.eventid then
		__string = string.gsub(__string, "eventid=%d+", string.format("eventid=%d", __data.eventid))
	end
	local hwnd = _AppendItem(__parent, __string, __name)
	self.__this = hwnd
	self:_SetSelf(self.__this)
	self:_SetParent(__parent)
	if __data.image then
		local __image = __data.image
		local __group = __data.group or 0
		local __loop = __data.loop or -1
		self:SetAnimate(__image, __group, __loop)
	end
	self:SetRelPos(__data.x or 0, __data.y or 0)
	if __parent.__addon then
		__parent = __parent:GetHandle()
	end
	__parent:FormatAllItemPos()

	--Bind Animate Events
	self.__this.OnItemMouseEnter = function()
		self:_FireEvent("OnEnter")
	end
	self.__this.OnItemMouseLeave = function()
		self:_FireEvent("OnLeave")
	end
	self.__this.OnItemLButtonClick = function()
		self:_FireEvent("OnClick")
	end
end

function ItemAnimate:SetGroup(...)
	self.__this:SetGroup(...)
	return self
end

function ItemAnimate:SetLoopCount(...)
	self.__this:SetLoopCount(...)
	return self
end

function ItemAnimate:SetImagePath(...)
	self.__this:SetImagePath(...)
	return self
end

function ItemAnimate:SetAnimate(...)
	self.__this:SetAnimate(...)
	return self
end

function ItemAnimate:AutoSize()
	self.__this:AutoSize()
	return self
end

function ItemAnimate:Replay()
	self.__this:Replay()
	return self
end

function ItemAnimate:SetIdenticalInterval(...)
	self.__this:SetIdenticalInterval(...)
	return self
end

function ItemAnimate:IsFinished()
	return self.__this:IsFinished()
end

function ItemAnimate:SetAnimateType(...)
	self.__this:SetAnimateType(...)
	return self
end

function ItemAnimate:GetAnimateType()
	return self.__this:GetAnimateType()
end

-- TreeLeaf Object
local ItemTreeLeaf = class(ItemBase)
function ItemTreeLeaf:ctor(__parent, __name, __data)
	assert(__parent ~= nil, "parent can not be null.")
	__data = __data or {}
	local __string = "<treeleaf>w=150 h=25 indentwidth=20 alwaysnode=1 indent=0 eventid=257 </treeleaf>"
	if __data.w then
		__string = string.gsub(__string, "w=%d+", string.format("w=%d", __data.w))
	end
	if __data.h then
		__string = string.gsub(__string, "h=%d+", string.format("h=%d", __data.h))
	end
	if __data.eventid then
		__string = string.gsub(__string, "eventid=%d+", string.format("eventid=%d", __data.eventid))
	end
	local hwnd = _AppendItem(__parent, __string, __name)
	self.__this = hwnd
	self:_SetSelf(self.__this)
	self:_SetParent(__parent)
	self:SetRelPos(__data.x or 0, __data.y or 0)
	if __parent.__addon then
		__parent = __parent:GetHandle()
	end
	__parent:FormatAllItemPos()

	--Bind TreeLeaf Event
	self.__this.OnItemLButtonDown =function()
		self:_FireEvent("OnClick")
	end
end

function ItemTreeLeaf:GetHandle(...)
	return self.__this
end

function ItemTreeLeaf:FormatAllItemPos()
	self.__this:FormatAllItemPos()
	return self
end

function ItemTreeLeaf:SetHandleStyle(...)
	self.__this:SetHandleStyle(...)
	return self
end

function ItemTreeLeaf:SetRowHeight(...)
	self.__this:SetRowHeight(...)
	return self
end

function ItemTreeLeaf:SetRowSpacing(...)
	self.__this:SetRowSpacing(...)
	return self
end

function ItemTreeLeaf:ClearHandle()
	self.__this:Clear()
	return self
end

function ItemTreeLeaf:GetItemStartRelPos()
	return self.__this:GetItemStartRelPos()
end

function ItemTreeLeaf:SetItemStartRelPos(...)
	self.__this:SetItemStartRelPos(...)
	return self
end

function ItemTreeLeaf:SetSizeByAllItemSize()
	self.__this:SetSizeByAllItemSize()
	return self
end

function ItemTreeLeaf:GetAllItemSize()
	return self.__this:GetAllItemSize()
end

function ItemTreeLeaf:GetItemCount()
	return self.__this:GetItemCount()
end

function ItemTreeLeaf:GetVisibleItemCount()
	return self.__this:GetVisibleItemCount()
end

function ItemTreeLeaf:EnableFormatWhenAppend(...)
	self.__this:EnableFormatWhenAppend(...)
	return self
end

function ItemTreeLeaf:ExchangeItemIndex(...)
	self.__this:ExchangeItemIndex(...)
	return self
end

function ItemTreeLeaf:Sort()
	self.__this:Sort()
	return self
end

function ItemTreeLeaf:IsExpand()
	return self.__this:IsExpand()
end

function ItemTreeLeaf:ExpandOrCollapse(...)
	self.__this:ExpandOrCollapse(...)
	return self
end

function ItemTreeLeaf:Expand()
	self.__this:Expand()
	return self
end

function ItemTreeLeaf:Collapse()
	self.__this:Collapse()
	return self
end

function ItemTreeLeaf:SetIndent(...)
	self.__this:SetIndent(...)
	return self
end

function ItemTreeLeaf:GetIndent()
	return self.__this:GetIndent()
end

function ItemTreeLeaf:SetEachIndentWidth(...)
	self.__this:SetEachIndentWidth(...)
	return self
end

function ItemTreeLeaf:GetEachIndentWidth()
	return self.__this:GetEachIndentWidth()
end

function ItemTreeLeaf:SetNodeIconSize(...)
	self.__this:SetNodeIconSize(...)
	return self
end

function ItemTreeLeaf:SetIconImage(...)
	self.__this:SetIconImage(...)
	return self
end

function ItemTreeLeaf:PtInIcon(...)
	return self.__this:PtInIcon(...)
end

function ItemTreeLeaf:AdjustNodeIconPos()
	self.__this:AdjustNodeIconPos()
	return self
end

function ItemTreeLeaf:AutoSetIconSize()
	self.__this:AutoSetIconSize()
	return self
end

function ItemTreeLeaf:SetShowIndex(...)
	self.__this:SetShowIndex(...)
	return self
end

function ItemTreeLeaf:GetShowIndex()
	return self.__this:GetShowIndex()
end

-------------------------------------------
-- Addon Class
-------------------------------------------
local CreateAddon = class()
local Addon_List = {}
function CreateAddon_new(__name)
	if not Addon_List[__name] then
		Addon_List[__name] = CreateAddon.new(__name)
	end
	return Addon_List[__name]
end

function debug_addon_list()
	for k,v in pairs(Addon_List) do
		Output(k)
	end
end

function CreateAddon:ctor(__name)
	self.__listeners = {self}

	-- Store UI Object By Name
	self.__items = {}

	--Bind Addon Base Events
	self.OnFrameCreate = function()
		self:_FireEvent("OnCreate")
	end
	self.OnFrameBreathe = function()
		self:_FireEvent("OnBreathe")
	end
	self.OnFrameRender = function()
		self:_FireEvent("OnRender")
	end
	self.OnEvent = function(__event)
		self:_FireEvent("OnEvents", __event)
	end
end

function CreateAddon:BindEvent(__src, __tar)
	self[__src] = function()
		self:_FireEvent(__tar)
	end
end

function CreateAddon:_FireEvent(__event, ...)
	for __k, __v in pairs(self.__listeners) do
		if __v[__event] then
			local res, err = pcall(__v[__event], self, ...)
			if not res then
				LR.SysMsg( "ERROR:" .. err .. "\n")
			end
		end
	end
end

function CreateAddon:Fetch(__name)
	for k, v in pairs(self.__items) do
		if __name == k then
			return v
		end
	end
	return nil
end

function CreateAddon:ClearHandle(__name)
	if type(__name) == "string" then
		local __name = __name
		_h = self:Fetch(__name)
		local temp = {}
		for k,v in pairs (self.__items) do
			if v:HasParent(__name) then
				temp[#temp+1] = k
			end
		end
		for k, v in pairs(temp) do
			self.__items[v] = nil
		end
		__h:ClearHandle()
	else
		local __h = __name
		local __name = __h:GetName()
		local temp = {}
		for k,v in pairs (self.__items) do
			if v:HasParent(__name) then
				temp[#temp+1] = k
			end
		end
		for k, v in pairs(temp) do
			self.__items[v] = nil
		end
		__h:ClearHandle()
	end
end

function CreateAddon:Destroy(__name)
	if type(__name) == "string" then
		local __h=self:Fetch(__name)
		if __h then
			if __h:GetSelf():GetType() == "WndFrame" then
--[[				local alpha=__h:GetAlpha()
				local _stopAlpha=50
				if alpha > _stopAlpha and not LR_TOOLS.DisableEffect and not __h:GetdisableEffect() then
					if alpha == 255 then
						self._startTime= GetTime()
						self._endTime=self._startTime + 500
					end
					local alpha2=_stopAlpha + math.floor(( self._endTime - GetTime() - 1 )/(self._endTime - self._startTime) * (255 - _stopAlpha))
					__h:SetAlpha(alpha2)
					LR.DelayCall(2, function() self:Destroy(__name) end)
				else]]
					for k,v in pairs (self.__items) do
						if v:GetType() == "WndUICheckBox" then
							__UICheckBoxGroups[v:GetGroup()] = nil
						elseif v:GetType() == "WndRadioBox" then
							__RadioBoxGroups[v:GetGroup()] = nil
						end
					end
					__h:Destroy()
					self.__items = {}
				--end
			else
				local temp = {}
				for k,v in pairs (self.__items) do
					if v:HasParent(__name) then
						if v:GetType() == "WndUICheckBox" then
							__UICheckBoxGroups[v:GetGroup()] = nil
						elseif v:GetType() == "WndRadioBox" then
							__RadioBoxGroups[v:GetGroup()] = nil
						end
						temp[#temp+1] = k
					end
				end
				for k, v in pairs(temp) do
					self.__items[v] = nil
				end
				self.__items[__name] = nil
			end
		end
	else
		local __h=__name
		local __name=__h:GetName()
		if __h and __name then
			if __h:GetSelf():GetType() == "WndFrame" then
--[[				local alpha=__h:GetAlpha()
				local _stopAlpha=50
				if alpha > _stopAlpha and not LR_TOOLS.DisableEffect and not __h:GetdisableEffect()  then
					if alpha == 255 then
						self._startTime= GetTime()
						self._endTime=self._startTime + 400
					end
					local alpha2=_stopAlpha + math.floor(( self._endTime - GetTime() - 1 )/(self._endTime - self._startTime) * (255 - _stopAlpha))
					__h:SetAlpha(alpha2)
					LR.DelayCall(2, function() self:Destroy(__name) end)
				else]]
					for k,v in pairs (self.__items) do
						--Output(k,v:GetName())
						if v:GetType() == "WndUICheckBox" then
							__UICheckBoxGroups[v:GetGroup()] = nil
						elseif v:GetType() == "WndRadioBox" then
							__RadioBoxGroups[v:GetGroup()] = nil
						end
					end
					__h:Destroy()
					self.__items = {}
				--end
			else
				local temp = {}
				for k,v in pairs (self.__items) do
					if v and  v:HasParent(__name) then
						if v:GetType() == "WndUICheckBox" then
							__UICheckBoxGroups[v:GetGroup()] = nil
						elseif v:GetType() == "WndRadioBox" then
							__RadioBoxGroups[v:GetGroup()] = nil
						end
						temp[#temp+1] = k
					end
				end
				for k, v in pairs(temp) do
					self.__items[v] = nil
				end
				__h:Destroy()
				self.__items[__name] = nil
			end
		end
	end
end

function CreateAddon:ChangeIn(UI)
	local __h = UI
	local __name = _h:GetName()

end

function CreateAddon:Append(__type, ...)
	local __h = nil
	if __type == "Frame" then
		__h = WndFrame.new(...)
	elseif __type == "Window" then
		__h = WndWindow.new(...)
	elseif __type == "WndContainer" then
		__h = WndContainer.new(...)
	elseif __type == "WndContainerScroll" then
		__h = WndContainerScroll.new(...)
	elseif __type == "PageSet" then
		__h = WndPageSet.new(...)
	elseif __type == "Button" then
		__h = WndButton.new(...)
	elseif __type == "UIButton" then
		__h = WndUIButton.new(...)
	elseif __type == "Edit" then
		__h = WndEdit.new(...)
	elseif __type == "CheckBox" then
		__h = WndCheckBox.new(...)
	elseif __type == "ComboBox" then
		__h = WndComboBox.new(...)
	elseif __type == "RadioBox" then
		__h = WndRadioBox.new(...)
	elseif __type == "CSlider" then
		__h = WndCSlider.new(...)
	elseif __type == "ColorBox" then
		__h = WndColorBox.new(...)
	elseif __type == "Scroll" then
		__h = WndScroll.new(...)
	elseif __type == "UICheckBox" then
		__h = WndUICheckBox.new(...)
	elseif __type == "Handle" then
		__h = ItemHandle.new(...)
	elseif __type == "HoverHandle" then
		__h = ItemHoverHandle.new(...)
	elseif __type == "Text" then
		__h = ItemText.new(...)
	elseif __type == "Image" then
		__h = ItemImage.new(...)
	elseif __type == "Animate" then
		__h = ItemAnimate.new(...)
	elseif __type == "Shadow" then
		__h = ItemShadow.new(...)
	elseif __type == "Box" then
		__h = ItemBox.new(...)
	elseif __type == "TreeLeaf" then
		__h = ItemTreeLeaf.new(...)
	end
	if __h == nil then
		local dg = function(arg0, arg1, arg2)
			Output(arg1, arg2)
		end
		dg(...)
	end
	local __name = __h:GetName()
	self.__items[__name] = __h

	if __type == "Frame" then
		local btn = __h:GetSelf():Lookup("Btn_Close")
		if btn then
			btn.OnLButtonClick = function()
				self:Destroy(__h)
			end
		end
	end
	return __h
end

----------------------------------------------
-- GUI Global Interface
----------------------------------------------
local _API = {
	CreateFrame = WndFrame.new,
	CreateWindow = WndWindow.new,
	CreateWndContainerScroll = WndContainerScroll.new,
	CreateWndContainer = WndContainer.new,
	CreatePageSet = WndPageSet.new,
	CreateButton = WndButton.new,
	CreateEdit = WndEdit.new,
	CreateCheckBox = WndCheckBox.new,
	CreateComboBox = WndComboBox.new,
	CreateRadioBox = WndRadioBox.new,
	CreateCSlider = WndCSlider.new,
	CreateColorBox = WndColorBox.new,
	CreateScroll = WndScroll.new,
	CreateUIButton = WndUIButton.new,
	CreateUICheckBox = WndUICheckBox.new,
	CreateHandle = ItemHandle.new,
	CreateHoverHandle = ItemHoverHandle.new,
	CreateText = ItemText.new,
	CreateImage = ItemImage.new,
	CreateAnimate = ItemAnimate.new,
	CreateShadow = ItemShadow.new,
	CreateBox = ItemBox.new,
	CreateTreeLeaf = ItemTreeLeaf.new,
	CreateAddon = CreateAddon_new,
}

_G2 = {}
do
	for k, v in pairs(_API) do
		_G2[k] = v
	end
end
