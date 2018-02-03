# ReadCSV.tcl --
# Create by HXM
# Function: Read CSV file into program
catch {namespace delete ::ReadCSV}
namespace eval ::ReadCSV {
	namespace export toArray toList
}

# ::ReadCSV::ReadFile
# Open file and read into variable
# Split by "\n"
# arguments:
#	f_in: path of .csv file
# output:
# data in "line"
proc ::ReadCSV::ReadFile {f_in} {
	set file_in [open $f_in r];
	set temp [read $file_in];
	close $file_in
	set temp [split $temp "\n"];
	return $temp
}

# ::ReadCSV::CheckStartLine
# check if start line input exceeds the limit
# arguments:
#	mydata: Readed .csv
#	start_line：the line to start read,1 means first line
# output:
# 	1  error
#   0  ok
proc ::ReadCSV::CheckStartLine {mydata start_line} {
	upvar $mydata data
	set num [llength $data]
	if {$num>=$start_line} {
		return -code ok
	} else {
		return -code error "Error: Reading from Line $start_line in a $num Line file"
	}
}

# ::ReadCSV::CreateArrayName
# 	create array name
# arguments:
#	line: one line in data
#	name_index: the index of elems used as array name, 
#				1 is first elem, 2 is first two elem seperated by ","
# output:
# 	array_name
proc ::ReadCSV::CreateArrayName {line name_index} {
	set tmp [split $line ","]
	set tmp_name [lrange $tmp 0 [expr $name_index-1]]
	set array_name [lindex $tmp_name 0];
	for {set ii 1} {$ii<$name_index} {incr ii} {
		append array_name "," [lindex $tmp_name $ii]
	}
	return $array_name
}

#::ReadCSV::CreateArrayValue
# create array vlaue
# arguments:
# 	line: one line in data
#	name_index: the index of elems used as array name, 
#				 first elem is 1, first two elem is 2 and seperated by ","
#               use 0 to get all values
# output:
# 	array_value
proc ::ReadCSV::CreateArrayValue {line name_index} {
	set tmp [split $line ","]
	set array_value [lrange $tmp $name_index end]
	return $array_value
}
# ::ReadCSV::CheckElemNum
#  check element number in 
# arguments:
#	line: one line in data
#   elem_num: "should be" numbers of elemens
# output:
# 	0: True
#   1: False
proc ::ReadCSV::CheckElemNum {line elem_num} {
	set num [regexp -all \, $line]
	if {$num!=[expr $elem_num-1]} {
		return 1
	} else {
		return 0
	}
}

# ::ReadCSV::toArray
# Read csv to Array
# arguments:
#	
# output:
# 	Modified Array Variable
proc ::ReadCSV::toArray {myArray f_in start_line elem_num name_index} {
	upvar $myArray tmp_array
	set data [::ReadCSV::ReadFile $f_in]
	::ReadCSV::CheckStartLine data $start_line
	
	set count [llength $data]
	for {set i [expr $start_line-1]} {$i<$count} {incr i} {
		set line [lindex $data $i]
		set flag [::ReadCSV::CheckElemNum $line $elem_num]
		switch -exact $flag {
			1 {
				puts "Number of element in Line [expr $i+1] is not $elem_num,Skipped"
			}
			0 {
				set name [::ReadCSV::CreateArrayName $line $name_index]
				set value [::ReadCSV::CreateArrayValue $line $name_index]
				set tmp_array($name) $value
			}
		}
	}
}

# ::ReadCSV::toList
# Read csv to List
# arguments:
#	
# output:
# 	Modified Array Variable
proc ::ReadCSV::toList {myList f_in start_line elem_num} {
	upvar $myList tmp_list
	set data [::ReadCSV::ReadFile $f_in]
	::ReadCSV::CheckStartLine data $start_line
	
	set count [llength $data]
	for {set i [expr $start_line-1]} {$i<$count} {incr i} {
		set line [lindex $data $i]
		set flag [::ReadCSV::CheckElemNum $line $elem_num]
		switch -exact $flag {
			1 {
				puts "Number of element in Line [expr $i+1] is not $elem_num,Skipped"
			}
			0 {
				lappend tmp_list [::ReadCSV::CreateArrayValue $line 0]
			}
		}
	}
}


