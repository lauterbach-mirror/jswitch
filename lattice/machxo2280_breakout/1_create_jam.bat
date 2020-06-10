REM @ECHO OFF

SETLOCAL

SET PRJDIR=%CD%\prj_switch
SET XPRJDIR=%PRJDIR:\=/%

IF EXIST ..\diamond_env.bat CALL ..\diamond_env.bat

ddtcmd -oft -stpsingle -if %XPRJDIR%/impl/jswitch_Implementation0.bit -dev LCMXO2280C -op "Multiple Operations File" -of %XPRJDIR%/jswitch_Implementation0.stp
COPY /Y %PRJDIR%\jswitch_Implementation0.stp .\jswitch_machxo2280.jam

ENDLOCAL
