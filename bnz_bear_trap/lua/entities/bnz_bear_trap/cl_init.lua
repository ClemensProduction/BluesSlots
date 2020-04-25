include("bnz_bear_trap_config.lua")
include("shared.lua")

surface.CreateFont( "bnz_bear_trap_ui", {
	font = "Roboto",
	extended = false,
	size = 30,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )

surface.CreateFont( "bnz_bear_trap_ui_2", {
	font = "Roboto",
	extended = false,
	size = 25,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )

local triggeredKeyRelease = true

hook.Add("Move", "bnz_bear_trap_handle_toggle", function(ply)
	if ply == LocalPlayer() then
		if input.WasKeyPressed(KEY_E) then
			local tr = LocalPlayer():GetEyeTrace()
			if tr.Entity ~= nil and tr.Entity:GetClass() == "bnz_bear_trap" then
				tr.Entity:OnBeginUse()
			end
			triggeredKeyRelease = false
		end

		//Apprently input.WasKeyRelease does not work? So gotta do this bullshit
		if not input.IsKeyDown(KEY_E) and not triggeredKeyRelease then
			triggeredKeyRelease = true
			local tr = LocalPlayer():GetEyeTrace()
			if tr.Entity ~= nil and tr.Entity:GetClass() == "bnz_bear_trap" then
				tr.Entity:OnStopUse()
			end
		end
	end
end)

local actionInProgress = false
local timeSinceActionStarted = CurTime()
local actionIsArming = false //True for disarm
local actionEntity = nil //The entity the action is based on

local function LerpColor(t, c1, c2)
	local c3 = Color(0,0,0)
	c3.r = Lerp(t, c1.r , c2.r)
	c3.g = Lerp(t, c1.g , c2.g)
	c3.b = Lerp(t, c1.b , c2.b)
	c3.a = Lerp(t, c1.a , c2.a)
	return c3
end

local progress_forground = Material("materials/bnz_ui/progress_forground.png", "smooth")

hook.Add("HUDPaint", "bnz_draw_progress_info", function()
	local timeToPerformAction = bnz_bear_trap_config.ArmAndDisarmTime
	if actionInProgress then
		if actionEntity == nil or actionEntity == NULL then
			actionInProgress = false
		else
			if actionEntity:GetInUse() then
				local progress = math.Clamp(CurTime() - timeSinceActionStarted, 0, timeToPerformAction) / timeToPerformAction

				draw.RoundedBox(0,ScrW()/2 - 190, ScrH()/2 + 55, 380, 65 - 18, Color(0,0,0,255))
				if actionIsArming then
					draw.RoundedBox(0,ScrW()/2 - 190, ScrH()/2 + 55, Lerp(progress, 0, 380), 65 - 18, LerpColor(progress, Color(30,180,30), Color(180,30,30)))
					surface.SetDrawColor(Color(255,255,255,255))
					surface.SetMaterial(progress_forground)
					surface.DrawTexturedRect(ScrW()/2 - 200, ScrH()/2 + 45, 400, 65)
					draw.NoTexture()
					draw.SimpleText("Arming Bear Trap", "bnz_bear_trap_ui", ScrW()/2 + 2, ScrH()/2 + (45 + (65/2)) + 2, Color(0,0,0,255), 1 , 1)
					draw.SimpleText("Arming Bear Trap", "bnz_bear_trap_ui", ScrW()/2 , ScrH()/2 + (45 + (65/2)), Color(225,225,225,255), 1 , 1)
				else
					draw.RoundedBox(0,ScrW()/2 - 190, ScrH()/2 + 55, Lerp(progress, 0, 380), 65 - 18, LerpColor(progress, Color(180,30,30), Color(30,180,30)))
					surface.SetDrawColor(Color(255,255,255,255))
					surface.SetMaterial(progress_forground)
					surface.DrawTexturedRect(ScrW()/2 - 200, ScrH()/2 + 45, 400, 65)
					draw.NoTexture()
					draw.SimpleText("Disarming Bear Trap", "bnz_bear_trap_ui", ScrW()/2 + 2, ScrH()/2 + (45 + (65/2)) + 2, Color(0,0,0,255), 1 , 1)
					draw.SimpleText("Disarming Bear Trap", "bnz_bear_trap_ui", ScrW()/2 , ScrH()/2 + (45 + (65/2)), Color(225,225,225,255), 1 , 1)
				end
			end
		end
	else
		local tr = LocalPlayer():GetEyeTrace()
		if not tr.HitWorld and tr.Entity ~= NULL and tr.Entity:GetClass() == "bnz_bear_trap" then
			if not tr.Entity:GetInUse() and LocalPlayer():GetPos():Distance(tr.Entity:GetPos()) <= 100 then
				if tr.Entity:GetArmed() then
					draw.SimpleText("Hold 'E' to disarm trap.", "bnz_bear_trap_ui", ScrW()/2 + 2, ScrH()/2 + (45 + (65/2)) + 2, Color(0,0,0,255), 1 , 1)
					draw.SimpleText("Hold 'E' to disarm trap.", "bnz_bear_trap_ui", ScrW()/2 , ScrH()/2 + (45 + (65/2)), Color(245,245,245,255), 1 , 1)
				else
					draw.SimpleText("Hold 'E' to arm trap.", "bnz_bear_trap_ui", ScrW()/2 + 2, ScrH()/2 + (45 + (65/2)) + 2, Color(0,0,0,255), 1 , 1)
					draw.SimpleText("Hold 'E' to arm trap.", "bnz_bear_trap_ui", ScrW()/2 , ScrH()/2 + (45 + (65/2)), Color(245,245,245,255), 1 , 1)
				end
			end
		end
	end
end)

function ENT:OnBeginUse()
	print("Should trigger event")
	if LocalPlayer():GetPos():Distance(self:GetPos()) > 100 then return end

	if self:GetInUse() then //Dont let them do anything if there not the one using it.
		if self:GetUsingPlayer() ~= LocalPlayer() then return end
	end

	if self:GetArmed() then
		LocalPlayer():ChatPrint("Starting disarm")
		net.Start("bnz_beartrap_toggle_disarm")
		net.WriteEntity(self)
		net.WriteBool(true)
		net.SendToServer()
		actionInProgress = true
		timeSinceActionStarted = CurTime()
		actionIsArming = false
		actionEntity = self
	else
		LocalPlayer():ChatPrint("Starting arm")
		net.Start("bnz_beartrap_toggle_arm")
		net.WriteEntity(self)
		net.WriteBool(true)
		net.SendToServer()
		actionInProgress = true
		timeSinceActionStarted = CurTime()
		actionIsArming = true
		actionEntity = self
	end
end

function ENT:OnStopUse()
	if self:GetInUse() then //Dont let them do anything if there not the one using it.
		if self:GetUsingPlayer() ~= LocalPlayer() then return end
	end

	if self:GetArmed() then
		LocalPlayer():ChatPrint("Starting disarm")
		net.Start("bnz_beartrap_toggle_disarm")
		net.WriteEntity(self)
		net.WriteBool(false)
		net.SendToServer()
		actionInProgress = false
	else
		net.Start("bnz_beartrap_toggle_arm")
		net.WriteEntity(self)
		net.WriteBool(false)
		net.SendToServer()
		actionInProgress = false
	end
end

function ENT:Initialize()
	self:SetAutomaticFrameAdvance(true)
end

function ENT:Draw()
	self:DrawModel()
end
