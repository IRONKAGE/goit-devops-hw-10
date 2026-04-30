"""
Django settings for core project.
Architect: IRONKAGE
Environment: Kubernetes (Helm + Ingress) / LocalStack
"""

import os
from pathlib import Path

# ==========================================
# 1. Визначаємо базову директорію проекту
# ==========================================
BASE_DIR = Path(__file__).resolve().parent.parent

# ==========================================
# 2. Безпека: Секретний ключ та Debug
# ==========================================
SECRET_KEY = os.environ.get('SECRET_KEY', 'django-insecure-debug-key-12345')
DEBUG = int(os.environ.get('DEBUG', 1))

# У Kubernetes Ingress сам керує доменами, тому для Django зазвичай дозволяють все (*),
# або передають конкретний домен через ConfigMap
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '*').split(',')

# ==========================================
# 3. Додатки та Middleware
# ==========================================
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'whitenoise.runserver_nostatic',
    'django.contrib.staticfiles',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'core.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'core.wsgi.application'

# ==========================================
# 4. Конфігурація Бази Даних (PostgreSQL)
# ==========================================
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('POSTGRES_DB', 'django_db'),
        'USER': os.environ.get('POSTGRES_USER', 'db_admin'),
        'PASSWORD': os.environ.get('POSTGRES_PASSWORD', 'strong_password'),
        'HOST': os.environ.get('POSTGRES_HOST', 'db'),
        'PORT': os.environ.get('POSTGRES_PORT', '5432'),
    }
}

# ==========================================
# 5. Валідація паролів та Локалізація
# ==========================================
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

LANGUAGE_CODE = 'uk-ua'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# ==========================================
# 6. СТАТИЧНІ ФАЙЛИ (WhiteNoise для Kubernetes)
# ==========================================
STATIC_URL = 'static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')

# Цей параметр змушує Django стискати статику (gzip/brotli) та кешувати її
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
