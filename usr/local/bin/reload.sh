#!/usr/bin/env bash

SERVICE_NAME=${SERVICE_NAME:-haproxy}
CONSUL=${CONSUL:-consul}
CERT_DIR="/var/www/ssl"

# Render Nginx configuration template using values from Consul,
# but do not reload because HAProxy has't started yet
preStart() {
    removeCruft
    writeConfiguration
    checkAndMoveConfiguration
}

preStop() {
    if [ -f /run/haproxy.pid ]; then
        ST_PIDS="-sf $(cat /run/haproxy.pid)"
    else
        ST_PIDS=""
    fi

    nl-qdisc-add --dev=lo --parent=1:4 --id=40: --update plug--release-indefinite &> /dev/null
}

# Render HAProxy configuration template using values from Consul,
# then gracefully reload HAProxy
onChange() {
#    local SSL_READY="false"
#    if [ -f ${CERT_DIR}/fullchain.pem -a -f ${CERT_DIR}/privkey.pem ]; then
#        SSL_READY="true"
#    fi
#    export SSL_READY

    if [ -f /run/haproxy.pid ]; then
        writeConfiguration
        checkAndMoveConfiguration

        nl-qdisc-add --dev=lo --parent=1:4 --id=40: --update plug --buffer &> /dev/null
        echo "Reloading HAProxy configuration"

        /usr/local/sbin/haproxy \
            -D \
            -p /run/haproxy.pid \
            -f /usr/local/etc/haproxy/haproxy.cfg \
            -sf $(cat /run/haproxy.pid)

        nl-qdisc-add --dev=lo --parent=1:4 --id=40: --update plug--release-indefinite &> /dev/null
    fi
}

writeConfiguration() {
    echo "Writing HAProxy to /tmp/haproxy.cfg"

    consul-template \
        -once \
        -dedup \
        -consul ${CONSUL}:8500 \
        -template "/usr/local/etc/haproxy/haproxy.cfg.ctmpl:/tmp/haproxy.cfg"
}

checkAndMoveConfiguration() {
    if [[ "$(/usr/local/sbin/haproxy -c -f /tmp/haproxy.cfg)" ]]; then
        echo "HAProxy configuration is valid - moving to /usr/local/etc/haproxy/haproxy.cfg"
        mv /tmp/haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
    else
        >&2 echo "HAProxy configuration is invalid"
        return 1
    fi
}

removeCruft() {
    if [ -f /run/haproxy.pid ]; then
        echo "Removing PID file left over after container shutdown"
        rm -f /run/haproxy.pid
    fi
}

help() {
    echo "Usage: ./reload.sh preStart  => first-run configuration for HAProxy"
    echo "       ./reload.sh preStop   => runs pre-stop operations for HAProxy"
    echo "       ./reload.sh onChange  => [default] update HAProxy config on upstream changes"
}

until
    cmd=$1
    if [ -z "$cmd" ]; then
        onChange
    fi
    shift 1
    $cmd "$@"
    [ "$?" -ne 127 ]
do
    onChange
    exit
done
