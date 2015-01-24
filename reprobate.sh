#!/bin/bash

function start() {
    nohup java -cp $(echo *.jar | tr ' ' ':') server.WebServer > app.log 2>&1 &
}

function stop() {
    PID=`currentpid`
    echo "### Killing PID ${PID}...."
    kill $PID
}

function status() {
    PID=`currentpid`
    if [[ -n $PID ]]; then
        echo "### Reprobate is running..."
    else
        echo "### Reprobate is NOT running..."
    fi
}


function currentpid() {
    ps -ef | awk '/[w]ebserver/{print $2}'
}

case "$1" in
    'start')
    echo "Starting Reprobate"
    start
;;
    'stop')
    echo "Stopping Reprobate"
    stop
;;
    'status')
    status
;;
esac

