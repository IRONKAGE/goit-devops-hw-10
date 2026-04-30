# ==============================================================================
# AWS DevOps Makefile (Enterprise UI + Terragrunt + Helm + Ingress)
# ==============================================================================

# Підтягуємо змінні для Helm
include .env
export $(shell sed 's/=.*//' .env)

# 0. Кросплатформна підтримка (ОС та Docker)
ifeq ($(OS),Windows_NT)
	TG_WRAPPER := tf.cmd
	DOCKER_START_CMD := start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
	WAIT_DOCKER := powershell -Command "do { Write-Host 'Чекаю на Docker...'; Start-Sleep -Seconds 2 } while (!(docker info 2>$$null))"
else
	TG_WRAPPER := ./tf.sh
	DOCKER_START_CMD := open -a Docker
	WAIT_DOCKER := until docker info >/dev/null 2>&1; do echo "Чекаю на Docker..."; sleep 3; done
endif

# 1. Налаштування середовищ та інфраструктури
VALID_ENVS   := dev prod
DEFAULT_ENV  := dev
REGION       := eu-central-1
CLUSTER_NAME := ironkage-k8s-hw89-cluster
APP_NAME     := django-app-hw89
TOOLCHAIN_IMG:= ironkage-iac-toolchain-89:latest

# 2. Зчитуємо аргументи
CMD    := $(word 1, $(MAKECMDGOALS))
ENV    := $(if $(word 2, $(MAKECMDGOALS)), $(word 2, $(MAKECMDGOALS)), $(DEFAULT_ENV))
DOMAIN := $(word 3, $(MAKECMDGOALS))
ENV_FILE := $(ENV).tfvars

# 3. Валідація середовища
ifneq ($(filter deploy-local deploy-aws destroy-local destroy-aws test-local test-aws, $(CMD)),)
	ifeq ($(filter $(ENV), $(VALID_ENVS)),)
		$(error [ПОМИЛКА] Невідоме середовище '$(ENV)'. Доступні середовища: $(VALID_ENVS))
	endif
endif

# 4. Інтелектуальна логіка Ingress
HELM_SET_FLAGS := --set secrets.SECRET_KEY=$(DJANGO_SECRET_KEY) --set secrets.POSTGRES_PASSWORD=$(POSTGRES_PASSWORD)

ifneq ($(DOMAIN),)
	HELM_SET_FLAGS += --set ingress.enabled=true \
	                  --set ingress.hosts[0].host=$(DOMAIN) \
	                  --set ingress.tls[0].hosts[0]=$(DOMAIN)
	USE_DOMAIN := true
else
	HELM_SET_FLAGS += --set ingress.enabled=false
	USE_DOMAIN := false
endif

.DEFAULT_GOAL := help
.PHONY: help docker-ensure up down test-local test-aws deploy-local deploy-aws bootstrap-cluster deploy-app destroy-local destroy-aws clean deep-clean

# ==============================================================================
# БАЗОВЕ МЕНЮ
# ==============================================================================

help:
	@echo "============================================================="
	@echo " Доступні команди (Terragrunt + Helm):"
	@echo "============================================================="
	@echo "  make help                        - Показати це меню"
	@echo "  make up                          - Запустити LocalStack Pro"
	@echo "  make down                        - Зупинити LocalStack Pro"
	@echo "  make test-local [env]            - План локального розгортання"
	@echo "  make test-aws [env]              - План бойового розгортання (AWS)"
	@echo "  make deploy-local [env]          - Деплой локально (LocalStack Pro)"
	@echo "  make open-jenkins                - Відкрити UI Jenkins та прокинути порт"
	@echo "  make open-argocd                 - Відкрити UI ArgoCD та прокинути порт"
	@echo "  make deploy-aws [env]            - Бойовий деплой (ClusterIP)"
	@echo "  make deploy-aws [env] [domain]   - Бойовий деплой (Ingress + TLS)"
	@echo "  make destroy-local [env]         - Знищити локальні ресурси"
	@echo "  make destroy-aws [env]           - Знищити ресурси AWS"
	@echo "  make clean                       - Очистити кеші Terragrunt/Terraform"
	@echo "  make deep-clean                  - Видалити всі образи та кеші"
	@echo "============================================================="
	@echo " * Середовища: $(VALID_ENVS) (Поточне: $(ENV))"
	@echo " * Обгортка:   $(TG_WRAPPER)"
	@echo "============================================================="

docker-ensure:
	@echo "[*] Перевірка стану Docker..."
	@docker info >/dev/null 2>&1 || (echo "[!] Docker вимкнений. Запускаю..." && $(DOCKER_START_CMD) && $(WAIT_DOCKER))
	@echo "[+] Docker готовий!"

