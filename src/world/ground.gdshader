// Boden: graue Welt und Grün, alles prozedural auf der Grafikkarte (keine Einzelobjekte).
// mask: Anzeige-Maske je Zelle (weich gefiltert), 0 = grau, 1 = grün.
// since_tex: je Zelle die Spielsekunde + 1, ab der sie grün ist (RG = 16 Bit, nie filtern).
// Deko liegt in Kacheln: Jede Kachel entscheidet per Zufallswert, ob dort etwas steht.
// Grün: Grüntöne, Grasbüschel, Blumen; je länger grün (lush 0..1), desto dichter und bunter.
// Blumen nur in Gruppen: große Blumenwiesen und kleine Inseln (Rauschen), dazwischen ruhiges Gras.
// Grau: Risse, Steinchen, trockene Halme. Werte setzt ground_view.gd aus data/balance.json.
// terrain_tex: weiche Masken für Wege (R) und Wasser (G), 0,5 genau auf dem Rand. Wege und Wasser
// liegen über dem Boden; sie werden lebendiger (warmes Braun, klares Blau), wenn daneben Grün ist.
// Wege rein optisch: im Grau staubig mit Flecken und Rissen; je grüner daneben, desto mehr
// Kiesel, Zweige und Laub liegen darauf (erscheinen Stück für Stück, nicht überblendet).
// Weg- und Wasserzellen neben grünem Land sind in der Maske grün (GroundGrid), daher kein Grau am Rand.
shader_type canvas_item;

uniform sampler2D mask : filter_linear, repeat_disable;
uniform sampler2D since_tex : filter_nearest, repeat_disable;
uniform sampler2D terrain_tex : filter_linear, repeat_disable;
uniform float cell_px = 24.0;
uniform vec2 map_size;
uniform float now = 0.0;
uniform float lush_sec = 300.0;
uniform float tuft_tile = 26.0;
uniform float tuft_young = 0.12;
uniform float tuft_old = 0.6;
uniform float tuft_alpha = 0.6;
uniform float flower_tile = 34.0;
uniform float flower_young = 0.04;
uniform float flower_old = 0.5;
uniform float color_from = 0.25;   // ab diesem lush kommen bunte Blumen dazu
uniform float meadow_scale = 700.0;
uniform float meadow_detail_scale = 260.0;
uniform float meadow_threshold = 0.6;   // höher = weniger Blumenwiesen
uniform float island_scale = 120.0;
uniform float island_threshold = 0.8;   // höher = weniger Blumeninseln
uniform float island_strength = 0.7;
uniform float calm_flowers = 0.05;      // Anteil der Blumen im ruhigen Gras
uniform float crack_tile = 96.0;
uniform float crack_density = 0.4;
uniform float pebble_tile = 44.0;
uniform float pebble_density = 0.22;
uniform float stalk_tile = 38.0;
uniform float stalk_density = 0.25;
uniform float path_pebbles = 0.45;   // Anteil der Kachel-Plätze mit Kiesel, wenn ganz grün daneben
uniform float path_twigs = 0.22;
uniform float path_leaves = 0.35;

const vec3 PAL[7] = vec3[7](
	vec3(1.0, 1.0, 0.96), vec3(1.0, 0.85, 0.30), vec3(1.0, 0.56, 0.69), vec3(0.72, 0.55, 0.95),
	vec3(1.0, 0.45, 0.35), vec3(0.55, 0.75, 1.0), vec3(1.0, 0.66, 0.30));

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

// Hash ohne sin(): auf GPUs mit geringer Genauigkeit stabil (sonst harte Kanten im Rauschen)
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	return length(pa - ba * clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0));
}

// 0..1: wie lange die Stelle schon grün ist (gemessen an der Kachelmitte)
float lush_at(vec2 p) {
	vec2 t = texture(since_tex, p / map_size).rg * 255.0;
	float s = floor(t.r + 0.5) + floor(t.g + 0.5) * 256.0;
	if (s < 0.5) {
		return 0.0;
	}
	return clamp((now - (s - 1.0)) / lush_sec, 0.0, 1.0);
}

