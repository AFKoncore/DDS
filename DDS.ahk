;Download https://www.autohotkey.com/download/ahk-install.exe to use this script.
;Made by AFK on core#0614 , message me on discord if you need anything or have suggestions!
v:=200314 ;Script version, yearmonthday
;###SETTINGS: (Change to false or 0 to disable option)
DEBUG := 0 ;Change it to false to turn off the annoying windows

boostKeybind:= "c" ;What key do you press to activate your boost (default is "c")
abilityKeybind:= "f" ;What key do you press to activate your first ability (default is "f")
sellFirstItemWarning := true 
sellMouseOverWarning := false
;___
;TODO: error log. wait 2 buildphase after warmup?. close chat before G. Spam repair at build phase? Read wave number at PopUp() at wave14. Fix chacing issue with update(). warning if unsupported res

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
	}	
	if(!DEBUG){
		Sleep, 5000	
		if(actionTaken){
			Sleep, 114*1000 ;Will loop faster if in debug mode
			actionTaken := false
		}
	}else{ ;Display various debug information
		CheckHeroColor() 
		DisplayInventoryBorder()
		Sleep, 750
		if(actionTaken){
			Sleep, 10*1000
			actionTaken := false
		}
	}
}
~F8:: Reload ;Restart fresh, use it to stop AutoCharge
^g:: ;Ctrl+G and F9 both activate auto G
~F9:: ActivateAutoG()
#ifWinActive, ahk_exe DDS-Win64-Shipping.exe
~s:: ;S to sell, L to lock item under cursor
F5:: SellMouseOver() ;Sells item under your cursor
~l:: LockMouseOver() ;Lock item under your cursor
F6:: SellFirstItem() ;Sells top left item of the inventory
F7:: ;Log() ;create a .txt with a line of information about the cursor pos
~^LButton:: ;Ctrl+Click or F10 to AutoFire
F10:: AutoFire() ;Auto attack depending on current hero
F11:: AutoCharge() ;Spam right click on apprentice or tower boost on Monk (make sure abilityKeybind [line 9] is set the correct key)

