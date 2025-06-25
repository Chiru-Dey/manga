@echo off
setlocal enabledelayedexpansion

:: --- Configuration ---
set "SUWAYOMI_SERVER_DIR=Suwayomi-Server"
set "SUWAYOMI_WEBUI_DIR=Suwayomi-WebUI"
:: This will be the new data root for the server. It will be created in the current directory.
set "CUSTOM_DATA_ROOT=%CD%\suwayomi-data"
:: The server expects the WebUI to be in a 'webUI' subdirectory of its data root.
set "CUSTOM_WEBUI_TARGET_DIR=%CUSTOM_DATA_ROOT%\webUI"
set "SERVER_CONF_FILE=%CUSTOM_DATA_ROOT%\server.conf"

:: --- Kill previous server process (if any) ---
echo Attempting to kill any running Suwayomi-Server processes...
:: This is a best-effort attempt. It tries to find Java processes that have "Suwayomi-Server" in their command line.
:: This might not catch all instances or could be too broad if other Java apps use similar names.
for /f "tokens=2" %%a in ('tasklist /nh /fi "imagename eq java.exe" /fo csv') do (
    for /f "tokens=*" %%b in ('wmic process where "ProcessId=%%a" get CommandLine /value ^| findstr /i "Suwayomi-Server"') do (
        echo Found process %%a: %%b
        taskkill /PID %%a /F
    )
)
timeout /t 2 /nobreak >nul :: Give it a moment to terminate

:: --- Build Suwayomi-Server JAR ---
echo Building Suwayomi-Server JAR...
pushd "%SUWAYOMI_SERVER_DIR%"
if %errorlevel% ne 0 (
    echo Error: Suwayomi-Server directory not found! Exiting.
    exit /b 1
)
call gradlew.bat shadowJar
if %errorlevel% ne 0 (
    echo Error: Suwayomi-Server build failed! Exiting.
    popd
    exit /b 1
)
:: Find the generated JAR file path
set "SERVER_JAR_PATH="
for /f "delims=" %%i in ('dir /b /s server\build\libs\Suwayomi-Server-*.jar') do (
    set "SERVER_JAR_PATH=%%i"
    goto :found_server_jar
)
:found_server_jar
if not defined SERVER_JAR_PATH (
    echo Error: Suwayomi-Server JAR not found after build! Exiting.
    popd
    exit /b 1
)
echo Suwayomi-Server JAR built: %SERVER_JAR_PATH%
popd

:: --- Build Suwayomi-WebUI static files ---
echo Building Suwayomi-WebUI static files...
pushd "%SUWAYOMI_WEBUI_DIR%"
if %errorlevel% ne 0 (
    echo Error: Suwayomi-WebUI directory not found! Exiting.
    exit /b 1
)
call yarn install
if %errorlevel% ne 0 (
    echo Error: Suwayomi-WebUI yarn install failed! Exiting.
    popd
    exit /b 1
)
call yarn build
if %errorlevel% ne 0 (
    echo Error: Suwayomi-WebUI build failed! Exiting.
    popd
    exit /b 1
)
:: Get the absolute path of the built WebUI directory
set "WEBUI_BUILD_DIR=%CD%\build"
echo Suwayomi-WebUI built: %WEBUI_BUILD_DIR%
popd

:: --- Prepare custom data directory and copy WebUI ---
echo Preparing custom data directory: %CUSTOM_DATA_ROOT%
:: Clean up previous custom data directory if it exists
if exist "%CUSTOM_DATA_ROOT%" rmdir /s /q "%CUSTOM_DATA_ROOT%"
:: Create the target directory structure
mkdir "%CUSTOM_WEBUI_TARGET_DIR%"
if %errorlevel% ne 0 (
    echo Error: Failed to create custom WebUI target directory! Exiting.
    exit /b 1
)
:: Copy the contents of the built WebUI into the target directory
xcopy "%WEBUI_BUILD_DIR%" "%CUSTOM_WEBUI_TARGET_DIR%" /E /I /Y
if %errorlevel% ne 0 (
    echo Error: Failed to copy WebUI files to custom data directory! Exiting.
    exit /b 1
)
echo WebUI files copied to %CUSTOM_WEBUI_TARGET_DIR%

:: --- Determine WebUI Access Link ---
set "SERVER_IP=localhost"
set "SERVER_PORT=8080"

if exist "%SERVER_CONF_FILE%" (
    for /f "tokens=1,2,3 delims==" %%i in ('findstr /b /c:"ip =" "%SERVER_CONF_FILE%"') do (
        set "TEMP_IP=%%k"
        set "TEMP_IP=!TEMP_IP: =!"
        set "TEMP_IP=!TEMP_IP:"=!"
        if not "!TEMP_IP!"=="" (
            if "!TEMP_IP!"=="0.0.0.0" (
                set "SERVER_IP=localhost"
            ) else (
                set "SERVER_IP=!TEMP_IP!"
            )
        )
    )
    for /f "tokens=1,2,3 delims==" %%i in ('findstr /b /c:"port =" "%SERVER_CONF_FILE%"') do (
        set "TEMP_PORT=%%k"
        set "TEMP_PORT=!TEMP_PORT: =!"
        if not "!TEMP_PORT!"=="" set "SERVER_PORT=!TEMP_PORT!"
    )
)

:: --- Run Suwayomi-Server with custom WebUI path ---
echo Starting Suwayomi-Server with local WebUI...
echo Server Data Root: %CUSTOM_DATA_ROOT%
echo WebUI Flavor: CUSTOM (server will use local files)
echo Access the WebUI at: http://%SERVER_IP%:%SERVER_PORT%
echo. :: Newline for readability

:: Run the server, setting the data root and WebUI flavor via system properties
java -Dsuwayomi.tachidesk.config.server.rootDir="%CUSTOM_DATA_ROOT%" -Dsuwayomi.tachidesk.config.server.webUIFlavor=CUSTOM -jar "%SERVER_JAR_PATH%"

endlocal