// Grasbüschel: 4 Halme aus einem Punkt, wachsen beim Erscheinen
vec4 tuft(vec2 p) {
	vec2 id = floor(p / tuft_tile);
	float h = hash(id + 11.0);
	float dens = mix(tuft_young, tuft_old, lush_at((id + 0.5) * tuft_tile));
	if (h > dens) {
		return vec4(0.0);
	}
	float grow = clamp((dens - h) / 0.06, 0.0, 1.0);
	vec2 base = (id + vec2(0.3 + 0.4 * hash(id + 3.1), 0.75 + 0.12 * hash(id + 7.7))) * tuft_tile;
	vec2 q = p - base;
	float len = tuft_tile * 0.45 * (0.4 + 0.6 * grow) * (0.8 + 0.25 * hash(id + 5.5));
	float d = 1e3;
	for (int k = 0; k < 4; k++) {
		float a = -1.5708 + (float(k) - 1.5) * 0.36 + (hash(id + float(k) * 1.7) - 0.5) * 0.25;
		d = min(d, seg(q, vec2(0.0), vec2(cos(a), sin(a)) * len * (0.75 + 0.25 * float(k % 2))));
	}
	vec3 c = mix(vec3(0.24, 0.52, 0.20), vec3(0.50, 0.76, 0.28), hash(id + 9.9));
	return vec4(c, (1.0 - smoothstep(0.9, 2.0, d)) * tuft_alpha);
}

// 0..1: wie stark hier Blumen wachsen (Wiese 1, Insel island_strength, ruhiges Gras calm_flowers)
float bloom_zone(vec2 p) {
	float m = vnoise(p / meadow_scale + 5.3) * 0.65 + vnoise(p / meadow_detail_scale + 91.7) * 0.35;
	float meadow = smoothstep(meadow_threshold - 0.04, meadow_threshold + 0.04, m);
	float island = smoothstep(island_threshold - 0.03, island_threshold + 0.03, vnoise(p / island_scale + 33.1)) * island_strength;
	return max(max(meadow, island), calm_flowers);
}

// Blume mit 5 Blütenblättern und gelber Mitte, kleiner Schatten. Junges Grün: nur weiß/gelb,
// bunte Blumen erscheinen erst später (keine Blume wechselt ihre Farbe).
vec4 flower(vec2 p) {
	vec2 id = floor(p / flower_tile);
	float h = hash(id + 23.0);
	float lush = lush_at((id + 0.5) * flower_tile);
	int ci = int(floor(hash(id + 6.6) * 6.999));
	float dens = mix(flower_young, flower_old, lush) * bloom_zone((id + 0.5) * flower_tile);
	if (ci >= 2) {
		dens *= smoothstep(color_from, 1.0, lush);
	}
	if (h > dens) {
		return vec4(0.0);
	}
	float grow = clamp((dens - h) / 0.08, 0.0, 1.0);
	vec2 c = (id + 0.3 + 0.4 * vec2(hash(id + 1.3), hash(id + 9.1))) * flower_tile;
	float R = flower_tile * (0.19 + 0.07 * hash(id + 4.4)) * (0.4 + 0.6 * grow) + 0.01;
	float rot = hash(id + 2.2) * 6.2832;
	vec2 q = p - c;
	vec2 qs = q - vec2(1.5, 2.0);
	float edge = R * (0.55 + 0.45 * abs(cos(2.5 * (atan(q.y, q.x) + rot))));
	float edge_s = R * (0.55 + 0.45 * abs(cos(2.5 * (atan(qs.y, qs.x) + rot))));
	float petal = 1.0 - smoothstep(edge - 0.8, edge + 0.6, length(q));
	float shadow = (1.0 - smoothstep(edge_s - 0.8, edge_s + 0.6, length(qs))) * 0.22;
	float centre = 1.0 - smoothstep(R * 0.3 - 0.7, R * 0.3 + 0.6, length(q));
	vec3 pc = mix(PAL[ci] * 0.82, PAL[ci], smoothstep(0.0, 2.0, edge - length(q)));   // Rand etwas dunkler
	vec3 col = mix(pc, vec3(1.0, 0.80, 0.25), centre);
	return petal > shadow ? vec4(col, petal) : vec4(vec3(0.0), shadow);
}

