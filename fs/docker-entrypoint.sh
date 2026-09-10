#!/bin/bash

set -eu

ok=true
if [ -z "${FRAME_TV_ADDR}" ]; then
  ok=false
  echo error: FRAME_TV_ADDR must be set in environment.
fi
if [ -z "${FRAME_TV_MAC}" ]; then
  ok=false
  echo error: FRAME_TV_MAC must be set in environment.
fi
if ! $ok; then
  exit 1
fi

(
  printf 'PATH=/usr/bin:/bin\n'
  printf '%s /opt/with-venv /opt/bin/sync-artwork.rb' \
    "${CRON_SCHEDULE:-0 10 * * *}"
  echo
) > /etc/cron.d/frame-art

set -x
touch /var/log/cron.log
cron && tail -f /var/log/cron.log
