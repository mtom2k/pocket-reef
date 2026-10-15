; Inno Setup script for the Windows installer. Built by tools/release/build_windows.ps1, which
; passes the version and paths:
;
;   ISCC /DAppVersion=0.6.0 /DSourceExe=...\Pocket Reef.exe /DSetupIcon=...\app_icon.ico
;        /DOutputDir=...\build /DOutputBase=PocketReef-0.6.0-windows-setup windows_installer.iss
;
; Installs per user (no administrator prompt) into %LOCALAPPDATA%\Programs\Pocket Reef. The tank
; itself is saved in %APPDATA%\Pocket Reef and is kept on uninstall, like the macOS app.

#define AppName "Pocket Reef"
#define AppExe "Pocket Reef.exe"

[Setup]
; Never change AppId: Windows uses it to recognise upgrades and the uninstaller.
AppId={{6E0C2B4A-7F3D-4C1E-9B8A-2D5F4E3A1C70}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppName}
AppPublisherURL=https://github.com/mtom2k/pocket-reef
VersionInfoVersion={#AppVersion}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#OutputDir}
OutputBaseFilename={#OutputBase}
SetupIconFile={#SetupIcon}
UninstallDisplayIcon={app}\{#AppExe}
UninstallDisplayName={#AppName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
; A running tank is asked to quit first (see [Code]); this is the fallback for anything else.
CloseApplications=yes
RestartApplications=no

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#SourceExe}"; DestDir: "{app}"; DestName: "{#AppExe}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Registry]
; "Open at login" lives in the Run key (see scripts/login_item.gd). Remove it on uninstall so
; Windows doesn't try to start a deleted app; ValueType none means install never creates it.
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: none; ValueName: "{#AppName}"; Flags: uninsdeletevalue

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent

[Code]
// Asks a running tank to quit, which saves it, then makes sure it has gone so its exe can be
// replaced or removed. Setup's CloseApplications doesn't cover the uninstaller.
procedure CloseRunningTank();
var
  ResultCode: Integer;
begin
  Exec(ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'),
    '-NoProfile -ExecutionPolicy Bypass -Command "$p = Get-Process -Name ''Pocket Reef'' -ErrorAction SilentlyContinue; ' +
    '$null = $p.CloseMainWindow(); $p | Wait-Process -Timeout 5 -ErrorAction SilentlyContinue; ' +
    '$p | Stop-Process -Force -ErrorAction SilentlyContinue"',
    '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  CloseRunningTank();
  Result := '';
end;

function InitializeUninstall(): Boolean;
begin
  CloseRunningTank();
  Result := True;
end;
