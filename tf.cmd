@echo off
setlocal EnableDelayedExpansion
:: Обгортка для Windows (God Mode: LocalStack Pro + Real AWS + K8s)

:: 0. Підвантаження .env файлу (якщо скрипт запускається без Makefile)
if exist ".env" (
    for /f "usebackq tokens=1,* delims==" %%A in (".env") do (
        :: Ігноруємо порожні рядки та коментарі
        if not "%%A"=="" if not "%%A"=="^#" set "%%A=%%B"
    )
)

:: Конфігураційні змінні
SET "TOOLCHAIN_IMG=ironkage-iac-toolchain-10:latest"
SET "LS_CONTAINER=localstack_main_hw_10"

echo [*] Перевірка/Збірка образу Toolchain...
docker build -q -t %TOOLCHAIN_IMG% -f Dockerfile.iac .

echo [+] Запуск команди: %*

:: 1. Локальне середовище (LocalStack Pro)
if "%~1"=="tflocal" (
    :: Отримуємо ПЕРШУ мережу (обходимо баг з додатковими мережами від k3d)
    SET "LS_NETWORK="
    FOR /F "tokens=*" %%i IN ('docker inspect !LS_CONTAINER! -f "{{range $k, $v := .NetworkSettings.Networks}}{{println $k}}{{end}}" 2^>nul') DO (
        IF "!LS_NETWORK!"=="" SET LS_NETWORK=%%i
    )

    :: Отримуємо ПЕРШУ чисту IP-адресу
    SET "LS_IP="
    FOR /F "tokens=*" %%i IN ('docker inspect !LS_CONTAINER! -f "{{range .NetworkSettings.Networks}}{{println .IPAddress}}{{end}}" 2^>nul') DO (
        IF "!LS_IP!"=="" SET LS_IP=%%i
    )

    IF "!LS_IP!"=="" (
        echo [-] Помилка: Не вдалося отримати IP-адресу LocalStack Pro. Перевірте, чи запущений контейнер: docker ps
        exit /b 1
    )

    echo [*] LocalStack Pro: Мережа = !LS_NETWORK! ^| IP = !LS_IP!

    :: Запускаємо Terraform, використовуючи ТІЛЬКИ IP-адресу
    docker run --rm -it ^
        -v "%cd%":/workspace ^
        --network "!LS_NETWORK!" ^
        -e PYTHONUNBUFFERED=1 ^
        -e LOCALSTACK_HOST="!LS_IP!" ^
        -e AWS_ENDPOINT_URL="http://!LS_IP!:4566" ^
        -e AWS_ACCESS_KEY_ID=test ^
        -e AWS_SECRET_ACCESS_KEY=test ^
        -e AWS_SESSION_TOKEN=dummy ^
        -e AWS_DEFAULT_REGION=eu-central-1 ^
        -e LOCALSTACK_AUTH_TOKEN="%LOCALSTACK_AUTH_TOKEN%" ^
        -e TF_VAR_localstack_ip="!LS_IP!" ^
        %TOOLCHAIN_IMG% %*
) else (
:: 2. Бойове середовище (Terragrunt, Helm, AWS CLI)
    :: Страховка: створюємо папки, якщо їх немає, щоб Docker не створив їх під рутом
    if not exist "%USERPROFILE%\.kube" mkdir "%USERPROFILE%\.kube"
    if not exist "%USERPROFILE%\.aws" mkdir "%USERPROFILE%\.aws"
    if not exist "%USERPROFILE%\.ssh" mkdir "%USERPROFILE%\.ssh"

    :: Запускаємо бойовий тулчейн із розширеним монтуванням
    docker run --rm -it ^
        -v "%cd%":/workspace ^
        -v "%USERPROFILE%\.aws":/root/.aws ^
        -v "%USERPROFILE%\.kube":/root/.kube ^
        -v "%USERPROFILE%\.ssh":/root/.ssh ^
        -e PYTHONUNBUFFERED=1 ^
        -e AWS_PROFILE="%AWS_PROFILE%" ^
        -e AWS_REGION="%AWS_REGION%" ^
        %TOOLCHAIN_IMG% %*
)
