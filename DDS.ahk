;Download https://www.autohotkey.com/download/ahk-install.exe to use this script.
;Made by AFK on core#0614 , message me on discord if you need anything or have suggestions!
v:=200903 ;Script version, yearmonthday
;#####vvvSETTINGS#### 
DEBUG:=0
readColorInBackground:=1 
boostKeybind:="c"
abilityKeybind:="f"
dropManaKeybind:="m"
beepSoundOnG:=0
AutoFocusTheGame:=1
GAtWarmUpPhase:=1
PressSpaceOnLoading:=1
DropManaAtBuildPhase:=0
GenieOnAppBoost:=0
;####^^^SETTINGS#### 
;About readColorInBackground: the script reads colors on screen to know current game phase and hero being played. 
;  If you're having issues turn on DEBGUG:=1 (or use Ctrl+Alt+D) to check what the script is reading and if coordinates are correct.
;  Default is 1 and will read from the game's window even in background, but that way is not working for some people. 
;  0 will read the color from screen and should work everytime, but you need to keep the top right corner of the game's window visible on screen.
;
#SingleInstance Force
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
	global hero
	global phase
	global autoG
	;
	phase := CheckPhaseColor() ;get the color of the ribbon top right of the screen to know the current phase
	hero := CheckHeroColor() 
	;
	if(phase == "warmup" && !waitNextCombatPhase){
		waitNextCombatPhase := true ;Wait wave2 to press G as to not screw up the first build phase
		if(GAtWarmUpPhase){
			G()
		}else if(AutoFocusTheGame){
			PopUp()
		}	
	}else if(phase == "build"){
		if(DropManaAtBuildPhase){
				ControlSend,,{%dropManaKeybind% down}, ahk_exe DDS-Win64-Shipping.exe
				Sleep, 550
				ControlSend,,{%dropManaKeybind% up}, ahk_exe DDS-Win64-Shipping.exe
		}
		if(!waitNextCombatPhase){
			if(autoG){
				G() ;Press G, works even if DDA is in background
			}else if(AutoFocusTheGame){
				PopUp() ;Will put the game in front at build phase if you tab out without activating autoG
			}
			waitNextCombatPhase := true	
		}	
	}else if(phase == "combat" || phase == "tavern"){	
		waitNextCombatPhase := false
		if(abilitySpamToggle){
			AbilitySpam(hero)
		}
	}else if(phase == "loading"){
		if(PressSpaceOnLoading){
			ControlSend,,{Space}, ahk_exe DDS-Win64-Shipping.exe
		}
	}
	if(phase == "mapover" && !mapFinished){
		mapFinished := true
		IfWinNotActive, ahk_exe DDS-Win64-Shipping.exe
			PopUp()
	}else if(phase == "combat" || phase == "build" || phase == "warmup"){
		mapFinished := false
	}
	;
	Gui()
	;
	sleepTime := 1000
	if(abilitySpamToggle && phase == "combat" && A_TickCount+sleepTime > abilityTimer){ ;If the ability is to be used soon it will wait for a shorter amount of time
		sleepTime := abilityTimer-A_TickCount
	}	
	Sleep, sleepTime
}

; Keybinds
~F8:: Reload ;Restart fresh, use it to stop AbilitySpam
^g:: ;Ctrl+G and F9 both activate auto G
~F9:: ActivateAutoG()
#ifWinActive, ahk_exe DDS-Win64-Shipping.exe
F6:: Click ;  LockMouseOver() ;Lock item under your cursor
~^LButton:: ;Ctrl+Click or F10 to AutoFire
F10:: AutoFire() ;Auto attack depending on current hero
^RButton::
F11:: ActivateAbilitySpam() ;AbilitySpam() ;Spam right click on apprentice or tower boost on Monk (make sure abilityKeybind [line 9] is set the correct key)
^!d:: ToggleDebug() ;Ctrl+Alt+D

