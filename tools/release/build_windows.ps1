# Builds the Windows downloads: exports Pocket Reef.exe with Godot, then makes
#   build/PocketReef-<version>-windows-portable.exe   (single file, runs from anywhere)
#   build/PocketReef-<version>-windows-setup.exe      (per-user installer with an uninstaller)
#
#   powershell -ExecutionPolicy Bypass -File tools/release/build_windows.ps1
#
# Needs the Godot 4.7.2 Windows export templates, Inno Setup 6 (for ISCC.exe) and uv (to make
# the installer's .ico with Pillow). Override the tools with $env:GODOT and $env:ISCC.
# The .exe files are unsigned, so SmartScreen warns until they are code-signed.
$ErrorActionPreference = "Stop"

$Root = (Resolve-Path "$PSScriptRoot\..\..").Path
$Name = "Pocket Reef"
$Version = (Select-String -Path "$Root\project.godot" -Pattern '^config/version="(.*)"').Matches[0].Groups[1].Value
$Out = Join-Path $Root "build"
$Stage = Join-Path $Out "windows"
$Exe = Join-Path $Stage "$Name.exe"
$Portable = Join-Path $Out "PocketReef-$Version-windows-portable.exe"
$SetupBase = "PocketReef-$Version-windows-setup"

function Find-Tool([string]$Override, [string]$Command, [string[]]$Candidates) {
	if ($Override) { return $Override }
	$found = Get-Command $Command -ErrorAction SilentlyContinue
	if ($found) { return $found.Source }
	foreach ($c in $Candidates) { if (Test-Path $c) { return $c } }
	throw "Can't find $Command. Install it or set the environment variable."
}

$Godot = Find-Tool $env:GODOT "godot" @("$env:LOCALAPPDATA\Programs\Godot\4.7.2\godot.exe")
$Iscc = Find-Tool $env:ISCC "ISCC" @("$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
	"${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe", "$env:ProgramFiles\Inno Setup 6\ISCC.exe")

Write-Host "==> Exporting $Name $Version"
if (Test-Path $Stage) { Remove-Item -Recurse -Force $Stage }
New-Item -ItemType Directory -Force $Stage | Out-Null
# The editor logs errors about the macOS-only plugin while exporting; the preset leaves it out.
# godot.exe is a GUI program, so PowerShell only waits for it when its output is piped.
& $Godot --headless --path $Root --export-release "Windows" $Exe | Out-Host
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $Exe)) { throw "Godot export failed" }

Write-Host "==> Portable build"
Copy-Item -Force $Exe $Portable

Write-Host "==> Installer"
$Icon = Join-Path $Stage "app_icon.ico"
& uv run --with pillow python -c "import sys; from PIL import Image; Image.open(sys.argv[1]).save(sys.argv[2], sizes=[(16,16),(24,24),(32,32),(48,48),(64,64),(128,128),(256,256)])" "$Root\art\icons\app_icon.png" $Icon
if ($LASTEXITCODE -ne 0) { throw "Couldn't make the installer icon" }
& $Iscc /Q "/DAppVersion=$Version" "/DSourceExe=$Exe" "/DSetupIcon=$Icon" "/DOutputDir=$Out" "/DOutputBase=$SetupBase" "$PSScriptRoot\windows_installer.iss"
if ($LASTEXITCODE -ne 0) { throw "Inno Setup failed" }

Write-Host "==> Done"
foreach ($f in @($Portable, (Join-Path $Out "$SetupBase.exe"))) {
	$hash = (Get-FileHash -Algorithm SHA256 $f).Hash.ToLower()
	"{0}  {1:N1} MB  SHA-256 {2}" -f (Split-Path -Leaf $f), ((Get-Item $f).Length / 1MB), $hash
}
