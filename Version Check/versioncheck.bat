@echo off
setlocal
set BATPATH=%~dp0
set DATAPATH=%1
if not defined DATAPATH set DATAPATH="data.win"

for %%I in (%DATAPATH%) do (
  set DATANAME=%%~nxI 
  cd /d %%~dpI
)

for /f %%N in ('"%BATPATH%\hashsum" /a md5 %DATANAME%') do set "MD5=%%N"

find /I "%MD5%" "%BATPATH%\allundertaleversions.txt" || (
  echo %MD5% Not a recognized version of Undertale.
  echo Please ensure you are using the data.win, game.win, game.ios, or game.unx file.
  echo If the issue persists, contact Space Core#0352 on Discord.
)

pause
endlocal