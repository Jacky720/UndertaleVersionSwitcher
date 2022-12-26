@if (@X)==(@Y) @end /* Harmless hybrid line that begins a JScript comment
@goto :Batch

::::
::::HASHSUM.BAT history
::::
::::  v1.6 2019-02-26 - Modify /F and /FR to support non-ASCII characters
::::  v1.5 2018-02-18 - Added /H, /F, /FR and /NH options.
::::  v1.4 2016-12-26 - Convert /A value to upper case because some Windows
::::                    versions are case sensitive. Also improve JScript file
::::                    read performance by reading 1000000 bytes instead of 1.
::::  v1.3 2016-12-17 - Bug fixes: Eliminate unwanted \r\n from temp file by
::::                    reading stdin with JScript instead of FINDSTR.
::::                    Fix help to ignore history.
::::  v1.2 2016-12-07 - Bug fixes: Exclude FORFILES directories and
::::                    correct setlocal/endlocal management in :getOptions
::::  v1.1 2016-12-06 - New /V option, and minor bug fixes.
::::  v1.0 2016-12-05 - Original release
:::
:::HASHSUM  [/Option [Value]]... [File]...
:::
:::  Print or check file hashes using any of the following standard
:::  hash algorithms: MD5, SHA1, SHA256, SHA384, or SHA512.
:::
:::  HASHSUM always does a binary read - \r\n is never converted to \n.
:::
:::  In the absence of /C, HASHSUM computes the hash for each File, and writes
:::  a manifest of the results. Each line of output consists of the hash value,
:::  followed by a space and an asterisk, followed by the File name. The default
:::  hash alogrithm is sha256. File may include wildcards, but must not contain
:::  any path information.
:::
:::  If File is not given, then read from standard input and write the hash
:::  value only, without the trailing space, asterisk, or file name.
:::
:::  Options:
:::
:::    /? - Prints this help information to standard output.
:::
:::    /?? - Prints paged help using MORE.
:::
:::    /V - Prints the HASHSUM.BAT version.
:::
:::    /H - Prints the HASHSUM.BAT history.
:::
:::    /A Algorithm
:::
:::         Specifies one of the following hash algorithms:
:::         MD5, SHA1, SHA256, SHA384, SHA512
:::
:::    /P RootPath
:::
:::         Specifies the root path for operations.
:::         The default is the current directory.
:::
:::    /S - Recurse into all Subdirectories. The relative path from the root
:::         is included in the file name output.
:::         This option is ignored if used with /C.
:::
:::    /I - Include the RootPath in the file name output.
:::         This option is ignored if used with /C.
:::
:::    /T - Writes a space before each file name, rather than an
:::         asterisk. However, files are still read in binary mode.
:::         This option is ignored if used with /C.
:::
:::    /C - Read hash values and file names from File (the manifest), and verify
:::         that local files match. File may include path information with /C.
:::
:::         If File is not given, then read hash and file names from standard
:::         input. Each line of input must have a hash, followed by two spaces,
:::         or a space and an asterisk, followed by a file name.
:::
:::         If /A is not specified, then the algorithm is determined by the
:::         File extension. If the extension is not a valid algorithm, then
:::         the algorithm is derived based on the length of the first hash
:::         within File.
:::
:::         Returns ERRORLEVEL 1 if any manifest File is not found or is invalid,
:::         or if any local file is missing or does not match the hash value in
:::         the manifest. If all files are found and match, then returns 0.
:::
:::    /F FileName
:::
:::         When using /C, only check lines within the manifest that contain the
:::         string FileName. The search ignores case.
:::
:::    /FR FileRegEx
:::
:::         When using /C, only check lines within the manifest that match the
:::         FINDSTR regular expression FileRegEx. The search ignores case.
:::
:::    /NH - (No Headers)  Suppresses listing of manifest name(s) when using /C.
:::
:::    /NE - (No Errors) Suppresses error messages when using /C.
:::
:::    /NM - (No Matches) Suppresses listing of matching files when using /C.
:::
:::    /NS - (No Summary) Suppresses summary information when using /C.
:::
:::    /Q  - (Quiet) Suppresses all output when using /C.
:::
:::HASHSUM.BAT version 1.6 was written by Dave Benham
:::maintained at http://www.dostips.com/forum/viewtopic.php?f=3&t=7592

============= :Batch portion ===========
@echo off
setlocal disableDelayedExpansion

:: Define options
set "options= /A:"" /C: /I: /P:"" /S: /T: /?: /??: /NH: /NE: /NM: /NS: /Q: /V: /H: /F:"" /FR:"" "

:: Set default option values
for %%O in (%options%) do for /f "tokens=1,* delims=:" %%A in ("%%O") do set "%%A=%%~B"
set "/?="
set "/??="

:getOptions
if not "%~1"=="" (
  set "test=%~1"
  setlocal enableDelayedExpansion
  if "!test:~0,1!" neq "/" endlocal & goto :endOptions
  set "test=!options:*%~1:=! "
  if "!test!"=="!options! " (
      endlocal
      >&2 echo Invalid option %~1
      exit /b 1
  ) else if "!test:~0,1!"==" " (
      endlocal
      set "%~1=1"
  ) else (
      endlocal
      set "%~1=%~2"
      shift /1
  )
  shift /1
  goto :getOptions
)
:endOptions

:: Display paged help
if defined /?? (
  (for /f "delims=: tokens=*" %%A in ('findstr "^:::[^:] ^:::$" "%~f0"') do @echo(%%A)|more /e
  exit /b 0
) 2>nul

:: Display help
if defined /? (
  for /f "delims=: tokens=*" %%A in ('findstr "^:::[^:] ^:::$" "%~f0"') do echo(%%A
  exit /b 0
)

:: Display version
if defined /V (
  for /f "delims=: tokens=*" %%A in ('findstr /ric:"^:::%~nx0 version" "%~f0"') do echo(%%A
  exit /b 0
)

:: Display history
if defined /H (
  for /f "delims=: tokens=*" %%A in ('findstr "^::::" "%~f0"') do echo(%%A
  exit /b 0
)

:: If no file specified, then read stdin and write to a temp file
set "tempFile="
if "%~1" equ "" set "tempFile=%~nx0.%time::=_%.%random%.tmp"
if defined tempFile cscript //nologo //E:JScript "%~f0" "%temp%\%tempFile%"

if defined /P cd /d "%/P%" || exit /b 1
if defined /C goto :check

:generate
if defined tempFile cd /d "%temp%"
if not defined /A set "/A=sha256"
if defined /S set "/S=/s"
if defined /T (set "/T= ") else set "/T=*"
call :defineEmpty
if not defined /P goto :generateLoop
if not defined /I goto :generateLoop
if "%/P:~-1%" equ "\" (set "/I=%/P:\=/%") else set "/I=%/P:\=/%/"
set "rtn=0"

:generateLoop
(
  for /f "delims=" %%F in (
    'forfiles %/s% /m "%tempFile%%~1" /c "cmd /c if @isdir==FALSE echo @relpath" 2^>nul'
  ) do for /f "delims=" %%A in (
    'certutil.exe -hashfile %%F %/A% ^| find /v ":" ^|^| if %%~zF gtr 0 (echo X^) else echo %empty%'
  ) do (
    set "file=%%~F"
    set "hash=%%A"
    setlocal enableDelayedExpansion
    set "file=!file:~2!"
    if defined tempFile (
      if !hash! equ X (
        set "rtn=1"
        echo ERROR
      ) else echo !hash: =!
    ) else (
      if !hash! equ X (
        set "rtn=1"
        echo ERROR: !/I!!file!
      ) else echo !hash: =! !/T!!/I!!file:\=/!
    )
    endlocal
  )
) || (
  set "rtn=1"
  echo MISSING: %/T%%1
)
shift /1
if "%~1" neq "" goto :generateLoop
if defined tempFile del "%tempFile%"
exit /b %rtn%

:check
if defined /Q for %%V in (/NE /NM /NS /NH) do set "%%V=1"
if defined /F if defined /FR (
  >&2 echo ERROR: /F and /FR cannot be combined
  exit /b 1
)
set "searchTemp="
if defined /F (
  set "searchTemp=%temp%\%~nx0.%time::=_%.%random%.search.tmp"
  setlocal enableDelayedExpansion
  (echo(!/F!) > "!%searchTemp!"
  endlocal
  set "file="    & set "freg=rem" & set "norm=rem"
) else if defined /FR (
  set "searchTemp=%temp%\%~nx0.%time::=_%.%random%.search.tmp"
  setlocal enableDelayedExpansion
  (echo(!/FR!) > "!%searchTemp!"
  endlocal
  set "file=rem" & set "freg="    & set "norm=rem"
) else (
  set "file=rem" & set "freg=rem" & set "norm="
)
set /a manifestCnt=missingManifestCnt=invalidCnt=missingCnt=failCnt=okCnt=0

:checkLoop
set "alogorithm=%/A%"
if defined tempFile set "tempFile=%temp%\%tempFile%"
for %%F in ("%tempFile%%~1") do call :checkFile "%%~F"
if defined tempFile del "%tempFile%"
shift /1
if "%~1" neq "" goto :checkLoop

if defined searchTemp del "%searchTemp%"

if not defined /NS (
  echo ==========  SUMMARY  ==========
  echo Total manifests   = %manifestCnt%
  echo Matched files     = %okCnt%
  echo(
  if %missingManifestCnt% gtr 0 echo Missing manifests = %missingManifestCnt%
  if %invalidCnt% gtr 0         echo Invalid manifests = %invalidCnt%
  if %missingCnt% gtr 0         echo Missing files     = %missingCnt%
  if %failCnt% gtr 0            echo Failed files      = %failCnt%
)
set /a "1/(missingManifestCnt+invalidCnt+missingCnt+failCnt)" 2>nul && (
  echo(
  exit /b 1
)
exit /b 0

:checkFile
set /a manifestCnt+=1
if not defined /NH if defined tempfile (echo ----------  ^<stdin^>  ----------) else echo ----------  %1  ----------
if not defined algorithm set "/A="
if not defined /A echo *.md5*.sha1*.sha256*.sha384*.sha512*|find /i "*%~x1*" >nul && for /f "delims=." %%A in ("%~x1") do set "/A=%%A"
findstr /virc:"^[0123456789abcdef][0123456789abcdef]* [ *][^ *?|<>]" %1 >nul 2>nul && (
  if not defined /NE if defined tempFile (echo *INVALID: ^<stdin^>) else echo *INVALID: %1
  set /a invalidCnt+=1
  exit /b
)
(
  %norm% for /f "usebackq tokens=1* delims=* " %%A in (%1) do (
  %file% for /f "tokens=1* delims=* " %%A in ('type %1 ^| findstr /ilg:"%searchTemp%"') do (
  %freg% for /f "tokens=1* delims=* " %%A in ('type %1 ^| findstr /irg:"%searchTemp%"') do (
    set "hash0=%%A"
    set "fileName=%%B"
    if defined /A (call :defineEmpty) else call :determineFormat
    setlocal enableDelayedExpansion
    set "fileName=!fileName:/=\!"
    for /f "tokens=1* delims=" %%C in (
      'certutil.exe -hashfile "!fileName!" !/A! ^| find /v ":" ^|^| if exist "!fileName!" (echo !empty!^) else echo X'
    ) do set "hash=%%C"
    if /i "!hash0!" equ "!hash: =!" (
      if not defined /NM echo OK: !fileName!
      endlocal
      set /a okCnt+=1
    ) else if !hash! equ X (
      if not defined /NE echo *MISSING: !fileName!
      endlocal
      set /a missingCnt+=1
    ) else (
      if not defined /NE echo *FAILED: !fileName!
      endlocal
      set /a failCnt+=1
    )
  )
) 2>nul || if not defined /F if not defined /FR (
  if not defined /NE echo *MISSING: %1
  set /a missingManifestCnt+=1
)
exit /b

:determineFormat
if "%hash0:~127%" neq "" (
  set "/A=SHA512"
) else if "%hash0:~95%" neq "" (
  set "/A=SHA384"
) else if "%hash0:~63%" neq "" (
  set "/A=SHA256"
) else if "%hash0:~39%" neq "" (
  set "/A=SHA1"
) else set "/A=MD5"

:defineEmpty
if /i "%/A%"=="md5" (
  set "empty=d41d8cd98f00b204e9800998ecf8427e"
  set "/A=MD5"
) else if /i "%/A%"=="sha1" (
  set "empty=da39a3ee5e6b4b0d3255bfef95601890afd80709"
  set "/A=SHA1"
) else if /i "%/A%"=="sha256" (
  set "empty=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  set "/A=SHA256"
) else if /i "%/A%"=="sha384" (
  set "empty=38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b"
  set "/A=SHA384"
) else if /i "%/A%"=="sha512" (
  set "empty=cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e"
  set "/A=SHA512"
) else (
  echo ERROR: Invalid /A algorithm>&2
  (goto) 2>nul&exit /b 1
)
exit /b


************* JScript portion **********/
var fso = new ActiveXObject("Scripting.FileSystemObject");
var out = fso.OpenTextFile(WScript.Arguments(0),2,true);
var chr;
while( !WScript.StdIn.AtEndOfStream ) {
  chr=WScript.StdIn.Read(1000000);
  out.Write(chr);
}
