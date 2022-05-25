.386
.model flat,stdcall
option casemap:none

includelib msvcrt.lib

atof PROTO C : ptr sbyte
printf PROTO C : ptr sbyte, :VARARG	
sprintf PROTO C : ptr sbyte, :VARARG
puts PROTO C : ptr sbyte

strcmp PROTO C : ptr sbyte, : ptr sbyte
strcat PROTO C : ptr sbyte, : ptr sbyte
strlen PROTO C : ptr sbyte

fopen PROTO C : ptr sbyte, : ptr sbyte
fgets PROTO C : ptr sbyte, : dword, : ptr sbyte
fclose PROTO C : ptr sbyte
fscanf PROTO C : ptr sbyte, :VARARG	
memset PROTO C :DWORD,:BYTE,:DWORD
Sleep PROTO :DWORD

Initializing  PROTO
runHint PROTO

WinMain     proto        ; Main window process
MessageBoxA proto :DWORD, :DWORD, :DWORD, :DWORD       
MessageBox 	equ   <MessageBoxA>                        

explore proto :dword, :dword
flagThePosition proto :dword, :dword
autoClick proto :dword, :dword
changeGameState proto
CallHint proto c :dword, :dword, :dword, :dword, :dword,:dword, :dword
autoExplore proto

PromptError      proto                                 


include     windows.inc
include     user32.inc
include     kernel32.inc
include     msgame.inc
includelib  mssolver.lib



.data
ClassName BYTE "Mine Sweeper", 0
AppName BYTE "Mine Sweeper", 0
ButtonClassName BYTE "button", 0
LEDClassName BYTE "STATIC", 0
error_title BYTE "Error", 0
error_msg BYTE "[ERROR] There is no input!", 0
scan_str BYTE "%d", 0ah, 0
file_mode BYTE "r", 0

HintText byte "Hint", 0
AutoSolveText byte "Auto Solve", 0

win_title byte "Congratulations", 0
win_msg byte "You win this one!", 0
lose_title byte "Sorry", 0
lose_msg byte "You lose this one!", 0
hint_title byte "Hint", 0
;hint_msg byte "Press the key ""Ctrl"" and click the map to get the hint.", 0

init_flag BYTE 0


ButtonText1     BYTE "1", 0


menuCaptionText BYTE "Level of Difficulty", 0
menuEasyText BYTE "Beginner (9*9, 10)", 0
menuMediumText BYTE "Intermediate (16*16, 40)", 0
menuHardText BYTE "Expert (30*16, 99)", 0
restartText byte    "Restart", 0

; handles
hInstance       HINSTANCE 0

hMenu HMENU  0
hSubMenu HMENU  0

button_pushed           HWND 0
buttons_all             HWND 16*30 dup(0)
buttons_all_end         dd 0
led1_handle             HWND 0
led0_handle             HWND 0

; image handles
mine_num    HBITMAP 9   dup(?)
led_num     HBITMAP 10  dup(?)
hidden      HBITMAP ?
flag        HBITMAP ?
mine        HBITMAP ?
exploded    HBITMAP ?
red         HBITMAP ?
green       HBITMAP ?
flag_wrong  HBITMAP ?

;paint           PAINTSTRUCT <>
;hDC             HDC ?
;hMemDC          HDC ?

; game information
led1        dd 0    ; the ends digit of LED
led0        dd 0    ; the ones digit of LED
windowWidth dd 0
windowHeight dd 0
currentDifficulty  dd 1001

; --- image resource ---
mine_num_path   BYTE    "src\images\0.bmp", 0,
                        "src\images\1.bmp", 0,
                        "src\images\2.bmp", 0,
                        "src\images\3.bmp", 0,
                        "src\images\4.bmp", 0,
                        "src\images\5.bmp", 0,
                        "src\images\6.bmp", 0,
                        "src\images\7.bmp", 0,
                        "src\images\8.bmp", 0
mine_num_path_length dd ($-mine_num_path)/9

