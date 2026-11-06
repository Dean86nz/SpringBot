# Entwicklerwerkzeug: erzeugt die Daten der Region Großstadt (data/regions/stadt/*.json) aus einem
# Straßenraster: Straßen, Fluss, Marktplatz mit Altstadt und Bewohnern, Parks, Brachflächen (dürr)
# und die Gebäude der übrigen Blöcke (Wohnblocks und Hochhäuser, je zu ihrer Straße gedreht).
# Danach von Hand nachbessern ist erlaubt; erneutes Erzeugen überschreibt alles.
#   python tools/gen_city.py
import json, math, os, random

W, H = 1000, 700
XS = [30 + 58 * i for i in range(17)]          # senkrechte Straßen (x in Zellen)
YS = [30 + 58 * j for j in range(12)]          # waagrechte Straßen
STREET_W = 4.5
HALF = STREET_W / 2
RIVER = [[-6, 250], [120, 278], [260, 336], [400, 322], [520, 384], [640, 362], [780, 424], [900, 402], [1006, 440]]
CENTER_BLOCK = (8, 2)                           # Block des Marktplatzes (Spalte, Zeile)
PARKS = {(2, 8), (3, 8), (2, 9), (3, 9), (12, 9), (13, 9)}
BRACHE = {(5, 1), (14, 2), (1, 5), (10, 7), (6, 10), (15, 6), (11, 4)}
rnd = random.Random(42)


def block_rect(i, j):
    return (XS[i] + HALF, YS[j] + HALF, XS[i + 1] - HALF, YS[j + 1] - HALF)


def dist_seg(p, a, b):
    ax, ay = a; bx, by = b; px, py = p
    dx, dy = bx - ax, by - ay
    t = max(0, min(1, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))
    return math.hypot(px - ax - t * dx, py - ay - t * dy)


def river_dist(p):
    return min(dist_seg(p, RIVER[k], RIVER[k + 1]) for k in range(len(RIVER) - 1))


def facing(x, y, rect):
    # Vorderseite (+y lokal) zur nächsten Straße; Winkel in Grad wie in main.gd (rot = Richtung - 90°)
    x0, y0, x1, y1 = rect
    opts = [(x - x0, (-1, 0)), (x1 - x, (1, 0)), (y - y0, (0, -1)), (y1 - y, (0, 1))]
    d = min(opts)[1]
    return round(math.degrees(math.atan2(d[1], d[0])) - 90)


ci, cj = CENTER_BLOCK
cx0, cy0, cx1, cy1 = block_rect(ci, cj)
center = [round((cx0 + cx1) / 2), round((cy0 + cy1) / 2) - 4]
village_blocks = {(ci, cj), (ci - 1, cj), (ci + 1, cj), (ci, cj - 1), (ci, cj + 1)}

# --- Dorf (Altstadt um den Marktplatz) ---
buildings = [
    {"id": "dom", "type": "cathedral", "pos": [center[0], center[1] - 19]},
    {"id": "schule", "type": "school_city", "pos": [center[0] - 19, center[1] - 14], "rot": 0},
    {"id": "buecherei", "type": "museum", "pos": [center[0] + 19, center[1] - 15]},
    {"id": "laden", "type": "cafe", "pos": [center[0] - 19, center[1] + 7], "rot": 0},
    {"id": "cafe", "type": "cafe", "pos": [center[0] + 19, center[1] + 7], "rot": 0},
]
props = []
homes = []
for k, (bi, bj) in enumerate([(ci - 1, cj), (ci + 1, cj), (ci, cj - 1), (ci, cj + 1)]):
    r = block_rect(bi, bj)
    x0, y0, x1, y1 = r
    corners = [(x0 + 10, y0 + 6), (x1 - 10, y0 + 6), (x0 + 10, y1 - 6), (x1 - 10, y1 - 6)]
    for n, (x, y) in enumerate(corners):
        hid = "w%d" % (len(homes) + 1)
        homes.append(hid)
        buildings.append({"id": hid, "type": "apartment", "pos": [round(x), round(y)], "rot": facing(x, y, r)})
    mid = [round((x0 + x1) / 2), round((y0 + y1) / 2)]
    if k < 3:
        props.append({"id": "garten%d" % (k + 1), "type": "raised_beds", "pos": mid})
    else:
        props.append({"id": "spielplatz", "type": "playground", "pos": mid})

