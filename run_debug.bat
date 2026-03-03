@echo off
cd build\windows\x64\runner\Debug
echo Ejecutando aplicacion...
punto_venta_app.exe
echo.
echo Codigo de salida: %ERRORLEVEL%
pause
