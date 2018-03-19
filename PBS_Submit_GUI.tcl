# File      : PBS_Submit_GUI.tcl
# Date      : 2018.2.1
# Created by: HXM
# Function  : 1.生成用户界面
#             2.提供界面按钮功能

#引用
package require Tk
package require http

set libDir [file join [file dir [info script]] "lib"]
catch {source "$libDir/ReadCSV.tcl"}
catch {source "$libDir/log.tcl"}
catch {source "$libDir/ftp.tcl"}

# 定义变量
catch {namespace delete ::PBSSubmit}
namespace eval ::PBSSubmit {
	#GUI Related Variables
	variable mainGUI;
	set mainGUI .mainGUI;
	
	variable txt; #txt文本框
	
	#PBS submit config,用于提交当前作业
	variable submit_config;
	
	#PBS submit config,用于提交当前作业
	variable conf;
	set conf [file join [file dir [info script]] "PBS_CONFIG/CONFIG.csv"]
}

# ::PBSSubmit::GetSolver
#	get hw profile
# arguments:
#	
# output:
#	solver type needed for PBS submit 
proc ::PBSSubmit::GetSolver {} {
	set curProfile [lindex [hm_framework getuserprofile] 0]
	switch -exact $curProfile {
		"OptiStruct" {
			return "Optistruct"
		}
		"Abaqus" {
			return "Abaqus-smp"
		}
		"LsDyna" {
			return "Dyna-mpp"
		}
		default {
			return -code error "Error: Solver Profile not found in config file"
		}
	}
}

# ::PBSSubmit::InitiaSubmitConfig
#	Initialize the submit Config
# arguments:
#	f_in: file path of config.csv
# output:
#	Initialized submit dict
proc ::PBSSubmit::InitiaSubmitConfig {f_in} {
	variable submit_config;
	
	::ReadCSV::toList tmplist $f_in 1 12
	set dict_name [lindex $tmplist 0]
	set solver_type [::PBSSubmit::GetSolver]
	set dict_value [lsearch -exact -index 1 -inline $tmplist $solver_type]
	set submit_config [dict create]
	foreach name $dict_name value $dict_value {
		dict set submit_config $name $value
	}
}

# ::PBSSubmit::ExportSolverDeck
#	Export solver deck and return file path
# arguments:
#	
# output:
#	return local file path of pbs submit
proc ::PBSSubmit::ExportSolverDeck {} {
	
	set alt_home [hm_info -appinfo ALTAIR_HOME]
	set curProfile [lindex [hm_framework getuserprofile] 0]
	set file [$::PBSSubmit::fileent get]
	if {$file!=""} {
		switch -exact $curProfile {
			"OptiStruct" {
				*createstringarray 2 "HM_NODEELEMS_SET_COMPRESS_SKIP " "HMBOMCOMMENTS_XML"
				*feoutputwithdata "$alt_home/templates/feoutput/optistruct/optistruct" "$file" 0 0 1 1 2
				return $file
			}
			"Abaqus" {
				*createstringarray 2 "HMBOMCOMMENTS_XML" "EXPORTIDS_SKIP"
				*feoutputwithdata "$alt_home/templates/feoutput/abaqus/standard.3d" "$file" 0 0 1 1 2
				return $file
			}
			"LsDyna" {
				*createstringarray 1 "HMBOMCOMMENTS_XML"
				*feoutputwithdata "$alt_home/2017/templates/feoutput/ls-dyna971/dyna.key" "$file" 0 0 1 1 1
				return $file
			}
			default {
				return -code error "Error: Solver Profile not found in config file"
			}
		}
	} else {
		return -code error "Error: File not selected"
	}
		
}

# ::PBSSubmit::SelectFile
# 	For Select file button
# arguments:
#	w: parent window pathname
#	ent: entry pathname to show the selected
#	opertaion: open/save
# output:
#	the file path selected return to entry
proc ::PBSSubmit::SelectFile {w ent operation} {

    if {$operation == "open"} {
		global selected_type
		if {![info exists selected_type]} {
			set selected_type "Tcl Scripts"
		}
		set file [tk_getOpenFile -filetypes $types -parent $w \
			-typevariable selected_type]
		puts "You selected filetype \"$selected_type\""
    } else {
		set curProfile [lindex [hm_framework getuserprofile] 0]
		switch -exact $curProfile {
			"OptiStruct" {
				set types {
					{"Optistruct"		{.fem}	}
					{"All files"		*}
				}
				set file [tk_getSaveFile -filetypes $types -parent $w \
				-defaultextension .fem]
			}	
			"Abaqus" {
				set types {
					{"Abaqus"			{.inp}	}
					{"All files"		*}
				}
				set file [tk_getSaveFile -filetypes $types -parent $w \
				-defaultextension .inp]
			}
			"LsDyna" {
				set types {
					{"Dyna"				{.key}	}
					{"All files"		*}
				}
				set file [tk_getSaveFile -filetypes $types -parent $w \
				-defaultextension .key]
			}
			default {
				return -code error "Error: Solver Profile not found in config file"
			}
		}
    }
    if {[string compare $file ""]} {
		$ent delete 0 end
		$ent insert 0 $file   
	}
}

