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
5. **Tiere:** Schmetterlinge, Vögel, Hasen, Frösche an den Teichen, nach und nach auf grünen Flächen. Reine Dekoration, nicht zu viele, flüssig auf dem Ally.
6. **Gebiete mit eigenem Charakter:** 4 bis 6 Gebiete (z. B. Wiese, Hügel, Seenlandschaft, Wald) mit eigener Mischung aus Pflanzen, Objekten und Farben, auch eigener Blumendichte. Name dezent einblenden beim Betreten.

Reihenfolge: Wege und Wasser kommen vor den Objekten, weil Objekte (Wegrand-Details, Teiche, Brücken) sich an ihnen ausrichten.