up: docker-ensure
	@echo "[*] Запуск LocalStack Pro..."
	docker compose up -d localstack
	@echo "[*] Перевірка готовності API LocalStack Pro..."
	@curl -s http://localhost:4566/_localstack/health >/dev/null || (echo "[*] Очікування старту сервісів (5 сек)..." && sleep 5)
	@echo "[+] LocalStack Pro готовий!"

down:
	@echo "[*] Зупинка LocalStack Pro..."
	docker compose down

# ==============================================================================
# БРАУЗЕР (Кросплатформне відкриття)
# ==============================================================================
ifeq ($(OS),Windows_NT)
	OPEN_CMD := start ""
else
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Linux)
		OPEN_CMD := xdg-open
	endif
	ifeq ($(UNAME_S),Darwin)
		OPEN_CMD := open
	endif
endif

# ==============================================================================
# ШВИДКИЙ ДОСТУП ДО UI (God Mode)
# ==============================================================================
open-jenkins:
	@echo "========================================"
	@echo "⏳ Отримання Kubeconfig з LocalStack EKS..."
	@echo "🤖 Режим 'Привид-друкар': через 10 секунд браузер відкриється і сам залогується!"
	@echo "⚠️  УВАГА: Не чіпайте клавіатуру пару секунд, коли відкриється вкладка Jenkins :)"
	@echo "========================================"
	@(sleep 10 && open http://localhost:8080 && sleep 4 && osascript -e 'tell application "System Events"' -e 'keystroke "admin"' -e 'key code 48' -e 'keystroke "admin_password_123"' -e 'key code 36' -e 'end tell') &
	./tf.sh bash -c "export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=eu-central-1 && aws --endpoint-url=http://172.18.0.2:4566 eks update-kubeconfig --region eu-central-1 --name ironkage-k8s-hw89-dev && sed -i 's/localhost.localstack.cloud/172.18.0.2/g' /root/.kube/config && kubectl port-forward --insecure-skip-tls-verify --address 0.0.0.0 svc/jenkins -n jenkins 8080:8080"

open-argocd:
	@echo "========================================"
	@echo "⏳ Отримання Kubeconfig та пароля ArgoCD..."
	@echo "🤖 Режим 'Привид-друкар': через 10 секунд браузер відкриється і сам залогується!"
	@echo "========================================"
	@# Дістаємо пароль АБСОЛЮТНО ТИХО, без логів tf.sh
	$(eval ARGO_PASS := $(shell docker run --rm --network "goit-devops-hw-08-09_default" -e AWS_ACCESS_KEY_ID=test -e AWS_SECRET_ACCESS_KEY=test -e AWS_DEFAULT_REGION=eu-central-1 -v ~/.kube:/root/.kube ironkage-iac-toolchain-89:latest bash -c "aws --endpoint-url=http://172.18.0.2:4566 eks update-kubeconfig --region eu-central-1 --name ironkage-k8s-hw89-dev >/dev/null 2>&1 && sed -i 's/localhost.localstack.cloud/172.18.0.2/g' /root/.kube/config && kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' --insecure-skip-tls-verify | base64 -d"))
	@echo "🔑 Логін: admin"
	@echo "🔑 Пароль: $(ARGO_PASS) (Скопійовано в буфер обміну!)"
	@echo -n "$(ARGO_PASS)" | pbcopy
	@(sleep 10 && open https://localhost:8081 && sleep 5 && osascript -e 'tell application "System Events"' -e 'keystroke "admin"' -e 'key code 48' -e 'keystroke "$(ARGO_PASS)"' -e 'key code 36' -e 'end tell') &
	./tf.sh bash -c "export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=eu-central-1 && aws --endpoint-url=http://172.18.0.2:4566 eks update-kubeconfig --region eu-central-1 --name ironkage-k8s-hw89-dev && sed -i 's/localhost.localstack.cloud/172.18.0.2/g' /root/.kube/config && kubectl port-forward --insecure-skip-tls-verify --address 0.0.0.0 svc/argocd-server -n argocd 8081:443"

# ==============================================================================
# ТЕСТУВАННЯ (Dry-Run)
# ==============================================================================

test-local: up
	@echo "[*] План локальної інфраструктури ($(ENV))..."
	$(TG_WRAPPER) tflocal init
	$(TG_WRAPPER) tflocal plan -var-file $(ENV_FILE)

test-aws: docker-ensure
	@echo "[*] План бойової інфраструктури AWS ($(ENV))..."
	$(TG_WRAPPER) terragrunt run-all plan -var-file $(ENV_FILE)

# ==============================================================================
# ДЕПЛОЙ (Створення ресурсів)
# ==============================================================================

deploy-local: up
	@echo "[*] Запуск локального деплою для середовища: $(ENV)..."
	$(TG_WRAPPER) tflocal init
	$(TG_WRAPPER) tflocal apply -var-file $(ENV_FILE) -auto-approve
	@echo "[+] Локальний деплой успішно завершено!"

deploy-aws: docker-ensure
	@echo "[*] Початок деплою в AWS | Середовище: $(ENV) | Домен: $(if $(DOMAIN),$(DOMAIN),БЕЗ ДОМЕНУ)"
	@echo "[*] 1. Створення інфраструктури (Terragrunt)..."
	$(TG_WRAPPER) terragrunt run-all apply --terragrunt-non-interactive
	@if [ "$(USE_DOMAIN)" = "true" ]; then \
		make bootstrap-cluster; \
	fi
	@make deploy-app

bootstrap-cluster:
	@echo "[*] Автоматична підготовка кластера до роботи з доменом..."
	$(TG_WRAPPER) aws eks update-kubeconfig --region $(REGION) --name $(CLUSTER_NAME)
	$(TG_WRAPPER) helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	$(TG_WRAPPER) helm repo add jetstack https://charts.jetstack.io
	$(TG_WRAPPER) helm repo update
	$(TG_WRAPPER) helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace
	$(TG_WRAPPER) helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true
	@echo "[*] Очікування ініціалізації Cert-Manager (30 сек)..." && sleep 30
	$(TG_WRAPPER) kubectl apply -f cluster-issuer.yaml
	@echo "[+] Кластер готовий до роботи з Ingress!"

deploy-app:
	@echo "[*] 2. Авторизація та пуш Docker-образу в ECR..."
	$(TG_WRAPPER) aws eks update-kubeconfig --region $(REGION) --name $(CLUSTER_NAME)
	$(eval ECR_URL := $(shell $(TG_WRAPPER) terragrunt output -raw ecr_repository_url))
	$(TG_WRAPPER) aws ecr get-login-password --region $(REGION) | docker login --username AWS --password-stdin $(ECR_URL)
	docker build -t $(APP_NAME):latest .
	docker tag $(APP_NAME):latest $(ECR_URL):latest
	docker push $(ECR_URL):latest
	@echo "[*] 3. Деплой застосунку через Helm..."
	$(TG_WRAPPER) helm upgrade --install $(APP_NAME) ./charts/django-app \
		--set image.repository=$(ECR_URL) \
		$(HELM_SET_FLAGS)
	@echo "🚀 [SUCCESS] Проєкт успішно розгорнуто!"

# ==============================================================================
# ОЧИЩЕННЯ (Видалення ресурсів)
# ==============================================================================

destroy-local: up
	@echo "[*] Видалення локальних ресурсів для середовища: $(ENV)..."
	$(TG_WRAPPER) tflocal destroy -var-file $(ENV_FILE) -auto-approve
	@echo "[+] Локальні ресурси видалено!"

destroy-aws: docker-ensure
	@echo "⚠️ [УВАГА] Повне видалення бойової інфраструктури AWS ($(ENV))..."
	-$(TG_WRAPPER) aws eks update-kubeconfig --region $(REGION) --name $(CLUSTER_NAME)
	@echo "[-] Видалення Helm релізів..."
	-$(TG_WRAPPER) helm uninstall $(APP_NAME)
	-$(TG_WRAPPER) helm uninstall ingress-nginx --namespace ingress-nginx
	-$(TG_WRAPPER) helm uninstall cert-manager --namespace cert-manager
	@echo "[*] Очікування (15 сек), щоб AWS встиг видалити фізичні балансувальники..." && sleep 15
	@echo "[-] Видалення інфраструктури Terragrunt..."
	$(TG_WRAPPER) terragrunt run-all destroy --terragrunt-non-interactive
	@echo "[+] Хмарні ресурси успішно видалено!"

clean:
	@echo "[*] Очищення кешів Terragrunt, Terraform та стейтів..."
ifeq ($(OS),Windows_NT)
	-for /d /r . %d in (.terragrunt-cache) do @if exist "%d" rd /s /q "%d"
	-rmdir /s /q .terraform 2>nul
	-del /q terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl 2>nul
else
	find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} +
	rm -rf .terraform terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl
endif
	@echo "[+] Кеш очищено!"

deep-clean: clean
	@echo "[*] Зупинка сервісів та динамічне видалення Docker-образів..."
	docker compose down --rmi all -v
	-docker rmi -f $(APP_NAME):latest 2>/dev/null
	-docker rmi -f $(TOOLCHAIN_IMG) 2>/dev/null
	@echo "[+] Сервер повністю очищено від образів цього проєкту. Пам'ять звільнено!"

# Хак для ігнорування невідомих аргументів
%:
	@:
