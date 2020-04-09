;Download https://www.autohotkey.com/download/ahk-install.exe to use this script.
;Made by AFK on core#0614 , message me on discord if you need anything or have suggestions!
v:=200409 ;Script version, yearmonthday
;###SETTINGS: (Change to false or 0 to disable option)
DEBUG := 0 ;Change it to false to turn off the annoying windows

boostKeybind:= "c" ;What key do you press to activate your boost (default is "c")
abilityKeybind:= "f" ;What key do you press to activate your first ability (default is "f")
sellMouseOverWarning := false
;___
;TODO: Spam repair at build phase? warning if unsupported res

CoordMode, Pixel, Screen
CoordMode, Mouse, Screen ;Change coordinate to be relative to the screen and not the current active window
autoG := false
Setup() ;Get game resolution and calculate various X/Y coordinates
if(!DEBUG){
	Progress, B Y0 ZH0 CW272822 CT60D9EF,Welcome to AFK on core's toolkit!
	Sleep, 550 
	Progress, OFF
}

Loop{ ;Main Loop
	global waitNextCombatPhase
	global abilitySpamToggle
	global abilityTimer
	phase := CheckPhaseColor() ;get the color of the ribbon top right of the screen to know the current phase
	if(phase == "warmup" && !waitNextCombatPhase){
		G() 
		waitNextCombatPhase := true ;Wait wave2 to press G as to not screw up the first build phase
	}else if(phase == "build"){
		if(!waitNextCombatPhase){
			if(autoG){
				G() ;Press G, works even if DDA is in background
			}else{
				PopUp() ;Will put the game in front at build phase if you tab out without activating autoG
			}
			actionTaken := true	
		}	
	}else if(phase == "mapover"){
		IfWinNotActive, ahk_exe DDS-Win64-Shipping.exe{
			PopUp()
			actionTaken := true
		;} ;WTF AHK WHY U ERROR?!
	}else if(phase == "combat"){
		waitNextCombatPhase := false
		if(abilitySpamToggle){
			AbilitySpam()
		}
	}	
	sleepTime := 0
	if(!DEBUG){
		sleepTime := sleepTime+5000	
		if(actionTaken){
			waitNextCombatPhase := true
			actionTaken := false
		}
		if(abilitySpamToggle && phase == "combat" && A_TickCount+sleepTime > abilityTimer){ ;If the ability is to be used soon it will wait for a shorter amount of time
			sleepTime := A_TickCount-abilityTimer
		}
		Sleep, sleepTime
	}else{ ;DEBUG: Display various debug information
		CheckHeroColor() 
		DisplayInventoryBorder()
		if(actionTaken){
			Sleep, 10*1000
			actionTaken := false
		}
	}
}
;~w:: 
;ControlSend,,{e down}, ahk_exe DDS-Win64-Shipping.exe
;Sleep, 10
;ControlSend,,{e up}, ahk_exe DDS-Win64-Shipping.exe
;return
;~c:: Click
~F8:: Reload ;Restart fresh, use it to stop AbilitySpam
^g:: ;Ctrl+G and F9 both activate auto G
~F9:: ActivateAutoG()
#ifWinActive, ahk_exe DDS-Win64-Shipping.exe
~s:: ;S to sell, L to lock item under cursor
F5:: SellMouseOver() ;Sells item under your cursor
F6:: Click ;  LockMouseOver() ;Lock item under your cursor
~^LButton:: ;Ctrl+Click or F10 to AutoFire
F10:: AutoFire() ;Auto attack depending on current hero
F11:: ActivateAbilitySpam() ;AbilitySpam() ;Spam right click on apprentice or tower boost on Monk (make sure abilityKeybind [line 9] is set the correct key)

