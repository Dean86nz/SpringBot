# Frühlings-Roboter (Arbeitstitel)

Kleines 2D-Incremental-Spiel: Ein Roboter bringt einer grauen Welt den Frühling zurück. Wo er fährt, wird der Boden grün. Godot 4.7.2, GDScript, Gamepad zuerst (ROG Ally X).

Stand: **Phase 2, Meilenstein 1 (Kamera am Kartenrand)**, Version 0.8.1. Plan der Phase 2 in `PHASE2.md`. Siehe `CHANGELOG.md`, Testliste in `TESTLISTE.md`, Ideen außerhalb des Umfangs in `IDEEN.md`, fremde Inhalte in `CREDITS.md`.

## Steuerung

| Aktion | Gamepad | Tastatur |
|---|---|---|
| Fahren | linker Stick | WASD oder Pfeiltasten |
| Skilltree auf/zu | Y | Tab |
| Skilltree: Ansicht schieben / zoomen | rechter Stick / LB, RB | Maus ziehen oder I/J/K/L / Mausrad, Q, E |
| Skilltree: Knoten wählen / kaufen | linker Stick oder D-Pad / A | Pfeile oder WASD / Enter, Maus: Klick wählt, zweiter Klick kauft |
| Pause-Menü (Weiterspielen, Titelbildschirm, Spiel beenden) | Start | Esc |
| Vollbild ein/aus | – | F11 |
| Cheat-Menü (nur Debug-EXE) | L3 + R3 eine Sekunde halten | F12 |
| Menü: wählen / bestätigen / schließen | D-Pad / A / B | Pfeile / Enter / Esc |

## Aufbau

- `data/balance.json`: Kartengröße, Zellgröße, Grundtempo, Begrünungsradius, Bienen (Stock, Flugtempo, Blütengröße, Schwebezeit, Sprungweite), Kamera.
- `data/skilltree.json`: Pollen je grüner Zelle und Sekunde, Grundwerte, Texte der Werte und alle 45 Knoten
  (Position, Voraussetzungen, Stufen, Kosten, Wirkung, besondere Knoten).
- `src/sim/skill_tree.gd`: Pollen, Knoten-Stufen, Sichtbarkeit (gekauft / kaufbar / „?“ / verdeckt), Summen der Werte (reine Logik, getestet).
- `src/sim/bee_swarm.gd`: Bienen-Logik (Zielwahl, Schweben, Begrünen), `src/world/bee_view.gd` zeichnet Stock und Bienen.
- `src/sim/ground_grid.gd`: Boden-Raster (1 Byte je Zelle), Begrünen im Kreis, Zähler, Schmutz-Rechteck,
  laufend gepflegte Grenze (graue Zellen mit grünem Nachbarn) und Selbstausbreitung mit Samenflug.
- `src/world/ground_view.gd`: Boden als ein Rechteck mit Shader; eine Maske (1 Pixel je Zelle, linear gefiltert) plus Rauschen ergibt weiche, organische Grenzen.
- `src/world/robot.gd`, `src/world/main.gd` (öffnet/schließt die Menüs), `src/ui/hud.gd`.
- `src/autoload/sfx.gd` (Autoload „Sfx“): Klänge mit Varianten, Musikstücke je Fortschritt mit Überblenden.
  Dateien in `assets/audio/`, Lautstärken und Schwellen in `data/audio.json`.
- `src/world/petal_fx.gd`: Blütenblätter-Partikel (fester Vorrat, ein Zeichenaufruf für alle).
- `src/sim/save_store.gd`: Spielstand als zwei abwechselnde JSON-Dateien plus Meta-Datei unter `user://saves/` (Debug-EXE: `user://saves_debug/`).
  Unter Windows: `%APPDATA%\Godot\app_userdata\Frühlings-Roboter\`. Was gespeichert wird, steht in `main.gd` (`save` / `load_game`).
- `src/ui/title_screen.gd`, `src/ui/end_screen.gd`: Titel- und Endbildschirm über der pausierten Welt.
- `src/ui/skill_tree_menu.gd` (statische Ebene, nur bei Änderungen neu gezeichnet), `src/ui/pause_menu.gd`, `src/ui/cheat_menu.gd`, gemeinsame Bausteine in `src/ui/menu_kit.gd`.

## Entwickeln

Die Engine liegt in `Godot_v4.7.2-stable_win64.exe/` im Projektordner oder wird aus `..\ScrapEmpire\` genommen.

```
# Tests (headless)
..\ScrapEmpire\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --headless --path . -s tests/run_tests.gd
# Screenshot-Lauf (Fenster öffnet kurz, stumm)
..\ScrapEmpire\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --audio-driver Dummy --path . -s tests/screenshot.gd -- shot.png 240 "ui_accept:10:11,move_right:20:200"
# Release- und Debug-EXE nach export/windows/
.\build.ps1
# Stil-Vorschaubild (Phase 2) nach docs/
..\ScrapEmpire\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --audio-driver Dummy --path . -s tools/style_preview.gd -- docs/stil_vorschlag_phase2.png
# Grobe Spieldauer-Rechnung nach Preisänderungen im Skilltree
python tools/balance_sim.py data/skilltree.json 0.4 640 480 1 0.005
```
