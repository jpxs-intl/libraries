--- Weapon Manager [customitems]
---@class WeaponManager
WeaponManager = WeaponManager or {}

---@type Enum.sound[][]
WeaponManager.soundOverrideQueue = {}

--- INTERNAL | Loads hooks for the weapon manager
---@param plugin Plugin
function WeaponManager.loadHooks(plugin)
	hook.add("BulletCreate", "customItems.weaponManager", function(type, pos, vel, player)
		local man = player.human
		if player == nil or man == nil then
			return
		end
		local hand = (bit32.band(player.inputFlags, enum.input.shift) == enum.input.shift and 1 or 0)
		local item = man:getInventorySlot(hand).primaryItem

		if item and item.isActive and item.data.CustomWeapon and not item.data.CustomWeapon.isVanillaItem then
			---@type CustomWeapon
			local customWeapon = item.data.CustomWeapon

			customWeapon.eventEmitter:emit("weaponPlayerFire", item, player)
			return customWeapon.overrideHooks and hook.override or hook.continue
		end
	end)

	hook.add("PostBulletCreate", "customItems.weaponManager", function(bullet)
		if bullet.player and bullet.player.human then
			local hand = (bit32.band(bullet.player.inputFlags, enum.input.shift) == enum.input.shift and 1 or 0)
			local item = bullet.player.human:getInventorySlot(hand).primaryItem

			if item and item.isActive and item.data.CustomWeapon and not item.data.CustomWeapon.isVanillaItem then
				---@type CustomWeapon
				local customWeapon = item.data.CustomWeapon
				customWeapon.eventEmitter:emit("weaponBullet", item, bullet)
			end
		end
	end)

	hook.add("EventBullet", "customItems.weaponManager", function(type, pos, vel, item)
		if item and item.data.CustomWeapon and not item.data.CustomWeapon.isVanillaItem then
			return hook.override
		end
	end)

	hook.add("ItemLink", "customItems.weaponManager", function(item, childItem, parentHuman, slot)
		if
			not item
			or not childItem
			or not item.data.CustomWeapon
			or item.data.CustomWeapon.isVanillaItem
			or not childItem.data.CustomAmmo
		then
			return
		end

		---@type CustomWeapon
		local customWeapon = item.data.CustomWeapon
		---@type CustomAmmo
		local customAmmo = childItem.data.CustomAmmo

		if not customWeapon.allowedReloadItems[customAmmo.id] then
			return hook.override
		end

		customWeapon.eventEmitter:emit("weaponPlayerReload", item, item.parentHuman.player)
	end)
end

return WeaponManager
