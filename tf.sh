#!/bin/sh
# Обгортка для Mac/Linux (God Mode: LocalStack Pro + Real AWS + K8s)

# 0. Підвантаження .env файлу (якщо скрипт запускається без Makefile)
if [ -f ".env" ]; then
    # Ігноруємо коментарі та безпечно експортуємо змінні
    export $(grep -v '^#' .env | xargs)
fi

# Конфігураційні змінні
TOOLCHAIN_IMG="ironkage-iac-toolchain-10:latest"
LS_CONTAINER="localstack_main_hw_10"
PROD_NETWORK="goit-devops-hw-10_default"

echo "[*] Перевірка/Збірка образу Toolchain..."
docker build -q -t "$TOOLCHAIN_IMG" -f Dockerfile.iac .

echo "[+] Запуск команди: $@"

# 1. Локальне середовище (LocalStack Pro)
if [ "$1" = "tflocal" ]; then
    # Надійно отримуємо IP-адресу, щоб обійти баги Docker на Mac
    LS_NETWORK=$(docker inspect "$LS_CONTAINER" -f '{{range $k, $v := .NetworkSettings.Networks}}{{println $k}}{{end}}' 2>/dev/null | head -n 1)
    LS_IP=$(docker inspect "$LS_CONTAINER" 2>/dev/null | grep -E '"IPAddress": "[0-9]+\.' | head -n 1 | cut -d '"' -f 4)

    if [ -z "$LS_IP" ]; then
        echo "[-] Помилка: Не вдалося отримати IP-адресу LocalStack Pro. Перевірте, чи запущений контейнер: docker ps"
        exit 1
    fi

    echo "[*] LocalStack Pro: Мережа = $LS_NETWORK | IP = $LS_IP"

    docker run --rm -it \
        -v "$(pwd)":/workspace \
        --network "$LS_NETWORK" \
        -e PYTHONUNBUFFERED=1 \
        -e LOCALSTACK_HOST="$LS_IP" \
        -e AWS_ENDPOINT_URL="http://$LS_IP:4566" \
        -e AWS_ACCESS_KEY_ID=test \
        -e AWS_SECRET_ACCESS_KEY=test \
        -e AWS_SESSION_TOKEN=dummy \
        -e AWS_DEFAULT_REGION=eu-central-1 \
        -e LOCALSTACK_AUTH_TOKEN="${LOCALSTACK_AUTH_TOKEN}" \
        -e TF_VAR_localstack_ip="$LS_IP" \
        "$TOOLCHAIN_IMG" "$@"
else
# 2. Бойове середовище (Terragrunt, Helm, AWS CLI)
    # Створюємо папки на хості, якщо їх немає (щоб Docker не створив їх під root)
    mkdir -p ~/.kube ~/.aws ~/.ssh

    # Монтуємо РЕАЛЬНІ ключі AWS, конфіги Kubernetes, SSH-ключі та ВІДКРИВАЄМО ПОРТИ
    docker run --rm -it \
        --network "$PROD_NETWORK" \
        -v "$(pwd)":/workspace \
        -v ~/.aws:/root/.aws \
        -v ~/.kube:/root/.kube \
        -v ~/.ssh:/root/.ssh \
        -p 8080:8080 \
        -p 8081:8081 \
        -e PYTHONUNBUFFERED=1 \
        -e AWS_PROFILE="${AWS_PROFILE}" \
        -e AWS_REGION="${AWS_REGION}" \
        "$TOOLCHAIN_IMG" "$@"
fi
