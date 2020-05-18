#!/usr/bin/bash
PSQL='/home/if/work/postgreses/EE12/bin/psql --set ON_ERROR_STOP=1 -1 -X -p 15432 work'
[[ ! "$SCHEMA" ]] && DEFINE="$DEFINE -DBCW=gsp" || DEFINE="$DEFINE -DGSP=$SCHEMA"
/usr/bin/cpp $DEFINE < $1 | sed '/^#/d' | $PSQL && touch `basename $1 .sql`.mark
