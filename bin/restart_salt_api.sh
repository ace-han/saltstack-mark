ps -ef | grep salt-api | awk '{print $2}' | xargs kill
salt-api -d --pid-file /var/run/salt-api.pid --log-file /var/log/salt/api