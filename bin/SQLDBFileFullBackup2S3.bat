::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Copyright(c) 2024 BeeX Inc. All rights reserved.
:: @auther:Naruhiro Ikeya
::
:: @name:SQLBackup2S3.bat
:: @summary:SQL Server Database Full Backup
::
:: @since:2024/08/22
:: @version:1.0
:: @see:SQLDBFullBackup2S3.ps1
::
:: @param:SQL Query File Name
:: @return:0:Success 9:Error
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@ECHO OFF

:::::::::::::::::::::::::::::::::::::
::       Environment Setting       ::
:::::::::::::::::::::::::::::::::::::
SET __DATABASENAME__="N'TestDB'"
SET __S3BUCKET__="N's3://beexsqlbackup.s3.ap-northeast-1.amazonaws.com/sqlbackup/'"
SET __STRIPING__=64
SET __LOG_CYCLE__=14
SET __LOG_PREFIX__=DBFullBackup

SET __SQLCMD__=C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE
:: Database Instance Host Name
SET __DBHOSTNAME__=%COMPUTERNAME%
SET __INSTANCENAME__=

SET __EXEC_SQL_FILE__=%1

::::::::::::::::::::::::::::::::::
::      Create Timestamp        ::
::::::::::::::::::::::::::::::::::
SET __TODAY__=%DATE:/=%
SET __TODAY__=%__TODAY__:~8%%__TODAY__:~4,4%
SET __TIME__=%TIME::=%
SET __TIME__=%__TIME__:.=%
SET __NOW__=%__TODAY__%%__TIME__: =0%

::::::::::::::::::::::::::::::::::::::::::::::
::   SQL Server Backup Script Log Setting   ::
::::::::::::::::::::::::::::::::::::::::::::::
:: Script Logfile Path
FOR /F "usebackq" %%l IN (`powershell -command "Split-Path %~dp0 -Parent | Join-Path -ChildPath log"`) DO @SET __LOGPATH__=%%l

IF NOT EXIST %__LOGPATH__% MKDIR %__LOGPATH__%

SET __LOGFILE__=%__LOGPATH__%\%__DBHOSTNAME__%_%__LOG_PREFIX__%_%__NOW__%.log
SET __EXEC_LOG_FILE__=%__LOGPATH__%\%__DBHOSTNAME__%_SQL_%__LOG_PREFIX__%_%__NOW__%.log

::::::::::::::::::::::::::::
::      log rotation      ::
::::::::::::::::::::::::::::
FORFILES /P %__LOGPATH__% /M *%__LOG_PREFIX__%*.log /D -%__LOG_CYCLE__% /C "CMD /C IF @isdir==FALSE DEL /Q @path" > NUL 2>&1

::::::::::::::::::::::::::::::::::::
::   Main Procedure               ::
::::::::::::::::::::::::::::::::::::

CALL :__ECHO__ ===== SQL Server Backup Database Start =====
ECHO. >> "%__LOGFILE__%"
CALL :__ECHO__ ================ Parameters =================
CALL :__ECHO__ Database Host Name       = %__DBHOSTNAME__%
CALL :__ECHO__ Execute SQL              = %__EXEC_SQL_FILE__%
CALL :__ECHO__ Log File                 = %__LOGFILE__%
CALL :__ECHO__ ==============================================
ECHO. >> "%__LOGFILE__%"

ECHO "%__SQLCMD__%" -E -S %__DBHOSTNAME__%\%__INSTANCENAME__% -i %__EXEC_SQL_FILE__% -o %__EXEC_LOG_FILE__% -v DatabaseName = %__DATABASENAME__% S3bucket = %__S3BUCKET__% Striping = %__STRIPING__% -b -r1 >> "%__LOGFILE__%"

"%__SQLCMD__%" -E -S %__DBHOSTNAME__%\%__INSTANCENAME__% -i %__EXEC_SQL_FILE__% -o %__EXEC_LOG_FILE__% -v DatabaseName = %__DATABASENAME__% S3bucket = %__S3BUCKET__% Striping = %__STRIPING__% -b -r1

IF ERRORLEVEL 1 (
  CALL :__ECHO__  Backup Database Execute Error
  ECHO Please check log file ^(%__EXEC_LOG_FILE__%^) >> "%__LOGFILE__%"
  EXIT /B 10
)

TYPE %__EXEC_LOG_FILE__% >> "%__LOGFILE__%"
FINDSTR /C:"return status = 1" %__EXEC_LOG_FILE__% 1>NUL 2>NUL
IF %ERRORLEVEL% EQU 0 (
  CALL :__ECHO__ Backup Database Execute Error
  DEL /Q %__EXEC_LOG_FILE__%
  EXIT /B 9
)
DEL /Q %__EXEC_LOG_FILE__%
ECHO. >> "%__LOGFILE__%"
CALL :__ECHO__ ===== SQL Server Backup Database Completed =====
ECHO. >> "%__LOGFILE__%"

:__QUIT__
EXIT /B 0

:__ECHO__
SET __TODAY__=%DATE%
SET __TODAY__=%__TODAY__:~10%/%__TODAY__:~4,5%
SET __TIME__=%TIME: =0%

ECHO [%__TODAY__% %__TIME__%] %*
ECHO [%__TODAY__% %__TIME__%] %* >>"%__LOGFILE__%"
EXIT /B 0
