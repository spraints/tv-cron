#!/bin/bash

set -eu

ok=true
if [ -z "${FRAME_TV_ADDR}" ]; then
  ok=false
  echo error: FRAME_TV_ADDR must be set in environment.
fi
if ! $ok; then
  exit 1
fi

(
  printf 'PATH=/usr/bin:/bin\n'
  printf '%s %s /opt/with-venv /opt/bin/sync-artwork.rb > /var/data/sync-artwork.log 2>&1' \
    "${CRON_SCHEDULE:-0 10 * * *}" "${CRON_USER:-root}"
  echo
) > /etc/cron.d/frame-art

set -x
touch /var/log/cron.log
cron && tail -f /var/log/cron.log
