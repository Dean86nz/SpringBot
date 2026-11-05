# Changelog

## 0.17.2 – Das Dorf wird wieder aufgebaut

- **Wiederaufbau:** Die Gebäude des Dorfes bleiben kaputt, auch wenn ringsum alles grün ist. Erst die zurückkehrenden Bewohner reparieren sie:
  zuerst das eigene Haus, dann ihre Arbeitsstelle (Bauern machen die Felder, die Wäscherin die Leine, der Kirchgänger den Friedhof),
  danach helfen alle, wo noch etwas kaputt ist (höchstens zwei an einem Gebäude, zu zweit doppelt so schnell). Am Gebäude steht ein Holzgerüst
  mit Fortschrittsbalken, die Bewohner hämmern (Holzspäne). Ist es fertig, erwacht das Gebäude mit Rascheln und Blüten.
  Bewohner kommen zurück, sobald um ihr Haus Grün ist und der Frühling ihren Wert erreicht hat.
- Was repariert ist, steht im Spielstand. Ältere Spielstände: Was dort schon grün und erwacht war, gilt als repariert, das Dorf sieht also gleich aus wie vorher.
- **Hunde** neu gezeichnet: kräftiger Körper mit vier Beinen, großer Kopf mit breiter Schnauze und Nase, große Schlappohren, kurzer Ringelschwanz, der wedelt.
  **Katzen** neu: schlanker gestreifter Körper, spitze Ohren mit rosa Innenseite, Schnurrhaare, grüne Augen, langer gebogener Schwanz, im Sitzen um den Körper gelegt.
  Hellere Fellfarben (braun, creme, grau, rotbraun), damit man die Formen sieht.
- **Niemand läuft mehr durch Brunnen, Gebäude oder den Bienenstock:** Die Bewohner gehen außen herum; Ziele in einem Hindernis (etwa der Ball am Brunnen) werden an dessen Rand gelegt.
- **Kirche mit Friedhof** etwas außerhalb im Nordwesten (Steinmauer mit Tor, Gräber mit Steinen und Kreuzen, Blumen); an ihrem alten Platz steht ein Wohnhaus.
- Bildschirmfotos (Entwicklung): `ZOOM=z` für Nahaufnahmen; neues Werkzeug `tools/villager_gallery.gd`.

## 0.17.1 – Ein belebtes Heimatdorf

- **Größeres Dorf mit verschiedenen Gebäuden:** Kirche mit Turm und Kreuz, Schule mit Pausenhof (Zaun, Fahne, Hüpfkästchen), Bücherei mit Bank
  und Buch-Schild, Dorfladen mit gestreifter Markise und Obstkisten, Schmiede mit glühendem Kamin und Amboss, Bauernhof (Bauernhaus mit Strohdach
  und Gemüsegarten, Scheune mit Heuballen) östlich des Weges mit zwei Feldern, Honigstand beim Bienenstock, Wäscheleine, sieben Wohnhäuser.
  Alle erwachen mit dem Grün (grau und kaputt → bunt, mit Blumen, Feldern voller Pflanzen, Glut in der Schmiede).
- **Bewohner mit Arbeit:** Der Schmied hämmert am Amboss (Funken), Bauern gehen die Ackerreihen entlang und hacken, die Ladenbesitzerin steht bei ihren Kisten,
  eine Frau hängt Wäsche Stück für Stück auf, lässt sie trocknen und nimmt sie wieder ab, Kinder rennen über den Platz einem Ball nach,
  jemand liest auf der Bank vor der Bücherei, der Imker holt im weißen Anzug Honig am Bienenstock (Bienen um ihn herum) und bringt die Gläser zu seinem Stand,
  andere schlendern zwischen Platz, Laden und Häusern. Zwischendurch machen alle mal eine Pause auf dem Platz.
- **Hunde und Katzen:** Hunde laufen ihren Menschen nach (mit den Kindern wild herum, Schwanz wedelt), Katzen sitzen lange vor einem Haus und wechseln ab und zu den Platz.
- **Rückkehr nach und nach:** Jeder Bewohner kommt zurück, sobald sein Haus erwacht ist und der Frühling seinen Wert erreicht hat (zwischen 8 und 93 %).
  Sie kommen zu Fuß von außerhalb des Dorfes, Haustiere mit ihnen. Ein geladener Spielstand hat die Bewohner gleich an ihrem Platz.
