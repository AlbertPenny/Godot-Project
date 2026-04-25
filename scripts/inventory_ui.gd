extends Control

const SLOT_SCENE = preload("res://scenes/slot.tscn")

var inv_slots: Array[Panel] = []
var equip_slots: Dictionary = {}  # equip_type -> Panel
var popup_menu: PopupMenu
var tooltip_panel: PanelContainer
var tooltip_title: Label
var tooltip_desc: Label
var tooltip_type: Label

var _popup_slot: Panel = null  # 当前右键操作的格子

func _ready():
	# 背景
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.color = Color(0.08, 0.08, 0.12)
	add_child(bg)

	# 主布局 HBox
	var main_hbox = HBoxContainer.new()
	main_hbox.name = "MainHBox"
	main_hbox.anchors_preset = Control.PRESET_FULL_RECT
	main_hbox.add_theme_constant_override("separation", 30)
	add_child(main_hbox)

	# 左侧留白
	var left_spacer = Control.new()
	left_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(left_spacer)

	# 背包面板
	var inv_panel = _create_inventory_panel()
	main_hbox.add_child(inv_panel)

	# 装备栏面板
	var equip_panel = _create_equipment_panel()
	main_hbox.add_child(equip_panel)

	# 右侧留白
	var right_spacer = Control.new()
	right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(right_spacer)

	# 底部按钮栏
	var bottom_bar = HBoxContainer.new()
	bottom_bar.name = "BottomBar"
	bottom_bar.anchor_top = 0.85
	bottom_bar.anchor_bottom = 0.95
	bottom_bar.anchor_left = 0.3
	bottom_bar.anchor_right = 0.7
	bottom_bar.add_theme_constant_override("separation", 10)
	add_child(bottom_bar)

	var pickup_btn = Button.new()
	pickup_btn.name = "PickupButton"
	pickup_btn.text = "拾取随机物品"
	pickup_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pickup_btn.pressed.connect(_on_pickup)
	bottom_bar.add_child(pickup_btn)

	var clear_btn = Button.new()
	clear_btn.name = "ClearButton"
	clear_btn.text = "清空背包"
	clear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clear_btn.pressed.connect(_on_clear)
	bottom_bar.add_child(clear_btn)

	# PopupMenu
	popup_menu = PopupMenu.new()
	popup_menu.name = "PopupMenu"
	add_child(popup_menu)
	popup_menu.id_pressed.connect(_on_popup_id)

	# Tooltip
	_create_tooltip()

	# 连接信号
	Inventory.inventory_changed.connect(_refresh_all)
	Inventory.equipment_changed.connect(_refresh_all)
	_refresh_all()

func _create_inventory_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.name = "InventoryPanel"
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.18, 0.95)
	style.border_color = Color(0.35, 0.35, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.name = "InvVBox"
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "背 包"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	vbox.add_child(title)

	var grid = GridContainer.new()
	grid.name = "InvGrid"
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(grid)

	for i in Inventory.SLOT_COUNT:
		var slot: Panel = SLOT_SCENE.instantiate()
		slot.slot_index = i
		slot.slot_type = ""
		slot.slot_clicked.connect(_on_slot_clicked)
		slot.slot_right_clicked.connect(_on_slot_right_clicked)
		grid.add_child(slot)
		inv_slots.append(slot)

	return panel

func _create_equipment_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.name = "EquipmentPanel"
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.18, 0.95)
	style.border_color = Color(0.5, 0.4, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.name = "EquipVBox"
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "装 备"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.9, 0.75, 0.6))
	vbox.add_child(title)

	var slots_vbox = VBoxContainer.new()
	slots_vbox.name = "EquipSlots"
	slots_vbox.add_theme_constant_override("separation", 4)
	vbox.add_child(slots_vbox)

	var slot_configs = [
		{"type": "helmet", "label": "头盔"},
		{"type": "armor", "label": "铠甲"},
		{"type": "weapon", "label": "武器"},
		{"type": "boots", "label": "鞋子"},
	]
	for cfg in slot_configs:
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		slots_vbox.add_child(hbox)

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

	return panel

func _create_tooltip():
	tooltip_panel = PanelContainer.new()
	tooltip_panel.name = "Tooltip"
	tooltip_panel.visible = false
	tooltip_panel.z_index = 100
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.border_color = Color(0.5, 0.5, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	tooltip_panel.add_theme_stylebox_override("panel", style)
	add_child(tooltip_panel)

	var tooltip_vbox = VBoxContainer.new()
	tooltip_vbox.add_theme_constant_override("separation", 4)
	tooltip_panel.add_child(tooltip_vbox)

	tooltip_title = Label.new()
	tooltip_title.add_theme_font_size_override("font_size", 14)
	tooltip_title.add_theme_color_override("font_color", Color(1, 0.95, 0.7))
	tooltip_vbox.add_child(tooltip_title)

	tooltip_type = Label.new()
	tooltip_type.add_theme_font_size_override("font_size", 11)
	tooltip_type.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	tooltip_vbox.add_child(tooltip_type)

	tooltip_desc = Label.new()
	tooltip_desc.add_theme_font_size_override("font_size", 11)
	tooltip_desc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	tooltip_vbox.add_child(tooltip_desc)

func _refresh_all():
	for i in inv_slots.size():
		var s = Inventory.slots[i]
		inv_slots[i].update_display(s.item_id, s.quantity)
	for equip_type in equip_slots:
		var e = Inventory.equipment[equip_type]
		equip_slots[equip_type].update_display(e.item_id, e.quantity)

func _on_slot_clicked(_slot: Panel):
	# 左键点击，隐藏tooltip
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
		0:  # 使用消耗品
			if _popup_slot.slot_type == "":
				Inventory.remove_item_from_slot(_popup_slot.slot_index, 1)
		1:  # 卸下装备
			Inventory.unequip_item(_popup_slot.slot_type)
		2:  # 装备
			if _popup_slot.slot_type == "":
				var item_def = ItemData.get_item(Inventory.slots[_popup_slot.slot_index].item_id)
				if item_def:
					Inventory.equip_item(_popup_slot.slot_index, item_def.equip_slot)
		3:  # 丢弃
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

	# 检查鼠标悬停在哪个格子上
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
