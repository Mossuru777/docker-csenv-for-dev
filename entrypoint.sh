#!/bin/bash
set -e

# Add hostname of Gateway(Host) to resolve its IP address
grep -v 'host.docker.internal' /etc/hosts | sudo tee /etc/hosts > /dev/null \
&& echo -e "$(/sbin/ip -4 route list match 0/0 | /usr/bin/awk "{ print \$3 }")\thost.docker.internal" | sudo tee -a /etc/hosts > /dev/null

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
