FROM debian:stable-slim

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y -q --no-install-recommends \
    gmt gmt-gshhg-low gmt-gshhg-high gmt-dcw ghostscript && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN gmt --version

WORKDIR /work
COPY build_map.sh .
RUN chmod +x build_map.sh

CMD ["/work/build_map.sh"]
