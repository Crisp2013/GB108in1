INCLUDE "hardware_constants.asm"
INCLUDE "vram_constants.asm"
INCLUDE "constants.asm"

Unknown_C0AD EQU $C0AD
Cur_Input EQU $C0AE
Unknown_C0AF EQU $C0AF
cur_input_2 EQU $C0B0
Unknown_C0B1 EQU $C0B1
Unknown_C0B2 EQU $C0B2
Current_Row EQU $C0B3;현재 메뉴에서 선택된 행(0부터 시작)
Unknown_C0B4 EQU $C0B4
Unknown_C0B5 EQU $C0B5
Unknown_C0B6 EQU $C0B6
Unknown_C0B7 EQU $C0B7
Unknown_C0B8 EQU $C0B8
Current_Page EQU $C0B9;현재 메뉴에서 선택된 페이지(0부터 시작)
Unknown_C0BA EQU $C0BA;가장 마지막 페이지?, 현제페이지에서 가장마지막항목?
Last_game_Cur_Page EQU $C0BB;현재 페이지의 마지막꺼
Total_Game_Count EQU $C0BC;총 개수



LENGTH_CART_NAME EQU 16
LENGTH_TITLE_NAME EQU 16
LENGTH_TITLE_SUB_NAME EQU 20

COORD_CART_NAME EQU vBGMap0+$22
COORD_MENU EQU vBGMap0+$83
COORD_SUB_NAME EQU vBGMap0+$220

MAX_ROW EQU 11	
GAME_COUNT EQU 108	

GAME_LIST_TWO_ROW EQU 0 ;한줄 띄어서 출력할것인가?

SECTION "rst 00", ROM0 [$00]

; SECTION "rst 08", ROM0 [$08]

; SECTION "rst 10", ROM0 [$10] 

; SECTION "rst 18", ROM0 [$18]

; SECTION "rst 20", ROM0 [$20]

; SECTION "rst 28", ROM0 [$28] 

; SECTION "rst 30", ROM0 [$30]

; SECTION "rst 38", ROM0 [$38]

SECTION "vblank", ROM0 [$40]
	reti 
SECTION "hblank", ROM0 [$48]
	reti
SECTION "timer", ROM0 [$50]
	reti
SECTION "serial", ROM0 [$58]
	reti
SECTION "joypad", ROM0 [$60]
	reti
	
SECTION "Entry", ROM0 [$100]

	nop
	jp Start_4000

SECTION "main",ROMX,BANK[$01]	
Start_4000::
	call Init_LCD
    call Init_Wram
    call Init_OAM_And_Hram
    call Init_Bank1
    xor  a			
    ld   [rSCY],a
    ld   [rSCX],a
    ld   [rSTAT],a
    ld   [rWY],a
    ld   a,$07
    ld   [rWX],a
    ld   a,$E4
    ld   [rBGP],a
    ld   [rOBP0],a
    ld   a,$1B
    ld   [rOBP1],a
    ld   a,$C0
    ld   [rLCDC],a
    xor  a
    ld   [rIF],a
    xor  a
    ld   [rNR52],a
    ld   a,1
    ld   [MBC1RomBank],a
	call Load_Main_Gfx
	call Load_Char_Gfx
	call Print_Cart_Name
	xor  a
	ld   [Current_Page],a
	ld   [Last_game_Cur_Page],a
	ld   [Current_Row],a
	ld   a,GAME_COUNT
	ld   [Total_Game_Count],a
	ld   a, ((GAME_COUNT-1)/MAX_ROW)
	ld   [Unknown_C0BA],a
	call Print_Game_Title
	xor  a
	ld   [Current_Row],a
	call Draw_arrow
	call Print_Game_Sub_Title
	call Print_Game_Sub_Title
	call Init_Vram_2
	call Control_LCD


.input_loop
    call Get_Input
    ld   a,[Cur_Input]
	
    cp   a,D_DOWN
    jp   nz, .loc_4076
    call Sel_Row_Down
    jp   .input_loop

.loc_4076
    cp   a,D_UP
    jp   nz,.loc_4081
    call Sel_Row_Up
    jp   .input_loop

.loc_4081
    cp   a,D_RIGHT
    jp   nz,.loc_408C
    call Select_Page_Inc
    jp   .input_loop

.loc_408C
    cp   a,D_LEFT
    jp   nz,.loc_4097
    call Decrease_Page
    jp   .input_loop

.loc_4097
    cp   a,START
    jp   nz,.loc_409F
    jp   .boot_game

.loc_409F
    cp   a,A_BUTTON
    jp   nz, .loc_40A7
    jp   .boot_game

.loc_40A7
	;처리안함
    jp   .input_loop

.boot_game
    di   
    ld   hl,Boot_Game
    ld   bc,$FF80
    ld   de,$7F

.copy_to_hram
    ldi  a,[hl]
    ld   [bc],a
    inc  bc
    dec  de
    ld   a,d
    or   e
    jp   nz, .copy_to_hram
    jp   $FF80

Decrease_Page::
    call Remove_arrow
    ; call Function_420C
    ld   a,[Current_Page]
    cp   a,0
    jr   nz,.not_first

;맨 처음 페이지 일때
    xor  a ;a=0
    ld   [Current_Row],a
    ld   a,[Unknown_C0BA];<-이해가 안되네
    ld   [Current_Page],a
    jp   .done_1

.not_first
	ld   hl,Current_Page
	dec  [hl]
	ld   a,[hl]

.done_1
	push af
	cp   a,0
	jr   nz,.not_zero
	xor  a
	jp   .done_2
	
.not_zero
	ld   d,a
	xor  a
.loop1
	add  a,MAX_ROW
	dec  d
	jr   nz,.loop1
	
.done_2
	ld   [Last_game_Cur_Page],a
	pop  af
	ld   [Current_Page],a
	xor  a
	ld   [Current_Row],a
	call Print_Game_Title
	xor  a
	ld   [Current_Row],a
	call Print_Game_Sub_Title
	call Check_Vblank
	xor  a
	ld   [Current_Row],a
	call Draw_arrow
	ret 

Select_Page_Inc::
	call Remove_arrow
	; call Function_420C
	ld   a,[Current_Page]
	ld   hl,Unknown_C0BA
	cp   [hl]
	jr   nz,.not_last

	xor  a
	ld   [Last_game_Cur_Page],a
	ld   [Current_Row],a
	ld   [Current_Page],a
	jp   .done

.not_last
	ld   hl,Current_Page
	inc  [hl]
	ld   a,[Current_Page]
	ld   d,a
	xor  a
.loop1
	add  a,MAX_ROW
	dec  d
	jr   nz,.loop1
	ld   [Last_game_Cur_Page],a
.done
	xor  a
	ld   [Current_Row],a
	call Print_Game_Title
	xor  a
	ld   [Current_Row],a
	call Print_Game_Sub_Title
	xor  a
	ld   [Current_Row],a
	call Draw_arrow
	ret  

Sel_Row_Up::
	ld   a,[Current_Row]
	
	cp   a,0
	jr   nz,.not_zero
	
	ld   a,[Current_Page]
	ld   hl,Unknown_C0BA;현재페이지의 수보다 작음
	cp   [hl]
	jr   nz,.go_to_last
	
	ld   hl,$C0BC
	ld   a,[hl]
	dec  a
	ld   d,a
	
