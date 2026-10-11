; LangFix AutoHotkey v1.1 background helper (tray app)
; Hotkey: Alt+X - copies the selection, fixes it, and pastes it back.

#NoEnv
#SingleInstance Force
#UseHook
#MaxThreadsPerHotkey 1
#MaxThreadsBuffer Off
SendMode Input
SetWorkingDir %A_ScriptDir%

global LangFixBusy := false
global LangFixDebug := false
global LangFixDebugFile := A_Temp . "\LangFix-debug.log"

; Keep direction-specific maps: punctuation such as "/" and "." is ambiguous
; when both layouts share one map and would otherwise overwrite an entry.
EnglishToHebrew := {}
HebrewToEnglish := {}
EnglishToHebrew["a"] := "ש"
EnglishToHebrew["b"] := "נ"
EnglishToHebrew["c"] := "ב"
EnglishToHebrew["d"] := "ג"
EnglishToHebrew["e"] := "ק"
EnglishToHebrew["f"] := "כ"
EnglishToHebrew["g"] := "ע"
EnglishToHebrew["h"] := "י"
EnglishToHebrew["i"] := "ן"
EnglishToHebrew["j"] := "ח"
EnglishToHebrew["k"] := "ל"
EnglishToHebrew["l"] := "ך"
EnglishToHebrew["m"] := "צ"
EnglishToHebrew["n"] := "מ"
EnglishToHebrew["o"] := "ם"
EnglishToHebrew["p"] := "פ"
EnglishToHebrew["q"] := "/"
EnglishToHebrew["r"] := "ר"
EnglishToHebrew["s"] := "ד"
EnglishToHebrew["t"] := "א"
EnglishToHebrew["u"] := "ו"
EnglishToHebrew["v"] := "ה"
EnglishToHebrew["w"] := "'"
EnglishToHebrew["x"] := "ס"
EnglishToHebrew["y"] := "ט"
EnglishToHebrew["z"] := "ז"
EnglishToHebrew[" "] := " "
EnglishToHebrew[","] := "ת"
EnglishToHebrew["'"] := ","
EnglishToHebrew[";"] := "ף"
EnglishToHebrew[Chr(96)] := ";"
EnglishToHebrew["."] := "ץ"
EnglishToHebrew["<"] := ">"
EnglishToHebrew[">"] := "<"
EnglishToHebrew["/"] := "."
EnglishToHebrew["["] := "]"
EnglishToHebrew["]"] := "["
EnglishToHebrew["{"] := "}"
EnglishToHebrew["}"] := "{"

HebrewToEnglish["ש"] := "a"
HebrewToEnglish["נ"] := "b"
HebrewToEnglish["ב"] := "c"
HebrewToEnglish["ג"] := "d"
HebrewToEnglish["ק"] := "e"
HebrewToEnglish["כ"] := "f"
HebrewToEnglish["ע"] := "g"
HebrewToEnglish["י"] := "h"
HebrewToEnglish["ן"] := "i"
HebrewToEnglish["ח"] := "j"
HebrewToEnglish["ל"] := "k"
HebrewToEnglish["ך"] := "l"
HebrewToEnglish["צ"] := "m"
HebrewToEnglish["מ"] := "n"
HebrewToEnglish["ם"] := "o"
HebrewToEnglish["פ"] := "p"
HebrewToEnglish["/"] := "q"
HebrewToEnglish["ר"] := "r"
HebrewToEnglish["ד"] := "s"
HebrewToEnglish["א"] := "t"
HebrewToEnglish["ו"] := "u"
HebrewToEnglish["ה"] := "v"
HebrewToEnglish["'"] := "w"
HebrewToEnglish["ס"] := "x"
HebrewToEnglish["ט"] := "y"
HebrewToEnglish["ז"] := "z"
HebrewToEnglish[" "] := " "
HebrewToEnglish["ת"] := ","
HebrewToEnglish[","] := "'"
HebrewToEnglish["ף"] := ";"
HebrewToEnglish[";"] := Chr(96)
HebrewToEnglish["ץ"] := "."
HebrewToEnglish[">"] := "<"
HebrewToEnglish["<"] := ">"
HebrewToEnglish["."] := "/"
HebrewToEnglish["]"] := "["
HebrewToEnglish["["] := "]"
HebrewToEnglish["}"] := "{"
HebrewToEnglish["{"] := "}"

; Use the tray icon's context menu; do not intercept right-clicks in other apps.
Menu, Tray, NoStandard
Menu, Tray, Add, Toggle Hotkey, ToggleHotkey
Menu, Tray, Add, Autostart On/Off, ToggleAutostart
Menu, Tray, Add, Settings, OpenSettings
Menu, Tray, Add
Menu, Tray, Add, About, ShowAbout
Menu, Tray, Add, Exit, ExitLangFix
trayIconPath := A_ScriptDir . "\desktop-helper\langfix.ico"
if (!FileExist(trayIconPath))
    trayIconPath := A_ScriptDir . "\langfix.ico"
