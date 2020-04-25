bnz_bear_trap_config = {}

//This is the amount of damage to do to a player if there get trapped.
//If the player dies they will respawn normaly
bnz_bear_trap_config.DamgeToDo = 25

//This is the time in seconds it take to both arm and disarm the trap.
//This is usefull for if someone gets caught in a trap
//the enermy faction hears it and then want to run and kill them before they escape the trap
bnz_bear_trap_config.ArmAndDisarmTime = 5

//If this is true then the player emits the scream sound XD
bnz_bear_trap_config.MakeScreamSound = true


//This is just the code that creates the entry on the F4 menu
//So users can buy it from there, feel free to change or remove this.
DarkRP.createEntity("Bear Trap", {
	ent = "bnz_bear_trap",
	model = "models/zerochain/props_industrial/beartrap/beartrap.mdl",
	price = 5000,
	max = 3,
	cmd = "buybeartrap",
})