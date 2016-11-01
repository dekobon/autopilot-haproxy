#!/usr/bin/env bash

SERVICE_NAME=${SERVICE_NAME:-haproxy}
CONSUL=${CONSUL:-consul}
CERT_DIR="/var/www/ssl"

# Render Nginx configuration template using values from Consul,
# but do not reload because HAProxy has't started yet
preStart() {
    removeCruft
    writeConfiguration
}

# Render HAProxy configuration template using values from Consul,
# then gracefully reload HAProxy
onChange() {
#    local SSL_READY="false"
#    if [ -f ${CERT_DIR}/fullchain.pem -a -f ${CERT_DIR}/privkey.pem ]; then
#        SSL_READY="true"
#    fi
#    export SSL_READY

    writeConfiguration
    kill -s SIGHUP $(pgrep -f '^/usr/local/sbin/haproxy-systemd-wrapper')
}

writeConfiguration() {
    echo "Writing HAProxy to /tmp/haproxy.cfg"

    consul-template \
        -once \
        -dedup \
        -consul ${CONSUL}:8500 \
        -template "/usr/local/etc/haproxy/haproxy.cfg.ctmpl:/usr/local/etc/haproxy/haproxy.cfg"
}

removeCruft() {
    if [ -f /run/haproxy.pid ]; then
        echo "Removing PID file left over after container shutdown"
        rm -f /run/haproxy.pid
    fi
}

help() {
    echo "Usage: ./reload.sh preStart  => first-run configuration for HAProxy"
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