.loop1
	ld   a,d
	cp   a,MAX_ROW
	jr   c,.done1

;ROW 개수만큼 반복
	dec  d
	dec  d
	dec  d
	dec  d
	dec  d
	dec  d
	dec  d
	dec  d
	dec  d
	dec  d
	dec  d
	jp   .loop1

.done1
	push af
	call Remove_arrow
	pop  af
	ld   [Current_Row],a
	call Draw_arrow
	call Print_Game_Sub_Title
	ret  

.go_to_last
    call Remove_arrow
    ld   a,MAX_ROW-1
    ld   [Current_Row],a
    call Draw_arrow
    call Print_Game_Sub_Title
    ret  

.not_zero
	push af
	call Remove_arrow
	pop  af
	dec  a
	ld   [Current_Row],a
	push af
	call Draw_arrow
	pop  af
	ld   [Current_Row],a
	call Print_Game_Sub_Title
	ret  

Sel_Row_Down::
	ld   a,[Current_Page]
	ld   hl,Unknown_C0BA
	cp   [hl]
	jr   nz,.loc_41DD
	cp   a,0
	jr   z,.loc_41C2
	ld   d,a
	xor  a
.loc_41BD
	add  a,MAX_ROW
	dec  d
	jr   nz,.loc_41BD
.loc_41C2
	ld   hl,$C0B3
	add  [hl]
	ld   d,a
	ld   hl,$C0BC
	ld   a,[hl]
	dec  a
	cp   d
	jr   nz,.loc_41F3
	call Remove_arrow
	xor  a
	ld   [Current_Row],a
	call Draw_arrow
	call Print_Game_Sub_Title
	ret  

.loc_41DD
	ld   a,[Current_Row]
	cp   a,MAX_ROW-1
	jr   nz,.loc_41F3
	call Remove_arrow
	ld   a,0
	ld   [Current_Row],a
	call Draw_arrow
	call Print_Game_Sub_Title
	ret  

.loc_41F3
	ld   a,[Current_Row]
	call Remove_arrow
	ld   a,[Current_Row]
	inc  a
	ld   [Current_Row],a
	push af
	call Draw_arrow
	pop  af
	ld   [Current_Row],a
	call Print_Game_Sub_Title
	ret  

;진짜 이거 뭐하는 함수지
Function_420C::
	ld   de,$120B;???
	ld   hl,COORD_MENU
.loc_4212
	push hl
	ld   a,0
.loc_4215
	call Check_Vblank
	ldi  [hl],a
	dec  d
	jr   nz,.loc_4215
	ld   bc,$20
	pop  hl
	add  hl,bc
	ld   a,$10
	ld   d,a
	dec  e
	jr   nz,.loc_4212
	ret  

;unused
; Function_4228::
; ROM1:4228 06 80            ld   b,$80
; ROM1:422A C3 2F 42         jp   .loc_422F
; ROM1:422D 06 83            ld   b,$83
; .loc_422F
; ROM1:422F 21 81 98         ld   hl,COORD_MENU-1
; ROM1:4232 11 20 00         ld   de,$20
; ROM1:4235 FA B3 C0         ld   a,[Current_Row]
; .loc_4238
; ROM1:4238 FE 00            cp   a,0
; ROM1:423A CA 42 42         jp   z,.loc_4242
; ROM1:423D 19               add  hl,de
; ROM1:423E 3D               dec  a
; ROM1:423F C3 38 42         jp   .loc_4238
; .loc_4242
; ROM1:4242 CD 47 42         call Check_Vblank
; ROM1:4245 70               ld   [hl],b
; ROM1:4246 C9               ret  

SECTION "main_4247",ROMX[$4247],BANK[$01]	
;정확히 말하면 vblank랑 상관없긴 한데...
;일단 쉽게 이해할려고 이렇게 적음
Check_Vblank::
	push af
.loop
	ld   a,[rSTAT]
	and  a,2
	jp   nz, .loop
	pop  af
	ret 

;unused?
; Function_4251::
; ROM1:4251 21 80 98         ld   hl,vBGMap0
; ROM1:4254 3E 0A            ld   a,10
; ROM1:4256 57               ld   d,a
; .loc_4257
; ROM1:4257 E5               push hl
; ROM1:4258 3E 14            ld   a,20
; ROM1:425A 5F               ld   e,a
; .loc_425B
; ROM1:425B CD 47 42         call Check_Vblank
; ROM1:425E 3E 80            ld   a,$80
; ROM1:4260 22               ldi  [hl],a
; ROM1:4261 1D               dec  e
; ROM1:4262 C2 5B 42         jp   nz,.loc_425B
; ROM1:4265 E1               pop  hl
; ROM1:4266 15               dec  d
; ROM1:4267 C2 6B 42         jp   nz,.loc_426B
; ROM1:426A C9               ret  
; .loc_426B
; ROM1:426B 01 20 00         ld   bc,$20
; ROM1:426E 09               add  hl,bc
; ROM1:426F C3 57 42         jp   .loc_4257

SECTION "main_4272",ROMX[$4272],BANK[$01]	
String_Cart_Name::	;01:4272
	db "0123456789ABCDEF";16바이트
	
;카트리지의 맨위에 타이틀 표시
Print_Cart_Name::	;01:4282
	ld   hl,COORD_CART_NAME
	ld   bc, String_Cart_Name
	call Print_Black_Char
	ret  	

;선택된 게임의 하단의 서브타이틀을 출력함
Print_Game_Sub_Title::
    ld   de,MAX_ROW*LENGTH_TITLE_SUB_NAME
    ld   hl,String_Game_Sub_Title
    ld   a,[Current_Page]
	
;현재 페이지의 첫번째 항목의 서브제목의 주소값 계산
.loop1
	cp   a,0
	jp   z, .loop1_end
	add  hl,de
	dec  a
	jp   .loop1
	
.loop1_end
	ld   de,LENGTH_TITLE_SUB_NAME
	ld   a,[Current_Row]

;현재 페이지의 현재 항목의 서브제목의 주소값 계산
.loop2
	cp   a,0
	jp   z, .loop2_end
	add  hl,de
	dec  a
	jp   .loop2
	
.loop2_end
	push hl
	pop  bc
	ld   hl,COORD_SUB_NAME;프린트 할 위치
	call Print_Gray_Char
	ret  


Print_Game_Title::	;01:42B8
	ld   hl, COORD_MENU;메뉴 텍스트 시작점
	ld   de, LENGTH_TITLE_NAME
	xor  a
	ld   [Current_Row],a

;순번계산하기
.loop1
	; 리스트 맨 끝에서 제대로 갱신 안되는 버그 수정할려면 아래 구역 삭제
	ld   a,[Last_game_Cur_Page]
	ld   d,a
	ld   a,[Total_Game_Count]
	cp   d
	jp   z, .loc_ret
	; 리스트 맨 끝에서 제대로 갱신 안되는 버그 수정할려면 위구역 삭제
	ld   a,[Current_Row]
	cp   a, MAX_ROW
	jp   z, .loc_ret

	push hl
	push de
	ld   hl,String_Game_Title
	ld   de,LENGTH_TITLE_NAME
	ld   a,[Last_game_Cur_Page]
