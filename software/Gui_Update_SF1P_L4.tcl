proc GUI {} {
  global gaSet gaGui
  wm title . "$gaSet(pair) : Update L4 FW"
  wm protocol . WM_DELETE_WINDOW {Quit}
  wm geometry . 600x350$gaGui(xy)
  wm resizable . 0 0
  
  set descmenu {
    "&File" all file 0 {	 
      {cascad "&Console" {} console 0 {
        {checkbutton "console show" {} "Console Show" {} -command "console show" -variable gConsole}
        {command "Capture Console" cc "Capture Console" {} -command CaptureConsole}
      }
      }
      {separator}
      {command "E&xit" exit "Exit" {Alt x} -command {Quit}}
    }
    "&Tools" tools tools 0 {	
      {command "Init Reference Unit"  {} {} {} -command InitRefUnit}
    }
    "&Terminal" terminal tterminal 0  {
      {command "UUT" "" "" {} -command {OpenTeraTerm gaSet(comDut)}}      
      {command "Linux level"  {} {} {} -command GuiLinuxLevel}      
    }
    
  }
  
  # "&About" all about 0 {
      # {command "&About" about "" {} -command {About}}
    # }
    
  set mainframe [MainFrame .mainframe -menu $descmenu]
  set gaSet(sstatus) [$mainframe addindicator]  
  $gaSet(sstatus) configure -width 60 
  
  #set gaSet(startTime) [$mainframe addindicator]
  
  set gaSet(runTime) [$mainframe addindicator]
  $gaSet(runTime) configure -width 5
  
  set tb0 [$mainframe addtoolbar]
  pack $tb0 -fill x
  set bb [ButtonBox $tb0.bbox0 -spacing 1 -padx 5 -pady 5]
    set gaGui(tbrun) [$bb add -image [Bitmap::get images/run1] \
        -takefocus 1 -command ButRun \
        -bd 1 -padx 5 -pady 5 -helptext "Run the Tester"]		 		 
    set gaGui(tbstop) [$bb add -image [Bitmap::get images/stop1] \
        -takefocus 0 -command ButStop \
        -bd 1 -padx 5 -pady 5 -helptext "Stop the Tester"]   
  pack $bb -side left  -anchor w -padx 7 ;#-pady 3
  
    set fr123 [frame [$mainframe getframe].fr123 -bd 2 -relief groove] 
      scrollbar $fr123.yscroll -command {$gaGui(prgrsTxt) yview} -orient vertical
      pack   $fr123.yscroll -side right -fill y
      set gaGui(prgrsTxt)  [text $fr123.prgrsTxt -yscrollcommand "$fr123.yscroll set"]
      pack $gaGui(prgrsTxt) -side left -fill both -expand 1  
    pack $fr123 -side left -fill both -expand 1
 
  pack $mainframe -fill both -expand yes

  $gaGui(tbrun) configure -relief raised -state normal
  $gaGui(tbstop) configure -relief sunken -state disabled  

  console eval {.console config -height 35 -width 92}
  console eval {set ::tk::console::maxLines 10000}
  console eval {.console config -font {Verdana 10}}
  focus -force .
  
  bind . <F1> {console show}
  bind . <Alt-r> {ButRun}
}
# ***************************************************************************
# About
# ***************************************************************************
proc About {} {
  if [file exists history.html] {
    set id [open history.html r]
    set hist [read $id]
    close $id
#     regsub -all -- {[<>]} $hist " " a
#     regexp {div ([\d\.]+) \/div} $a m date
    regsub -all -- {<[\w\=\#\d\s\"\/]+>} $hist "" a
    regexp {<!---->\s(.+)\s<!---->} $a m date
  } else {
    set date 14.11.2016 
  }
  DialogBox -title "About the Tester" -icon info -type ok  -font {{Lucida Console} 9} -message "ATE software upgrade\n$date"
  #DialogBox -title "About the Tester" -icon info -type ok\
          -message "The software upgrated at 14.11.2016"
}

#***************************************************************************
#** Quit
#***************************************************************************
proc Quit {} {
  global gaSet
  SaveInit
  RLSound::Play information
  set ret [DialogBox -title "Confirm exit"\
      -type "yes no" -icon images/question -aspect 2000\
      -text "Are you sure you want to close the application?"]
  if {$ret=="yes"} {exit}
  if {$ret=="yes"} {CloseRL; exit}
}
#***************************************************************************
#** ButRun
#***************************************************************************
proc ButRun {} {
  global gaSet gaGui
  #pack forget $gaGui(frFailStatus)
  set gaSet(ButRunTime) [clock seconds]
  Status ""
  focus $gaGui(tbrun) 
  set gaSet(runStatus) ""
  set gaSet(fail) ""
  $gaGui(prgrsTxt) configure -state normal
  $gaGui(prgrsTxt) delete 1.0 end
  $gaGui(prgrsTxt) configure -state disabled
  update
  set ::wastedSecs 0
  set gaSet(act) 1
  console eval {.console delete 1.0 end}
  console eval {set ::tk::console::maxLines 100000}
  #$gaSet(startTime) configure -text " Start: [MyTime] "
  $gaGui(tbrun) configure -relief sunken -state disabled
  $gaGui(tbstop) configure -relief raised -state normal
    
  set clkSeconds [clock seconds]
  set ti [clock format $clkSeconds -format  "%Y.%m.%d-%H.%M"]
  set gaSet(logTime) [clock format  $clkSeconds -format  "%Y.%m.%d-%H.%M.%S"]
  
  if ![file exists c:/logs] {
    file mkdir c:/logs
  }
  set ret [OpenRL]
  if {$ret==0} {
    set gaSet(runStatus) ""
    set ret [Update_L4]
  }
  puts "ret of Testing: $ret"  ; update
  set retC [CloseRL]
  puts "ret of CloseRL: $retC"  ; update
  if {$ret==0} {
    RLSound::Play pass
    #Status "Done"  green
  } else {
    RLSound::Play fail
    Status $gaSet(fail) red
  } 
  $gaGui(tbrun) configure -relief raised -state normal
  $gaGui(tbstop) configure -relief sunken -state disabled  
}  
#***************************************************************************
#** ButStop
#***************************************************************************
proc ButStop {} {
  global gaGui gaSet
  set gaSet(act) 0
  $gaGui(tbrun) configure -relief raised -state normal
  $gaGui(tbstop) configure -relief sunken -state disabled
  
  .mainframe setmenustate tools normal
  CloseRL
  update
}
#***************************************************************************
#** CaptureConsole
#***************************************************************************
proc CaptureConsole {} {
  console eval { 
    set ti [clock format [clock seconds] -format  "%Y.%m.%d_%H.%M.%S"]
    if ![file exists c:/temp] {
      file mkdir c:/temp
      after 1000
    }
    set fi c:\\temp\\ConsoleCapt_[set ti].txt
    if [file exists $fi] {
      set res [tk_messageBox -title "Save Console Content" \
        -icon info -type yesno \
        -message "File $fi already exist.\n\
               Do you want overwrite it?"]      
      if {$res=="no"} {
         set types { {{Text Files} {.txt}} }
         set new [tk_getSaveFile -defaultextension txt \
                 -initialdir c:\\ -initialfile [file rootname $fi]  \
                 -filetypes $types]
         if {$new==""} {return {}}
      }
    }
    set aa [.console get 1.0 end]
    set id [open $fi w]
    puts $id $aa
    close $id
  }
}
