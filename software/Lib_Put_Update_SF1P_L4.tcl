# ***************************************************************************
# Login
# ***************************************************************************
proc Login {} {
  global gaSet buffer
  set ret -1
  set gaSet(loginBuffer) ""
  set statusTxt  [$gaSet(sstatus) cget -text]
  Status "Login"
  set com $gaSet(comDut)
  
  Send $com "\r" stam 0.25
  append gaSet(loginBuffer) "$buffer"
  Send $com "\r" stam 0.25
  append gaSet(loginBuffer) "$buffer"
  if {[string match {*PCPE*} $gaSet(loginBuffer)]} {
    Send $com boot\r "partitions"
  }
  if {[string match {*root@localhost*} $gaSet(loginBuffer)]} {
    Send $com exit\r\r "-1p"
  }
  
  if {$ret!=0} {
    if {[string match *-1p* $buffer]} {
      after 2000
      Send $com "\r" stam 0.25
      append gaSet(loginBuffer) "$buffer"
      if {[string match *-1p* $buffer]} {
        set ret 0
      }
    }
  }
  if {$ret!=0} {
    if {[string match {*CLI session is closed*} $buffer]} {
      set ret -1
      RLCom::Send $com \r
    }
  }
  
  set gaSet(fail) "Login fail" 
  set startSec [clock seconds]
  if {$ret!=0} {
    for {set i 1} {$i<=90} {incr i} {
      set loginTime [expr {[clock seconds] - $startSec}]
      $gaSet(runTime) configure -text $loginTime ; update
      if {$gaSet(act)==0} {set ret -2; break}
      RLCom::Read $com buffer
      append gaSet(loginBuffer) "$buffer"
      #puts "Login i:$i [MyTime] gaSet(loginBuffer):<$gaSet(loginBuffer)>" ; update
      puts "Login i:$i $loginTime [MyTime] buffer:<$buffer>" ; update
      
      if {[string match {*failed to achieve system info*} $gaSet(loginBuffer)] &&\
          [string match {*command execute error:*} $gaSet(loginBuffer)]} {
        return "PowerOffOn"  
      }    

      if {[string match {*user>*} $gaSet(loginBuffer)]} {
        set ret [Send $com su\r "assword"]
        set ret [Send $com 1234\r "-1p#" 3]
        if {$ret=="-1"} {
          if {[string match {*Login failed user*} $buffer]} {
            set ret [Send $com su\r4\r "again" 3]
          }
          set ret [Send $com 4\r "again" 3]
          set ret [Send $com 4\r "-1p#" 3]
        }        
        if {$ret==0} {break}
      }
      if {[string match {*-1p*} $buffer]} {
        return 0
      }
      if {[string match {*PCPE*} $buffer]} {
        Send $com boot\r "partitions"
      }
      after 5000
    }
  }
  
  return $ret
}

# ***************************************************************************
# Login2Linux
# ***************************************************************************
proc Login2Linux {} {
  global gaSet buffer
  set ret -1
  set gaSet(loginBuffer) ""
  set statusTxt  [$gaSet(sstatus) cget -text]
  Status "Login to Linux"
  set com $gaSet(comDut)
  
  Send $com "\r" stam 1
  if {[string match {*root@localhost*} $gaSet(loginBuffer)]} {
    return 0
  }
  
  set ret [LogonDebug $com]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "debug shell\r\r" localhost]
  if [string match *:/#* $buffer] {
    set gaSet(linuxPrompt) /#
  } elseif [string match */\]* $buffer] {
    set gaSet(linuxPrompt) /\]
  }
  set ret [Send $com "\r\r" $gaSet(linuxPrompt)]
  return $ret
}
# ***************************************************************************
# LogonDebug
# ***************************************************************************
proc LogonDebug {com} {
  global gaSet buffer
  Send $com "exit all\r" stam 0.25 
  Send $com "logon debug\r" stam 0.25 
  Status "logon debug"
   if {[string match {*command not recognized*} $buffer]==0} {
#     set ret [Send $com "logon debug\r" password]
#     if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" "-1p#" ]
    if {$ret!=0} {return $ret}
  } else {
    set ret 0
  }
  return $ret  
}


