@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo   Iniciando proceso de Release (Flutter Windows)
echo ===================================================

echo.
echo [1/4] Obteniendo dependencias (pub get)...
call fvm flutter pub get
if %ERRORLEVEL% neq 0 (
echo.
echo [ERROR] Fallo al ejecutar 'fvm flutter pub get'.
goto :error
)

echo.
echo [2/4] Ejecutando build_runner...
call fvm dart run build_runner build --delete-conflicting-outputs
if %ERRORLEVEL% neq 0 (
echo.
echo [ERROR] Fallo al ejecutar 'build_runner'.
goto :error
)

echo.
echo [3/4] Compilando aplicacion para Windows (Release)...
call fvm flutter build windows --release --dart-define-from-file=.dart_define.json --no-tree-shake-icons
if %ERRORLEVEL% neq 0 (
echo.
echo [ERROR] Fallo al compilar la aplicacion con Flutter.
goto :error
)

echo.
echo [4/4] Generando instalador con Inno Setup...
"C:\Program Files\Inno Setup 7\ISCC.exe" "installer\punto_venta.iss"
if %ERRORLEVEL% neq 0 (
echo.
echo [ERROR] Fallo al compilar el instalador en Inno Setup.
goto :error
)

echo.
echo ===================================================
echo   COMPILACION Y EMPAQUETADO FINALIZADOS CON EXITO
echo ===================================================
pause
exit /b 0

:error
echo.
echo ===================================================
echo   EL PROCESO SE HA DETENIDO DEBIDO A UN ERROR
echo ===================================================
pause
exit /b 1