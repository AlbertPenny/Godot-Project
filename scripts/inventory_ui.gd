extends Control

const SLOT_SCENE = preload("res://scenes/slot.tscn")

@onready var inv_grid: GridContainer = $MainHBox/InventoryPanel/InvVBox/InvGrid
@onready var equip_slots_vbox: VBoxContainer = $MainHBox/EquipmentPanel/EquipVBox/EquipSlots
@onready var popup_menu: PopupMenu = $PopupMenu
@onready var tooltip_panel: PanelContainer = $Tooltip
@onready var tooltip_title: Label = $Tooltip/TooltipVBox/TooltipTitle
@onready var tooltip_desc: Label = $Tooltip/TooltipVBox/TooltipDesc
@onready var tooltip_type: Label = $Tooltip/TooltipVBox/TooltipType
@onready var pickup_btn: Button = $BottomBar/PickupButton
@onready var clear_btn: Button = $BottomBar/ClearButton

var inv_slots: Array[Panel] = []
var equip_slots: Dictionary = {}
var _popup_slot: Panel = null

func _ready():
	_setup_panel_styles()
	_create_inventory_slots()
	_create_equipment_slots()

	pickup_btn.pressed.connect(_on_pickup)
	clear_btn.pressed.connect(_on_clear)
	popup_menu.id_pressed.connect(_on_popup_id)

	Inventory.inventory_changed.connect(_refresh_all)
	Inventory.equipment_changed.connect(_refresh_all)
	_refresh_all()

func _setup_panel_styles():
	var texture = load("res://images/3.png")

	var inv_style = StyleBoxTexture.new()
	inv_style.texture = texture
	inv_style.draw_center = true
	inv_style.content_margin_left = 16
	inv_style.content_margin_right = 16
	inv_style.content_margin_top = 12
	inv_style.content_margin_bottom = 12
	$MainHBox/InventoryPanel.add_theme_stylebox_override("panel", inv_style)

	var equip_style = StyleBoxTexture.new()
	equip_style.texture = texture
	equip_style.draw_center = true
	equip_style.content_margin_left = 16
	equip_style.content_margin_right = 16
	equip_style.content_margin_top = 12
	equip_style.content_margin_bottom = 12
	$MainHBox/EquipmentPanel.add_theme_stylebox_override("panel", equip_style)

	var tooltip_style = StyleBoxTexture.new()
	tooltip_style.texture = texture
	tooltip_style.draw_center = true
	tooltip_style.content_margin_left = 10
	tooltip_style.content_margin_right = 10
	tooltip_style.content_margin_top = 8
	tooltip_style.content_margin_bottom = 8
	tooltip_panel.add_theme_stylebox_override("panel", tooltip_style)

func _create_inventory_slots():
	for i in Inventory.SLOT_COUNT:
		var slot: Panel = SLOT_SCENE.instantiate()
		slot.slot_index = i
		slot.slot_type = ""
		slot.slot_clicked.connect(_on_slot_clicked)
		slot.slot_right_clicked.connect(_on_slot_right_clicked)
		inv_grid.add_child(slot)
		inv_slots.append(slot)

func _create_equipment_slots():
	var slot_configs = [
		{"type": "helmet", "label": "头盔"},
		{"type": "armor", "label": "铠甲"},
		{"type": "weapon", "label": "武器"},
		{"type": "boots", "label": "鞋子"},
	]
	for cfg in slot_configs:
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		equip_slots_vbox.add_child(hbox)

		var lbl = Label.new()
		lbl.text = cfg.label
		lbl.custom_minimum_size = Vector2(40, 64)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55))
		hbox.add_child(lbl)

		var slot: Panel = SLOT_SCENE.instantiate()
		slot.slot_type = cfg.type
		slot.set_slot_type_label(cfg.label)
		slot.slot_clicked.connect(_on_slot_clicked)
		slot.slot_right_clicked.connect(_on_slot_right_clicked)
		hbox.add_child(slot)
		equip_slots[cfg.type] = slot

