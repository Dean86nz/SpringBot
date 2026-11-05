// Übersichtskarte: die ganze Welt klein, aus denselben Masken wie der Boden (ground.gdshader).
// Grau = noch nicht begrünt (leicht schraffiert, damit Lücken auffallen), Grün in der Farbe des
// Gebiets, Wege braun, Wasser blau. UV 0..1 = ganze Karte.
shader_type canvas_item;

uniform sampler2D mask : filter_linear, repeat_disable;
uniform sampler2D terrain_tex : filter_linear, repeat_disable;
uniform sampler2D region_a : filter_linear, repeat_disable;
uniform bool use_regions = false;
uniform vec2 px_size = vec2(1120.0, 840.0);   // Größe der Karte auf dem Bildschirm

void fragment() {
	float m = smoothstep(0.42, 0.58, texture(mask, UV).r);
	vec2 tr = texture(terrain_tex, UV).rg;
	vec3 green = vec3(0.46, 0.76, 0.33);
	if (use_regions) {
		green *= texture(region_a, UV).rgb * 2.0;
	}
	vec2 p = UV * px_size;
	float hatch = step(0.5, fract((p.x + p.y) / 10.0));
	vec3 grey = mix(vec3(0.66, 0.64, 0.60), vec3(0.58, 0.56, 0.52), hatch * 0.6);
	vec3 col = mix(grey, green, m);
	col = mix(col, vec3(0.74, 0.60, 0.43), smoothstep(0.45, 0.55, tr.x));
	col = mix(col, vec3(0.36, 0.62, 0.88), smoothstep(0.45, 0.55, tr.y));
	COLOR = vec4(col, 1.0);
}
