@REM To run this:
@REM   1. Create ..\diamond_env.bat (see ..\diamond_env.bat.sample)
@REM   2. Start DOS Command shell
@REM   3. CD to directory where this "0_create_prj.bat" is in.
@REM   4. Execute    .\0_create_prj.bat

@ECHO OFF

SETLOCAL

SET PRJDIR=%CD%\prj_switch
SET XPRJDIR=%PRJDIR:\=/%

IF EXIST ..\diamond_env.bat CALL ..\diamond_env.bat

RMDIR /S /Q "%PRJDIR%"
MKDIR "%PRJDIR%"
CD "%PRJDIR%"

COPY ..\jswitch.lpf .
COPY ..\jswitch.ldc .

ECHO set myprjdir "%XPRJDIR%">start.tcl
ECHO source ../2_prj_setup.tcl>>start.tcl
ECHO source ../3_compile.tcl>>start.tcl

START pnmain.exe -t "%XPRJDIR%/start.tcl"

ENDLOCAL
