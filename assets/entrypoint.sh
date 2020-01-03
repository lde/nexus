#!/bin/sh
echo "github.org=${GH_ORG}" >> /opt/nexus/etc/githuboauth.properties
exec "$@"