residents = [
    {"job": "shop", "home": "laden", "from": 0.08},
    {"job": "stroll", "home": "w1", "from": 0.1, "cat": True},
    {"job": "farmer", "home": "w2", "work": "garten1", "from": 0.14},
    {"job": "shop", "home": "cafe", "from": 0.18},
    {"job": "stroll", "home": "dom", "from": 0.22},
    {"job": "farmer", "home": "w5", "work": "garten2", "from": 0.26, "dog": True},
    {"job": "stroll", "home": "w14", "from": 0.3, "dog": True},
    {"job": "kid", "home": "schule", "from": 0.35, "dog": True},
    {"job": "read", "home": "buecherei", "from": 0.4},
    {"job": "kid", "home": "schule", "from": 0.45},
    {"job": "farmer", "home": "w9", "work": "garten3", "from": 0.5},
    {"job": "hike", "home": "w3", "from": 0.55, "dog": True},
    {"job": "kid", "home": "schule", "from": 0.6},
    {"job": "stroll", "home": "w7", "from": 0.66, "cat": True},
    {"job": "read", "home": "w11", "from": 0.72},
    {"job": "hike", "home": "w13", "from": 0.78},
    {"job": "stroll", "home": "w16", "from": 0.85},
    {"job": "stroll", "home": "w10", "from": 0.92, "cat": True},
]

# --- Übrige Blöcke: Gebäude ---
structures = []
dry = []
for i in range(len(XS) - 1):
    for j in range(len(YS) - 1):
        if (i, j) in village_blocks or (i, j) in PARKS:
            continue
        r = block_rect(i, j)
        x0, y0, x1, y1 = r
        mx, my = (x0 + x1) / 2, (y0 + y1) / 2
        if (i, j) in BRACHE:
            dry.append([round(mx), round(my), 22])
            continue
        downtown = abs(i - ci) <= 2 and abs(j - cj) <= 2
        # Wohnblocks längs an den oberen und unteren Rand, an die Seiten mittig Hochhäuser oder Wohnblocks;
        # dazwischen Durchgänge, in der Mitte bleibt ein Innenhof frei
        spots = [(x0 + 10, y0 + 6, "apartment"), (x1 - 10, y0 + 6, "apartment"), (x0 + 10, y1 - 6, "apartment"), (x1 - 10, y1 - 6, "apartment")]
        if downtown or rnd.random() < 0.5:
            side = "tower" if downtown or rnd.random() < 0.4 else "apartment"
            off = 6 if side == "apartment" else 6
            spots += [(x0 + off, my, side), (x1 - off, my, side)]
        for (x, y, kind) in spots:
            if river_dist((x, y)) < 16:   # nicht ans oder ins Wasser
                continue
            structures.append({"type": kind, "pos": [round(x), round(y)], "rot": facing(x, y, r)})

