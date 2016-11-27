; "DeskIcons.ahk"
; Updated to be x86 and x64 compatible by Joe DF
; Revision Date : 22:13 2014/05/09
; From : Rapte_Of_Suzaku
; http://www.autohotkey.com/board/topic/60982-deskicons-getset-desktop-icon-positions/

/*
   Save and Load desktop icon positions
   based on save/load desktop icon positions by temp01 (http://www.autohotkey.com/forum/viewtopic.php?t=49714)
   
   Example:
      ; save positions
      coords := DeskIcons()
      MsgBox now move the icons around yourself
      ; load positions
      DeskIcons(coords)
   
   Plans:
      handle more settings (icon sizes, sort order, etc)
         - http://msdn.microsoft.com/en-us/library/ff485961%28v=VS.85%29.aspx
   
*/

while True {
   x := 1000
   y := 0
   while x > 0 {
      coords := DeskIcons("",y)
      DeskIcons(coords,1)
      Sleep, 1000/100
      x--
      y := y + 2
   }
}


DeskIcons(coords, ByRef speed){
   Critical
   static MEM_COMMIT := 0x1000, PAGE_READWRITE := 0x04, MEM_RELEASE := 0x8000
   static LVM_GETITEMPOSITION := 0x00001010, LVM_SETITEMPOSITION := 0x0000100F, WM_SETREDRAW := 0x000B
   
   ControlGet, hwWindow, HWND,, SysListView321, ahk_class Progman
   if !hwWindow ; #D mode
      ControlGet, hwWindow, HWND,, SysListView321, A
   IfWinExist ahk_id %hwWindow% ; last-found window set
      WinGet, iProcessID, PID
   hProcess := DllCall("OpenProcess"   , "UInt",   0x438       ; PROCESS-OPERATION|READ|WRITE|QUERY_INFORMATION
                              , "Int", FALSE       ; inherit = false
                              , "ptr", iProcessID)
   if hwWindow and hProcess
   {  
      ControlGet, list, list,Col1         
      if !coords
      {
         VarSetCapacity(iCoord, 8)
         pItemCoord := DllCall("VirtualAllocEx", "ptr", hProcess, "ptr", 0, "UInt", 8, "UInt", MEM_COMMIT, "UInt", PAGE_READWRITE)
         Loop, Parse, list, `n
         {
            SendMessage, %LVM_GETITEMPOSITION%, % A_Index-1, %pItemCoord%
            DllCall("ReadProcessMemory", "ptr", hProcess, "ptr", pItemCoord, "UInt", &iCoord, "UInt", 8, "UIntP", cbReadWritten)
            speed := speed
            MouseGetPos, xpos, ypos 
            DesktopScreenCoordinates(xmin,ymin,xmax,ymax)
            ;ypos := ymax - ypos
            Scale(NumGet(iCoord,"Int"),xpos,Numget(iCoord, 4,"Int"),ypos,speed,xspeed,yspeed)
            ret .= A_LoopField ":" (((NumGet(iCoord,"Int")+xspeed) & 0xFFFF) | (((Numget(iCoord, 4,"Int")+yspeed) & 0xFFFF) << 16)) "`n"
         }
         DllCall("VirtualFreeEx", "ptr", hProcess, "ptr", pItemCoord, "ptr", 0, "UInt", MEM_RELEASE)
      }
      else
      {
         SendMessage, %WM_SETREDRAW%,0,0
         Loop, Parse, list, `n
            If RegExMatch(coords,"\Q" A_LoopField "\E:\K.*",iCoord_new)
               SendMessage, %LVM_SETITEMPOSITION%, % A_Index-1, %iCoord_new%
         SendMessage, %WM_SETREDRAW%,1,0
         ret := true
      }
   }
   DllCall("CloseHandle", "ptr", hProcess)
   return ret
}

DesktopScreenCoordinates(byref Xmin, byref Ymin, byref Xmax, byref Ymax){
   SysGet, Xmin, 76  ; XVirtualScreenleft    ; left side of virtual screen
   SysGet, Ymin, 77  ; YVirtualScreenTop     ; Top side of virtual screen
   WinGetPos tbrX, tbrY, tbrWidth, tbrHeight, ahk_class Shell_TrayWnd
   SysGet, VirtualScreenWidth, 78
   SysGet, VirtualScreenHeight, 79

   Xmax := Xmin + VirtualScreenWidth
   Ymax := Ymin + VirtualScreenHeight-200-tbrHeight
   return
} 

Min(x,x1="",x2="",x3="",x4="",x5="",x6="",x7="",x8="",x9="") {
   Loop
      IfEqual x%A_Index%,, Return x
      Else x := x < x%A_Index% ? x : x%A_Index%
}

Max(x,x1="",x2="",x3="",x4="",x5="",x6="",x7="",x8="",x9="") {
   Loop
      IfEqual x%A_Index%,, Return x
      Else x := x > x%A_Index% ? x : x%A_Index%
}

Scale(x1,x2,y1,y2,ByRef speed, ByRef speedX, ByRef speedY){
   distance := sqrt((y2-y1)**2+(X2-X1)**2)
   speedX := (x2-x1) * (speed/distance)
   speedY := (y2-y1) * (speed/distance)
   return
}
