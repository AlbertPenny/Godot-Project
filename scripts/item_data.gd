extends Node

class Item:
	var id: String
	var name: String
	var color: Color
	var max_stack: int
	var item_type: String  # "consumable" / "equipment" / "material"
	var equip_slot: String # "helmet" / "armor" / "weapon" / "boots" / ""
	var description: String

	func _init(p_id: String, p_name: String, p_color: Color, p_max_stack: int, p_type: String, p_slot: String, p_desc: String):
		id = p_id
		name = p_name
		color = p_color
		max_stack = p_max_stack
		item_type = p_type
		equip_slot = p_slot
		description = p_desc

var _items: Dictionary = {}

func _ready():
	_add_item("health_potion", "生命药水", Color.CRIMSON, 10, "consumable", "", "恢复30点生命值")
	_add_item("mana_potion", "魔法药水", Color.DODGER_BLUE, 10, "consumable", "", "恢复20点魔法值")
	_add_item("iron_helmet", "铁头盔", Color.SILVER, 1, "equipment", "helmet", "防御+5 普通的铁头盔")
	_add_item("leather_armor", "皮甲", Color.BROWN, 1, "equipment", "armor", "防御+12 轻便的皮甲")
	_add_item("iron_sword", "铁剑", Color.LIGHT_GRAY, 1, "equipment", "weapon", "攻击+10 锋利的铁剑")
	_add_item("speed_boots", "疾风靴", Color.MEDIUM_SEA_GREEN, 1, "equipment", "boots", "速度+3 轻盈的靴子")
	_add_item("wood", "木材", Color.SANDY_BROWN, 20, "material", "", "基础建材")
	_add_item("stone", "石材", Color.DIM_GRAY, 20, "material", "", "坚固的石材")
	_add_item("gold_coin", "金币", Color.GOLD, 99, "material", "", "闪闪发光的金币")

func _add_item(id: String, item_name: String, color: Color, max_stack: int, type: String, slot: String, desc: String):
	_items[id] = Item.new(id, item_name, color, max_stack, type, slot, desc)

func get_item(id: String) -> Item:
	return _items.get(id)

func get_all_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in _items:
		ids.append(id)
	return ids
