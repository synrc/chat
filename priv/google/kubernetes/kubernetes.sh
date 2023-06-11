#!/bin/sh

## Shell setting
#if [ ! -z "$DEBUG" ]; then
#    set -ex
#fi

## Local IP address setting

LOCAL_IP=$(hostname -i |grep -E -oh '((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])'|head -n 1)

##

export ERL_CLUSTER_COOKIE=emq_dist_cookie
export ERL_NODE_NAME=mq@127.0.0.1
envsubst < vm.args.dist > vm.args
envsubst < etc/emq.conf.dist > etc/emq.conf
#envsubst < etc/acl.conf.dist > etc/acl.conf

sleep 3

## Nynja Base settings and plugins setting
# Base settings in ~server/etc/emq.conf
# Plugin settings in ~server/etc/plugins

_EMQ_HOME="/home/nynja/server"

if [ -z "$PLATFORM_ETC_DIR" ]; then
    export PLATFORM_ETC_DIR="$_EMQ_HOME/etc"
fi

if [ -z "$PLATFORM_LOG_DIR" ]; then
    export PLATFORM_LOG_DIR="$_EMQ_HOME/log"
fi

#if [ -z "$EMQ_NAME" ]; then
#    export EMQ_NAME="$(hostname)"
#fi

#if [ -z "$EMQ_HOST" ]; then
#    export EMQ_HOST="$LOCAL_IP"
#fi

if [ -z "$EMQ_WAIT_TIME" ]; then
    export EMQ_WAIT_TIME=600
fi

#if [ -z "$EMQ_NODE_NAME" ]; then
#    export EMQ_NODE_NAME="$EMQ_NAME@$EMQ_HOST"
#fi

make start &
#tail -f /home/nynja/server/log/erlang.log.1 &

# Sleep 5 seconds to wait for the loaded plugins catch up.
sleep 20

echo "['$(date -u +"%Y-%m-%dT%H:%M:%SZ")']: nynja start"

# Wait and ensure emqttd status is running
WAIT_TIME=0
while [ -z "$($_EMQ_HOME/bin/emqttd_ctl status |grep 'is running'|awk '{print $1}')" ]
do
    sleep 1
    echo "['$(date -u +"%Y-%m-%dT%H:%M:%SZ")']:waiting emqttd"
    WAIT_TIME=$((WAIT_TIME+1))
    if [ $WAIT_TIME -gt $EMQ_WAIT_TIME ]; then
        echo "['$(date -u +"%Y-%m-%dT%H:%M:%SZ")']:timeout error"
        exit 1
    fi
done

# Sleep 5 seconds to wait for the loaded plugins catch up.
sleep 5

echo "['$(date -u +"%Y-%m-%dT%H:%M:%SZ")']:emqttd start"

# Run cluster script

#if [ -x "./cluster.sh" ]; then
#    ./cluster.sh &
#fi

# Join an exist cluster

if [ ! -z "$EMQ_JOIN_CLUSTER" ]; then
    echo "['$(date -u +"%Y-%m-%dT%H:%M:%SZ")']:emqttd try join $EMQ_JOIN_CLUSTER"
    bin/emqttd_ctl cluster join $EMQ_JOIN_CLUSTER &
fi

# Change admin password

#if [ ! -z "$EMQ_ADMIN_PASSWORD" ]; then
#    echo "['$(date -u +"%Y-%m-%dT%H:%M:%SZ")']:admin password changed to $EMQ_ADMIN_PASSWORD"
#    /home/nynja/server/bin/emqttd_ctl admins passwd admin $EMQ_ADMIN_PASSWORD &
#fi

# monitor emqttd is running, or the docker must stop to let docker PaaS know
# warning: never use infinite loops such as `` while true; do sleep 1000; done`` here
#          you must let user know emqtt crashed and stop this container,
#          and docker dispatching system can known and restart this container.
IDLE_TIME=0
while [ $IDLE_TIME -lt 5 ]
do
    IDLE_TIME=$((IDLE_TIME+1))
    if [ ! -z "$($_EMQ_HOME/bin/emqttd_ctl status |grep 'is running'|awk '{print $1}')" ]; then
        IDLE_TIME=0
    else
        echo "['$(date -u +"%Y-%m-%dT%H:%M:%SZ")']:emqttd not running, waiting for recovery in $((25-IDLE_TIME*5)) seconds"
    fi
    sleep 5
done

# If running to here (the result 5 times not is running, thus in 25s emq is not running), exit docker image
# Then the high level PaaS, e.g. docker swarm mode, will know and alert, rebanlance this service

# tail $(ls /opt/emqttd/log/*)

escript bin/nodetool -name mq@127.0.0.1 -setcookie $CLUSTER_COOKIE "test"

echo "['$(date -u +"%Y-%m-%dT%H:%M:%SZ")']:emqttd exit abnormally"
exit 1

