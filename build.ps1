# Baut Release- und Debug-EXE nach export/windows/ (PCK eingebettet).
# Die Version kommt aus project.godot (config/version). Nur die Debug-EXE enthält das Cheat-Menü.
# Engine: im Projektordner oder, falls dort nicht vorhanden, aus ..\ScrapEmpire.
# Voraussetzung: Export-Templates 4.7.2 unter %APPDATA%\Godot\export_templates\4.7.2.stable\
$ErrorActionPreference = "Stop"
$rel = "Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
$godot = Join-Path $PSScriptRoot $rel
if (-not (Test-Path $godot)) { $godot = Join-Path $PSScriptRoot "..\ScrapEmpire\$rel" }
if (-not (Test-Path $godot)) { throw "Godot 4.7.2 nicht gefunden" }
$outDir = Join-Path $PSScriptRoot "export\windows"
New-Item -ItemType Directory -Force $outDir | Out-Null

$projectFile = Join-Path $PSScriptRoot "project.godot"
$versionLine = Get-Content $projectFile | Where-Object { $_ -match '^config/version="(.+)"$' } | Select-Object -First 1
$version = if ($versionLine -match '"(.+)"') { $Matches[1] } else { "dev" }
& $godot --headless --path $PSScriptRoot --import | Out-Null
foreach ($kind in @("release", "debug")) {
	$exeName = if ($kind -eq "release") { "SpringBot_v$version.exe" } else { "SpringBot_v${version}_DEBUG.exe" }
	& $godot --headless --path $PSScriptRoot "--export-$kind" "Windows Desktop" "export/windows/$exeName"
	if ($LASTEXITCODE -ne 0) { throw "Export ($kind) fehlgeschlagen (Exit $LASTEXITCODE)" }
	$exe = Join-Path $outDir $exeName
	if (-not (Test-Path $exe)) { throw "EXE wurde nicht erzeugt: $exe" }
	$size = [math]::Round((Get-Item $exe).Length / 1MB, 1)
	Write-Host "Build fertig ($kind): $exe ($size MB)"
}