led_path        BYTE    "src\images\led0.bmp", 0,
                        "src\images\led1.bmp", 0,
                        "src\images\led2.bmp", 0,
                        "src\images\led3.bmp", 0,
                        "src\images\led4.bmp", 0,
                        "src\images\led5.bmp", 0,
                        "src\images\led6.bmp", 0,
                        "src\images\led7.bmp", 0,
                        "src\images\led8.bmp", 0,
                        "src\images\led9.bmp", 0
led_path_length dd ($-led_path)/10

hidden_path     BYTE    "src\images\hidden.bmp", 0
green_path      BYTE    "src\images\green.bmp", 0
red_path        BYTE    "src\images\red.bmp", 0
flag_path       BYTE    "src\images\flag.bmp", 0
flag_wrong_path BYTE    "src\images\flag_wrong.bmp", 0
mine_path       BYTE    "src\images\mine.bmp", 0
exploded_path   BYTE    "src\images\exploded.bmp", 0


; --- Global information ---
extern playBoard        : byte
extern hintBoard        : byte
extern gameState        : dword
extern mine_total       : dword
extern Board_column     : dword
extern Board_row        : dword
extern Clicked_column   : dword
extern Clicked_row      : dword
extern flaggedMinesTotal: dword
extern showHint         : dword

.const
Button1ID       equ 1
Button2ID       equ 2
Button3ID       equ 3
BLOCK_SIZE      equ 30


.code

;
; generate the main window, fundation of the project
; You should not modify this function in most cases.
;
WinMain proc
    local wndclassex: WNDCLASSEX
    local message: MSG
    local handle: HWND

    ; initiallize WNDCLASSEX
    mov wndclassex.style, CS_HREDRAW or CS_VREDRAW
    mov wndclassex.cbSize, SIZEOF WNDCLASSEX
    mov wndclassex.lpfnWndProc, offset handle_function  ; set our function
    mov wndclassex.cbClsExtra, 0
    mov wndclassex.cbWndExtra, 0
    invoke GetModuleHandle, 0
    mov wndclassex.hInstance, eax
    mov wndclassex.hbrBackground, 04H
    mov wndclassex.lpszMenuName, 0
    mov wndclassex.lpszClassName, offset ClassName

    invoke LoadIcon, 0, IDI_APPLICATION
    mov wndclassex.hIcon, eax
    mov wndclassex.hIconSm, eax
    invoke LoadCursor, 0, IDC_ARROW
    mov wndclassex.hCursor, eax

    invoke RegisterClassEx, addr wndclassex
    invoke CreateWindowEx, WS_EX_CLIENTEDGE, offset ClassName, offset AppName, \
    WS_OVERLAPPEDWINDOW,   ; style of the main window
        CW_USEDEFAULT, CW_USEDEFAULT, 285, 380, 0, 0, hInstance, 0
    mov handle, eax

    ; show the window and refresh it recursively
    invoke ShowWindow, handle, SW_SHOWNORMAL
    invoke UpdateWindow, handle

WINDOW_LOOP:
    invoke GetMessage, addr message, NULL, 0, 0
    CMP eax, 0
    jz WINDOW_LOOP_OUT
    invoke TranslateMessage, addr message
    invoke DispatchMessage, addr message

    jmp WINDOW_LOOP
WINDOW_LOOP_OUT:

    ; exit
    mov eax, message.wParam
    ret
WinMain endp


;
; error handler
; I have not invoked this function at any places
;
PromptError proc
  pushad
  invoke MessageBox, NULL, ADDR error_msg, ADDR error_title, MB_OK
  popad
  ret
PromptError	endp


