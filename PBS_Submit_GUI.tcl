# File      : PBS_Submit_GUI.tcl
# Date      : 2018.2.1
# Created by: HXM
# Function  : 1.生成用户界面
#             2.提供界面按钮功能

package require Tk
# 定义变量
source {C:\Users\imaix\OneDrive\Documents\Github\ReadFileLib\lib\ReadCSV.tcl}
#set libDir [file join [file dir [info script]] "lib"]
#source "$libDir/ReadCSV.tcl"

catch {namespace delete ::PBSSubmit}
namespace eval ::PBSSubmit {
	#GUI Related Variables
	variable mainGUI;
	set mainGUI .mainGUI;
	
	variable txt; #txt文本框
	
	#PBS submit config,用于提交当前作业
	variable submit_config;
	
	#运行环境
	#variable baseDir;#tcl脚本运行目录
	#set baseDir [file dir [info script]];
	
	#界面相关
	#variable projui;#proj主界面名称
	#set projui .projui;
	#variable pulldown; #下拉菜单显示内容
	#variable proj_tkv_config;#下拉菜单显示内容设置文件
	#set proj_tkv_config  "$baseDir/01_PROJ_TKV_CONFIG.csv";
}

# ::PBSSubmit::GetSolverType
#	get hw profile
# arguments:
#	
# output:
#

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
	#set solver_type [::PBSSubmit::GetSolverType]
	set solver_type "Optistruct"
	set dict_value [lsearch -exact -index 1 -inline $tmplist $solver_type]
	puts $dict_value
	
	set submit_config [dict create]
	foreach name $dict_name value $dict_value {
		dict set submit_config $name $value
	}
}
#test
#set f_in "C:/Users/imaix/OneDrive/Documents/Github/PBS_Submit/PBS_CONFIG/CONFIG.csv"
#::PBSSubmit::InitiaSubmitConfig $f_in
#dict for {name value} $::PBSSubmit::submit_config {
#	puts "$name $value"
#}
#test

# ::PBSSubmit::ExportSolverDeck
#
# arguments:
#	
# output:
#
proc ::PBSSubmit::ExportSolverDeck {} {

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
	 set types {
		{"Optistruct"		{.fem}	}
		{"Abaqus"			{.inp}	}
		{"Dyna"				{.dyn .key}	}
		{"All files"		*}
    }
    if {$operation == "open"} {
		global selected_type
		if {![info exists selected_type]} {
			set selected_type "Tcl Scripts"
		}
		set file [tk_getOpenFile -filetypes $types -parent $w \
			-typevariable selected_type]
		puts "You selected filetype \"$selected_type\""
    } else {
		set file [tk_getSaveFile -filetypes $types -parent $w \
			-initialfile Untitled -defaultextension .txt]
    }
    if {[string compare $file ""]} {
		$ent delete 0 end
		$ent insert 0 $file
		$ent xview end
    }
}

# ::PBSSubmit::WriteLog
# 	Write log file with time
# arguments:
#	f_out: file path of log
#   content: string to log
# output:
#	write to log file end
proc ::PBSSubmit::WriteLog {f_out content} {
	set file_out [open $f_out a];
	set cur_time [clock format [clock seconds] -format "%Y-%b-%d %H:%M:%S"]
	puts $file_out "$cur_time,$content"
	close $file_out
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
	$txt_handle insert end $content
	$txt_handle configure -state disabled
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
	set filelab	[ttk::label $filefrm.filelab -text "Export to:"]
	set ::PBSSubmit::fileent [ttk::entry $filefrm.fileent -width 40]
	set filesel [ttk::button $filefrm.filesel -width 15 -text "Select File.." \
	-command "::PBSSubmit::SelectFile $::PBSSubmit::mainGUI $::PBSSubmit::fileent save"]
	set filesubmit [ttk::button $filefrm.filesubmit -width 15 -text "Export&Submit"]
	
	#Text Frame
	set txtfrm [ttk::labelframe $::PBSSubmit::mainGUI.txtfrm -padding 10 -text "Job Status"]
	set ::PBSSubmit::txt [text $txtfrm.txt -yscrollcommand [list $txtfrm.scroll set] \
	-setgrid 1 -height 10 -state disabled]
	set scrollbar [scrollbar $txtfrm.scroll -command [list $txtfrm.txt yview]]

	#buttom buttons
	set btnfrm [ttk::frame $::PBSSubmit::mainGUI.btnfrm -padding 10]
	set refbtn [ttk::button $btnfrm.refbtn -width 15 -text "Refresh Status"]
	set downloadbtn [ttk::button $btnfrm.downloadbtn -width 15 -text "Download" -state disabled]
	set closebtn [ttk::button $btnfrm.closebtn -width 15 -text "Close" -command exit]
	
	#griding....
	grid $filefrm -row 0 -column 0 -sticky w -pady 5 -padx 5
	grid $filelab -row 0 -column 0 -sticky w -pady 5 -padx 5
	grid $::PBSSubmit::fileent -row 0 -column 1 -sticky w -pady 5 -padx 5
	grid $filesel -row 0 -column 2 -sticky w -pady 5 -padx 5
	grid $filesubmit -row 0 -column 3 -sticky w -pady 5 -padx 5
	
	grid $txtfrm -row 1 -column 0 -sticky w -pady 5 -padx 5
	pack $scrollbar -side right -fill y
	pack $::PBSSubmit::txt -expand yes -fill both
	
	grid $btnfrm -row 2 -column 0 -sticky e -pady 5 -padx 5
	grid $refbtn -row 0 -column 0 -pady 5 -padx 5
	grid $downloadbtn -row 0 -column 1 -pady 5 -padx 5
	grid $closebtn -row 0 -column 2 -pady 5 -padx 5
	
}
#::PBSSubmit::CreateGUI




