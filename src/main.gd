extends Node3D

const PlayerScript = preload("res://src/player.gd")

var locations: Array = []
var lore_entries: Dictionary = {}
var location_nodes: Dictionary = {}
var player: CharacterBody3D

var prompt_label: Label
var quest_label: Label
var morality_label: Label
var panel: PanelContainer
var panel_title: Label
var panel_body: RichTextLabel
var choice_box: VBoxContainer
var nearest_location_id := ""
var interact_was_down := false

func _ready() -> void:
	GameState.load_state()
	_load_content()
	_build_world()
	_spawn_player()
	_build_ui()
	GameState.morality_changed.connect(_update_hud)
	GameState.quest_changed.connect(_update_hud)
	_update_hud()

func _process(_delta: float) -> void:
	nearest_location_id = _find_nearest_location()
	if nearest_location_id != "":
		var loc := _location_by_id(nearest_location_id)
		prompt_label.text = "[E] Untersuchen: %s" % loc.get("name", nearest_location_id)
		prompt_label.visible = not panel.visible
	else:
		prompt_label.visible = false

	var interact_down := Input.is_physical_key_pressed(KEY_E)
	if interact_down and not interact_was_down and nearest_location_id != "" and not panel.visible:
		_open_location(nearest_location_id)
	interact_was_down = interact_down

func _load_content() -> void:
	var parsed_locations = JSON.parse_string(FileAccess.get_file_as_string("res://data/locations.json"))
	var parsed_lore = JSON.parse_string(FileAccess.get_file_as_string("res://data/lore.json"))

	if typeof(parsed_locations) == TYPE_ARRAY:
		locations = parsed_locations
	if typeof(parsed_lore) == TYPE_ARRAY:
		for entry in parsed_lore:
			lore_entries[str(entry.get("location_id", ""))] = entry

func _build_world() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.055, 0.07, 0.08)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.35, 0.4, 0.45)
	environment.ambient_light_energy = 0.8
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.2, 0.24, 0.26)
	environment.fog_density = 0.012
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	add_child(sun)

	var ground := StaticBody3D.new()
	ground.name = "Ground"

	var ground_mesh_instance := MeshInstance3D.new()
	var ground_mesh := BoxMesh.new()
	ground_mesh.size = Vector3(80, 0.4, 80)
	ground_mesh_instance.mesh = ground_mesh
	ground_mesh_instance.position.y = -0.2
	ground.add_child(ground_mesh_instance)

	var ground_collision := CollisionShape3D.new()
	var ground_shape := BoxShape3D.new()
	ground_shape.size = Vector3(80, 0.4, 80)
	ground_collision.shape = ground_shape
	ground_collision.position.y = -0.2
	ground.add_child(ground_collision)
	add_child(ground)

	for location in locations:
		_create_location_marker(location)

	_create_forest()

func _create_location_marker(location: Dictionary) -> void:
	var marker := Node3D.new()
	marker.name = str(location.get("id", "location"))
	var p = location.get("position", [0, 0, 0])
	marker.position = Vector3(float(p[0]), float(p[1]), float(p[2]))

	var column := MeshInstance3D.new()
	var marker_mesh := CylinderMesh.new()
	marker_mesh.top_radius = 0.5
	marker_mesh.bottom_radius = 0.8
	marker_mesh.height = 2.8
	column.mesh = marker_mesh
	column.position.y = 1.4
	marker.add_child(column)

	var label := Label3D.new()
	label.text = str(location.get("name", "Ort"))
	label.position = Vector3(0, 3.1, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 32
	label.outline_size = 8
	marker.add_child(label)

	add_child(marker)
	location_nodes[str(location.get("id"))] = marker

func _create_forest() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	for i in range(55):
		var x := rng.randf_range(-36.0, 36.0)
		var z := rng.randf_range(-36.0, 36.0)
		if Vector2(x, z).length() < 5.0:
			continue

		var tree := Node3D.new()
		tree.position = Vector3(x, 0, z)

		var trunk := MeshInstance3D.new()
		var trunk_mesh := CylinderMesh.new()
		trunk_mesh.top_radius = 0.12
		trunk_mesh.bottom_radius = 0.2
		trunk_mesh.height = rng.randf_range(2.5, 4.0)
		trunk.mesh = trunk_mesh
		trunk.position.y = trunk_mesh.height * 0.5
		tree.add_child(trunk)

		var crown := MeshInstance3D.new()
		var crown_mesh := SphereMesh.new()
		crown_mesh.radius = rng.randf_range(0.8, 1.4)
		crown_mesh.height = crown_mesh.radius * 2.0
		crown.mesh = crown_mesh
		crown.position.y = trunk_mesh.height + crown_mesh.radius * 0.4
		tree.add_child(crown)
		add_child(tree)

func _spawn_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.set_script(PlayerScript)
	player.position = Vector3(0, 0.1, 7)
	add_child(player)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var hud := VBoxContainer.new()
	hud.position = Vector2(18, 14)
	hud.size = Vector2(920, 130)
	layer.add_child(hud)

	var title := Label.new()
	title.text = "TOPOGRAPHIE DES UNHEIMLICHEN — MVP"
	title.add_theme_font_size_override("font_size", 22)
	hud.add_child(title)

	quest_label = Label.new()
	quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud.add_child(quest_label)

	morality_label = Label.new()
	morality_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud.add_child(morality_label)

	prompt_label = Label.new()
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 20)
	prompt_label.position = Vector2(360, 650)
	prompt_label.size = Vector2(560, 40)
	layer.add_child(prompt_label)

	panel = PanelContainer.new()
	panel.visible = false
	panel.position = Vector2(265, 110)
	panel.size = Vector2(750, 500)
	layer.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	margin.add_child(box)

	panel_title = Label.new()
	panel_title.add_theme_font_size_override("font_size", 26)
	box.add_child(panel_title)

	panel_body = RichTextLabel.new()
	panel_body.bbcode_enabled = true
	panel_body.custom_minimum_size = Vector2(680, 280)
	box.add_child(panel_body)

	choice_box = VBoxContainer.new()
	box.add_child(choice_box)

	var close_button := Button.new()
	close_button.text = "Schließen"
	close_button.pressed.connect(_close_panel)
	box.add_child(close_button)