;
; show the number of remaining mines
; paramter "change" can be 1, 0, -1
; you should invoke this function only if when the player labeled a mine
;
showLED proc C  hWnd:HWND
    push ebx
    push ecx
    push edx
    push esi
    push edi

    mov eax, mine_total
    .if flaggedMinesTotal >= eax
        xor esi, esi
        xor edi, edi
    .else
        xor edx, edx
        sub eax, flaggedMinesTotal
        mov ebx, 10
        div bx

        mov esi, edx
        mov edi, eax
    .endif

    invoke DestroyWindow, led1_handle
    invoke DestroyWindow, led0_handle

    invoke CreateWindowEx, WS_EX_WINDOWEDGE, ADDR LEDClassName, ADDR LEDClassName, \
            WS_CHILD or WS_VISIBLE or SS_BITMAP, \
            10, 10, 24, 40, hWnd, 6666, hInstance, NULL
    mov led1_handle, eax
    invoke SendMessage, eax, STM_SETIMAGE, IMAGE_BITMAP, led_num[edi*type led_num]
    
    invoke CreateWindowEx, NULL, ADDR LEDClassName, ADDR LEDClassName, \
            WS_CHILD or WS_VISIBLE or SS_BITMAP, \
            34, 10, 24, 40, hWnd, 6667, hInstance, NULL
    mov led0_handle, eax
    invoke SendMessage, eax, STM_SETIMAGE, IMAGE_BITMAP, led_num[esi*type led_num]
  
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
showLED endp


;
; show the entire map of mines when initializing
; !!! you should not change or invoke this fucntion !!!
;
showMap proc C  hWnd:HWND, Width1: DWORD, Height1: DWORD, buttonWidth1: DWORD, buttonHeight1: DWORD
    local cnt: dword
    push ebx
    push ecx
    push edx
    push esi
    push edi

    xor ebx, ebx ; height
    xor ecx, ecx ; width
    mov cnt, 0

    .while ebx < Height1
        .while ecx < Width1
            mov eax, ecx
            mul buttonWidth1
            mov edi, eax

            mov eax, ebx
            mul buttonHeight1
            mov esi, eax
            add esi, 60

            ; ID of button
            xor eax, eax
            mov ah, bl
            mov al, cl


            push ecx
            push edx
            invoke CreateWindowEx, NULL, ADDR LEDClassName, ADDR ButtonText1, \
                    WS_CHILD or WS_VISIBLE or SS_BITMAP, \
                    edi, esi, buttonWidth1, buttonHeight1, hWnd, eax, hInstance, NULL

            mov esi, eax
            invoke SendMessage, esi, STM_SETIMAGE, IMAGE_BITMAP, hidden
            pop edx
            pop ecx

            mov edx, cnt
            mov buttons_all[edx*type buttons_all], esi
            inc ecx
            inc cnt
        .endw

        xor ecx, ecx
        inc ebx
    .endw

    mov eax, type buttons_all
    mul cnt
    mov buttons_all_end, eax
    add buttons_all_end, offset buttons_all
  
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
showMap	endp


;
; start a new game
; this function refreash everything including LED, mine, difficulty and menu
; you should input the difficulty at parameter "dicciculty", 
; where 1001 is easy, 1002 is medium, 1003 is hard
;
newGame proc C hWnd: HWND, difficulty: DWORD
    push ebx
    push ecx
    push edx
    push esi
    push edi

    lea esi, buttons_all
    .while esi < buttons_all_end
        mov edi, [esi]
        invoke DestroyWindow, edi
        add esi, type buttons_all
    .endw

    mov gameState, STATE_INIT

    ; refresh window and reset size of it
    .if difficulty == 1001
        mov Board_column, BEGINNER_WIDTH
        mov Board_row, BEGINNER_HEIGHT
        mov led1, 1
        mov led0, 0
        mov mine_total, BEGINNER_MINES
    .elseif difficulty == 1002
        mov Board_column, INTERMEDIATE_WIDTH
        mov Board_row, INTERMEDIATE_HEIGHT
        mov led1, 4
        mov led0, 0
        mov mine_total, INTERMEDIATE_MINES
    .else
        mov Board_column, EXPERT_WIDTH
        mov Board_row, EXPERT_HEIGHT
        mov led1, 9
        mov led0, 9
        mov mine_total, EXPERT_MINES
    .endif

    mov     flaggedMinesTotal, 0

    mov esi, Board_column
    mov edi, Board_row

    invoke showLED, hWnd

    mov eax, BLOCK_SIZE
    mul esi
    add eax, 20
    mov windowWidth, eax

    mov eax, BLOCK_SIZE
    mul edi
    add eax, 123
    mov windowHeight, eax
    invoke MoveWindow, hWnd, 100, 150, windowWidth, windowHeight, 1
    ;invoke  SetWindowPos, hWnd, hWnd, 0, 0, windowWidth, windowHeight, SWP_NOMOVE or SWP_SHOWWINDOW

    invoke showMap, hWnd, esi, edi, BLOCK_SIZE, BLOCK_SIZE
    

    ; modify the menu
    mov edi, 1001

    .while edi < 1004
        mov esi, MF_BYCOMMAND
        .if difficulty == edi
            or esi, MF_CHECKED
        .else
            or esi, MF_UNCHECKED
        .endif
        invoke CheckMenuItem, hSubMenu, edi, esi
        inc edi
    .endw

    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
