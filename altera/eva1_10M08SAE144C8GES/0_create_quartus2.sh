#!/bin/bash

if [ -e ../quartus_env.sh ]; then
	. ../quartus_env.sh
	export QUARTUS_ROOTDIR
fi

${QUARTUS_ROOTDIR}/bin/quartus_sh -t ../2_create_quartus_project3.tcl maxten files.txt

