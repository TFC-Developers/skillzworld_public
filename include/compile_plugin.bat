@echo off

:: ------------------------------------------------------------------------------------
:: INSTRUCTIONS TO COMPILE
:: * Place amxxpc.exe, amxxpc32.dll and compile.exe inside a directory named .\tools
:: * Place the contents of the amxmodx "includes" folder in .\includes
:: * Drag and drop a .sma over this script to compile. Output is in .\plugins
:: ------------------------------------------------------------------------------------

:: Makes current directory the working directory, saving the current one in memory
pushd "%~dp0"

::set output dir for .amxx file
set PLUGINS_DIR="F:\SteamLibrary\steamapps\common\Half-Life\tfc\addons\amxmodx\plugins"
if not exist %PLUGINS_DIR% mkdir %PLUGINS_DIR%

:: Echo the stuff we need for the plugins into .inc files
echo stock const _SCRIPT_DATE[] = "%DATE%" > include\script_version.inc
echo stock const _SCRIPT_NAME[] = "%~n1" > include\script_name.inc 

:: Compile the plugin
..\tools\amxxpc.exe %1 -o%PLUGINS_DIR%\%~n1.amxx 

:: Delete these files to prevent other plugins accidently using them
del include\script_version.inc
del include\script_name.inc 

:: Return to the original working directory
popd