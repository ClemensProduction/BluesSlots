AddCSLuaFile("bnz_bear_trap_config.lua")
include("bnz_bear_trap_config.lua")

AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("bnz_beartrap_toggle_arm")
util.AddNetworkString("bnz_beartrap_toggle_disarm")

hook.Add("Move", "bnz_bear_trap_freeze", function(ply, mv)
	if ply.isInTrap then
		mv:SetOrigin(ply.trappedPos)
	end
end)

function ENT:Initialize()
	self:SetModel("models/zerochain/props_industrial/beartrap/beartrap.mdl")
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	local physics = self:GetPhysicsObject()
	if (physics:IsValid()) then
		physics:Wake()
	end

	self:SetAutomaticFrameAdvance(true)
	self:SetUseType(CONTINUOUS_USE)

	self.armed = false
	self.isArming = false
	self.armingPlayer = nil
	self.timeSinceStartedArming = CurTime()

	self.disarmingPlayer = nil
	self.disarming = false
	self.timeSinceStartedDisarming = CurTime()

	self:PlayAnim("bite",5) //high speed to almost instantly close when spawned

	self:SetArmed(false)
	self:SetInUse(false)

	self.playerTraped = false
	self.timeSinceLastTrap = CurTime()

	self.health = 100 //Large health
end	

//Helper functions for playing animations and shit
function ENT:PlayAnim(anim,speed)
  local id = self:LookupSequence(anim)
  self:SetCycle( 0 )
  self:ResetSequence(id)
  self:SetPlaybackRate(speed)
end

function ENT:OnTakeDamage(damage)
	self.health = self.health - damage:GetDamage()
	if self.health <= 0 then
		self:Remove()
	end
end

function ENT:OnRemove()
	if self.playerTraped then
		self.trappedPlayer.isInTrap = false
	end
end


//Handle biting stuff
function ENT:BitePlayer(ply)
	local newPos = ply:GetPos()
	newPos.x = self:GetPos().x
	newPos.y = self:GetPos().y
	ply:SetPos(newPos)

	self.playerTraped = true
	self.trappedPlayer = ply
	ply.isInTrap = true
	ply.trappedPos = newPos
	self:PlayAnim("bite", 1)
	self.timeSinceLastTrap = CurTime()

	ply:SetHealth(math.Clamp(ply:Health() - bnz_bear_trap_config.DamgeToDo, 0, 100))
	if ply:Health() == 0 then
		ply:Kill()
		self.playerTrapped = false
		ply.isInTrap = false
	else
		if bnz_bear_trap_config.MakeScreamSound then
			timer.Simple(0.65, function()
				ply:EmitSound("bnz_bear_trap/scream.ogg", 100, math.random(90,110), 0.9)
			end)
		end
	end
	ply:EmitSound("bnz_bear_trap/bite.ogg", 100, math.random(90,110), 0.9)

	timer.Simple(0.01, function()
		ParticleEffectAttach("bt_ouch_effect",PATTACH_POINT_FOLLOW,self,0)
	end)
end

//Helper for arming trap
function ENT:ArmTrap()
	self.armed = true
	self.isArming = false
	self.armingPlayer = nil
	self:PlayAnim("open", 1)
	self:SetArmed(true)
	self:SetInUse(false)
	self:SetMoveType( MOVETYPE_NONE ) //Disable moving when armed
end

//Just helper for disarming trap
function ENT:DisarmTrap()
	self.armed = false
	self.disarming = false
	self.disarmingPlayer = nil
	self:PlayAnim("bite", 1)
	self:SetArmed(false)
	self:SetInUse(false)
	self.playerTraped = false
	if self.trappedPlayer ~= nil then
		self.trappedPlayer.isInTrap = false
	end
	self:SetMoveType( MOVETYPE_VPHYSICS )
end

function ENT:Think()
	if self.isArming then
		if self.armingPlayer ~= nil then
			local tr = self.armingPlayer:GetEyeTrace()
			if not IsValid(tr.Entity) or tr.Entity ~= self then //They looked away
				self.armed = false
				self.isArming = false
				self.armingPlayer = nil
				self:SetInUse(false)
				self:SetArmed(false)
			end 
			if CurTime() - self.timeSinceStartedArming > bnz_bear_trap_config.ArmAndDisarmTime then
				self:ArmTrap()
			end
		else
			self.armed = false
			self.isArming = false
			self.armingPlayer = nil
			self:SetInUse(false)
			self:SetArmed(false)
		end
	elseif self.disarming then
		if self.disarmingPlayer ~= nil then
			local tr = self.disarmingPlayer:GetEyeTrace()
			if not IsValid(tr.Entity) or tr.Entity ~= self then //They looked away
				self.disarming = false
				self.disarmingPlayer = nil
				self:SetInUse(false)
			end 
			if CurTime() - self.timeSinceStartedDisarming > bnz_bear_trap_config.ArmAndDisarmTime then
				self:DisarmTrap()
			end
		else
			self.disarming = false
			self.disarmingPlayer = nil
			self:SetInUse(false)
		end
	end
end

function ENT:StartTouch(e)
	if self.armed and self.playerTraped == false then
		if e:IsPlayer() then
			if CurTime() - self.timeSinceLastTrap > 3 then
				self:BitePlayer(e)
			end
		end
	end
end

net.Receive("bnz_beartrap_toggle_disarm", function(len, ply)
	local ent = net.ReadEntity()
	local state = net.ReadBool()

	if ent:GetClass() ~= "bnz_bear_trap" then return end //Dont do anything if there no sending us the bear trap
	if ent:GetInUse() then //Dont let them do anything if there not the one using it.
		if ent:GetUsingPlayer() ~= ply then return end
	end

	if state == true then
		if ent.disarming == false and ply:GetPos():Distance(ent:GetPos()) < 100 then
			local tr = ply:GetEyeTrace()
			if tr.Entity ~= ent then return end //Not looking at the entity
			ent.disarmingPlayer = ply
			ent:SetUsingPlayer(ply)
			ent.timeSinceStartedDisarming = CurTime()
			ent.disarming = true
			ent:SetInUse(true)
			player.GetAll()[1]:ChatPrint("Started Disarming")
		end
	else
		//Only reset if it was us who was originaly dearming
		if ent.disarming and ent.disarmingPlayer == ply then
			ent.disarmingPlayer = nil
			ent.disarming = false
			ent.disarmAmount = 0
			ent:SetInUse(false)
		end
	end
end)

net.Receive("bnz_beartrap_toggle_arm", function(len, ply)
	local ent = net.ReadEntity()
	local state = net.ReadBool()

	if ent:GetClass() ~= "bnz_bear_trap" then return end //Dont do anything if there no sending us the bear trap
	if ent:GetInUse() then //Dont let them do anything if there not the one using it.
		if ent:GetUsingPlayer() ~= ply then return end
	end

	if state == true then
		if ent.isArming == false and ply:GetPos():Distance(ent:GetPos()) < 100 then
			local tr = ply:GetEyeTrace()
			if tr.Entity ~= ent then return end //Not looking at the entity
			ent.armingPlayer = ply
			ent:SetUsingPlayer(ply)
			ent.timeSinceStartedArming = CurTime()
			ent.isArming = true
			ent:SetInUse(true)
		end
	else
		//Only reset if it was us who was originaly dearming
		if ent.isArming and ent.armingPlayer == ply then
			ent.armingPlayer = nil
			ent.isArming = false
			ent.disarmAmount = 0
			ent:SetInUse(false)
		end
	end
end)
