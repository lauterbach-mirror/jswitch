#!/bin/bash

MYDIR=$(dirname $(readlink -e $0))
PRJDIR="${MYDIR}/prj_switch"

if [ -e ../diamond_env.sh ]; then
	. ../diamond_env.sh
	export PATH
fi

rm -rf ${PRJDIR}
mkdir ${PRJDIR}
cd ${PRJDIR}

cp ../jswitch.lpf .
cp ../jswitch.ldc .

echo "set myprjdir ${PRJDIR}" > start.tcl
echo "source ../2_prj_setup.tcl" >> start.tcl
echo "source ../3_compile.tcl" >> start.tcl

setsid diamond -t ${PRJDIR}/start.tcl 2>/dev/null 1>/dev/null &