Gui(){ ;Display a little status windows with a button to open settings
	return ;Work in Progress
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
	global readColorInBackground
	global phaseColorX
	global phaseColorY
	
	autoG := !autoG
	Gui()
	if(autoG){
		if(CheckPhaseColor() == "build"){
			G()
			waitNextCombatPhase := true
		}
		if(readColorInBackground){
			Progress,B zh0 fs18 CW272822 CT7CFC00 W65,, G ON.
			Sleep, 500
			Progress, OFF
		}else{ ;Display a warning when reading color on screen (and not from the window even if background)
		pX := phaseColorX-355
		pY := phaseColorY-15
		Progress, B M zh0 X%pX% Y%pY% CW272822 CT60D9EF W350,Will press G once if this area is green --> `So keep it visible on screen.
		pX := phaseColorX-5
		pY := phaseColorY-5
		Progress, 10:B M zh0 CW60D9EF X%pX% Y%pY% W1 H10
		pX := phaseColorX+5
		pY := phaseColorY-5
		Progress, 9:B M zh0 CW60D9EF X%pX% Y%pY% W1 H10
		pX := phaseColorX-5
		pY := phaseColorY+5
		Progress, 8:B M zh0 CW60D9EF X%pX% Y%pY% W10 H1
		pX := phaseColorX-5
		pY := phaseColorY-5
		Progress, 7:B M zh0 CW60D9EF X%pX% Y%pY% W10 H1
		;/---
		pX := phaseColorX-8
		pY := phaseColorY-8
		Progress, 6:B M zh0 CWW272822 X%pX% Y%pY% W3 H14
		pX := phaseColorX+6
		pY := phaseColorY-8
		Progress, 5:B M zh0 CWW272822 X%pX% Y%pY% W3 H14
		pX := phaseColorX-8
		pY := phaseColorY+6
		Progress, 4:B M zh0 CWW272822 X%pX% Y%pY% W17 H3
		pX := phaseColorX-8
		pY := phaseColorY-8
		Progress, 3:B M zh0 CWW272822 X%pX% Y%pY% W14 H3
		Sleep, 2500
		Progress, OFF
		Progress, 10: OFF
		Progress, 9: OFF
		Progress, 8: OFF
		Progress, 7: OFF
		Progress, 6: OFF
		Progress, 5: OFF
		Progress, 4: OFF
		Progress, 3: OFF
		}
	}else{
		Progress,B zh0 fs18 CW272822 CTDC143C W70,, G OFF.
		Sleep, 500
		Progress, OFF
	}
}

G(){
	global beepSoundOnG
	ControlSend,,{g down}, ahk_exe DDS-Win64-Shipping.exe
		if(beepSoundOnG){
			SoundBeep, 450, 50
			Sleep, 370
		}else{
			Sleep, 420
		}
	ControlSend,,{g up}, ahk_exe DDS-Win64-Shipping.exe

}

PopUp(){ ;Put the game in focus
	IfWinNotActive, ahk_exe DDS-Win64-Shipping.exe
	{
		WinActivate, ahk_exe DDS-Win64-Shipping.exe
	}
}

CheckPhaseColor(){ ; Check the color of the ribbon behind Build Phase/Combat Phase
	global readColorInBackground
	global WinX
	global WinY
	global WinWidth
	global phaseColorX
	global phaseColorY
	global DEBUG
	
	pX:= WinX+WinWidth-300
	Progress, 4:OFF
	Progress, 5:OFF
	Progress, 6:OFF
	
	if(readColorInBackground){
		ColorCheck := PixelColorSimple(phaseColorX, phaseColorY)
	}else{
		PixelGetColor, ColorCheck, phaseColorX, phaseColorY, RGB 
	}
	StringTrimLeft, ColorCheck, ColorCheck, 2
	R := Format("{:u}", "0x"+SubStr(ColorCheck, 1, 2))
	G := Format("{:u}", "0x"+SubStr(ColorCheck, 3, 2))
	B := Format("{:u}", "0x"+SubStr(ColorCheck, 5, 2))
	;Color : RGB value
	
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
	}else if(R>140 && R<180 && G>80 && G<150 && B<20){
		if(DEBUG){
			Progress, 5: B Y0 cw%ColorCheck% ZHn0 W300 H29 X%pX%,Warmup phase (%R% %G% %B%)
		}
		return "warmup"
	}else if(R>55 && R<85 && G>85 && G<150 && B<20){
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
			Progress, 5:B Y0 cw%ColorCheck% ZHn0 W300 H29 X%pX%,Tavern (%R% %G% %B%)
		}
		return "tavern"
	}else if(R>120 && R<190 && G>20 && G<60 && B<10){
		if(DEBUG){
			Progress, 5:B Y0 cw%ColorCheck% ZHn0 W300 H29 X%pX%,Loading (%R% %G% %B%)
		}
		return "loading"
	}else if(DEBUG){
		Progress, 5:B Y0 cw%ColorCheck% ctFFFFFF ZH0 W300 H29 X%pX%,No color match (%R% %G% %B%)
	}
}

CheckHeroColor(){ ;Check the color of the background behind the hero's head icon
	;/!\ TODO: Fix the weird bug with Windowed max res with DEBUG off
	global readColorInBackground
	global DEBUG
	global WinX
	global WinY
	global WinWidth
	global WinHeight
	global heroColorX
	global heroColorY
	
	pX := WinX	
	Progress, OFF
	Progress, 2:OFF
	Progress, 3:OFF
	
	if(readColorInBackground){	
		ColorCheck := PixelColorSimple(heroColorX, heroColorY)
	}else{
		PixelGetColor, ColorCheck, heroColorX, heroColorY, RGB 
	}
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
	if(R<20 && G>60 && G<160&& B>99 && B<220){
		if(DEBUG){
			Progress, B X%WinX% Y0 cw%ColorCheck% ZHn0,Apprentice (%R% %G% %B%)
		}
		return "apprentice"
	}else if(R>143 && R<245 && G>49 && G<120 && B>20 && B<50){
		if(DEBUG){
			Progress, B X%WinX% Y0 cw%ColorCheck% ZHn0,Monk (%R% %G% %B%)
		}
		return "monk"
	}else if(R>106 && R<245 && G<25 && B<25){
		if(DEBUG){
			Progress, B X%WinX% Y0 cw%ColorCheck% ZHn0,Squire (%R% %G% %B%)
		}
		return "squire"
	}else if(G>60 && G<170 && B>39 && B<75){
		if(DEBUG){
			Progress, B X%WinX% Y0 cw%ColorCheck% ZHn0,Huntress (%R% %G% %B%)
		}
		return "huntress"
	}else if(R>100 && R<140 && G>10 && G<40 && B>170 && B<200){
		if(DEBUG){
			Progress, B X%WinX% Y0 cw%ColorCheck% ZHn0,Series EV-A (%R% %G% %B%)
		}
		return "ev"
	}else{
		if(DEBUG){
			Progress, B X%WinX% Y0 cw%ColorCheck% ZHn0,No color match (%R% %G% %B%)
		}
	}
}

AutoFire(){ ;Trigger normal attacks depending on class
	global DEBUG
	global boostKeybind
	sleep, 250 ;wait a bit to avoid MouseUp event from the real mouse in case it was activated using Ctrl+Click
	hero := CheckHeroColor()
	If(hero == "apprentice" || hero == "huntress" || hero == "squire"|| hero == "ev"){ 
		ControlClick,, ahk_exe DDS-Win64-Shipping.exe,,,,D
	}
	if(hero == "monk"){ 
		ControlClick,, ahk_exe DDS-Win64-Shipping.exe,,RIGHT,,D
	}
}

ActivateAbilitySpam(){
	global abilitySpamToggle
	global abilityKeybind
	
	abilitySpamToggle:= !abilitySpamToggle
	Gui()
	hero := CheckHeroColor()
	
	if(hero == "monk"){
		if(abilitySpamToggle){
			Progress, 10: B zh0 fs18 CW272822 CT7CFC00 W215,, Spam Tower Boost (%abilityKeybind%): ON
			AbilitySpam(hero)
			Sleep, 400
		}else{
			Progress, 10:B zh0 fs18 CW272822 CTDC143C W190,, Spam Tower Boost: OFF
			Sleep, 200
		}
		Progress, 10: OFF
	}else if(hero == "apprentice"){
		if(abilitySpamToggle){
			Progress, 10: B zh0 fs18 CW272822 CT7CFC00 W165,, Spam right click: ON
			AbilitySpam(hero)
			Sleep, 400
		}else{
			Progress, 10:B zh0 fs18 CW272822 CTDC143C W170,, Spam right click: OFF
			Sleep, 200
		}
		Progress, 10: OFF	
	}else if(hero == "squire"){
	if(abilitySpamToggle){
			Progress, 10: B zh0 fs18 CW272822 CT7CFC00 W130,, Hold Block: ON
			AbilitySpam(hero)
			Sleep, 400
		}else{
			Progress, 10:B zh0 fs18 CW272822 CTDC143C W135,, Hold Block: OFF
			ControlClick,, ahk_exe DDS-Win64-Shipping.exe,,RIGHT,,U
			Sleep, 200
		}
		Progress, 10: OFF
	}
}

AbilitySpam(hero){ ;Spam right click on apprentice, towerboost on monk
	global DEBUG
	global abilityKeybind
	global boostKeybind
	global abilityTimer
	global abilitySpamToggle
	global GenieOnAppBoost

	if(A_TickCount < abilityTimer){
		return
	}
	
	if(hero == "monk"){ ;Spam tower boost
		ControlSend,,{%abilityKeybind%}, ahk_exe DDS-Win64-Shipping.exe
		useEvery := 20100
		abilityTimer := A_TickCount+useEvery
	}
	
	if(hero == "apprentice"){ ;Spam right click on apprentice
			if(GenieOnAppBoost){ ;got genie
				ControlClick,, ahk_exe DDS-Win64-Shipping.exe,,RIGHT,,D
				Sleep, 150
				ControlClick,, ahk_exe DDS-Win64-Shipping.exe,,RIGHT,U
				Sleep, 250
				useEvery := 7650
				abilityTimer := A_TickCount+useEvery
			}else{ ;no genie - sad
				ControlSend,,{ %boostKeybind% down}, ahk_exe DDS-Win64-Shipping.exe
				Sleep, 100
				ControlSend,,{%boostKeybind% up}, ahk_exe DDS-Win64-Shipping.exe
				Sleep, 1100
				ControlClick,, ahk_exe DDS-Win64-Shipping.exe,,RIGHT,,D
				Sleep, 150
				ControlClick,, ahk_exe DDS-Win64-Shipping.exe,,RIGHT,U
				Sleep, 850
				ControlSend,,{%boostKeybind% down}, ahk_exe DDS-Win64-Shipping.exe
				Sleep, 100
				ControlSend,,{%boostKeybind% up}, ahk_exe DDS-Win64-Shipping.exe
				useEvery := 6500
				abilityTimer := A_TickCount+useEvery
			}
	}
	
	if(hero == "squire"){ ;Hold block, and refresh holding block twice a second in case it drops
		ControlClick,, ahk_exe DDS-Win64-Shipping.exe,,RIGHT,,D		
		useEvery := 500
		abilityTimer := A_TickCount+useEvery
	}
}

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
	
	;Set coordinate to check for with CheckHeroColor() and CheckPhaseColor 
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
	}	
	;if(WinHeight == 2160){ ;Dirty fix for 4k
	;	phaseColorX := 3955
	;	phaseColorY:= 130
	;	heroColorX := 85
	;	heroColorY := 165	
	;}
	if(WinWidth == 3840 && WinHeight == 2160) { ;Fix for [3840x2160], thanks betagan
        phaseColorX:= 3700
        phaseColorY:= 120
        heroColorX := 90
        heroColorY := 160
    }
}

ToggleDebug(){
	global DEBUG:=!DEBUG
}

;#Script self-editing
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
		MsgBox,4,Update, A new version of the script is available. Would you like to download it?
		IfMsgBox, Yes
			doTheUpdate := true
		if(doTheUpdate){
			UrlDownloadToFile, %downloadURL%, %A_ScriptName%
			SaveSettingsToFile() ;Import current settings
			changelog:= StrSplit(newVer.2, "|")
			changelog:= changelog.1
			MsgBox,Changelog:%changelog%
			Reload
		}
	}
}

SaveSettingsToFile(){
	return ;work in progress
}
