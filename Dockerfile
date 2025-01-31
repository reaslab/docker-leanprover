FROM ubuntu:latest AS base
ENV DEBIAN_FRONTEND=noninteractive
RUN userdel -r ubuntu && \
    groupadd -g 1000 lean && \
    useradd -m -u 1000 -g lean lean
RUN --mount=type=cache,target=/var/cache \
    apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl git tini gosu zstd && \
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

ARG LEAN_TOOLCHAIN=stable
RUN --mount=type=bind,dst=/src,rw \
    node /src/releases.mjs download ${LEAN_TOOLCHAIN} /src && \
    tar -xvf /src/lean-* -C /opt && \
    mv /opt/lean-* /opt/lean

ENV PATH=/opt/lean/bin:$PATH
ENV UID=1000 USER=lean \
    GID=1000 GROUP=lean \
    XDG_CACHE_HOME=/var/cache/lean
COPY ./entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]