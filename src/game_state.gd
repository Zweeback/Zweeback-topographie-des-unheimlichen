extends Node

signal morality_changed
signal quest_changed

const QUEST_TITLE := "Die Hostie und der Name"
const QUEST_STEPS := [
	"Untersuche das Hostienwunder in Gottsbüren.",
	"Folge der Spur zur Sababurg.",
	"Suche die Mühle auf und entscheide über den Namen.",
	"Quest abgeschlossen."
]

var morality := {
	"Mercy": 0,
	"Greed": 0,
	"Truth": 0,
	"Fear": 0,
	"Pact": 0,
	"Renown": 0,
	"Corruption": 0
}

var quest_step := 0
var discovered_locations: Array[String] = []

func reset() -> void:
	for axis in morality.keys():
		morality[axis] = 0
	quest_step = 0
	discovered_locations.clear()
	morality_changed.emit()
	quest_changed.emit()
	save_state()

func discover_location(location_id: String) -> void:
	if not discovered_locations.has(location_id):
		discovered_locations.append(location_id)
		save_state()

func apply_choice(changes: Dictionary) -> void:
	for axis in changes.keys():
		if morality.has(axis):
			morality[axis] += int(changes[axis])
	morality_changed.emit()
	save_state()

func advance_quest(expected_step: int) -> bool:
	if quest_step != expected_step:
		return false
	quest_step = mini(quest_step + 1, QUEST_STEPS.size() - 1)
	quest_changed.emit()
	save_state()
	return true

func get_quest_text() -> String:
	return QUEST_STEPS[quest_step]

func save_state() -> void:
	var payload := {
		"morality": morality,
		"quest_step": quest_step,
		"discovered_locations": discovered_locations
	}
	var file := FileAccess.open("user://save.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload))

func load_state() -> void:
	if not FileAccess.file_exists("user://save.json"):
		return
	var raw := FileAccess.get_file_as_string("user://save.json")
	var parsed = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	if parsed.has("morality") and typeof(parsed["morality"]) == TYPE_DICTIONARY:
		for axis in morality.keys():
			if parsed["morality"].has(axis):
				morality[axis] = int(parsed["morality"][axis])
	if parsed.has("quest_step"):
		quest_step = clampi(int(parsed["quest_step"]), 0, QUEST_STEPS.size() - 1)
	if parsed.has("discovered_locations") and typeof(parsed["discovered_locations"]) == TYPE_ARRAY:
		discovered_locations.clear()
		for item in parsed["discovered_locations"]:
			discovered_locations.append(str(item))
