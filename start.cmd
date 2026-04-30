@echo off
title MLOps Daily Starter

:: Вмикаємо UTF-8 про всяк випадок для внутрішньої обробки
chcp 65001 >nul

echo ===^> Searching for Bash execution environment...

:: ====================================================================
:: ВАРІАНТ 1: Стандартний шлях Git Bash (найшвидший і найпопулярніший)
:: ====================================================================
if exist "C:\Program Files\Git\bin\bash.exe" (
    echo [OK] Standard Git Bash found.
    "C:\Program Files\Git\bin\bash.exe" "%~dp0start.sh"
    goto :end
)

:: ====================================================================
:: ВАРІАНТ 2: Bash є у глобальному PATH (MSYS2, Cygwin, кастомні шляхи)
:: ====================================================================
where bash >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Global Bash found.
    bash "%~dp0start.sh"
    goto :end
)

:: ====================================================================
:: ВАРІАНТ 3: WSL (Підсистема Windows для Linux)
:: ====================================================================
where wsl >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] WSL found. Handing over to Linux subsystem...
    wsl bash "%~dp0start.sh"
    goto :end
)

:: ====================================================================
:: ВАРІАНТ 4: Тотальне фіаско (Елегантне падіння з інструкцією)
:: ====================================================================
echo.
echo ====================================================================
echo [CRITICAL ERROR] Bash environment NOT FOUND!
echo ====================================================================
echo This project uses universal scripts (.sh), but your system
echo lacks the tools to execute them.
echo.
echo To fix this, please install Git for Windows:
echo -^> Download: https://gitforwindows.org/
echo.
echo After installation, just run this file again.
echo ====================================================================
echo.

:end
pause
