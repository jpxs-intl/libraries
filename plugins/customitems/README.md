# plugins/customitems

Allows you to create "custom items" that have custom behavior.

## Requirements

Latest version of [jpxs/RosaServerCore](https://github.com/jpxs-intl/RosaServerCore) and [jpxs/RosaServer](https://github.com/jpxs-intl/RosaServer).

     - lib/classic
     - lib/eventEmitter
     - lib/loader
     - plugins/libUtil

## Commands

### `/customitem <itemId>` 
Gives you a custom item with the specified ID. The item's folder structure determines the ID. if the item is in `customitems/namespaces/jpxs/weapon/sniper`, the ID is `jpxs.weapon.sniper`.

    /cit jpxs.weapon.sniper
    /cit jpxs.ammo.smg

You can also spawn vanilla items using this system.
    
    /cit subrosa.box

### API

### ItemManager

Custom items can be created by making a new lua file in the namespaces folder. See the example files for more information.

customitems exposes a global `ItemManager` object that can be used to create custom items.

```lua
local item = ItemManager.spawnItem("jpxs.weapon.sniper", Vector(), oreintations.n)
assert(item, "Failed to spawn item")
ply:mountItem(item, 0)
```

Again, you can also spawn vanilla items using this system.

```lua
local item = ItemManager.spawnItem("subrosa.box", Vector(), oreintations.n)
assert(item, "Failed to spawn item")
ply:mountItem(item, 0)
```

### CustomItem

Events are like hooks for custom items. They are called when certain actions are performed on the item.

```lua
local customItem = CustomItem:new("Example Item", enum.item.box)

customItem:on("create", function(item)
    print(string.format("Item was created at index %s", item.index))
end)
```

**Events**

- `create` - Called when the item is created.
- `remove` - Called when the item is removed.
- `playerPickupItem` - Called when a player picks up the item.
- `playerDropItem` - Called when a player drops the item.
- `logic` - Called every tick, during logic.
- `physics` - Called every tick, during physics.

### CustomWeapon

**Events**

These are assigned using `onWeapon` instead of `on`.

- `weaponPlayerFire` - Called when the player fires the weapon.
- `weaponPlayerReload` - Called when the player reloads the weapon.
- `weaponBullet` - Called when a bullet is created.