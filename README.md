# Frühlings-Roboter (Arbeitstitel)

Kleines 2D-Incremental-Spiel: Ein Roboter bringt einer grauen Welt den Frühling zurück. Wo er fährt, wird der Boden grün. Godot 4.7.2, GDScript, Gamepad zuerst (ROG Ally X).

Stand: **Phase 2 vollständig, Einführung, Lautstärke-Regler und Übersichtskarte**, Version 0.15.0. Plan für Phase 3 in `PHASE3.md` (wartet auf Freigabe). Plan der Phase 2 in `PHASE2.md`. Siehe `CHANGELOG.md`, Testliste in `TESTLISTE.md`, Ideen außerhalb des Umfangs in `IDEEN.md`, fremde Inhalte in `CREDITS.md`.

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
- `data/world.json` + `src/sim/world_map.gd`: Flüsse und Wege als Kurven, daraus je Zelle Land, Weg, Wasser oder Brücke (GroundGrid.terrain).
  Nur Land wird grün und zählt zur Fläche; Wasser ist ohne Brücke nicht befahrbar. `src/world/bridge_view.gd` zeichnet die Brücken.
- `data/objects.json` + `src/sim/world_objects.gd`: Verteilung der Objekte (fester Startwert). `src/world/world_object.gd` zeichnet ein Objekt tot oder erwacht;
  main.gd lässt Objekte erwachen, sobald unter ihnen Grün ist, und gibt Bäume und Felsen dem Roboter als Hindernisse.
- `data/animals.json` + `src/sim/animals.gd`: Tiere als Deko (Schmetterlinge, Vögel, Hasen, Frösche), nur nahe der Kamera und über Grün; `src/world/animal_view.gd` zeichnet sie.
- `src/world/disc.gd`: Kreise als Textur statt draw_circle (in Godot 4.7 rund 80-mal billiger). Gilt auch für Objekte: Godot zeichnet sie jedes Bild neu, auch wenn sie nur einmal aufgezeichnet werden.
- `data/tutorial.json`: Einleitung, Hinweise, Tastennamen je Gerät und die Seite „Steuerung“. `src/sim/tutorial.gd` entscheidet, wann welcher Hinweis kommt (je Spielstand einmal, gespeichert); `src/ui/key_hints.gd` merkt sich das zuletzt benutzte Gerät; `src/ui/intro_screen.gd` zeigt die Einleitung, `src/ui/intro_art.gd` malt ihre bewegten Bilder (mit Roboter und Objekten aus dem Spiel).
- `src/ui/map_screen.gd` + `map.gdshader`: Übersichtskarte (Pause-Menü oder View-Taste / M), nutzt die Masken des Bodens.
- Lautstärke: `Sfx.set_volume`, Regler im Pause-Menü, gespeichert in `user://settings.json` (nicht im Spielstand).
- `data/regions.json` + `src/sim/regions.gd`: Gebiete mit eigenen Farben, Blumen, Objekten; ground_view.gd gibt sie als kleine Texturen an den Shader, das HUD blendet den Namen beim Betreten ein.
- `src/sim/skill_tree.gd`: Pollen, Knoten-Stufen, Sichtbarkeit (gekauft / kaufbar / „?“ / verdeckt), Summen der Werte (reine Logik, getestet).
- `src/sim/bee_swarm.gd`: Bienen-Logik (Zielwahl, Schweben, Begrünen), `src/world/bee_view.gd` zeichnet Stock und Bienen.
- `src/sim/ground_grid.gd`: Boden-Raster (1 Byte je Zelle), Begrünen im Kreis, Zähler, Schmutz-Rechteck,
  laufend gepflegte Grenze (graue Zellen mit grünem Nachbarn) und Selbstausbreitung mit Samenflug.
- `src/world/ground_view.gd` + `ground.gdshader`: Boden als ein Rechteck mit Shader; eine Maske (1 Pixel je Zelle, linear gefiltert) plus Rauschen ergibt weiche, organische Grenzen.
  Grüntöne, Grasbüschel, Blumen, Risse, Steinchen und Halme entstehen im Shader aus Zufallswerten je Kachel; „seit wann grün“ je Zelle (zweite Textur) macht alte Stellen üppiger. Werte in `data/balance.json` (`ground`).
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
# Ganze Karte als Bild (Wege, Wasser, Brücken, Objekte; links grau, rechts grün), optional Zoom und Mitte in Zellen
..\ScrapEmpire\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --audio-driver Dummy --path . -s tools/map_preview.gd -- karte.png
# Grobe Spieldauer-Rechnung nach Preisänderungen im Skilltree
python tools/balance_sim.py data/skilltree.json 0.4 640 480 1 0.005
```
