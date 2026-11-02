# Grobes Modell der Spieldauer (kein echtes Spiel): Der Spieler fährt ständig und kauft immer den
# billigsten verfügbaren Knoten. Roboter begrünt Tempo × Spurbreite × Grau-Anteil × Fahreffizienz,
# dazu Ausbreitung (Zellen/s) und Bienen (Blütenfläche / Flugzyklus). Nur zum Vergleichen von Preisen.
# Aufruf: python tools/balance_sim.py data/skilltree.json [fahreffizienz] [breite] [höhe] [kostenfaktor] [pollen_je_zelle]
#   z. B. python tools/balance_sim.py data/skilltree.json 0.4 640 480 1 0.005
import json, math, sys
data = json.load(open(sys.argv[1], encoding='utf-8'))
nodes = {n['id']: n for n in data['nodes']}
lvl = {k: 0 for k in nodes}; lvl['root'] = 1
drive_eff = float(sys.argv[2]) if len(sys.argv) > 2 else 0.6
TOTAL = int(sys.argv[3]) * int(sys.argv[4]) if len(sys.argv) > 4 else 320 * 240
CM = float(sys.argv[5]) if len(sys.argv) > 5 else 1.0
PR = float(sys.argv[6]) if len(sys.argv) > 6 else 0.01
def stat(s): return sum(nodes[k]['effects'].get(s, 0) * lvl[k] for k in nodes)
def cost(k): return math.floor(nodes[k]['base_cost'] * CM * nodes[k]['cost_growth'] ** lvl[k])
def avail(k):
    n = nodes[k]
    return lvl[k] < n['max_level'] and (not n['requires'] or any(lvl[r] > 0 for r in n['requires']))
green, pollen, t = 28.0, 0.0, 0
src = {'robot': 0.0, 'spread': 0.0, 'bees': 0.0}
log = []
while green < TOTAL and t < 6 * 3600:
    c = green / TOTAL
    r = 3 + stat('radius'); v = 380 * (1 + stat('speed') / 100) / 24
    robot = v * 2 * r * (1 - c) * drive_eff
    spread = stat('spread') if c < 0.999 else 0
    bees = stat('bees'); bs = 1 + stat('bee_speed') / 100
    cycle = 12 * 24 / (260 * bs) + 2.0 * (1 - stat('bee_rest') / 100)
    bloom = 2.3 + stat('bloom')
    beecells = bees * math.pi * bloom ** 2 * 0.8 / cycle
    src['robot'] += robot; src['spread'] += spread; src['bees'] += beecells
    green = min(TOTAL, green + robot + spread + beecells)
    pollen += green * PR * (1 + stat('pollen') / 100)
    while True:
        opts = sorted((cost(k), k) for k in nodes if avail(k))
        if not opts or opts[0][0] > pollen: break
        pollen -= opts[0][0]; lvl[opts[0][1]] += 1
    t += 1
    for mark in (0.1, 0.25, 0.5, 0.75, 0.9, 0.99):
        if c < mark <= green / TOTAL: log.append((mark, t))
bought = sum(lvl.values()) - 1; total = sum(n['max_level'] for n in nodes.values()) - 1
for m, tt in log: print(f"{int(m*100):3d} % nach {tt/60:5.1f} min")
print(f"fertig nach {t/60:.1f} min, Stufen gekauft {bought}/{total}")
print("Anteile:", {k: round(v / sum(src.values()) * 100) for k, v in src.items()})
print("nicht gekauft:", [k for k in nodes if lvl[k] < nodes[k]['max_level']])
