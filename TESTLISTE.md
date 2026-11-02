# Testliste Meilenstein 3 (v0.3.1)

EXEs: `export/windows/SpringBot_v0.3.1.exe` (Release) und `SpringBot_v0.3.1_DEBUG.exe` (Debug mit Cheat-Menü).

## Neu in 0.3.1
- Ausbreitung wächst gleichmäßig: Stufe 1 = 3 Zellen pro Sekunde, Stufe 10 = 30. Das Grün wird nicht mehr von selbst immer schneller.
- Nur mit Ausbreitung und Weite sollte die Karte jetzt deutlich länger dauern (bei Maximum rund 43 Minuten ohne Fahren).

## Ausbreitung
1. Neues Spiel: Ohne Wachstums-Upgrade wächst nichts von allein (Spur bleibt, wie gefahren).
2. Upgrade-Menü (Y / Tab): Es gibt jetzt die Überschriften „Roboter“ und „Wachstum“, darunter „Ausbreitung“ und „Weite“.
3. „Ausbreitung“ Stufe 1 kaufen (40 Pollen), Menü schließen, kurz stehen bleiben: Die Ränder wachsen langsam nach außen (3 Zellen pro Sekunde).
4. Weitere Stufen: Das Wachsen wird sichtbar schneller. Die Prozentanzeige und der Pollen-Ertrag steigen auch ohne Fahren, aber gleichmäßig.
5. „Weite“ kaufen (150 Pollen): Vor dem Rand tauchen einzelne grüne Inseln auf, die selbst weiterwachsen.
6. Die Grenze sieht organisch aus (keine geraden Kanten, kein Flackern).
7. Läuft es flüssig, auch wenn viel gleichzeitig wächst?

## Cheat-Menü (nur Debug-EXE: L3 + R3 eine Sekunde halten, PC F12)
8. „Alles freischalten“ + „Zeit ×10“: Das Grün wächst mit 300 Zellen pro Sekunde (Karte in rund 4 Minuten). Ruckelt es dabei auf dem Ally?
9. „Spielstand zurücksetzen“: Alles grau, Wachstum steht wieder still, bis man neu kauft.

## Wie bisher
10. Start / Esc: Pause-Menü mit „Spiel beenden“. Kaufen mit A lässt das Menü offen.

## Offen für Feedback
- Wachstum zu langsam oder zu schnell? Werte in `data/upgrades.json` (`spread`, `reach`, `seed_chance`).
- Das Spielende bei 100 % kommt erst mit Meilenstein 7; bis dahin passiert bei voller Karte nichts Besonderes.
