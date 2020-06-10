set ise_dir [ lindex $argv 0 ]

file mkdir ${ise_dir}

cd ${ise_dir}

set fp [open "../files.txt" r]

while {-1 != [gets $fp line]} {
	set fileopt  [ string index $line 0 ]
	set filepath [ string range $line 2 end ]
	if { (${fileopt}=="D") } {
		project new $filepath
		source "../${filepath}.tcl"
	} elseif { (${fileopt}=="X") || (${fileopt}=="B") } { 
		xfile add "../${filepath}"
	} elseif { (${fileopt}=="M") } {
		file copy -force "../${filepath}" ./
	} else {
		puts "skipping $filepath"
	}
}

project close

close $fp
