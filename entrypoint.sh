#!/bin/bash
set -e

echo "⏳ Чекаємо на PostgreSQL ($POSTGRES_HOST:$POSTGRES_PORT)..."
while ! nc -z $POSTGRES_HOST $POSTGRES_PORT; do
  sleep 0.5
done
echo "✅ PostgreSQL запущено!"

echo "🔄 Застосовуємо міграції бази даних..."
python manage.py migrate --noinput || echo "⚠️ Міграції вже виконуються іншим подом"

echo "📁 Збираємо статичні файли..."
python manage.py collectstatic --noinput

echo "🚀 Запускаємо Gunicorn сервер..."
exec gunicorn core.wsgi:application --bind 0.0.0.0:8000 --workers 3
