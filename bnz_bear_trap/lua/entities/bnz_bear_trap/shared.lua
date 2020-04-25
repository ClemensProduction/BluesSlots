ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Bear Trap"
ENT.Spawnable = true
ENT.Category = "Blue 'n' Zero"

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "Armed" )
	self:NetworkVar( "Bool", 1, "InUse" )
	self:NetworkVar( "Entity", 0, "UsingPlayer" )
end