# To fix failed build of Dockerfile from origin
DOMAINS = ["*"]
DATABASES = {
    'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': 'db.sqlite3'
    }
}
