@echo off
REM Build script for LangFix AHK -> EXE using Ahk2Exe (part of AutoHotkey)
REM Place this file in the 'desktop-helper' folder and run it from there.

setlocal enabledelayedexpansion
echo Building LangFix EXE...

rem locate Ahk2Exe in common install locations
set AHK2EXE="%ProgramFiles%\AutoHotkey\Compiler\Ahk2Exe.exe"
if not exist %AHK2EXE% set AHK2EXE="%ProgramFiles(x86)%\AutoHotkey\Compiler\Ahk2Exe.exe"

rem fallback: check PATH
if not exist %AHK2EXE% (
  for %%I in (Ahk2Exe.exe) do set AHK2PATH=%%~$PATH:I
  if defined AHK2PATH set AHk2EXE="%AHK2PATH%"
)

if not exist %AHK2EXE% (
  echo Ahk2Exe compiler not found. Install AutoHotkey (which includes Ahk2Exe), or place Ahk2Exe.exe on PATH.
  pause
  exit /b 1
)

rem paths
set SRC=%~dp0..\langfix.ahk
set OUT=%~dp0..\LangFix.exe
set ICON=%~dp0\langfix.ico

echo Source: %SRC%
echo Output: %OUT%

if exist %ICON% (
  echo Using icon: %ICON%
  %AHK2EXE% /in "%SRC%" /out "%OUT%" /icon "%ICON%"
) else (
  %AHK2EXE% /in "%SRC%" /out "%OUT%"
)

if %ERRORLEVEL% EQU 0 (
  echo Build succeeded: %OUT%
  exit /b 0
) else (
  echo Build failed with error %ERRORLEVEL%
  pause
  exit /b %ERRORLEVEL%
)