;텍스트 위치찾기
.loop2
	cp   a,0
	jp   z, .loc_42EA
	add  hl,de
	dec  a
	jp   .loop2
.loc_42EA
	push hl
	pop  bc
	pop  de
	pop  hl
	push hl
	call Print_Black_Char
	ld   hl,Last_game_Cur_Page
	inc  [hl]
	ld   hl,Current_Row
	inc  [hl]
	pop  hl
	push de
IF (GAME_LIST_TWO_ROW)
	ld   de,ROW_WIDTH*2
ELSE
	ld   de,ROW_WIDTH
ENDC
	add  hl,de
	pop  de
	jp   .loop1
.loc_ret
	ret  

Print_Gray_Char::	;01:4305
	ld   a,LENGTH_TITLE_SUB_NAME
	ld   e,a
.loop
	ld   a,[bc]
	cp   a,$20
	jp   nz, .not_space
	ld   a,$AB
	jp   .switch_end

.not_space
;0~9
	cp   a,$30
	jp   c, .not_numeral
	cp   a,$3A
	jp   nc, .not_numeral
	add  a,$80
	jp   .switch_end

.not_numeral
	cp   a,$41
	jp   c, .not_alphabet
	cp   a,$5B
	jp   nc, .not_alphabet
	add  a,$80
	jp   .switch_end

.not_alphabet
	nop  

.switch_end
	push af
	call Check_Vblank
	pop  af
	ld   [hl],a
	inc  hl
	inc  bc
	dec  e
	jp   nz,.loop
	ret  
	
Load_Char_Gfx::	;01:433F
    ld   bc,Char_Gfx
    ld   hl,$8800
    ld   de,$0170
;검은색으로 폰트 출력
.loop1
    ld   a,[bc]
    call Check_Vblank
    ldi  [hl],a
    call Check_Vblank
    ldi  [hl],a
    inc  bc
    dec  de
    ld   a,d
    or   e
    jp   nz, .loop1

;회색으로 폰트 출력
    ld   bc,Char_Gfx
    ld   hl,$8B00
    ld   de,$0170
.loop2
	ld   a,[bc]
	call Check_Vblank
	ldi  [hl],a
	ld   a,00
	call Check_Vblank
	ldi  [hl],a
	inc  bc
	dec  de
	ld   a,d
	or   e
	jp   nz, .loop2
	ret  

Print_Black_Char::	;01:4374
	ld   a,LENGTH_TITLE_NAME
	ld   e,a
	
.loop
	ld   a,[bc]
	cp   a,$20;' '
	jp   nz,.not_space
	ld   a,$AB
	jp   .switch_end
	
.not_space
	cp   a,$30
	jp   c,.not_numeral
	cp   a,$3A
	jp   nc,.not_numeral
	add  a,$50
	jp   .switch_end
	
.not_numeral
	cp   a,$41
	jp   c,.not_alphabet
	cp   a,$5B
	jp   nc,.not_alphabet
	add  a,$50
	jp   .switch_end
	
.not_alphabet
	;nop
	
.switch_end
	push af
	call Check_Vblank
	pop  af
	ld   [hl],a
	inc  hl
	inc  bc
	dec  e
	jp   nz,.loop
	ret  

;C000~DFFF (Wram)을 a의 값으로 초기화
Init_Wram::	;01:43AD
    ld   hl,$DFFF
    ld   c,$20
    ld   b,$00
.loop
    ldd  [hl],a
    dec  b
    jp   nz, .loop
    dec  c
    jp   nz, .loop
    ret  	
	
;FE00~FE9F (OAM)
;FEA0~FEFF (사용불가영역)
;FE80~FEFF (HRAM, IE)을 a의 값으로 초기화
Init_OAM_And_Hram::	;01:43BE
   ld   hl,$FEFF
   ld   b,0
.loop1
	ldd  [hl],a
	dec  b
	jp   nz,.loop1
	ret  
	ld   hl,$FFFF
	ld   b,$80
.loop2
	ldd  [hl],a
	dec  b
	jp   nz,.loop2
	ret 	


Init_LCD::	;01:43D4
	xor  a
	ld   [rIF],a
	ld   a,[rIE]
	ld   b,a
	res  0,a
	ld   [rIE],a
	ld   a,[rLCDC]
	add  a
	ret  nc
	
.loc_43E2
	ld   a,[rLY]
	cp   a,$91
	jp   c,.loc_43E2
	ld   a,[rLCDC]
	and  a,$7F
	ld   [rLCDC],a
	ld   a,b
	ld   [rIE],a
	ret  

Control_LCD::
	ld   a,[rLCDC]
	or   a,$81
	and  a,$E7
	ld   [rLCDC],a
	ret  

;뭔지 모르겠음
Get_Input::
    ld   a,[Unknown_C0AD]
    ld   [Unknown_C0AF],a
    ld   a,[Cur_Input]
    ld   [cur_input_2],a
    call Get_Input_Inner

	ld   a,[Unknown_C0AD]
	ld   d,a
	ld   a,[Unknown_C0AF]
	ld   [Unknown_C0AD],a
	ld   a,[Cur_Input]
	ld   e,a
	ld   a,[cur_input_2]
	ld   [Cur_Input],a
	call Get_Input_Inner

	ld   a,[Unknown_C0AD]
	cp   d
	jp   nz, .no_input
	ld   a,[Cur_Input]
	cp   e
	ret  z
	
.no_input
	ld   a,[Unknown_C0AF]
	ld   [Unknown_C0AD],a
	xor  a
	ld   [Cur_Input],a
	ret  

;조이패드 입력 부분
Get_Input_Inner::
	ld   a,$20
	ld   [rJOYP],a
	ld   a,[rJOYP]
	ld   a,[rJOYP]
	cpl  
	and  a,$0F
	ld   b,a
	ld   a,$10
	ld   [rJOYP],a
	ld   a,[rJOYP]
	ld   a,[rJOYP]
	ld   a,[rJOYP]
	ld   a,[rJOYP]
	ld   a,[rJOYP]
	ld   a,[rJOYP]
	cpl  
	and  a,$0F
	swap a
	or   b
	ld   c,a
	ld   a,[Unknown_C0AD]
	xor  c
	and  c
	ld   [Cur_Input],a
	ld   a,c
	ld   [Unknown_C0AD],a
	ld   a,$30
	ld   [rJOYP],a
	ret  

;8FF0~8FFF 초기화? 00 FF 반복해서 적기?	
Init_Vram_2:: ;01:446D
    ld   hl,$8FF0
    ld   de,$0008
.loop_4473
	ld   a,$00
	push af
	call Check_Vblank
	pop  af
	ldi  [hl],a
	ld   a,$FF
	push af
	call Check_Vblank
	pop  af
	ldi  [hl],a
	dec  de
	ld   a,d
	or   e
	jp   nz,.loop_4473
	ret  
	
;8000~A000  초기화?
Init_Bank1::	;01:448A
	ld   hl,$8000
	ld   bc,$2000
