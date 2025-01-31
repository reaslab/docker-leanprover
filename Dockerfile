FROM ubuntu:latest AS base
ENV DEBIAN_FRONTEND=noninteractive
RUN userdel -r ubuntu && \
    groupadd -g 1000 lean && \
    useradd -m -u 1000 -g lean lean

WORKDIR /src
ADD https://deb.nodesource.com/setup_lts.x /src/setup_nodesource.sh
RUN --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean && \
    bash ./setup_nodesource.sh && \
    apt-get install -y --no-install-recommends ca-certificates curl git tini gosu zstd nodejs

ARG LEAN_TOOLCHAIN=stable
COPY /releases.mjs /src/releases.mjs
RUN --mount=type=tmpfs,target=/tmp \
    node /src/releases.mjs download ${LEAN_TOOLCHAIN} && \
    tar -xvf ./lean-*.tar.* -C /opt && \
    mv /opt/lean-* /opt/lean && \
    rm -rf /src

ENV PATH=/opt/lean/bin:$PATH
ENV UID=1000 USER=lean \
    GID=1000 GROUP=lean \
    XDG_CACHE_HOME=/var/cache/lean
COPY ./entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]