- **Fest bei 100 %:** Alle kommen auf dem Platz zusammen und hüpfen vor Freude; nach dem Endbildschirm gehen sie wieder an die Arbeit.
- **Bienen ohne Arbeit:** Ist alles grün, fliegen sie zu Blüten und zu erwachten Bäumen und Büschen in der Nähe des Stocks, naschen dort und kriechen ab und zu in den Stock zum Ausruhen.
- **Klänge am Ende:** Kein Meilenstein-Jingle mehr bei 100 % und keiner beim Endbildschirm. Beim Fest erklingt nur ein leises Glöckchen (Kenney Interface Sounds, CC0).
  Andere Klänge zum Anhören in `sound_kandidaten/fest/`.
- Alles in `data/regions/heimatdorf/region.json` („village“: buildings, props, types, residents).

## 0.17.0 – Phase 3, Meilenstein 2: Heimatdorf

- In der Mitte der Karte, gleich nördlich vom Start, liegt jetzt das **Heimatdorf**: ein runder, befestigter Dorfplatz mit Brunnen,
  zwölf Häuser in zwei Ringen darum, ein kurzer Weg verbindet den Platz mit dem Weg nach Norden.
- **Häuser erwachen** wie Bäume: grau, mit Löchern im Dach und schiefem Kamin, im Grün dann bunte Ziegeldächer (fünf Farben), Blumenkästen, Büsche und Tür.
  Der **Brunnen** ist trocken und rissig und füllt sich mit Wasser und einem Blumenring, sobald rund um den Platz Grün ist.
  Häuser und Brunnen sind Hindernisse; zwischen den Häusern passt der Roboter überall durch (Test).
- Neues Gebiet **Dorfmitte** mit wenig Bäumen, vielen Büschen und Obstbäumen, roten Blumen; Name erscheint beim Betreten.
- **Dorffest bei 100 %:** Die Kamera schwenkt zum Dorf, 16 Menschen kehren zurück und gehen zum Platz, Blüten fliegen, Glocke,
  großes Banner „Das Heimatdorf lebt wieder auf!“. Danach der Endbildschirm mit eigenem Text („Das Heimatdorf lebt wieder!“);
  „Weiterfahren“ schwenkt die Kamera zurück. Die Menschen bleiben danach im Dorf und schlendern zwischen Platz und Haustüren.
- Ein fertiger Spielstand (100 %) hat die Menschen beim Laden gleich im Dorf.
- Wege und Plätze werden jetzt auch in der Mitte warm und bunt, wenn das Grün weiter weg ist (zweiter, weiterer Ring im Boden-Shader).
- Alle Werte in `data/regions/heimatdorf/region.json` („village“) und `world.json` („plazas“).

## 0.16.0 – Phase 3, Meilenstein 1: Gerüst für Regionen

Technik für die Reise durch mehrere Regionen. Im Spiel ändert sich sichtbar nichts.
- Neue Datei `data/campaign.json`: Liste der Regionen und Startregion (vorerst nur das Heimatdorf).
- Die Daten der heutigen Karte liegen jetzt im Ordner `data/regions/heimatdorf/`: `region.json` (Name, Größe, Start, Bienenstock; vorher in `balance.json`),
  `world.json`, `objects.json` und `areas.json` (die Gebiete, vorher `data/regions.json`).
- Im Code heißen die Gebiete jetzt `Areas`, damit „Region“ für die Regionen frei ist.
- Spielstand Version 2: Jede Region hat ihren eigenen Eintrag (Raster, Roboter, fertig); Skilltree, Pollen, Spielzeit und Einführung gelten für alle Regionen.
  Ältere Spielstände werden beim Laden automatisch zum Heimatdorf (getestet mit einem echten alten Stand).
- „Neues Spiel“ setzt alle Regionen zurück.

## 0.15.0 – Lautstärke-Regler und Übersichtskarte

- Plan für Phase 3 „Regionen“ in `PHASE3.md`: vier Regionen mit je einem neuen Helfer, Ablauf, Vorschläge zu den offenen Fragen, sechs Meilensteine. Noch nichts davon umgesetzt.
- Pause-Menü → **Lautstärke**: Regler für Musik und Klänge (0 bis 100 %, in 10er-Schritten), mit Stick / Steuerkreuz links und rechts.
  Beim Klänge-Regler gibt es einen Probeklang. Der gewählte Regler leuchtet gelb. Gespeichert in einer eigenen Datei (bleibt auch bei „Neues Spiel“).
