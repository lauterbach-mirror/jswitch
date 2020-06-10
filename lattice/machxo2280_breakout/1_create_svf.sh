#!/bin/bash

MYDIR=$(dirname $(readlink -e $0))
PRJDIR="${MYDIR}/prj_switch"

if [ -e ../diamond_env.sh ]; then
	. ../diamond_env.sh
	export PATH
fi

ddtcmd -oft -svfsingle -if ${PRJDIR}/impl/jswitch_Implementation0.bit -dev LCMXO2280C -op "FLASH Erase,Program,Verify" -of ${MYDIR}/jswitch_machxo2280.svf