Setup(){ ;Get game resolution and calculate various X/Y coordinates  ;/!\ issues with 1280x1024
	global DEBUG
	global WinID
	global WinX
	global WinY
	global WinWidth
	global WinHeight
	global phaseColorX
	global phaseColorY
	global heroColorX
	global heroColorY
	;Check for Update
	Update()
	;Get game's size
	WinGetPos, WinX, WinY,WinWidthWithTitle,WinHeightWithTitle, ahk_exe DDS-Win64-Shipping.exe
	;DDL call to get client size thanks to /u/G33kDude https://www.reddit.com/r/AutoHotkey/comments/a62ieu/
	VarSetCapacity(rect, 16)
	DllCall("GetClientRect", "ptr", WinExist("ahk_exe DDS-Win64-Shipping.exe"), "ptr", &rect)
	WinWidth := NumGet(rect, 8, "int")
	WinHeight := NumGet(rect, 12, "int")
	;__
	WinGet, WinID,, ahk_exe DDS-Win64-Shipping.exe
	WinRatio:= SubStr(WinWidth/WinHeight,3,1) ;"1.(3)3:4/3 - 1.(6):16/10 - 1.(7)7:6/9"
	
		if(WinX==0 && WinY==0){
			if(A_ScreenWidth==WinWidth && A_ScreenHeight==WinHeight){
				fullscreenWindowed := true
			}
		}else{
			MsgBox, You're not running the game in Borderless Windowed. `n The script might not work, sorry about that.
		}
	
	;Set coordinate to check for with CheckHeroColor(), CheckPhaseColor and the expected items' position in the inventory
	phaseColorX := WinWidth*0.97 ;Same X coord for all screen ratio	
	heroColorX := WinWidth*0.03
	;4/3
	if(WinRatio == 3){ ;[1024x768] [1152x864] [1280x960]
		phaseColorY := WinHeight*0.0945 
		heroColorX := WinWidth*0.039
		heroColorY := WinHeight*0.111
	}
	;16/10
	if(WinRatio == 6){
		if(WinWidth == 1280){ ;[1280x800] [1280x768]
			phaseColorY := WinHeight*0.097 
			heroColorY := WinHeight*0.112
		}else{ ;[1440x900] ;765 285 / 1340 765
			phaseColorX := WinWidth*0.964
			phaseColorY := WinHeight*0.057
			heroColorX := WinWidth*0.026
			heroColorY := WinHeight*0.073
			if(WinWidth !=1440){
				Progress, B X0 ZHn0 CW272822 CT60D9EF,- WARNING - `n This script is untested on your current resolution so it might misfunction. Please tell AFK on core#0614 what resolution you're using. Thanks.
				Sleep, 7500
				Progress, OFF
			}
		}
		if(WinWidth == 1920){ ;[1920x1200]
			phaseColorX:= 1845
			phaseColorY:= 65
			heroColorX := 55
			heroColorY := 95
			if(!fullscreenWindowed){
				phaseColorX:= phaseColorX+WinWidthWithTitle-WinWidth
				phaseColorY:= phaseColorY+WinHeightWithTitle-WinHeight
				heroColorX := heroColorX 
				heroColorY := heroColorY+(WinHeightWithTitle-WinHeight)/1.8
			}
		}
	}
	;16/9
	if(WinRatio == 7){ ;[1280x720] [1360x768] [1366x768]
		phaseColorY:= WinHeight* 0.099
		heroColorX := WinWidth*0.0285
		heroColorY := WinHeight*0.115
		if(WinWidth == 2560){ ;Dirty fix for [2560x1440]
			phaseColorX:= 2475
			phaseColorY:= 85
			heroColorX := 60
			heroColorY := 105
		}
	}
	if(WinWidth == 1920 && WinHeight == 1080){ ;Dirty fix for [1920x1080]
		phaseColorX:= 1850
		phaseColorY:= 60
		heroColorX := 45
		heroColorY := 80
	}
	;21/9
	if(SubStr(WinWidth/WinHeight,1,3) == 2.3){
		phaseColorY:= WinHeight*0.0574
		heroColorX := WinWidth*0.0156 
		heroColorY := WinHeight*0.077
		if(!fullscreenWindowed){
				phaseColorX:= phaseColorX+WinWidthWithTitle-WinWidth
				phaseColorY:= phaseColorY+WinHeightWithTitle-WinHeight
				heroColorX := heroColorX 
				heroColorY := heroColorY+(WinHeightWithTitle-WinHeight)/1.8
			}
	}

	if(DEBUG){ ;Display game's resolution & position in DEBUG mode
		Progress, B X0 ZHn0 CW272822 CT60D9EF,= DEBUG MODE = `n x%WinX% y%WinY% [%WinWidth%x%WinHeight%]`n`nTurn it off by editing script line 5
		Sleep, 750
		Progress, OFF
		DisplayInventoryBorder()
	}	
}
PixelColorSimple(pc_x, pc_y){ ;Gets pixel color even if the window is in background ;Thanks to Lexikos https://github.com/Lexikos/AutoHotkey_L
	global WinID
	pc_wID:= WinID
    if (pc_wID) {
        pc_hDC := DllCall("GetDC", "UInt", pc_wID)
        pc_fmtI := A_FormatInteger
        SetFormat, IntegerFast, Hex
        pc_c := DllCall("GetPixel", "UInt", pc_hDC, "Int", pc_x, "Int", pc_y, "UInt")
        pc_c := pc_c >> 16 & 0xff | pc_c & 0xff00 | (pc_c & 0xff) << 16
        pc_c .= ""
        SetFormat, IntegerFast, %pc_fmtI%
        DllCall("ReleaseDC", "UInt", pc_wID, "UInt", pc_hDC)
		pc_c := "0x" SubStr("000000" SubStr(pc_c, 3), -5)
        return pc_c ;
    }
}

ActivateAutoG(){
	global autoG	
	global waitNextCombatPhase
	autoG := true
	test:=CheckPhaseColor()
	if(CheckPhaseColor() == "build"){
		G()
		waitNextCombatPhase := true
	}
	Progress,B zh0 fs18 CW272822 CT60D9EF W60,, G on.
	Sleep, 500
	Progress, OFF
}
G(){
	ControlSend,,{g down}, ahk_exe DDS-Win64-Shipping.exe
		SoundBeep, 450, 50
		Sleep, 370
	ControlSend,,{g up}, ahk_exe DDS-Win64-Shipping.exe

}
PopUp(){ ;Put the game in focus
	IfWinNotActive, ahk_exe DDS-Win64-Shipping.exe
	{
		WinActivate, ahk_exe DDS-Win64-Shipping.exe
	}
}

CheckPhaseColor(){ ; Check the color of the ribbon behind Build Phase/Combat Phase
	global WinX
	global WinY
	global WinWidth
	global phaseColorX
	global phaseColorY
	global DEBUG
	
	if(DEBUG){
		pX:= WinX+WinWidth-300
		Progress, 4:OFF
		Progress, 6:OFF
	}
	ColorCheck := PixelColorSimple(phaseColorX, phaseColorY)
	StringTrimLeft, ColorCheck, ColorCheck, 2
	R := Format("{:u}", "0x"+SubStr(ColorCheck, 1, 2))
	G := Format("{:u}", "0x"+SubStr(ColorCheck, 3, 2))
	B := Format("{:u}", "0x"+SubStr(ColorCheck, 5, 2))
	;Color : RGB value
	;pX:=phaseColorX+WinX
	pY:=phaseColorY+WinY
	if(DEBUG){
		vert := pY-4
		hor := phaseColorX+WinX-4
		Progress, 4:B X%hor% Y%pY% CW00FFFF H2 W9
		Progress, 6:B X%phaseColorX% Y%vert% CWFF0000 H9 W2 ;red
	}
	if(R<10 && G>75 && G<155 && B>120){
		if(DEBUG){
			Progress, 5:B Y0 cw%ColorCheck% ZHn0 W300 X%pX%,End of map (%R% %G% %B%) 
		}
		return "mapover"
	}else if(R>105 && R<168 && G>75 && G<125 && B<20){
		if(DEBUG){
			Progress, 5: B Y0 cw%ColorCheck% ZHn0 W300 H29 X%pX%,Warmup phase (%R% %G% %B%)
		}
		return "warmup"
	}else if(R>55 && R<85 && G>85 && G<140 && B<20){
		if(DEBUG){
			Progress, 5:B Y0 cw%ColorCheck% ZHn0 W300 H29 X%pX%,Build phase (%R% %G% %B%)
		}
		return "build"
	}else if(R>95 && R<185 && G>12 && G<30 && B>20 && B<45){
		if(DEBUG){
			Progress, 5:B Y0 cw%ColorCheck% ZHn0 W300 H29 X%pX%,Combat phase (%R% %G% %B%)
		}
		return "combat"
	}else if(R>120 && R<190 && G>65 && G<110){
		if(DEBUG){
			Progress, 5:B Y0 cw%ColorCheck% ZHn0 W300 H29 X%pX%,Tavern(%R% %G% %B%)
		}
		return "tavern"
	}else if(DEBUG){
		Progress, 5:B Y0 cw%ColorCheck% ctFFFFFF ZH0 W300 H29 X%pX%,No color match(%R% %G% %B%)
	}
}
CheckHeroColor(){ ;Check the color of the background behind the hero's head icon
	;/!\ TODO: Fix the weird bug with Windowed max res with DEBUG off
	global DEBUG
	global WinX
	global WinY
	global WinWidth
	global WinHeight
	global heroColorX
	global heroColorY
	
	if(DEBUG){
		pX := WinX
		Progress, 2:OFF
		Progress, 3:OFF
	}
	ColorCheck := PixelColorSimple(heroColorX, heroColorY)
	StringTrimLeft, ColorCheck, ColorCheck, 2
	R := Format("{:u}", "0x"+SubStr(ColorCheck, 1, 2))
	G := Format("{:u}", "0x"+SubStr(ColorCheck, 3, 2))
	B := Format("{:u}", "0x"+SubStr(ColorCheck, 5, 2))
	pX:=heroColorX+WinX
	pY:=heroColorY+WinY
	if(DEBUG){
		vert := pY-4
		hor := pX-4
		Progress, 2:B X%hor% Y%pY% CW00FFFF H2 W9
		Progress, 3:B X%pX% Y%vert% CWFF0000 H9 W2
	}
	if(R>12 && R<105 && G>60 && G<160&& B>99 && B<220){
		if(DEBUG){
			Progress, B X%pX% Y0 cw%ColorCheck% ZHn0,Apprentice (%R% %G% %B%)
		}
		return "apprentice"
	}else if(R>143 && R<245 && G>49 && G<120 && B>20 && B<50){
		if(DEBUG){
			Progress, B X%pX% Y0 cw%ColorCheck% ZHn0,Monk (%R% %G% %B%)
		}
		return "monk"
	}else if(R>106 && R<245 && G>20 && G<130 && B>20 && B<55){
		if(DEBUG){
			Progress, B X%pX% Y0 cw%ColorCheck% ZHn0,Squire (%R% %G% %B%)
		}
		return "squire"
	}else if(G>60 && G<170 && B>39 && B<75){
		if(DEBUG){
			Progress, B X%pX% Y0 cw%ColorCheck% ZHn0,Huntress (%R% %G% %B%)
		}
		return "huntress"
	}else{
		if(DEBUG){
			Progress, B X%pX% Y0 cw%ColorCheck% ZHn0,No color match (%R% %G% %B%)
		}
	}
}

AutoFire(){ ;Trigger normal attack depending on class
	global DEBUG
	global boostKeybind
	
	hero := CheckHeroColor()
	If(hero == "apprentice" || hero == "huntress" || hero == "squire"){ 
		if(hero == "huntress"){
			ControlSend,,{%boostKeybind%}, ahk_exe DDS-Win64-Shipping.exe
		}
		ControlClick,, ahk_exe DDS-Win64-Shipping.exe,,,,D
		ControlSend,,{Enter}, ahk_exe DDS-Win64-Shipping.exe
		Sleep, 250
		ControlClick,, ahk_exe DDS-Win64-Shipping.exe,,,,U
		ControlSend,,{Enter}, ahk_exe DDS-Win64-Shipping.exe
		if(hero == "huntress"){
			Sleep, 5100
			ControlSend,,{%boostKeybind%}, ahk_exe DDS-Win64-Shipping.exe
		}
	}
	if(hero == "monk"){ 
		ControlClick,, ahk_exe DDS-Win64-Shipping.exe,,RIGHT,,D
		ControlSend,,{Enter}, ahk_exe DDS-Win64-Shipping.exe
		Sleep, 250
		ControlClick,, ahk_exe DDS-Win64-Shipping.exe,,RIGHT,U
	}
}

ActivateAbilitySpam(){
	global abilitySpamToggle
	global abilityKeybind
	global abilityTimer
	abilitySpamToggle:= !abilitySpamToggle

	if(CheckHeroColor() == "monk"){
		if(abilitySpamToggle){
			Progress, 10: B zh0 fs18 CW272822 CT60D9EF W215,, Spam Tower Boost (%abilityKeybind%): ON
			AbilitySpam()
			Sleep, 400
		}else{
			Progress, 10:B zh0 fs18 CW272822 CT60D9EF W190,, Spam Tower Boost: OFF
			Sleep, 200
		}
		Progress, 10: OFF
	}
}
AbilitySpam(){ ;Spam right click on apprentice, towerboost on monk
	global DEBUG
	global abilityKeybind
	global abilityTimer
	global abilitySpamToggle
	hero := CheckHeroColor()
	if(0){ ;hero == "apprentice"){ ;Spam right click on apprentice
		Loop{
			ControlClick,, ahk_exe DDS-Win64-Shipping.exe,,RIGHT,,D
			Sleep, 50
			ControlClick,, ahk_exe DDS-Win64-Shipping.exe,,RIGHT,U
			Sleep, 250
		}
	}
	if(hero == "monk"){ ;Spam tower boost
		if(A_TickCount>abilityTimer){
			if(CheckPhaseColor() !="combat"){
				return
			}
			ControlSend,,{%abilityKeybind%}, ahk_exe DDS-Win64-Shipping.exe
			useEvery := 20100
			abilityTimer := A_TickCount+useEvery
		}
	}
}

SellMouseOver(){
	global DEBUG
	global WinWidth
	global WinHeight	
	ColorCheck := PixelColorSimple(WinWidth*0.942, WinHeight*0.946)
	StringTrimLeft, ColorCheck, ColorCheck, 2
	R := Format("{:u}", "0x"+SubStr(ColorCheck, 1, 2))
	G := Format("{:u}", "0x"+SubStr(ColorCheck, 3, 2))
	B := Format("{:u}", "0x"+SubStr(ColorCheck, 5, 2))
	if(R>70 && R<80 && G>75 && G<86 && B>130 && B<150 || R>30 && R<50 && G>30 && G<50 && B>70 && B<80){ ;check if the inventory is open by looking at the Equip button color
		MouseGetPos, mX, mY
		ControlClick,x%mX% y%mY%, ahk_exe DDS-Win64-Shipping.exe,,RIGHT
		Sleep, 75
		ControlSend,,{Up down}, ahk_exe DDS-Win64-Shipping.exe
		Sleep, 75
		ControlSend,,{Up up}, ahk_exe DDS-Win64-Shipping.exe
		Sleep, 50
		if(!DEBUG){
			ControlSend,,{Enter}, ahk_exe DDS-Win64-Shipping.exe
		}
		Sleep, 100
	}
}
LockMouseOver(){
	global DEBUG
	global WinWidth
	global WinHeight	
	ColorCheck := PixelColorSimple(WinWidth*0.942, WinHeight*0.946)
	StringTrimLeft, ColorCheck, ColorCheck, 2
	R := Format("{:u}", "0x"+SubStr(ColorCheck, 1, 2))
	G := Format("{:u}", "0x"+SubStr(ColorCheck, 3, 2))
	B := Format("{:u}", "0x"+SubStr(ColorCheck, 5, 2))
	if(R>70 && R<80 && G>75 && G<86 && B>65 && B<85 || R>30 && R<50 && G>30 && G<50 && B>70 && B<80){ ;check if the inventory is open by looking at the Equip button color
		MouseGetPos, mX, mY
		ControlClick,x%mX% y%mY%, ahk_exe DDS-Win64-Shipping.exe,,RIGHT
		Sleep, 10
		ControlSend,,{Up 2}, ahk_exe DDS-Win64-Shipping.exe
		Sleep, 10
		if(!DEBUG){
			ControlSend,,{Enter}, ahk_exe DDS-Win64-Shipping.exe
		}
	}
}
DisplayInventoryBorder(){ ;used for DEBUG
	global DEBUG
	global WinWidth
	global WinHeight	
	invColor := PixelColorSimple(WinWidth*0.942, WinHeight*0.946)
	if(!DEBUG){ 
		return
	}
		pX := WinWidth*0.942
		pY := WinHeight*0.946
		vert := pY-4
		hor := pX-4
		Progress, 10:B X%hor% Y%pY% CW00FFFF H2 W9
		Progress, 9:B X%pX% Y%vert% CWFF0000 H9 W2 
	ColorCheck := PixelColorSimple(WinWidth*0.942, WinHeight*0.946)
	StringTrimLeft, ColorCheck, ColorCheck, 2
	R := Format("{:u}", "0x"+SubStr(ColorCheck, 1, 2))
	G := Format("{:u}", "0x"+SubStr(ColorCheck, 3, 2))
	B := Format("{:u}", "0x"+SubStr(ColorCheck, 5, 2))	
	pX:= WinWidth-50
	pY:= WinHeight-75
	Progress, 8:B Y%pY% cw%ColorCheck% ctFFFFFF ZHn0 W40 H55 fs11 X%pX%,%R%`n%G%`n%B%
	return
	
}
Update(){
	t:=A_TickCount ;/add a number at the end of the URL to avoid caching issues
	versionURL := "https://raw.githubusercontent.com/AFKoncore/DDS/master/lastVersionNumber?t="%t%
	downloadURL:= "https://raw.githubusercontent.com/AFKoncore/DDS/master/DDS.ahk?t="%t%
	global v
	ErrorLevel := 0
	hObject:=ComObjCreate("WinHttp.WinHttpRequest.5.1") ;Create the Object
	hObject.Open("GET",versionURL) ;Open communication
	hObject.Send() ;Send the "get" request
	;newVer:=subStr(hObject.ResponseText,1,6) 
	newVer:=StrSplit(hObject.ResponseText, ":")
	if(newVer.1>v && ErrorLevel==0){
		MsgBox,4,Update, A new version of the script is available. Would you like to downlod it?
		IfMsgBox, Yes
			doTheUpdate := true
		if(doTheUpdate){
			UrlDownloadToFile, %downloadURL%, %A_ScriptName%
						changelog:= StrSplit(newVer.2, "|")
			changelog:= changelog.1
			MsgBox,Changelog:%changelog%
			Reload
		}
	}
}
