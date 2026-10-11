[Setup]
; LangFix Inno Setup installer
AppName=LangFix
AppVersion=1.0
DefaultDirName={pf}\LangFix
DefaultGroupName=LangFix
OutputBaseFilename=LangFix-Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern

; Show License/Readme pages
LicenseFile=EULA.txt

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "hebrew"; MessagesFile: "compiler:Languages\Hebrew.isl"

; SignTool can be added here if you have a code signing certificate
; SignTool=...

[Files]
; Source: path relative to this .iss file; the release process should copy LangFix.exe next to the .iss or update this path
Source: "..\..\LangFix.exe"; DestDir: "{app}"; Flags: ignoreversion
; Custom Windows icon used by the tray app and shortcuts.
Source: "..\langfix.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\LangFix"; Filename: "{app}\LangFix.exe"; WorkingDir: "{app}"; IconFilename: "{app}\langfix.ico"; Tasks: desktopicon
Name: "{userdesktop}\LangFix"; Filename: "{app}\LangFix.exe"; IconFilename: "{app}\langfix.ico"; Tasks: desktopicon

[Tasks]
Name: desktopicon; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"; Flags: unchecked
Name: autostart; Description: "Start LangFix when I log on"; Flags: unchecked

[Run]
; Run at end of installation if user wants
Filename: "{app}\LangFix.exe"; Description: "Launch LangFix"; Flags: nowait postinstall skipifsilent

[Registry]
; If user selected the autostart task, create Run key for current user
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "LangFix"; ValueData: "{app}\LangFix.exe"; Flags: uninsdeletevalue; Tasks: autostart

[UninstallDelete]
Type: files; Name: "{app}\langfix.ico"

[Code]
function Is64BitInstallMode(): Boolean;
begin
  Result := (IsWin64);
end;