func _update_hud() -> void:
	quest_label.text = "QUEST — %s\n%s" % [GameState.QUEST_TITLE, GameState.get_quest_text()]
	var parts: Array[String] = []
	for axis in ["Mercy", "Greed", "Truth", "Fear", "Pact", "Renown", "Corruption"]:
		parts.append("%s %d" % [axis, int(GameState.morality[axis])])
	morality_label.text = "MORALITÄT — " + " | ".join(parts)

func _find_nearest_location() -> String:
	if player == null:
		return ""
	var best_id := ""
	var best_distance := 4.25
	for id in location_nodes.keys():
		var node: Node3D = location_nodes[id]
		var distance := player.global_position.distance_to(node.global_position)
		if distance < best_distance:
			best_distance = distance
			best_id = str(id)
	return best_id

func _location_by_id(location_id: String) -> Dictionary:
	for location in locations:
		if str(location.get("id")) == location_id:
			return location
	return {}

func _open_location(location_id: String) -> void:
	var location := _location_by_id(location_id)
	var lore: Dictionary = lore_entries.get(location_id, {})
	GameState.discover_location(location_id)

	panel_title.text = "%s  [%s]" % [str(location.get("name", location_id)), str(location.get("evidence", "?"))]
	panel_body.text = "[b]%s[/b]\n\n%s\n\n[i]Provenienzklasse %s: %s[/i]" % [
		str(location.get("summary", "")),
		str(lore.get("text", "Für diesen Ort liegt noch kein Lore-Eintrag vor.")),
		str(location.get("evidence", "?")),
		str(lore.get("provenance_note", "Noch zu prüfen."))
	]
	_clear_choices()
	_add_quest_choices(location)
	panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _add_quest_choices(location: Dictionary) -> void:
	var required_step := int(location.get("quest_step", -1))
	if required_step != GameState.quest_step:
		return

	match required_step:
		0:
			_add_choice("Die Überlieferung respektieren", {"Mercy": 1, "Truth": 1}, required_step)
			_add_choice("Das Wunder als Ruhmquelle ausschlachten", {"Greed": 1, "Renown": 1}, required_step)
		1:
			_add_choice("Pilger und Erinnerung schützen", {"Mercy": 1, "Renown": 1}, required_step)
			_add_choice("Einen Pakt mit dem Ort eingehen", {"Pact": 1, "Corruption": 1}, required_step)
		2:
			_add_choice("Den wahren Namen offenlegen", {"Truth": 2, "Fear": -1}, required_step)
			_add_choice("Den Namen binden und Macht behalten", {"Pact": 2, "Corruption": 2}, required_step)

func _add_choice(label_text: String, changes: Dictionary, step: int) -> void:
	var button := Button.new()
	button.text = label_text
	button.pressed.connect(func():
		GameState.apply_choice(changes)
		GameState.advance_quest(step)
		_clear_choices()
		_update_hud()
	)
	choice_box.add_child(button)

func _clear_choices() -> void:
	for child in choice_box.get_children():
		child.queue_free()

func _close_panel() -> void:
	panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
