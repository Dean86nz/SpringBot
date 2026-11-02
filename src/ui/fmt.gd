class_name Fmt
extends RefCounted
## Zahlen für die Anzeige, deutsch formatiert.


## 1234567 → "1.234.567"
static func int_str(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out


## 2.5 → "2,5"; ganze Zahlen ohne Nachkomma.
static func num(v: float) -> String:
	if is_equal_approx(v, roundf(v)):
		return int_str(roundi(v))
	return ("%.1f" % v).replace(".", ",")