if (FileExist(trayIconPath))
    Menu, Tray, Icon, %trayIconPath%

iniFile := A_ScriptDir . "\langfix.ini"
IniRead, savedHotkey, %iniFile%, Settings, Hotkey, !x
StringLower, normalizedHotkey, savedHotkey
if (normalizedHotkey = "^!l") {
    savedHotkey := "!x"
}
IniRead, hotkeyEnabledVal, %iniFile%, Settings, HotkeyEnabled, 1
hotkeyEnabled := (hotkeyEnabledVal = "1")
defaultAutostart := RegReadAutostart() ? "1" : "0"
IniRead, autostartEnabledVal, %iniFile%, Settings, Autostart, %defaultAutostart%
autostartEnabled := (autostartEnabledVal = "1")

currentHotkey := savedHotkey
; Persist the default/migrated shortcut on first startup and every subsequent start.
IniWrite, %currentHotkey%, %iniFile%, Settings, Hotkey
if (hotkeyEnabled)
    Hotkey, %currentHotkey%, DoFix, On
else
    Hotkey, %currentHotkey%, DoFix, Off
RefreshTray()
Return

ToggleHotkey:
    hotkeyEnabled := !hotkeyEnabled
    if (hotkeyEnabled)
        Hotkey, %currentHotkey%, DoFix, On
    else
        Hotkey, %currentHotkey%, DoFix, Off
    IniWrite, % (hotkeyEnabled ? "1" : "0"), %iniFile%, Settings, HotkeyEnabled
    RefreshTray()
Return

ToggleAutostart:
    if (autostartEnabled) {
        RegDelete, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Run, LangFix
        if (ErrorLevel) {
            MsgBox, 16, LangFix, Could not remove LangFix from Windows startup.
            Return
        }
        autostartEnabled := false
    } else {
        RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Run, LangFix, "%A_ScriptFullPath%"
        if (ErrorLevel) {
            MsgBox, 16, LangFix, Could not add LangFix to Windows startup.
            Return
        }
        autostartEnabled := true
    }
    IniWrite, % (autostartEnabled ? "1" : "0"), %iniFile%, Settings, Autostart
    RefreshTray()
Return

ShowAbout:
    MsgBox, 64, LangFix, LangFix - Hebrew/English keyboard-layout correction`nHotkey: Alt+X
Return

RefreshTray() {
    global hotkeyEnabled, autostartEnabled, currentHotkey
    status := hotkeyEnabled ? "Hotkey: On" : "Hotkey: Off"
    aut := autostartEnabled ? "Autostart: On" : "Autostart: Off"
    Menu, Tray, Tip, % "LangFix - " . status . " | " . aut . " | Hotkey: " . currentHotkey
}

RegReadAutostart() {
    RegRead, val, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Run, LangFix
    return (ErrorLevel = 0 && val != "")
}

DoFix:
    if (LangFixBusy)
        Return
    LangFixBusy := true
    ; Alt+X fires while Alt is down. Wait for its key-up before sending Ctrl+C.
    KeyWait, Alt, T2
    if (ErrorLevel) {
        LangFixBusy := false
        MsgBox, 48, LangFix, Alt was not released; no copy or paste was sent.
        Return
    }
    try {
        FixSelection()
    } finally {
        LangFixBusy := false
    }
Return

FixSelection() {
    global LangFixDebug, LangFixDebugFile
    ClipSaved := ""
    clipboardCaptured := false
    errorMessage := ""
    restoreErrorMessage := ""
    try {
        ClipSaved := ClipboardAll
        clipboardCaptured := true
        Clipboard := ""
        Sleep, 30
        if (Clipboard != "")
            throw Exception("Could not clear the clipboard before copying. The selection was not changed.")

        SendInput, ^c
        ClipWait, 2
        if (ErrorLevel) {
            WriteDebug("copy-failed", "Clipboard remained empty after Ctrl+C.")
            throw Exception("Copy failed: no selected text arrived on the clipboard within 2 seconds. The selection was not changed.")
        }

        selectedText := Clipboard
        if (selectedText = "") {
            WriteDebug("copy-failed", "Ctrl+C returned empty text.")
            throw Exception("Copy failed: the copied selection was empty. The selection was not changed.")
        }
        WriteDebug("clipboard-input", selectedText)

        fixedText := FixText(selectedText)
        WriteDebug("converted-output", fixedText)
        if (fixedText = selectedText)
            throw Exception("Conversion produced no change; nothing was pasted.")

        Clipboard := ""
        Clipboard := fixedText
        ClipWait, 1
        if (ErrorLevel || Clipboard != fixedText) {
            WriteDebug("clipboard-output-failed", Clipboard)
            throw Exception("Could not set the converted text on the clipboard. The selection was not changed.")
        }

        SendInput, ^v
        WriteDebug("paste-sent", fixedText)
        ; Let the target application consume the paste before restoring ClipboardAll.
        Sleep, 750
    } catch e {
        errorMessage := e.Message
    } finally {
        try {
            if (clipboardCaptured)
                Clipboard := ClipSaved
        } catch e {
            restoreErrorMessage := "Could not restore the original clipboard: " . e.Message
        }
        VarSetCapacity(ClipSaved, 0)
    }

    if (restoreErrorMessage != "") {
        if (errorMessage != "")
            errorMessage .= "`n"
        errorMessage .= restoreErrorMessage
    }
    if (errorMessage != "")
        MsgBox, 16, LangFix Error, % errorMessage . "`n`nThe original clipboard was restored where possible."
}

