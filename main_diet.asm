INCLUDE "hardware_constants.asm"

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

;확인 필요
D_RIGHT  EQU %00000001;1
D_LEFT   EQU %00000010;2
D_UP     EQU %00000100;4
D_DOWN   EQU %00001000;8
A_BUTTON EQU %00010000;10
B_BUTTON EQU %00100000;20
SELECT   EQU %01000000;40
START    EQU %10000000;80

SCREEN_WIDTH  EQU 20
SCREEN_HEIGHT EQU 18
ROW_WIDTH  EQU $20


LENGTH_CART_NAME EQU 16
LENGTH_TITLE_NAME EQU 16
LENGTH_TITLE_SUB_NAME EQU 20

MAX_ROW EQU 11	;정의가능하게 분석해야함
GAME_COUNT EQU 108	;정의 가능

GAME_LIST_TWO_ROW EQU 0 ;한줄 띄어서 출력할것인가?

SECTION "rst 00", ROM0 [$00]

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
	; call Print_Game_Sub_Title
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
	ld   hl,$9882
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

String_Cart_Name::	;01:4272
	db "0123456789ABCDEF";16바이트
	
;카트리지의 맨위에 타이틀 표시
Print_Cart_Name::	;01:4282
	ld   hl,$9822
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
	ld   hl,$9A20;프린트 할 위치
	call Print_Gray_Char
	ret  


Print_Game_Title::	;01:42B8
	ld   hl, $9882;메뉴 텍스트 시작점
	ld   de, LENGTH_TITLE_NAME
	xor  a
	ld   [Current_Row],a

;순번계산하기
.loop1
	; ld   a,[Last_game_Cur_Page]
	; ld   d,a
	; ld   a,[Total_Game_Count]
	; cp   d
	; jp   z, .loc_ret
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
    ld   hl,$9800;map쪽으로 로드
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


;화살표 지우고 쓰고 그런거
Draw_arrow::  ;01:46B0
	ld   hl,$9881
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
	ld   hl,$9881
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
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $
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