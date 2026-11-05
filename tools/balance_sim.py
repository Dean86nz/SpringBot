# Grobes Modell der Spieldauer (kein echtes Spiel): Der Spieler fährt ständig und kauft immer den
# billigsten verfügbaren Knoten. Roboter begrünt Tempo × Spurbreite × Grau-Anteil × Fahreffizienz,
# dazu Ausbreitung (Zellen/s), Bienen (Blütenfläche / Flugzyklus) und Samenvögel (Streifen / Flugrunde).
# Dürre Stellen (region.json "dry"): Dort schaffen Ausbreitung und Bienen nichts, nur Roboter und Vögel
# (Vögel zielen bevorzugt dorthin).
# Nur zum Vergleichen von Preisen.
# Aufruf: python tools/balance_sim.py data/skilltree.json [fahreffizienz] [breite] [höhe] [kostenfaktor] [pollen_je_zelle]
#   z. B. python tools/balance_sim.py data/skilltree.json 0.4 640 480 1 0.005
# Reise (Phase 3): mit --reise werden die Regionen nacheinander gespielt (Größen aus data/regions/*, Land
#   ca. 95 % der Fläche); Äste einer Region (Knoten mit "region") gibt es erst ab dort, fertige Regionen
#   bringen einen Anteil ihrer Pollen weiter (campaign.json "finished_pollen_share").
#   z. B. python tools/balance_sim.py data/skilltree.json 0.4 0 0 1 0.005 --reise
import json, math, sys

reise = '--reise' in sys.argv
args = [a for a in sys.argv if a != '--reise']
data = json.load(open(args[1], encoding='utf-8'))
nodes = {n['id']: n for n in data['nodes']}
lvl = {k: 0 for k in nodes}; lvl['root'] = 1
drive_eff = float(args[2]) if len(args) > 2 else 0.6
CM = float(args[5]) if len(args) > 5 else 1.0
PR = float(args[6]) if len(args) > 6 else 0.01
birds_cfg = json.load(open('data/balance.json', encoding='utf-8')).get('birds', {})


def stat(s): return sum(nodes[k]['effects'].get(s, 0) * lvl[k] for k in nodes)
def cost(k): return math.floor(nodes[k]['base_cost'] * CM * nodes[k]['cost_growth'] ** lvl[k])


def avail(k, reached):
    n = nodes[k]
    if n.get('region', '') and n['region'] not in reached:
        return False
    return lvl[k] < n['max_level'] and (not n['requires'] or any(lvl[r] > 0 for r in n['requires']))


def play(total, reached, bonus_cells, pollen, dry_share=0.0):
    green, t = 28.0, 0
    dry_total = total * dry_share
    green_dry = 0.0
    src = {'robot': 0.0, 'spread': 0.0, 'bees': 0.0, 'birds': 0.0}
    log = []
    while green < total and t < 6 * 3600:
        c = green / total
        r = 3 + stat('radius'); v = 380 * (1 + stat('speed') / 100) / 24
        robot = v * 2 * r * (1 - c) * drive_eff
        spread = stat('spread') if c < 0.999 else 0
        bees = stat('bees'); bs = 1 + stat('bee_speed') / 100
        cycle = 12 * 24 / (260 * bs) + 2.0 * (1 - stat('bee_rest') / 100)
        bloom = 2.3 + stat('bloom')
        beecells = bees * math.pi * bloom ** 2 * 0.8 / cycle
        # Samenvögel: drei Streifen je Runde (Anflug je ~45 Zellen), Heimflug ~60 Zellen, Rast im Häuschen
        flocks = stat('birds')
        bv = birds_cfg.get('speed_px', 320) * (1 + stat('bird_speed') / 100) / 24
        strip = birds_cfg.get('strip_cells', 30) + stat('strip')
        width = 2 * (birds_cfg.get('width_cells', 1.6) + stat('strip_width'))
        rest = birds_cfg.get('rest_sec', 4.0) * max(0.1, 1 - stat('bird_rest') / 100)
        trips = birds_cfg.get('trips_home', 3)
        grey_hit = min(1.0, (1 - c) * 1.6)   # bester von mehreren Streifen: mehr Grau als der Schnitt
        birdcells = flocks * trips * strip * width * grey_hit / ((trips * (45 + strip) + 60) / bv + rest)
        green_wet = green - green_dry
        grey_dry = dry_total - green_dry
        grey_wet = max(total - dry_total - green_wet, 0.0)
        grey = max(grey_dry + grey_wet, 1e-9)
        if grey_wet <= 0:
            spread = 0; beecells = 0
        to_dry = robot * grey_dry / grey + birdcells * 3 * grey_dry / max(3 * grey_dry + grey_wet, 1e-9)
        if grey_dry > 0 and grey_wet < total * 0.02:
            # Nur noch dürre Flecken: Der Spieler fährt gezielt hin (sichtbar braun), Vögel zielen ohnehin dorthin
            robot = v * 2 * r * drive_eff * 0.35
            birdcells = birdcells / max(grey_hit, 1e-9) * 0.6
            to_dry = robot + birdcells
        to_wet = robot + birdcells - to_dry + spread + beecells
        green_dry = min(dry_total, green_dry + to_dry)
        green_wet = min(total - dry_total, green_wet + to_wet)
        src['robot'] += robot; src['spread'] += spread; src['bees'] += beecells; src['birds'] += birdcells
        green = green_wet + green_dry
        if total - green < 0.5:
            green = total
        pollen += (green + bonus_cells) * PR * (1 + stat('pollen') / 100)
        while True:
            opts = sorted((cost(k), k) for k in nodes if avail(k, reached))
            if not opts or opts[0][0] > pollen: break
            pollen -= opts[0][0]; lvl[opts[0][1]] += 1
        t += 1
        for mark in (0.1, 0.25, 0.5, 0.75, 0.9, 0.99):
            if c < mark <= green / total: log.append((mark, t))
    for m, tt in log: print(f"{int(m*100):3d} % nach {tt/60:5.1f} min")
    print(f"fertig nach {t/60:.1f} min, Pollen übrig {pollen:,.0f}")
    print("Anteile:", {k: round(v / max(sum(src.values()), 1) * 100) for k, v in src.items()})
    return pollen


if reise:
    camp = json.load(open('data/campaign.json', encoding='utf-8'))
    share = camp.get('finished_pollen_share', 0.25)
    reached, bonus, pollen = [], 0.0, 0.0
    for r in camp['regions']:
        info = json.load(open('data/regions/%s/region.json' % r['id'], encoding='utf-8'))
        total = int(info['width_cells'] * info['height_cells'] * 0.95)
        dry = sum(math.pi * pa[2] ** 2 for pa in info.get('dry', {}).get('patches', [])) / total
        reached.append(r['id'])
        print(f"--- {info['name']} ({total} Zellen Land, {dry * 100:.0f} % dürr, Bonus {bonus:,.0f} Zellen)")
        pollen = play(total, reached, bonus, pollen, dry)
        bonus += total * share
else:
    total = int(args[3]) * int(args[4]) if len(args) > 4 else 320 * 240
    play(total, list({n.get('region', '') for n in nodes.values()}), 0.0, 0.0)
bought = sum(lvl.values()) - 1; all_levels = sum(n['max_level'] for n in nodes.values()) - 1
print(f"Stufen gekauft {bought}/{all_levels}")
print("nicht gekauft:", [k for k in nodes if lvl[k] < nodes[k]['max_level']])
