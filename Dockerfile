FROM caddy:latest

# See https://caddyserver.com/docs/conventions#file-locations for details
ENV XDG_CONFIG_HOME /config
ENV XDG_DATA_HOME /data
ENV TZ Asia/Shanghai
ADD https://cdn.hyh.ink/ao3/dockerao3/ao3.caddyfile /etc/caddy/Caddyfile
ADD https://cdn.hyh.ink/ao3/disclaimer.html /usr/share/caddy/disclaimer.html
ADD https://cdn.hyh.ink/ao3/offline.html /usr/share/caddy/offline.html
ADD https://cdn.hyh.ink/ao3/sw.js /usr/share/caddy/sw.js
ADD https://cdn.hyh.ink/ao3/dockerao3/2890.pem /etc/caddy/2890.pem
ADD https://cdn.hyh.ink/ao3/dockerao3/2890.key /etc/caddy/2890.key

# set up nsswitch.conf for Go's "netgo" implementation
# - https://github.com/golang/go/blob/go1.9.1/src/net/conf.go#L194-L275
# - docker run --rm debian:stretch grep '^hosts:' /etc/nsswitch.conf
RUN [ ! -e /etc/nsswitch.conf ] && echo 'hosts: files dns' > /etc/nsswitch.conf

RUN set -e \
    && apk upgrade \
    && apk add bash tzdata mailcap \
    && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone

VOLUME /config
VOLUME /data

EXPOSE 80
EXPOSE 443
EXPOSE 2019
EXPOSE 22

WORKDIR /srv

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
