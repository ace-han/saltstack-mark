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