start = [center[0], center[1] + 13]
region = {
    "_info": "Region Großstadt (dritte Region), erzeugt von tools/gen_city.py. Größe, Start, Bienenstock, Vogelhäuschen (nest_cell) und Ladestation der Drohnen (dock_cell) in Zellen. ground.paved = Straßen aus Asphalt. dry = Brachflächen (dürr). village = Altstadt um den Marktplatz wie im Heimatdorf (rot = Drehung in Grad statt Blick zum Platz). structures = Gebäude der übrigen Blöcke (types: Hindernis und Platzbedarf in Pixeln, Größe; list: Art, Zelle, Drehung in Grad): Sie erwachen mit dem Grün unter ihnen und bekommen dann einen Dachgarten.",
    "name": "Großstadt",
    "width_cells": W,
    "height_cells": H,
    "start_cell": start,
    "hive_cell": [start[0] - 12, start[1] + 6],
    "nest_cell": [start[0] + 12, start[1] + 6],
    "dock_cell": [start[0], start[1] + 9],
    "intro": {"art": "robot", "title": "Großstadt", "text": "Straßen, Häuserblocks und ein Fluss, alles grau und verlassen.\nHier helfen bald Gärtner-Drohnen: Sie begrünen ganze Höfe und Dächer."},
    "finished_title": "Die Stadt lebt wieder!",
    "finished_text": "Grüne Höfe, Gärten auf den Dächern, Menschen auf dem Marktplatz:\nDie Großstadt ist wiederhergestellt.",
    "finished_banner": "Die Großstadt ist wiederhergestellt!",
    "ground": {"paved": 1.0},
    "dry": {"seed": 9, "wobble": 0.25, "patches": dry},
    "village": {
        "center": center,
        "plaza_radius": 10.0,
        "fountain": center,
        "fountain_type": "fountain_city",
        "buildings": buildings,
        "props": props,
        "types": {
            "cathedral": {"block": 76, "radius": 130},
            "school_city": {"block": 66, "radius": 120},
            "museum": {"block": 62, "radius": 100},
            "cafe": {"block": 52, "radius": 90},
            "apartment": {"block": 120, "radius": 230},
            "raised_beds": {"block": 0, "radius": 64},
            "playground": {"block": 0, "radius": 72},
        },
        "residents": residents,
        "people_speed_px": 85,
        "repair_sec": 12.0,
        "hub_cells": 80,
        "local_cells": 90,
        "yard_radius_px": 110,
        "arrive_from_cells": 22,
        "arrive_spread_sec": 3.0,
        "wait_sec": [1.5, 5.0],
        "fest_sec": 10.0,
        "fest_petals_per_sec": 40,
    },
    "structures": {
        "types": {
            "apartment": {"block": 120, "radius": 230, "size": [0.95, 1.0]},
            "tower": {"block": 130, "radius": 175, "size": [1.0, 1.05]},
        },
        "list": structures,
    },
}

world = {
    "_info": "Straßen und Fluss der Großstadt, erzeugt von tools/gen_city.py. Punkte in Zellen, Breite in Zellen. Brücken entstehen, wo eine Straße den Fluss kreuzt. plazas = Marktplatz.",
    "rivers": [{"name": "Stadtfluss", "width": 8.0, "wiggle": 1.2, "points": RIVER}],
    "paths": [{"width": STREET_W, "wiggle": 0.0, "points": [[x, -6], [x, H + 6]]} for x in XS]
    + [{"width": STREET_W, "wiggle": 0.0, "points": [[-6, y], [W + 6, y]]} for y in YS],
    "plazas": [{"name": "Marktplatz", "center": center, "radius": 10.0}],
    "bridge_width": 7.0,
    "bridge_overhang": 1.5,
}

objects = {
    "_info": "Objekte der Großstadt: wenige, vor allem in Parks und am Fluss (Gewichte in areas.json). Am Straßenrand nichts.",
    "seed": 3031,
    "min_gap_px": 24,
    "keep_free": {"radius_cells": 10},
    "tries": 60,
    "types": {
        "pond": {"count": 8, "radius_px": 110, "block_px": 0},
        "willow": {"count": 14, "radius_px": 80, "block_px": 32, "size": [0.9, 1.15], "near_water_cells": 6, "tries": 600},
        "oak": {"count": 40, "radius_px": 76, "block_px": 36, "size": [0.85, 1.2]},
        "fir": {"count": 12, "radius_px": 56, "block_px": 28, "size": [0.8, 1.25]},
        "rock": {"count": 10, "radius_px": 62, "block_px": 44, "size": [0.75, 1.15]},
        "fruit": {"count": 10, "radius_px": 58, "block_px": 28, "size": [0.85, 1.1]},
        "birch": {"count": 40, "radius_px": 50, "block_px": 22, "size": [0.85, 1.15]},
        "bush": {"count": 140, "radius_px": 48, "block_px": 0, "size": [0.8, 1.15]},
        "sapling": {"count": 60, "radius_px": 26, "block_px": 0, "size": [0.8, 1.2], "quiet": True},
    },
    "wayside": {"every_cells": [10, 18], "offset_cells": 1.4, "kinds": [], "radius_px": 40},
    "awake_check_sec": 0.2,
    "awake_petals": 24,
    "max_bursts_per_check": 6,
    "wayside_petals": 8,
}

