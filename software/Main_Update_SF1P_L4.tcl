# ***************************************************************************
# InitRefUnit
# ***************************************************************************
proc InitRefUnit {} {
  global gaSet buffer
  catch {CloseComUut} 
  after 1000
  set ret [OpenComUut]
  if {$ret==0} {
    set ret [InitRefUnitPerf]
  }
  CloseComUut
  if {$ret!=0} {
    RLSound::Play fail
    update
    DialogBox -icon /images/error -title "Fail to init reference" -text $gaSet(fail) -type OK
    Status "$gaSet(fail)" red
  } else {  
    RLSound::Play information
    Status Done yellow
  }  
  
  return 0
}
# ***************************************************************************
# Update_L4
# ***************************************************************************
proc Update_L4 {} {
  AddLineToText "Checking current FW"
  set ret [Check_L4_Ver]
  if {$ret=="-1" || $ret=="-2"} {return $ret}
  AddLineToText "\tCurrent FW: $ret"
  if {$ret=="EC25AFFDR07A10M4G"} {
    Status "FW is $ret, no need update" green
    return 0
  }
  set ret [Update_L4_Perf]
  if {$ret==0} {
    AdminReboot
    AddLineToText "Checking updated FW"
    set ret [Check_L4_Ver]
    if {$ret=="-1" || $ret=="-2"} {return $ret}
    AddLineToText "\tUpdated FW: $ret"
    if {$ret=="EC25AFFDR07A10M4G"} {
      Status "FW is $ret" green
      return 0
    } else {
      set gaSet(fail) $ret
      return -1
    }
  }
  return $ret
}
# ***************************************************************************
# GuiLinuxLevel
# ***************************************************************************
proc GuiLinuxLevel {} {
  global gaSet buffer
  set ::sendSlow 1
  catch {CloseComUut} 
  after 1000
  set ret [OpenComUut]
  if {$ret==0} {
    set ret [Login]
    if {$ret!=0} {return $ret}
    set ret [Login2Linux]
  }
  CloseComUut
  if {$ret!=0} {
    RLSound::Play fail
    update
    Status "$gaSet(fail)" red
  } else {
    RLSound::Play information
    update
    Status "Done" yellow
  }
  
  return 0
}