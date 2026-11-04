# Changelog

## 0.10.0 – Phase 2, Meilenstein 3: Wege und Wasser

- Ein Fluss von Nord nach Süd und ein Bach, der nach Osten abzweigt; vier Erdwege schlängeln sich durch die Landschaft.
  Wo ein Weg Wasser kreuzt, steht eine Holzbrücke (4 Brücken). Ohne Brücke kommt der Roboter nicht übers Wasser, am Ufer gleitet er entlang.
- Wege und Wasser werden nie grün und zählen nicht zur Prozentanzeige: 100 % = alles Land (95,9 % der Karte). Das Grün wächst bis an ihren Rand.
- Wege und Wasser reagieren auf das Grün daneben: staubiger Weg und trübes Wasser in der grauen Welt, warmes Braun mit Grassaum und klares, glitzerndes Blau neben Grün.
- Bienen fliegen über Wasser hinweg, lassen aber nur auf grauem Land etwas erblühen.
- Karte in `data/world.json`: Flüsse und Wege als Punktlisten (in Zellen) mit Breite und Schlängeln; Brückenbreite. Aufbau beim Start ca. 50 ms.
- Alte Spielstände: Grün auf jetzigen Wegen und Wasser verfällt; stand der Roboter im Wasser, startet er am Startpunkt.
- Nebenwirkung: Weil Wege und Wasser 4,1 % der Karte einnehmen, ist die Welt etwas schneller voll.
- Werkzeug `tools/map_preview.gd`: ganze Karte als Bild (links grau, rechts grün).

## 0.9.1 – Blumen in Gruppen (Rückmeldung zu 0.9.0)

- Blumen wachsen nicht mehr überall gleich dicht, sondern in großen Blumenwiesen (ca. 26 % des Grüns) und kleinen Blumeninseln (ca. 7 %).
  Dazwischen, etwa zwei Drittel der Fläche, ruhiges Gras mit Grüntönen, Büscheln und nur vereinzelten Blumen.
- Werte in `data/balance.json` (`ground`): `meadow_threshold` (höher = weniger Wiesen), `meadow_scale` (Größe der Wiesen),
  `island_threshold`, `island_scale`, `island_strength`, `calm_flowers` (Blumen im ruhigen Gras), `flower_old` (Dichte in voller Wiese).
  Unterschiedliche Dichte je Gebiet folgt mit dem Meilenstein „Gebiete“.
- Plan der Phase 2 um Wege, Flüsse, Brücken und Wegrand-Details erweitert (`PHASE2.md`).

## 0.9.0 – Phase 2, Meilenstein 2: Abwechslungsreiches Grün

- Grün in mehreren Tönen: große dunklere und gelblichere Flecken statt einer einheitlichen Fläche.
- Grasbüschel und Blumen in sieben Farben (weiß, gelb, rosa, lila, rot, blau, orange). Frisches Grün hat nur wenige Büschel und vereinzelt weiße und gelbe Blumen.
  Je länger eine Stelle grün ist, desto dichter wachsen Büschel und Blumen, nach und nach kommen die bunten dazu. Voll üppig nach 5 Minuten Spielzeit (`ground/lush_sec`).
  Neue Pflanzen wachsen klein heran, keine Blume wechselt ihre Farbe.
- Die graue Welt bekommt Risse, Steinchen und trockene Halme, bleibt aber trist.
- Alles wird im Boden-Shader (`src/world/ground.gdshader`) direkt auf der Grafikkarte gezeichnet, ohne Einzelobjekte. Grafikkarten-Zeit am PC (Radeon 860M, ähnlich wie im Ally X) 0,74 ms je Bild statt 0,15 ms.
- Jede Zelle merkt sich, seit wann sie grün ist; das wird mitgespeichert. Alte Spielstände: alles vorhandene Grün gilt als alt (sofort üppig).
- Alle Dichten und Kachelgrößen in `data/balance.json` (`ground`).

## 0.8.1 – Spur mittig (Rückmeldung zu 0.8.0)

- Die grüne Spur lag bis zu einer halben Zelle (12 px) neben dem Roboter, weil sie am Zellraster einrastete.
  Jetzt bekommt der Rand der Spur in der Anzeige Teilwerte (`GroundGrid.vis`), der sichtbare Rand liegt genau auf dem Kreis um den Roboter.
  Rein optisch: Welche Zellen als grün zählen, Pollen und Fläche bleiben gleich. Die Spur wirkt dadurch etwas breiter (vorher am Raster abgeschnitten).

## 0.8.0 – Phase 2, Meilenstein 1: Kamera am Kartenrand

- Die Kamera bleibt auf der Karte, man sieht am Rand keine leere Fläche mehr (`camera/edge_margin_px`, 0).
  Auch der Titelbildschirm verschiebt die Ansicht nicht mehr über den Rand.
- Der Roboter bleibt am Kartenrand samt Ketten ganz im Bild (`robot/edge_margin_px`, 46). Sein Grün reicht trotzdem bis an den Rand.
- Musik (Rückmeldung zu 0.7.0): „A Simple Trifle“ entfernt, „Another August“ läuft von Anfang an. Musik insgesamt 3 dB leiser (`music_db` −11).
- Stil-Vorschlag für Grün, Objekte und Tiere: `docs/stil_vorschlag_phase2.png` (erzeugt mit `tools/style_preview.gd`).

