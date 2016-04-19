#!/bin/sh
#
#
# Copyright (c) 2004 by SICO software
#
#
#
# Copyright Modificacion: SICO software 2004
#
#

# Comprobamos los parametros de router ...
id=`/usr/bin/ps -efa | grep /home/metro/sun/router | grep -v grep | awk '{ if ($3 == "1") printf $2" "}'`

if test -n "$id"
then
   echo "router esta rodando sin padre, hay que detenerlo ... "
   kill -15 $id
   echo "detencion 3 sg para esperar a que termine router ..."
   sleep 3
fi

