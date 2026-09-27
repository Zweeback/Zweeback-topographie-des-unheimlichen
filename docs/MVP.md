# MVP — Topographie des Unheimlichen

## Playable loop

1. Explore a generated dark-forest placeholder world.
2. Approach one of six canonical locations.
3. Press E to inspect its lore card and provenance class.
4. Follow the quest “Die Hostie und der Name”: Gottsbüren → Sababurg → Mühle.
5. Make one moral decision at every quest stage.
6. The seven-axis morality state persists locally in user://save.json.

## Controls

- WASD — move
- Mouse — look
- E — inspect/interact
- Esc — release/capture mouse

## Evidence classes

A = primary source; B = reliable research; C = regional tradition; D = tourist/popular attribution; E = creative synthesis; O = oral history.

The MVP intentionally separates historical claims from later fairy-tale framing.

## Run

Open the repository in Godot 4.x and run the project. No external assets are required: terrain, trees, location markers, player body and UI are generated from primitives at runtime.

## Validation

Run: python scripts/validate_content.py

The validator checks the six-location catalog, lore coverage, evidence classes and quest-step integrity.

## Next slice

- replace placeholder positions with georeferenced Reinhardswald coordinates
- import terrain/height data
- migrate recoverable Quality Cycle 01 Godot code
- add authored NPCs and bounded AI dialogue adapter
- add primary/research source references to each lore record
- Android export profile and headless Godot smoke test
