# A minimal HAProxy container including ContainerPilot and a simple virtualhost config
FROM haproxy:latest

RUN apt-get update && \
    apt-get install --no-install-recommends -qy netcat hatop curl unzip ca-certificates syslog-ng && \
    rm -rf /var/lib/apt/lists/*

# Install Consul
# Releases at https://releases.hashicorp.com/consul
RUN export CONSUL_VERSION=0.7.0 \
    && export CONSUL_CHECKSUM=b350591af10d7d23514ebaa0565638539900cdb3aaa048f077217c4c46653dd8 \
    && curl --retry 7 --fail -vo /tmp/consul.zip "https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip" \
    && echo "${CONSUL_CHECKSUM}  /tmp/consul.zip" | sha256sum -c \
    && unzip /tmp/consul -d /usr/local/bin \
    && rm /tmp/consul.zip \
    && mkdir /config

# Create empty directories for Consul config and data
RUN mkdir -p /etc/consul \
    && mkdir -p /var/lib/consul

# Install Consul template
# Releases at https://releases.hashicorp.com/consul-template/
RUN export CONSUL_TEMPLATE_VERSION=0.14.0 \
    && export CONSUL_TEMPLATE_CHECKSUM=7c70ea5f230a70c809333e75fdcff2f6f1e838f29cfb872e1420a63cdf7f3a78 \
    && curl --retry 7 --fail -Lso /tmp/consul-template.zip "https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip" \
    && echo "${CONSUL_TEMPLATE_CHECKSUM}  /tmp/consul-template.zip" | sha256sum -c \
    && unzip /tmp/consul-template.zip -d /usr/local/bin \
    && rm /tmp/consul-template.zip

# Add Containerpilot and set its configuration
ENV CONTAINERPILOT_VER 2.4.4
ENV CONTAINERPILOT file:///etc/containerpilot.json

RUN export CONTAINERPILOT_CHECKSUM=6194ee482dae95844046266dcec2150655ef80e9 \
    && curl -Lso /tmp/containerpilot.tar.gz \
         "https://github.com/joyent/containerpilot/releases/download/${CONTAINERPILOT_VER}/containerpilot-${CONTAINERPILOT_VER}.tar.gz" \
    && echo "${CONTAINERPILOT_CHECKSUM}  /tmp/containerpilot.tar.gz" | sha1sum -c \
    && tar zxf /tmp/containerpilot.tar.gz -C /usr/local/bin \
    && rm /tmp/containerpilot.tar.gz

# Add Dehydrated
RUN export DEHYDRATED_VERSION=v0.3.1 \
    && curl --retry 8 --fail -Lso /tmp/dehydrated.tar.gz "https://github.com/lukas2511/dehydrated/archive/${DEHYDRATED_VERSION}.tar.gz" \
    && tar xzf /tmp/dehydrated.tar.gz -C /tmp \
    && mv /tmp/dehydrated-0.3.1/dehydrated /usr/local/bin \
    && rm -rf /tmp/dehydrated-0.3.1

# Add jq
RUN export JQ_VERSION=1.5 \
    && curl --retry 8 --fail -Lso /usr/local/bin/jq "https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64" \
    && chmod a+x /usr/local/bin/jq

# Consul session data written here
RUN mkdir -p /var/consul

# Add user and group to run haproxy as
RUN groupadd -g 77 haproxy && \
    useradd -r -m -g 77 -u 77 haproxy && \
    groupadd -g 88 syslog && \
    useradd -r -m -g 88 -u 88 syslog && \
    chown -R syslog:syslog /var/lib/syslog-ng

COPY etc /etc/
COPY usr /usr/

# /usr/local/bin/containerpilot /usr/local/sbin/haproxy-systemd-wrapper -p /run/haproxy.pid -f /usr/local/etc/haproxy/haproxy.cfg
CMD [ "/usr/local/bin/containerpilot", \
      "/usr/local/sbin/haproxy-systemd-wrapper", \
      "-p", \
      "/run/haproxy.pid", \
      "-f", \
      "/usr/local/etc/haproxy/haproxy.cfg" ]
