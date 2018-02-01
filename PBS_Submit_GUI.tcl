# File      : PBS_Submit_GUI.tcl
# Date      : 2018.2.1
# Created by: HXM
# Function  : 1.生成用户界面
#             2.提供界面按钮功能

package require Tk
# 定义变量
catch {namespace delete ::PBSSubmit}
namespace eval ::PBSSubmit {
	#GUI Related Variables
	variable mainGUI;
	set mainGUI .mainGUI;
	
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

# ::PBSSubmit::ExportSolverDeck
#
# arguments:
#	
# output:
#
proc ::PBSSubmit::ExportSolverDeck {} {

}

# ::PBSSubmit::SelectFile
# 
# arguments:
#	
# output:
#
proc ::PBSSubmit::SelectFile {} {

}

# ::PBSSubmit::RefreshTxt
# 
# arguments:
#	
# output:
#
proc ::PBSSubmit::RefreshTxt {} {

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
	set fileent [ttk::entry $filefrm.fileent -width 40]
	set filesel [ttk::button $filefrm.filesel -width 15 -text "Select File.."]
	set filesubmit [ttk::button $filefrm.filesubmit -width 15 -text "Export&Submit"]
	
	#Text Frame
	set txtfrm [ttk::labelframe $::PBSSubmit::mainGUI.txtfrm -padding 10 -text "Job Status"]
	set txt [text $txtfrm.txt -yscrollcommand [list $txtfrm.scroll set] -setgrid 1 -height 10 -state disabled]
	set scrollbar [scrollbar $txtfrm.scroll -command [list $txtfrm.txt yview]]

	#buttom buttons
	set btnfrm [ttk::frame $::PBSSubmit::mainGUI.btnfrm -padding 10]
	set refbtn [ttk::button $btnfrm.refbtn -width 15 -text "Refresh Status"]
	set downloadbtn [ttk::button $btnfrm.downloadbtn -width 15 -text "Download" -state disabled]
	set closebtn [ttk::button $btnfrm.closebtn -width 15 -text "Close" -command exit]
	
	#griding....
	grid $filefrm -row 0 -column 0 -sticky w -pady 5 -padx 5
	grid $filelab -row 0 -column 0 -sticky w -pady 5 -padx 5
	grid $fileent -row 0 -column 1 -sticky w -pady 5 -padx 5
	grid $filesel -row 0 -column 2 -sticky w -pady 5 -padx 5
	grid $filesubmit -row 0 -column 3 -sticky w -pady 5 -padx 5
	
	grid $txtfrm -row 1 -column 0 -sticky w -pady 5 -padx 5
	pack $scrollbar -side right -fill y
	pack $txt -expand yes -fill both
	
	grid $btnfrm -row 2 -column 0 -sticky e -pady 5 -padx 5
	grid $refbtn -row 0 -column 0 -pady 5 -padx 5
	grid $downloadbtn -row 0 -column 1 -pady 5 -padx 5
	grid $closebtn -row 0 -column 2 -pady 5 -padx 5
	
}
::PBSSubmit::CreateGUI


