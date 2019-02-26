#!/bin/sh

# Make sure the directory for individual app logs exists
mkdir -p /var/log/shiny-server
chown shiny.shiny /var/log/shiny-server

# Swap in environment variable for app root.
cat /etc/shiny-server/shiny-server-template.conf | sed 's@${APP_ROOT}@'$APP_ROOT'@' > /etc/shiny-server/shiny-server.conf

exec shiny-server