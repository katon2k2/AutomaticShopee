#include "Library\ImageSearch.au3"
#include <WindowsConstants.au3>
#include <AutoItConstants.au3>
#include <StaticConstants.au3>
#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <GuiConstants.au3>
#include <Constants.au3>
#include <GDIPlus.au3>
#include <Array.au3>

Global $interrupt = 0
Global $checkScreenOn = True
Global Const $screenshot = "Img\screenshot.png"

Func _Run($sCommand, $WorkingDir = @ScriptDir & "\Adb\")
   Local $processId, $line, $output = ""
   $processId = Run(@ComSpec & " /c " & $WorkingDir & $sCommand & " 2>&1", @ScriptDir, @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
   While 1
	  $line = StdoutRead($processId)
	  If @error Then ExitLoop
		 $output &= $line
   WEnd
   Return StringTrimRight($output, StringLen(@CRLF))
EndFunc

Func _GetSizeScreen()
	Return StringRegExp(_Run("adb shell wm size"), "(\d+)x(\d+)", 3)
EndFunc

Func _TapScreen($x, $y)
   _Run("adb shell input tap "&$x&" "&$y)
EndFunc

Func _ResetAdb()
   _Run("adb kill-server")
   _Run("adb start-server")
EndFunc

Func _TurnOnScreen()
   _Run("adb shell input keyevent 26")
   Sleep(1000)
   _Run("adb shell input keyevent 26")
   Sleep(1000)
   _Run("adb shell input text 121202")
EndFunc

Func _TurnOffScreen()
   _Run("adb push --sync DisplayToggle.dex /data/local/tmp/")
   _Run("adb shell CLASSPATH=/data/local/tmp/DisplayToggle.dex app_process / DisplayToggle 0")
EndFunc

Func _TurnOnOffScreen()
   $checkScreenOn = Not $checkScreenOn
   If $checkScreenOn Then
	  _TurnOffScreen()
   Else
	  _TurnOnScreen()
   EndIf
EndFunc

Func _WatchVideo()
	_TurnOffScreen()
	$interrupt = 0
	$timer = TimerInit()
	_Swipe()
	While $interrupt == 0
		If TimerDiff($timer) > 50000 Then
			_Swipe()
			$timer = TimerInit()
		EndIf
		Sleep(2000)
	WEnd
EndFunc

Func _WatchLive()
	_TurnOffScreen()
	$timer = TimerInit()
	$interrupt = 0
	While $interrupt == 0
		If TimerDiff($timer) > 299000 Then
			MsgBox('', '', 'DONE', 3)
			ExitLoop
		EndIf
		Sleep(500)
	WEnd
EndFunc

Func _Swipe()
	_Run("adb shell input swipe "&10&" "&1000&" "&10&" "&100&" "&100)
EndFunc

HotKeySet("{End}", "_WatchLive")
HotKeySet("{PGUP}", "_TurnOnScreen")
HotKeySet("{PGDN}", "_Swipe")
HotKeySet("{HOME}", "_TurnOffScreen")

#Region ### START Koda GUI section ### Form=
$Form1 = GUICreate("Form1", 191, 90)
$btnReset = GUICtrlCreateButton("Reset", 16, 18, 75, 25)
$btnPause = GUICtrlCreateButton("Pause", 100, 18, 75, 25)
$btnWatchVideo = GUICtrlCreateButton("Watch Video", 16, 44, 75, 25)
$btnWatchLive = GUICtrlCreateButton("Watch Live", 100, 44, 75, 25)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

#Region Định nghĩa và gán các Button muốn dùng để ngắt vòng lặp
GUIRegisterMsg($WM_COMMAND, "_WM_COMMAND_PAUSEBUTTON")
Func _WM_COMMAND_PAUSEBUTTON($hWnd, $Msg, $wParam, $lParam)
   Switch BitAND($wParam, 0x0000FFFF)
	  Case $btnPause
		 $interrupt = 1
   EndSwitch
   Return 'GUI_RUNDEFMSG'
EndFunc
#EndRegion

#Region Tắt GUI khi vẫn còn đang chạy vòng lặp
GUIRegisterMsg($WM_SYSCOMMAND, "_WM_COMMAND_CLOSEBUTTON")
Func _WM_COMMAND_CLOSEBUTTON($hWnd, $Msg, $wParam, $lParam)
   If BitAND($wParam, 0x0000FFFF) = 0xF060 Then
	  Exit
   EndIf
   Return 'GUI_RUNDEFMSG'
EndFunc
#EndRegion

While 1
   Switch GUIGetMsg()
	  Case $GUI_EVENT_CLOSE
		 Exit
	  Case $btnReset
		 _ResetAdb()
	  Case $btnWatchLive
		 GUICtrlSetData($btnWatchLive, "Watching...")
		 _WatchLive()
		 GUICtrlSetData($btnWatchLive, "Watch Live")
	  Case $btnWatchVideo
		 GUICtrlSetData($btnWatchVideo, "Watching...")
		 _WatchVideo()
		 GUICtrlSetData($btnWatchVideo, "Watch Video")
   EndSwitch
WEnd