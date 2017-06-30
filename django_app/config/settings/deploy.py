from .base import *

config_secret_deploy = json.loads(open(CONFIG_SECRET_DEPLOY_FILE).read())

DEBUG = False

ALLOWED_HOSTS = config_secret_deploy['django']['allowed_hosts']

print('@@@@@@ DEBUG:', DEBUG)
print('@@@@@@ ALLOWED HOST', ALLOWED_HOSTS)

STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'static_root')