@echo off
setlocal
echo.
echo ==============================
echo   TradApp Windows — Build
echo ==============================
echo.

:: Install dependencies
echo [1/3] Installation des dependances...
pip install -r requirements.txt pyinstaller
if errorlevel 1 goto error

:: Generate icon
echo [2/3] Creation de l'icone...
python create_icon.py
if errorlevel 1 goto error

:: Build exe
echo [3/3] Compilation...
pyinstaller tradapp.spec --clean
if errorlevel 1 goto error

echo.
echo ==============================
echo   Build termine !
echo   Executable : dist\TradApp.exe
echo ==============================
echo.
start "" "dist"
goto end

:error
echo.
echo ERREUR — le build a echoue.
pause
exit /b 1

:end
pause
