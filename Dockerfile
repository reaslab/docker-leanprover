FROM ubuntu:latest AS base
ENV DEBIAN_FRONTEND=noninteractive
RUN userdel -r ubuntu && \
    groupadd -g 1000 lean && \
    useradd -m -u 1000 -g lean lean
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl git tini gosu && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

FROM base AS builder
ARG LEAN_TOOLCHAIN=stable
ENV ELAN_HOME=/tmp/elan
WORKDIR /tmp
RUN --mount=type=tmpfs,target=/tmp \
    curl -sSfL https://github.com/leanprover/elan/raw/master/elan-init.sh -o elan-init.sh && \
    chmod +x elan-init.sh && \
    ./elan-init.sh -v -y --no-modify-path --default-toolchain ${LEAN_TOOLCHAIN} && \
    cp -rv /tmp/elan/toolchains/*/ /opt/lean

FROM base AS runner
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
COPY --from=builder /opt/lean /opt/lean
ENV PATH=/opt/lean/bin:$PATH
ENV UID=1000 USER=lean \
    GID=1000 GROUP=lean \
    XDG_CACHE_HOME=/var/cache/lean
COPY ./entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]