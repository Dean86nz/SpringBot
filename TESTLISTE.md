# Testliste Phase 2, Meilenstein 3 (v0.10.0)

EXEs: `export/windows/SpringBot_v0.10.0.exe` (Release) und `SpringBot_v0.10.0_DEBUG.exe` (Debug mit Cheat-Menü).
Dein Spielstand wird übernommen. Grün, das jetzt auf einem Weg oder im Wasser läge, verschwindet.

Karte zum Orientieren: Vom Start aus liegt ein Weg kurz südlich (Ost–West), ein Weg führt nach Norden zum Bach mit Brücke.
Der Fluss liegt im Westen (Nord–Süd) mit zwei Brücken, der Bach zweigt vom Fluss nach Osten ab, mit zwei Brücken.

## Wege
1. Erdwege schlängeln sich durch die Landschaft. In der grauen Welt sind sie staubig, neben Grün warmbraun mit Grassaum am Rand.
2. Auf Wegen kann man fahren, sie werden aber nicht grün. Das Grün wächst bis an den Wegrand.

## Wasser und Brücken
3. Fluss und Bach: in der grauen Welt trüb, neben Grün klares Blau mit leichtem Glitzern.
4. Ohne Brücke kommt der Roboter nicht übers Wasser, er gleitet am Ufer entlang.
5. Über die Holzbrücken fährt er hinüber. Lässt sich das gut treffen, oder sind die Brücken zu schmal?

## Fläche
6. Die Prozentanzeige zählt nur Land. Mit Cheat-Menü (L3 + R3 eine Sekunde halten, PC F12) → „Welt fast fertig“ und über den letzten Fleck fahren: Es kommen 100 % und der Endbildschirm, obwohl Wege und Wasser grau bzw. blau bleiben.

## Allgemein
7. Läuft es auf dem Ally weiterhin flüssig, auch am Wasser?
8. Gefällt dir der Verlauf der Wege und Flüsse? Er steht in `data/world.json` und lässt sich leicht ändern.
