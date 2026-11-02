# Frühlings-Roboter (Arbeitstitel)

Kleines 2D-Incremental-Spiel: Ein Roboter bringt einer grauen Welt den Frühling zurück. Wo er fährt, wird der Boden grün. Godot 4.7.2, GDScript, Gamepad zuerst (ROG Ally X).

Stand: **Meilenstein 3 (Selbstausbreitung)**, Version 0.3.1. Siehe `CHANGELOG.md`, Testliste in `TESTLISTE.md`, Ideen außerhalb des Umfangs in `IDEEN.md`.

## Steuerung

| Aktion | Gamepad | Tastatur |
|---|---|---|
| Fahren | linker Stick | WASD oder Pfeiltasten |
| Upgrade-Menü auf/zu | Y | Tab |
| Pause-Menü (Weiterspielen, Spiel beenden) | Start | Esc |
| Vollbild ein/aus | – | F11 |
| Cheat-Menü (nur Debug-EXE) | L3 + R3 eine Sekunde halten | F12 |
| Menü: wählen / bestätigen / schließen | D-Pad / A / B | Pfeile / Enter / Esc |

## Aufbau

- `data/balance.json`: Kartengröße, Zellgröße, Grundtempo, Begrünungsradius, Kamera.
- `data/upgrades.json`: Pollen je grüner Zelle und Sekunde, Upgrades (Kosten, Wachstum, Maximalstufe, Wirkung je Stufe).
- `src/sim/economy.gd`: Pollen und Upgrade-Stufen (reine Logik, getestet).
- `src/sim/ground_grid.gd`: Boden-Raster (1 Byte je Zelle), Begrünen im Kreis, Zähler, Schmutz-Rechteck,
  laufend gepflegte Grenze (graue Zellen mit grünem Nachbarn) und Selbstausbreitung mit Samenflug.
- `src/world/ground_view.gd`: Boden als ein Rechteck mit Shader; eine Maske (1 Pixel je Zelle, linear gefiltert) plus Rauschen ergibt weiche, organische Grenzen.
- `src/world/robot.gd`, `src/world/main.gd` (öffnet/schließt die Menüs), `src/ui/hud.gd`.
- `src/ui/upgrade_menu.gd`, `src/ui/pause_menu.gd`, `src/ui/cheat_menu.gd`, gemeinsame Bausteine in `src/ui/menu_kit.gd`.

## Entwickeln

Die Engine liegt in `Godot_v4.7.2-stable_win64.exe/` im Projektordner oder wird aus `..\ScrapEmpire\` genommen.

```
# Tests (headless)
..\ScrapEmpire\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --headless --path . -s tests/run_tests.gd
# Screenshot-Lauf (Fenster öffnet kurz)
..\ScrapEmpire\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --path . -s tests/screenshot.gd -- shot.png 240 "move_right:2:200"
# Release- und Debug-EXE nach export/windows/
.\build.ps1
```