- **Übersichtskarte**: Pause-Menü → „Karte“ oder direkt mit der View-Taste (Tastatur: M). Zeigt die ganze Welt: Grau (schraffiert) = hier fehlt noch der Frühling,
  Grün in der Farbe des Gebiets, Wege, Wasser, Namen der Gebiete, Bienenstock und den Roboter (blinkt). B / Esc / View schließt.
  Aus dem Pause-Menü geöffnet, geht es danach zurück ins Pause-Menü.
- Unten links und auf der Seite „Steuerung“ steht jetzt auch die Karte-Taste.

## 0.14.2 – Aufblühen wieder hörbar

- Das Rascheln beim Aufblühen von Bäumen und Büschen war zu leise: -15 statt -24 dB (der alte Jingle hatte -12 dB).
- Kurz hintereinander wird jeder weitere Klang um 4 statt 5 dB leiser, ab dem dritten bleibt es still wie bisher.
- Werte in `data/audio.json` („sfx_level_db“ → „awake“, „groups“ → „awake“).

## 0.14.1 – Schönere Einleitung

- Jede Seite der Einleitung hat jetzt ein bewegtes Bild im Stil des Spiels:
  - „Die graue Welt“: kahler Baum, trockener Teich, welker Busch, Staub weht vorbei.
  - „Ein kleiner Roboter erwacht“: der Roboter fährt eine Schleife, hinter ihm wächst eine grüne Spur mit Grasbüscheln.
  - „Bring den Frühling zurück“: Baum, Obstbaum, Teich und Busch erwachen nacheinander mit Blütenblättern, Blumen sprießen, Bienen und Schmetterlinge fliegen, Blüten fallen.
- Seitenwechsel blenden weich über; wer schnell weiterdrückt, kürzt den Übergang ab.
- Kürzere Texte, größere Schrift; nach „Los geht's!“ ein kleiner Blütenregen um den Roboter (nicht beim Überspringen).
- Texte und Bild je Seite in `data/tutorial.json` („intro“, „art“).
- Das Rascheln beim Aufblühen bleibt (Rückmeldung: „super“).

## 0.14.0 – Einführung am Spielstart und sanftere Klänge

- Einleitung beim Neuen Spiel: drei Bilder (graue Welt, kleiner Roboter, Ziel), von Grau zu Grün. A / Enter: weiter, B / Esc: überspringen.
- Hinweise im Spiel, jeder genau einmal je Spielstand, dezent unten in der Mitte:
  - zu Beginn: wie man fährt (verschwindet, sobald der Roboter ein Stück gefahren ist),
  - sobald der erste Kauf möglich ist: wie man den Skilltree öffnet,
  - beim ersten Öffnen des Skilltrees: wählen, kaufen, schließen (heller Kasten oben),
  - sobald es Bienen gibt: was sie tun.
  Welche Hinweise schon kamen, steht im Spielstand. Ältere Spielstände bekommen die Hinweise einmal.
- Tasten passend zum Gerät: Wer zuletzt den Controller benutzt hat, sieht „A“, „Y“, „Linker Stick“, sonst „Enter“, „Tab“, „WASD“. Gilt für Hinweise, die Zeile unten links, die Tastenzeile im Skilltree und die Einleitung.
- Pause-Menü: neuer Punkt „Steuerung“ mit allen Tasten zum Nachlesen; B / Esc führt zurück ins Pause-Menü.
- Aufblühen klingt sanft: weiches Rascheln (4 Varianten, Kenney RPG Audio, CC0) statt Jingle, deutlich leiser (-24 statt -12 dB).
  Blühen mehrere Objekte kurz hintereinander auf, wird jeder weitere Klang leiser und ab dem dritten still, bis 2,5 s Ruhe war.
  Werte in `data/audio.json` („groups“). Andere Klänge zum Anhören in `sound_kandidaten/aufbluehen/`.
- Alle Texte und Tastennamen in `data/tutorial.json`.

## 0.13.0 – Phase 2, Meilenstein 6: Gebiete