// Riss: kurze Zickzacklinie in der Kachel
float crack(vec2 p) {
	vec2 id = floor(p / crack_tile);
	if (hash(id + 31.0) > crack_density) {
		return 0.0;
	}
	vec2 q = p / crack_tile - id;
	vec2 a = vec2(0.2 + 0.2 * hash(id + 1.0), 0.2 + 0.6 * hash(id + 2.0));
	float d = 1e3;
	for (int k = 0; k < 4; k++) {
		vec2 b = clamp(a + (vec2(hash(id + float(k) + 4.0), hash(id + float(k) + 8.0)) - vec2(0.2, 0.5)) * 0.3, 0.08, 0.92);
		d = min(d, seg(q, a, b));
		if (k == 1) {
			d = min(d, seg(q, b, b + vec2(0.05, 0.15) * (hash(id + 13.0) - 0.5) * 2.0));
		}
		a = b;
	}
	return 1.0 - smoothstep(0.6, 1.6, d * crack_tile);
}

// Steinchen mit Schatten und hellem Fleck
vec4 pebble(vec2 p) {
	vec2 id = floor(p / pebble_tile);
	if (hash(id + 41.0) > pebble_density) {
		return vec4(0.0);
	}
	vec2 c = (id + 0.3 + 0.4 * vec2(hash(id + 2.5), hash(id + 6.5))) * pebble_tile;
	float r = 2.5 + 3.5 * hash(id + 8.5);
	vec2 q = p - c;
	float body = 1.0 - smoothstep(r - 0.7, r + 0.6, length(q * vec2(1.0, 1.25)));
	float sh = (1.0 - smoothstep(r - 0.7, r + 0.6, length((q - vec2(1.5, 2.0)) * vec2(1.0, 1.25)))) * 0.25;
	vec3 c1 = mix(vec3(0.58, 0.56, 0.53), vec3(0.76, 0.74, 0.70), hash(id + 3.3));
	c1 = mix(c1, c1 + 0.08, 1.0 - smoothstep(0.0, r * 0.6, length(q + vec2(r * 0.3))));
	return body > sh ? vec4(c1, body) : vec4(vec3(0.0), sh);
}

// Trockene Halme: 3 braune Striche
vec4 stalk(vec2 p) {
	vec2 id = floor(p / stalk_tile);
	if (hash(id + 51.0) > stalk_density) {
		return vec4(0.0);
	}
	vec2 base = (id + vec2(0.3 + 0.4 * hash(id + 1.5), 0.7 + 0.15 * hash(id + 2.5))) * stalk_tile;
	vec2 q = p - base;
	float d = 1e3;
	for (int k = 0; k < 3; k++) {
		float a = -1.5708 + (float(k) - 1.0) * 0.5 + (hash(id + float(k) * 2.3) - 0.5) * 0.4;
		d = min(d, seg(q, vec2(0.0), vec2(cos(a), sin(a)) * stalk_tile * (0.22 + 0.12 * hash(id + float(k)))));
	}
	return vec4(vec3(0.62, 0.55, 0.42), (1.0 - smoothstep(0.5, 1.4, d)) * 0.85);
}

// Wie grün ist es rund um p (Mittel aus 8 Richtungen, 4 Zellen weit)? Für Wege und Wasser,
// die selbst nie grün werden; das Mittel gibt weiche Übergänge statt harter Kanten.
float green_near(vec2 p) {
	vec2 uv = p / map_size;
	vec2 d = vec2(4.0 * cell_px) / map_size;
	float sum = 0.0;
	for (int k = 0; k < 8; k++) {
		float a = float(k) * 0.7854;
		sum += texture(mask, uv + vec2(cos(a), sin(a)) * d).r;
	}
	return smoothstep(0.08, 0.45, sum / 8.0);
}

// Kieselsteinchen auf dem Weg: erscheint, wenn hash < amount (amount wächst mit dem Grün daneben)
vec4 path_pebble(vec2 p, float amount) {
	float tile = 16.0;
	vec2 id = floor(p / tile);
	float h = hash(id + 61.0);
	if (h > amount) {
		return vec4(0.0);
	}
	vec2 c = (id + 0.25 + 0.5 * vec2(hash(id + 1.7), hash(id + 4.9))) * tile;
	float r = 1.6 + 2.2 * hash(id + 2.9);
	vec2 q = p - c;
	float body = 1.0 - smoothstep(r - 0.6, r + 0.5, length(q * vec2(1.0, 1.3)));
	float sh = (1.0 - smoothstep(r - 0.6, r + 0.5, length((q - vec2(1.0, 1.4)) * vec2(1.0, 1.3)))) * 0.22;
	float k = hash(id + 7.3);
	vec3 c1 = k < 0.4 ? vec3(0.86, 0.83, 0.76) : (k < 0.7 ? vec3(0.70, 0.66, 0.60) : vec3(0.80, 0.68, 0.55));
	c1 = mix(c1, c1 + 0.08, 1.0 - smoothstep(0.0, r * 0.7, length(q + vec2(r * 0.35))));
	return body > sh ? vec4(c1, body) : vec4(vec3(0.0), sh);
}