.loop
	ld   a,$00
	ldi  [hl],a
	dec  bc
	ld   a,b
	or   c
	jp   nz, .loop
	ret  

; Function_449A::
; ROM1:449A 21 E0 99         ld   hl,vBGMap0+$1E0
; ROM1:449D 11 14 00         ld   de,$0014
; .loc_44A0
; ROM1:44A0 E5               push hl
; ROM1:44A1 E5               push hl
; ROM1:44A2 3E FF            ld   a,$FF
; ROM1:44A4 CD 47 42         call Check_Vblank
; ROM1:44A7 77               ld   [hl],a
; ROM1:44A8 E1               pop  hl
; ROM1:44A9 01 20 00         ld   bc,$0020
; ROM1:44AC 09               add  hl,bc
; ROM1:44AD 3E FF            ld   a,$FF
; ROM1:44AF CD 47 42         call Check_Vblank
; ROM1:44B2 77               ld   [hl],a
; ROM1:44B3 E1               pop  hl
; ROM1:44B4 23               inc  hl
; ROM1:44B5 1B               dec  de
; ROM1:44B6 7A               ld   a,d
; ROM1:44B7 B3               or   e
; ROM1:44B8 C2 A0 44         jp   nz,.loc_44A0
; ROM1:44BB C9               ret  

;unused?
; Function_44BC::
; ROM1:44BC CD 9A 44         call Function_449A
; ROM1:44BF CD 22 45         call Function_4522
; ROM1:44C2 CD C6 44         call Function_44C6
; ROM1:44C5 C9               ret  

; Function_44C6::
; ROM1:44C6 FA B9 C0         ld   a,[Current_Page]
; ROM1:44C9 FE 00            cp   a,00
; ROM1:44CB CA DB 44         jp   z,.loc_44DB
; ROM1:44CE 57               ld   d,a
; ROM1:44CF FA B3 C0         ld   a,[Current_Row]
; .loc_44D2
; ROM1:44D2 C6 0A            add  a,10
; ROM1:44D4 15               dec  d
; ROM1:44D5 C2 D2 44         jp   nz,.loc_44DB
; ROM1:44D8 C3 DE 44         jp   .loc_44DE
; .loc_44DB
; ROM1:44DB FA B3 C0         ld   a,[Current_Row]
; .loc_44DE
; ROM1:44DE EA B5 C0         ld   [Unknown_C0B5],a
; ROM1:44E1 5F               ld   e,a
; ROM1:44E2 AF               xor  a
; ROM1:44E3 57               ld   d,a
; ROM1:44E4 21 2C 4E         ld   hl,data_4E2C
; ROM1:44E7 19               add  hl,de
; ROM1:44E8 7E               ld   a,[hl]
; ROM1:44E9 4F               ld   c,a
; ROM1:44EA 3E 0A            ld   a,10
; ROM1:44EC 91               sub  c
; ROM1:44ED 5F               ld   e,a
; ROM1:44EE AF               xor  a
; ROM1:44EF 57               ld   d,a
; ROM1:44F0 21 E0 99         ld   hl,vBGMap0+$1E0
; ROM1:44F3 19               add  hl,de
; ROM1:44F4 3E 54            ld   a,$54
; ROM1:44F6 47               ld   b,a
; .loop_44F7
; ROM1:44F7 E5               push hl
; ROM1:44F8 E5               push hl
; ROM1:44F9 78               ld   a,b
; ROM1:44FA CD 47 42         call Check_Vblank
; ROM1:44FD 77               ld   [hl],a
; ROM1:44FE 04               inc  b
; ROM1:44FF 04               inc  b
; ROM1:4500 23               inc  hl
; ROM1:4501 78               ld   a,b
; ROM1:4502 CD 47 42         call Check_Vblank
; ROM1:4505 77               ld   [hl],a
; ROM1:4506 E1               pop  hl
; ROM1:4507 11 20 00         ld   de,$20
; ROM1:450A 19               add  hl,de
; ROM1:450B 05               dec  b
; ROM1:450C 78               ld   a,b
; ROM1:450D CD 47 42         call Check_Vblank
; ROM1:4510 77               ld   [hl],a
; ROM1:4511 23               inc  hl
; ROM1:4512 04               inc  b
; ROM1:4513 04               inc  b
; ROM1:4514 78               ld   a,b
; ROM1:4515 CD 47 42         call Check_Vblank
; ROM1:4518 77               ld   [hl],a
; ROM1:4519 E1               pop  hl
; ROM1:451A 04               inc  b
; ROM1:451B 23               inc  hl
; ROM1:451C 23               inc  hl
; ROM1:451D 0D               dec  c
; ROM1:451E C2 F7 44         jp   nz,$44F7
; ROM1:4521 C9               ret  

; Function_4522::
; ROM1:4522 FA B9 C0         ld   a,[Current_Page]
; ROM1:4525 FE 00            cp   a,00
; ROM1:4527 CA 37 45         jp   z,.loc_4537
; ROM1:452A 57               ld   d,a
; ROM1:452B FA B3 C0         ld   a,[Current_Row]
; .loc_452E
; ROM1:452E C6 0A            add  a,10
; ROM1:4530 15               dec  d
; ROM1:4531 C2 2E 45         jp   nz,.loc_452E
; ROM1:4534 C3 3A 45         jp   .loc_453A
; .loc_4537
; ROM1:4537 FA B3 C0         ld   a,[Current_Row]
; .loc_453A
; ROM1:453A EA B4 C0         ld   [Unknown_C0B4],a
; ROM1:453D 21 2C 4E         ld   hl,data_4E2C
; ROM1:4540 4F               ld   c,a
; ROM1:4541 AF               xor  a
; ROM1:4542 47               ld   b,a
; ROM1:4543 09               add  hl,bc
; ROM1:4544 7E               ld   a,[hl]
; ROM1:4545 EA B5 C0         ld   [Unknown_C0B5],a
; ROM1:4548 FA B4 C0         ld   a,[Unknown_C0B4]
; ROM1:454B FE 00            cp   a,00
; ROM1:454D CA 6E 45         jp   z,.loc_456E
; ROM1:4550 01 00 00         ld   bc,0
; ROM1:4553 21 2C 4E         ld   hl,data_4E2C
; .loc_4556
; ROM1:4556 2A               ldi  a,[hl]
; ROM1:4557 81               add  c
; ROM1:4558 4F               ld   c,a
; ROM1:4559 3E 00            ld   a,00
; ROM1:455B 88               adc  b
; ROM1:455C 47               ld   b,a
; ROM1:455D FA B4 C0         ld   a,[Unknown_C0B4]
; ROM1:4560 3D               dec  a
; ROM1:4561 EA B4 C0         ld   [Unknown_C0B4],a
; ROM1:4564 C2 56 45         jp   nz,.loc_4556
; ROM1:4567 21 A0 4E         ld   hl,String_Game_Title
; ROM1:456A 09               add  hl,bc
; ROM1:456B C3 71 45         jp   .loc_4571
; .loc_456E
; ROM1:456E 21 A0 4E         ld   hl,String_Game_Title
; .loc_4571
; ROM1:4571 FA B5 C0         ld   a,[Unknown_C0B5]
; ROM1:4574 01 40 95         ld   bc,$9540
; .loc_4577
; ROM1:4577 F5               push af
; ROM1:4578 2A               ldi  a,[hl]
; ROM1:4579 E5               push hl
; ROM1:457A C5               push bc
; ROM1:457B D6 01            sub  a,1
; ROM1:457D 4F               ld   c,a
; ROM1:457E AF               xor  a
; ROM1:457F 47               ld   b,a
; ROM1:4580 CB 21            sla  c
; ROM1:4582 CB 10            rl   b
; ROM1:4584 CB 21            sla  c
; ROM1:4586 CB 10            rl   b
; ROM1:4588 CB 21            sla  c
; ROM1:458A CB 10            rl   b
; ROM1:458C CB 21            sla  c
; ROM1:458E CB 10            rl   b
; ROM1:4590 CB 21            sla  c
; ROM1:4592 CB 10            rl   b
; ROM1:4594 21 A0 4E         ld   hl,String_Game_Title
; ROM1:4597 09               add  hl,bc
; ROM1:4598 11 20 00         ld   de,$20
; ROM1:459B C1               pop  bc
; .loc_459C
; ROM1:459C 2A               ldi  a,[hl]
; ROM1:459D F5               push af
; ROM1:459E CD 47 42         call Check_Vblank
; ROM1:45A1 02               ld   [bc],a
; ROM1:45A2 03               inc  bc
; ROM1:45A3 F1               pop  af
; ROM1:45A4 AF               xor  a
; ROM1:45A5 CD 47 42         call Check_Vblank
; ROM1:45A8 02               ld   [bc],a
; ROM1:45A9 03               inc  bc
; ROM1:45AA 1B               dec  de
; ROM1:45AB 7A               ld   a,d
; ROM1:45AC B3               or   e
; ROM1:45AD C2 9C 45         jp   nz,.loc_459C
; ROM1:45B0 E1               pop  hl
; ROM1:45B1 F1               pop  af
; ROM1:45B2 3D               dec  a
; ROM1:45B3 C2 77 45         jp   nz,.loc_4577
; ROM1:45B6 C9               ret  