newGame endp


;
; load the all the image here
;
loadBitmap proc C
    push ecx
    push edx

    ; load number of mines images
    xor ebx, ebx
    xor esi, esi
    .while esi <= 8
        invoke  LoadImageA, NULL, addr mine_num_path[ebx], IMAGE_BITMAP, 30, 30, LR_LOADFROMFILE
        mov dword ptr mine_num[esi*type mine_num], eax

        add ebx, mine_num_path_length
        inc esi
    .endw

    ; load led images
    xor ebx, ebx
    xor esi, esi
    .while esi <= 9
        invoke  LoadImageA, NULL, addr led_path[ebx], IMAGE_BITMAP, 24, 40, LR_LOADFROMFILE
        mov dword ptr led_num[esi*type led_num], eax

        add ebx, led_path_length
        inc esi
    .endw

    ; load other image of mine status
    invoke  LoadImageA, NULL, addr hidden_path, IMAGE_BITMAP, 30, 30, LR_LOADFROMFILE
    mov hidden, eax

    invoke  LoadImageA, NULL, addr flag_path, IMAGE_BITMAP, 30, 30, LR_LOADFROMFILE
    mov flag, eax

    invoke  LoadImageA, NULL, addr mine_path, IMAGE_BITMAP, 30, 30, LR_LOADFROMFILE
    mov mine, eax

    invoke  LoadImageA, NULL, addr exploded_path, IMAGE_BITMAP, 30, 30, LR_LOADFROMFILE
    mov exploded, eax

    invoke  LoadImageA, NULL, addr red_path, IMAGE_BITMAP, 30, 30, LR_LOADFROMFILE
    mov red, eax

    invoke  LoadImageA, NULL, addr green_path, IMAGE_BITMAP, 30, 30, LR_LOADFROMFILE
    mov green, eax

    invoke  LoadImageA, NULL, addr flag_wrong_path, IMAGE_BITMAP, 30, 30, LR_LOADFROMFILE
    mov flag_wrong, eax

    pop edx
    pop ecx
    ret
loadBitmap endp


;
; input handle of button and handle of image, then the image of button will change
;
changeButtonImage proc C lParam: dword, image: dword
    push ebx
    push ecx
    push edx
    push esi
    push edi

    mov eax, lParam
    mov dl, 30
    div dl
    xor ebx, ebx
    mov bl, al ; x

    mov eax, lParam
    shr eax, 16
    sub eax, 60
    div dl
    xor ecx, ecx
    mov cl, al ; y

    mov eax, ecx
    mul Board_column
    add eax, ebx

    invoke SendMessage, buttons_all[eax*type buttons_all], STM_SETIMAGE, IMAGE_BITMAP, image

    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
changeButtonImage endp


;
; calculate click position
;
resolveClickPosition proc C lParam: dword
    push ebx
    push ecx
    push edx
    push esi
    push edi

    mov eax, lParam
    mov dl, 30
    div dl
    xor ebx, ebx
    mov bl, al ; x

    mov eax, lParam
    shr eax, 16
    sub eax, 60

    jl INVALID_CLICK

    div dl
    xor ecx, ecx
    mov cl, al ; y

    mov Clicked_column, ebx
    mov Clicked_row, ecx

    xor eax, eax
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

INVALID_CLICK:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    mov eax, -1
    ret
resolveClickPosition endp


