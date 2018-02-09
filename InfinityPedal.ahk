; Event Pump w/ Saved State for the Infinity 3-Pedal HID Input Device
; Current version by Cuyler Stuwe (salembeats).

; The majority of the code (the entirety of the lower-level code) was written by others and is credited below:

; Original script credit:
; http://musingsfromtheunderground.blogspot.com/2011/05/dream-autohotkey-powered-foot-pedal-for.html

; Credit for adapting to 64-bit AHK:
; https://autohotkey.com/board/topic/91506-broken-dllcall-to-registerrawinputdevices/?p=577346

; ============================================================================ ;
;                            PEDAL STATE VARIABLES.                            ;
; ============================================================================ ;

LastLeftPedalState := "Up"
LastMiddlePedalState := "Up"
LastRightPedalState := "Up"

; ============================================================================ ;
;                             EVENT PUMP SECTION.                              ;
; ============================================================================ ;

; ======  DOWN EVENTS  ======

onLeftDown() {
    ; Default behavior. Feel free to remove this to customize behavior.
    SendInput {CtrlDown}
}

onMiddleDown() {
    ; Default behavior. Feel free to remove this to customize behavior.
    SendInput {ShiftDown}
}

onRightDown() {
    ; Default behavior. Feel free to remove this to customize behavior.
    SendInput {AltDown}
}

; =======  UP EVENTS  =======

onLeftUp() {
    ; Default behavior. Feel free to remove this to customize behavior.
    SendInput {CtrlUp}
}

onMiddleUp() {
    ; Default behavior. Feel free to remove this to customize behavior.
    SendInput {ShiftUp}
}

onRightUp() {
    ; Default behavior. Feel free to remove this to customize behavior.
    SendInput {AltUp}
}

onLeftStateChange() {
}

onMiddleStateChange() {
}

onRightStateChange() {
}

; ============================================================================ ;
;   DON'T EDIT ANYTHING BELOW THIS LINE UNLESS YOU MEAN TO CHANGE THE SYSTEM.  ;
; ============================================================================ ;

LeftDown() {
    global LastLeftPedalState
    onLeftStateChange()
    onLeftDown()
    LastLeftPedalState := "Down"
}

MiddleDown() {
    global LastMiddlePedalState
    onMiddleStateChange()
    onMiddleDown()
    LastMiddlePedalState := "Down"
}

RightDown() {
    global LastRightPedalState
    onRightStateChange()
    onRightDown()
    LastRightPedalState := "Down"
}

LeftUp() {
    global LastLeftPedalState
    onLeftStateChange()
    onLeftUp()
    LastLeftPedalState := "Up"
}

MiddleUp() {
    global LastMiddlePedalState
    onMiddleStateChange()
    onMiddleUp()
    LastMiddlePedalState := "Up"
}

RightUp() {
    global LastRightPedalState
    onRightStateChange()
    onRightUp()
    LastRightPedalState := "Up"
}

OnMessage(0x00FF, "InputMessage")

USAGE_PAGE_FOOTPEDAL := 12
USAGE_FOOTPEDAL := 3

RegisterHIDDevice(USAGE_PAGE_FOOTPEDAL, USAGE_FOOTPEDAL) ; Register Foot Pedal

PedalLastPress := 0

Return

ProcessPedalInput(input)
{
    global PedalLastPress

    ; The input are combinations of 1, 2, 4 with 00 appended to the end
    ; indicating which pedals are pressed.
    ; For example, pressing the leftmost pedal triggers input 100, middle pedal 200, etc.
    ; all three pedals presses together will trigger 700 (1 ^ 2 ^ 4 = 7)
    ; Release of pedal trigger an input indicating what pedals are still held down

    input := input//100

    If (input > PedalLastPress)
    {
      PressKey((PedalLastPress & input) ^ input)
    }
    Else
    {
        ReleaseKey((PedalLastPress & input) ^ PedalLastPress)
    } 
    PedalLastPress := input
}

PressKey(bits)
{
    If (bits & 1)
        LeftDown()
    Else If (bits & 4)
        RightDown()
    Else
        MiddleDown()
}

