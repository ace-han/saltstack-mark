saltpad_setup.md

# Source code retrieval
```sh
git clone git@github.com:tinyclues/saltpad.git
pyenv virtualenv 2.7.9 saltpad
pyenv activate saltpad
cd saltpad
pip install -r requirement.txt
```

# salt-api running
refer to [salt-master_n_salt-api_setup.md](https://github.com/ace-han/saltstack-mark/blob/master/salt-master_n_salt-api_setup.md)

# Cherrypy config
`default_settings.py` # pay attention to `API_URL` make it point to your `salt-api`
`local_settings.py` # pay attention to `SECRET_KEY`, `HOST` and `EAUTH`
```python
# TODO: Generate a random key ith os.urandom(24)
# SECRET_KEY = ''

# Uncomment next line if you want to add sentry support
# You'll also need to install raven[flask]
# SENTRY_DSN = "https://YOUR_SENTRY_DSN"

# Uncomment next line if your API use a self-signed HTTPS certificate
# VERIFY_SSL = False

# You can make saltpad bind 0.0.0.0 (all server address) but you should
# only bind 0.0.0.0 for testing purposes, you should really deploy
# saltpad in production using a wsgi server (like gunicorn or chaussette)
# behind nginx, you have been warned!
HOST = "127.0.0.1"

# You can customize the external auth module to use, by default, pam is used
EAUTH = "mysql"

```


# uwsgi setup 
```sh
pip install uwsgi
```
```sh
# start_saltpad.sh
# place this file in ${PROJECT_ROOT}/bin (create the folder if necessary)

ORIGINAL_DIR=`pwd`
SCRIPT_HOME=$(cd "$(dirname "$0")"; pwd)

PROJECT_NAME=saltpad

PROJECT_HOME=$SCRIPT_HOME/../$PROJECT_NAME

export PYENV_ROOT="${HOME}/.pyenv"

if [ -d "${PYENV_ROOT}" ]; then
  export PATH="${PYENV_ROOT}/bin:${PATH}"
  eval "$(pyenv init -)"
fi

pyenv activate $PROJECT_NAME 

uwsgi --chdir $PROJECT_HOME --module app:app --master --processes 2 --threads 2 --vacuum --pidfile $SCRIPT_HOME/$PROJECT_NAME.pid --socket $SCRIPT_HOME/$PROJECT_NAME.sock --harakiri 60 --max-requests 5000 --daemonize $SCRIPT_HOME/$PROJECT_NAME.log
pyenv deactivate
cd $ORIGINAL_DIR

```

```sh
# stop_saltpad.sh
#!/bin/sh

ps -ef | grep saltpad | awk '{print $2}'| xargs kill -9

```
```sh
cd ${PROJECT_ROOT}/bin
chmod 777 *.sh

```

# nginx setup
```sh
# please make sure nginx working with uwsgi
upstream saltpad {
  server unix:/home/xxx/workspace/github/saltpad/bin/saltpad.sock;
}

server {
  listen 80;
  server_name YOUR.DOMAIN;
  return 301 https://YOUR.DOMAIN$request_uri;
}

server {
  listen 443 ssl;         # e.g., listen 192.168.1.1:80; In most cases *:80 is a good idea
  server_name YOUR.DOMAIN;     # e.g., server_name source.example.com;

  server_tokens off;     # don't show the version number, a security best practice
  ssl_certificate /etc/pki/tls/certs/localhost.crt;
  ssl_certificate_key /etc/pki/tls/certs/localhost.key;
  client_max_body_size 5m;

  access_log  /var/log/nginx/saltpad_access.log;
  error_log   /var/log/nginx/saltpad_error.log;

  location / {
    uwsgi_pass saltpad;
    include uwsgi_params;
    #proxy_pass http://saltpad;
    #proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    #proxy_set_header Host $http_host;
    #proxy_set_header X-Real-IP $remote_addr;
  }

}
```
