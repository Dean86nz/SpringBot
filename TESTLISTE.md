# Testliste Meilenstein 4 (v0.4.1)

EXEs: `export/windows/SpringBot_v0.4.1.exe` (Release) und `SpringBot_v0.4.1_DEBUG.exe` (Debug mit Cheat-Menü).

## Neu in 0.4.1
- Gegen den Bienenstock fahren: Der Roboter kommt nicht hindurch, sondern rutscht seitlich daran vorbei. Frontal angefahren bleibt er stehen.

## Bienen
1. Neues Spiel: Links oberhalb des Roboters steht ein gelber Bienenstock. Noch keine Bienen.
2. Upgrade-Menü (Y / Tab): Unten die neue Gruppe „Bienen“ mit „Bienenvolk“ und „Flügelschlag“. Alle sechs Upgrades passen aufs Bild, jedes in zwei Zeilen, Kosten oben rechts in der Zeile.
3. „Bienenvolk“ kaufen (120 Pollen): Eine Biene fliegt aus dem Stock zu einer grauen Stelle, schwebt dort kurz (flattert) und hinterlässt einen runden grünen Fleck. Dann fliegt sie weiter.
4. Mehr Stufen = mehr Bienen. „Flügelschlag“ macht sie sichtbar schneller.
5. Die Flecken der Bienen wachsen mit „Ausbreitung“ auch von selbst weiter.
6. Sind die Bienen gut zu erkennen auf dem Ally-Bildschirm?

## Cheat-Menü (nur Debug-EXE: L3 + R3 eine Sekunde halten, PC F12)
7. „Alles freischalten“ + „Zeit ×10“: 10 Bienen schwirren über die Karte. Gegen Ende fliegen sie die letzten grauen Lücken an. Ruckelt etwas?
8. „Spielstand zurücksetzen“: Alle Bienen weg, Stock bleibt.

## Wie bisher
9. Start / Esc: Pause-Menü mit „Spiel beenden“. Kaufen mit A lässt das Menü offen.

## Offen für Feedback
- Sind Bienen zu stark oder zu schwach im Vergleich zur Ausbreitung? Werte in `data/balance.json` (`bees`) und `data/upgrades.json` (`bees`, `bee_speed`).
