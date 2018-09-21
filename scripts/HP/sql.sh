#!/usr/bin/sh

echo; echo "WHERE"
sort < $1 | uniq | sed "s/^/hostname LIKE \'%/;s/$/%\' OR/"
