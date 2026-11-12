@echo off
setlocal
set "COMPILER=%WINDIR%\Microsoft.NET\Framework\v4.0.30319\csc.exe"
if not exist "%COMPILER%" (
    echo The .NET Framework 4 C# compiler was not found. 1>&2
    exit /b 1
)
if not exist "%~dp0bin" mkdir "%~dp0bin"
if not exist "%~dp0bin" exit /b 1
"%COMPILER%" /nologo /target:winexe /optimize+ /reference:System.dll /reference:System.Drawing.dll /reference:System.Windows.Forms.dll "/out:%~dp0bin\AERoPlotWindowsUI.exe" "%~dp0TableUI.cs" "%~dp0PlotUI.cs" "%~dp0TablePlotUI.cs"
if errorlevel 1 exit /b 1
echo Built %~dp0bin\AERoPlotWindowsUI.exe
