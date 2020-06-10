@REM To run this:
@REM   1. Create ..\quartus_env.bat (see ..\quartus_env.bat.sample)
@REM   2. Start DOS Command shell
@REM   3. CD to directory where this "0_create_quratus2.bat" is in.
@REM   4. Execute    .\0_create_quratus2.bat
@REM   5. Open project in Quartus Software, Compile

@ECHO OFF

SETLOCAL

IF EXIST ..\quartus_env.bat CALL ..\quartus_env.bat

quartus_sh.exe -t ../2_create_quartus_project3.tcl maxten files.txt

ENDLOCAL
