@echo off
setlocal ENABLEDELAYEDEXPANSION
chcp 65001 >nul

:: Enable ANSI escape codes
>nul 2>&1 reg query "HKCU\Console" /v VirtualTerminalLevel || (
    reg add "HKCU\Console" /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul
)

:: === Color Definitions ===
for /f %%A in ('echo prompt $E ^| cmd') do set "ESC=%%A"
set "RESET=%ESC%[0m"
set "RED=%ESC%[91m"
set "GRN=%ESC%[92m"
set "YEL=%ESC%[33m"
set "PRP=%ESC%[95m"

:: === CONFIGURATION ===
for %%i in ("%~dp0.") do set "BASE_PATH=%%~fi"
set "SCRIPT_PATH=%BASE_PATH%\export_to_fbx.py"
set "CONFIG_FILE=%BASE_PATH%\blender_config.txt"

:: === GET BLENDER PATH ===
if exist "%CONFIG_FILE%" (
    set /p "BLENDER_PATH="<"%CONFIG_FILE%"
    if not exist "!BLENDER_PATH!" (
        echo %RED%ERROR: Saved Blender path not found: !BLENDER_PATH!%RESET%
        del "%CONFIG_FILE%"
        goto AskBlenderPath
    )
) else (
    goto AskBlenderPath
)
goto ChooseFBXType

:AskBlenderPath
echo.
set /p "BLENDER_FOLDER=%PRP%Enter path to Blender directory (without blender.exe): %RESET%"
set "BLENDER_FOLDER=!BLENDER_FOLDER:"=!"
if "!BLENDER_FOLDER:~-1!"=="\" set "BLENDER_FOLDER=!BLENDER_FOLDER:~0,-1!"
set "BLENDER_PATH=!BLENDER_FOLDER!\blender.exe"
if not exist "!BLENDER_PATH!" (
    echo %RED%ERROR: blender.exe not found at "!BLENDER_PATH!"%RESET%
    pause
    exit /b
)
echo !BLENDER_PATH!>"%CONFIG_FILE%"

:ChooseFBXType
echo.
echo Select FBX export type:
echo   [1] Unity FBX
echo   [2] Standard FBX
set /p "FBX_TYPE=%PRP%Enter 1 or 2: %RESET%"

if "%FBX_TYPE%"=="1" (
    set "FBX_MODE=unity"
) else if "%FBX_TYPE%"=="2" (
    set "FBX_MODE=normal"
) else (
    echo %RED%Invalid export type selected.%RESET%
    pause
    exit /b
)

:: === LIST FOLDERS ===
set "index=0"
echo.
echo Available folders in: %BASE_PATH%

for /f "tokens=*" %%d in ('dir /b /ad "%BASE_PATH%"') do (
    set /a index+=1
    set "FOLDER_!index!=%%d"
    echo   [!index!] %%d
)

if %index%==0 (
    echo %YEL%WARNING: No folders found in base path.%RESET%
    pause
    exit /b
)

:: === ASK FOR FOLDER CHOICE ===
echo.
set /p "CHOICE=%PRP%Enter folder number to use: %RESET%"
call set "FOLDER_NAME=%%FOLDER_%CHOICE%%%"

if not defined FOLDER_NAME (
    echo %RED%ERROR: Invalid choice.%RESET%
    pause
    exit /b
)

set "BLEND_DIR=%BASE_PATH%\%FOLDER_NAME%"

if not exist "%BLEND_DIR%" (
    echo %RED%ERROR: Folder does not exist: %BLEND_DIR%%RESET%
    pause
    exit /b
)

:: === PROCESS .blend FILES ===
set /a count=0
for %%f in ("%BLEND_DIR%\*.blend") do (
    set /a count+=1
    call :Export "%%f" !count!
)

:: === SUMMARY ===
echo.
if "%count%"=="0" (
    echo %YEL%WARNING: No .blend files found in: "%BLEND_DIR%"%RESET%
) else (
    echo %GRN%SUCCESS: Exported %count% .blend file(s).%RESET%
)

echo.
<nul set /p=Press any key to exit the .blend to FBX Batch Converter...
pause >nul
exit /b

:Export
set "FILE=%~1"
set "NUM=%~2"
echo.
echo %PRP%Processing !NUM!: %~nx1%RESET%
"%BLENDER_PATH%" -b "%FILE%" --python "%SCRIPT_PATH%" -- "%FBX_MODE%"
if errorlevel 1 (
    echo %RED%ERROR exporting: %~nx1%RESET%
) else (
    echo %GRN%Export complete: %~nx1%RESET%
)
goto :eof