# ::PBSSubmit::UpdateTxt
# 	update the txt widget
# arguments:
#	txt_handle: path name of txt
#   content: strings to insert
# output:
#	updated txt widget
proc ::PBSSubmit::UpdateTxt {txt_handle content} {
	$txt_handle configure -state normal
	set cur_time [clock format [clock seconds] -format "%Y-%b-%d %H:%M:%S"]
	$txt_handle insert end "$cur_time,$content"
	$txt_handle configure -state disabled
}

# ::PBSSubmit::ClearTxt
# 	Clear the txt widget
# arguments:
#	txt_handle: path name of txt
#   content: strings to insert
# output:
#	clear the txt
proc ::PBSSubmit::ClearTxt {txt_handle} {
	$txt_handle configure -state normal
	$txt_handle delete 0.0 end
	$txt_handle configure -state disabled
}

# ::PBSSubmit::GetUserPW
# 	check if User and PW exists
#	update them to submit_config 
# arguments:
#
# output:
#	updated submit_config
#   0:success
#   1:Failed
proc ::PBSSubmit::GetUserPW {} {
	variable submit_config;
	set acc [$::PBSSubmit::userentry get]
	set pw [$::PBSSubmit::pwentry get]
	if {$acc!=""&&$pw!=""} {
		dict set submit_config username $acc
		dict set submit_config pw $pw
		return 0
	} else {
		tk_messageBox -title "PBS Submit" -icon error -message "PBS Username/Password not ready"
		return 1
	}
}

