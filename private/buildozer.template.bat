@echo off
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION

set MF=%RUNFILES_MANIFEST_FILE:/=\\%
set PATH=%SYSTEMROOT%\system32

REM If not given a RUNFILES_MANIFEST_FILE env var, this should be the top level executable.
REM Try the MANIFEST in the current directory. When runfiles are disabled, the current directory
REM is set to the (mostly empty) runfiles directory.
if not exist %MF% (
    set MF=MANIFEST
)

REM If runfiles are enabled, the current directory will be set to the main repository under
REM the runfiles directory.
if not exist %MF% (
    set MF=..\MANIFEST
)

REM Only look up the binary in the runfiles manifest, since this batch file does not read
REM the repo mapping. Reading the repo mapping would be required in order to locate a runfile
REM in the runfiles directory by path alone.
if exist %MF% (
  REM Lookup the buildozer binary in the runfiles manifest.
  for /F "tokens=2* usebackq" %%i in (`findstr.exe /l /c:"%%BUILDOZER_RLOCATIONPATH%% " "%MF%"`) do (
    set BUILDOZER=%%i
    set BUILDOZER=!BUILDOZER:/=\!
  )
)

if "!BUILDOZER!" equ "" (
  echo>&2 ERROR: %%BUILDOZER_RLOCATIONPATH%% not found in runfiles.
  exit /b 1
)

REM Run the newly found full path to the executable within the build's workspace.
cd %BUILD_WORKSPACE_DIRECTORY%
!BUILDOZER! %*
if %ERRORLEVEL% neq 0 (
  exit /b %ERRORLEVEL%
)
