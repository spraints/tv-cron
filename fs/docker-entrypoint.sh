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

set -x
touch /var/log/cron.log
cron && tail /var/log/cron.log