Setup(){ ;Get game resolution and calculate various X/Y coordinates  ;!\ issues with 1280x1024
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
	global invMinX
	global invMinY
	global invMaxX
	global invMaxY
	
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
	if(A_ScreenWidth==WinWidth && A_ScreenHeight==WinHeight){
		if(WinX==0 && WinY==0){
			fullscreenWindowed := true
		}
	}
	
	;Set coordinate to check for with CheckHeroColor(), CheckPhaseColor and the expected items' position in the inventory
	phaseColorX := WinWidth*0.97 ;Same X coord for all screen ratio	
	heroColorX := WinWidth*0.03
	;4/3
	if(WinRatio == 3){ ;[1024x768] [1152x864] [1280x960]
		phaseColorY := WinHeight*0.0945 
		heroColorX := WinWidth*0.039
		heroColorY := WinHeight*0.111
		invMinX := WinWidth*0.453
		if(SubStr(WinWidth/WinHeight,4,1) == 9){ ;[1280x960]
			invMinX := WinWidth*0.47
		}
		invMaxX := WinWidth*0.975
		invMinY := WinHeight*0.366
		invMaxY := WinHeight*0.860
	}
	;16/10
	if(WinRatio == 6){
		if(WinWidth == 1280){ ;[1280x800] [1280x768]
			phaseColorY := WinHeight*0.097 
			heroColorY := WinHeight*0.112
			invMinX := WinWidth*0.527
			if(SubStr(WinWidth/WinHeight,4,1) == 6){ ;[1280x768]
				invMinX := WinWidth*0.543
			}
			invMaxX := WinWidth*0.960
			invMinY := WinHeight*0.368
			invMaxY := WinHeight*0.863
		}else{ ;[1440x900]
			phaseColorX := WinWidth*0.964
			phaseColorY := WinHeight*0.057
			heroColorX := WinWidth*0.026
			heroColorY := WinHeight*0.073
			invMinX := WinWidth*0.522
			invMaxX := WinWidth*0.957
			invMinY := WinHeight*0.330		
			invMaxY := WinHeight*0.826
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
			invMinX := 1005
			invMaxX := 1840
			invMinY := 395
			invMaxY := 990
			if(!fullscreenWindowed){
				phaseColorX:= phaseColorX+WinWidthWithTitle-WinWidth
				phaseColorY:= phaseColorY+WinHeightWithTitle-WinHeight
				heroColorX := heroColorX 
				heroColorY := heroColorY+(WinHeightWithTitle-WinHeight)/1.8
				invMinX := invMinX+(WinWidthWithTitle-WinWidth)/2
				invMaxX := invMaxX+(WinWidthWithTitle-WinWidth)/2
				invMinY := invMinY+20+(WinHeightWithTitle-WinHeight)/2-(WinWidthWithTitle-WinWidth)/2
				invMaxY := invMaxY+20+(WinHeightWithTitle-WinHeight)/2-(WinWidthWithTitle-WinWidth)/2
			}
		}
	}
	;16/9
	if(WinRatio == 7){ ;[1280x720] [1360x768] [1366x768]
		phaseColorY:= WinHeight* 0.099
		heroColorX := WinWidth*0.0285
		heroColorY := WinHeight*0.115
		invMinX := WinWidth*0.566
		invMaxX := WinWidth*0.960
		invMinY := WinHeight*0.371
		invMaxY := WinHeight*0.865
		if(WinWidth == 2560){ ;Dirty fix for [2560x1440]
			phaseColorX:= 2475
			phaseColorY:= 85
			heroColorX := 60
			heroColorY := 105
			invMinX := 1435
			invMaxX := 2440
			invMinY := 475
			invMaxY := 1190
		}
	}
	if(WinWidth == 1920 && WinHeight == 1080){ ;Dirty fix for [1920x1080]
		phaseColorX:= 1850
		phaseColorY:= 60
		heroColorX := 45
		heroColorY := 80
		invMinX := 1080
		invMaxX := 1830
		invMinY := 360
		invMaxY := 860
	}
	;Adjust coordinate to window's position if windowed
	if(WinX>0){
		;phaseColorX := WinX+phaseColorX
		;heroColorX := WinX+heroColorX
		invMinX := invMinX+WinX
		invMaxX := invMaxX+WinX
	}
	if(WinY>0){
		;phaseColorY := WinY+phaseColorY
		;heroColorY := WinY+heroColorY
		invMinY := invMinY+WinY
		invMaxY := invMaxY+WinY
	}

	if(DEBUG){ ;Display game's resolution & position in DEBUG mode
		;%A_ScreenWidth%x%A_ScreenHeight% (%monitorCount%)
		;MsgBox, Window Size: %WinWidthWithTitle%x%WinHeightWithTitle% Client Size:%WinWidth%x%WinHeight%
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
        return pc_c
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
	Sleep, 420
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
		Progress, 6:OFF
		Progress, 4:OFF
	}
	ColorCheck := PixelColorSimple(phaseColorX, phaseColorY)
	StringTrimLeft, ColorCheck, ColorCheck, 2
	R := Format("{:u}", "0x"+SubStr(ColorCheck, 1, 2))
	G := Format("{:u}", "0x"+SubStr(ColorCheck, 3, 2))
	B := Format("{:u}", "0x"+SubStr(ColorCheck, 5, 2))
	;Color : RGB value
	phaseColorX:=phaseColorX+WinX
	phaseColorY:=phaseColorY+WinY
	if(R>105 && R<168 && G>75 && G<125 && B<20){
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
	}else if(R<10 && G>50 && G<90 && B>95 && B<140){
		if(DEBUG){
			Progress, 5:B Y0 cw%ColorCheck% ZHn0 W300 H29 X%pX%,End of map (%R% %G% %B%)
		}
		return "mapover"
	}else if(R>52 && R<60 && G>45 && G<52 && B>82 && B<90){
		if(DEBUG){
			Progress, 5:B Y0 cw%ColorCheck% ZHn0 W300 H29 X%pX%,Inventory(%R% %G% %B%)
		}
		return "inventory"
	}else if(R>155 && R<190 && G>75 && G<110){
		if(DEBUG){
			Progress, 5:B Y0 cw%ColorCheck% ZHn0 W300 H29 X%pX%,Tavern(%R% %G% %B%)
		}
		return "tavern"
	}else if(DEBUG){
		Progress, 5:B Y0 cw%ColorCheck% ZHn0 W300 H29 X%pX%,No color match(%R% %G% %B%)
	}
	if(DEBUG){
		vert := phaseColorY-4
		hor := phaseColorX-4
		Progress, 6:B X%hor% Y%phaseColorY% CW00FFFF H2 W9
		Progress, 4:B X%phaseColorX% Y%vert% CWFF0000 H9 W2 ;red
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
	ppX:= heroColorX-5
	ppY:= heroColorY-5
pX := WinX
	if(DEBUG){
		Progress, 2:OFF
		Progress, 3:OFF
	}
	ColorCheck := PixelColorSimple(heroColorX, heroColorY)
	StringTrimLeft, ColorCheck, ColorCheck, 2
	R := Format("{:u}", "0x"+SubStr(ColorCheck, 1, 2))
	G := Format("{:u}", "0x"+SubStr(ColorCheck, 3, 2))
	B := Format("{:u}", "0x"+SubStr(ColorCheck, 5, 2))
	heroColorX:=heroColorX+WinX
	heroColorY:=heroColorY+WinY
	if(DEBUG){
		vert := heroColorY-4
		hor := heroColorX-4
		Progress, 2:B X%hor% Y%heroColorY% CW00FFFF H2 W9
		Progress, 3:B X%heroColorX% Y%vert% CWFF0000 H9 W2
	}
	if(R>12 && R<105 && G>86 && G<160&& B>132 && B<220){
		if(DEBUG){
			Progress, B X%pX% Y0 cw%ColorCheck% ZHn0,Apprentice (%R% %G% %B%)
		}
		return "apprentice"
	}else if(R>143 && R<240 && G>70 && G<120 && B>34 && B<50){
		if(DEBUG){
			Progress, B X%pX% Y0 cw%ColorCheck% ZHn0,Monk (%R% %G% %B%)
		}
		return "monk"
	}else if(R>106 && R<245 && G>20 && G<130 && B>20 && B<55){
		if(DEBUG){
			Progress, B X%pX% Y0 cw%ColorCheck% ZHn0,Squire (%R% %G% %B%)
		}
		return "squire"
	}else if(G>84 && G<170 && B>49 && B<75){
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
	If(hero == "apprentice" || hero == "huntress"){ 
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
	if(hero == "squire"){ 
		ControlClick,, ahk_exe DDS-Win64-Shipping.exe,,,,D
		Loop{ ;melee fast atk
			Sleep, 86
			ControlClick,, ahk_exe DDS-Win64-Shipping.exe,,RIGHT,
		}
	}
	
	if(0){ ;MONK
		Loop{ 
			ControlClick,, ahk_exe DDS-Win64-Shipping.exe,
			Sleep, 60
			ControlClick,, ahk_exe DDS-Win64-Shipping.exe,,RIGHT,	
			Sleep, 20
		}
	}
}
AutoCharge(){ ;Spam right click on apprentice, towerboost on monk
	global DEBUG
	global abilityKeybind
	hero := CheckHeroColor()
	If(hero == "apprentice"){ ;Spam right click on apprentice
		Loop{
			ControlClick,, ahk_exe DDS-Win64-Shipping.exe,,RIGHT,,D
			Sleep, 225
			ControlClick,, ahk_exe DDS-Win64-Shipping.exe,,RIGHT,U
			Sleep, 1000
		}
	}
	If(hero == "monk"){ ;Spam tower boost
		Loop{
			ControlSend,,{%abilityKeybind%}, ahk_exe DDS-Win64-Shipping.exe
			Sleep, 20100
			;Also check if not in build phase or inventory
		}
	}
}

SellFirstItem(){
	IfWinNotActive, ahk_exe DDS-Win64-Shipping.exe
	{
		return
	}
	global DEBUG
	global sellFirstItemWarning
	global invMinX
	global invMinY
	global invMaxX
	global invMaxY
	if(sellFirstItemWarning){
		Progress,B zh0 fs18 CW272822 CT60D9EF,, Press F6 again to sell the first item in your inventory.,Sorting by Item Power (Inverted) is recommanded.
		sellFirstItemWarning := false
		Sleep, 3250
		Progress, Off
	}else{
		ItemSize := (invMaxX-invMinX)/7
		;First item position on screen
		X:= invMinX+0.5*ItemSize
		Y:= invMinY+0.5*ItemSize
		;Sell button position
		X2:=X+ItemSize*0.78
		Y2:=Y+ItemSize*1.928
		If(DEBUG){
			MouseMove, X, Y
			Sleep, 250
			Click, Right
			Sleep, 350
			MouseMove, X2, Y2
		}else{
			ControlClick, x%X% y%Y%, ahk_exe DDS-Win64-Shipping.exe,,RIGHT
			Sleep, 175
			ControlClick, x%X2% y%Y2%, ahk_exe DDS-Win64-Shipping.exe
		}
	}
}
SellMouseOver(){
	if(CheckPhaseColor() != "inventory"){
		return
	}
	global DEBUG
	global sellMouseOverWarning
	global invMinX
	global invMinY
	global invMaxX
	global invMaxY
	if(sellMouseOverWarning){
			Progress,B zh0 fs18 CW272822 CT60D9EF,, Press F5 again to sell the item below your cursor
			sellMouseOverWarning := false
			Sleep, 2250
			Progress, Off
	}else{
		MouseGetPos, mX, mY
		if(mX>invMinX && mX<invMaxX && mY>invMinY && mY<invMaxY){
			ItemSize := (invMaxX-invMinX)/7
			slotX :=Floor((mX-invMinX)/ItemSize)+0.5
			slotY :=Floor((mY-invMinY)/ItemSize)+0.5
			;Item position on screen
			X:= invMinX+slotX*ItemSize
			Y:= invMinY+slotY*ItemSize
			;Sell button position
			X2:=X+ItemSize*0.90
			Y2:=Y+ItemSize*1.98
			
			If(DEBUG){
				MouseMove, X, Y
				Sleep, 250
				Click, Right
				Sleep, 350
				MouseMove, X2, Y2
			}else{
				ControlClick, x%X% y%Y%, ahk_exe DDS-Win64-Shipping.exe,,RIGHT
				Sleep, 175
				ControlClick, x%X2% y%Y2%, ahk_exe DDS-Win64-Shipping.exe
			}
		}
	}
}
LockMouseOver(){
	global DEBUG
	global sellMouseOverWarning
	global invMinX
	global invMinY
	global invMaxX
	global invMaxY
	if(CheckPhaseColor() != "inventory"){
		return
	}
	MouseGetPos, mX, mY
	if(mX>invMinX && mX<invMaxX && mY>invMinY && mY<invMaxY){
		ItemSize := (invMaxX-invMinX)/7
		slotX :=Floor((mX-invMinX)/ItemSize)+0.5
		slotY :=Floor((mY-invMinY)/ItemSize)+0.5
		;Item position on screen
		X:= invMinX+slotX*ItemSize
		Y:= invMinY+slotY*ItemSize
		;Lock button position
		X2:=X+ItemSize*0.90
		Y2:=Y+ItemSize*1.5
		
		If(DEBUG){
			MouseMove, X, Y
			Sleep, 250
			Click, Right
			Sleep, 350
			MouseMove, X2, Y2
		}else{
			ControlClick, x%X% y%Y%, ahk_exe DDS-Win64-Shipping.exe,,RIGHT
			Sleep, 175
			ControlClick, x%X2% y%Y2%, ahk_exe DDS-Win64-Shipping.exe
		}
	}
}
DisplayInventoryBorder(){ ;used for DEBUG
	global DEBUG
	global invMinX
	global invMinY
	global invMaxX
	global invMaxY
	global displayInv
	
	if(!DEBUG){
		return
	}
	
	if(CheckPhaseColor()=="inventory"){	
		if(!displayInv){
		pMinY := invMinY-4
		Progress, 6:B X%invMinX% Y%pMinY% CW00FFFF H4 W55
		pMinX := invMinX-4
		Progress, 9:B X%pMinX% Y%invMinY% CWFF0000 H55 W4
		pMaxX := invMaxX-55
		Progress, 8:B X%pMaxX% Y%invMaxY% CW00FFFF H4 W55
		pMaxY := invMaxY-55
		Progress, 7:B X%invMaxX% Y%pMaxY% CWFF0000 H55 W4
		pMinX := invMinX-4
		pMinY := invMinY-58
		Progress, 10: B Y%pMinY% X%invMinX%  ZH0 CW272822 CT60D9EF, Press F5 to try selling the item below your mouse
		displayInv := true
		}
	}else{
		Progress, 10: OFF
		Progress, 9: OFF
		Progress, 8: OFF
		Progress, 7: OFF
		Progress, 6: OFF
		displayInv := 
	}
}
Update(){
	versionURL := "https://raw.githubusercontent.com/AFKoncore/DDS/master/lastVersionNumber?fakeParam=42"
	downloadURL:= "https://raw.githubusercontent.com/AFKoncore/DDS/master/DDS.ahk"
	global v
	ErrorLevel := 0
	hObject:=ComObjCreate("WinHttp.WinHttpRequest.5.1") ;Create the Object
	hObject.Open("GET",versionURL) ;Open communication
	hObject.Send() ;Send the "get" request
	newVer:=subStr(hObject.ResponseText,1,6) ;Set the "text" variable to the response
	if(newVer>v&&ErrorLevel==0){
	msgbox, %newVer%>%v%
		MsgBox,4,Update, A new version of the script is available. Would you like to downlod it?
		IfMsgBox, Yes
			doTheUpdate := true
		if(doTheUpdate){
			UrlDownloadToFile, %downloadURL%, AFK on core.ahk
			Reload
		}
	}
}
Log(){
	global WinWidth
	global WinHeight
	; - - -
	WinRatio:= WinWidth/WinHeight ;SubStr(WinWidth/WinHeight,3,1)
	MouseGetPos, mX, mY
	mXP := Round(mX/WinWidth,3)
	mYP := Round(mY/WinHeight,3)
	; - - -
	if(1){
	FileAppend ,
	(
	
[%WinWidth%x%WinHeight%](%WinRatio%)
x%mX% y%mY% (%mXP% %mYP%)
	), AHK log.txt
	}
	if(0){
	MouseGetPos, mX, mY
	PixelGetColor, ColorCheck, mX, mY, RGB 
	StringTrimLeft, ColorCheck, ColorCheck, 2
	R := Format("{:u}", "0x"+SubStr(ColorCheck, 1, 2))
	G := Format("{:u}", "0x"+SubStr(ColorCheck, 3, 2))
	B := Format("{:u}", "0x"+SubStr(ColorCheck, 5, 2))
		FileAppend ,
	(
	
R:%R% G:%G% B:%B%
	), AHK log.txt
	}
}
