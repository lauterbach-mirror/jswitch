@REM To run this:
@REM   1. Start DOS Command shell
@REM   2. CD to directory where this "0_create_prj.bat" is in.
@REM   3. Execute    .\0_create_prj.bat

@ECHO OFF

SETLOCAL

SET PRJDIR=%CD%\prj_switch
SET XPRJDIR=%PRJDIR:\=/%

RMDIR /S /Q "%PRJDIR%"
MKDIR "%PRJDIR%"
CD "%PRJDIR%"

COPY ..\jtagswitcher_sbt.project .
COPY ..\jtagswitcher_syn.prj .
COPY ..\jtagswitcher_ice40hx8k-evb.pcf .
COPY ..\jtagswitcher_syn.sdc .
COPY ..\jswitch_config_pkg.vhd .
COPY ..\toplevel.vhd .

ENDLOCAL
