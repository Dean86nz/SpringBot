# Testliste Phase 2, Meilenstein 2 (v0.9.1)

EXEs: `export/windows/SpringBot_v0.9.1.exe` (Release) und `SpringBot_v0.9.1_DEBUG.exe` (Debug mit Cheat-Menü).
Dein Spielstand wird übernommen.

## Blumen in Gruppen (deine Rückmeldung zu 0.9.0)
1. In altem Grün sind die Blumen jetzt in Gruppen: große Blumenwiesen und kleine Blumeninseln.
2. Dazwischen, etwa zwei Drittel der Fläche, ruhiges Gras in verschiedenen Grüntönen mit Grasbüscheln und nur ab und zu einer Blume.
3. Passt die Menge? Anpassen in `data/balance.json` → `ground`:
   - `meadow_threshold` 0.6: höher = weniger und kleinere Wiesen (z. B. 0.65), tiefer = mehr (z. B. 0.55).
   - `meadow_scale` 700: größer = weiter auseinander liegende, größere Wiesen.
   - `island_threshold` 0.78: höher = weniger Inseln.
   - `calm_flowers` 0.05: Blumen im ruhigen Gras (0 = gar keine).
   - `flower_old` 0.7: wie dicht eine volle Blumenwiese ist.
   Die JSON-Datei steckt in der EXE. Für Änderungen sag mir einfach die Werte, ich baue neu.

## Allgemein
4. Läuft es auf dem Ally weiterhin flüssig?
