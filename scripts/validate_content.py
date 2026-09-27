#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VALID_EVIDENCE = {"A", "B", "C", "D", "E", "O"}
REQUIRED_LOCATIONS = {"gottsbueren", "sababurg", "muehle", "trendelburg", "wolkenbruch", "gieselwerder"}

def load_json(path):
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)

def main():
    locations = load_json(ROOT / "data" / "locations.json")
    lore = load_json(ROOT / "data" / "lore.json")
    errors = []
    ids = [item.get("id") for item in locations]

    if len(ids) != len(set(ids)):
        errors.append("location ids must be unique")
    missing = REQUIRED_LOCATIONS - set(ids)
    if missing:
        errors.append("missing required locations: " + ", ".join(sorted(missing)))

    for item in locations:
        if item.get("evidence") not in VALID_EVIDENCE:
            errors.append(f"{item.get('id')}: invalid evidence class")
        pos = item.get("position")
        if not isinstance(pos, list) or len(pos) != 3:
            errors.append(f"{item.get('id')}: position must have three coordinates")

    lore_ids = [item.get("location_id") for item in lore]
    for location_id in ids:
        if location_id not in lore_ids:
            errors.append(f"{location_id}: missing lore entry")

    quest_steps = {item.get("quest_step") for item in locations if isinstance(item.get("quest_step"), int) and item.get("quest_step") >= 0}
    if quest_steps != {0, 1, 2}:
        errors.append(f"quest steps must be 0,1,2; got {sorted(quest_steps)}")

    if errors:
        for error in errors:
            print("ERROR:", error)
        return 1

    print(f"OK: {len(locations)} locations, {len(lore)} lore entries, provenance valid")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
