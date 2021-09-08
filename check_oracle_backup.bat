:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: 25/07/2016
::
:: Check oracle backup script
::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

@echo off
SetLocal EnableDelayedExpansion
:: chcp 65001
:: chcp 1251


:: Check Directory

set dir=C:\oracle\

if exist %dir% (
 cd %dir% 
) else (
 echo CRITICAL - Directory doesn't exist.
 exit /b 2
)


:: Check Empty Directory

dir %dir% /a-d >nul 2>nul
if errorlevel 1 (
 echo CRITICAL - Directory is empty.
 exit /b 2
)


:: Keys

if /I "%1" == "" goto USAGE
if /I %1 == -f goto FULLNUM
if /I %1 == -i goto INCREMENTNUM
if /I %1 == -a goto ARCHLOGSNUM
if /I %1 == -fd goto FULL
if /I %1 == -id goto INCREMENT
if /I %1 == -ad goto ARCHLOGS
::if /I %1 == -l goto ALERT


:: Help

:USAGE
echo ============================================
echo Wrong argument.
echo check_oracle_backup.bat [ -f(d) ] [ -i(d) ] [ -a(d) ]
echo -f - full backup
echo -i - incremental backup
echo -a - backup archivelogs
echo  d - debug mode
echo Exit code:
echo 0 - backup complete
echo 1 - errors
echo 2 - backup is missing
echo 3 - backup log is empty
echo 4 - backup in progress
echo ============================================
exit /b 0


:: Check full backup

:FULLNUM
for /f "tokens=*" %%i in ('dir /b /o:d /a:-d %dir%*db_bkp_diff0*.*') do set log=%%i
if not defined log (
 echo 2
 exit /b 2
)

set output=0
for /f "usebackq" %%l in ("%dir%%log%") do set /A output+=1
if "!output!"=="0" (
 echo 3
 exit /b 2
)

for /f "delims=" %%d in ('"type %dir%%log% | findstr "Finished backup at""') do set progress=%%d
if "%progress%" == "" (
 for /f "delims=" %%e in ('"type %dir%%log% | findstr "ORA-00600 ORA-07445 ORA-01555 ORA-01578 ORA-04030 ORA-04031 ORA-00255""') do set ERRPROG=%%e
 if "%ERRPROG%" == "" (
  echo 4
  exit /b 0
 )
)

for /f %%a in ('"type %dir%%log% | findstr ERROR"') do set ORA=%%a
if  "%ORA%"=="ERROR" (
 echo 1
 exit /b 2
) else (
 echo 0
 exit /b 0
)


:FULL
::for /f "tokens=*" %%i in ('dir /b /o:d /a:-d %dir%*db_bkp_diff0*.*') do set log=%%i
::if not defined log (
:: echo CRITICAL - Backup is missing.
:: exit /b 2
::)

for /f "tokens=*" %%i in ('forfiles /d -7 /p %dir% /m *db_bkp_diff0*.*') do set log=%%i
if not defined log (
echo CRITICAL - Backup is missing.
exit /b 2
)

::forfiles - week

set output=0
for /f "usebackq" %%l in ("%dir%%log%") do set /A output+=1
if "!output!"=="0" (
 echo CRITICAL - Backup log is empty.
 exit /b 2
)

for /f "delims=" %%d in ('"type %dir%%log% | findstr "Finished backup at""') do set progress=%%d
if "%progress%" == "" (
 for /f "delims=" %%e in ('"type %dir%%log% | findstr "ORA-00600 ORA-07445 ORA-01555 ORA-01578 ORA-04030 ORA-04031 ORA-00255""') do set ERRPROG=%%e
 if "%ERRPROG%" == "" (
  echo Current backup in progress.
  exit /b 0
 )
)

for /f "delims=" %%c in ('"type %dir%%log% | findstr "ORA-00600 ORA-07445 ORA-01555 ORA-01578 ORA-04030 ORA-04031 ORA-00255""') do set ERR=%%c

for /f %%a in ('"type %dir%%log% | findstr ERROR"') do set ORA=%%a
if  "%ORA%"=="ERROR" (
 echo CRITICAL - Backup complete with errors: !ERR!.
 exit /b 2
) else (
 echo OK - backup complete.
 exit /b 0
)


:: Check incremental level 1 backup

:INCREMENTNUM
for /f "tokens=*" %%i in ('dir /b /o:d /a:-d %dir%*db_bkp_diff1*.*') do set log=%%i
if not defined log (
 echo 2
 exit /b 2
)

set output=0
for /f "usebackq" %%l in ("%dir%%log%") do set /A output+=1
if "!output!"=="0" (
 echo 3
 exit /b 2
)

