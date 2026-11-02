# Testliste Meilenstein 2 (v0.2.0)

EXEs: `export/windows/SpringBot_v0.2.0.exe` (Release) und `SpringBot_v0.2.0_DEBUG.exe` (Debug mit Cheat-Menü).

## Neu: Pause und Beenden
1. **Start** (PC: **Esc**) öffnet das Pause-Menü, das Spiel steht still (Pollen zählen nicht weiter).
2. „Weiterspielen“ oder nochmal Start/B schließt es. „Spiel beenden“ schließt das Spiel.

## Pollen
3. Oben links „Pollen: N (+x/s)“. Der Ertrag pro Sekunde steigt mit der grünen Fläche, die Pollen zählen von allein hoch.

## Upgrades
4. **Y** (PC: **Tab**) öffnet das Upgrade-Menü rechts. Der Roboter bleibt stehen, Pollen fließen weiter.
5. D-Pad oder Stick wählt zwischen „Reichweite“ und „Tempo“, **A** kauft eine Stufe.
6. Nach dem Kauf bleibt das Menü offen und der Fokus auf dem Knopf: mehrmals A kauft mehrere Stufen hintereinander.
7. Reicht es nicht, ist die Schrift rötlich und der Knopf wackelt bei A, es wird nichts abgezogen.
8. Menü schließen (Y, B, Start oder Esc/Tab) und fahren: Reichweite macht die grüne Spur breiter, Tempo den Roboter schneller.
9. Bei Stufe 10/10 steht „Maximal“.

## Cheat-Menü (nur Debug-EXE)
10. Ally: **L3 + R3 eine Sekunde halten**, PC: **F12**. Öffnet nicht, solange Upgrade- oder Pause-Menü offen ist.
11. „+10.000 Pollen“, „Alles freischalten“ (beide Upgrades auf 10), „Zeit ×10“, „Spielstand zurücksetzen“ (alles grau, 0 Pollen, Stufen 0).
12. In der Release-EXE öffnet L3 + R3 / F12 nichts.

## Offen für Feedback
- Tempo der ersten Upgrades: Das erste sollte nach etwa einer halben Minute Fahren bezahlbar sein. Passt das?
- Alle Zahlen stehen in `data/upgrades.json`.
