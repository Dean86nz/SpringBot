# Changelog

## 0.4.1 – Bienenstock fest (Rückmeldung zu 0.4.0)

- Der Roboter fährt nicht mehr durch den Bienenstock, sondern gleitet an ihm entlang. Radien in `data/balance.json` (`robot/radius_px`, `bees/hive_radius_px`).

## 0.4.0 – Meilenstein 4: Bienen

- Bienenstock nahe dem Startpunkt. Bienen fliegen zu grauen Stellen in 6–18 Zellen Entfernung, schweben dort 2 Sekunden und lassen einen runden grünen Fleck (Radius 2,3 Zellen) entstehen.
- Findet eine Biene in der Nähe nichts Graues, fliegt sie zu einer beliebigen Randzelle der Karte: Bienen schließen am Ende die letzten Lücken. Ist alles grün, kreisen sie um den Stock.
- Neue Upgrade-Gruppe „Bienen“: Bienenvolk (+1 Biene je Stufe, 10 Stufen, ab 120 Pollen) und Flügelschlag (+15 % Flugtempo je Stufe, 8 Stufen, ab 200 Pollen).
- Upgrade-Menü kompakter (zwei Zeilen je Upgrade, Kosten in der ersten Zeile), damit alle sechs Upgrades auf den Bildschirm passen.

## 0.3.1 – Ausbreitung gebremst (Rückmeldung zu 0.3.0)

- Problem: Mit Ausbreitung und Weite war die Karte in wenigen Minuten voll, weil jede Samen-Insel neuen Rand brachte und das Wachstum sich selbst beschleunigte.
- Ausbreitung ist jetzt eine feste Zahl Zellen pro Sekunde: +3 je Stufe, höchstens 30/s. Allein damit dauert die ganze Karte rund 43 Minuten.
- Weite ändert nur noch, wo das Grün wächst (30 % der Schritte werden zu Samenflug), nicht wie viel.
- Kosten steigen steiler: Ausbreitung ×1,9 je Stufe, Weite ×2,0.

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
