# Phase 2: Die Welt erwacht

Auftrag vom 2026-11-04. Ziel: Die Welt lebendig machen. **Keine neuen Spielmechaniken**, keine Änderungen an Skilltree, Pollen oder Balancing, nur Optik und Dinge in der Welt, die auf das Grün reagieren.
Arbeitsweise wie bisher: ein Meilenstein, dann anhalten, Release- und Debug-EXE, Testliste, auf Feedback warten. Leistung auf dem Ally beachten. Alle Werte in JSON.

1. **Kamera am Kartenrand:** Die Kamera bleibt auf der Karte. (erledigt in 0.8.0, Spur mittig in 0.8.1)
2. **Abwechslungsreiches Grün:** Grüntöne, Grasbüschel, Blumen; länger grüne Stellen werden üppiger und bunter. Graue Welt mit Rissen, Steinchen, trockenen Halmen. (erledigt in 0.9.0)
   Rückmeldung: Blumen in Gruppen statt überall, ca. zwei Drittel ruhiges Gras, dazwischen Blumenwiesen und -inseln, Werte in JSON. (0.9.1)
3. **Wege und Wasser** (Ergänzung vom 2026-11-04):
   - Erdwege, die sich durch die Landschaft schlängeln, mit Gras am Rand.
   - Flüsse und Bäche mit kleinen Holzbrücken, über die der Roboter fährt. Ohne Brücke kann der Roboter nicht übers Wasser.
   - Wege und Wasser werden nicht begrünt und zählen nicht zur Prozentanzeige (100 % bleiben erreichbar). Das Grün wächst bis an ihren Rand.
   (erledigt in 0.10.0)
4. **Dinge, die zum Leben erwachen:** kahle Bäume, ausgetrocknete Teiche, verwelkte Büsche, kahle Felsen. Erreicht sie das Grün, verwandeln sie sich mit kleinem Effekt und Klang (Blüten, Wasser und Seerosen, Beeren, Moos).
   Reine Dekoration und Orientierungspunkte, keine Hindernisse für das Grün. Der Roboter fährt um Bäume und Felsen herum.
   Dazu Baumstämme, Zäune und Steine als Details am Wegrand.
   (erledigt in 0.11.0; Rückmeldung zu 0.10.0 in 0.10.1: keine Grau-Reste, dezentere Grasbüschel)
   Korrektur in 0.11.1: kein Wege-Fortschritt, Wege werden rein optisch schöner neben Grün (Kiesel, Zweige, Laub).
   Verschiedene Baumarten mit eigener Form und Größe: Laubbaum, Tanne, Birke, Obstbaum, Weide am Wasser, junge Bäume.
5. **Tiere:** Schmetterlinge, Vögel, Hasen, Frösche an den Teichen, nach und nach auf grünen Flächen. Reine Dekoration, nicht zu viele, flüssig auf dem Ally.
   (erledigt in 0.12.0)
6. **Gebiete mit eigenem Charakter:** 4 bis 6 Gebiete (z. B. Wiese, Hügel, Seenlandschaft, Wald) mit eigener Mischung aus Pflanzen, Objekten und Farben, auch eigener Blumendichte. Name dezent einblenden beim Betreten.
   (erledigt in 0.13.0: Blumental, Stiller Wald, Seenland, Felsenhügel, Obstgarten)
7. **Eingeschoben: Einführung am Spielstart und sanftere Klänge:** kurze Einleitung beim Neuen Spiel (A weiter, B überspringen),
   Hinweise genau einmal im richtigen Moment (fahren, Skilltree öffnen, im Skilltree wählen/kaufen/schließen, Bienen),
   Tasten passend zum Gerät, „Steuerung“ im Pause-Menü, Aufblüh-Klang sanft und zusammengefasst. (erledigt in 0.14.0)
   Rückmeldung: Einleitung schöner, mit bewegten Bildern und weichen Übergängen. (0.14.1)

Reihenfolge: Wege und Wasser kommen vor den Objekten, weil Objekte (Wegrand-Details, Teiche, Brücken) sich an ihnen ausrichten.

---

# Ausblick: Phase 3 „Regionen“ (freigegeben am 2026-11-05, siehe `PHASE3.md`)

Info vom 2026-11-05. Plan und Stand: `PHASE3.md`.

- Man startet im eigenen **Heimatdorf**. Ist die Region fertig (alles grün), kehren Menschen zurück und das Dorf lebt wieder auf.
- Danach geht es in **größere Regionen** weiter, z. B. Felder oder Vorort, dann Großstadt, am Ende die ganze Welt.
- Jede Region bringt einen **neuen Helfer** für mehr Automatisierung (so wie heute die Bienen).
- Der **Skilltree bleibt** über alle Regionen erhalten.

## Wie die Gebiete aus Phase 2 darauf vorbereitet sind

Phase 2 unterscheidet **Gebiete** (Teile einer Karte mit eigenem Charakter, z. B. Blumental, Stiller Wald) und Phase 3 **Regionen** (eigene Karten, nacheinander gespielt).
Die heutige Karte mit ihren fünf Gebieten kann später die erste Region werden (oder ihr Vorbild). Was schon passt:

- **Alles steckt in Daten, nicht im Code:** Wege und Wasser (`data/world.json`), Objekte (`data/objects.json`), Gebiete (`data/regions.json`), Tiere (`data/animals.json`), Boden (`data/balance.json` → „ground“).
  Eine neue Region braucht vor allem einen eigenen Satz dieser Dateien, z. B. in einem Ordner je Region.
- **Die Logik nimmt Daten entgegen statt feste Pfade:** `WorldMap.build`, `WorldObjects.place`, `Regions.new`, `Animals.new` bekommen ihre Daten übergeben.
  Nur `main.gd` kennt die Pfade (Konstanten oben); dort käme später „welche Region ist gerade dran“ hinein.
- **Kartengröße steht in den Daten** (`balance.json` → „map“), das Raster hat keine feste Größe. Größere Regionen = größere Zahlen; für sehr große Karten müsste man Leistung neu messen.
- **Skilltree und Welt sind im Spielstand getrennt** („skills“ und „grid“). Für Phase 3 bekäme jede Region ihren eigenen Raster-Eintrag, die Skills bleiben gemeinsam.
- **Gebiete kennen ihre Fläche** (`Regions.share`, Gebiet je Zelle). Fortschritt je Gebiet oder „Region fertig“ lässt sich daraus ableiten, ohne die Gebiete umzubauen.
- **Helfer nach dem Muster der Bienen:** reine Logik in `src/sim` (wie `bee_swarm.gd`), Zeichnung in `src/world` (wie `bee_view.gd`), Werte im Skilltree. Ein neuer Helfer wäre ein weiteres solches Paar.
- **Hinweise sind erweiterbar:** neue Hinweise (z. B. „neuer Helfer“, „Region fertig“) sind neue Einträge in `data/tutorial.json` plus eine Bedingung in `tutorial.gd`.

Offene Fragen für Phase 3 (später klären): Wie wird eine fertige Region verlassen und betreten (Karte, Weg, Fahrzeug)? Kann man zurück? Wie sehen Menschen und Häuser aus (Grafik selbst gezeichnet wie bisher)? Was passiert mit der Pollen-Menge beim Wechsel?
