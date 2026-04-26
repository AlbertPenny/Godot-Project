extends Panel

signal slot_clicked(slot: Panel)
signal slot_right_clicked(slot: Panel)

const SLOT_SIZE := Vector2(64, 64)

var slot_index: int = -1
var slot_type: String = ""
var _slot_type_text: String = ""

var _icon: TextureRect
var _name_label: Label
var _quantity_label: Label
var _slot_type_label: Label
var _item_texture: Texture2D

func _ready():
	custom_minimum_size = SLOT_SIZE
	size = SLOT_SIZE
	_item_texture = load("res://images/3.png")

	var slot_style = StyleBoxTexture.new()
	slot_style.texture = _item_texture
	slot_style.draw_center = true
	add_theme_stylebox_override("panel", slot_style)

	_icon = TextureRect.new()
	_icon.name = "Icon"
	_icon.anchors_preset = Control.PRESET_CENTER
	_icon.custom_minimum_size = Vector2(48, 48)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.texture = _item_texture
	_icon.modulate = Color.TRANSPARENT
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(_icon)

	_name_label = Label.new()
	_name_label.name = "NameLabel"
	_name_label.anchors_preset = Control.PRESET_CENTER_TOP
	_name_label.anchor_top = 0.15
	_name_label.anchor_bottom = 0.55
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_label.add_theme_font_size_override("font_size", 10)
	_name_label.add_theme_color_override("font_color", Color.WHITE)
	_name_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_name_label.add_theme_constant_override("shadow_offset_x", 1)
	_name_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_name_label)

	_quantity_label = Label.new()
	_quantity_label.name = "QuantityLabel"
	_quantity_label.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	_quantity_label.anchor_left = 0.5
	_quantity_label.anchor_top = 0.65
	_quantity_label.anchor_right = 1.0
	_quantity_label.anchor_bottom = 1.0
	_quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_quantity_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_quantity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quantity_label.add_theme_font_size_override("font_size", 12)
	_quantity_label.add_theme_color_override("font_color", Color.WHITE)
	_quantity_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_quantity_label.add_theme_constant_override("shadow_offset_x", 1)
	_quantity_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_quantity_label)

	_slot_type_label = Label.new()
	_slot_type_label.name = "SlotTypeLabel"
	_slot_type_label.anchors_preset = Control.PRESET_CENTER
	_slot_type_label.anchor_top = 0.3
	_slot_type_label.anchor_bottom = 0.7
	_slot_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_slot_type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_slot_type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slot_type_label.add_theme_font_size_override("font_size", 9)
	_slot_type_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.5))
	add_child(_slot_type_label)
	if _slot_type_text != "":
		_slot_type_label.text = _slot_type_text

	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func set_slot_type_label(text: String):
	if is_inside_tree():
		_slot_type_label.text = text
	else:
		_slot_type_text = text

func update_display(item_id: String, quantity: int):
	if item_id == "":
		_icon.modulate = Color.TRANSPARENT
		_name_label.text = ""
		_quantity_label.text = ""
		return
	var item_def = ItemData.get_item(item_id)
	if item_def == null:
		return
	_icon.modulate = item_def.color
	_name_label.text = item_def.name
	_quantity_label.text = str(quantity) if quantity > 1 else ""

func _get_drag_data(_at_position: Vector2):
	var data = _get_slot_data()
	if data.item_id == "":
		return null
	var preview = _create_drag_preview(data.item_id, data.quantity)
	set_drag_preview(preview)
	_add_highlight(Color(1, 1, 0.3, 0.8))
	return data

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data == null or not data is Dictionary:
		return false
	if not data.has("item_id") or data.item_id == "":
		return false
	if slot_type != "":
		var item_def = ItemData.get_item(data.item_id)
		if item_def == null or item_def.equip_slot != slot_type:
			return false
	return true

func _drop_data(_at_position: Vector2, data: Variant):
	_remove_highlight()
	if data == null or not data is Dictionary:
		return
	var source_type = data.get("source_type", "inventory")
	var source_index = data.get("source_index", -1)
	if source_type == "inventory":
		if slot_type != "":
			Inventory.move_inv_to_equip(source_index, slot_type)
		else:
			Inventory.move_slot_to_slot(source_index, slot_index)
	elif source_type == "equipment":
		if slot_type != "":
			Inventory.unequip_item(data.get("equip_type", ""))
			var inv_idx = _find_slot_for_item(data.item_id)
			if inv_idx >= 0:
				Inventory.equip_item(inv_idx, slot_type)
		else:
			Inventory.move_equip_to_inv(data.get("equip_type", ""), slot_index)

func _get_slot_data() -> Dictionary:
	if slot_type != "":
		var equip_data = Inventory.equipment.get(slot_type)
		if equip_data and not equip_data.is_empty():
			return {"item_id": equip_data.item_id, "quantity": equip_data.quantity, "source_type": "equipment", "equip_type": slot_type}
		return {"item_id": "", "quantity": 0, "source_type": "equipment", "equip_type": slot_type}
	else:
		var slot_data = Inventory.slots[slot_index]
		return {"item_id": slot_data.item_id, "quantity": slot_data.quantity, "source_type": "inventory", "source_index": slot_index}

func _create_drag_preview(item_id: String, quantity: int) -> Control:
	var item_def = ItemData.get_item(item_id)
	var panel = Panel.new()
	panel.custom_minimum_size = SLOT_SIZE
	panel.size = SLOT_SIZE

	var style = StyleBoxTexture.new()
	style.texture = _item_texture
	style.draw_center = true
	panel.add_theme_stylebox_override("panel", style)
	panel.modulate = item_def.color if item_def else Color.MAGENTA

	var qty = Label.new()
	qty.text = str(quantity) if quantity > 1 else ""
	qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	qty.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	qty.anchor_left = 0.5
	qty.anchor_top = 0.65
	qty.mouse_filter = Control.MOUSE_FILTER_IGNORE
	qty.add_theme_font_size_override("font_size", 12)
	qty.add_theme_color_override("font_color", Color.WHITE)
	qty.add_theme_color_override("font_shadow_color", Color.BLACK)
	qty.add_theme_constant_override("shadow_offset_x", 1)
	qty.add_theme_constant_override("shadow_offset_y", 1)
	panel.add_child(qty)
	return panel

func _find_slot_for_item(item_id: String) -> int:
	for i in Inventory.slots.size():
		if Inventory.slots[i].item_id == item_id:
			return i
	for i in Inventory.slots.size():
		if Inventory.slots[i].is_empty():
			return i
	return -1

func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		_remove_highlight()

func _add_highlight(color: Color):
	var highlight = StyleBoxTexture.new()
	highlight.texture = _item_texture
	highlight.draw_center = true
	add_theme_stylebox_override("panel", highlight)
	modulate = color

func _remove_highlight():
	var style = StyleBoxTexture.new()
	style.texture = _item_texture
	style.draw_center = true
	add_theme_stylebox_override("panel", style)
	modulate = Color.WHITE

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			slot_clicked.emit(self)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			slot_right_clicked.emit(self)