- Fünf Gebiete mit eigenem Charakter, Grenzen natürlich geschwungen und weich ineinander übergehend:
  - **Blumental** (Start): helles Grün, sehr viele und große Blumenwiesen, kaum Bäume, viele Büsche.
  - **Stiller Wald** (Norden): dunkleres, kühles Grün, dichter Wald aus Laubbäumen, Tannen, Birken und jungen Bäumen, wenig Blumen, meist weiße.
  - **Seenland** (Westen, am Fluss): frisches, bläuliches Grün, viele Teiche (mit Fröschen), Birken, Vergissmeinnicht-Blau.
  - **Felsenhügel** (Nordosten): gelbliches Grün, viele Felsen und Tannen, violette Blumen, etwas kühleres Grau.
  - **Obstgarten** (Südosten): warmes Grün, viele blühende Obstbäume und Büsche, rosa Blumen.
- Beim Betreten eines Gebiets erscheint sein Name dezent unter der Prozentanzeige („~ Blumental ~“) und blendet wieder aus.
  Erst nach einer Sekunde im neuen Gebiet, damit es an der Grenze nicht flackert; nach dem Titelbildschirm wird das aktuelle Gebiet gezeigt.
- Alles in `data/regions.json`: Lage, Farben, Blumen- und Büscheldichte, Lieblingsfarbe der Blumen, Objekt-Gewichte und zusätzliche Objekte je Gebiet, Zeiten der Einblendung.
- Dadurch mehr Objekte in der Welt (646 statt 396, davon 330 statt 155 Hindernisse), vor allem im Wald und auf dem Felsenhügel.
- Leistung: Godot zeichnet auch einmal aufgezeichnete Objekte jedes Bild neu, Kreise und Polygone kosten dabei viel.
  Die Objekte zeichnen deshalb Kreise jetzt als Textur, Polygone als Dreiecke und Umrisse als Linien. Sie sehen gleich aus.
  Mit allen Ausbauten und Zeit ×10 am PC ungedrosselt etwa 330–350 FPS wie in 0.12.0, obwohl es deutlich mehr Objekte gibt (ohne die Umstellung wären es etwa 190).

## 0.12.0 – Phase 2, Meilenstein 5: Tiere

- Schmetterlinge flattern über dem Grün (fünf Farben) und kehren um, wo es grau wird.
- Hasen hoppeln von Grün zu Grün, meiden Wasser, Bäume, Felsen und Teiche und kommen von außerhalb des Bildes herein.
- Vögel ziehen ab und zu in kleinen Gruppen (1 bis 4) über das Bild, mit Schatten tief unter ihnen.
- Frösche sitzen am Rand erwachter Teiche, hüpfen ein Stück weiter oder springen mit Platschen ins Wasser und tauchen anderswo wieder auf.
- Kommt der Roboter nah, fliehen Hasen und Schmetterlinge, Frösche springen ins Wasser.
- Nach und nach: In der grauen Welt gibt es keine Tiere. Ihre Höchstzahl wächst mit dem Grün (z. B. Schmetterlinge ab 2 %, alle 9 ab 50 %; Hasen ab 8 %, Vögel ab 12 %).
- Nicht zu viele: Tiere gibt es nur nahe der Kamera (höchstens 9 Schmetterlinge, 3 Hasen, 2 Frösche je sichtbarem Teich). Weiter weg verschwinden sie, beim Zurückkommen entstehen neue.
  Reine Deko, nicht gespeichert, ohne Klang. Alle Werte in `data/animals.json`.
- Leistung: `draw_circle`, Polygone und Bögen kosten in Godot 4.7 je Aufruf rund 15 bis 20 µs, ein Textur-Rechteck 0,2 µs (gemessen).
  Tiere, Bienen, Bienenstock und Roboter zeichnen Kreise deshalb jetzt als Textur (`src/world/disc.gd`), das Aussehen bleibt gleich.
  Mit allen Ausbauten (28 Bienen) und Zeit ×10 am PC ungedrosselt jetzt etwa 400 statt 300 FPS, obwohl die Tiere dazugekommen sind.

## 0.11.1 – Wege rein optisch, verschiedene Baumarten

- Wege: kein eigener Fortschritt mehr. „Wege: x %“, das Säubern durch den Roboter und die Staubwölkchen aus 0.10.1 sind entfernt.
  Wege werden jetzt von selbst schöner, wenn es daneben grün wird: aus staubigem Grau mit Flecken und Rissen wird warmes Braun, auf dem nach und nach Kiesel, Zweige und Laub liegen.
  Werte in `data/balance.json` (`ground/path_pebbles`, `path_twigs`, `path_leaves`). Alte Spielstände mit „sauberen“ Wegen laden normal.
