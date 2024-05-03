local CustomItem = require("plugins.customitems.classes.CustomItem")
local SoundUtil = require("plugins.libutil.sound")
local VectorUtil = require("plugins.libutil.vector")

---Represents a custom weapon.
---@class CustomWeapon : CustomItem
---@field super CustomItem
---@field overrideHooks boolean
---@field allowedReloadItems table<string, boolean>
---@field maxAmmo integer
---@field bulletVelocity number
---@field bulletSpread number
---@field bulletType Enum.bullet
---@field sound Enum.sound | Enum.sound[]
---@field soundVolume number
---@field soundPitch number
---@field fireRate number
---@field onWeapon fun(self: CustomWeapon, eventName: "weaponPlayerFire", func: fun(item: Item, player: Player, position: Vector, velocity: Vector))
---@field onWeapon fun(self: CustomWeapon, eventName: "weaponBullet", func: fun(item: Item, bullet: Bullet))
---@field onWeapon fun(self: CustomWeapon, eventName: "weaponPlayerReload", func: fun(item: Item, player: Player))
local CustomWeapon = CustomItem:extend()

---Creates a new custom weapon.
---@param name string
---@param baseItem Enum.item
---@return CustomWeapon
function CustomWeapon:new(name, baseItem)
	---@type CustomWeapon
	---@diagnostic disable-next-line: assign-type-mismatch
	local item = self.super.new(self, name, baseItem)

	item.super = CustomWeapon
	item.overrideHooks = true
	item.allowedReloadItems = {}
	item.maxAmmo = 0
	item.isWeapon = true
	item.isVanillaItem = false
	setmetatable(item, self)

	return item
end

---Spawns the custom weapon.
---@param pos Vector
---@param rot RotMatrix
function CustomWeapon:spawn(pos, rot)
	local item = items.create(itemTypes[self.baseItem], pos, rot)
	assert(item, "Failed to create item")
	self:addCustomWeaponData(item)
	self:addCustomItemData(item)

	self.eventEmitter:emit("create", item)
	return item
end

---Adds an event listener to the custom weapon.
function CustomWeapon:onWeapon(eventName, func)
	self.eventEmitter:on(eventName, func)
end

---Adds needed custom weapon data to the item.
---@param item Item
function CustomWeapon:addCustomWeaponData(item)
	self:addCustomItemData(item)
	item.data.CustomWeapon = self
end

---Add an ammo item to the list of allowed reload items.
---@param ammoId string
function CustomWeapon:allowReloadItem(ammoId)
	self.allowedReloadItems[ammoId] = true

	---@type ItemType
	local weaponItemType = itemTypes[self.baseItem]

	local ammoCustomItem = ItemManager.getItem(ammoId)

	if not ammoCustomItem then
		-- defer until after items are loaded, then try again
		ItemManager.eventEmitter:once("PostLoad", function()
			ammoCustomItem = ItemManager.getItem(ammoId)
			if not ammoCustomItem then
				error("Ammo item not found, id: " .. ammoId)
			end

			self:allowReloadItem(ammoId)
		end)

		return
	end

	---@type ItemType
	local ammoItemType = itemTypes[ammoCustomItem.baseItem]

	print("Allowing reload for", ammoItemType.name, "to", weaponItemType.name)
	print("Allowing reload for", self.id, "to", ammoId)

	if not ammoItemType:getCanMountTo(weaponItemType) then
		ammoItemType:setCanMountTo(weaponItemType, true)
	end
end

---Fires a bullet from the weapon.
---@param item Item
---@param player Player
---@param accuracy number? Current accuracy, 0-1, 1 being 100% accurate (no spread), 0 being spread accuracy. default: 0
---@param dontConsumeAmmo boolean? If true, the weapon will not consume ammo. default: false
function CustomWeapon:fireBullet(item, player, accuracy, dontConsumeAmmo)
	accuracy = accuracy or 0

	if item.bullets <= 0 then
		return
	end

	local bulletType = self.bulletType
	local position = item.pos:clone()

	local spread = vecRandBetween(-VectorUtil.cubedVector(self.bulletSpread), VectorUtil.cubedVector(self.bulletSpread))
		* (1 - accuracy)

	local velocity = (item.rot:forwardUnit() * self.bulletVelocity) + item.rigidBody.vel + spread

	SoundUtil.createRandom(
		self.sound and (type(self.sound) == "table" and self.sound or { self.sound }) or enum.sound.weapon.m16,
		position,
		self.soundVolume or 1,
		self.soundPitch or 1
	)

	events.createBullet(self.bulletType, position, velocity, item)
	-- WeaponManager.addWeaponToSoundQueue(self.baseItem)

	local mag = item:getChildItem(0)
	if not dontConsumeAmmo and mag and mag.bullets > 0 then
		mag.bullets = mag.bullets - 1
	end

	hook.run("PostBulletCreate", bullets.create(bulletType, position, velocity, player))

	if self.fireRate then
		item.cooldown = self.fireRate
	end
end

function CustomWeapon:__tostring()
	return string.format("CustomWeapon(%s)", self.id)
end

return CustomWeapon
