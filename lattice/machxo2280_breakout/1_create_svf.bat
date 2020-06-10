REM @ECHO OFF

SETLOCAL

SET PRJDIR=%CD%\prj_switch
SET XPRJDIR=%PRJDIR:\=/%

IF EXIST ..\diamond_env.bat CALL ..\diamond_env.bat
ddtcmd -oft -svfsingle -if %XPRJDIR%/impl/jswitch_Implementation0.bit -dev LCMXO2280C -op "FLASH Erase,Program,Verify" -of ./jswitch_machxo2280.svf

ENDLOCAL
