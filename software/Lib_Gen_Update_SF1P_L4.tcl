##***************************************************************************
##** OpenRL
##***************************************************************************
proc OpenRL {} {
  global gaSet
  if [info exists gaSet(curTest)] {
    set curTest $gaSet(curTest)
  } else {
    set curTest "1..ID"
  }
  CloseRL
  catch {RLEH::Close}
  
  RLEH::Open
  
  puts "Open PIO [MyTime]"
  set ret 0; #[OpenPio]
  set ret1 [OpenComUut]
  
  set gaSet(curTest) $curTest
  puts "[MyTime] ret:$ret ret1:$ret1" ; update
  if {$ret1!=0} {
    return -1
  }
  return 0
}

# ***************************************************************************
# OpenComUut
# ***************************************************************************
proc OpenComUut {} {
  global gaSet
  ##set ret [RLSerial::Open $gaSet(comDut) 115200 n 8 1]
  set ret [RLCom::Open $gaSet(comDut) 115200 8 NONE 1]
  if {$ret!=0} {
    set gaSet(fail) "Open COM $gaSet(comDut) fail"
  }
  return $ret
}
proc ocu {} {OpenComUut}
proc ouc {} {OpenComUut}
proc ccu {} {CloseComUut}
proc cuc {} {CloseComUut}
# ***************************************************************************
# CloseComUut
# ***************************************************************************
proc CloseComUut {} {
  global gaSet
  catch {RLCom::Close $gaSet(comDut)}
  return {}
}

#***************************************************************************
#** CloseRL
#***************************************************************************
proc CloseRL {} {
  global gaSet
  set gaSet(serial) ""
  #ClosePio
  puts "CloseRL ClosePio" ; update
  CloseComUut
  puts "CloseRL CloseComUut" ; update 
  catch {RLEH::Close}
}

# ***************************************************************************
# RetriveUsbChannel
# ***************************************************************************
proc RetriveUsbChannel {} {
  global gaSet
  # parray ::RLUsbPio::description *Ser*
  set boxL [lsort -dict [array names ::RLUsbPio::description]]
  if {[llength $boxL]!=14} {
    set gaSet(fail) "Not all USB ports are open. Please close and open the GUIs again"
    #return -1
  }
  foreach nam $boxL {
    if [string match *Ser*Num* $nam] {
      foreach {usbChan serNum} [split $nam ,] {}
      set serNum $::RLUsbPio::description($nam)
      puts "usbChan:$usbChan serNum: $serNum"      
      if {$serNum==$gaSet(pioBoxSerNum)} {
        set channel $usbChan
        break
      }
    }  
  }
  puts "serNum:$serNum channel:$channel"
  return $channel
}
# ***************************************************************************
# OpenPio
# ***************************************************************************
proc OpenPio {} {
  global gaSet descript
  set channel [RetriveUsbChannel]
  if {$channel=="-1"} {
    return -1
  }
  set gaSet(idPwr1) [RLUsbPio::Open 1 RBA $channel]
  return 0
}

# ***************************************************************************
# ClosePio
# ***************************************************************************
proc ClosePio {} {
  global gaSet
  set ret 0
  catch {RLUsbPio::Close $gaSet(idPwr1)}
  return $ret
}
# ***************************************************************************
# SaveInit
# ***************************************************************************
proc SaveInit {} {
  global gaSet  
  set id [open [info host]/init$gaSet(pair).tcl w]
  puts $id "set gaGui(xy) +[winfo x .]+[winfo y .]"
  close $id   
}

