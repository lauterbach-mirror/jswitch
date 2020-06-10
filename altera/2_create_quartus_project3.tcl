# The MIT License

# Copyright (c) 2018 Lauterbach GmbH, Ingo Rohloff

# Permission is hereby granted, free of charge,
# to any person obtaining a copy of this software and
# associated documentation files (the "Software"), to
# deal in the Software without restriction, including
# without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom
# the Software is furnished to do so,
# subject to the following conditions:

# The above copyright notice and this permission notice
# shall be included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
# ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

global env

package require ::quartus::project

set quartus_prj [ lindex $argv 0]
set filelist    [ lindex $argv 1]
set fsettings   [ lindex $argv 2]

set prjpre ""
if { ${fsettings}=="" } {
	set fsettings "../1_settings.tcl"
} else {
	set prjpre "${fsettings}_"
	set fsettings "../1_settings_${fsettings}.tcl"
}
puts "Found fsettings ${fsettings}"
set fp [open ${filelist} r]

set versp1 ""
set versp2 ""
regexp {[^0-9]*([0-9]+)\.([0-9]+)[^S]+(Service[^0-9]+([0-9]+))?} $::quartus(version) verfull ver1 ver2 versp1 versp2

if { ${versp1}=="" } {
	set prjdir "${prjpre}${ver1}_${ver2}"
} else {
	set prjdir "${prjpre}${ver1}_${ver2}_sp${versp2}"
}
puts "prjdir ${prjdir}"
if { ! [ file exists ${prjdir} ] } {
	file mkdir ${prjdir}
}

if { ! [ file exists ${prjdir} ] } {
	puts "could not create directory ${prjdir}"
} else {
	puts "directory ${prjdir} created"
}


cd ${prjdir}

if {[project_exists ${quartus_prj}]} {
	project_open -revision ${quartus_prj} ${quartus_prj}
	remove_all_global_assignments -name AHDL_FILE
	remove_all_global_assignments -name VHDL_FILE
} else {
	project_new -revision ${quartus_prj} ${quartus_prj}
	source ${fsettings}
	file mkdir vhdl
}

if {[file exists ../1_timing.sdc]} {
	file copy -force ../1_timing.sdc ${quartus_prj}.sdc
	set_global_assignment -name SDC_FILE ${quartus_prj}.sdc
}

while {-1 != [gets $fp line]} {
	set line     [ string trim $line ]
	set fileopt  [ string index $line 0 ]
	set filepath [ string range $line 2 end ]
	set filebname [ file tail ${filepath} ]
	set fileroot [ file rootname ${filebname} ]
	set fileext   [ file extension ${filebname} ]

	if { (${fileopt}=="H") } {
		if { ${fileext}==".vhd" } {
			puts "Adding vhdl/${filebname}"
			set_global_assignment -name VHDL_FILE vhdl/${filebname}
			file copy -force ../${filepath} vhdl/
		}
	} else {
		puts "skipping $filepath"
	}
}
close $fp

# copy TimeQuest report scripts
foreach f [glob -nocomplain ../report*.tcl] {
	puts "copying ${f}"
	file copy -force $f ./
}

export_assignments
project_close
