--- warden library
-- @name warden
-- @class library
-- @libtbl warden_library
SF.RegisterLibrary("warden")

local permReq
if SERVER then 
	permReq = SF.BurstObject("warden_permission_request", "permReq", 10, 10, "permission requests per second", "maximum permission requests per second")
end

return function(instance)
	local env = instance.env

	--- warden permissions enums
	-- @name builtins_library.PERMISSION
	-- @class table
	-- @field ALL
	-- @field TOOL
	-- @field PHYSGUN
	-- @field GRAVGUN
	-- @field USE
	-- @field DAMAGE
	local PERMISSION = {
		["ALL"] = Warden.PERMISSION_ALL,
		["TOOL"] = Warden.PERMISSION_TOOL,
		["PHYSGUN"] = Warden.PERMISSION_PHYSGUN,
		["GRAVGUN"] = Warden.PERMISSION_GRAVGUN,
		["USE"] = Warden.PERMISSION_USE,
		["DAMAGE"] = Warden.PERMISSION_DAMAGE
	}
	env.PERMISSION = PERMISSION

	local permissionLookup = {
		[Warden.PERMISSION_ALL] = PERMISSION.ALL,
		[Warden.PERMISSION_TOOL] = PERMISSION.TOOL,
		[Warden.PERMISSION_PHYSGUN] = PERMISSION.PHYSGUN,
		[Warden.PERMISSION_GRAVGUN] = PERMISSION.GRAVGUN,
		[Warden.PERMISSION_USE] = PERMISSION.USE,
		[Warden.PERMISSION_DAMAGE] = PERMISSION.DAMAGE
	}

	-- Global to all starfalls
	local checkluatype = SF.CheckLuaType
	local checkvalidnumber = SF.CheckValidNumber
	local registerprivilege = SF.Permissions.registerPrivilege
	local ENT_META = FindMetaTable("Entity")
	local PLY_META = FindMetaTable("Player")

	local Ent_IsValid = ENT_META.IsValid
	local player_methods, player_meta, wrap, unwrap = instance.Types.Player.Methods, instance.Types.Player, instance.Types.Player.Wrap, instance.Types.Player.Unwrap
	local owrap, ounwrap = instance.WrapObject, instance.UnwrapObject
	local ent_meta, ewrap, eunwrap = instance.Types.Entity, instance.Types.Entity.Wrap, instance.Types.Entity.Unwrap
	local vec_meta, vwrap, vunwrap = instance.Types.Vector, instance.Types.Vector.Wrap, instance.Types.Vector.Unwrap
	local ang_meta, awrap, aunwrap = instance.Types.Angle, instance.Types.Angle.Wrap, instance.Types.Angle.Unwrap
	local wep_meta, wwrap, wunwrap = instance.Types.Weapon, instance.Types.Weapon.Wrap, instance.Types.Weapon.Unwrap
	local veh_meta, vhwrap, vhunwrap = instance.Types.Vehicle, instance.Types.Vehicle.Wrap, instance.Types.Vehicle.Unwrap

	local function getply(self)
		local ent = player_meta.sf2sensitive[self]
		if Ent_IsValid(ent) then
			return ent
		else
			SF.Throw("Entity is not valid.", 3)
		end
	end

	local warden_library = instance.Libraries.warden

	--- Check the permissions between a player and an entity
	-- @shared
	-- @param Player player The player 
	-- @param entity entity The entity getting checked
	-- @param number permission The permission to check for see. see the PERMISSION enums
	-- @return boolean If the player has permissions with the entity
	function warden_library.checkPermission(ply, ent, permission)
		local p = getply(ply)
		local e = eunwrap(ent)
		if not permissionLookup[permission] then SF.Throw("Invalid permission!") end
		return Warden.CheckPermission(p, e, permission)
	end

	--- Check the permissions between a player and an entity
	-- @shared
	-- @param entity entity The entity getting checked
	-- @param number permission The permission to check for see. see the PERMISSION enums
	-- @return boolean If the player has permissions with the entity
	function player_methods:checkPermission(ent, permission) 
		return warden_library.checkPermission(self, ent, permission)
	end

	if SERVER then 
		--- Grant permisisons to a player
		-- @server
		-- @param Player player the player you're giving permissions to
		-- @param number permission the permission you're granting. check PERMISSION
		-- @param boolean val False to revoke permission, True to grant permission
		function warden_library.permissionRequest(ply, perm, val)
			local p = getply(ply)
			checkluatype(perm, TYPE_NUMBER)
			checkluatype(val, TYPE_BOOL)
			if not permissionLookup[perm] then SF.Throw("Invalid permission!") end
			permReq:use(instance.player, 1)
			
			Warden.PermissionRequest(instance.player, p, val, perm)
		end

		--- Check how many requests you have left
		-- @server
		function warden_library.checkRequestsLeft()
			return math.floor(permReq:check(instance.player))
		end

		--- ADMINONLY set adminlevel 
		-- @server
		-- @param number level The admin level
		-- @param Player? otherPly SUPERADMIN+ Set the adminlevel of another admin
		function warden_library.setAdminLevel(level, otherPly)
			checkluatype(level, TYPE_NUMBER)

			local ply = instance.player 
			if not ply:IsAdmin() then SF.Throw("You are not an admin!") end
			
			if level < 0 or 4 < level then SF.Throw("Invalid admin level!") end 

			if otherPly then 
				local p = getply(otherPly)
				if not ply:IsSuperAdmin() then SF.Throw("You can not set the admin level of others! (superadmin+)") end
				if not p:IsAdmin() then SF.Throw("Player is not an admin!") end

				p:WardenSetAdminLevel(level)
				return 
			end

			ply:WardenSetAdminLevel(level)
		end

		--- ADMINONLY set adminlevel 
		-- @param number level The admin level
		function player_methods:setAdminLevel(level) 
			warden_library.setAdminLevel(level, self)
		end
	end
end --EOF

