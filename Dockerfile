# Stage 1: build the FluffOS driver

# debian:buster (GCC 8) is used intentionally: the driver is mid-2000s C code
# that triggers hard errors on newer GCC versions.
# Buster is EOL so we redirect apt to the archive mirror before installing.
FROM debian:buster-slim AS builder

RUN echo "deb http://archive.debian.org/debian buster main" > /etc/apt/sources.list \
 && echo "deb http://archive.debian.org/debian-security buster/updates main" >> /etc/apt/sources.list \
 && apt-get -o Acquire::Check-Valid-Until=false update \
 && apt-get install -y --no-install-recommends \
        git ca-certificates \
        gcc make \
        bison byacc flex \
        libpcre3-dev zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --depth 1 https://github.com/MudRen/FinalRealms.git .

WORKDIR /src/fluffos-2.9-ds2.11
# -fgnu89-inline: the driver uses GNU C89-style `inline` semantics where a
# definition in a .c file also emits an external symbol.  GCC 8+ defaults to
# C99 semantics where inline definitions never produce external symbols, which
# causes every other translation unit to get "undefined reference" errors for
# core runtime functions declared INLINE in interpret.h.
RUN chmod +x configure build.MudOS && \
    ./configure fr && \
    sed -i '/^CFLAGS/s/$/ -fgnu89-inline/' GNUmakefile && \
    make && make install && \
    (make addr_server && cp addr_server ../bin/ 2>/dev/null || true)

# Stage 2: minimal runtime image
FROM debian:buster-slim

RUN echo "deb http://archive.debian.org/debian buster main" > /etc/apt/sources.list \
 && echo "deb http://archive.debian.org/debian-security buster/updates main" >> /etc/apt/sources.list \
 && apt-get -o Acquire::Check-Valid-Until=false update \
 && apt-get install -y --no-install-recommends \
        libpcre3 zlib1g \
 && rm -rf /var/lib/apt/lists/*

# Directory layout expected by mudos.cfg:
RUN mkdir -p /mud/fr/bin /mud/fr/lib
COPY --from=builder /src/bin/ /mud/fr/bin/
COPY --from=builder /src/lib/ /mud/fr/lib/

# These directories are needed by the driver on runtime
RUN mkdir -p \
        /mud/fr/lib/log \
        /mud/fr/lib/tmp \
        /mud/fr/lib/players \
        /mud/fr/lib/secure/save/binaries \
    && chmod +x /mud/fr/bin/driver

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh


EXPOSE 4001

WORKDIR /mud/fr/bin
ENTRYPOINT ["/entrypoint.sh"]
