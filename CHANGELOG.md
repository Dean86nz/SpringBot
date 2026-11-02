# Changelog

## 0.3.0 – Meilenstein 3: Selbstausbreitung

- Das Grün wächst von allein: Graue Zellen am Rand des Grüns werden nach und nach grün.
- Neue Upgrade-Gruppe „Wachstum“ im Upgrade-Menü:
  - Ausbreitung: +2 % Randwachstum pro Sekunde je Stufe (10 Stufen). Ohne diese Stufe wächst nichts von allein.
  - Weite: Beim Wachsen fliegt ein Samen bis zu 2–9 Zellen weit und startet dort eine neue grüne Insel (8 Stufen).
- Upgrade-Menü zeigt Gruppen-Überschriften „Roboter“ und „Wachstum“.
- Leistung: Die Grenze wird mitgeführt statt gesucht; höchstens 3.000 Wachstumsschritte pro Bild (in `data/upgrades.json`).

## 0.2.0 – Meilenstein 2: Pollen und erste Upgrades

- Grüne Zellen bringen Pollen (0,01 je Zelle und Sekunde), Anzeige oben links mit Ertrag pro Sekunde.
- Upgrade-Menü (Y / Tab) rechts am Rand: Reichweite (+0,5 Zellen Radius je Stufe) und Tempo (+12 % je Stufe), je 10 Stufen.
  A kauft, das Menü bleibt offen, der Fokus bleibt auf dem Knopf. Pollen fließen weiter, der Roboter steht.
- Pause-Menü (Start / Esc) mit „Weiterspielen“ und „Spiel beenden“ (Rückmeldung aus dem Test von 0.1.0).
- Tastenhinweis unten links.
- Cheat-Menü: „+10.000 Pollen“ und „Alles freischalten“ (alle Upgrades maximal) funktionieren jetzt.

## 0.1.0 – Meilenstein 1: Prototyp

- Roboter fährt per linkem Stick (analog) oder WASD/Pfeiltasten, bleibt in der Karte.
- Boden-Raster 320 × 240 Zellen; unter dem Roboter wird ein Kreis (Radius 3 Zellen) grün.
- Prozentanzeige „Frühling: x,y %“ oben, Versionsnummer unten rechts.
- Cheat-Menü nur in der Debug-EXE (F12 / L3+R3 1 s): Zeit ×10, Spielstand zurücksetzen; Pollen und Freischalten als Platzhalter bis Meilenstein 2.
- Alle Zahlen in `data/balance.json`. Build-Skript für Release- und Debug-EXE.