;
;
;
initHint proc C hWnd: HWND
    push ecx
    push edx

    mov eax, windowWidth
    shr eax, 1
    sub eax, 30
    invoke CreateWindowEx, NULL, ADDR ButtonClassName, ADDR HintText, \
            WS_CHILD or WS_VISIBLE, \
            eax, 10, 40, 40, hWnd, 333, hInstance, NULL

    pop edx
    pop ecx

    ret
initHint endp


;
;
;
initAutoSolve proc C hWnd: HWND
    push ecx
    push edx

    mov eax, windowWidth
    shr eax, 1
    add eax, 30
    invoke CreateWindowEx, NULL, ADDR ButtonClassName, ADDR AutoSolveText, \
            WS_CHILD or WS_VISIBLE, \
            eax, 10, 80, 40, hWnd, 334, hInstance, NULL

    pop edx
    pop ecx

    ret
initAutoSolve endp


;
;
;
updateShow proc C hWnd: HWND
    local cnt: dword, image: HWND
    local flag_num: dword

    push ebx
    push ecx
    push edx
    push esi
    push edi


    mov eax, Board_column
    mov ebx, Board_row
    mul ebx
    mov cnt, eax

    mov flag_num, 0
    
    xor ebx, ebx ; count the button

    .while ebx < cnt
        movzx esi, byte ptr playBoard[ebx*type playBoard]
        movzx edi, byte ptr hintBoard[ebx*type hintBoard]

        .if showHint && edi != HINT_NONE
            .if edi == HINT_SAFE
                push green
            .elseif edi == HINT_MINE   
                push red
            .else
            ;TODO:hint type other images
                push exploded
            .endif

        .else
            .if esi >= NUMBER_0 && esi <= NUMBER_8
                push mine_num[esi*type mine_num]
            .elseif esi == MINE   
                push mine
            .elseif esi == UNKNOWN
                push hidden
            .elseif esi == FLAGED 
                push flag
            .elseif esi == EXPLODED
                push exploded
            .elseif esi == FLAG_WRONG 
                push flag_wrong
            .endif

        .endif
        
        pop image
        invoke SendMessage, buttons_all[ebx*type buttons_all], STM_SETIMAGE, IMAGE_BITMAP, image

        inc ebx
        inc flag_num
    .endw

    invoke showLED, hWnd

    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
updateShow endp

