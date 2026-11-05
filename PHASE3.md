# Phase 3: Regionen

Entwurf vom 2026-11-05 auf Grundlage der Info vom selben Tag (siehe `PHASE2.md`, „Ausblick“). **Freigegeben am 2026-11-05** („go“).
Arbeitsweise wie bisher: ein Meilenstein, dann anhalten, Release- und Debug-EXE, Testliste, Feedback. 60 FPS auf dem Ally, alle Werte in JSON.

## Idee in einem Satz

Der kleine Roboter bringt zuerst sein **Heimatdorf** zurück ins Leben, zieht dann in immer größere **Regionen** weiter
(Felder und Vorort, Großstadt, am Ende die ganze Welt), bekommt in jeder Region einen **neuen Helfer** und behält seinen **Skilltree**.

## Begriffe

- **Region:** eine eigene Karte, die man von 0 bis 100 % begrünt. Regionen spielt man nacheinander.
- **Gebiet:** ein Teil einer Region mit eigenem Charakter (wie heute Blumental, Stiller Wald). Jede Region hat mehrere Gebiete.
  Im Code heißt das heutige Gebiets-System noch `Regions`; es wird in Meilenstein 1 in `Areas` (Gebiete) umbenannt, damit „Region“ frei ist.

## Die Regionen (Vorschlag)

| # | Region | Größe (Zellen) | Charakter | Neuer Helfer |
|---|---|---|---|---|
| 1 | **Heimatdorf** | 640 × 480 (heutige Karte) | Dorf mit Häusern, Dorfplatz und Brunnen in der Mitte, rundherum die heutigen Gebiete | Bienen (gibt es schon) |
| 2 | **Felder und Vorort** | ca. 900 × 650 | große Äcker in Reihen, Feldwege, Bauernhöfe, Windrad, am Rand ein Vorort mit Gärten | **Samenvögel:** Schwärme tragen Samen weit und lassen ganze Streifen ergrünen |
| 3 | **Großstadt** | ca. 1000 × 700 | Straßen (wie Wege, werden nicht grün), Häuserblöcke als Hindernisse mit Dachgärten, Parks, Fluss mit Brücken | **Gärtner-Drohnen:** fliegen feste Runden über Straßen hinweg und begrünen Höfe und Dächer |
| 4 | **Die ganze Welt** | ca. 1100 × 750 | Erdteile im Kleinen: Wüste, Eis, Dschungel, Meer mit Inseln (Gebiete mit sehr eigenem Aussehen) | **Regenwolken:** ziehen über die Karte und lassen breite Bahnen erblühen |

Die Helfer sind eigene Ideen (nichts aus Unharvest oder Moon Sweepers). Größen sind Startwerte; jede Region wird auf Leistung gemessen.

## Ablauf einer Region

1. **Ankommen:** kurze Einleitung wie beim Spielstart (ein Bild, zwei Sätze), dann der Name der Region groß eingeblendet.
2. **Begrünen** wie heute. Gebiete, Objekte und Tiere je Region aus eigenen Daten.
3. **Unterwegs:** Mit wachsendem Grün erwachen auch Häuser (bunte Dächer, Blumenkästen, Licht in den Fenstern), so wie heute Bäume.
4. **Region fertig (100 %):** Statt des heutigen Endbildschirms ein kleines Fest: Menschen kehren zurück und laufen durch die Region,
   im Heimatdorf ein Dorffest mit Blütenregen. Danach: „Weiterreisen“ oder „Noch bleiben“.
5. **Weiterreisen:** Die **Regionenkarte** zeigt alle Regionen als Stationen auf einer Reiseroute. Die nächste ist frei, spätere sind verhüllt.
6. **Ende des Spiels:** Wenn auch „Die ganze Welt“ blüht: großer Abschluss mit allen Regionen nacheinander, dann Abspann.

## Vorschläge zu den offenen Fragen (bitte bestätigen oder ändern)

| Frage | Vorschlag |
|---|---|
| Wie wechselt man die Region? | Über die Regionenkarte („Weiterreisen“ nach dem Fest, später auch über das Pause-Menü). Kein Fahrzeug, keine Ladezeit-Show. |
| Kann man zurück? | Ja, fertige Regionen kann man jederzeit besuchen, zum Anschauen und Herumfahren. Sie bleiben grün. |
| Muss eine Region 100 % haben? | Ja, wie heute. Damit 100 % angenehm bleibt, helfen die Bienen und später alle Helfer am Ende bei den letzten Lücken. |
| Was passiert mit den Pollen? | Pollen sind gemeinsam (wie der Skilltree). Fertige Regionen bringen weiter Pollen, aber nur einen Teil (Wert in JSON, z. B. 25 %), damit sich das Weiterreisen lohnt. |
| Skilltree | Bleibt erhalten. Jede Region schaltet einen neuen Ast für ihren Helfer frei (verhüllt, bis man die Region erreicht). Bestehende Äste bekommen bei Bedarf weitere Stufen. |
| Wirken Helfer überall? | Ja, alle freigeschalteten Helfer arbeiten in jeder Region (Bienen also auch in der Großstadt). |
| Menschen und Häuser | Selbst gezeichnet im Stil des Spiels, von oben: Häuser mit Dach, Menschen als kleine runde Figuren mit Hut oder Haaren. |
| Wie lange dauert eine Region? | Ziel: Heimatdorf 30 bis 45 Minuten wie heute, jede weitere etwas länger (45 bis 75 Minuten). Prüfung mit `tools/balance_sim.py`. |
| Bestehender Spielstand | Wird übernommen: Der heutige Garten wird zum Heimatdorf, Skills und Pollen bleiben. |

## Meilensteine (Vorschlag)

1. **Gerüst für Regionen (Technik):** Daten je Region in Ordnern (`data/regions/<id>/…`), Liste der Regionen in `data/campaign.json`,
   Spielstand mit einem Raster je Region, alter Spielstand wird übernommen. `Regions` → `Areas` umbenennen. Sichtbar ändert sich fast nichts.
   (erledigt in 0.16.0)
2. **Heimatdorf:** Dorf in der Mitte der heutigen Karte (Häuser, Dorfplatz, Brunnen), Häuser erwachen mit dem Grün.
   Bei 100 % kehren die Menschen zurück, Dorffest statt Endbildschirm.
   (erledigt in 0.17.0: Fest mit Rückkehr der Menschen, danach der Endbildschirm der Region; „Weiterreisen“ kommt mit Meilenstein 3)
3. **Regionenkarte und Reisen:** Reiseroute mit allen Regionen, Weiterreisen, Zurückkehren, Pollen-Regel für fertige Regionen,
   Einleitung je Region. (Die Übersichtskarte aus 0.15.0 ist dafür die Grundlage.)
4. **Felder und Vorort** mit Samenvögeln (neuer Skilltree-Ast).
5. **Großstadt** mit Gärtner-Drohnen.
6. **Die ganze Welt** mit Regenwolken, großer Abschluss und Abspann.

Nach jedem Regions-Meilenstein: Balancing-Prüfung (Dauer je Region) und Leistungsmessung auf dem Ally.

## Was schon vorbereitet ist

Siehe `PHASE2.md`, „Wie die Gebiete aus Phase 2 darauf vorbereitet sind“: alles in Daten, Logik ohne feste Pfade,
Skilltree und Welt im Spielstand getrennt, Gebiete kennen ihre Fläche, Helfer nach dem Muster der Bienen.
