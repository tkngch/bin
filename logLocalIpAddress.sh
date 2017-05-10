#!/usr/bin/env sh

logFile=$HOME/sync/ipAddress.$(hostname)

logIP () {
    ipaddress=`ip addr show | grep "enp0s25" -A2 | sed -n 3p | awk '{print $2}' | cut -f1  -d'/'`
    datetime=`date +'%Y-%m-%d %H:%M'`

    echo "${datetime},${ipaddress}"
    echo "${datetime},${ipaddress}" >> ${logFile}
    sleep `awk 'BEGIN {print 60 * 60 * 4}'`
    logIP
}

logIP
