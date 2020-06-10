#!/bin/bash

MYDIR=$(dirname $(readlink -e $0))
PRJDIR="${MYDIR}/prj_switch"

if [ -e ../diamond_env.sh ]; then
	. ../diamond_env.sh
	export PATH
fi

ddtcmd -oft -stpsingle -if ${PRJDIR}/impl/jswitch_Implementation0.bit -dev LCMXO2280C -op "Multiple Operations File" -of ${PRJDIR}/jswitch_Implementation0.stp
cp ${PRJDIR}/jswitch_Implementation0.stp ${MYDIR}/jswitch_machxo2280.jam