SECTION "main_45B7",ROMX[$45B7],BANK[$01]	

; 실제 롬상에서는 작동안하고
; 먼저 루틴을 ff80으로 복사한뒤에 거기로 건너뛰어서 작동함
Boot_Game:: ;01:45B7
;FF80
    ld   a,[Current_Page]
    cp   a,0
    jp   z,$FF95
    ld   d,a
    ld   a,[Current_Row]
;FF8C
	add  a,MAX_ROW
	dec  d
	jp   nz,$FF8C
	jp   $FF98
;FF95
	ld   a,[Current_Row]
;FF98
	ld   [Unknown_C0B5],a
	di   
	ld   e,a
	xor  a
	ld   d,a
	sla  e
	rl   d
	sla  e
	rl   d


	ld   hl, Game_Boot_List
	add  hl,de
	push hl
	pop  bc
	ld   a,[bc]
	push af
	inc  bc
	ld   a,[bc]
	push af
	inc  bc
	ld   a,[bc]
	push af
	inc  bc
	ld   a,[bc]
	ld   [$7000],a
	nop  
	nop  
	nop  
	pop  af
	ld   [$7001],a
	nop  
	nop  
	nop  
	pop  af
	ld   [$7002],a
	nop  
	nop  
	nop  
	nop  
	nop  
	nop  
	ld   a,01
	ld   [$2000],a
	ld   a,00
	ld   [$3000],a
	nop  
	nop  
	nop  
	nop  
	nop  
	nop  
	pop  af
	jp   $100
	ld   a,[Unknown_C0B8]
	jp   $150
	
Load_Main_Gfx::	;01:461F
	call Load_Title_gfx
	call Load_BG_Tilemap
	call Load_Pallet
	ret  
	
Load_Title_gfx::
	ld   hl,Title_gfx;타이틀 그래픽
	ld   de,$800
	ld   bc,$9000	;$9000에 해당 그래픽을 로드
	call Load_Title_gfx_loop
	
	ld   bc,$8800	;그리고 8800에도 로드
	ld   de,$800

Load_Title_gfx_loop:
.loop
	ldi  a,[hl]
	call Check_Vblank
	ld   [bc],a
	inc  bc
	dec  de
	ld   a,e
	or   d
	jr   nz, .loop
	ret  

Load_BG_Tilemap::
    ld   hl,vBGMap0;map쪽으로 로드
    ld   de,$1214
    ld   bc,Menu_Tilemap
.loop
    ld   a,[bc]
    inc  bc
    call Check_Vblank
    ld   [hl],a
    inc  hl
    dec  e
    jr   nz,.loop
    dec  d
    jr   z,.loop_end
    push de
    ld   de,12
    add  hl,de
    pop  de
    ld   a,SCREEN_WIDTH
    ld   e,a
    jp   .loop
.loop_end
	ret  

Load_Pallet::
	ld   hl,Menu_Pallet
	ld   a,$40
	ld   d,a
	ld   a,$80
	ld   [rBGPI],a
.loop
	ldi  a,[hl]
	call Check_Vblank
	ld  [rBGPD],a
	dec  d
	jr   nz,.loop
	ret  

; Function_467E::
; ROM1:467E FA B8 C0         ld   a,[Unknown_C0B8]
; ROM1:4681 FE 11            cp   a,$11
; ROM1:4683 20 2A            jr   nz,.ret_46AF
; ROM1:4685 3E 01            ld   a,$01
; ROM1:4687 E0 4F            ld   [rVBK],a
; ROM1:4689 21 00 98         ld   hl,vBGMap0
; ROM1:468C 11 14 12         ld   de,$1214
; ROM1:468F 01 C4 4C         ld   bc,data_4CC4
; .loc_4692
; ROM1:4692 0A               ld   a,[bc]
; ROM1:4693 03               inc  bc
; ROM1:4694 CD 47 42         call Check_Vblank
; ROM1:4697 77               ld   [hl],a
; ROM1:4698 23               inc  hl
; ROM1:4699 1D               dec  e
; ROM1:469A 20 F6            jr   nz,.loc_4692
; ROM1:469C 15               dec  d
; ROM1:469D 28 0C            jr   z,.loc_46AB
; ROM1:469F D5               push de
; ROM1:46A0 11 0C 00         ld   de,$C
; ROM1:46A3 19               add  hl,de
; ROM1:46A4 D1               pop  de
; ROM1:46A5 3E 14            ld   a,$14
; ROM1:46A7 5F               ld   e,a
; ROM1:46A8 C3 92 46         jp   .loc_4692
; .loc_46AB
; ROM1:46AB 3E 00            ld   a,00
; ROM1:46AD E0 4F            ld   [rVBK],a
; .ret_46AF
; ROM1:46AF C9               ret	

SECTION "main_46B0",ROMX[$46B0],BANK[$01]	

;화살표 지우고 쓰고 그런거
Draw_arrow::  ;01:46B0
	ld   hl,COORD_MENU-1
	ld   a,[Current_Row]
	ld   e,a
	xor  a
	ld   d,a
	sla  e
	rl   d
	sla  e
	rl   d
	sla  e
	rl   d
	sla  e
	rl   d
	sla  e
	rl   d
