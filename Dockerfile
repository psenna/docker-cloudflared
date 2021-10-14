ARG ALPINE_VERSION=3.14
ARG CLOUDFLARED_RELEASE_TAG=2021.9.2
ARG ARCH=amd64

FROM alpine:${ALPINE_VERSION}

ARG CLOUDFLARED_RELEASE_TAG
ARG ALPINE_VERSION
ARG ARCH

LABEL maintainer="psenna"

ENV UPSTREAM1 https://1.1.1.1/dns-query
ENV UPSTREAM2 https://1.0.0.1/dns-query
ENV PORT 5054
ENV ADDRESS 0.0.0.0
ENV METRICS 127.0.0.1:8080
ENV MAX_UPSTREAM_CONNS 0

RUN adduser -S cloudflared; \
    apk add --no-cache ca-certificates bind-tools libcap tzdata; \
    rm -rf /var/cache/apk/*;

RUN wget https://github.com/cloudflare/cloudflared/releases/download/${CLOUDFLARED_RELEASE_TAG}/cloudflared-linux-${ARCH} -O /usr/local/bin/cloudflared \
    && chmod +x /usr/local/bin/cloudflared \
    && setcap CAP_NET_BIND_SERVICE+eip /usr/local/bin/cloudflared

HEALTHCHECK --interval=5s --timeout=3s --start-period=5s CMD nslookup -po=${PORT} cloudflare.com 127.0.0.1 || exit 1

USER cloudflared

CMD ["/bin/sh", "-c", "/usr/local/bin/cloudflared proxy-dns --address ${ADDRESS} --port ${PORT} --metrics ${METRICS} --upstream ${UPSTREAM1} --upstream ${UPSTREAM2} --max-upstream-conns ${MAX_UPSTREAM_CONNS}"]
