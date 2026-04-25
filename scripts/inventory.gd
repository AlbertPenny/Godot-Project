extends Node

signal inventory_changed
signal equipment_changed

const SLOT_COUNT := 20

class SlotData:
	var item_id: String = ""
	var quantity: int = 0

	func is_empty() -> bool:
		return item_id == ""

	func clear():
		item_id = ""
		quantity = 0

var slots: Array[SlotData] = []
var equipment: Dictionary = {}  # slot_type -> SlotData

func _ready():
	for i in SLOT_COUNT:
		slots.append(SlotData.new())
	for slot_type in ["helmet", "armor", "weapon", "boots"]:
		equipment[slot_type] = SlotData.new()

func add_item(item_id: String, amount: int = 1) -> bool:
	var item_def = ItemData.get_item(item_id)
	if item_def == null:
		return false

	var remaining = amount
	# 先尝试堆叠到已有格子
	for slot in slots:
		if slot.item_id == item_id and slot.quantity < item_def.max_stack:
			var can_add = mini(remaining, item_def.max_stack - slot.quantity)
			slot.quantity += can_add
			remaining -= can_add
			if remaining <= 0:
				inventory_changed.emit()
				return true
	# 再尝试放入空格子
	for slot in slots:
		if slot.is_empty():
			var can_add = mini(remaining, item_def.max_stack)
			slot.item_id = item_id
			slot.quantity = can_add
			remaining -= can_add
			if remaining <= 0:
				inventory_changed.emit()
				return true
	inventory_changed.emit()
	return remaining < amount

func remove_item_from_slot(slot_index: int, amount: int = 1):
	if slot_index < 0 or slot_index >= slots.size():
		return
	var slot = slots[slot_index]
	if slot.is_empty():
		return
	slot.quantity -= amount
	if slot.quantity <= 0:
		slot.clear()
	inventory_changed.emit()

func move_slot_to_slot(from: int, to: int):
	if from == to:
		return
	var src = slots[from]
	var dst = slots[to]
	if src.is_empty():
		return
	# 同类物品堆叠
	if not dst.is_empty() and src.item_id == dst.item_id:
		var item_def = ItemData.get_item(src.item_id)
		var can_stack = mini(src.quantity, item_def.max_stack - dst.quantity)
		if can_stack > 0:
			dst.quantity += can_stack
			src.quantity -= can_stack
			if src.quantity <= 0:
				src.clear()
		else:
			# 已满则交换
			var tmp_id = dst.item_id
			var tmp_qty = dst.quantity
			dst.item_id = src.item_id
			dst.quantity = src.quantity
			src.item_id = tmp_id
			src.quantity = tmp_qty
	else:
		# 交换
		var tmp_id = dst.item_id
		var tmp_qty = dst.quantity
		dst.item_id = src.item_id
		dst.quantity = src.quantity
		src.item_id = tmp_id
		src.quantity = tmp_qty
	inventory_changed.emit()

func equip_item(slot_index: int, equip_type: String) -> bool:
	var inv_slot = slots[slot_index]
	if inv_slot.is_empty():
		return false
	var item_def = ItemData.get_item(inv_slot.item_id)
	if item_def.equip_slot != equip_type:
		return false
	var equip_slot_data = equipment[equip_type]
	# 交换：卸下当前装备到背包格，穿上新装备
	if not equip_slot_data.is_empty():
		var tmp_id = equip_slot_data.item_id
		var tmp_qty = equip_slot_data.quantity
		equip_slot_data.item_id = inv_slot.item_id
		equip_slot_data.quantity = inv_slot.quantity
		inv_slot.item_id = tmp_id
		inv_slot.quantity = tmp_qty
	else:
		equip_slot_data.item_id = inv_slot.item_id
		equip_slot_data.quantity = inv_slot.quantity
		inv_slot.clear()
	inventory_changed.emit()
	equipment_changed.emit()
	return true

func unequip_item(equip_type: String) -> bool:
	var equip_slot_data = equipment[equip_type]
	if equip_slot_data.is_empty():
		return false
	# 找空格子放回去
	for slot in slots:
		if slot.is_empty():
			slot.item_id = equip_slot_data.item_id
			slot.quantity = equip_slot_data.quantity
			equip_slot_data.clear()
			inventory_changed.emit()
			equipment_changed.emit()
			return true
	# 尝试堆叠
	for slot in slots:
		if slot.item_id == equip_slot_data.item_id:
			var item_def = ItemData.get_item(equip_slot_data.item_id)
			var can_stack = mini(equip_slot_data.quantity, item_def.max_stack - slot.quantity)
			if can_stack > 0:
				slot.quantity += can_stack
				equip_slot_data.quantity -= can_stack
				if equip_slot_data.quantity <= 0:
					equip_slot_data.clear()
					inventory_changed.emit()
					equipment_changed.emit()
					return true
	return false

func move_inv_to_equip(inv_index: int, equip_type: String) -> bool:
	return equip_item(inv_index, equip_type)

func move_equip_to_inv(equip_type: String, inv_index: int):
	var equip_slot_data = equipment[equip_type]
	var inv_slot = slots[inv_index]
	if equip_slot_data.is_empty():
		return
	if inv_slot.is_empty():
		inv_slot.item_id = equip_slot_data.item_id
		inv_slot.quantity = equip_slot_data.quantity
		equip_slot_data.clear()
	elif inv_slot.item_id == equip_slot_data.item_id:
		var item_def = ItemData.get_item(equip_slot_data.item_id)
		var can_stack = mini(equip_slot_data.quantity, item_def.max_stack - inv_slot.quantity)
		if can_stack > 0:
			inv_slot.quantity += can_stack
			equip_slot_data.quantity -= can_stack
			if equip_slot_data.quantity <= 0:
				equip_slot_data.clear()
	else:
		# 交换
		var tmp_id = inv_slot.item_id
		var tmp_qty = inv_slot.quantity
		inv_slot.item_id = equip_slot_data.item_id
		inv_slot.quantity = equip_slot_data.quantity
		# 只允许装备类放回装备槽
		var tmp_def = ItemData.get_item(tmp_id)
		if tmp_def and tmp_def.equip_slot == equip_type:
			equip_slot_data.item_id = tmp_id
			equip_slot_data.quantity = tmp_qty
		else:
			# 不匹配，找空位放回去
			equip_slot_data.clear()
			add_item(tmp_id, tmp_qty)
	inventory_changed.emit()
	equipment_changed.emit()
