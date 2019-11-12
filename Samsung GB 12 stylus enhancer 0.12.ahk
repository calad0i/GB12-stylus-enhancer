	/*
	Developed based on https://github.com/jleb/AHKHID.
  Author Calad0i
	*/
  
  
	SendMode Input
	SetWorkingDir %A_ScriptDir%

	global MULTIPLE_CLICK_TIMEOUT := 170 ;in ms, from one up to next down
	global LONG_CLICK_TIMEOUT := 300 ;in ms, from last time button down
	global LONG_LONG_CLICK_TIMEOUT := 2000 ;in ms, recovery time from hibination
	global TIME_OUT_LONG := 50 ;These two are for CPU usage optimization. Bigger values for better performence, but greater delay the sametime.
	global TIME_OUT_SHORT := 20 	
	global TIME_OUT_HIBINATION := 200 ;CPU usage optmization when disabled.
	global tmp := 0
	global CurApp := 0
	
	#include AHKHID.ahk

	WM_INPUT := 0xFF
	USAGE_PAGE := 13
	USAGE := 2
	global WriteUpTrigered := 0
	global CtrlDown := 0
	global AltDown := 0
	global Enabled := 1
	AHKHID_UseConstants()
	AHKHID_AddRegister(1)
	AHKHID_AddRegister(USAGE_PAGE, USAGE, A_ScriptHwnd, RIDEV_INPUTSINK)
	AHKHID_Register()

	OnMessage(WM_INPUT, "Work")
	
	ResetKeys() {

	if (CtrlDown == 1) {
			SendInput, {CtrlUp} ;from hover long click count = 3
		}

	if (AltDown == 1) {
			SendInput, {AltUp} ;from hover long click count = 3
		}
	}
	
	GetCurApp() {
		StringCaseSense, On
		WinGetClass, Class, A
		if (Class == "sflRootWindow") {
			return 1
		} else if (Class == "BGI - Main window") {
			return -1
		}		
		if (Class == "Photoshop") {
			return 1
		}
/*
		if (Class == "CLIP STUDIO") {
			return 3
		}
	*/
		return 0
	}
	HoverLongClick(Count){
		static CtrlDown := 0
		if (Count == 4) {
				Enabled := 0
				MsgBox Stylus Enhancer Disabled
		}
		if (!CurApp) {
			if (Count == 1) {
				Click, right
			} else if (Count == 2) {
				SendInput, #e ;Explorer
			}
		} else if (CurApp > 0) {
			if(CurApp == 1) {
				if(Count == 2) {
					if(!CtrlDown) {
						if (AltDown) {
							SendInput, {CtrlDown}{AltDown}
						} else {
							SendInput, {CtrlDown}
						}
						CtrlDown := 1
					} else {
						SendInput, {CtrlUp}
						CtrlDown := 0
					}
				} else if (Count == 1) {
					SendInput, ^y
				}
			}
		} else {
			if(CurApp == -1) {
				if(Count == 1) {
					SendInput, {CtrlDown}
				} else if (Count == 2) {
					SendInput, {Space}
				}
			}
		}
	}
	HoverLongClickUp(Count) {
		if(!CurApp) {
			if (Count == 1) {
			}
		} else if (CurApp > 0) {
		} else {
			if (Count == 1) {
				SendInput, {CtrlUp}
			}
		}
	}
	HoverShortClickUp(Count){
		if (!CurApp) {
			if(Count == 1) {
				Click, left
			} else if (Count == 2) {
				Click, 2
			} else if (Count == 3) {
				SendInput, ^!L
			}
		} else if (CurApp > 0) {
			if(CurApp == 1){
				if(Count == 1) {
					SendInput, -
				} else if (Count == 2) {
					SendInput, ^z
				} else if (Count == 3) {
					if (AltDown) {
						SendInput, {AltUp}
						AltDown := 0
					} else {
						if (CtrlDown) {
							SendInput, {CtrlDown}{AltDown}
						} else {
							SendInput, {AltDown}
						}
						AltDown := 1
					}
				}
			}
		} else {
			if (CurApp == -1) {
				if (Count == 1) {
					Click
				} else if (Count == 2) {
					SendInput, {WheelUp}
				} else if (Count == 3) {
					SendInput, #{Tab} 
				}
			}
		}
	}
	
	
	HoverClickDown(){
	}

	ScreenWriteDown(Count){
		if (CurApp == 1) {
			if(Count == 1) {
				Click, up
				SendInput, {CtrlDown}
				Click, down
			}
		} else {
		}
	}
	
	ScreenWriteUp(Count){
		WriteUpTrigered := 1	
		if (CurApp == 1) {
			if(Count == 1) {
				SendInput, {CtrlUp}
			}
		} else {
			Click, right
		}
	}

	Work(wParam, lParam) {

		Local type, inputInfo, inputData, raw, State
		static LastState := 0
		static Timer := 0
		static DoubleDown := 0
		static ClickCount :=0
		static AltPen := 0 ;Holding the button before entering hovering region would disable all functions before releasing
		static LastSeen := 0
		Critical

		type := AHKHID_GetInputInfo(lParam, II_DEVTYPE)
		if (type = RIM_TYPEHID) {
			inputData := AHKHID_GetInputData(lParam, uData)

			raw := NumGet(uData, 0, "UInt")
				State := (raw >> 8) & 0x1F
							 
			if(Enabled == 0)
			{
				if (State == 8) {
					if (LastState == 0) {
						Timer := A_TickCount
					} else if (Timer) {
						if (A_TickCount - Timer > LONG_LONG_CLICK_TIMEOUT) {
							Enabled := 1
							Timer := 0
							MsgBox Stylus Enhancer Enabled
							return
						}
					}
				}
				LastState := State
				sleep TIME_OUT_HIBINATION
				return
			}
			
			CurApp := GetCurApp()
			
			if (!CurApp) {
				ResetKeys()
			}
			
			if (A_TickCount - LastSeen > 100) {	
				ClickCount := 0
				Timer := 0
				AltPen := State
			}
			
			LastSeen := A_TickCount

			if (AltPen)
			{
				sleep TIME_OUT_LONG *2
				return
			}
			
			if (State == LastState) {
				if (State == 8)
				{
					if (Timer) and (A_TickCount - Timer > LONG_CLICK_TIMEOUT) {
						HoverLongClick(ClickCount)
						Timer := 0
					} else {
						sleep TIME_OUT_SHORT
					}
				} else if (Timer) and (State == 0) {
					if (A_TickCount - Timer > MULTIPLE_CLICK_TIMEOUT) {
						HoverShortClickUp(ClickCount)
						Timer := 0
					}
						sleep TIME_OUT_LONG
				}
			} else {
				if (State == 8) {
					if (LastState == 0) { ;Press button in hover
						WriteUpTrigered := 0
						if(!Timer) {
							HoverClickDown()
							ClickCount := 0
						}
						tmp := 0
						ClickCount += 1
						Timer := A_TickCount
					}
				} else if (State == 0) { 
					if (LastState == 8) and (ClickCount) { ;Release button in hover
						if (!Timer) and (!WriteUpTrigered) {
							HoverLongClickUp(ClickCount)
							ClickCount := 0
						} else {
							tmp := 1
							Timer := A_TickCount
						}
					}
				} else if (State == 12) { ;Write on screen while button being pressed
					Timer := 0
					if (!ClickCount) {
						ClickCount := 1
					}
					ScreenWriteDown(ClickCount)
				}
				if (LastState == 12)
				{
					ScreenWriteUp(ClickCount)
					ClickCount := 0
				}
				LastState := State
			}
		}
	}

	 

