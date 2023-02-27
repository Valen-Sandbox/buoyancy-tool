local language_Add = CLIENT and language.Add
local IsValid = IsValid
local math_Clamp = math.Clamp
local duplicator_StoreEntityModifier = SERVER and duplicator.StoreEntityModifier
local duplicator_RegisterEntityModifier = duplicator.RegisterEntityModifier
local timer_Simple = timer.Simple
local hook_Add = hook.Add

TOOL.Category		= "Construction"
TOOL.Name			= "#Buoyancy"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Information	= {
	{ name = "left" },
	{ name = "right" }
}

if CLIENT then
	language_Add( "tool.rt_buoyancy.name", "Buoyancy" )
	language_Add( "tool.rt_buoyancy.desc", "Make things float" )
	language_Add( "tool.rt_buoyancy.left", "Set buoyancy value" )
	language_Add( "tool.rt_buoyancy.right", "Copy buoyancy value")
end

TOOL.ClientConVar[ "ratio" ] = "0"

local function setBuoyancy( ply, ent, data )
	local phys = ent:GetPhysicsObject()

	if IsValid( phys ) then
		local ratio = math_Clamp( data.Ratio, -1000, 1000 ) / 100
		ent.BuoyancyRatio = ratio
		phys:SetBuoyancyRatio( ratio )
		phys:Wake()

		duplicator_StoreEntityModifier( ent, "buoyancy", data )
	end

	return true
end
duplicator_RegisterEntityModifier( "buoyancy", setBuoyancy )

function TOOL:LeftClick( trace )
	local ent = trace.Entity
	if not ent or not IsValid( ent ) then return false end
	if CLIENT then return true end

	setBuoyancy( self:GetOwner(), ent, { Ratio = self:GetClientNumber( "ratio" ) } )

	return true
end

function TOOL:RightClick( trace )
	local ent = trace.Entity
	if not ent or not IsValid( ent ) then return false end
	if CLIENT then return true end

	local ply = self:GetOwner()
	ply:ConCommand( "rt_buoyancy_ratio " .. ( ( ent.BuoyancyRatio or 0 ) * 100 ) )

	return true
end

function TOOL.BuildCPanel( panel )
	panel:NumSlider( "Percent", "rt_buoyancy_ratio", 0, 100 )
end

if SERVER then
	local function set( phys, ratio )
		if not IsValid( phys ) then return end
		phys:SetBuoyancyRatio( ratio )
	end

	local function onDrop( ply, ent )
		if not ent.BuoyancyRatio then return end

		local phys = ent:GetPhysicsObject()
		if not IsValid( phys ) then return end

		timer_Simple( 0, function() set( phys, ent.BuoyancyRatio ) end)
	end
	hook_Add( "PhysgunDrop", "rt_buoyancy", onDrop )
	hook_Add( "GravGunOnDropped", "rt_buoyancy", onDrop )
end