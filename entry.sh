#!/bin/ash

if [ "$1" = 'concourse' ]; then
  shift
  exec /sbin/su-exec concourse:concourse /usr/local/bin/concourse "$@"
fi

exec "$@"