IF (GAME_LIST_TWO_ROW)
	sla  e	;2칸씩 이동하고 싶음 하나 더 추가
	rl   d
ENDC
	add  hl,de
	ld   a,$AC
	call Check_Vblank
	ldi  [hl],a
	ret  

Remove_arrow::	;01:46D5
	ld   hl,COORD_MENU-1
	ld   a,[Current_Row]
	ld   e,a
	xor  a
	ld   d,a
	sla  e
	rl   d
	sla  e
	rl   d
	sla  e
	rl   d
	sla  e
	rl   d
	sla  e
	rl   d
IF (GAME_LIST_TWO_ROW)
	sla  e	;2칸씩 이동하고 싶음 하나 더 추가
	rl   d
ENDC
	add  hl,de
	ld   a,$AB
	call Check_Vblank
	ldi  [hl],a
	ret

SECTION "Boot_List",ROMX[$46FA],BANK[$01]	
Game_Boot_List:: ;01:46FA
	db $11, $90, $E0, $40
	db $11, $90, $E0, $80
	db $11, $90, $E0, $C0
	db $11, $91, $E0, $01
	db $11, $91, $E0, $41
	db $11, $91, $E0, $81
	db $11, $91, $E0, $C1
	db $11, $92, $E0, $02
	db $11, $92, $E0, $42
	db $11, $92, $E0, $82
	db $11, $92, $E0, $C2
	db $11, $93, $E0, $03
	db $11, $93, $E0, $43
	db $11, $93, $E0, $83
	db $01, $93, $E0, $C3
	db $01, $F1, $F8, $68
	db $01, $F0, $F0, $A0
	db $01, $F0, $F0, $B0
	db $01, $F0, $FC, $08
	db $01, $F0, $FC, $0C
	db $01, $F0, $FC, $10
	db $01, $F0, $FC, $14
	db $01, $F0, $FF, $01
	db $01, $F0, $FF, $02
	db $01, $F0, $FF, $03
	db $01, $F0, $EF, $04
	db $01, $F0, $FF, $05
	db $01, $F0, $FE, $06
	db $01, $F0, $FE, $18
	db $01, $F0, $FE, $1A
	db $01, $F0, $FE, $1C
	db $01, $F0, $FE, $1E
	db $01, $F1, $FE, $70
	db $01, $F1, $FE, $72
	db $01, $F1, $FE, $74
	db $01, $F1, $FE, $76
	db $01, $F1, $FE, $78
	db $01, $F1, $FE, $7A
	db $01, $F1, $FE, $7C
	db $01, $F1, $FE, $7E
	db $01, $F3, $FE, $80
	db $01, $F3, $FE, $82
	db $01, $F3, $FE, $84
	db $01, $F3, $FE, $86
	db $01, $F3, $FE, $88
	db $01, $F3, $FE, $8A
	db $01, $F3, $FE, $8C
	db $01, $F3, $EE, $8E
	db $01, $F3, $FE, $90
	db $01, $F3, $FE, $92
	db $01, $F3, $FE, $94
	db $01, $F3, $FE, $96
	db $01, $F3, $FE, $98
	db $01, $F3, $FE, $9A
	db $01, $F3, $FE, $9C
	db $01, $F3, $FE, $9E
	db $01, $F3, $FE, $A0
	db $01, $F3, $FE, $A2
	db $01, $F3, $FE, $A4
	db $01, $F3, $FE, $A6
	db $01, $F3, $FE, $A8
	db $01, $F3, $FE, $AA
	db $01, $F3, $FE, $AC
	db $01, $F3, $FE, $AE
	db $01, $F2, $FC, $60
	db $01, $F2, $FC, $64
	db $01, $F2, $FC, $68
	db $01, $F2, $FC, $6C
	db $01, $F2, $FC, $70
	db $01, $F2, $FC, $74
	db $01, $F2, $FC, $78
	db $01, $F2, $FC, $7C
	db $01, $F2, $FC, $E0
	db $01, $F2, $FC, $E4
	db $01, $F2, $FC, $E8
	db $01, $F2, $FC, $EC
	db $01, $F2, $FC, $F0
	db $01, $F2, $FC, $F4
	db $01, $F2, $FC, $F8
	db $01, $F2, $FC, $FC
	db $01, $F3, $FC, $B0
	db $01, $F3, $FC, $B4
	db $01, $F3, $FC, $B8
	db $01, $F3, $FC, $BC
	db $01, $F3, $FC, $C0
	db $01, $F3, $FC, $C4
	db $01, $F3, $FC, $C8
	db $01, $F3, $FC, $CC
	db $01, $F3, $FC, $D0
	db $01, $F3, $FC, $D4
	db $01, $F3, $FC, $D8
	db $01, $F3, $FC, $DC
	db $01, $F3, $FC, $E0
	db $01, $F3, $FC, $E4
	db $01, $F3, $FC, $E8
	db $01, $F3, $FC, $EC
	db $01, $F3, $FC, $F0
	db $01, $F3, $FC, $F4
	db $01, $F3, $FC, $F8
	db $01, $F3, $FC, $FC
	db $01, $F2, $FC, $A0
	db $01, $F2, $FC, $A4
	db $01, $F2, $FC, $A8
	db $01, $F2, $FC, $AC
	db $01, $F2, $FC, $B0
	db $01, $F2, $FC, $B4
	db $01, $F2, $FC, $B8
	db $01, $F2, $FC, $BC
	
Title_gfx::		;01:48AA
INCBIN "title.bin"
	
	;unknown	; 01:4ADA
	db $FF, $FF
	
Menu_Tilemap::	;01:4ADB
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $20, $21, $22, $20, $21, $22, $20, $21, $22, $20, $21, $22, $20, $21, $22, $20, $21, $22, $20, $21
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $20, $21, $22, $20, $21, $22, $20, $21, $22, $20, $21, $22, $20, $21, $22, $20, $21, $22, $20, $21
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

Menu_Pallet::	;01:4C44
	;   color1    color2    color3   color4
	db $FF, $F2, $00, $48, $1F, $00, $00, $00
	db $E9, $7F, $E9, $7F, $E9, $7F, $E9, $7F
	db $E9, $7F, $E9, $7F, $E9, $7F, $E9, $7F
	db $E9, $7F, $E9, $7F, $E9, $7F, $E9, $7F
	db $E9, $7F, $E9, $7F, $E9, $7F, $E9, $7F
	db $E9, $7F, $E9, $7F, $E9, $7F, $E9, $7F
	db $E9, $7F, $E9, $7F, $E9, $7F, $E9, $7F
	db $E9, $7F, $E9, $7F, $E9, $7F, $E9, $7F
	db $E9, $7F, $E9, $7F, $E9, $7F, $E9, $7F
	db $E9, $7F, $E9, $7F, $E9, $7F, $E9, $7F
	db $E9, $7F, $E9, $7F, $E9, $7F, $E9, $7F
	db $E9, $7F, $E9, $7F, $E9, $7F, $E9, $7F
	db $E9, $7F, $E9, $7F, $E9, $7F, $E9, $7F
	db $E9, $7F, $E9, $7F, $E9, $7F, $E9, $7F
	db $E9, $7F, $E9, $7F, $E9, $7F, $E9, $7F
	db $E9, $7F, $E9, $7F, $E9, $7F, $E9, $7F

