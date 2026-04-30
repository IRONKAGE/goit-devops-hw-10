# Використовуємо офіційний легкий образ
FROM python:3.11-slim

# Встановлюємо змінні середовища для оптимізації Python
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    APP_HOME=/app

# Встановлюємо робочу директорію
WORKDIR $APP_HOME

# Створюємо непривілейованого користувача (Security Best Practice)
RUN addgroup --system appuser && adduser --system --group appuser

# Встановлюємо системні залежності (netcat потрібен для очікування бази даних)
RUN apt-get update && apt-get install -y netcat-traditional && rm -rf /var/lib/apt/lists/*

# Копіюємо та встановлюємо залежності
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# АРХІТЕКТУРНИЙ ФІКС: Копіюємо скрипт у КОРІНЬ (/), щоб volume його не затер
COPY ./entrypoint.sh /entrypoint.sh

# Надаємо права на скрипт запуску та змінюємо власника
RUN chmod +x /entrypoint.sh && \
    chown appuser:appuser /entrypoint.sh

# Копіюємо код проєкту
COPY ./core $APP_HOME/
RUN chown -R appuser:appuser $APP_HOME

# Перемикаємось на безпечного користувача
USER appuser

# Визначаємо скрипт, який виконається при старті (запускаємо з кореня!)
ENTRYPOINT ["/entrypoint.sh"]