;
; message handler
; this is the core function
;
handle_function proc hWnd: HWND, uMsg: UINT, wParam: WPARAM, lParam: LPARAM
    .IF uMsg == WM_DESTROY
        invoke DestroyWindow, hWnd
        invoke PostQuitMessage, NULL

    .ELSEIF uMsg == WM_CREATE
        ; menu
        invoke CreateMenu
        mov hMenu, eax
        
        invoke CreateMenu
        mov hSubMenu, eax
 
        invoke AppendMenu, hMenu, MF_POPUP, hSubMenu, offset menuCaptionText
        invoke AppendMenu, hSubMenu, MF_STRING, 2000, offset restartText
        invoke AppendMenu, hSubMenu, MF_SEPARATOR, 0, NULL
        invoke AppendMenu, hSubMenu, MF_STRING or MF_CHECKED, 1001, offset menuEasyText
        invoke AppendMenu, hSubMenu, MF_STRING, 1002, offset menuMediumText
        invoke AppendMenu, hSubMenu, MF_STRING, 1003, offset menuHardText
        invoke AppendMenu, hSubMenu, MF_SEPARATOR, 0, NULL

        invoke SetMenu, hWnd, hMenu

        invoke loadBitmap

        invoke newGame, hWnd, 1001

        invoke initHint, hWnd
        invoke initAutoSolve, hWnd

    .ELSEIF uMsg == WM_COMMAND
        mov eax, wParam

        ; change difficulty
        .if eax == 1001  ; easy
            mov     currentDifficulty, eax
            invoke newGame, hWnd, 1001
        .elseif eax == 1002 ; midium
            mov     currentDifficulty, eax
            invoke newGame, hWnd, 1002
        .elseif eax == 1003 ; hard
            mov     currentDifficulty, eax
            invoke newGame, hWnd, 1003
        .elseif eax == 2000
            invoke newGame, hWnd, currentDifficulty
        .elseif eax == 333
            .if gameState == STATE_PLAYING 
                .if showHint == 0
                    invoke CallHint, Board_column, Board_row, mine_total, addr playBoard, addr hintBoard, Clicked_row, Clicked_column
                    mov     showHint, 1
                    invoke updateShow, hWnd
                    invoke memset,addr hintBoard,HINT_NONE,MAX_CELLS
                .elseif showHint == 1
                    mov showHint, 0
                    invoke updateShow, hWnd
                .endif
            .endif

            outexplore:
        .elseif eax == 334
            .if gameState == STATE_PLAYING 
                .while gameState == STATE_PLAYING
                    invoke CallHint, Board_column, Board_row, mine_total, addr playBoard, addr hintBoard, Clicked_row, Clicked_column
                    mov		eax, Board_row
	                mul		Board_column
	                mov		ecx, eax
	                xor		ebx, ebx
	                .WHILE	ebx < ecx
                        mov al, byte ptr hintBoard[ebx]
                        .if al == 0
                            inc ebx
                            .continue
                        .endif
                        jmp autoexplore
	                .ENDW
                    jmp outexplore

                autoexplore:
                    mov     showHint, 1
                    invoke updateShow, hWnd
                    invoke memset,addr hintBoard,HINT_NONE,MAX_CELLS
                    invoke Sleep, 100

                    invoke autoExplore
                    invoke changeGameState
                    invoke updateShow, hWnd
                    invoke Sleep, 100
                .endw
                .if gameState == STATE_WIN
                    invoke MessageBox, NULL, ADDR win_msg, ADDR win_title, MB_OK
                .endif
            .endif
        .endif

    .ELSEIF uMsg == WM_LBUTTONUP 
        ; �����һ�β���ʱȡ��
        mov     showHint, 0
        .if wParam == MK_CONTROL
            .if gameState == STATE_PLAYING
                    invoke resolveClickPosition, lParam
                .if eax == 0
                    ;; autoClick
                    invoke autoClick, Clicked_row, Clicked_column
                    invoke changeGameState
                    invoke updateShow, hWnd    
                .endif        
            .endif

        .elseif gameState == STATE_INIT
            invoke resolveClickPosition, lParam
            .if eax == 0
                invoke Initializing
                mov gameState, STATE_PLAYING
                invoke explore, Clicked_row, Clicked_column
                invoke changeGameState
                invoke updateShow, hWnd
                ;invoke changeButtonImage, lParam, green
                    
                .if gameState == STATE_WIN
                    invoke MessageBox, NULL, ADDR win_msg, ADDR win_title, MB_OK

                .elseif gameState == STATE_LOSE
                    invoke MessageBox, NULL, ADDR lose_msg, ADDR lose_title, MB_OK

                .endif
            .endif

        .elseif gameState == STATE_PLAYING
            invoke resolveClickPosition, lParam
            .if eax == 0
                invoke explore, Clicked_row, Clicked_column 
                invoke changeGameState
                invoke updateShow, hWnd
            .endif
            ;invoke changeButtonImage, lParam, red

            .if gameState == STATE_WIN
                invoke MessageBox, NULL, ADDR win_msg, ADDR win_title, MB_OK

            .elseif gameState == STATE_LOSE
                invoke MessageBox, NULL, ADDR lose_msg, ADDR lose_title, MB_OK

            .endif

        .else
            
        .endif

    .ELSEIF uMsg == WM_RBUTTONUP
        ; �����һ�β���ʱȡ��
        mov     showHint, 0
        .if gameState == STATE_PLAYING
            invoke resolveClickPosition, lParam
            ;;; change flag
            .if eax == 0
                invoke flagThePosition, Clicked_row, Clicked_column 
                invoke updateShow, hWnd
            .endif
            ;invoke changeButtonImage, lParam, flag
        .endif
    .ELSE
        invoke DefWindowProc, hWnd, uMsg, wParam, lParam
        ret
    .ENDIF

    xor eax, eax
    ret
handle_function endp


;
; main
;
main:
  invoke WinMain
  invoke ExitProcess, eax
end main