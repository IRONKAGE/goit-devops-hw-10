#!/bin/sh
set -e

# ==============================================================================
# MLOps Omni-Starter (Universal Docker Health-Check & Auto-Start)
# Архітектура: Коментарі українською, stdout англійською для 100% сумісності.
# Підтримує: systemd, OpenRC (Alpine/Gentoo), runit (Void), sysvinit (Legacy),
#            Lima (BSD/macOS), Docker Desktop (Win/Mac), Docker Toolbox (Win 7).
# ==============================================================================

printf "\n===> [1/2] Checking Docker Engine health...\n"

# 1. Перевірка чи встановлено CLI взагалі
if ! command -v docker >/dev/null 2>&1; then
    printf "[CRITICAL ERROR] Docker CLI is not found on this system.\n"
    printf "Please run the appropriate IaC provisioner for your OS.\n"
    exit 1
fi

# 2. Інтелектуальна діагностика Демона та Спроба Автозапуску
if ! DOCKER_ERR=$(docker ps 2>&1 >/dev/null); then
    printf "[WARNING] DOCKER IS INSTALLED, BUT THE DAEMON IS UNREACHABLE!\n\n"
    OS_TYPE=$(uname -s)

    # Сценарій А: Проблема з правами доступу
    if echo "$DOCKER_ERR" | grep -qi "permission denied"; then
        printf "  [Issue] Permission Denied: Your user cannot read the Docker socket.\n"
        printf "  [Fix]   Run: newgrp docker\n"
        exit 1

    # Сценарій Б: TLS помилка (Специфічно для Docker Toolbox на Legacy Windows)
    elif echo "$DOCKER_ERR" | grep -qi "error during connect\|tls"; then
        printf "  [Issue] TLS Connection Error (Likely Docker Toolbox / Legacy Engine).\n"
        printf "  [Fix]   Please run this project from the 'Docker Quickstart Terminal'.\n"
        exit 1

    # Сценарій В: Демон лежить (Спроба Автозапуску + Fallback)
    else
        printf "  [Issue] Docker daemon is not running.\n"
        printf "  [Action] Attempting to auto-start Docker...\n"

        STARTED=0

        # Спроба системного автозапуску (використовуємо '|| true' щоб set -e не вбив скрипт)
        if command -v limactl >/dev/null 2>&1; then
            limactl start docker && STARTED=1 || true
        elif [ "$OS_TYPE" = "Darwin" ]; then
            open -a Docker && STARTED=1 || true
        elif [ "$OS_TYPE" = "Linux" ]; then
            if grep -qi microsoft /proc/version 2>/dev/null; then
                # WSL зазвичай вимагає запуску Docker Desktop з-під Windows
                STARTED=0
            elif command -v systemctl >/dev/null 2>&1; then
                sudo systemctl start docker && STARTED=1 || true
            elif command -v rc-service >/dev/null 2>&1; then
                sudo rc-service docker start && STARTED=1 || true
            elif command -v sv >/dev/null 2>&1; then
                sudo sv start docker && STARTED=1 || true
            else
                sudo service docker start && STARTED=1 || true
            fi
        fi

        # Якщо команда запуску пройшла (особливо актуально для macOS / systemd)
        if [ "$STARTED" -eq 1 ]; then
            printf "  ⏳ Waiting for Docker Engine to wake up."
            WAIT_COUNT=0
            # Чекаємо до 60 секунд
            while ! docker ps >/dev/null 2>&1; do
                if [ "$WAIT_COUNT" -ge 30 ]; then
                    break
                fi
                printf "."
                sleep 2
                WAIT_COUNT=$((WAIT_COUNT + 1))
            done
            printf "\n"
        fi

        # Якщо після спроби автозапуску Докер все ще лежить
        if ! docker ps >/dev/null 2>&1; then
            printf "\n  [WARNING] Auto-start failed or requires manual intervention.\n"
            printf "  [Fix for your specific environment]:\n"

            if command -v limactl >/dev/null 2>&1; then
                printf "   -> BSD/macOS (Lima VM): Run 'limactl start docker'\n"
                printf "      And ensure DOCKER_HOST is exported.\n"
            elif [ "$OS_TYPE" = "Darwin" ]; then
                printf "   -> macOS: Launch 'Docker Desktop' from Applications.\n"
            elif [ "$OS_TYPE" = "Linux" ]; then
                if grep -qi microsoft /proc/version 2>/dev/null; then
                    printf "   -> Windows (WSL): Launch 'Docker Desktop' in your Windows host.\n"
                elif command -v systemctl >/dev/null 2>&1; then
                    printf "   -> Linux (systemd): Run 'sudo systemctl start docker'\n"
                elif command -v rc-service >/dev/null 2>&1; then
                    printf "   -> Alpine/Gentoo (OpenRC): Run 'sudo rc-service docker start'\n"
                elif command -v sv >/dev/null 2>&1; then
                    printf "   -> Void Linux (runit): Run 'sudo sv start docker'\n"
                else
                    printf "   -> Legacy Linux (sysvinit): Run 'sudo service docker start'\n"
                fi
            else
                printf "   -> Windows/Other: Ensure Docker Desktop or Daemon is running.\n"
            fi

            printf "\n⏳ Please fix the issue and run this script again.\n"
            exit 1
        fi
    fi
fi

printf "[OK] Docker Engine is active and ready!\n"

# ==========================================
# 3. АВТОВИЗНАЧЕННЯ ВЕРСІЇ COMPOSE ТА ЗАПУСК
# ==========================================
printf "\n===> [2/2] Building and starting the project...\n"

# Новий синтаксис (Docker Compose V2 - стандарт де-факто)
if docker compose version >/dev/null 2>&1; then
    printf "[INFO] Using: Docker Compose V2 (Native)\n"
    docker compose up -d --build

# Старий синтаксис (docker-compose V1 - спадкові системи)
elif docker-compose --version >/dev/null 2>&1; then
    printf "[INFO] Using: docker-compose V1 (Legacy)\n"
    docker-compose up -d --build

# Якщо плагін не знайдено взагалі
else
    printf "[CRITICAL ERROR] Compose plugin not found!\n"
    exit 1
fi

printf "\n[SUCCESS] Project deployed successfully! Environment is up and running.\n Open your browser and click: http://localhost\n"
