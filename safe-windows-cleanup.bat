@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

title Windows Cleanup Utility (v2.0)
color 0A

net session >nul 2>&1

if errorlevel 1 (
    echo.
    echo ============================================================
    echo RENDSZERGAZDAI JOGOSULTSAG SZUKSEGES A FUTTATASHOZ
    echo ============================================================
    echo.

    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Start-Process -FilePath '%~f0' -Verb RunAs"

    if errorlevel 1 (
        echo [HIBA] Az emeles megtagadva.
        echo A szkriptet adminisztratori jogokkal kell inditani.
        pause
    )

    exit /b
)

set "LOGFILE=%~dp0cleanup.log"

set /a TOTAL=0
set /a SUCCESS=0
set /a FAILED=0

(
echo ===============================================
echo [%DATE% %TIME%] Cleanup indult
echo ===============================================
)>>"%LOGFILE%"

:: ==================================================
:: FEJLEC
:: ==================================================

cls

echo.
echo =================================================
echo             WINDOWS CLEANUP UTILITY v2.2
echo =================================================
echo.
echo [ADMIN] Jogosultsag rendben
echo.

:: ==================================================
:: USER TEMP
:: ===================================================

echo ===============================================
echo [1/3] USER TEMP
echo ===============================================
call :CLEANFOLDER "%TEMP%"

:: =================================================
:: WINDOWS TEMP
:: ================================================

echo.
echo ==============================================
echo [2/3] WINDOWS TEMP
echo =============================================
call :CLEANFOLDER "C:\Windows\Temp"

:: ===============================================
:: PREFETCH
:: =============================================
echo.
echo ==========================================
echo [3/3] PREFETCH
echo =============================================
echo [INFO] Megjegyzes: a Prefetch torlese utan a kovetkezo
echo        programinditasok lasabbak lehetnek, amig a
echo        Windows ujraepiti a gyorsitotarat.
echo.

choice /C YN /M "Prefetch tisztitas induljon"

if errorlevel 2 goto SKIP_PREFETCH

call :CLEANFOLDER "C:\Windows\Prefetch"

:SKIP_PREFETCH

echo.
echo ==============================================
echo OSSZEGZES:
echo ===============================================
echo.
echo Osszes vizsgalt fajl : %TOTAL%
echo Sikeresen torolve    : %SUCCESS%
echo Sikertelen torlesek    : %FAILED%
echo.
echo Naplofajl:
echo %LOGFILE%
echo.

(
echo ============================================================
echo [%DATE% %TIME%] Cleanup vege - OK:%SUCCESS% FAIL:%FAILED% OSSZ:%TOTAL%
echo ============================================================
echo.
)>>"%LOGFILE%"

pause
exit /b

:: ============================================================
:: CLEANFOLDER:
:: ============================================================

:CLEANFOLDER

set "TARGET=%~1"

echo.
echo Mappa:
echo %TARGET%
echo.

:: ===============================================
:: LETEZIK-E:
:: ===============================================

if not exist "%TARGET%" (
    echo [INFO] A mappa nem letezik!
    exit /b
)

:: ===============================================
:: KRITIKUS MAPPA ELLENI VEDELEM:
:: ===============================================

if /I "%TARGET%"=="C:\" (
    echo [VEDELEM] C:\ torlese nem engedelyezett.
    exit /b
)

if /I "%TARGET%"=="C:\Windows" (
    echo [VEDELEM] Windows mappa vedett.
    exit /b
)

if /I "%TARGET%"=="C:\Users" (
    echo [VEDELEM] Users mappa vedett.
    exit /b
)

if /I "%TARGET%"=="C:\Program Files" (
    echo [VEDELEM] Program Files vedett.
    exit /b
)

if /I "%TARGET%"=="C:\Program Files (x86)" (
    echo [VEDELEM] Program Files x86 vedett.
    exit /b
)

:: ==============================================
:: REPARSE POINT VIZSGALAT:
:: ==============================================

fsutil reparsepoint query "%TARGET%" >nul 2>&1

if not errorlevel 1 (
    echo [VEDELEM] Reparse Point vagy Junction detektalva.
    echo [SKIP] Mappa kihagyva.
    exit /b
)


setlocal DisableDelayedExpansion

:: ===============================================
:: FAJLOK TORLESE:
:: ===============================================

for /f "usebackq delims=" %%F in (`dir /a-d-l /b /s "%TARGET%" 2^>nul`) do (

    set /a TOTAL+=1

    attrib -r -h -s "%%F" >nul 2>&1

    del /f /q "%%F" >nul 2>&1

    if exist "%%F" (

        set /a FAILED+=1

        echo [HIBA] %%F
        >>"%LOGFILE%" echo [FAILED] %%F

    ) else (

        set /a SUCCESS+=1

        echo [OK] %%F
        >>"%LOGFILE%" echo [DELETED] %%F
    )
)

:: ================================================
:: URES MAPPAK TORLESE
:: ================================================

for /f "usebackq delims=" %%D in (`dir /ad /b /s "%TARGET%" 2^>nul ^| sort /R`) do (
    rd "%%D" >nul 2>&1
)

for /f "tokens=1-3" %%A in ("%TOTAL% %SUCCESS% %FAILED%") do (
    endlocal
    set /a TOTAL+=%%A
    set /a SUCCESS+=%%B
    set /a FAILED+=%%C
)

exit /b