WriteDebug(stage, value) {
    global LangFixDebug, LangFixDebugFile
    if (!LangFixDebug)
        return

    line := A_Now . " | " . stage . " | " . value . "`r`n"
    FileAppend, %line%, %LangFixDebugFile%, UTF-8
}

FixText(str) {
    global EnglishToHebrew, HebrewToEnglish
    englishCount := 0
    hebrewCount := 0
    out := ""
    len := StrLen(str)

    Loop, %len%
    {
        code := Asc(SubStr(str, A_Index, 1))
        if ((code >= 65 && code <= 90) || (code >= 97 && code <= 122))
            englishCount++
        else if (code >= 1488 && code <= 1514)
            hebrewCount++
    }

    map := (hebrewCount > englishCount) ? HebrewToEnglish : EnglishToHebrew
    Loop, %len%
    {
        ch := SubStr(str, A_Index, 1)
        lookup := ch
        code := Asc(ch)
        if (code >= 65 && code <= 90)
            StringLower, lookup, ch
        if (map.HasKey(lookup))
            out .= map[lookup]
        else
            out .= ch
    }
    return out
}

OpenSettings:
    hk := currentHotkey
    ctrl := InStr(hk, "^")
    alt := InStr(hk, "!")
    shift := InStr(hk, "+")
    win := InStr(hk, "#")
    key := hk
    StringReplace, key, key, ^, , All
    StringReplace, key, key, !, , All
    StringReplace, key, key, +, , All
    StringReplace, key, key, #, , All
    if (key = "")
        key := "L"

    Gui, Settings:New, +AlwaysOnTop +LabelSettingsGui
    Gui, Settings:Add, Text,, הגדר מקש חם
    Gui, Settings:Add, CheckBox, % "vHotCtrl " . (ctrl ? "Checked" : ""), Ctrl
    Gui, Settings:Add, CheckBox, % "vHotAlt " . (alt ? "Checked" : ""), Alt
    Gui, Settings:Add, CheckBox, % "vHotShift " . (shift ? "Checked" : ""), Shift
    Gui, Settings:Add, CheckBox, % "vHotWin " . (win ? "Checked" : ""), Win
    Gui, Settings:Add, Text,, מפתח (אות או F1-F12)
    Gui, Settings:Add, Edit, vHotKey w80, %key%
    Gui, Settings:Add, CheckBox, % "vHotEnabled " . (hotkeyEnabled ? "Checked" : ""), Hotkey Enabled
    Gui, Settings:Add, Button, gSaveSettings Default, Save
    Gui, Settings:Add, Button, gCloseSettings, Cancel
    Gui, Settings:Show,, LangFix Settings
Return

SettingsGuiClose:
CloseSettings:
    Gui, Settings:Destroy
Return

SaveSettings:
    Gui, Settings:Submit, NoHide
    StringUpper, k, HotKey
    if !RegExMatch(k, "^(?:[A-Z]|F(?:[1-9]|1[0-2]))$") {
        MsgBox, 48, LangFix, Enter one letter (A-Z) or a function key (F1-F12).
        Return
    }

    newHot := ""
    if (HotCtrl)
        newHot .= "^"
    if (HotAlt)
        newHot .= "!"
    if (HotShift)
        newHot .= "+"
    if (HotWin)
        newHot .= "#"
    newHot .= k

    ApplyHotkey(newHot, HotEnabled)
    IniWrite, %newHot%, %iniFile%, Settings, Hotkey
    IniWrite, % (HotEnabled ? "1" : "0"), %iniFile%, Settings, HotkeyEnabled
    IniWrite, % (autostartEnabled ? "1" : "0"), %iniFile%, Settings, Autostart
    Gui, Settings:Destroy
    MsgBox, 64, LangFix, Settings saved.
Return

ApplyHotkey(newHot, enabled) {
    global currentHotkey, hotkeyEnabled
    Hotkey, %currentHotkey%, DoFix, Off
    currentHotkey := newHot
    hotkeyEnabled := enabled ? true : false
    if (hotkeyEnabled)
        Hotkey, %currentHotkey%, DoFix, On
    else
        Hotkey, %currentHotkey%, DoFix, Off
    RefreshTray()
}

ExitLangFix:
    ExitApp
