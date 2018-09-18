FROM alpine:3.8

MAINTAINER Jean-Charles Sisk <jeancharles@gasbuddy.com>

ARG GLIBC_VERSION=2.27-r0
ARG CONCOURSE_VERSION=4.0.0

RUN mkdir -p /opt/concourse && \
    addgroup -S concourse && \
    adduser -SDh /opt/concourse -s /sbin/nologin -G concourse concourse

RUN apk --no-cache add su-exec openssl dumb-init openssh-keygen findutils bash

RUN TMPFILE=$(mktemp).apk KEYPATH=/etc/apk/keys/ PUBKEY=sgerrand.rsa.pub && \
    wget -P "${KEYPATH}" "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/${PUBKEY}" && \
    wget -O "${TMPFILE}" "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk" && \
    apk --no-cache add "${TMPFILE}" && \
    rm -rf "${TMPFILE}" "${KEYPATH}${PUBKEY}"

RUN apk --no-cache add dpkg && ARCH=$(dpkg --print-architecture | awk -F- '{ print $NF }') && apk del dpkg && \
    wget -O /usr/local/bin/concourse "https://github.com/concourse/concourse/releases/download/v${CONCOURSE_VERSION}/concourse_linux_${ARCH}" && \
    chown root:concourse /usr/local/bin/concourse && \
    chmod 1750 /usr/local/bin/concourse 

COPY entry.sh /entry.sh
RUN chmod 700 /entry.sh

VOLUME ["/opt/concourse"]
ENTRYPOINT ["/usr/bin/dumb-init", "--", "/entry.sh"]

WORKDIR /opt/concourse

CMD ["concourse"]