#***************************************************************************
#** MyTime
#***************************************************************************
proc MyTime {} {
  return [clock format [clock seconds] -format "%d/%m/%Y %T"]
}
#***************************************************************************
#** Send
#** #set ret [RLCom::SendSlow $com $toCom 150 buffer $fromCom $timeOut]
#** #set ret [Send$com $toCom buffer $fromCom $timeOut]
#** 
#***************************************************************************
proc Send {com sent {expected stamm} {timeOut 8}} {
  global buffer gaSet
  if {$gaSet(act)==0} {return -2}

  #puts "sent:<$sent>"
  
  ## replace a few empties by one empty
  regsub -all {[ ]+} $sent " " sent
  
  #puts "sent:<[string trimleft $sent]>"
  ##set cmd [list RLSerial::SendSlow $com $sent 50 buffer $expected $timeOut]
  if {$expected=="stamm"} {
    ##set cmd [list RLSerial::Send $com $sent]
    set cmd [list RLCom::Send $com $sent]
    foreach car [split $sent ""] {
      set asc [scan $car %c]
      #puts "car:$car asc:$asc" ; update
      if {[scan $car %c]=="13"} {
        append sentNew "\\r"
      } elseif {[scan $car %c]=="10"} {
        append sentNew "\\n"
      } else {
        append sentNew $car
      }
    }
    set sent $sentNew
  
    set tt "[expr {[lindex [time {set ret [eval $cmd]}] 0]/1000000.0}]sec"
    puts "\nsend: ---------- [MyTime] ---------------------------"
    puts "send: com:$com, ret:$ret tt:$tt, sent=$sent"
    puts "send: ----------------------------------------\n"
    update
    return $ret
    
  }
  #set cmd [list RLSerial::Send $com $sent buffer $expected $timeOut]
  #set cmd [list RLCom::Send $com $sent buffer $expected $timeOut]
  if $::sendSlow {
    set cmd [list RLCom::SendSlow $com $sent 20 buffer $expected $timeOut]
  } else {
    set cmd [list RLCom::Send $com $sent buffer $expected $timeOut]
  }
  if {$gaSet(act)==0} {return -2}
  set tt "[expr {[lindex [time {set ret [eval $cmd]}] 0]/1000000.0}]sec"
  set ::buff $buffer
  
  #puts buffer:<$buffer> ; update
  regsub -all -- {\x1B\x5B..\;..H} $buffer " " b1
  regsub -all -- {\x1B\x5B.\;..H}  $b1 " " b1
  regsub -all -- {\x1B\x5B..\;.H}  $b1 " " b1
  regsub -all -- {\x1B\x5B.\;.H}   $b1 " " b1
  regsub -all -- {\x1B\x5B..\;..r} $b1 " " b1
  regsub -all -- {\x1B\x5B.J}      $b1 " " b1
  regsub -all -- {\x1B\x5BK}       $b1 " " b1
  regsub -all -- {\x1B\x5B\x38\x30\x44}     $b1 " " b1
  regsub -all -- {\x1B\x5B\x31\x42}      $b1 " " b1
  regsub -all -- {\x1B\x5B.\x6D}      $b1 " " b1
  regsub -all -- \\\[m $b1 " " b1
  set re \[\x1B\x0D\]
  regsub -all -- $re $b1 " " b2
  #regsub -all -- ..\;..H $b1 " " b2
  regsub -all {\s+} $b2 " " b3
  regsub -all {\-+} $b3 "-" b3
  regsub -all -- {\[0\;30\;47m} $b3 " " b3
  regsub -all -- {\[1\;30\;47m} $b3 " " b3
  regsub -all -- {\[0\;34\;47m} $b3 " " b3
  regsub -all -- {\[74G}        $b3 " " b3
  set buffer $b3
  
  foreach car [split $sent ""] {
    set asc [scan $car %c]
    #puts "car:$car asc:$asc" ; update
    if {[scan $car %c]=="13"} {
      append sentNew "\\r"
    } elseif {[scan $car %c]=="10"} {
      append sentNew "\\n"
    } else {
      append sentNew $car
    }
  }
  set sent $sentNew
  
  #puts "sent:<$sent>"
  if $gaSet(puts) {
    #puts "\nsend: ---------- [clock format [clock seconds] -format %T] ---------------------------"
    #puts "\nsend: ---------- [MyTime] ---------------------------"
    puts "\n[MyTime] Send: com:$com, ret:$ret tt:$tt, sent=$sent,  expected=<$expected>, buffer=<$buffer>"
    #puts "send: ----------------------------------------\n"
    update
  }
  
  #RLTime::Delayms 50
  return $ret
}

#***************************************************************************
#** Status
#***************************************************************************
proc Status {txt {color white}} {
  global gaSet gaGui
  #set gaSet(status) $txt
  #$gaGui(labStatus) configure -bg $color
  $gaSet(sstatus) configure -bg $color  -text $txt
  if {$txt!=""} {
    puts "\n ..... $txt ..... /* [MyTime] */ \n"
  }
  $gaSet(runTime) configure -text ""
  update
}


#***************************************************************************
#** Wait
#***************************************************************************
proc Wait {txt count {color white}} {
  global gaSet
  puts "\nStart Wait $txt $count.....[MyTime]"; update
  Status $txt $color 
  for {set i $count} {$i > 0} {incr i -1} {
    if {$gaSet(act)==0} {return -2}
	 $gaSet(runTime) configure -text $i
	 RLTime::Delay 1
  }
  $gaSet(runTime) configure -text ""
  Status "" 
  puts "Finish Wait $txt $count.....[MyTime]\n"; update
  return 0
}
#***************************************************************************
#** Init_UUT
#***************************************************************************
proc Init_UUT {init} {
  global gaSet
  set gaSet(curTest) $init
  Status ""
  OpenRL
  $init
  CloseRL
  set gaSet(curTest) ""
  Status "Done"
}
# ***************************************************************************
# OpenTeraTerm
# ***************************************************************************
proc OpenTeraTerm {comName} {
  global gaSet
  set path1 C:\\Program\ Files\\teraterm\\ttermpro.exe
  set path2 C:\\Program\ Files\ \(x86\)\\teraterm\\ttermpro.exe
  if [file exist $path1] {
    set path $path1
  } elseif [file exist $path2] {
    set path $path2  
  } else {
    puts "no teraterm installed"
    return {}
  }
  # if {[string match *Dut* $comName] || [string match *Gen* $comName] || [string match *Ser* $comName]} {
    # set baud 115200
  # } else {
    # set baud 9600
  # }
  set baud 115200
  regexp {com(\w+)} $comName ma val
  set val Tester-$gaSet(pair).[string toupper $val]  
  exec $path /c=[set $comName] /baud=$baud /W="$val" &
  return {}
} 

# ***************************************************************************
# ReadCom
# ***************************************************************************
proc ReadCom {com inStr {timeout 10}} {
  global buffer buff gaSet
  set buffer ""
  $gaSet(runTime) configure -text ""
  set secStart [clock seconds]
  set secNow [clock seconds]
  set secRun [expr {$secNow-$secStart}]
  while {1} {
    if {$gaSet(act) == 0} {return -2}
    set ret [RLCom::Read $com buff]
    append buffer $buff
    puts "Read from Com-$com $secRun buff:<$buff>" ; update
    if {$ret!=0} {break}
    if {[string match "*$inStr*" $buffer]} {
      set ret 0
      break
    }
    if {[string match {*Quectel module not found*} $buffer]} {
      set ret -1
      break
    }
    
    
    after 1000
    set secNow [clock seconds]
    set secRun [expr {$secNow-$secStart}]
    $gaSet(runTime) configure -text "$secRun" ; update
    if {$secRun > $timeout} {
      set ret -1
      break
    }
  }
  return $ret
}

# ***************************************************************************
# AddLineToText
# ***************************************************************************
proc AddLineToText {{txt ""}} {
  global gaGui
  $gaGui(prgrsTxt) configure -state normal
  $gaGui(prgrsTxt) insert end "[MyTime] $txt\n"
  $gaGui(prgrsTxt) configure -state disabled
}