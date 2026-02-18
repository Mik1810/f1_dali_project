@echo off
cls
title "F1 Race MAS - Ferrari vs McLaren"
echo ============================================
echo   DALI F1 Race Simulator - Windows
echo ============================================
echo.

REM ---- CONFIGURE THESE PATHS ----
REM Standard SICStus 4.6.0 Windows install path:
set sicstus_home=C:\Program Files (x86)\SICStus Prolog 4.6.0\bin
REM If you installed elsewhere, change the line above.
set dali_home=..\..\src
set prolog=%sicstus_home%\spwin.exe
set WAIT=ping -n 4 127.0.0.1

REM Clean previous run artifacts
del /q work\*.pl 2>nul
del /q work\*.ple 2>nul
del /q work\*.plv 2>nul
del /q work\*.plf 2>nul
copy /Y mas\*.txt work > nul

REM Convert backslashes for Prolog path strings
set daliH=%dali_home:\=/%

REM 1. Start LINDA server
echo [1/3] Starting LINDA blackboard server...
start "DALI LINDA Server" /B "" "%prolog%" --noinfo -l "%dali_home%\active_server_wi.pl" --goal "go(3010,'%daliH%/server.txt')."
echo Server started. Waiting...
%WAIT% >nul

REM 2. Start user agent (FIPA interface)
echo [2/3] Starting User FIPA agent...
start "DALI User Agent" /B "" "%prolog%" --noinfo -l "%dali_home%\active_user_wi.pl" --goal utente.
%WAIT% >nul

REM 3. Start F1 car agents
echo [3/3] Starting F1 car agents...
FOR /F "tokens=*" %%G IN ('dir /b mas\*.txt') DO (
    echo   Activating agent: %%~nG
    call conf\makeconf %%~nG %%G
    call conf\startagent %%G "%prolog%" "%dali_home%"
    %WAIT% >nul
)

echo.
echo ============================================
echo   F1 Race MAS is running!
echo ============================================
echo.
echo HOW TO START THE RACE:
echo   In the User Agent window, type:
echo     ferrari.
echo     user.
echo     send_message(start_race, user).
echo.
echo HOW TO SHUTDOWN:
echo   Close all SICStus windows or run:  taskkill /IM spwin.exe /F
echo ============================================
pause