# ::PBSSubmit::FTPTranslate
# 	Create Directory in Stage
#   translate file to remote
# arguments:
#
# output:
#	1: failed
#   0: Success
proc ::PBSSubmit::FTPTranslate {} {
	variable submit_config;
	
	set LocalDir [dict get $submit_config local_path]
	cd $LocalDir
	set job_name [dict get $submit_config job_name]

	set user [dict get $submit_config username]
	set pw [dict get $submit_config pw]
	
	set FiletoPut [file join $LocalDir [dict get $submit_config input]]
	
	#加入include file
	set include_list [hm_getincludes -byfullname]
	if {[llength $include_list]>0} {
		foreach item $include_list {
			lappend FiletoPut $item
		}
		
	}
	
	set tok [http::geturl http://10.203.48.2/site/ws_pbs/server_job_directory_create.php?job_dir=$job_name&user_name=$user&user_pass=$pw]
	set RemoteDir [http::data $tok]
	
	if {[string match "*error_*" $RemoteDir]==1} {
		puts "$RemoteDir"
		return 1
	} else {
		set RemoteDir [string range $RemoteDir 1 end];#网页返回值最前面多一个空格
		
		set ftp_handle ""
		set ftp_handle [::ftp::Open 210.75.66.60 $user $pw]
		::ftp::Cd $ftp_handle $RemoteDir
		foreach item $FiletoPut {
			::ftp::Put $ftp_handle $item
		}
		::ftp::Close $ftp_handle
		dict set submit_config remote_path [file tail $RemoteDir]
		return 0
	}
}

# ::PBSSubmit::SubmitPBS
# 	Submit to PBS
# arguments:
#	
# output:
#	1: failed
#   0: Success
proc ::PBSSubmit::SubmitPBS {} {
	variable submit_config;
	dict for {name value} $submit_config {
		set $name $value
	}
	
	switch -exact $Solver {
		"Optistruct" {
			set tok [http::geturl http://10.203.48.2/site/ws_pbs/server_job_submit_optistruct.php?job_dir_remote=$remote_path&user_name=$username&user_pass=$pw&version=$ver&job_name=$job_name&platform=$platform&cores=$cpu&main_file=$input]
			set jobid [http::data $tok]
			if {[string match "*error_*" $jobid]==1} {
				puts "$jobid"
				return 1
			} else {
				dict set submit_config job_id [string range $jobid 1 end];#网页返回值最前面多一个空格
				dict set submit_config status "submitted-q"
				return 0
			}
		}
		"Abaqus-smp" {
			set tok [http::geturl http://10.203.48.2/site/ws_pbs/server_job_submit_abaqussmp.php?job_dir_remote=$remote_path&user_name=$username&user_pass=$pw&version=$ver&job_name=$job_name&platform=$platform&cores=$cpu&main_file=$input]
			set jobid [http::data $tok]
			if {[string match "*error_*" $jobid]==1} {
				puts "$jobid"
				return 1
			} else {
				dict set submit_config job_id [string range $jobid 1 end];#网页返回值最前面多一个空格
				dict set submit_config status "submitted-q"
				return 0
			}
		}
		"Dyna-mpp" {
			set tok [http::geturl http://10.203.48.2/site/ws_pbs/server_job_submit_dynampp.php?job_dir_remote=$remote_path&user_name=$username&user_pass=$pw&version=$ver&job_name=$job_name&platform=$platform&cores=$cpu&main_file=$input]
			set jobid [http::data $tok]
			if {[string match "*error_*" $jobid]==1} {
				puts "$jobid"
				return 1
			} else {
				dict set submit_config job_id [string range $jobid 1 end];#网页返回值最前面多一个空格
				dict set submit_config status "submitted-q"
				return 0
			}
		}
		default {
			return -code error "Error: subimt http not found"
		}
	}
}

# ::PBSSubmit::WriteSubmitInfo
# 	Write the submit info in csv
# arguments:
#	
# output:
#	1: failed
#   0: Success
proc ::PBSSubmit::WriteSubmitInfo {} {
	variable submit_config;
	
	set f_out [dict get $submit_config job_name]
	append f_out "_SubmitPBS.csv"
	set f_out [file join [dict get $submit_config local_path] $f_out]
	
	set file_out [open $f_out w];
	
	set header "";
	set output "";
	dict for {name value} $submit_config {
		if {[string compare $name "username"]==0||[string compare $name "pw"]==0} {
			continue
		} else {
			append output $value ","
		}
	}
	puts $file_out [string range $output 0 end-1]
	close $file_out
}

# ::PBSSubmit::ExportandSubmit
#  function of button Export&Submit
# arguments:
#	
# output:
#	initiate submit_config
#   get username and pw
#	Update submit_config
#   Export solver deck
#	Update submit_config
#   file transfer to remote
#   update submit_config
#   job submit
#   update submit_config
#   logging....
proc ::PBSSubmit::ExportandSubmit {} {
	variable submit_config;
	
	#初始化 txt
	::PBSSubmit::ClearTxt $::PBSSubmit::txt
	
	#disable download button
	$::PBSSubmit::downloadbtn configure -state disabled
	#enable refresh button
	$::PBSSubmit::refbtn configure -state normal
	
	#从CSV中 初始化 submit_config
	::PBSSubmit::InitiaSubmitConfig $::PBSSubmit::conf
	::PBSSubmit::UpdateTxt $::PBSSubmit::txt "Solver Set....\n"
	
	#获取用户名/密码
	set flag [::PBSSubmit::GetUserPW]
	if {$flag==0} {
		::PBSSubmit::UpdateTxt $::PBSSubmit::txt "ACC/PW Set....\n"
	} else {
		::PBSSubmit::UpdateTxt $::PBSSubmit::txt "ACC/PW Not Set....Exiting\n"
		return 1
	}
	
	#输出文件/获取本地路径
	::PBSSubmit::UpdateTxt $::PBSSubmit::txt "SolverDeck Exporting....\n"
	if {[catch {set solverdeck [::PBSSubmit::ExportSolverDeck]}]==1} {
		::PBSSubmit::UpdateTxt $::PBSSubmit::txt "SolverDeck not Exported....Exiting\n"
		return 1
	} else {
		dict set submit_config job_name [file rootname [file tail $solverdeck]]
		dict set submit_config local_path [file dir $solverdeck]
		dict set submit_config input [file tail $solverdeck]
		::PBSSubmit::UpdateTxt $::PBSSubmit::txt "SolverDeck Exported....\n"
	}
	
	#传输文件/获取远程路径
	::PBSSubmit::UpdateTxt $::PBSSubmit::txt "SolverDeck Transferring....\n"
	set flag [::PBSSubmit::FTPTranslate]
	if {$flag==0} {
		::PBSSubmit::UpdateTxt $::PBSSubmit::txt "SolverDeck Transfered to PBS....\n"
	} else {
		::PBSSubmit::UpdateTxt $::PBSSubmit::txt "Can not Transfer file to PBS....Exiting\n"
		return 1
	}
	
	#PBS提交/获取作业号，作业状态
	::PBSSubmit::UpdateTxt $::PBSSubmit::txt "PBS Submitting....\n"
	set flag [::PBSSubmit::SubmitPBS]
	if {$flag==0} {
		set job_id [dict get $submit_config job_id]
		::PBSSubmit::UpdateTxt $::PBSSubmit::txt "PBS Job $job_id Created....Done\n"
	} else {
		::PBSSubmit::UpdateTxt $::PBSSubmit::txt "Can not Create PBS Job....Exiting\n"
		return 1
	}
	
	#输出记录文件
	::PBSSubmit::WriteSubmitInfo
	
	#激活refresh按钮
	$::PBSSubmit::refbtn configure -state normal
}

# ::PBSSubmit::Refresh
#  Update states of current job
# arguments:
#	
# output:
#	txt update
proc ::PBSSubmit::Refresh {} {
		
	variable submit_config;
	dict for {name value} $submit_config {
		set $name $value
	}
	
	set tok [http::geturl http://10.203.48.2/site/ws_pbs/server_job_summary.php?job_id=$job_id&user_name=$username&user_pass=$pw]
	set job_status [http::data $tok]
	set job_status [string range $job_status 1 end];#网页返回值最前面多一个空格
	puts $job_status
	switch -exact $job_status {
		"F" {
			::PBSSubmit::UpdateTxt $::PBSSubmit::txt "Job $job_id Finished....\n"
			$::PBSSubmit::refbtn configure -state disabled
			$::PBSSubmit::downloadbtn configure -state normal
			dict set submit_config status "submitted-f"
		}
		"R" {
			::PBSSubmit::UpdateTxt $::PBSSubmit::txt "Job $job_id Running....\n"
			dict set submit_config status "submitted-r"
		}
		"Q" {
			::PBSSubmit::UpdateTxt $::PBSSubmit::txt "Job $job_id Queuing....\n"
			dict set submit_config status "submitted-q"
		}
		"H" {
			::PBSSubmit::UpdateTxt $::PBSSubmit::txt "Job $job_id Holding Pls Check....\n"
			dict set submit_config status "submitted-h"
		}
		"E" {
			::PBSSubmit::UpdateTxt $::PBSSubmit::txt "Job $job_id Exiting....\n"
			dict set submit_config status "submitted-e"
		}
		default {
			return -code error "Error: Job Status not Identified"
		}
	}
	::PBSSubmit::WriteSubmitInfo
}

# ::PBSSubmit::Download
#  Update states of current job
# arguments:
#	
# output:
#	Transfer back
proc ::PBSSubmit::Download {} {
	
	variable submit_config;
	dict for {name value} $submit_config {
		set $name $value
	}
	set pbs_path [file join "/stage/cmjobs" "$username"]
	set remote_path [file join "$pbs_path" "$remote_path"]
	
	set opti_pattern [list "*.h3d" "*.out"]
	set abq_pattern [list "*.msg" "*.odb" "*.fil"]
	set dyna_pattern [list "d3plot*" "message" "binout*" "curveplot_*"]
	
	::PBSSubmit::UpdateTxt $::PBSSubmit::txt "Job $job_id Downloading....\n"
	set ftp_handle "";
	set ftp_handle [::ftp::Open 210.75.66.60 $username $pw]
	::ftp::Cd $ftp_handle $remote_path
	switch -glob $Solver {
		"Optistruct" {
			foreach pattern $opti_pattern {
				set file_list [::ftp::NList $ftp_handle $pattern]
				foreach item $file_list {
					::ftp::Get $ftp_handle $item $local_path
				}
			}
		}
		"Abaqus*" {
			foreach pattern $abq_pattern {
				set file_list [::ftp::NList $ftp_handle $pattern]
				foreach item $file_list {
					::ftp::Get $ftp_handle $item $local_path
				}
			}
		}
		"Dyna*" {
			foreach pattern $dyna_pattern {
				set file_list [::ftp::NList $ftp_handle $pattern]
				foreach item $file_list {
					::ftp::Get $ftp_handle $item $local_path
				}
			}
		}
		default {
			::PBSSubmit::UpdateTxt $::PBSSubmit::txt "Job $job_id No Matching File Found....\n"
		}
	}
	::ftp::Close $ftp_handle
	::PBSSubmit::UpdateTxt $::PBSSubmit::txt "Job $job_id Downloaded....\n"
}

# ::PBSSubmit::CreateGUI
# Create mainGUI
# arguments:
#	
# output:
#	Main GUI of Submission
proc ::PBSSubmit::CreateGUI {} {
	catch {destroy $::PBSSubmit::mainGUI}
	toplevel $::PBSSubmit::mainGUI
	wm title $::PBSSubmit::mainGUI "PBS Submission"
	wm attributes $::PBSSubmit::mainGUI -topmost 1
	#file frame
	set filefrm [ttk::labelframe $::PBSSubmit::mainGUI.filefrm -padding 10 -text "Export Solver Deck and Submit"]
	set filelab	[ttk::label $filefrm.filelab -text "     Export to:"]
	set ::PBSSubmit::fileent [ttk::entry $filefrm.fileent -width 40]
	set filesel [ttk::button $filefrm.filesel -width 15 -text "Select File.." \
	-command "::PBSSubmit::SelectFile $::PBSSubmit::mainGUI $::PBSSubmit::fileent save"]
	set filesubmit [ttk::button $filefrm.filesubmit -width 15 -text "Export&Submit" \
	-command "::PBSSubmit::ExportandSubmit"]
	set userlab [ttk::label $filefrm.userlab -text "   PBS Account:"]
	set ::PBSSubmit::userentry [ttk::entry $filefrm.userentry -width 10]
	set pwlab [ttk::label $filefrm.pwlab -text "  PBS Password:"]
	set ::PBSSubmit::pwentry [ttk::entry $filefrm.pwentry -show * -width 10]
	
	#Text Frame
	set txtfrm [ttk::labelframe $::PBSSubmit::mainGUI.txtfrm -padding 10 -text "Job Status"]
	set ::PBSSubmit::txt [text $txtfrm.txt -yscrollcommand [list $txtfrm.scroll set] \
	-setgrid 1 -height 10 -state disabled]
	set scrollbar [scrollbar $txtfrm.scroll -command [list $txtfrm.txt yview]]

	#buttom buttons
	set btnfrm [ttk::frame $::PBSSubmit::mainGUI.btnfrm -padding 10]
	set ::PBSSubmit::refbtn [ttk::button $btnfrm.refbtn -width 15 -text "Refresh Status" -state disabled -command "::PBSSubmit::Refresh"]
	set ::PBSSubmit::downloadbtn [ttk::button $btnfrm.downloadbtn -width 15 -text "Download" -state disabled -command "::PBSSubmit::Download"]
	set closebtn [ttk::button $btnfrm.closebtn -width 15 -text "Close" -command {destroy $::PBSSubmit::mainGUI}]
	
	#griding....
	grid $filefrm -row 0 -column 0 -sticky w -pady 5 -padx 5
	grid $filelab -row 0 -column 0 -sticky e -pady 5 -padx 5
	grid $::PBSSubmit::fileent -row 0 -column 1 -sticky w -pady 5 -padx 5
	grid $filesel -row 0 -column 2 -sticky w -pady 5 -padx 5
	grid $userlab -row 1 -column 0 -sticky e -pady 5 -padx 5
	grid $::PBSSubmit::userentry -row 1 -column 1 -sticky w -pady 5 -padx 5
	grid $pwlab -row 2 -column 0 -sticky e -pady 5 -padx 5
	grid $::PBSSubmit::pwentry -row 2 -column 1 -sticky w -pady 5 -padx 5
	grid $filesubmit -row 3 -column 1 -sticky w -pady 5 -padx 5
	
	grid $txtfrm -row 1 -column 0 -sticky w -pady 5 -padx 5
	pack $scrollbar -side right -fill y
	pack $::PBSSubmit::txt -expand yes -fill both
	
	grid $btnfrm -row 2 -column 0 -sticky e -pady 5 -padx 5
	grid $::PBSSubmit::refbtn -row 0 -column 0 -pady 5 -padx 5
	grid $::PBSSubmit::downloadbtn -row 0 -column 1 -pady 5 -padx 5
	grid $closebtn -row 0 -column 2 -pady 5 -padx 5
	
}
#main execute
::PBSSubmit::CreateGUI




