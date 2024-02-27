#!/bin/bash
# Ensure log files exist
touch /var/log/auth.log
touch /var/log/apache2/access.log
touch /var/log/apache2/error.log
# Starting SSH service
service ssh start
# Tail Apache2 and Auth logs in the background
tail -F /var/log/apache2/* /var/log/auth.log &
# Run Apache2 in the foreground
apache2ctl -D FOREGROUND