- Sechs Baumarten mit eigener Form und Größe statt eines Baums: Laubbaum (große buckelige Krone), Tanne (gezackte Schichten, Zapfen), Birke (weißer Stamm, lichte hellgrüne Krone),
  Obstbaum (kleinere Krone voller rosa oder weißer Blüten), Trauerweide (hängende Zweige, steht nur am Wasser) und junge Bäume (Stecken mit ein paar Blättern, erwachen leise, kein Hindernis).
  Jeder Baum, Fels und Busch hat eine eigene Größe. Alles in `data/objects.json` (Anzahl, Größe von bis, Hindernis, Abstand zum Wasser).
- Werkzeug `tools/object_gallery.gd`: alle Objekte tot und erwacht auf einem Bild.

## 0.11.0 – Phase 2, Meilenstein 4: Dinge, die zum Leben erwachen

- 275 Objekte in der Landschaft: 90 Bäume, 55 Felsen, 20 Teiche, 110 Büsche. In der grauen Welt kahl, ausgetrocknet, verwelkt.
  Wird es unter ihnen grün, erwachen sie mit kleiner Animation, Blätterwolke und Klang: Bäume blühen (rosa oder weiß), Teiche füllen sich mit Wasser und Seerosen, Büsche tragen rote Beeren, Felsen bekommen Moos und eine Blume.
- Am Wegrand: rund 80 Baumstämme, Zäune und Steinhaufen. Sie erwachen ebenfalls (Moos und Pilze, Blumen am Zaun, Moos auf den Steinen), leiser und mit kleinerer Blätterwolke.
- Um Bäume und Felsen fährt der Roboter herum; alles andere ist Dekoration. Für das Grün sind Objekte kein Hindernis.
- Verteilung zufällig, aber mit festem Startwert immer gleich; nie auf Wegen oder Wasser, nie am Start; zwischen zwei Hindernissen passt der Roboter immer durch.
  Alles in `data/objects.json` (Anzahl, Größe, Hindernis-Radius, Abstände, Wegrand-Abstand, Blätter).
- Ob ein Objekt erwacht ist, ergibt sich aus dem Grün und muss nicht gespeichert werden.
- Klang: Kenney „jingles_STEEL02“ (CC0), leise und mit wechselnder Tonhöhe (`awake` in `data/audio.json`).
- Leistung: Ausbreitung wieder fast so schnell wie vor 0.10.1 (1,9 statt 3,8 µs je Ereignis). Die Erwach-Animation läuft über die Skalierung, neu gezeichnet wird nur einmal.
  Jedes Objekt ist ein eigener Knoten, gezeichnet werden nur sichtbare.

## 0.10.1 – Rückmeldung zu 0.10.0

- Keine grauen Reste mehr bei 100 %. Ursache war die Spurkorrektur aus 0.8.1: Zellen am Rand der Roboterspur behielten in der Anzeige einen Teilwert, auch wenn sie längst grün waren, und schimmerten mit dem Rauschen grau durch.
  Jetzt werden sie voll grün, sobald sie nicht mehr am Rand liegen. Ein Test prüft, dass bei 100 % jede Landzelle in der Anzeige voll grün ist.
- Kein eingeschlossenes Land mehr: Die Ausbreitung springt über Wege und Wasser (bis 12 Zellen, `map/spread_hop_cells`). Ein Test lässt die Ausbreitung allein die ganze echte Karte füllen.
- Saubere Wegränder: Weg- und Wasserzellen neben grünem Land gelten in der Anzeige als grün, dadurch scheint am Rand kein Grau mehr durch.
- Wege sauber fahren: Wege sind anfangs schmutzig (dunkle Flecken, Zweige) und werden dort sauber, wo der Roboter darüberfährt, mit kleinen Staubwölkchen.
  Dezente Anzeige „Wege: x %“ unter der Prozentanzeige. Zählt nicht für das Ende. Wird mitgespeichert. Bienen und Ausbreitung säubern keine Wege.
- Grasbüschel weniger und dezenter (`ground/tuft_young` 0.07, `tuft_old` 0.32, neu `tuft_alpha` 0.6).

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