parks = sorted(PARKS)
park_pts = [[round((block_rect(i, j)[0] + block_rect(i, j)[2]) / 2), round((block_rect(i, j)[1] + block_rect(i, j)[3]) / 2)] for (i, j) in parks]
few = {"pond": 0.1, "oak": 0.15, "fir": 0.1, "rock": 0.2, "fruit": 0.1, "birch": 0.2, "bush": 0.3, "sapling": 0.3}
areas = {
    "_info": "Gebiete der Großstadt, erzeugt von tools/gen_city.py. Felder wie in heimatdorf/areas.json.",
    "seed": 23,
    "warp_cells": 40,
    "warp_scale_cells": 150,
    "areas": [
        {"name": "Altstadt", "points": [center], "grass": [1.0, 1.04, 0.9], "dry": [1.02, 1.0, 0.96], "flowers": 1.4, "tufts": 0.8,
         "flower_color": [1.0, 0.56, 0.69], "flower_share": 0.5, "objects": few, "extra": {}},
        {"name": "Innenstadt", "points": [[center[0] - 110, center[1]], [center[0] + 110, center[1]], [center[0], center[1] + 110]],
         "grass": [0.96, 1.04, 0.98], "dry": [0.98, 0.98, 1.0], "flowers": 0.9, "tufts": 0.7,
         "flower_color": [0.72, 0.55, 0.95], "flower_share": 0.4, "objects": few, "extra": {}},
        {"name": "Stadtpark", "points": park_pts, "grass": [0.92, 1.06, 0.92], "dry": [0.98, 1.0, 1.0], "flowers": 1.6, "tufts": 1.1,
         "flower_color": [1.0, 0.85, 0.30], "flower_share": 0.45,
         "objects": {"pond": 4.0, "oak": 6.0, "fir": 2.0, "rock": 1.0, "fruit": 2.0, "birch": 5.0, "bush": 4.0, "sapling": 3.0},
         "extra": {"oak": 20, "birch": 16, "pond": 4, "bush": 40}},
        {"name": "Flussufer", "points": [p for p in RIVER[1:-1]], "grass": [0.86, 1.0, 1.08], "dry": [0.96, 0.99, 1.04], "flowers": 1.0, "tufts": 1.2,
         "flower_color": [0.55, 0.75, 1.0], "flower_share": 0.5,
         "objects": {"pond": 0.5, "oak": 2.0, "fir": 0.5, "rock": 1.0, "fruit": 0.5, "birch": 3.0, "bush": 2.0, "sapling": 2.0}, "extra": {"birch": 10}},
        {"name": "Wohnviertel", "points": [[120, 100], [150, 470], [420, 620], [700, 620]], "grass": [1.04, 1.05, 0.88], "dry": [1.02, 1.0, 0.95],
         "flowers": 1.1, "tufts": 0.9, "flower_color": [1.0, 0.45, 0.35], "flower_share": 0.45, "objects": few, "extra": {}},
        {"name": "Gewerbegebiet", "points": [[900, 120], [920, 600]], "grass": [1.08, 1.04, 0.82], "dry": [1.0, 0.99, 0.97],
         "flowers": 0.6, "tufts": 1.0, "flower_color": [1.0, 1.0, 0.96], "flower_share": 0.5, "objects": few, "extra": {}},
    ],
    "banner": {"confirm_sec": 1.0, "fade_in_sec": 0.8, "hold_sec": 2.5, "fade_out_sec": 1.4},
}

out = os.path.join(os.path.dirname(__file__), "..", "data", "regions", "stadt")
os.makedirs(out, exist_ok=True)
for name, data in [("region", region), ("world", world), ("objects", objects), ("areas", areas)]:
    with open(os.path.join(out, name + ".json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, ensure_ascii=False, indent="\t")
        f.write("\n")
print("Gebäude: %d Dorf, %d Stadt, %d Brachflächen" % (len(buildings), len(structures), len(dry)))
