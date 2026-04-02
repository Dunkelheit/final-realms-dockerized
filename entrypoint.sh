#!/bin/sh
set -e

# Start the hostname-resolution helper if it was compiled.
# The mud works without it; hostnames just won't resolve.
if [ -x /mud/fr/bin/addr_server ]; then
    echo "[entrypoint] Starting addr_server on port 8099..."
    /mud/fr/bin/addr_server 8099 &
    sleep 1
fi

echo "[entrypoint] Starting Final Realms MUD on port 4001..."
echo "[entrypoint] Connect with: telnet localhost 4001  (login: god / god)"

# Run the driver in the foreground so Docker can manage the process
exec /mud/fr/bin/driver /mud/fr/bin/mudos.cfg
