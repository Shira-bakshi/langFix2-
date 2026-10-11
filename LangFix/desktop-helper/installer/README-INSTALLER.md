LangFix Installer (Inno Setup)
================================

This folder contains an Inno Setup script to build a Windows installer for LangFix.

Files:
- `LangFixInstaller.iss` — Inno Setup script. It expects `LangFix.exe` to be available next to the project root (two levels above this folder) or update the `Source:` path.

What the installer does:
- Installs `LangFix.exe` into `Program Files\LangFix` by default.
- Creates Start Menu entries and optional Desktop shortcut.
- Optional installer checkbox to add LangFix to Windows startup (current user Run registry key).
- Adds an uninstaller entry (Programs & Features) and removes the Run registry value on uninstall.

How to build the installer (developer machine):

1. Install Inno Setup: https://jrsoftware.org/isinfo.php
2. Place `LangFix.exe` in the project root (next to `langfix.ahk`) or adjust the `Source:` path in `LangFixInstaller.iss`.
 - Add your branded icon `langfix.ico` to the `icons` folder (`icons\langfix.ico`). The installer references this file to set shortcut icons and include the icon in the app folder. If it's missing the installer will still compile but shortcuts won't have the custom icon.
 - Edit `EULA.txt` in this folder to contain your real license text.
3. Open `LangFixInstaller.iss` in Inno Setup IDE and press Compile, or run from command line:

```bat
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" "LangFixInstaller.iss"
```

The compiler will produce a `LangFix-Setup.exe` in this folder.

Notes for release:
- Include `langfix.ico` in the source folder if you want a custom icon placed in the application folder and used for shortcuts.
- If you need to sign the installer, configure the `SignTool` directive in the `[Setup]` section.

Language selection and License page
----------------------------------
The included `LangFixInstaller.iss` adds a language selection page (English and Hebrew) and shows the EULA (License) page during installation. You can extend or replace these languages by adjusting the `[Languages]` and `LicenseFile` entries in the .iss file.
