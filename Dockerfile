FROM ubuntu:latest AS builder

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ARG LEAN_TOOLCHAIN=stable
ENV ELAN_HOME=/tmp/elan
WORKDIR /tmp
RUN --mount=type=tmpfs,target=/tmp \
    curl -sSfL https://github.com/leanprover/elan/raw/master/elan-init.sh -o elan-init.sh && \
    chmod +x elan-init.sh && \
    ./elan-init.sh -v -y --no-modify-path --default-toolchain ${LEAN_TOOLCHAIN} && \
    mv -v /tmp/elan/toolchains/$(echo ${LEAN_TOOLCHAIN} | sed -e 's/\//--/g' -e 's/:/---/g') /opt/lean

FROM ubuntu:latest AS runner

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates git tini gosu && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/lean /opt/lean
ENV PATH=/opt/lean/bin:$PATH

ENV UID=1000 \
    GID=1000 \
    USER=lean \
    GROUP=lean

COPY ./entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]