# ***************************************************************************
# InitRefUnitPerf
# ***************************************************************************
proc InitRefUnitPerf {} {
  global gaSet buffer
  set ::sendSlow 0
  puts "\n[MyTime] Init Ref Unit"; update
  set com $gaSet(comDut)
  
  set ret [Login]
  if {$ret!=0} {return $ret}
  
 
  set ret [PingToRef]
  if {$ret!=0} {
  
   Status "Init Ref Unit"
    set ret [Send $com "exit all\r" "-1p"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "configure\r" "config#"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "port ethernet 3\r" "(3)"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "shutdown\r" "(3)"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "exit\r" "port"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "exit\r" "config"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "router 1\r" "router(1)#"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "no interface 32\r" "router(1)#"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "no interface 3\r" "router(1)#"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "interface 3\r" "(3)"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "shutdown\r" "(3)"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "address 10.10.10.1$gaSet(pair)/24\r" "(3)"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "bind ethernet 3\r" "(3)"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "no shutdown\r" "(3)"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "exit\r" "(1)"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "exit\r" "config"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "port ethernet 3\r" "(3)"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "no shutdown\r" "(3)"]
    if {$ret!=0} {return $ret}
    
    set ret [Send $com "exit all\r" "-1p"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "admin save\r" "successfully"]
    if {$ret!=0} {return $ret}
    
    set ret [PingToRef]
    if {$ret!=0} {return $ret}
  }  
  
  set ret [Login2Linux]
  if {$ret!=0} {return $ret}   
  
  set ret [Send $com "ll /mnt\r" "#"]
  if {$ret!=0} {return $ret}
  puts "llmnt:<$buffer>"
  if ![string match {*QFirehose*} $buffer] {
    set gaSet(fail) "No QFirehose at /mnt"
    return -1
  }
  
  return $ret
}
# ***************************************************************************
# PingToRef
# ***************************************************************************
proc PingToRef {} {
  global gaSet 
  set addr 10.10.10.1$gaSet(pair)
  Status "Pings to $addr"
  catch {exec ping $addr -n 1} res
  puts "Res of ping: <$res>"
  catch {exec ping $addr -n 1} res
  puts "Res of ping: <$res>"
  if [catch {exec ping $addr} res] {
    set gaSet(fail) "Ping to $addr fail"
    return -1
  } else {
    puts "Res of pings: <$res>"
    set ret 0
    if ![string match {*Received = 4*} $res] {
      set gaSet(fail) "No 4 ping replies from addr"
      return -1  
    }
  }
  return $ret
}

# ***************************************************************************
# Check_L4_Ver
# ***************************************************************************
proc Check_L4_Ver {} {
  global gaSet buffer gaGui
  set ::sendSlow 0
  puts "\n[MyTime] Check_L4_Ver"; update
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Check Firmware fail"
  Status "Check Firmware"
  set ret [Send $com "exit all\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "port\r" "-1p"]
  if {$ret!=0} {return $ret}
  set prmpt "(lte)"
  set ret [Send $com "cellular lte\r" $prmpt]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show status\r" "stam" 1]
  set buf $buffer
  set ret [Send $com "\r" "stam" 1]
  append buf $buffer
  set ret [Send $com "\r" "stam" 1]
  append buf $buffer
  #set ret [Send $com "\r" "stam" 1]
  #append buf $buffer
  #if {$ret!=0} {return $ret}
  set buffer $buf
  set gaSet(fail) "Read Firmware fail"
  set val ""
  set res [regexp {Firmware : Revision:\s+(\w+)} $buffer ma val]  
  if {$res==0} {
    set res [set res [regexp {Firmware :\s+([\w\._/]+)} $buffer ma val]]  
    if {$res==0} {return -1}  
  }  
  puts "Firmware ma:<$ma> val:<$val>"; update  
  set ret $val  
  
  return $ret
}
# ***************************************************************************
# Update_L4_Perf
# ***************************************************************************
proc Update_L4_Perf {} {
  global gaSet buffer gaGui
  puts "\n[MyTime] Update_L4_Perf"; update
  set com $gaSet(comDut)
  
  set ret [Login]
  if {$ret!=0} {return $ret}
  set ret [Login2Linux]
  if {$ret!=0} {return $ret} 
   
  set ret [Send $com "ll /mnt\r" "#"]
  if {$ret!=0} {return $ret}
  puts "llmnt:<$buffer>"
  if ![string match {*QFirehose*} $buffer] {
    set gaSet(fail) "No QFirehose at /mnt"
    return -1
  }   
  set ret [Send $com "cd /mnt\r" "#"]
  set ret [Send $com "chmod 777 QFirehose\r" "#"]
   
  AddLineToText "First time FW updating"
  Status "Update FW (1)"
  set ret [Send $com \r\r "#"]
  #set ret [Send $com "./QFirehose -f EC25AFFDR07A10M4G_01.007.01.007/\r" "mnt" 60]
  set ret [Send $com "./QFirehose -f EC25AFFDR07A10M4G_01.007.01.007/\r" "stam" 1]
  set ret [ReadCom $com "mnt" 90]
  if {$ret!=0} {
    set gaSet(fail) "Update FW fail"
    return -1
  } 
  if {[string match {*Upgrade module failed*} $buffer]} {
    AddLineToText "Second time FW updating"
    Status "Update FW (2)"
    #set ret [Send $com "./QFirehose -f EC25AFFDR07A10M4G_01.007.01.007/\r" "Upgrade module successfully" 60]
    set ret [Send $com \r\r "#"]
    set ret [Send $com "./QFirehose -f EC25AFFDR07A10M4G_01.007.01.007/\r" "stam" 1]
    set ret [ReadCom $com "Upgrade module successfully" 90]
    if {$ret!=0} {
      set gaSet(fail) "Update FW fail"
      return -1
    } 
  }
  
  return $ret
  
}
# ***************************************************************************
# AdminReboot
# ***************************************************************************
proc AdminReboot {} {
  global gaSet buffer gaGui
  AddLineToText "Reboot after FW updating"
  Status "Admin Reboot"
  set ret [Login]
  if {$ret!=0} {return $ret}
  set com $gaSet(comDut)
  set ret [Send $com "exit all\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "admin reboot\r" "yes/no"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "yes\r" "stam" 1]
  
  Wait "Wait for reboot" 20
  return 0
}