// Zweig: Ast mit einer Gabel, quer über den Weg gefallen
vec4 path_twig(vec2 p, float amount) {
	float tile = 46.0;
	vec2 id = floor(p / tile);
	if (hash(id + 71.0) > amount) {
		return vec4(0.0);
	}
	vec2 c = (id + 0.3 + 0.4 * vec2(hash(id + 3.3), hash(id + 5.1))) * tile;
	float a = hash(id + 8.8) * 6.2832;
	vec2 dir = vec2(cos(a), sin(a));
	float len = tile * (0.22 + 0.12 * hash(id + 9.4));
	vec2 a0 = c - dir * len;
	vec2 a1 = c + dir * len;
	vec2 fork = mix(a0, a1, 0.6);
	float b = a + (hash(id + 2.1) < 0.5 ? 0.6 : -0.6);
	float d = min(seg(p, a0, a1), seg(p, fork, fork + vec2(cos(b), sin(b)) * len * 0.55));
	vec3 col = mix(vec3(0.42, 0.30, 0.20), vec3(0.55, 0.42, 0.28), hash(id + 6.2));
	return vec4(col, 1.0 - smoothstep(0.6, 1.5, d));
}

// Blatt: spitzes Oval mit Mittelrippe, frisch grün bis gelblich
vec4 path_leaf(vec2 p, float amount) {
	float tile = 24.0;
	vec2 id = floor(p / tile);
	if (hash(id + 81.0) > amount) {
		return vec4(0.0);
	}
	vec2 c = (id + 0.25 + 0.5 * vec2(hash(id + 4.1), hash(id + 7.9))) * tile;
	float a = hash(id + 3.7) * 6.2832;
	vec2 q = p - c;
	q = vec2(q.x * cos(a) + q.y * sin(a), -q.x * sin(a) + q.y * cos(a));
	float L = 3.5 + 2.5 * hash(id + 5.3);
	float w = L * 0.45 * (1.0 - (q.x / L) * (q.x / L));
	float body = (1.0 - smoothstep(-0.4, 0.6, abs(q.y) - w)) * step(abs(q.x), L);
	float k = hash(id + 9.7);
	vec3 col = k < 0.5 ? vec3(0.42, 0.66, 0.26) : (k < 0.8 ? vec3(0.62, 0.72, 0.28) : vec3(0.78, 0.62, 0.30));
	col = mix(col * 0.8, col, smoothstep(0.0, 0.9, abs(q.y)));   // Mittelrippe
	return vec4(col, body * 0.95);
}

