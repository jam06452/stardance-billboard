#!/bin/sh
set -e

/app/bin/xinfeng eval "Xinfeng.Release.migrate()"

exec "$@"
