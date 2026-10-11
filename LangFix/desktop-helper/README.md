# LangFix Desktop Helper

This helper lets you run the keyboard-fix logic from any application on Windows as a background tray app.

Files added/updated:
- `desktop-helper/langfix-cli.js` — (legacy) Node CLI included earlier. Not required by the new AHK tray app.
- `langfix.ahk` — AutoHotkey tray/background script (Alt+X) that copies the selection, fixes text in-place, and pastes it back.
- `desktop-helper/langfix.ico` — custom LangFix tray/application icon used by the AHK script and EXE build.

Quick steps:

1. Install AutoHotkey (v1.1+). Node.js is no longer required for the default flow.
2. Double-click `langfix.ahk` to run it; it appears in the system tray. The default hotkey is Alt+X.
3. Select text anywhere, press Alt+X — the selection will be replaced with the fixed text.

Tray menu options (right-click the LangFix tray icon):
- Toggle Hotkey — enable/disable the hotkey.
- Autostart On/Off — add/remove LangFix from Windows startup (uses current user Run registry key).
- About — brief info.
- Exit — stop the helper.

The script waits for Alt to be released before sending Ctrl+C, then verifies
that selected text was copied before converting or pasting. It restores the
original clipboard after the paste. To temporarily diagnose clipboard issues,
set `LangFixDebug := true` near the top of `langfix.ahk`; this writes the
copied text and conversion stages to `%TEMP%\LangFix-debug.log`. The log may
contain selected text, so disable debugging and remove the log after testing.

Settings GUI:
- Right-click the tray icon and choose `Settings`.
- Choose modifiers (Ctrl/Alt/Shift/Win) and type the main key (A-Z or F1..F12).
- Toggle `Hotkey Enabled` and press `Save` to persist the configuration to `langfix.ini`.
- The chosen hotkey is applied immediately and shown in the tray tooltip.

Optional:
- To produce a single executable for non-developers, compile `langfix.ahk` with the AutoHotkey compiler (`Ahk2Exe`). The compiled exe can be distributed and will run without requiring AutoHotkey installed on the target machine.

Notes:
- The script uses the registry Run key for autostart; you can also place a shortcut in your Startup folder if preferred.
- If you still want a Node-based approach, `desktop-helper/langfix-cli.js` remains available, but the AHK tray app does not require Node.

Compile to EXE (one-click for distribution)
-----------------------------------------

I included a helper script to automate compilation if you have AutoHotkey installed:

- Script: `desktop-helper/build-exe.bat` — runs Ahk2Exe to create `LangFix.exe` next to the AHK script.

Steps:

1. Install AutoHotkey (v1.1+). Ensure the compiler Ahk2Exe is available (usually installed with AutoHotkey in Program Files).
2. Open a Command Prompt and run the build script from the `desktop-helper` folder:

```bat
cd "desktop-helper"
build-exe.bat
```

3. On success you'll have `LangFix.exe` in the project root. You can rename or move it as needed.

Create a shortcut for Startup (optional)
--------------------------------------

To make the app start at login without using the registry GUI, create a shortcut in the user's Startup folder:

1. Press Win+R, paste `shell:startup` and press Enter. This opens the Startup folder.
2. Place a shortcut to `LangFix.exe` inside that folder.

Notes for distribution
----------------------
- If you want a single-file installer, tools such as Inno Setup can build an installer that places `LangFix.exe` in Program Files and creates shortcuts.
- The compiled exe will carry the behavior of the `langfix.ahk` script (tray icon, Settings GUI, autostart toggle).
