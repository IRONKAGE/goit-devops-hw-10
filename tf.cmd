@echo off
setlocal EnableDelayedExpansion
:: Обгортка для Windows (God Mode: LocalStack Pro + Real AWS + K8s)

echo [*] Перевірка/Збірка образу Toolchain...
docker build -q -t ironkage-iac-toolchain-89:latest -f Dockerfile.iac .

echo [+] Запуск команди: %*

:: 1. Локальне середовище (LocalStack Pro)
if "%~1"=="tflocal" (
    :: Жорстко фіксуємо ім'я контейнера
    SET "LS_CONTAINER=localstack_main_89"

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
        ironkage-iac-toolchain-89:latest %*
) else (
:: 2. Бойове середовище (Terragrunt, Helm, AWS CLI)
    if not exist "%USERPROFILE%\.kube" mkdir "%USERPROFILE%\.kube"

    docker run --rm -it ^
        -v "%cd%":/workspace ^
        -v "%USERPROFILE%\.aws":/root/.aws ^
        -v "%USERPROFILE%\.kube":/root/.kube ^
        -e PYTHONUNBUFFERED=1 ^
        ironkage-iac-toolchain-89:latest %*
)