; unused
; data_4E2C:: 
; ROM1:4E2C 08 08 09         ld   (0908),sp
; ROM1:4E2F 08 08 08         ld   (0808),sp
; ROM1:4E32 08 08 08         ld   (0808),sp
; ROM1:4E35 08 05 04         ld   (0405),sp
; ROM1:4E38 04               inc  b
; ROM1:4E39 08 04 06         ld   (0604),sp
; ROM1:4E3C 06 06            ld   b,06
; ROM1:4E3E 05               dec  b
; ROM1:4E3F 04               inc  b
; ROM1:4E40 04               inc  b
; ROM1:4E41 04               inc  b
; ROM1:4E42 05               dec  b
; ROM1:4E43 04               inc  b
; ROM1:4E44 05               dec  b
; ROM1:4E45 04               inc  b
; ROM1:4E46 04               inc  b
; ROM1:4E47 04               inc  b
; ROM1:4E48 04               inc  b
; ROM1:4E49 04               inc  b
; ROM1:4E4A 04               inc  b
; ROM1:4E4B 06 05            ld   b,05
; ROM1:4E4D 05               dec  b
; ROM1:4E4E 05               dec  b
; ROM1:4E4F 04               inc  b
; ROM1:4E50 05               dec  b
; ROM1:4E51 05               dec  b
; ROM1:4E52 08 05 06         ld   (0605),sp
; ROM1:4E55 04               inc  b
; ROM1:4E56 06 04            ld   b,04
; ROM1:4E58 05               dec  b
; ROM1:4E59 04               inc  b
; ROM1:4E5A 04               inc  b
; ROM1:4E5B 04               inc  b
; ROM1:4E5C 04               inc  b
; ROM1:4E5D 04               inc  b
; ROM1:4E5E 04               inc  b
; ROM1:4E5F 04               inc  b
; ROM1:4E60 06 04            ld   b,04
; ROM1:4E62 08 03 03         ld   (0303),sp
; ROM1:4E65 04               inc  b
; ROM1:4E66 04               inc  b
; ROM1:4E67 05               dec  b
; ROM1:4E68 04               inc  b
; ROM1:4E69 05               dec  b
; ROM1:4E6A 04               inc  b
; ROM1:4E6B 05               dec  b
; ROM1:4E6C 04               inc  b
; ROM1:4E6D 04               inc  b
; ROM1:4E6E 04               inc  b
; ROM1:4E6F 06 04            ld   b,04
; ROM1:4E71 05               dec  b
; ROM1:4E72 04               inc  b
; ROM1:4E73 05               dec  b
; ROM1:4E74 05               dec  b
; ROM1:4E75 05               dec  b
; ROM1:4E76 06 05            ld   b,05
; ROM1:4E78 04               inc  b
; ROM1:4E79 04               inc  b
; ROM1:4E7A 08 04 04         ld   (0404),sp
; ROM1:4E7D 04               inc  b
; ROM1:4E7E 04               inc  b
; ROM1:4E7F 06 07            ld   b,07
; ROM1:4E81 05               dec  b
; ROM1:4E82 03               inc  bc
; ROM1:4E83 05               dec  b
; ROM1:4E84 05               dec  b
; ROM1:4E85 07               rlca 
; ROM1:4E86 05               dec  b
; ROM1:4E87 04               inc  b
; ROM1:4E88 06 04            ld   b,04
; ROM1:4E8A 06 04            ld   b,04
; ROM1:4E8C 04               inc  b
; ROM1:4E8D 04               inc  b
; ROM1:4E8E 03               inc  bc
; ROM1:4E8F 04               inc  b
; ROM1:4E90 08 07 04         ld   (0407),sp
; ROM1:4E93 03               inc  bc
; ROM1:4E94 04               inc  b
; ROM1:4E95 04               inc  b
; ROM1:4E96 04               inc  b
; ROM1:4E97 05               dec  b
; ROM1:4E98 06 07            ld   b,07
; ROM1:4E9A 05               dec  b
; ROM1:4E9B 05               dec  b
; ROM1:4E9C 06 05            ld   b,05
; ROM1:4E9E 04               inc  b
; ROM1:4E9F 05               dec  b

SECTION "Game_Title",ROMX[$4EA0],BANK[$01]	
String_Game_Title::		;01:4EA0
	db "GAME TITLE 001  ";
	db "GAME TITLE 002  ";
	db "GAME TITLE 003  ";
	db "GAME TITLE 004  ";
	db "GAME TITLE 005  ";
	db "GAME TITLE 006  ";
	db "GAME TITLE 007  ";
	db "GAME TITLE 008  ";
	db "GAME TITLE 009  ";
	db "GAME TITLE 010  ";
	db "GAME TITLE 011  ";
	db "GAME TITLE 012  ";
	db "GAME TITLE 013  ";
	db "GAME TITLE 014  ";
	db "GAME TITLE 015  ";
	db "GAME TITLE 016  ";
	db "GAME TITLE 017  ";
	db "GAME TITLE 018  ";
	db "GAME TITLE 019  ";
	db "GAME TITLE 020  ";
	db "GAME TITLE 021  ";
	db "GAME TITLE 022  ";
	db "GAME TITLE 023  ";
	db "GAME TITLE 024  ";
	db "GAME TITLE 025  ";
	db "GAME TITLE 026  ";
	db "GAME TITLE 027  ";
	db "GAME TITLE 028  ";
	db "GAME TITLE 029  ";
	db "GAME TITLE 030  ";
	db "GAME TITLE 031  ";
	db "GAME TITLE 032  ";
	db "GAME TITLE 033  ";
	db "GAME TITLE 034  ";
	db "GAME TITLE 035  ";
	db "GAME TITLE 036  ";
	db "GAME TITLE 037  ";
	db "GAME TITLE 038  ";
	db "GAME TITLE 039  ";
	db "GAME TITLE 040  ";
	db "GAME TITLE 041  ";
	db "GAME TITLE 042  ";
	db "GAME TITLE 043  ";
	db "GAME TITLE 044  ";
	db "GAME TITLE 045  ";
	db "GAME TITLE 046  ";
	db "GAME TITLE 047  ";
	db "GAME TITLE 048  ";
	db "GAME TITLE 049  ";
	db "GAME TITLE 050  ";
	db "GAME TITLE 051  ";
	db "GAME TITLE 052  ";
	db "GAME TITLE 053  ";
	db "GAME TITLE 054  ";
	db "GAME TITLE 055  ";
	db "GAME TITLE 056  ";
	db "GAME TITLE 057  ";
	db "GAME TITLE 058  ";
	db "GAME TITLE 059  ";
	db "GAME TITLE 060  ";
	db "GAME TITLE 061  ";
	db "GAME TITLE 062  ";
	db "GAME TITLE 063  ";
	db "GAME TITLE 064  ";
	db "GAME TITLE 065  ";
	db "GAME TITLE 066  ";
	db "GAME TITLE 067  ";
	db "GAME TITLE 068  ";
	db "GAME TITLE 069  ";
	db "GAME TITLE 070  ";
	db "GAME TITLE 071  ";
	db "GAME TITLE 072  ";
	db "GAME TITLE 073  ";
	db "GAME TITLE 074  ";
	db "GAME TITLE 075  ";
	db "GAME TITLE 076  ";
	db "GAME TITLE 077  ";
	db "GAME TITLE 078  ";
	db "GAME TITLE 079  ";
	db "GAME TITLE 080  ";
	db "GAME TITLE 081  ";
	db "GAME TITLE 082  ";
	db "GAME TITLE 083  ";
	db "GAME TITLE 084  ";
	db "GAME TITLE 085  ";
	db "GAME TITLE 086  ";
	db "GAME TITLE 087  ";
	db "GAME TITLE 088  ";
	db "GAME TITLE 089  ";
	db "GAME TITLE 090  ";
	db "GAME TITLE 091  ";
	db "GAME TITLE 092  ";
	db "GAME TITLE 093  ";
	db "GAME TITLE 094  ";
	db "GAME TITLE 095  ";
	db "GAME TITLE 096  ";
	db "GAME TITLE 097  ";
	db "GAME TITLE 098  ";
	db "GAME TITLE 099  ";
	db "GAME TITLE 100  ";
	db "GAME TITLE 101  ";
	db "GAME TITLE 102  ";
	db "GAME TITLE 103  ";
	db "GAME TITLE 104  ";
	db "GAME TITLE 105  ";
	db "GAME TITLE 106  ";
	db "GAME TITLE 107  ";
	db "GAME TITLE 108  ";


