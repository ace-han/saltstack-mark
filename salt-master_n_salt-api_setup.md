h1 salt-master setup

* Install
sudo add-apt-repository ppa:saltstack/salt
sudo apt-get update
sudo apt-get install salt-master

* Configuration
## change user in /etc/salt/master
vi /etc/salt/master
*** user: xxx
*** file_roots:
   base:
     - /xxx/yyy/zzz

* change folder permission
chown -R user /etc/salt /var/cache/salt /var/log/salt /var/run/salt
service salt-master restart


* Keys
```sh
salt-key -L
salt-key -a xxx 
salt-key -A #(for all)
```

* Activate netapi moduel(Salt-Api)
		Since the Salt-Api project has been merged into SaltStack in release 2014.7.0, so you can use the salt-api with SaltStack 2014.7.0 release
		no need to install another salt-api 
		just do below
## Create salt-api bin cmd
```sh
root@acebuild-sfo:/usr/lib/python2.7/dist-packages/salt# vi /usr/bin/salt-api
```
```python
#!/usr/bin/python

# Import salt libs
from salt.scripts import salt_api


if __name__ == '__main__':
    salt_api()
```
```sh
root@acebuild-sfo:/usr/lib/python2.7/dist-packages/salt# ll /usr/bin/salt-api
-rwxr-xr-x 1 root root 116 May 11 08:59 /usr/bin/salt-api*
```

## Mysql databases setup
```sql
CREATE DATABASE `saltstack` CHARACTER SET utf8 COLLATE utf8_general_ci;
GRANT ALL ON `saltstack`.* TO `xxx`@localhost IDENTIFIED BY 'xxx';
FLUSH PRIVILEGES;

REVOKE ALL ON `saltstack`.* FROM xxx@localhost;
FLUSH PRIVILEGES;
drop user xxx@localhost;
```
```sql
# login mysql as the user above for saltstack
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(25) DEFAULT NULL,
  `password` varchar(70) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

INSERT INTO users VALUES (NULL, 'yyy', SHA2('yyy', 256));
```

## Section `external_auth` in master config file with mysql (pam is sth that I'm not familiar with...)
### `/etc/salt/master.d/eauth.conf`
```yaml
mysql_auth:
  hostname: localhost
  database: saltstack
  username: xxx
  password: xxx
  auth_sql: 'SELECT username FROM users WHERE username = "{0}" AND password = SHA2("{1}", 256)'


external_auth:
  mysql:
    xxx:
      - .*
      - '@runner'
      - '@wheel'
```

## Install MySQLdb-python in the venv for salt-api(since salt-api merge into salt-master, they share the same venv)
```sh
pyenv shell system # this maybe the most suitable case...
pip install MySQLdb-python
# or 
sudo apt-get install python-mysqldb
```

## Install Cherrypy in the venv for salt-api(since salt-api merge into salt-master, they share the same venv)
```sh
pyenv shell system # this maybe the most suitable case...
pip install cherrypy
# or
git clone https://github.com/cherrypy/cherrypy.git
cd cherrypy
pyenv shell system # this maybe the most suitable case...
python setup.py install
```

## Master config for rest_cherry to run local only
### `/etc/salt/master.d/api.conf`
```yaml
rest_cherrypy:
  port: 8000
  host: 127.0.0.1
  disable_ssl: true
```

### nginx conf proxy for this rest_cherrypy
```sh
upstream saltapi {
  server localhost:8000;
}

server {
  listen 80;
  server_name salt-api.madeinace.com;
  return 301 https://salt-api.madeinace.com$request_uri;
}

server {
  listen 443 ssl;         # e.g., listen 192.168.1.1:80; In most cases *:80 is a good idea
  server_name salt-api.madeinace.com;     # e.g., server_name source.example.com;

  server_tokens off;     # don't show the version number, a security best practice
  ssl_certificate /etc/pki/tls/certs/localhost.crt;
  ssl_certificate_key /etc/pki/tls/certs/localhost.key;
  client_max_body_size 5m;

  access_log  /var/log/nginx/saltapi_access.log;
  error_log   /var/log/nginx/saltapi_error.log;

  location / {
    proxy_pass http://saltapi;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
  }
}
```

### Start salt-api deamon
salt-api -d --pid-file /var/run/salt-api.pid --log-file /var/log/salt/api

### Test
curl -k https://salt-api.madeinace.com/login \
        -H "Accept: application/x-yaml" \
        -d username='xxx' \
        -d password='xxx' \
        -d eauth='mysql'

curl -sSk https://salt-api.madeinace.com/login -H 'Accept: application/x-yaml' -d username=salt -d password=salt -d eauth=mysql