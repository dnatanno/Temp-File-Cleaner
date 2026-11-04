@setlocal EnableExtensions DisableDelayedExpansion

@fltmc >nul 2>&1
@if errorlevel 1 (
    @powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    @exit /b
)

@set "STORAGE_POLICY=HKLM\SOFTWARE\Policies\Microsoft\Windows\StorageSense"
@reg add "%STORAGE_POLICY%" /v AllowStorageSenseGlobal /t REG_DWORD /d 1 /f >nul 2>&1
@reg add "%STORAGE_POLICY%" /v AllowStorageSenseTemporaryFilesCleanup /t REG_DWORD /d 1 /f >nul 2>&1
@reg add "%STORAGE_POLICY%" /v ConfigStorageSenseDownloadsCleanupThreshold /t REG_DWORD /d 0 /f >nul 2>&1
@reg add "%STORAGE_POLICY%" /v ConfigStorageSenseGlobalCadence /t REG_DWORD /d 1 /f >nul 2>&1

@call :CleanFolder "%TEMP%"
@call :CleanFolder "%WINDIR%\Temp"
@call :CleanFolder "%WINDIR%\Prefetch"
@call :CleanFolder "%LOCALAPPDATA%\D3DSCache"

@taskkill /f /im explorer.exe >nul 2>&1
@call :CleanFolder "%APPDATA%\Microsoft\Windows\Recent"
@call :CleanFolder "%APPDATA%\Microsoft\Windows\Recent\AutomaticDestinations"
@call :CleanFolder "%APPDATA%\Microsoft\Windows\Recent\CustomDestinations"
@call :CleanFolder "%LOCALAPPDATA%\Microsoft\Windows\Explorer"
@call :DeleteFile "%LOCALAPPDATA%\IconCache.db"
@start "" explorer.exe

@call :CleanWindowsUpdateDownloads
@exit /b 0

:CleanFolder
@set "CLEAN_TARGET=%~1"
@for %%N in (1 2) do (
    @powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$p=$env:CLEAN_TARGET; if (Test-Path -LiteralPath $p -PathType Container) { Get-ChildItem -LiteralPath $p -Force -ErrorAction SilentlyContinue | ForEach-Object { try { Remove-Item -LiteralPath $_.FullName -Force -Recurse -ErrorAction Stop } catch { } } }" >nul 2>&1
)
@exit /b

:DeleteFile
@set "CLEAN_FILE=%~1"
@for %%N in (1 2) do if exist "%CLEAN_FILE%" del /f /q "%CLEAN_FILE%" >nul 2>&1
@exit /b

:CleanWindowsUpdateDownloads
@set "CLEAN_TARGET=C:\Windows\SoftwareDistribution\Download"
@powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$names=@('wuauserv','bits'); $running=@(Get-Service -Name $names -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Running' } | Select-Object -ExpandProperty Name); try { Stop-Service -Name $names -Force -ErrorAction SilentlyContinue; foreach($n in 1..2) { $p=$env:CLEAN_TARGET; if (Test-Path -LiteralPath $p -PathType Container) { Get-ChildItem -LiteralPath $p -Force -ErrorAction SilentlyContinue | ForEach-Object { try { Remove-Item -LiteralPath $_.FullName -Force -Recurse -ErrorAction Stop } catch { } } } } } finally { foreach($name in $running) { try { Start-Service -Name $name -ErrorAction Stop } catch { } } }" >nul 2>&1
@exit /b