FROM frolvlad/alpine-glibc

MAINTAINER Jean-Charles Sisk <jeancharles@gasbuddy.com>

RUN mkdir -p /opt/concourse && \
    addgroup -S concourse && \
    adduser -SDh /opt/concourse concourse -G concourse

RUN apk --no-cache add ca-certificates su-exec

RUN ARCH=$(ARCH=$(apk --print-arch); case $ARCH in x86_64)ARCH=amd64;; x86)ARCH=i386;; esac; echo $ARCH) && \
    wget -O /usr/local/bin/concourse "https://github.com/concourse/concourse/releases/download/v1.2.0/concourse_linux_${ARCH}" && \
    chown root:concourse /usr/local/bin/concourse && \
    chmod 1750 /usr/local/bin/concourse 

COPY entry.sh /entry.sh
RUN chmod 700 /entry.sh

VOLUME ["/opt/concourse"]
ENTRYPOINT ["/entry.sh"]

CMD ["concourse"]