## 0.7.0 – Meilenstein 7: Rahmen (Titel, Speichern, Ende)

- Titelbildschirm mit Blätterregen; dahinter sieht man den eigenen gespeicherten Garten. „Weiterspielen“ (mit Fläche und Spielzeit), „Neues Spiel“ (fragt nach, wenn schon ein Garten existiert), „Beenden“.
- Speichern automatisch alle 30 Sekunden, beim Öffnen von Pause, beim Schließen des Skilltrees, beim Wechsel zum Titel, beim Beenden und beim Schließen des Fensters.
  Gespeichert werden Boden, Pollen, Skilltree, Roboterposition, Spielzeit und ob das Ende erreicht ist.
  Zwei abwechselnd beschriebene Dateien (Ansatz aus Scrap Empire): Ein Absturz beim Schreiben kostet höchstens den letzten Stand. Packen und Schreiben laufen im Hintergrund, damit kein Bild hängt.
  Die Debug-EXE speichert in einen eigenen Ordner (`saves_debug`), Cheats berühren den echten Spielstand nie.
- Ende: Blüht die ganze Welt, gibt es einen großen Blätterregen und nach 2,5 Sekunden den Endbildschirm mit Spielzeit, gesammelten Pollen, gekauften Knoten und Bienen. „Weiterfahren“ oder „Zum Titelbildschirm“. Erscheint nur einmal je Spielstand.
- Pause-Menü: neu „Zum Titelbildschirm“.
- Cheat-Menü: „Welt fast fertig (Ende testen)“ lässt nur einen kleinen grauen Fleck rechts vom Roboter übrig.
- Werte in `data/balance.json`: `save/autosave_sec`, `end/coverage`, `end/delay_sec`, `camera/title_offset_px`.

## 0.6.0 – Meilenstein 6: Gefühl (Musik, Klänge, Partikel)

- Skilltree frei verschiebbar und zoombar (Rückmeldung zu 0.5.0): rechter Stick schiebt (gewählt ist der Knoten in der Bildmitte), LB/RB zoomen; PC: Maus ziehen, Mausrad, Q/E, I/J/K/L.
- Musik wird mit dem Fortschritt voller: vier CC0-Stücke von ruhig nach fröhlich, ab 0 %, 5 %, 30 % und 60 % Fläche, mit Überblenden. Auswahl durch den Auftraggeber aus `sound_kandidaten/` (nicht im Repo). Quellen in `CREDITS.md`.
- Klänge (Kenney, CC0): Kauf (heller je Stufe), besonderer Knoten, „reicht nicht“, Knoten wählen, Menü auf/zu, jedes volle Zehntel Fläche. Kein Fahrgeräusch.
- Partikel: Blütenblätter hinter dem Roboter, wo frisch begrünt wird; kleines Büschel, wo Bienen etwas erblühen lassen; Blätterwolke beim Kauf im Skilltree; großer Blätterregen und aufspringende Prozentanzeige bei jedem vollen Zehntel.
  Alle Blätter werden mit einem einzigen Zeichenaufruf gezeichnet.
- Spiel beenden stoppt erst den Ton (keine Fehlermeldung beim Beenden).
- Lautstärken und Musik-Schwellen in `data/audio.json`.
## 0.5.0 – Meilenstein 5: Skilltree

- Der Skilltree ersetzt das Upgrade-Menü (Y / Tab): 45 Knoten, drei Äste um den Startknoten „Frühlingsfunke“:
  Roboter (oben: Reichweite, Tempo), Wachstum (rechts: Ausbreitung, Samenflug), Bienen (links: Anzahl, Flugtempo, Blütengröße, Schwebezeit).
  Pollen-Knoten sind in allen drei Ästen verteilt.
- Viele Knoten mit mehreren Stufen (Punkte unter dem Knoten), 9 besondere Knoten mit großer Wirkung (goldener Stern), z. B. Frühlingsherz, Löwenzahn-Sturm, Bienenkönigin, Ewiger Frühling.
- Verdeckte Knoten: Kaufbare Knoten sind sichtbar, ihre Nachbarn als „?“ angedeutet, alles Weitere ist unsichtbar. Anzeige „Entdeckt: x / 45“.
- Komplett per Gamepad: Stick/D-Pad springt zum nächsten Knoten in diese Richtung, die Ansicht fährt mit, A kauft, das Menü bleibt offen. Infofeld mit Name, Beschreibung, Wirkung je Stufe, Stufe und Kosten.
  Bezahlbare Knoten leuchten, beim Kauf dehnt sich ein Ring aus, reicht es nicht, wackelt der Auswahlring rot.
- Größere Welt: 640 × 480 Zellen (vorher 320 × 240), damit Skilltree und Bienen bis zum Ende gebraucht werden.
  Pollen 0,005 je Zelle und Sekunde. Grobe Modellrechnung: Welt voll nach ca. 40 Minuten bei ständigem Spielen; echte Spieldauer muss der Test zeigen.
- Cheat-Menü: „+100.000 Pollen“, „Alles freischalten“ kauft den ganzen Skilltree.
- Leistung: Der Skilltree zeichnet Knoten und Linien nur bei Änderungen neu (vorher jedes Bild: 77 statt 365 FPS ungedrosselt am PC).
- Entfernt: altes Upgrade-Menü und `data/upgrades.json`.

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