func _refresh_all():
	for i in inv_slots.size():
		var s = Inventory.slots[i]
		inv_slots[i].update_display(s.item_id, s.quantity)
	for equip_type in equip_slots:
		var e = Inventory.equipment[equip_type]
		equip_slots[equip_type].update_display(e.item_id, e.quantity)

func _on_slot_clicked(_slot: Panel):
	tooltip_panel.visible = false

func _on_slot_right_clicked(slot: Panel):
	_popup_slot = slot
	var item_id = _get_slot_item_id(slot)
	if item_id == "":
		return
	var item_def = ItemData.get_item(item_id)
	if item_def == null:
		return

	popup_menu.clear()
	if item_def.item_type == "consumable":
		popup_menu.add_item("使用", 0)
	elif item_def.item_type == "equipment":
		if slot.slot_type != "":
			popup_menu.add_item("卸下", 1)
		else:
			popup_menu.add_item("装备", 2)
	popup_menu.add_item("丢弃", 3)
	popup_menu.position = DisplayServer.mouse_get_position()
	popup_menu.reset_size()
	popup_menu.popup()

func _get_slot_item_id(slot: Panel) -> String:
	if slot.slot_type != "":
		var e = Inventory.equipment.get(slot.slot_type)
		return e.item_id if e else ""
	else:
		if slot.slot_index >= 0 and slot.slot_index < Inventory.slots.size():
			return Inventory.slots[slot.slot_index].item_id
		return ""

func _on_popup_id(id: int):
	if _popup_slot == null:
		return
	match id:
		0:
			if _popup_slot.slot_type == "":
				Inventory.remove_item_from_slot(_popup_slot.slot_index, 1)
		1:
			Inventory.unequip_item(_popup_slot.slot_type)
		2:
			if _popup_slot.slot_type == "":
				var item_def = ItemData.get_item(Inventory.slots[_popup_slot.slot_index].item_id)
				if item_def:
					Inventory.equip_item(_popup_slot.slot_index, item_def.equip_slot)
		3:
			if _popup_slot.slot_type != "":
				Inventory.equipment[_popup_slot.slot_type].clear()
				Inventory.equipment_changed.emit()
			else:
				Inventory.remove_item_from_slot(_popup_slot.slot_index, Inventory.slots[_popup_slot.slot_index].quantity)
	_popup_slot = null

func _on_pickup():
	var ids = ItemData.get_all_ids()
	var random_id = ids[randi() % ids.size()]
	var amount = 1
	var item_def = ItemData.get_item(random_id)
	if item_def and item_def.max_stack > 1:
		amount = randi_range(1, mini(5, item_def.max_stack))
	Inventory.add_item(random_id, amount)

func _on_clear():
	for slot in Inventory.slots:
		slot.clear()
	for key in Inventory.equipment:
		Inventory.equipment[key].clear()
	Inventory.inventory_changed.emit()
	Inventory.equipment_changed.emit()

func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		_update_tooltip()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			tooltip_panel.visible = false

func _update_tooltip():
	var mouse_pos = get_global_mouse_position()
	var item_id = ""
	var item_def = null

	for slot in inv_slots:
		var slot_rect = Rect2(slot.global_position, slot.size)
		if slot_rect.has_point(mouse_pos):
			item_id = Inventory.slots[slot.slot_index].item_id
			if item_id != "":
				item_def = ItemData.get_item(item_id)
			break

	if item_def == null:
		for equip_type in equip_slots:
			var slot = equip_slots[equip_type]
			var slot_rect = Rect2(slot.global_position, slot.size)
			if slot_rect.has_point(mouse_pos):
				item_id = Inventory.equipment[equip_type].item_id
				if item_id != "":
					item_def = ItemData.get_item(item_id)
				break

	if item_def:
		tooltip_title.text = item_def.name
		var type_names = {"consumable": "消耗品", "equipment": "装备", "material": "材料"}
		tooltip_type.text = type_names.get(item_def.item_type, "")
		tooltip_desc.text = item_def.description
		tooltip_panel.visible = true
		tooltip_panel.position = Vector2(mouse_pos.x + 16, mouse_pos.y + 16)
		tooltip_panel.reset_size()
	else:
		tooltip_panel.visible = false