SECTION "Game_Sub_Title",ROMX[$5560],BANK[$01]	
String_Game_Sub_Title::	;01:5560
	db "GAME SUB TITLE 001  ";
	db "GAME SUB TITLE 002  ";
	db "GAME SUB TITLE 003  ";
	db "GAME SUB TITLE 004  ";
	db "GAME SUB TITLE 005  ";
	db "GAME SUB TITLE 006  ";
	db "GAME SUB TITLE 007  ";
	db "GAME SUB TITLE 008  ";
	db "GAME SUB TITLE 009  ";
	db "GAME SUB TITLE 010  ";
	db "GAME SUB TITLE 011  ";
	db "GAME SUB TITLE 012  ";
	db "GAME SUB TITLE 013  ";
	db "GAME SUB TITLE 014  ";
	db "GAME SUB TITLE 015  ";
	db "GAME SUB TITLE 016  ";
	db "GAME SUB TITLE 017  ";
	db "GAME SUB TITLE 018  ";
	db "GAME SUB TITLE 019  ";
	db "GAME SUB TITLE 020  ";
	db "GAME SUB TITLE 021  ";
	db "GAME SUB TITLE 022  ";
	db "GAME SUB TITLE 023  ";
	db "GAME SUB TITLE 024  ";
	db "GAME SUB TITLE 025  ";
	db "GAME SUB TITLE 026  ";
	db "GAME SUB TITLE 027  ";
	db "GAME SUB TITLE 028  ";
	db "GAME SUB TITLE 029  ";
	db "GAME SUB TITLE 030  ";
	db "GAME SUB TITLE 031  ";
	db "GAME SUB TITLE 032  ";
	db "GAME SUB TITLE 033  ";
	db "GAME SUB TITLE 034  ";
	db "GAME SUB TITLE 035  ";
	db "GAME SUB TITLE 036  ";
	db "GAME SUB TITLE 037  ";
	db "GAME SUB TITLE 038  ";
	db "GAME SUB TITLE 039  ";
	db "GAME SUB TITLE 040  ";
	db "GAME SUB TITLE 041  ";
	db "GAME SUB TITLE 042  ";
	db "GAME SUB TITLE 043  ";
	db "GAME SUB TITLE 044  ";
	db "GAME SUB TITLE 045  ";
	db "GAME SUB TITLE 046  ";
	db "GAME SUB TITLE 047  ";
	db "GAME SUB TITLE 048  ";
	db "GAME SUB TITLE 049  ";
	db "GAME SUB TITLE 050  ";
	db "GAME SUB TITLE 051  ";
	db "GAME SUB TITLE 052  ";
	db "GAME SUB TITLE 053  ";
	db "GAME SUB TITLE 054  ";
	db "GAME SUB TITLE 055  ";
	db "GAME SUB TITLE 056  ";
	db "GAME SUB TITLE 057  ";
	db "GAME SUB TITLE 058  ";
	db "GAME SUB TITLE 059  ";
	db "GAME SUB TITLE 060  ";
	db "GAME SUB TITLE 061  ";
	db "GAME SUB TITLE 062  ";
	db "GAME SUB TITLE 063  ";
	db "GAME SUB TITLE 064  ";
	db "GAME SUB TITLE 065  ";
	db "GAME SUB TITLE 066  ";
	db "GAME SUB TITLE 067  ";
	db "GAME SUB TITLE 068  ";
	db "GAME SUB TITLE 069  ";
	db "GAME SUB TITLE 070  ";
	db "GAME SUB TITLE 071  ";
	db "GAME SUB TITLE 072  ";
	db "GAME SUB TITLE 073  ";
	db "GAME SUB TITLE 074  ";
	db "GAME SUB TITLE 075  ";
	db "GAME SUB TITLE 076  ";
	db "GAME SUB TITLE 077  ";
	db "GAME SUB TITLE 078  ";
	db "GAME SUB TITLE 079  ";
	db "GAME SUB TITLE 080  ";
	db "GAME SUB TITLE 081  ";
	db "GAME SUB TITLE 082  ";
	db "GAME SUB TITLE 083  ";
	db "GAME SUB TITLE 084  ";
	db "GAME SUB TITLE 085  ";
	db "GAME SUB TITLE 086  ";
	db "GAME SUB TITLE 087  ";
	db "GAME SUB TITLE 088  ";
	db "GAME SUB TITLE 089  ";
	db "GAME SUB TITLE 090  ";
	db "GAME SUB TITLE 091  ";
	db "GAME SUB TITLE 092  ";
	db "GAME SUB TITLE 093  ";
	db "GAME SUB TITLE 094  ";
	db "GAME SUB TITLE 095  ";
	db "GAME SUB TITLE 096  ";
	db "GAME SUB TITLE 097  ";
	db "GAME SUB TITLE 098  ";
	db "GAME SUB TITLE 099  ";
	db "GAME SUB TITLE 100  ";
	db "GAME SUB TITLE 101  ";
	db "GAME SUB TITLE 102  ";
	db "GAME SUB TITLE 103  ";
	db "GAME SUB TITLE 104  ";
	db "GAME SUB TITLE 105  ";
	db "GAME SUB TITLE 106  ";
	db "GAME SUB TITLE 107  ";
	db "GAME SUB TITLE 108  ";

	
Char_Gfx::	;01:55D0
INCBIN "char.bin"

;마지막에 있는데 폰트인지 모르겠음
db $3E, $FF, $E0, $24, $3E, $77, $E0, $10