vec3 paths_and_water(vec2 p, vec3 col, vec2 tr, float near, float big, float small) {
	// Erdweg: im Grau staubig mit Flecken und Rissen; neben Grün warmes Braun mit Kieseln,
	// Zweigen und Laub, Grassaum am Rand.
	float pv = tr.x + (small - 0.5) * 0.22;
	float pe = smoothstep(0.45, 0.55, pv);
	if (pe > 0.001) {
		vec3 dirt = mix(vec3(0.60, 0.56, 0.49), vec3(0.76, 0.61, 0.43), near) + (big - 0.5) * 0.06 + (small - 0.5) * 0.05;
		float dull = 1.0 - near;
		if (dull > 0.001) {
			float blot = smoothstep(0.45, 0.75, vnoise(p / 30.0 + 71.0) * 0.7 + vnoise(p / 9.0 + 13.0) * 0.3);
			dirt = mix(dirt, vec3(0.50, 0.47, 0.42), blot * 0.5 * dull);
			dirt = mix(dirt, dirt * 0.75, crack(p * 0.7 + 5.0) * 0.7 * dull);
		}
		if (near > 0.001) {
			vec4 pb = path_pebble(p, near * path_pebbles);
			dirt = mix(dirt, pb.rgb, pb.a);
			vec4 tw = path_twig(p, near * path_twigs);
			dirt = mix(dirt, tw.rgb, tw.a);
			vec4 lf = path_leaf(p, near * path_leaves);
			dirt = mix(dirt, lf.rgb, lf.a);
		}
		col = mix(col, dirt, pe);
	}
	float fringe = smoothstep(0.40, 0.5, pv) * (1.0 - smoothstep(0.52, 0.64, pv));
	col = mix(col, vec3(0.34, 0.63, 0.27), fringe * near * 0.8);
	// Wasser: Uferstreifen, Wasser mit leichtem Glitzern, dunkle Uferlinie
	float wv = tr.y + (small - 0.5) * 0.12;
	float bank = smoothstep(0.30, 0.46, wv);
	float we = smoothstep(0.48, 0.55, wv);
	vec3 shore = mix(vec3(0.60, 0.57, 0.52), vec3(0.66, 0.58, 0.42), near);
	vec3 water = mix(vec3(0.53, 0.60, 0.65), vec3(0.34, 0.62, 0.88), near);
	water = mix(water * 1.12, water, smoothstep(0.55, 0.95, wv));   // flach am Rand heller
	float rip = vnoise(p / 26.0 + vec2(TIME * 0.35, TIME * 0.22)) * vnoise(p / 11.0 - vec2(TIME * 0.25, -TIME * 0.3));
	water += smoothstep(0.35, 0.6, rip) * 0.14 * (0.35 + 0.65 * near);
	col = mix(col, shore, bank * (1.0 - we) * (1.0 - pe));   // kein Uferstreifen auf dem Weg
	col = mix(col, water, we);
	col = mix(col, vec3(0.30, 0.36, 0.44), we * (1.0 - we) * 4.0 * 0.45);
	return col;
}

void fragment() {
	vec2 p = local_pos;
	float m = texture(mask, p / map_size).r;
	vec2 tr = texture(terrain_tex, p / map_size).rg;
	float near = 0.0;
	if (tr.x > 0.02 || tr.y > 0.02) {
		near = green_near(p);
	}
	float big = vnoise(p / 46.0);
	float small = vnoise(p / 9.0);
	float v = m + (big * 0.6 + small * 0.4 - 0.5) * 0.55;
	float g = smoothstep(0.44, 0.56, v);
	vec3 col;
	vec3 dry = mix(vec3(0.66, 0.64, 0.60), vec3(0.77, 0.75, 0.70), big) + (small - 0.5) * 0.07;
	vec3 lush = mix(vec3(0.40, 0.72, 0.30), vec3(0.56, 0.84, 0.36), big) + (small - 0.5) * 0.09;
	if (g < 0.999) {
		// Trocken: helles, warmes Grau mit Rissen, Steinchen und Halmen – trist, aber nie dunkel
		dry = mix(dry, dry * 0.72, crack(p) * 0.8);
		vec4 s = stalk(p);
		dry = mix(dry, s.rgb, s.a);
		vec4 pb = pebble(p);
		dry = mix(dry, pb.rgb, pb.a);
	}
	if (g > 0.001) {
		// Grün in mehreren Tönen: große Flecken dunkler, andere gelblicher
		float t1 = vnoise(p / 230.0 + 17.0);
		float t2 = vnoise(p / 120.0 + 53.0);
		lush = mix(lush, vec3(0.30, 0.60, 0.26), smoothstep(0.5, 0.85, t1) * 0.7);
		lush = mix(lush, vec3(0.64, 0.84, 0.34), smoothstep(0.55, 0.9, t2) * 0.6);
		vec4 t = tuft(p);
		lush = mix(lush, t.rgb, t.a);
		vec4 f = flower(p);
		lush = mix(lush, f.rgb, f.a);
	}
	col = mix(dry, lush, g);
	// Heller gelbgrüner Saum an der Wachstumsgrenze
	float rim = smoothstep(0.30, 0.50, v) - smoothstep(0.50, 0.72, v);
	col = mix(col, vec3(0.82, 0.92, 0.48), rim * 0.55);
	if (tr.x > 0.02 || tr.y > 0.02) {
		col = paths_and_water(p, col, tr, near, big, small);
	}
	COLOR = vec4(col, 1.0);
}