for /f "delims=" %%d in ('"type %dir%%log% | findstr "Finished backup at""') do set progress=%%d
if "%progress%" == "" (
 for /f "delims=" %%e in ('"type %dir%%log% | findstr "ORA-00600 ORA-07445 ORA-01555 ORA-01578 ORA-04030 ORA-04031 ORA-00255""') do set ERRPROG=%%e
 if "%ERRPROG%" == "" (
  echo 4
  exit /b 0
 )
)

for /f %%a in ('"type %dir%%log% | findstr ERROR"') do set ORA=%%a
if  "%ORA%"=="ERROR" (
 echo 1
 exit /b 2
) else (
 echo 0
 exit /b 0
)

:INCREMENT
for /f "tokens=*" %%i in ('dir /b /o:d /a:-d %dir%*db_bkp_diff1*.*') do set log=%%i
if not defined log (
 echo CRITICAL - Backup is missing.
 exit /b 2
)

::forfiles - day

set output=0
for /f "usebackq" %%l in ("%dir%%log%") do set /A output+=1
if "!output!"=="0" (
 echo CRITICAL - Backup log is empty.
 exit /b 2
)

for /f "delims=" %%d in ('"type %dir%%log% | findstr "Finished backup at""') do set progress=%%d
if "%progress%" == "" (
 for /f "delims=" %%e in ('"type %dir%%log% | findstr "ORA-00600 ORA-07445 ORA-01555 ORA-01578 ORA-04030 ORA-04031 ORA-00255""') do set ERRPROG=%%e
 if "%ERRPROG%" == "" (
  echo Current backup in progress.
  exit /b 0
 )
)

for /f "delims=" %%c in ('"type %dir%%log% | findstr "ORA-00600 ORA-07445 ORA-01555 ORA-01578 ORA-04030 ORA-04031 ORA-00255""') do set ERR=%%c

for /f %%a in ('"type %dir%%log% | findstr ERROR"') do set ORA=%%a
if  "%ORA%"=="ERROR" (
 echo CRITICAL - Backup complete with errors: !ERR!.
 exit /b 2
) else (
 echo OK - backup complete.
 exit /b 0
)


:: Check backup archivelogs

:ARCHLOGSNUM
for /f "tokens=*" %%i in ('dir /b /o:d /a:-d %dir%*arc_bkp*.*') do set log=%%i
if not defined log (
 echo 2
 exit /b 2
)

set output=0
for /f "usebackq" %%l in ("%dir%%log%") do set /A output+=1
if "!output!"=="0" (
 echo 3
 exit /b 2
)

for /f "delims=" %%d in ('"type %dir%%log% | findstr "Finished backup at""') do set progress=%%d
if "%progress%" == "" (
 for /f "delims=" %%e in ('"type %dir%%log% | findstr "ORA-00600 ORA-07445 ORA-01555 ORA-01578 ORA-04030 ORA-04031 ORA-00255""') do set ERRPROG=%%e
 if "%ERRPROG%" == "" (
  echo 4
  exit /b 0
 )
)

for /f %%a in ('"type %dir%%log% | findstr ERROR"') do set ORA=%%a
if  "%ORA%"=="ERROR" (
 echo 1
 exit /b 2
) else (
 echo 0
 exit /b 0
)

:ARCHLOGS
for /f "tokens=*" %%i in ('dir /b /o:d /a:-d %dir%*arc_bkp*.*') do set log=%%i
if not defined log (
 echo CRITICAL - Backup is missing.
 exit /b 2
)

set output=0
for /f "usebackq" %%l in ("%dir%%log%") do set /A output+=1
if "!output!"=="0" (
 echo CRITICAL - Backup log is empty.
 exit /b 2
)

for /f "delims=" %%d in ('"type %dir%%log% | findstr "Finished backup at""') do set progress=%%d
if "%progress%" == "" (
 for /f "delims=" %%e in ('"type %dir%%log% | findstr "ORA-00600 ORA-07445 ORA-01555 ORA-01578 ORA-04030 ORA-04031 ORA-00255""') do set ERRPROG=%%e
 if "%ERRPROG%" == "" (
  echo Current backup in progress.
  exit /b 0
 )
)

for /f "delims=" %%c in ('"type %dir%%log% | findstr "ORA-00600 ORA-07445 ORA-01555 ORA-01578 ORA-04030 ORA-04031 ORA-00255""') do set ERR=%%c

for /f %%a in ('"type %dir%%log% | findstr ERROR"') do set ORA=%%a
if  "%ORA%"=="ERROR" (
 echo CRITICAL - Backup complete with errors: !ERR!.
 exit /b 2
) else (
 echo OK - backup complete.
 exit /b 0
)


:: Check alert log
::set path=C:\app\ora17\diag\rdbms\tyva\tyva\trace
::cd %path%
::type alert_tyva.log | findstr (date?)