ReleaseKey(bits)
{
    If (bits & 1)
        LeftUp()
    Else If (bits & 4)
        RightUp()
    else
        MiddleUp()
}

Mem2Hex( pointer, len )
{
    A_FI := A_FormatInteger
    SetFormat, Integer, Hex
    
    Loop, %len%  {
        Hex := *Pointer+0
        StringReplace, Hex, Hex, 0x, 0x0
        StringRight Hex, Hex, 2          
        hexDump := hexDump . hex
        Pointer ++
    }
    
    SetFormat, Integer, %A_FI%
    StringUpper, hexDump, hexDump
    
    Return hexDump
}
  
; Keyboards are always Usage Page 1, Usage 6, Mice are Usage Page 1, Usage 2.
; Foot pedal is Usage Page 12, Usage 3.
; HID devices specify their top level collection in the info block
RegisterHIDDevice(UsagePage,Usage)
{
    ; local RawDevice,HWND
    RIDEV_INPUTSINK := 0x00000100
    DetectHiddenWindows, on
    HWND := WinExist("ahk_class AutoHotkey ahk_pid " DllCall("GetCurrentProcessId"))
    DetectHiddenWindows, off

    VarSetCapacity(RawDevice, 8 + A_PtrSize)
    NumPut(UsagePage, RawDevice, 0, "UShort")
    NumPut(Usage, RawDevice, 2, "UShort")
    NumPut(RIDEV_INPUTSINK, RawDevice, 4, "UInt")
    NumPut(HWND, RawDevice, 8, "UPtr")

    Res := DllCall("RegisterRawInputDevices", "Ptr", &RawDevice, "UInt", 1, "UInt", 8 + A_PtrSize, "UInt")

    if (Res = 0)
    {
        MsgBox, Failed to register for HID Device
    }
}

InputMessage(wParam, lParam, msg, hwnd)
{
    RID_INPUT   := 0x10000003
    RIM_TYPEHID := 2
    SizeOfHeader := 8 + A_PtrSize + A_PtrSize
    SizeofRidDeviceInfo := 32
    RIDI_DEVICEINFO := 0x2000000b

    VENDOR_ID := 1523
    PRODUCT_ID := 255

    DllCall("GetRawInputData", "Ptr", lParam, "UInt", RID_INPUT, "Ptr", 0, "UIntP", Size, "UInt", SizeOfHeader, "UInt")
    VarSetCapacity(Buffer, Size)
    DllCall("GetRawInputData", "Ptr", lParam, "UInt", RID_INPUT, "Ptr", &Buffer, "UIntP", Size, "UInt", SizeOfHeader, "UInt")

    Type := NumGet(Buffer, 0 * 4, "UInt")
    Size := NumGet(Buffer, 1 * 4, "UInt")
    Handle := NumGet(Buffer, 2 * 4, "UPtr")

    VarSetCapacity(Info, SizeofRidDeviceInfo)
    NumPut(SizeofRidDeviceInfo, Info, 0)
    Length := SizeofRidDeviceInfo

    DllCall("GetRawInputDeviceInfo", "Ptr", Handle, "UInt", RIDI_DEVICEINFO, "Ptr", &Info, "UIntP", SizeofRidDeviceInfo)

    VendorID := NumGet(Info, 4 * 2, "UInt")
    Product := NumGet(Info, 4 * 3, "UInt")

    if (Type = RIM_TYPEHID)
    {
        SizeHid := NumGet(Buffer, (SizeOfHeader + 0), "UInt")
        InputCount := NumGet(Buffer, (SizeOfHeader + 4), "UInt")

        Loop %InputCount% {
            Addr := &Buffer + SizeOfHeader + 8 + ((A_Index - 1) * SizeHid)
            BAddr := &Buffer
            Input := Mem2Hex(Addr, SizeHid)

            If (VendorID = 1523 && Product = 255) ; need special function to process foot pedal input
                ProcessPedalInput(Input)

            Else If (IsLabel(Input))
            {
                Gosub, %Input%
            }
        }
   }
}