# Testliste Meilenstein 1 (v0.1.0)

EXEs: `export/windows/SpringBot_v0.1.0.exe` (Release) und `SpringBot_v0.1.0_DEBUG.exe` (Debug mit Cheat-Menü).

## Ally X (Armoury Crate im Gamepad-Modus)
1. Release-EXE starten: Vollbild, graue Welt, Roboter in der Mitte, unten rechts „v0.1.0“.
2. Linken Stick leicht neigen: Roboter fährt langsam; voll neigen: schnell. Er dreht sich in Fahrtrichtung.
3. Wo er fährt, wird der Boden grün, mit weichem, welligem Rand.
4. Oben steigt „Frühling: x,y %“ beim Fahren über graue Fläche, bleibt gleich auf schon grünem Boden.
5. An den Kartenrand fahren: Roboter bleibt stehen, die Kamera zeigt etwas Rand.
6. Läuft es flüssig (60 FPS, kein Ruckeln beim Fahren)?
7. Debug-EXE: **L3 + R3 (beide Sticks drücken) eine Sekunde halten** → Cheat-Menü öffnet, Spiel pausiert. D-Pad wählt, A bestätigt, B schließt.
8. Cheat „Zeit ×10“: Roboter fährt zehnmal so schnell. Nochmal drücken: normal.
9. Cheat „Spielstand zurücksetzen“: alles wieder grau, Roboter in der Mitte, 0,0 %.
10. In der Release-EXE darf L3 + R3 nichts öffnen.

## PC
11. Debug-EXE: WASD und Pfeiltasten fahren. **F12** öffnet und schließt das Cheat-Menü, Esc schließt es auch. F11 wechselt Vollbild/Fenster.

## Offen für Feedback
- Tempo, Begrünungsradius und Kamera-Zoom passen? (alles in `data/balance.json`)
- Wirkt die graue Welt trist, aber hell genug?
