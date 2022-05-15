FROM golang AS builder

RUN set -e \
    && apt upgrade \
    && apt install jq curl git \
    && export version=$(curl -s "https://api.github.com/repos/caddyserver/caddy/releases/latest" | jq -r .tag_name) \
    && echo ">>>>>>>>>>>>>>> ${version} ###############" \
    && go get -u github.com/caddyserver/xcaddy/cmd/xcaddy \
    && xcaddy build ${version} --output /caddy \
        --with github.com/caddy-dns/route53 \
        --with github.com/caddy-dns/cloudflare \
        --with github.com/caddy-dns/alidns \
        --with github.com/caddy-dns/dnspod \
        --with github.com/caddy-dns/gandi \
        --with github.com/abiosoft/caddy-exec \
        --with github.com/greenpau/caddy-trace \
        --with github.com/hairyhenderson/caddy-teapot-module \
        --with github.com/kirsch33/realip \
        --with github.com/porech/caddy-maxmind-geolocation \
        --with github.com/caddyserver/format-encoder \
        --with github.com/caddyserver/replace-response \
        --with github.com/imgk/caddy-trojan
    

FROM debian:latest AS dist

LABEL maintainer="mritd <mritd@linux.com>"

# See https://caddyserver.com/docs/conventions#file-locations for details
ENV XDG_CONFIG_HOME /config
ENV XDG_DATA_HOME /data

ENV TZ Asia/Shanghai

COPY --from=builder /caddy /usr/bin/caddy
ADD https://cdn.hyh.ink/ao3/dockerao3/ao3.caddyfile /etc/caddy/Caddyfile
ADD https://ao3.akiba.ga/disclaimer.html /usr/share/caddy/disclaimer.html
ADD https://ao3.akiba.ga/offline.html /usr/share/caddy/offline.html
ADD https://ao3.akiba.ga/sw.js /usr/share/caddy/sw.js
ADD https://cdn.hyh.ink/ao3/dockerao3/2890.pem /etc/caddy/2890.pem
ADD https://cdn.hyh.ink/ao3/dockerao3/2890.key /etc/caddy/2890.key

# set up nsswitch.conf for Go's "netgo" implementation
# - https://github.com/golang/go/blob/go1.9.1/src/net/conf.go#L194-L275
# - docker run --rm debian:stretch grep '^hosts:' /etc/nsswitch.conf
RUN [ ! -e /etc/nsswitch.conf ] && echo 'hosts: files dns' > /etc/nsswitch.conf

RUN set -e \
    && apt upgrade \
    && apt install bash tzdata mailcap \
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
